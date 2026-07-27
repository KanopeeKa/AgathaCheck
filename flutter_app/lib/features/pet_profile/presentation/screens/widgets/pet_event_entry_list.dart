import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_status.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_type_labels.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/pet_event_lifecycle.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Type filter for the manage-events unified list.
enum ManageEventsTypeFilter { all, medication, preventive, vetVisit, other }

/// Recurring filter for the manage-events unified list.
enum ManageEventsRecurringFilter { all, recurring, oneTime }

/// Open/closed/due filter for the manage-events unified list.
enum ManageEventsStatusFilter { all, open, closed, dueOverdue }

/// Combined filter state for manage-events list screens.
class ManageEventsFilters {
  const ManageEventsFilters({
    this.type = ManageEventsTypeFilter.all,
    this.recurring = ManageEventsRecurringFilter.all,
    this.status = ManageEventsStatusFilter.all,
    this.showSkipped = true,
  });

  final ManageEventsTypeFilter type;
  final ManageEventsRecurringFilter recurring;
  final ManageEventsStatusFilter status;
  final bool showSkipped;

  ManageEventsFilters copyWith({
    ManageEventsTypeFilter? type,
    ManageEventsRecurringFilter? recurring,
    ManageEventsStatusFilter? status,
    bool? showSkipped,
  }) {
    return ManageEventsFilters(
      type: type ?? this.type,
      recurring: recurring ?? this.recurring,
      status: status ?? this.status,
      showSkipped: showSkipped ?? this.showSkipped,
    );
  }
}

/// Histories keyed by entry id for manage-events sorting and skipped display.
final petManageEventHistoriesProvider =
    FutureProvider.family<Map<String, List<HealthHistoryEntry>>, String>((
      ref,
      petId,
    ) async {
      final entries =
          ref.watch(petHealthEntriesByIdProvider(petId)).valueOrNull ?? [];
      final histories = <String, List<HealthHistoryEntry>>{};
      await Future.wait(
        entries.map((entry) async {
          histories[entry.id] = await ref.read(
            entryHistoryProvider(entry.id).future,
          );
        }),
      );
      return histories;
    });

bool isCurrentOccurrenceSkipped(
  HealthEntry entry,
  List<HealthHistoryEntry> history,
) {
  if (entry.nextDueDate == null) return false;
  final nextDay = calendarDateOnly(entry.nextDueDate!);
  return history.any(
    (row) =>
        row.isSkipped &&
        row.dueDate != null &&
        calendarDateOnly(row.dueDate!).isAtSameMomentAs(nextDay),
  );
}

String formatManageEventStatusLine(
  HealthEntry entry,
  AppLocalizations l,
  List<HealthHistoryEntry> history,
) {
  if (isCurrentOccurrenceSkipped(entry, history)) {
    return l.occurrenceSkipped;
  }
  if (isHealthEntrySeriesClosed(entry)) {
    final last = sortedHistoryDesc(history).firstOrNull;
    if (last?.isSkipped == true) {
      return l.occurrenceSkipped;
    }
    if (last?.completedOn != null) {
      return l.doneOn(formatHealthEntryStatusDate(last!.completedOn!));
    }
    if (last?.dueDate != null) {
      return formatHealthEntryStatusDate(last!.dueDate!);
    }
  }
  return formatHealthEntryStatusLine(entry, l);
}

DateTime manageEventSortKey(
  HealthEntry entry,
  List<HealthHistoryEntry> history,
) {
  if (!isHealthEntrySeriesClosed(entry)) {
    return entry.nextDueDate ?? DateTime(2100);
  }
  final last = lastCompletedHistory(history);
  if (last?.completedOn != null) return last!.completedOn!;
  if (last?.dueDate != null) return last!.dueDate!;
  if (entry.completedOn != null) return entry.completedOn!;
  return entry.nextDueDate ?? entry.startDate;
}

bool matchesManageEventsFilters(
  HealthEntry entry,
  ManageEventsFilters filters,
  List<HealthHistoryEntry> history,
) {
  if (!filters.showSkipped && isCurrentOccurrenceSkipped(entry, history)) {
    return false;
  }

  switch (filters.type) {
    case ManageEventsTypeFilter.all:
      break;
    case ManageEventsTypeFilter.medication:
      if (entry.type != HealthEntryType.medication) return false;
    case ManageEventsTypeFilter.preventive:
      if (entry.type != HealthEntryType.preventive) return false;
    case ManageEventsTypeFilter.vetVisit:
      if (entry.type != HealthEntryType.vetVisit) return false;
    case ManageEventsTypeFilter.other:
      if (entry.type != HealthEntryType.other) return false;
  }

  switch (filters.recurring) {
    case ManageEventsRecurringFilter.all:
      break;
    case ManageEventsRecurringFilter.recurring:
      if (entry.frequency == HealthFrequency.once) return false;
    case ManageEventsRecurringFilter.oneTime:
      if (entry.frequency != HealthFrequency.once) return false;
  }

  final closed = isHealthEntrySeriesClosed(entry);
  switch (filters.status) {
    case ManageEventsStatusFilter.all:
      break;
    case ManageEventsStatusFilter.open:
      if (closed) return false;
    case ManageEventsStatusFilter.closed:
      if (!closed) return false;
    case ManageEventsStatusFilter.dueOverdue:
      if (closed || entry.isCompleted) return false;
      if (!entry.isOverdue && !entry.isDueToday && !isEntryDueOrOverdue(entry)) {
        return false;
      }
  }

  return true;
}

