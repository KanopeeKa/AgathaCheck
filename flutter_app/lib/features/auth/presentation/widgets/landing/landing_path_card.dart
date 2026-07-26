import 'package:flutter/material.dart';

/// Landing path button — scrolls to an audience section below the hero.
class LandingPathCard extends StatelessWidget {
  const LandingPathCard({
    super.key,
    required this.summary,
    required this.actionLabel,
    required this.accentColor,
    required this.onAccentColor,
    required this.icon,
    required this.onPressed,
  });

  final String summary;
  final String actionLabel;
  final Color accentColor;
  final Color onAccentColor;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '$summary. $actionLabel',
      child: Material(
        color: accentColor,
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: onAccentColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summary,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onAccentColor,
                      height: 1.35,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward, color: onAccentColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
