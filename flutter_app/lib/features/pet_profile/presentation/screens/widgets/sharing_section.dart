import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/pet.dart';
import '../../../../sharing/domain/entities/pet_access.dart';
import '../../../../sharing/domain/entities/share_link.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../../../l10n/app_localizations.dart';

class SharingSection extends ConsumerWidget {
  const SharingSection({required this.petId, required this.pet, super.key});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (pet.isShared) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(Icons.people, color: theme.colorScheme.primary),
            title: Text(l.sharingSection,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _FollowerSharingContent(petId: petId, pet: pet),
              ),
            ],
          ),
        ),
      );
    }

    final accessAsync = ref.watch(petAccessNotifierProvider(petId));
    final linksAsync = ref.watch(petShareLinksNotifierProvider(petId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.people, color: theme.colorScheme.primary),
          title: Text(l.sharingSection,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: accessAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l.couldNotLoadSharingInfo,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
                data: (accessList) => linksAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l.couldNotLoadSharingInfo,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
                  data: (links) => _OwnerSharingContent(
                    petId: petId,
                    pet: pet,
                    accessList: accessList,
                    shareLinks: links,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowerSharingContent extends ConsumerWidget {
  const _FollowerSharingContent({required this.petId, required this.pet});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.sharedPetFollowerDescription(pet.name),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmStopFollowing(context, ref, l),
            icon: const Icon(Icons.person_remove),
            label: Text(l.stopFollowing),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _confirmStopFollowing(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.stopFollowing),
        content: Text(l.stopFollowingConfirm(pet.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await stopFollowingPet(ref, petId);
                if (context.mounted) context.go('/');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(l.stopFollowing),
          ),
        ],
      ),
    );
  }
}

class _OwnerSharingContent extends ConsumerWidget {
  const _OwnerSharingContent({
    required this.petId,
    required this.pet,
    required this.accessList,
    required this.shareLinks,
  });

  final String petId;
  final Pet pet;
  final List<PetAccess> accessList;
  final List<ShareLink> shareLinks;

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
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        if (shareLinks.isNotEmpty) ...[
          ...shareLinks.map((link) => _ShareLinkTile(petId: petId, pet: pet, link: link)),
          const SizedBox(height: 8),
        ],
        ...accessList
            .where((access) => !shareLinks.any((link) =>
                link.isActive && link.claimedBy == access.userId))
            .map((access) => _AccessTile(petId: petId, access: access)),
        if (accessList.isNotEmpty) const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _generateShareLink(context, ref),
            icon: const Icon(Icons.link),
            label: Text(l.shareLinkTitle),
          ),
        ),
        if (pet.organizationId == null) ...[
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
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _generateShareLink(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    try {
      final code = await ref.read(petShareLinksNotifierProvider(petId).notifier).createLink();
      if (context.mounted) {
        _showLinkDialog(context, l, code);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showLinkDialog(BuildContext context, AppLocalizations l, String code) {
    final baseUrl = Uri.base.origin;
    final link = '$baseUrl/#/shared/$code';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.shareLinkTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.shareLinkDescription(pet.name)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(link, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).closeButtonLabel),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(l.linkCopied)),
              );
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l.copyLinkAgain),
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
              TextFormField(
                key: const Key('transfer_recipient_email'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l.recipientEmail,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return l.orgInviteEmailRequired;
                  if (!email.contains('@')) return l.orgInviteEmailInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('transfer_confirmation_name'),
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l.transferNameConfirmationHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value?.trim() ?? '').isEmpty) {
                    return l.transferNameConfirmationHint;
                  }
                  if (value!.trim().toLowerCase() != pet.name.trim().toLowerCase()) {
                    return l.transferNameMismatch;
                  }
                  return null;
                },
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
      await ref.read(petAccessNotifierProvider(petId).notifier).transferOwnership(
            recipientEmail: emailController.text.trim(),
            confirmationName: nameController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.transferSuccess)),
        );
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      emailController.dispose();
      nameController.dispose();
    }
  }
}

class _ShareLinkTile extends ConsumerWidget {
  const _ShareLinkTile({
    required this.petId,
    required this.pet,
    required this.link,
  });

  final String petId;
  final Pet pet;
  final ShareLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final baseUrl = Uri.base.origin;
    final url = '$baseUrl/#/shared/${link.code}';

    final statusLabel = link.isActive && (link.claimedByName?.isNotEmpty ?? false)
        ? l.sharingWithActive(link.claimedByName!)
        : l.shareLinkPending;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  link.isActive ? Icons.check_circle_outline : Icons.schedule,
                  size: 20,
                  color: link.isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(statusLabel, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.linkCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(l.copyLinkAgain),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l.deleteLink,
                  onPressed: () => _confirmDelete(context, ref, l),
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteLink),
        content: Text(l.deleteShareLinkConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(petShareLinksNotifierProvider(petId).notifier).deleteLink(link.id);
            },
            child: Text(l.deleteLink),
          ),
        ],
      ),
    );
  }
}

class _AccessTile extends ConsumerWidget {
  const _AccessTile({required this.petId, required this.access});

  final String petId;
  final PetAccess access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = access.user;
    final displayName = user?.displayName ?? 'User #${access.userId}';
    final initials = user?.initials ?? '?';
    final isGuardian = access.role == PetAccessRole.guardian;
    final roleLabel = isGuardian ? l.guardian : l.sharing;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        backgroundImage: user?.photoUrl != null && user!.photoUrl.isNotEmpty
            ? NetworkImage(user.photoUrl)
            : null,
        child: user?.photoUrl == null || user!.photoUrl.isEmpty
            ? Text(initials)
            : null,
      ),
      title: Text(displayName),
      subtitle: Text(roleLabel, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'remove') {
            _confirmRemove(context, ref, displayName, l);
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.person_remove, size: 20, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(l.removeAccess, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, String name, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.removeAccess),
        content: Text('${l.removeAccess}: $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(petAccessNotifierProvider(petId).notifier).removeAccess(access.userId);
            },
            child: Text(l.removeAccess),
          ),
        ],
      ),
    );
  }
}
