import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/pet.dart';
import '../../../../sharing/domain/entities/pet_access.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../../l10n/app_localizations.dart';

class SharingSection extends ConsumerWidget {
  const SharingSection({required this.petId, required this.pet, super.key});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accessAsync = ref.watch(petAccessNotifierProvider(petId));

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
                data: (accessList) => _SharingContent(
                  petId: petId,
                  pet: pet,
                  accessList: accessList,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharingContent extends ConsumerWidget {
  const _SharingContent({
    required this.petId,
    required this.pet,
    required this.accessList,
  });

  final String petId;
  final Pet pet;
  final List<PetAccess> accessList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (accessList.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l.sharing,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        if (accessList.isNotEmpty) ...[
          ...accessList.map((access) => _AccessTile(
                petId: petId,
                access: access,
              )),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _generateShareLink(context, ref),
            icon: const Icon(Icons.link),
            label: Text(l.shareLinkTitle),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _generateShareLink(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    try {
      final ds = ref.read(sharingDataSourceProvider);
      final code = await ds.createShare(petId, {}, token);
      final baseUrl = Uri.base.origin;
      final link = '$baseUrl/#/shared/$code';
      if (context.mounted) {
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
                label: const Text('Copy'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
