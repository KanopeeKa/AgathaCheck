import 'package:flutter/material.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Destructive Close care action (CARE-STATUS-MODEL-R-014, R-015).
class CareItemCloseCareButton extends StatelessWidget {
  const CareItemCloseCareButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 1 / 3,
        alignment: Alignment.centerRight,
        child: Semantics(
          identifier: 'care_item_close_care_button',
          button: true,
          child: FilledButton(
            key: const Key('care_item_close_care_button'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              minimumSize: const Size(0, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onPressed,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(l.careCloseCareButton),
            ),
          ),
        ),
      ),
    );
  }
}
