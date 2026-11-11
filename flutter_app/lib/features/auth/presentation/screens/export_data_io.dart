import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

const _exportFileName = 'agatha_track_export.json';

bool get isUserDataExportDeliveryAvailable => true;

/// Returns `true` when the user saved the file, `false` when they cancelled.
Future<bool> deliverUserDataExport(Uint8List bytes) async {
  final uri = await FilePicker.saveFile(
    fileName: _exportFileName,
    bytes: bytes,
    mimeType: 'application/json',
  );
  return uri != null;
}
