// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop' if (dart.library.js_interop) 'dart:js_interop.dart';
import 'dart:typed_data';
// ignore: uri_does_not_exist
import 'package:web/web.dart' as web if (dart.library.js_interop) 'package:web/web.dart';

Future<void> savePdf(Uint8List bytes, String filename) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
