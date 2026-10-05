import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Shared Mark done action for care rows (care-item-bulk-scope-spec FR-18).
///
/// Round filled control with [Icons.check_circle], 40dp visual inside 48dp touch.
class CareMarkDoneButton extends StatelessWidget {
  const CareMarkDoneButton({
    super.key,
    required this.onPressed,
    this.semanticLabel,
    this.semanticsIdentifier,
  });

  final VoidCallback? onPressed;

  /// Screen-reader label; defaults to the localized "Mark as done".
  final String? semanticLabel;

  /// Stable `flt-semantics-identifier` for E2E locators.
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
      label: semanticLabel ?? l.markAsDone,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: semanticLabel ?? l.markAsDone,
        child: IconButton.filled(
          onPressed: onPressed,
          icon: const Icon(Icons.check_circle),
          iconSize: iconSize,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.onSurface.withValues(
              alpha: 0.12,
            ),
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
