import 'package:file_picker/file_picker.dart';

import '../controllers/health_entry_form_constants.dart';

/// Single-file document picker for health photos/PDFs.
///
/// Uses [FilePicker.pickFile] (v12 returns [List<PlatformFile>] from
/// [FilePicker.pickFiles] and defaults [allowMultiple] to true).
Future<PlatformFile?> pickSingleHealthDocument() {
  return FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: healthDocumentAllowedExtensions,
  );
}
