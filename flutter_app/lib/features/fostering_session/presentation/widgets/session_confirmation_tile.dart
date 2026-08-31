import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

class SessionConfirmationTile extends StatelessWidget {
  const SessionConfirmationTile({
    super.key,
    required this.label,
    required this.confirmed,
    this.confirmedAt,
  });

  final String label;
  final bool confirmed;
  final DateTime? confirmedAt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: confirmed ? colorScheme.primary : colorScheme.outline,
      ),
      title: Text(label),
      subtitle: confirmed && confirmedAt != null
          ? Text(
              l.fosteringSessionConfirmedAt(
                DateFormat.yMMMd().add_jm().format(confirmedAt!.toLocal()),
              ),
            )
          : Text(
              l.fosteringSessionAwaitingConfirmation,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
    );
  }
}
