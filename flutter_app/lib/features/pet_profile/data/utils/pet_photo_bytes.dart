import 'dart:convert';
import 'dart:typed_data';

const int maxPetPhotoBytes = 2 * 1024 * 1024;

const Set<String> allowedPetPhotoExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
};

bool isServerPhotoPath(String? photoPath) {
  if (photoPath == null || photoPath.isEmpty) return false;
  return photoPath.startsWith('/uploads/');
}

bool isPendingPetPhotoUpload(String? photoPath) {
  if (photoPath == null || photoPath.isEmpty) return false;
  if (isServerPhotoPath(photoPath)) return false;
  if (photoPath.startsWith('asset://')) return false;
  return true;
}

Uint8List decodePendingPetPhotoBytes(String photoPath) {
  if (photoPath.startsWith('data:')) {
    final commaIndex = photoPath.indexOf(',');
    if (commaIndex == -1) {
      throw const FormatException('Invalid data URL');
    }
    return base64Decode(photoPath.substring(commaIndex + 1));
  }
  return base64Decode(photoPath);
}

String defaultPetPhotoFilename(String? originalName) {
  final lower = (originalName ?? '').toLowerCase();
  for (final ext in allowedPetPhotoExtensions) {
    if (lower.endsWith(ext)) {
      return 'pet$ext';
    }
  }
  return 'pet.jpg';
}

bool isAllowedPetPhotoFilename(String? filename) {
  final lower = (filename ?? '').toLowerCase();
  return allowedPetPhotoExtensions.any(lower.endsWith);
}
