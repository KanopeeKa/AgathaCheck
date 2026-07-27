import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_status.dart';
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
      if (!entry.isOverdue &&
          !entry.isDueToday &&
          !isEntryDueOrOverdue(entry)) {
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
