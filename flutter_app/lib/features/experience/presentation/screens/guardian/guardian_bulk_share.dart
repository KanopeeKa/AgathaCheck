import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';

/// Shows the standard single-pet share link dialog (reused by bulk share).
Future<void> showPetShareLinkDialog(
  BuildContext context,
  WidgetRef ref, {
  required String petId,
  required String petName,
}) async {
  final l = AppLocalizations.of(context)!;
  try {
    final code = await ref.read(petShareLinksNotifierProvider(petId).notifier).createLink();
    if (!context.mounted) return;
    final baseUrl = Uri.base.origin;
    final link = '$baseUrl/#/shared/$code';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.shareLinkTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.shareLinkDescription(petName)),
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
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

/// Runs the existing share-link dialog once per selected owned pet.
Future<void> runBulkShareForPets(
  BuildContext context,
  WidgetRef ref,
  List<({String id, String name})> pets,
) async {
  for (final pet in pets) {
    if (!context.mounted) return;
    await showPetShareLinkDialog(context, ref, petId: pet.id, petName: pet.name);
  }
}
