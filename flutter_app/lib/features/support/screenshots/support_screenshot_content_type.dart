import 'package:http_parser/http_parser.dart';

import 'support_screenshot_limits.dart';

MediaType contentTypeForSupportScreenshot(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  }
  return MediaType('image', 'jpeg');
}

bool isAllowedSupportScreenshotFilename(String? filename) {
  if (filename == null || filename.isEmpty) return false;
  final lower = filename.toLowerCase();
  return supportScreenshotAllowedExtensions.any(lower.endsWith);
}
