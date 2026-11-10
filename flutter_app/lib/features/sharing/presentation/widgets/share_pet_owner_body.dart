import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_state/supplemental_state_caption.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/pet_profile.dart';
import '../../domain/entities/pet_access.dart';
import '../../domain/entities/share_invite.dart';
import '../providers/share_pet_providers.dart';
import '../sharing_error_messages.dart';
import 'owner_sharing_content.dart';
import 'pending_invite_tile.dart';
import 'share_invite_form.dart';

/// Full sharing controls for owners and co-parents.
class SharePetOwnerBody extends ConsumerWidget {
  const SharePetOwnerBody({
    required this.pet,
    required this.allPetIds,
    required this.accessList,
    required this.pendingInvites,
    required this.accessLoading,
    required this.accessFailed,
    required this.canTransferOwnership,
    required this.onInviteSent,
    required this.onRetryAccess,
    this.prefillEmail,
    this.contactId,
  });

  final Pet pet;
  final List<String> allPetIds;
  final List<PetAccess> accessList;
  final List<ShareInvite> pendingInvites;
  final bool accessLoading;
  final bool accessFailed;
  final bool canTransferOwnership;
  final VoidCallback onInviteSent;
  final VoidCallback onRetryAccess;
  final String? prefillEmail;
  final String? contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shareState = ref.watch(sharePetNotifierProvider(allPetIds));
    final accessResolved = !accessLoading && !accessFailed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShareInviteForm(
          petCount: allPetIds.length,
          isSending: shareState.isSendingInvite,
          initialEmail: prefillEmail,
          onSubmit: (email, role) async {
            try {
              await ref
                  .read(sharePetNotifierProvider(allPetIds).notifier)
                  .sendInvite(
                    inviteeEmail: email,
                    role: role,
                    contactId: contactId,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l.shareInviteSent)));
                onInviteSent();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(sharingMutationErrorMessage(l, e))),
                );
              }
            }
          },
        ),
        const SizedBox(height: 20),
        if (accessLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SupplementalStateCaption(
              state: SupplementalState.loading,
              label: l.shareAccessUnavailable,
            ),
          )
        else if (accessFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SupplementalStateCaption(
              state: SupplementalState.unavailable,
              label: l.shareAccessUnavailable,
              onRetry: onRetryAccess,
              retryKey: const Key('share_pet_access_retry'),
            ),
          ),
        if (accessResolved && pendingInvites.isNotEmpty) ...[
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
          accessResolved: accessResolved,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sharingMutationErrorMessage(l, e))),
                  );
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
