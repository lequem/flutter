// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'mock_text_input.dart';

void main() {
  MockTextInput mockTextInput = new MockTextInput()..register();

  void enterText(String text) {
    mockTextInput.enterText(text);
  }

  Future<Null> showKeyboard(WidgetTester tester) async {
    RawInputState editable = tester.state(find.byType(RawInput).first);
    editable.requestKeyboard();
    await tester.pump();
  }

  testWidgets('onSaved callback is called', (WidgetTester tester) async {
    GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    String fieldValue;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            child: new InputFormField(
              onSaved: (InputValue value) { fieldValue = value.text; },
            ),
          )
        )
      );
    }

    await tester.pumpWidget(builder());
    await showKeyboard(tester);

    expect(fieldValue, isNull);

    Future<Null> checkText(String testValue) async {
      enterText(testValue);
      await tester.idle();
      formKey.currentState.save();
      // pump'ing is unnecessary because callback happens regardless of frames
      expect(fieldValue, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('Validator sets the error text only when validate is called', (WidgetTester tester) async {
    GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    GlobalKey inputKey = new GlobalKey();
    String errorText(InputValue input) => input.text + '/error';

    Widget builder(bool autovalidate) {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            autovalidate: autovalidate,
            child: new InputFormField(
              key: inputKey,
              validator: errorText,
            ),
          )
        )
      );
    }

    // Start off not autovalidating.
    await tester.pumpWidget(builder(false));
    await showKeyboard(tester);

    Future<Null> checkErrorText(String testValue) async {
      formKey.currentState.reset();
      enterText(testValue);
      await tester.idle();
      await tester.pumpWidget(builder(false));

      // We have to manually validate if we're not autovalidating.
      expect(find.text(errorText(new InputValue(text: testValue))), findsNothing);
      formKey.currentState.validate();
      await tester.pump();
      expect(find.text(errorText(new InputValue(text: testValue))), findsOneWidget);

      // Try again with autovalidation. Should validate immediately.
      formKey.currentState.reset();
      enterText(testValue);
      await tester.idle();
      await tester.pumpWidget(builder(true));

      expect(find.text(errorText(new InputValue(text: testValue))), findsOneWidget);
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Multiple Inputs communicate', (WidgetTester tester) async {
    GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    GlobalKey<FormFieldState<InputValue>> fieldKey = new GlobalKey<FormFieldState<InputValue>>();
    GlobalKey focusKey = new GlobalKey();
    // Input 2's validator depends on a input 1's value.
    String errorText(InputValue input) => fieldKey.currentState.value?.text.toString() + '/error';

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            autovalidate: true,
            child: new Focus(
              key: focusKey,
              child: new Block(
                children: <Widget>[
                  new InputFormField(
                    key: fieldKey
                  ),
                  new InputFormField(
                    validator: errorText,
                  ),
                ]
              )
            ),
          )
        )
      );
    }

    await tester.pumpWidget(builder());
    await showKeyboard(tester);

    Future<Null> checkErrorText(String testValue) async {
      enterText(testValue);
      await tester.idle();
      await tester.pump();

      // Check for a new Text widget with our error text.
      expect(find.text(testValue + '/error'), findsOneWidget);
      return null;
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Provide initial value to input', (WidgetTester tester) async {
    String initialValue = 'hello';
    GlobalKey<FormFieldState<InputValue>> inputKey = new GlobalKey<FormFieldState<InputValue>>();

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Form(
            child: new InputFormField(
              key: inputKey,
              initialValue: new InputValue(text: initialValue),
            ),
          )
        )
      );
    }

    await tester.pumpWidget(builder());
    await showKeyboard(tester);

    // initial value should be loaded into keyboard editing state
    expect(mockTextInput.editingState, isNotNull);
    expect(mockTextInput.editingState['text'], equals(initialValue));

    // initial value should also be visible in the raw input line
    RawInputState editableText = tester.state(find.byType(RawInput));
    expect(editableText.config.value.text, equals(initialValue));

    // sanity check, make sure we can still edit the text and everything updates
    expect(inputKey.currentState.value.text, equals(initialValue));
    enterText('world');
    await tester.idle();
    await tester.pump();
    expect(inputKey.currentState.value.text, equals('world'));
    expect(editableText.config.value.text, equals('world'));
  });

  testWidgets('No crash when a FormField is removed from the tree', (WidgetTester tester) async {
    GlobalKey<FormState> formKey = new GlobalKey<FormState>();
    GlobalKey fieldKey = new GlobalKey();
    String fieldValue;

    Widget builder(bool remove) {
      return new Center(
        child: new Material(
          child: new Form(
            key: formKey,
            child: remove ? new Container() : new InputFormField(
              key: fieldKey,
              autofocus: true,
              onSaved: (InputValue value) { fieldValue = value.text; },
              validator: (InputValue value) { return value.text.isEmpty ? null : 'yes'; }
            ),
          )
        )
      );
    }

    await tester.pumpWidget(builder(false));
    await showKeyboard(tester);

    expect(fieldValue, isNull);
    expect(formKey.currentState.validate(), isTrue);

    enterText('Test');
    await tester.idle();
    await tester.pumpWidget(builder(false));

    // Form wasn't saved yet.
    expect(fieldValue, null);
    expect(formKey.currentState.validate(), isFalse);

    formKey.currentState.save();

    // Now fieldValue is saved.
    expect(fieldValue, 'Test');
    expect(formKey.currentState.validate(), isFalse);

    // Now remove the field with an error.
    await tester.pumpWidget(builder(true));

    // Reset the form. Should not crash.
    formKey.currentState.reset();
    formKey.currentState.save();
    expect(formKey.currentState.validate(), isTrue);
  });
}
