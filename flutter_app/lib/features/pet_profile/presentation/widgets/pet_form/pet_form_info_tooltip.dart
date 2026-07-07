import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Info icon that opens a dialog with helper text for pet form fields.
class PetFormInfoTooltip extends StatelessWidget {
  const PetFormInfoTooltip({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return IconButton(
      icon: Icon(
        Icons.info_outline,
        size: 18,
        color: Theme.of(context).colorScheme.outline,
      ),
      tooltip: message,
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.ok),
              ),
            ],
          ),
        );
      },
    );
  }
}
