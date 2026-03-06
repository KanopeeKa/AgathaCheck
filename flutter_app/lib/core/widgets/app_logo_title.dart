import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable AppBar title widget that displays the Agatha Track logo
/// followed by the screen title text.
///
/// Tapping the logo navigates to the home page (`/`).
/// Used across all screens to provide consistent branding and navigation.
class AppLogoTitle extends StatelessWidget {
  /// The title text displayed next to the logo.
  final String title;

  const AppLogoTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
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
                'assets/logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
                semanticLabel: 'Agatha Track logo – tap to go home',
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
