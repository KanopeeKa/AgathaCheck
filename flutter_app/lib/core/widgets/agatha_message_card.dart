import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';

/// Shared Agatha / Care Intelligence suggestion card chrome (tokens.md).
abstract final class AgathaMessageCardShell {
  static const EdgeInsets contentPadding = EdgeInsets.all(16);
  static const EdgeInsets defaultMargin = EdgeInsets.fromLTRB(16, 8, 16, 8);

  static TextStyle titleStyle(TextTheme textTheme) {
    return textTheme.titleSmall!.copyWith(
      color: AppColorTokens.agathaTeal,
      fontWeight: FontWeight.w600,
    );
  }

  /// Plum primary CTAs clash on Agatha message cards — use darker teal actions.
  static ThemeData suggestionActionsTheme(ThemeData base) {
    final action = AppColorTokens.agathaTealAction;
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: action,
          foregroundColor: AppColorTokens.inverse,
          disabledBackgroundColor: action.withValues(alpha: 0.38),
          disabledForegroundColor: AppColorTokens.inverse.withValues(
            alpha: 0.6,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: action,
          side: BorderSide(color: action),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: action),
      ),
    );
  }
}

/// Card wrapper with Agatha message surface and border.
class AgathaMessageCard extends StatelessWidget {
  const AgathaMessageCard({
    super.key,
    required this.child,
    this.margin = AgathaMessageCardShell.defaultMargin,
    this.themeSuggestionActions = false,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  /// When true, Accept / Why / text actions use [AgathaMessageCardShell.suggestionActionsTheme].
  final bool themeSuggestionActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 0,
      color: AppColorTokens.agathaMessageSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColorTokens.agathaMessageBorder),
      ),
      child: Padding(
        padding: AgathaMessageCardShell.contentPadding,
        child: themeSuggestionActions
            ? Theme(
                data: AgathaMessageCardShell.suggestionActionsTheme(
                  Theme.of(context),
                ),
                child: child,
              )
            : child,
      ),
    );
  }
}
