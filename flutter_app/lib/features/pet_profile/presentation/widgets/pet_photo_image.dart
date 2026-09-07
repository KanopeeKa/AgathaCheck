import 'package:flutter/material.dart';

import '../../../../core/utils/resolve_static_asset_url.dart';
import '../../data/utils/pet_photo_bytes.dart';

/// Renders a pet photo from a server path, inline base64/data URL, or asset URI.
Widget? buildPetPhotoImage({
  required String? photoPath,
  required String apiBaseUrl,
  required BoxFit fit,
  String? semanticLabel,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (photoPath == null || photoPath.isEmpty) return null;

  if (photoPath.startsWith('asset://')) {
    return Image.asset(
      photoPath.substring('asset://'.length),
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: errorBuilder,
    );
  }

  if (isServerPhotoPath(photoPath) ||
      photoPath.startsWith('http://') ||
      photoPath.startsWith('https://')) {
    final url = photoPath.startsWith('http')
        ? photoPath
        : resolveStaticAssetUrl(photoPath, apiBaseUrl: apiBaseUrl);
    if (url.isEmpty) return null;
    return Image.network(
      url,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: errorBuilder,
    );
  }

  try {
    final bytes = decodePendingPetPhotoBytes(photoPath);
    return Image.memory(
      bytes,
      fit: fit,
      semanticLabel: semanticLabel,
    );
  } catch (_) {
    return null;
  }
}
