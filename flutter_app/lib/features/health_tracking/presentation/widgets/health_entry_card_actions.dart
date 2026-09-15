import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';

class HealthEntryOpenButton extends StatelessWidget {
  const HealthEntryOpenButton({super.key, this.onPressed, this.semanticKey});

  final VoidCallback? onPressed;
  final Key? semanticKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      key: semanticKey,
      width: 48,
      child: Material(
        color: AppColorTokens.surfaceAlt,
        child: InkWell(
          onTap: onPressed,
          splashColor: AppColorTokens.border,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.open_in_new, size: 18, color: AppColorTokens.muted),
                const SizedBox(height: 2),
                Text(
                  l.open,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColorTokens.muted,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthEntryMarkDoneButton extends StatelessWidget {
  const HealthEntryMarkDoneButton({
    super.key,
    this.onPressed,
    required this.petStripWidth,
  });

  final VoidCallback? onPressed;
  final double petStripWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: petStripWidth * 2,
      child: Material(
        color: AppColorTokens.successLight,
        child: InkWell(
          onTap: onPressed,
          splashColor: AppColorTokens.successLight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 22,
                  color: AppColorTokens.success,
                ),
                const SizedBox(height: 4),
                Text(
                  l.markAsDone,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColorTokens.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthEntryUndoCompleteButton extends StatelessWidget {
  const HealthEntryUndoCompleteButton({
    super.key,
    this.onPressed,
    required this.petStripWidth,
  });

  final VoidCallback? onPressed;
  final double petStripWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: petStripWidth * 2,
      child: Material(
        color: AppColorTokens.warmAccentLight,
        child: InkWell(
          onTap: onPressed,
          splashColor: AppColorTokens.warmAccentLight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.undo, size: 22, color: AppColorTokens.warmAccent),
                const SizedBox(height: 4),
                Text(
                  l.undoComplete,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColorTokens.heading,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
