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
///
/// Empty [types], [statuses], and [recurring] sets mean "all" for that row.
class ManageEventsFilters {
  const ManageEventsFilters({
    this.types = const {},
    this.recurring = const {},
    this.statuses = const {},
    this.showSkipped = true,
  });

  final Set<ManageEventsTypeFilter> types;
  final Set<ManageEventsRecurringFilter> recurring;
  final Set<ManageEventsStatusFilter> statuses;
  final bool showSkipped;

  ManageEventsFilters copyWith({
    Set<ManageEventsTypeFilter>? types,
    Set<ManageEventsRecurringFilter>? recurring,
    Set<ManageEventsStatusFilter>? statuses,
    bool? showSkipped,
  }) {
    return ManageEventsFilters(
      types: types ?? this.types,
      recurring: recurring ?? this.recurring,
      statuses: statuses ?? this.statuses,
      showSkipped: showSkipped ?? this.showSkipped,
    );
  }

  ManageEventsFilters toggleType(ManageEventsTypeFilter value) {
    if (value == ManageEventsTypeFilter.all) {
      return copyWith(types: {});
    }
    final next = Set<ManageEventsTypeFilter>.from(types);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return copyWith(types: next);
  }

  ManageEventsFilters toggleStatus(ManageEventsStatusFilter value) {
    if (value == ManageEventsStatusFilter.all) {
      return copyWith(statuses: {});
    }
    final next = Set<ManageEventsStatusFilter>.from(statuses);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return copyWith(statuses: next);
  }

  ManageEventsFilters toggleRecurring(ManageEventsRecurringFilter value) {
    if (value == ManageEventsRecurringFilter.all) {
      return copyWith(recurring: {});
    }
    final next = Set<ManageEventsRecurringFilter>.from(recurring);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return copyWith(recurring: next);
  }

  bool isTypeSelected(ManageEventsTypeFilter value) =>
      value == ManageEventsTypeFilter.all
      ? types.isEmpty
      : types.contains(value);

  bool isStatusSelected(ManageEventsStatusFilter value) =>
      value == ManageEventsStatusFilter.all
      ? statuses.isEmpty
      : statuses.contains(value);

  bool isRecurringSelected(ManageEventsRecurringFilter value) =>
      value == ManageEventsRecurringFilter.all
      ? recurring.isEmpty
      : recurring.contains(value);
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

ManageEventsTypeFilter? _typeFilterForEntry(HealthEntry entry) {
  return switch (entry.type) {
    HealthEntryType.medication => ManageEventsTypeFilter.medication,
    HealthEntryType.preventive => ManageEventsTypeFilter.preventive,
    HealthEntryType.vetVisit => ManageEventsTypeFilter.vetVisit,
    HealthEntryType.other => ManageEventsTypeFilter.other,
  };
}

bool _matchesTypeFilters(HealthEntry entry, Set<ManageEventsTypeFilter> types) {
  if (types.isEmpty) return true;
  final filter = _typeFilterForEntry(entry);
  return filter != null && types.contains(filter);
}

bool _matchesRecurringFilters(
  HealthEntry entry,
  Set<ManageEventsRecurringFilter> recurring,
) {
  if (recurring.isEmpty) return true;
  final isOneTime = entry.frequency == HealthFrequency.once;
  if (recurring.contains(ManageEventsRecurringFilter.recurring) && !isOneTime) {
    return true;
  }
  if (recurring.contains(ManageEventsRecurringFilter.oneTime) && isOneTime) {
    return true;
  }
  return false;
}

bool _matchesStatusFilters(
  HealthEntry entry,
  Set<ManageEventsStatusFilter> statuses,
) {
  if (statuses.isEmpty) return true;

  final closed = isHealthEntrySeriesClosed(entry);
  final dueOrOverdue =
      !closed &&
      !entry.isCompleted &&
      (entry.isOverdue || entry.isDueToday || isEntryDueOrOverdue(entry));

  if (statuses.contains(ManageEventsStatusFilter.open) && !closed) {
    return true;
  }
  if (statuses.contains(ManageEventsStatusFilter.closed) && closed) {
    return true;
  }
  if (statuses.contains(ManageEventsStatusFilter.dueOverdue) && dueOrOverdue) {
    return true;
  }
  return false;
}

bool matchesManageEventsFilters(
  HealthEntry entry,
  ManageEventsFilters filters,
  List<HealthHistoryEntry> history,
) {
  if (!filters.showSkipped && isCurrentOccurrenceSkipped(entry, history)) {
    return false;
  }

  if (!_matchesTypeFilters(entry, filters.types)) return false;
  if (!_matchesRecurringFilters(entry, filters.recurring)) return false;
  if (!_matchesStatusFilters(entry, filters.statuses)) return false;

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
