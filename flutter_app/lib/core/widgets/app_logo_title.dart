import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../branding/logo_assets.dart';
import '../../features/experience/domain/entities/app_experience.dart';
import '../../features/experience/presentation/providers/experience_providers.dart';

/// A reusable AppBar title widget that displays the Agatha Track logo
/// followed by the screen title text.
///
/// Tapping the logo navigates to the home page (`/`).
/// Used across all screens to provide consistent branding and navigation.
class AppLogoTitle extends ConsumerWidget {
  /// The title text displayed next to the logo.
  final String title;

  /// Optional experience override; otherwise resolved from route + preferences.
  final AppExperience? experience;

  const AppLogoTitle({super.key, required this.title, this.experience});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = experience ?? _resolveExperience(context, ref);
    final assetPath = LogoAssets.pngFor(resolved);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.go('/'),
          child: Tooltip(
            message: 'Go to home',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                assetPath,
                height: 32,
                width: 32,
                fit: BoxFit.cover,
                semanticLabel: 'Agatha Track logo – tap to go home',
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  AppExperience _resolveExperience(BuildContext context, WidgetRef ref) {
    final routeExperience = LogoAssets.experienceForContext(context);
    if (routeExperience == AppExperience.organization) {
      return routeExperience;
    }
    return ref.watch(activeExperienceProvider) ?? AppExperience.guardian;
  }
}
