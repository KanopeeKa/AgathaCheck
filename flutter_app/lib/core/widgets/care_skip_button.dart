import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Shared Skip action for care occurrence rows (care-item-bulk-scope-spec FR-19).
class CareSkipButton extends StatelessWidget {
  const CareSkipButton({
    super.key,
    required this.onPressed,
    this.semanticLabel,
    this.semanticsIdentifier,
  });

  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? semanticsIdentifier;

  static const double visualSize = 40;
  static const double touchTargetSize = 48;
  static const double iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      identifier: semanticsIdentifier,
      label: semanticLabel ?? l.careSkip,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: semanticLabel ?? l.careSkip,
        child: IconButton.outlined(
          onPressed: onPressed,
          icon: const Icon(Icons.skip_next),
          iconSize: iconSize,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.primary,
            disabledForegroundColor: colorScheme.onSurface.withValues(
              alpha: 0.38,
            ),
            fixedSize: const Size.square(visualSize),
            minimumSize: const Size.square(visualSize),
            tapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }
}
