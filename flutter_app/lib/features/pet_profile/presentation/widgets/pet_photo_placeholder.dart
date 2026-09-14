import 'package:flutter/material.dart';

/// Bundled default art when a pet has no uploaded photo.
abstract final class PetPhotoPlaceholderAssets {
  static const defaultPhoto = 'assets/pets/pet-photo-placeholder.jpg';
}

/// Watercolor dog-and-cat illustration used across pet photo surfaces.
class PetPhotoPlaceholder extends StatelessWidget {
  const PetPhotoPlaceholder({
    super.key,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      PetPhotoPlaceholderAssets.defaultPhoto,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE8E1E3)),
    );
  }
}
