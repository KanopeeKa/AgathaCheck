import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet_access.dart';
import '../../domain/entities/share_invite.dart';

class PendingInviteTile extends StatelessWidget {
  const PendingInviteTile({
    required this.invite,
    required this.onCancel,
  });

  final ShareInvite invite;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final roleLabel = invite.role == PetAccessRole.coParent
        ? l.coParent
        : l.shareInviteRoleCarer;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      child: ListTile(
        leading: Icon(Icons.mail_outline, color: theme.colorScheme.primary),
        title: Text(invite.inviteeEmail),
        subtitle: Text(
          l.shareInvitePendingStatus(roleLabel),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          tooltip: l.shareInviteCancel,
          icon: Icon(Icons.close, color: theme.colorScheme.error),
          onPressed: onCancel,
        ),
      ),
    );
  }
}
