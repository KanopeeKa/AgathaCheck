import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/roster.dart';
import '../widgets/person_status_chip.dart';
import 'person_detail_shell.dart';
import 'person_detail_target.dart';

class PersonDetailInviteView extends StatelessWidget {
  const PersonDetailInviteView({
    super.key,
    required this.target,
    required this.embedded,
    required this.roster,
  });

  final PersonDetailPendingInviteTarget target;
  final bool embedded;
  final Roster roster;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final invite = target.invite;

    return PersonDetailShell(
      embedded: embedded,
      personId: invite.id,
      title: invite.email,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            invite.email,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const PersonStatusChip(kind: PersonStatusChipKind.invited),
          const SizedBox(height: 12),
          Text(
            l.peopleDetailPendingInviteBody,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text(
            l.peopleDetailPendingPets,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (invite.petIds.isEmpty)
            Text(
              l.peopleNoLinkedPets,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final petId in invite.petIds)
              ListTile(
                title: Text(rosterPetName(roster, petId) ?? petId),
              ),
          const SizedBox(height: 16),
          Text(
            l.peopleDetailRevokeInEdit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
