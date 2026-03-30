import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> exportUserDataWebOnly(List<int> bytes) async {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = 'agatha_track_export.json';
  anchor.click();
  web.URL.revokeObjectURL(url);
}
