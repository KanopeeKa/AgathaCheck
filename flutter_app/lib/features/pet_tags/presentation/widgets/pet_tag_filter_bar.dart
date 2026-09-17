import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/collection_filter/collection_filter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet_tag.dart';
import '../providers/pet_tag_providers.dart';

class PetTagFilterBar extends ConsumerWidget {
  const PetTagFilterBar({super.key});

  static const dimensionId = 'pet_tags';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final tagsAsync = ref.watch(petTagListProvider);
    final filter = ref.watch(petTagFilterProvider);

    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        final dimension = CollectionFilterDimension(
          id: dimensionId,
          label: l.petTagsFilterDimension,
          choices: tags
              .map((tag) => CollectionFilterChoice(id: tag.id, label: tag.name))
              .toList(),
          multiSelect: true,
        );
        final selections = <String, Set<String>>{
          dimensionId: Set<String>.from(filter.selectedTagIds),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CollectionFilterBar(
              dimensions: [dimension],
              selections: selections,
              primaryDimensionIds: [dimensionId],
              onSelectionsChanged: (next) {
                ref
                    .read(petTagFilterProvider.notifier)
                    .updateSelections(
                      Set<String>.from(next[dimensionId] ?? const {}),
                    );
              },
            ),
            if (filter.selectedTagIds.length >= 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<PetTagMatchMode>(
                  segments: [
                    ButtonSegment(
                      value: PetTagMatchMode.any,
                      label: Text(l.petTagsMatchAny),
                    ),
                    ButtonSegment(
                      value: PetTagMatchMode.all,
                      label: Text(l.petTagsMatchAll),
                    ),
                  ],
                  selected: {filter.matchMode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(petTagFilterProvider.notifier)
                        .updateMatchMode(selection.first);
                  },
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('pet_tags_manage_link'),
                onPressed: () => context.push('/account/pet-tags'),
                child: Text(l.petTagsManage),
              ),
            ),
          ],
        );
      },
    );
  }
}
