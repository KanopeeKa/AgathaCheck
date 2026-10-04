import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../care_item/care_item.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../care_surface/care_collection_inset_list.dart';
import 'care_agenda_inset_items.dart';
import 'care_agenda_row_tile.dart';

/// The agenda for [entries] (D-CIE-025) with server-confirmed Done
/// (§18.6.1). Advances timed Due → Overdue each minute and asks the server
/// again every 15 minutes while on screen (D-CIE-028).
class CareAgendaCollection extends ConsumerStatefulWidget {
  const CareAgendaCollection({
    super.key,
    required this.entries,
    required this.source,
    this.petNames,
    this.empty,
    this.header,
  });

  final List<HealthEntry> entries;
  final CareCommandSource source;

  /// Pet names by id: set on the dashboard (all pets) to label rows.
  final Map<String, String>? petNames;

  /// Shown when there is no planned care at all (UIR-5).
  final Widget? empty;

  /// Shown above the collection when it is not empty (e.g. orientation line).
  final Widget Function(CareAgenda<HealthEntry> agenda)? header;

  @override
  ConsumerState<CareAgendaCollection> createState() =>
      _CareAgendaCollectionState();
}

class _CareAgendaCollectionState extends ConsumerState<CareAgendaCollection> {
  bool _upcomingExpanded = false;
  DateTime _readAt = DateTime.now();
  Timer? _minute;

  @override
  void initState() {
    super.initState();
    _minute = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_readAt);
      if (elapsed >= const Duration(minutes: 15) || _crossedPetHomeMidnight(elapsed)) {
        _refresh();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(CareAgendaCollection oldWidget) {
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

  Future<void> _refresh() async {
    await ref.read(healthEntriesNotifierProvider.notifier).refresh();
    if (mounted) _readAt = DateTime.now();
  }

  /// Pet-home midnight crossed since [_readAt] (D-CIE-028 / review #1477).
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

  void _open(CareAgendaRow<HealthEntry> row) {
    final entry = row.item;
    final occurrence = row.occurrence;
    if (row.isStack || occurrence == null) {
      openPetEventView(context, petId: entry.petId, entryId: entry.id);
      return;
    }
    openOccurrenceScreen(
      context,
      petId: entry.petId,
      entryId: entry.id,
      occurrenceId: occurrence.id,
      source: widget.source.name,
    );
  }

  Future<void> _done(CareAgendaRow<HealthEntry> row) {
    return ref
        .read(careCompletionFlowProvider)
        .done(
          context,
          schedule: row.schedule,
          onChanged: _refresh,
          source: widget.source,
        );
  }

  @override
  Widget build(BuildContext context) {
    final agenda = buildCareAgenda<HealthEntry>(
      widget.entries,
      (e) => e.schedule,
      elapsed: DateTime.now().difference(_readAt),
    );
    if (agenda.isEmpty && widget.empty != null) return widget.empty!;
    final items = buildCareAgendaInsetItems(
      context: context,
      agenda: agenda,
      upcomingExpanded: _upcomingExpanded,
      onToggleUpcoming: () =>
          setState(() => _upcomingExpanded = !_upcomingExpanded),
      rowBuilder: (row) => CareAgendaRowTile(
        row: row,
        petName: widget.petNames?[row.item.petId],
        onOpen: () => _open(row),
        onDone: () => _done(row),
      ),
    );
    return Column(
      key: const Key('care_agenda'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?widget.header?.call(agenda),
        CareCollectionInsetList(children: items),
      ],
    );
  }
}
