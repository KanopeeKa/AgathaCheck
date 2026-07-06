import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../sharing/domain/entities/share_link.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../domain/entities/pet.dart';

class ShareLinkTile extends ConsumerWidget {
  const ShareLinkTile({
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
