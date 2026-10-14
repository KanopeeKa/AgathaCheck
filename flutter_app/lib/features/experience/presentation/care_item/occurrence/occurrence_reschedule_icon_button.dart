import 'package:flutter/material.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Icon reschedule control for Care date Block 2 (CARE-ITEM-R-018).
class OccurrenceRescheduleIconButton extends StatelessWidget {
  const OccurrenceRescheduleIconButton({
    super.key,
    required this.onPressed,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final String? semanticLabel;

  static const double visualSize = 40;
  static const double iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      identifier: 'occurrence_reschedule',
      label: semanticLabel ?? l.rescheduleActionLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: semanticLabel ?? l.rescheduleActionLabel,
        child: IconButton.outlined(
          key: const Key('occurrence_reschedule'),
          onPressed: onPressed,
          icon: const Icon(Icons.edit_calendar_outlined),
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
