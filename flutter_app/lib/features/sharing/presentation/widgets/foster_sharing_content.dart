import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/share_link.dart';
import '../providers/sharing_providers.dart';
import 'share_link_created_dialog.dart';
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
}
