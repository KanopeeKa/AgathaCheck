import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/pet_tag_providers.dart';
import 'pet_tag_picker_sheet.dart';

class PetTagChipRow extends ConsumerWidget {
  const PetTagChipRow({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final tagsAsync = ref.watch(petTagListProvider);
    final theme = Theme.of(context);

    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (allTags) {
        final assigned = allTags
            .where((tag) => tag.petIds.contains(petId))
            .toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.petTagsMyTags,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in assigned)
                    InputChip(
                      key: Key('pet_tag_chip_${tag.id}'),
                      label: Text(tag.name),
                      onDeleted: () => ref
                          .read(petTagListProvider.notifier)
                          .unassignTag(petId, tag.id),
                    ),
                  ActionChip(
                    key: const Key('pet_tag_add_chip'),
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(l.petTagsAssign),
                    onPressed: () => showPetTagPickerSheet(
                      context: context,
                      ref: ref,
                      petId: petId,
                      allTags: allTags,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
