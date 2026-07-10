import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../sharing/domain/entities/pet_access.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';

class AccessTile extends ConsumerWidget {
  const AccessTile({required this.petId, required this.access});

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

    final resolvedPhotoUrl = resolveStaticAssetUrl(
      user?.photoUrl ?? '',
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        backgroundImage: resolvedPhotoUrl.isNotEmpty
            ? NetworkImage(resolvedPhotoUrl)
            : null,
        child: resolvedPhotoUrl.isEmpty
            ? Text(initials)
            : null,
      ),
      title: Text(displayName),
      subtitle: Text(
        roleLabel,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
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
                Icon(
                  Icons.person_remove,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  l.removeAccess,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    String name,
    AppLocalizations l,
  ) {
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
              await ref
                  .read(petAccessNotifierProvider(petId).notifier)
                  .removeAccess(access.userId);
            },
            child: Text(l.removeAccess),
          ),
        ],
      ),
    );
  }
}
