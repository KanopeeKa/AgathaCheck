import '../../../core/utils/calendar_date.dart';
import '../domain/entities/weight_fulfilment_candidates.dart';
import '../domain/entities/weight_overview.dart';
import '../domain/entities/weight_write_outcomes.dart';
import 'models/weight_entry_model.dart';

WeightFulfilmentCandidates parseFulfilmentCandidates(
  Map<String, dynamic> json,
) {
  final date = parseCalendarDate(json['date'] as String?) ?? DateTime.now();
  final raw = json['candidates'];
  final candidates = <WeightFulfilmentCandidate>[];
  if (raw is List) {
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final scheduled = parseCalendarDate(item['scheduled_date'] as String?);
      candidates.add(
        WeightFulfilmentCandidate(
          entryId: item['entry_id']?.toString() ?? '',
          entryName: item['entry_name']?.toString() ?? '',
          occurrenceId: item['occurrence_id']?.toString() ?? '',
          scheduledDate: calendarDateOnly(scheduled ?? date),
          status: item['status']?.toString() ?? '',
        ),
      );
    }
  }
  return WeightFulfilmentCandidates(
    date: calendarDateOnly(date),
    candidates: candidates,
    defaultOccurrenceId: json['default_occurrence_id']?.toString(),
  );
}

WeightOverview parseWeightOverview(Map<String, dynamic> json) {
  WeightReference? reference;
  final refJson = json['reference'];
  if (refJson is Map<String, dynamic> && refJson['value'] != null) {
    reference = WeightReference(
      valueKg: (refJson['value'] as num).toDouble(),
      authority: refJson['authority']?.toString() ?? '',
      managementContext: refJson['management_context']?.toString() ?? 'none',
    );
  }
  final routines = <WeightRoutine>[];
  final raw = json['routines'];
  if (raw is List) {
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      WeightRoutineNext? next;
      final nextJson = item['next'];
      if (nextJson is Map<String, dynamic>) {
        final scheduled = parseCalendarDate(
          nextJson['scheduled_date'] as String?,
        );
        next = WeightRoutineNext(
          occurrenceId: nextJson['occurrence_id']?.toString() ?? '',
          scheduledDate: calendarDateOnly(scheduled ?? DateTime.now()),
          status: nextJson['status']?.toString() ?? '',
        );
      }
      routines.add(
        WeightRoutine(
          entryId: item['entry_id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          status: item['status']?.toString() ?? 'active',
          next: next,
        ),
      );
    }
  }
  return WeightOverview(
    petId: json['pet_id']?.toString() ?? '',
    routines: routines,
    reference: reference,
  );
}

WeightSaveOutcome parseWeightSaveResponse(Map<String, dynamic> json) {
  final entry = WeightEntryModel.fromJson(json);
  WeightFulfilmentOutcome? fulfilment;
  final f = json['fulfilment'];
  if (f is Map<String, dynamic>) {
    fulfilment = WeightFulfilmentOutcome(
      careEntryId: f['entry_id']?.toString() ?? '',
      undoToken: f['undo_token']?.toString() ?? '',
      routineName: entry.fulfils?.entryName,
    );
  }
  return WeightSaveOutcome(entry: entry, fulfilment: fulfilment);
}

WeightDeleteOutcome parseWeightDeleteResponse(Map<String, dynamic> json) {
  final reopened = json['reopened_occurrence'];
  if (reopened is! Map<String, dynamic>) {
    return const WeightDeleteOutcome();
  }
  return WeightDeleteOutcome(
    reopened: WeightReopenedOccurrence(
      careEntryId: reopened['entry_id']?.toString() ?? '',
      occurrenceId: reopened['occurrence_id']?.toString() ?? '',
    ),
  );
}
