import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../branding/logo_assets.dart';
import '../../features/experience/domain/entities/app_experience.dart';

/// A reusable AppBar title widget that displays the AgathaTrack logo
/// followed by the screen title text.
///
/// Tapping the logo navigates to the home page (`/`).
/// Used across all screens to provide consistent branding and navigation.
class AppLogoTitle extends StatelessWidget {
  /// The title text displayed next to the logo.
  final String title;

  static const double _logoSize = 32;
  static const double _titleGap = 8;

  /// Optional experience override; otherwise resolved from the current route.
  final AppExperience? experience;

  /// When false, the logo is not tappable (e.g. section drawer header).
  final bool linkLogo;

  /// When false, only the logo is shown (no title text).
  final bool showTitle;
  final bool useShellLogo;

  const AppLogoTitle({
    super.key,
    required this.title,
    this.experience,
    this.linkLogo = true,
    this.showTitle = true,
    this.useShellLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = experience ?? LogoAssets.experienceForContext(context);
    final assetPath = useShellLogo
        ? LogoAssets.pngForShell(resolved)
        : LogoAssets.pngFor(resolved);
    final logoImage = Image.asset(
      assetPath,
      height: _logoSize,
      width: _logoSize,
      fit: BoxFit.cover,
      semanticLabel: linkLogo
          ? 'AgathaTrack logo – tap to go home'
          : 'AgathaTrack logo',
    );

    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: logoImage,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep logo + title as one compact unit for centered AppBar titles.
        // `Flexible` would expand the row to the full title slot width and leave
        // the logo visually centered with the text lopsided to the right.
        final maxTextWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth - _logoSize - _titleGap)
                .clamp(0.0, double.infinity)
            : MediaQuery.sizeOf(context).width * 0.55;

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
              const SizedBox(width: _titleGap),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTextWidth),
                child: Text(title, overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        );
      },
    );
  }
}
