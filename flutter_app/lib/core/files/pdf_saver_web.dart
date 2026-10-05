import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'pdf_download_user_agent.dart';

Future<void> savePdf(Uint8List bytes, String filename) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url;

  if (shouldOpenPdfInNewBrowserTab(web.window.navigator.userAgent)) {
    anchor.target = '_blank';
    anchor.rel = 'noopener';
  } else {
    anchor.download = filename;
  }

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  // Let the browser start the download or new-tab navigation before revoking.
  Future<void>.delayed(const Duration(seconds: 1), () {
    web.URL.revokeObjectURL(url);
  });
}
