import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import '../care_list/care_list_card.dart';
import '../care_surface/care_collection_inset_list.dart';
import '../care_surface/care_surface_tokens.dart';
import 'care_coordination_banner.dart';

/// Surface layouts for multi-line care cards outside global All care.
enum CareListSurfaceLayout {
  /// Guardian dashboard: Today cards only (no Upcoming block).
  dashboardTodayOnly,

  /// Pet profile: Today plus Upcoming capped at [petProfileUpcomingCap].
  petProfileCappedUpcoming,
}

/// Max Upcoming cards on the pet profile before expand (CARE-ITEM-R-024 phase 5).
const int kPetProfileUpcomingCap = 5;

/// Dashboard and pet-profile care cards (phase 5); global list uses [CareListCollection].
class CareListSurfaceCollection extends ConsumerStatefulWidget {
  const CareListSurfaceCollection({
    super.key,
    required this.entries,
    required this.source,
    required this.layout,
    this.petNames,
    this.empty,
  });

  final List<HealthEntry> entries;
  final CareCommandSource source;
  final CareListSurfaceLayout layout;
  final Map<String, String>? petNames;
  final Widget? empty;

  @override
  ConsumerState<CareListSurfaceCollection> createState() =>
      _CareListSurfaceCollectionState();
}

class _CareListSurfaceCollectionState
    extends ConsumerState<CareListSurfaceCollection> {
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
  void didUpdateWidget(CareListSurfaceCollection oldWidget) {
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

    final items = _buildInsetItems(context, partition, elapsed);

    return Column(
      key: const Key('care_list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [CareCollectionInsetList(children: items)],
    );
  }

  List<CareCollectionInsetItem> _buildInsetItems(
    BuildContext context,
    CareListPartition<HealthEntry> partition,
    Duration elapsed,
  ) {
    final l = AppLocalizations.of(context)!;
    final items = <CareCollectionInsetItem>[];
    final showUpcoming =
        widget.layout == CareListSurfaceLayout.petProfileCappedUpcoming;

    void header(String key, String text, {String? semanticsIdentifier}) {
      items.add(
        CareCollectionInsetItem(
          showDividerBefore: items.isNotEmpty,
          child: _SurfaceHeader(
            key: Key(key),
            text: text,
            semanticsIdentifier: semanticsIdentifier ?? key,
          ),
        ),
      );
    }

    Widget todayCard(HealthEntry entry) {
      final schedule = entry.schedule!;
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

    Widget upcomingCard(HealthEntry entry) {
      final schedule = entry.schedule!;
      final row = careListUpcomingRow(entry, schedule, elapsed: elapsed);
      if (row == null) return const SizedBox.shrink();
      return CareListUpcomingCard(
        key: Key('care_list_upcoming_card_${entry.id}'),
        row: row,
        petName: widget.petNames?[entry.petId],
        onOpen: () => _open(row.item),
        onDone: () => _done(row.item),
      );
    }

    void card(HealthEntry entry, {required bool todaySection}) {
      items.add(
        CareCollectionInsetItem(
          showDividerBefore: true,
          child: todaySection ? todayCard(entry) : upcomingCard(entry),
        ),
      );
    }

    header('care_list_today', l.careAgendaToday);
    if (partition.today.isEmpty) {
      items.add(
        CareCollectionInsetItem(
          showDividerBefore: true,
          child: _SurfaceLine(
            key: const Key('care_list_nothing_today'),
            text: l.careAgendaNothingDueToday,
          ),
        ),
      );
    } else {
      for (final entry in partition.today) {
        card(entry, todaySection: true);
      }
    }

    if (!showUpcoming || partition.upcoming.isEmpty) return items;

    final cap = kPetProfileUpcomingCap;
    final hasOverflow = partition.upcoming.length > cap;
    final visible = hasOverflow && !_upcomingExpanded
        ? partition.upcoming.take(cap).toList(growable: false)
        : partition.upcoming;

    if (hasOverflow) {
      items.add(
        CareCollectionInsetItem(
          showDividerBefore: true,
          child: _UpcomingCapToggle(
            total: partition.upcoming.length,
            expanded: _upcomingExpanded,
            onToggle: () =>
                setState(() => _upcomingExpanded = !_upcomingExpanded),
          ),
        ),
      );
    } else {
      items.add(
        CareCollectionInsetItem(
          showDividerBefore: true,
          child: _SurfaceHeader(
            key: const Key('care_list_upcoming'),
            text: l.careAgendaUpcoming(partition.upcoming.length),
            semanticsIdentifier: 'care_list_upcoming',
          ),
        ),
      );
    }

    _appendUpcomingWithDateHeaders(items, visible, card, header, elapsed);

    return items;
  }

  void _appendUpcomingWithDateHeaders(
    List<CareCollectionInsetItem> items,
    List<HealthEntry> entries,
  void Function(HealthEntry entry, {required bool todaySection}) card,
    void Function(String key, String text, {String? semanticsIdentifier})
        header,
    Duration elapsed,
  ) {
    final petNames = widget.petNames;
    final multiPet =
        petNames != null && petNames.length > 1;
    final rows = <CareAgendaRow<HealthEntry>>[];
    for (final entry in entries) {
      final row = careListUpcomingRow(entry, entry.schedule!, elapsed: elapsed);
      if (row != null) rows.add(row);
    }
    for (final group in groupAgendaRowsByDueDate(rows)) {
      if (showSameDayDateHeader(group)) {
        header(
          'care_list_date_${group.dateKey}',
          formatCalendarDateDisplay(group.date),
        );
      }
      if (multiPet && showCoordinationBanner(group, (entry) => entry.petId)) {
        final ids = coordinationPetIds(group, (entry) => entry.petId);
        final names = {
          for (final id in ids)
            if (petNames.containsKey(id)) id: petNames[id]!,
        };
        if (names.length >= 2) {
          items.add(
            CareCollectionInsetItem(
              showDividerBefore: true,
              child: CareCoordinationBanner(
                date: group.date,
                dateKey: group.dateKey,
                petNames: names,
                onOpenPet: (petId) => goToPetDetail(context, petId),
              ),
            ),
          );
        }
      }
      for (final row in group.rows) {
        card(row.item, todaySection: false);
      }
    }
  }
}

class _SurfaceHeader extends StatelessWidget {
  const _SurfaceHeader({
    super.key,
    required this.text,
    this.semanticsIdentifier,
  });

  final String text;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      identifier: semanticsIdentifier,
      child: Padding(
        padding: CareSurfaceTokens.collectionHeaderPadding,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SurfaceLine extends StatelessWidget {
  const _SurfaceLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: CareSurfaceTokens.collectionInsetRowPadding,
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _UpcomingCapToggle extends StatelessWidget {
  const _UpcomingCapToggle({
    required this.total,
    required this.expanded,
    required this.onToggle,
  });

  final int total;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      button: true,
      expanded: expanded,
      identifier: 'care_list_upcoming',
      hint: expanded ? l.careAgendaHideUpcoming : l.careAgendaShowUpcoming,
      child: InkWell(
        key: const Key('care_list_upcoming'),
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: CareSurfaceTokens.collectionHeaderPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.careAgendaUpcoming(total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Open Today slots on partitioned care items (Care tab badge, phase 5).
int countCareListAttentionToday<T>(
  Iterable<T> items,
  CareItemSchedule? Function(T item) scheduleOf, {
  Duration elapsed = Duration.zero,
}) {
  final partition = partitionCareList(items, scheduleOf, elapsed: elapsed);
  var count = 0;
  for (final item in partition.today) {
    final schedule = scheduleOf(item);
    if (schedule == null) continue;
    final content = buildCareListTodayContent(schedule, elapsed: elapsed);
    if (content.isStack || content.openLines.isNotEmpty) count++;
  }
  return count;
}