List<HealthEntry> filterAndSortManageEvents(
  List<HealthEntry> entries,
  ManageEventsFilters filters,
  Map<String, List<HealthHistoryEntry>> histories,
) {
  final filtered = entries
      .where(
        (entry) => matchesManageEventsFilters(
          entry,
          filters,
          histories[entry.id] ?? const [],
        ),
      )
      .toList();

  filtered.sort((a, b) {
    final aClosed = isHealthEntrySeriesClosed(a);
    final bClosed = isHealthEntrySeriesClosed(b);
    if (aClosed != bClosed) {
      return aClosed ? 1 : -1;
    }
    final aKey = manageEventSortKey(a, histories[a.id] ?? const []);
    final bKey = manageEventSortKey(b, histories[b.id] ?? const []);
    return aKey.compareTo(bKey);
  });

  return filtered;
}

/// Filter chips for the manage-events unified list.
class ManageEventsFilterBar extends StatelessWidget {
  const ManageEventsFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final ManageEventsFilters filters;
  final ValueChanged<ManageEventsFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterChipRow(
            children: [
              _typeChip(ManageEventsTypeFilter.all, l.all),
              _typeChip(ManageEventsTypeFilter.medication, l.medication),
              _typeChip(ManageEventsTypeFilter.preventive, l.preventive),
              _typeChip(ManageEventsTypeFilter.vetVisit, l.vetVisit),
              _typeChip(ManageEventsTypeFilter.other, l.other),
            ],
          ),
          const SizedBox(height: 8),
          _FilterChipRow(
            children: [
              _statusChip(ManageEventsStatusFilter.all, l.all),
              _statusChip(ManageEventsStatusFilter.open, l.open),
              _statusChip(ManageEventsStatusFilter.closed, l.eventFilterClosed),
              _statusChip(
                ManageEventsStatusFilter.dueOverdue,
                l.dueAndOverdue,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FilterChipRow(
            children: [
              _recurringChip(ManageEventsRecurringFilter.all, l.all),
              _recurringChip(
                ManageEventsRecurringFilter.recurring,
                l.eventFilterRecurring,
              ),
              _recurringChip(
                ManageEventsRecurringFilter.oneTime,
                l.eventFilterOneTime,
              ),
              FilterChip(
                key: const Key('manage_events_show_skipped_chip'),
                label: Text(l.eventFilterShowSkipped),
                selected: filters.showSkipped,
                onSelected: (selected) =>
                    onChanged(filters.copyWith(showSkipped: selected)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip(ManageEventsTypeFilter value, String label) {
    return FilterChip(
      key: Key('manage_events_type_${value.name}'),
      label: Text(label),
      selected: filters.type == value,
      onSelected: (_) => onChanged(filters.copyWith(type: value)),
    );
  }

  Widget _statusChip(ManageEventsStatusFilter value, String label) {
    return FilterChip(
      key: Key('manage_events_status_${value.name}'),
      label: Text(label),
      selected: filters.status == value,
      onSelected: (_) => onChanged(filters.copyWith(status: value)),
    );
  }

  Widget _recurringChip(ManageEventsRecurringFilter value, String label) {
    return FilterChip(
      key: Key('manage_events_recurring_${value.name}'),
      label: Text(label),
      selected: filters.recurring == value,
      onSelected: (_) => onChanged(filters.copyWith(recurring: value)),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Compact two-line event row with date on the right and chevron.
class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.entry,
    required this.history,
    required this.petId,
  });

  final HealthEntry entry;
  final List<HealthHistoryEntry> history;
  final String petId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final detail = entry.dosage.trim().isEmpty
        ? healthEntryTypeLabel(l, entry.type)
        : '${healthEntryTypeLabel(l, entry.type)} · ${entry.dosage}';
    final statusLine = formatManageEventStatusLine(entry, l, history);
    final statusColor = isCurrentOccurrenceSkipped(entry, history)
        ? colorScheme.onSurfaceVariant
        : healthEntryStatusColor(entry, colorScheme);

    return Semantics(
      button: true,
      label: '${entry.name}, $detail, $statusLine',
      child: InkWell(
        key: Key('event_list_card_${entry.id}'),
        onTap: () => context.go('/pet/$petId/events/${entry.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legacy list tile layout used by pet profile health/other sections.
class PetEventEntryList extends StatelessWidget {
  const PetEventEntryList({
    super.key,
    required this.entries,
    required this.petId,
    required this.onEntryTap,
  });

  final List<HealthEntry> entries;
  final String petId;
  final void Function(HealthEntry entry) onEntryTap;

  static IconData iconForType(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return Icons.medication_outlined;
      case HealthEntryType.preventive:
        return Icons.shield_outlined;
      case HealthEntryType.vetVisit:
        return Icons.local_hospital_outlined;
      case HealthEntryType.other:
        return Icons.more_horiz_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l.noEntriesYet,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final detail = entry.dosage.trim().isEmpty
            ? healthEntryTypeLabel(l, entry.type)
            : '${healthEntryTypeLabel(l, entry.type)} · ${entry.dosage}';
        final statusColor = healthEntryStatusColor(entry, colorScheme);
        final statusLine = formatHealthEntryStatusLine(entry, l);

        return ListTile(
          leading: Icon(iconForType(entry.type), color: statusColor),
          title: Text(entry.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail),
              Text(
                statusLine,
                style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onEntryTap(entry),
        );
      },
    );
  }
}
