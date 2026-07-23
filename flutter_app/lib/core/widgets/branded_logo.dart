import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../branding/logo_assets.dart';
import '../../features/experience/domain/entities/app_experience.dart';
import '../../features/experience/presentation/providers/experience_providers.dart';
import 'web_image.dart';

/// Agatha Track logo image, tinted plum (guardian) or teal (organisation).
class BrandedLogo extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = experience ?? _resolveExperience(context, ref);
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
      );
    } else {
      image = Image.asset(
        assetPath,
        height: size,
        width: size,
        fit: BoxFit.cover,
        semanticLabel: 'Agatha Track logo',
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

  AppExperience _resolveExperience(BuildContext context, WidgetRef ref) {
    final routeExperience = LogoAssets.experienceForContext(context);
    if (routeExperience == AppExperience.organization) {
      return routeExperience;
    }
    return ref.watch(resolvedExperienceProvider);
  }
}
