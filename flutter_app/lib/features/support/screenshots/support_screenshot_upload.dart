import 'dart:typed_data';

/// In-memory screenshot pending upload with the support ticket.
class SupportScreenshotUpload {
  const SupportScreenshotUpload({
    required this.filename,
    required this.bytes,
  });

  final String filename;
  final Uint8List bytes;
}
