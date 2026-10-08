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
}

/// Card wrapper with Agatha message surface and border.
class AgathaMessageCard extends StatelessWidget {
  const AgathaMessageCard({
    super.key,
    required this.child,
    this.margin = AgathaMessageCardShell.defaultMargin,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

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
        child: child,
      ),
    );
  }
}
