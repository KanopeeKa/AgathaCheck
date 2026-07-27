import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../branding/logo_assets.dart';
import '../../features/experience/domain/entities/app_experience.dart';

/// A reusable AppBar title widget that displays the Agatha Track logo
/// followed by the screen title text.
///
/// Tapping the logo navigates to the home page (`/`).
/// Used across all screens to provide consistent branding and navigation.
class AppLogoTitle extends StatelessWidget {
  /// The title text displayed next to the logo.
  final String title;

  /// Optional experience override; otherwise resolved from the current route.
  final AppExperience? experience;

  /// When false, the logo is not tappable (e.g. section drawer header).
  final bool linkLogo;

  /// When false, only the logo is shown (no title text).
  final bool showTitle;

  const AppLogoTitle({
    super.key,
    required this.title,
    this.experience,
    this.linkLogo = true,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = experience ?? LogoAssets.experienceForContext(context);
    final assetPath = LogoAssets.pngFor(resolved);

    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        assetPath,
        height: 32,
        width: 32,
        fit: BoxFit.cover,
        semanticLabel: linkLogo
            ? 'Agatha Track logo – tap to go home'
            : 'Agatha Track logo',
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (linkLogo)
          GestureDetector(
            onTap: () => context.go('/'),
            child: Tooltip(message: 'Go to home', child: logo),
          )
        else
          logo,
        if (showTitle) ...[
          const SizedBox(width: 8),
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        ],
      ],
    );
  }
}
