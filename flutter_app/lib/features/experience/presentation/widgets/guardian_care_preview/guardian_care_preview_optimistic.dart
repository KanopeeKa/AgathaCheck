import 'package:flutter/material.dart';

import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/mobile_due_event_row.dart';
import '../../../../pet_profile/domain/entities/pet.dart';

/// A due entry optimistically marked complete on the compact Care preview.
///
/// Retained at [previewIndex] through the real server refresh so its approved
/// completed presentation stays visible in place.
class GuardianCareOptimisticCompletion {
  const GuardianCareOptimisticCompletion({
    required this.entry,
    required this.previewIndex,
  });

  /// The entry snapshot captured when the user confirmed completion.
  final HealthEntry entry;

  /// The index this item held in its Care preview at completion.
  final int previewIndex;
}

/// A single item in the merged mobile preview: due or optimistically completed.
class GuardianCarePreviewItem {
  const GuardianCarePreviewItem._(this.entry, this.isCompleted);

  factory GuardianCarePreviewItem.due(HealthEntry entry) =>
      GuardianCarePreviewItem._(entry, false);

  factory GuardianCarePreviewItem.completed(HealthEntry entry) =>
      GuardianCarePreviewItem._(entry, true);

  final HealthEntry entry;
  final bool isCompleted;
}

/// Builds the ordered Care preview by merging fresh entries with retained
/// optimistic-completed items at their original indices.
List<GuardianCarePreviewItem> buildGuardianCareMobilePreview({
  required List<HealthEntry> dueEntries,
  required Map<String, GuardianCareOptimisticCompletion> completed,
  required int previewLimit,
}) {
  final completedItems = completed.values.toList()
    ..sort((a, b) => a.previewIndex.compareTo(b.previewIndex));
  final completedIds = completedItems.map((item) => item.entry.id).toSet();

  final freshDue = dueEntries
      .where((entry) => !completedIds.contains(entry.id))
      .toList();

  final result = <GuardianCarePreviewItem?>[];

  for (final completion in completedItems) {
    final index = completion.previewIndex.clamp(0, previewLimit - 1).toInt();
    while (result.length <= index) {
      result.add(null);
    }
    if (result[index] == null) {
      result[index] = GuardianCarePreviewItem.completed(completion.entry);
    } else {
      result.add(GuardianCarePreviewItem.completed(completion.entry));
    }
  }

  final dueQueue = List<HealthEntry>.from(freshDue);
  for (var i = 0; i < result.length && dueQueue.isNotEmpty; i++) {
    if (result[i] == null) {
      result[i] = GuardianCarePreviewItem.due(dueQueue.removeAt(0));
    }
  }
  while (dueQueue.isNotEmpty && result.length < previewLimit) {
    result.add(GuardianCarePreviewItem.due(dueQueue.removeAt(0)));
  }

  final compacted = result.whereType<GuardianCarePreviewItem>().toList();
  if (compacted.length > previewLimit) {
    return compacted.sublist(0, previewLimit);
  }
  return compacted;
}

/// Renders merged preview items as [MobileDueEventRow] items.
class GuardianCarePreviewEventList extends StatelessWidget {
  const GuardianCarePreviewEventList({
    super.key,
    required this.items,
    required this.petMap,
    required this.onMarkDone,
    required this.onUndo,
    required this.onOpen,
  });

  final List<GuardianCarePreviewItem> items;
  final Map<String, Pet> petMap;
  final void Function(HealthEntry entry, int previewIndex) onMarkDone;
  final void Function(HealthEntry entry) onUndo;
  final void Function(HealthEntry entry) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('mobile_due_event_list'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          MobileDueEventRow(
            key: Key('mobile_due_row_${items[i].entry.id}'),
            entry: items[i].entry,
            pet: petMap[items[i].entry.petId],
            isCompleted: items[i].isCompleted,
            onMarkDone: () => onMarkDone(items[i].entry, i),
            onUndo: () => onUndo(items[i].entry),
            onOpen: () => onOpen(items[i].entry),
          ),
      ],
    );
  }
}
