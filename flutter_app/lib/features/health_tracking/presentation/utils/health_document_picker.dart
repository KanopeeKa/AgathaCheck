import 'package:file_picker/file_picker.dart';

import '../controllers/health_entry_form_constants.dart';

/// Single-file document picker for health photos/PDFs.
///
/// file_picker 12.0.0: [FilePicker.pickFiles] is `Future<List<PlatformFile>>`
/// with `allowMultiple` defaulting to true. Use [FilePicker.pickFile] here.
Future<PlatformFile?> pickSingleHealthDocument() {
  return FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: healthDocumentAllowedExtensions,
  );
}
