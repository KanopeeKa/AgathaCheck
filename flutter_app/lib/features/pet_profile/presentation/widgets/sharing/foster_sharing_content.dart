import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../sharing/domain/entities/share_link.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../domain/entities/pet.dart';
import 'share_link_tile.dart';

class FosterSharingContent extends ConsumerWidget {
  const FosterSharingContent({
    required this.petId,
    required this.pet,
    required this.shareLinks,
  });

  final String petId;
  final Pet pet;
  final List<ShareLink> shareLinks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.fosterSharingDescription(pet.name),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (shareLinks.isNotEmpty) ...[
          ...shareLinks.map(
            (link) => ShareLinkTile(petId: petId, pet: pet, link: link),
          ),
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
    try {
      final code = await ref
          .read(petShareLinksNotifierProvider(petId).notifier)
          .createLink();
      if (context.mounted) {
        _showLinkDialog(context, l, code);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(SnackBar(content: Text(l.linkCopied)));
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l.copyLinkAgain),
          ),
        ],
      ),
    );
  }
}
