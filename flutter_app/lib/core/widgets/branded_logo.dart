import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../branding/logo_assets.dart';
import '../../features/experience/domain/entities/app_experience.dart';
import 'web_image.dart';

/// Agatha Track logo image, tinted plum (guardian) or teal (organisation).
class BrandedLogo extends StatelessWidget {
  const BrandedLogo({
    super.key,
    required this.size,
    this.experience,
    this.useJpg = false,
    this.borderRadius,
    this.clipOval = false,
  });

  final double size;
  final AppExperience? experience;
  final bool useJpg;
  final BorderRadius? borderRadius;
  final bool clipOval;

  @override
  Widget build(BuildContext context) {
    final resolved = experience ?? LogoAssets.experienceForContext(context);
    final assetPath = useJpg
        ? LogoAssets.jpgFor(resolved)
        : LogoAssets.pngFor(resolved);

    final fallback = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: clipOval ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: clipOval ? null : (borderRadius ?? BorderRadius.zero),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: size * 0.55,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    Widget image;
    if (kIsWeb && useJpg) {
      image = WebAssetImage(
        assetPath: assetPath,
        height: size,
        width: size,
        fit: BoxFit.cover,
        fallback: fallback,
        clipOval: clipOval,
        semanticsLabel: 'Agatha Track logo',
      );
    } else {
      image = Image.asset(
        assetPath,
        height: size,
        width: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
      if (clipOval) {
        image = ClipOval(child: image);
      } else if (borderRadius != null) {
        image = ClipRRect(borderRadius: borderRadius!, child: image);
      }
    }

    return Semantics(label: 'Agatha Track logo', child: image);
  }
}
