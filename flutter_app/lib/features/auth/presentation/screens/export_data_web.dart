import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

bool get isUserDataExportDeliveryAvailable => true;

Future<bool> deliverUserDataExport(Uint8List bytes) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = 'agatha_track_export.json';
  anchor.click();
  web.URL.revokeObjectURL(url);
  return true;
}
