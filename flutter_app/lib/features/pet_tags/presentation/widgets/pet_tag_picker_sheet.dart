import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet_tag.dart';
import '../providers/pet_tag_providers.dart';

Future<void> showPetTagPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String petId,
  required List<PetTag> allTags,
}) {
  final assignedIds = allTags
      .where((tag) => tag.petIds.contains(petId))
      .map((tag) => tag.id)
      .toSet();
  final available = allTags
      .where((tag) => !assignedIds.contains(tag.id))
      .toList();

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l = AppLocalizations.of(context)!;
      if (available.isEmpty) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.petTagsCreateInSettings, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/account/pet-tags');
                  },
                  child: Text(l.petTagsManage),
                ),
              ],
            ),
          ),
        );
      }

      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l.petTagsAssign,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final tag in available)
              ListTile(
                key: Key('pet_tag_pick_${tag.id}'),
                title: Text(tag.name),
                onTap: () async {
                  await ref
                      .read(petTagListProvider.notifier)
                      .assignTag(petId, tag.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
          ],
        ),
      );
    },
  );
}
