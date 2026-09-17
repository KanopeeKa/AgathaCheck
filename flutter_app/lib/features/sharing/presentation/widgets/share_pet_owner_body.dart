import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/pet_access.dart';
import '../../domain/entities/share_invite.dart';
import '../../domain/entities/share_link.dart';
import '../providers/share_pet_providers.dart';
import 'owner_sharing_content.dart';
import 'pending_invite_tile.dart';
import 'share_invite_form.dart';

/// Full sharing controls for owners and co-parents.
class SharePetOwnerBody extends ConsumerWidget {
  const SharePetOwnerBody({
    required this.pet,
    required this.allPetIds,
    required this.accessList,
    required this.shareLinks,
    required this.pendingInvites,
    required this.canTransferOwnership,
    required this.onInviteSent,
  });

  final Pet pet;
  final List<String> allPetIds;
  final List<PetAccess> accessList;
  final List<ShareLink> shareLinks;
  final List<ShareInvite> pendingInvites;
  final bool canTransferOwnership;
  final VoidCallback onInviteSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shareState = ref.watch(sharePetNotifierProvider(allPetIds));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShareInviteForm(
          petCount: allPetIds.length,
          isSending: shareState.isSendingInvite,
          onSubmit: (email, role) async {
            try {
              await ref
                  .read(sharePetNotifierProvider(allPetIds).notifier)
                  .sendInvite(inviteeEmail: email, role: role);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.shareInviteSent)),
                );
                onInviteSent();
              }
            } catch (e) {
              if (context.mounted) {
                final msg = e.toString().replaceFirst('Exception: ', '');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
              }
            }
          },
        ),
        const SizedBox(height: 20),
        if (pendingInvites.isNotEmpty) ...[
          Text(l.shareInvitePendingSection, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...pendingInvites.map(
            (invite) => PendingInviteTile(
              invite: invite,
              onCancel: () => _confirmCancel(context, ref, invite, l),
            ),
          ),
          const SizedBox(height: 16),
        ],
        OwnerSharingContent(
          petId: pet.id,
          pet: pet,
          accessList: accessList,
          shareLinks: shareLinks,
          canTransferOwnership: canTransferOwnership,
        ),
      ],
    );
  }

  void _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    ShareInvite invite,
    AppLocalizations l,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.shareInviteCancel),
        content: Text(l.shareInviteCancelConfirm(invite.inviteeEmail)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(sharePetNotifierProvider(allPetIds).notifier)
                    .cancelInvite(invite.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            child: Text(l.shareInviteCancel),
          ),
        ],
      ),
    );
  }
}
