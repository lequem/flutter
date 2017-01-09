import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui show Image;
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/http.dart' as http;


void main() {

  ImageInfo imageloaded;
  void handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    imageloaded = imageInfo;
  }

  Future<ImageInfo> isloaded() async {
    while(imageloaded == null) {};
    return imageloaded;
  }

  //transparent png
  List<int> bytes = <int>[0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,0x00,0x00,
      0x00,0x01,0x00,0x00,0x00,0x01,0x08,0x06,0x00,0x00,0x00,0x1F,0x15,0xC4,0x89,0x00,0x00,0x00,0x0A,0x49,0x44,0x41,0x54,
      0x78,0x9C,0x63,0x00,0x01,0x00,0x00,0x05,0x00,0x01,0x0D,0x0A,0x2D,0xB4,0x00,0x00,0x00,0x00,0x49,0x45,0x4E,0x44,0xAE,
      0x42,0x60,0x82];

  test('decodeImageFromList call', () async {

    ui.Image image  = await decodeImageFromList(new Uint8List.fromList(bytes));
    expect(image != null, true);

  });

  testWidgets('ImageNetwork call', (WidgetTester tester) async {

    http.Client.clientOverride = () {
      return new http.MockClient((http.BaseRequest request) {
        return new Future<http.Response>.value(
          new http.Response.bytes(new Uint8List.fromList(bytes), 200)
        );
      });
    };

    NetworkImage networkImage = new NetworkImage('fakeurl');
    ImageStreamCompleter completer = networkImage.load(networkImage);
    completer.addListener(handleImageChanged);
    await tester.pump();
    ImageInfo info = await isloaded();
    expect(info != null, true);
  });

}
