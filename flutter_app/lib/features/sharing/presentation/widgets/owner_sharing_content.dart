import 'package:flutter/material.dart';

import '../../../../core/widgets/form/app_form_labeled_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/pet_access.dart';
import '../../domain/entities/share_link.dart';
import '../providers/sharing_providers.dart';
import 'access_tile.dart';
import 'share_link_created_dialog.dart';
import 'share_link_tile.dart';

class OwnerSharingContent extends ConsumerWidget {
  const OwnerSharingContent({
    required this.petId,
    required this.pet,
    required this.accessList,
    required this.shareLinks,
    this.canTransferOwnership = true,
  });

  final String petId;
  final Pet pet;
  final List<PetAccess> accessList;
  final List<ShareLink> shareLinks;
  final bool canTransferOwnership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shareLinks.isEmpty && accessList.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l.sharing,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (shareLinks.isNotEmpty) ...[
          ...shareLinks.map(
            (link) => ShareLinkTile(petId: petId, pet: pet, link: link),
          ),
          const SizedBox(height: 8),
        ],
        ...accessList
            .where(
              (access) => !shareLinks.any(
                (link) => link.isActive && link.claimedBy == access.userId,
              ),
            )
            .map((access) => AccessTile(petId: petId, access: access)),
        if (accessList.isNotEmpty) const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _generateShareLink(context, ref),
            icon: const Icon(Icons.link),
            label: Text(l.shareLinkTitle),
          ),
        ),
        if (canTransferOwnership) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('transfer_ownership_button'),
              onPressed: () => _showTransferDialog(context, ref, l),
              icon: const Icon(Icons.swap_horiz),
              label: Text(l.transferOwnership),
            ),
          ),
        ],
        if (pet.isShared && pet.accessRole == PetAccessRole.coParent) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmHide(context, ref, l),
              icon: const Icon(Icons.visibility_off),
              label: Text(l.hideFromMyPets),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _generateShareLink(BuildContext context, WidgetRef ref) async {
    try {
      final code = await ref
          .read(petShareLinksNotifierProvider(petId).notifier)
          .createLink();
      if (context.mounted) {
        await ShareLinkCreatedDialog.show(
          context,
          petName: pet.name,
          shareCode: code,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _confirmHide(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.hideFromMyPets),
        content: Text(l.hideSharedPetConfirm(pet.name)),
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
                    .read(hiddenSharedPetsProvider.notifier)
                    .hideSharedPet(petId);
                if (context.mounted) context.go('/');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(l.hideFromMyPets),
          ),
        ],
      ),
    );
  }

  Future<void> _showTransferDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.transferOwnership),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.transferOwnershipDescription,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              AppFormLabeledField(
                label: l.recipientEmail,
                child: TextFormField(
                  key: const Key('transfer_recipient_email'),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return l.orgInviteEmailRequired;
                    if (!email.contains('@')) return l.orgInviteEmailInvalid;
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              AppFormLabeledField(
                label: l.transferNameConfirmationHint,
                child: TextFormField(
                  key: const Key('transfer_confirmation_name'),
                  controller: nameController,
                  decoration: const InputDecoration(),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) {
                      return l.transferNameConfirmationHint;
                    }
                    if (value!.trim().toLowerCase() !=
                        pet.name.trim().toLowerCase()) {
                      return l.transferNameMismatch;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            key: const Key('transfer_ownership_confirm'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l.confirmTransfer),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      emailController.dispose();
      nameController.dispose();
      return;
    }

    try {
      await ref
          .read(petAccessNotifierProvider(petId).notifier)
          .transferOwnership(
            recipientEmail: emailController.text.trim(),
            confirmationName: nameController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.transferSuccess)));
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      emailController.dispose();
      nameController.dispose();
    }
  }
}
