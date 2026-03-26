import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop' if (dart.library.js_interop) 'dart:js_interop.dart';
import 'package:web/web.dart' as web if (dart.library.js_interop) 'package:web/web.dart';

/// Web-only implementation for exporting user data as a file download.
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
