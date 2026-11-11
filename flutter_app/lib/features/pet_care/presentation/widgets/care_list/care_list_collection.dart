import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import '../care_surface/care_collection_inset_list.dart';
import 'care_list_card.dart';
import 'care_list_inset_items.dart';

/// Global All care planned section: multi-line cards in Today and Upcoming.
class CareListCollection extends ConsumerStatefulWidget {
  const CareListCollection({
    super.key,
    required this.entries,
    required this.source,
    this.petNames,
    this.empty,
  });

  final List<HealthEntry> entries;
  final CareCommandSource source;
  final Map<String, String>? petNames;
  final Widget? empty;

  @override
  ConsumerState<CareListCollection> createState() => _CareListCollectionState();
}

class _CareListCollectionState extends ConsumerState<CareListCollection> {
  bool _upcomingExpanded = false;
  DateTime _readAt = DateTime.now();
  Timer? _minute;

  @override
  void initState() {
    super.initState();
    _minute = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_readAt);
      if (elapsed >= const Duration(minutes: 15) ||
          _crossedPetHomeMidnight(elapsed)) {
        _refreshHealthEntries();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(CareListCollection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.entries, widget.entries)) {
      _readAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _minute?.cancel();
    super.dispose();
  }

  Future<void> _refreshHealthEntries() async {
    await ref.read(healthEntriesNotifierProvider.notifier).refresh();
    if (mounted) _readAt = DateTime.now();
  }

  Future<void> _refreshAfterCareCommand() async {
    await ref.read(careDataChangedProvider)();
    if (mounted) _readAt = DateTime.now();
  }

  bool _crossedPetHomeMidnight(Duration elapsed) {
    if (elapsed <= Duration.zero) return false;
    final minutes = elapsed.inMinutes;
    for (final entry in widget.entries) {
      final asOf = entry.schedule?.asOf;
      if (asOf == null) continue;
      if (asOf.minutes + minutes >= 24 * 60) return true;
    }
    return false;
  }

  void _open(HealthEntry entry) {
    goToPetEventView(context, petId: entry.petId, entryId: entry.id);
  }

  Future<void> _done(HealthEntry entry) {
    final schedule = entry.schedule;
    if (schedule == null) return Future.value();
    return ref
        .read(careCompletionFlowProvider)
        .done(
          context,
          schedule: schedule,
          onChanged: _refreshAfterCareCommand,
          source: widget.source,
        );
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(_readAt);
    final partition = partitionCareList(
      widget.entries,
      (e) => e.schedule,
      elapsed: elapsed,
    );
    if (partition.isEmpty && widget.empty != null) return widget.empty!;

    final items = buildCareListInsetItems(
      context: context,
      partition: partition,
      upcomingExpanded: _upcomingExpanded,
      onToggleUpcoming: () =>
          setState(() => _upcomingExpanded = !_upcomingExpanded),
      petNames: widget.petNames,
      onOpenPet: widget.petNames != null
          ? (petId) => goToPetDetail(context, petId)
          : null,
      elapsed: elapsed,
      cardBuilder: (entry, {required bool todaySection}) {
        final schedule = entry.schedule!;
        if (todaySection) {
          final content = buildCareListTodayContent(schedule, elapsed: elapsed);
          return CareListTodayCard(
            key: Key('care_list_today_card_${entry.id}'),
            entry: entry,
            content: content,
            petName: widget.petNames?[entry.petId],
            onOpen: () => _open(entry),
            onDone: content.showMarkDone ? () => _done(entry) : null,
          );
        }
        final row = careListUpcomingRow(entry, schedule, elapsed: elapsed);
        if (row == null) return const SizedBox.shrink();
        return CareListUpcomingCard(
          key: Key('care_list_upcoming_card_${entry.id}'),
          row: row,
          petName: widget.petNames?[entry.petId],
          onOpen: () => _open(row.item),
          onDone: () => _done(row.item),
        );
      },
    );

    return Column(
      key: const Key('care_list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CareCollectionInsetList(children: items),
      ],
    );
  }
}
