import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../domain/entities/health_entry.dart';
import '../health_dashboard_actions.dart' show GroupMode;

/// Builds the grouped entry buckets used by the Events PDF export.
///
/// Extracted from `health_dashboard_screen.dart`. Returns an ordered list of
/// `(sectionTitle, entries)` pairs matching the selected [mode].
List<MapEntry<String?, List<HealthEntry>>> buildEventsPdfGroups({
  required List<HealthEntry> entries,
  required Map<String, Pet> petMap,
  required GroupMode mode,
  required AppLocalizations l,
}) {
  switch (mode) {
    case GroupMode.dueDate:
      return _pdfGroupByDueDate(entries, l);
    case GroupMode.pet:
      return _pdfGroupByPet(entries, petMap);
    case GroupMode.petType:
      return _pdfGroupByPetType(entries, petMap);
  }
}

List<MapEntry<String?, List<HealthEntry>>> _pdfGroupByDueDate(
  List<HealthEntry> entries,
  AppLocalizations l,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final endOfWeek = today.add(const Duration(days: 7));

  final buckets = <String, List<HealthEntry>>{
    l.overdue: [],
    l.today: [],
    l.tomorrow: [],
    l.thisWeek: [],
    l.later: [],
    l.completed: [],
  };

  for (final e in entries) {
    if (e.isCompleted) {
      buckets[l.completed]!.add(e);
    } else if (e.nextDueDate != null) {
      final due = DateTime(
        e.nextDueDate!.year,
        e.nextDueDate!.month,
        e.nextDueDate!.day,
      );
      if (due.isBefore(today)) {
        buckets[l.overdue]!.add(e);
      } else if (due.isAtSameMomentAs(today)) {
        buckets[l.today]!.add(e);
      } else if (due.isAtSameMomentAs(tomorrow)) {
        buckets[l.tomorrow]!.add(e);
      } else if (due.isBefore(endOfWeek)) {
        buckets[l.thisWeek]!.add(e);
      } else {
        buckets[l.later]!.add(e);
      }
    }
  }

  final result = <MapEntry<String?, List<HealthEntry>>>[];
  for (final key in [
    l.overdue,
    l.today,
    l.tomorrow,
    l.thisWeek,
    l.later,
    l.completed,
  ]) {
    if (buckets[key]!.isNotEmpty) {
      result.add(MapEntry(key, buckets[key]!));
    }
  }
  return result;
}

List<MapEntry<String?, List<HealthEntry>>> _pdfGroupByPet(
  List<HealthEntry> entries,
  Map<String, Pet> petMap,
) {
  final grouped = <String, List<HealthEntry>>{};
  for (final e in entries) {
    final petName = petMap[e.petId]?.name ?? 'Unknown Pet';
    grouped.putIfAbsent(petName, () => []).add(e);
  }
  final sortedKeys = grouped.keys.toList()..sort();
  return sortedKeys.map((name) {
    final sorted = grouped[name]!
      ..sort((a, b) {
        final ad = a.nextDueDate ?? DateTime(2100);
        final bd = b.nextDueDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });
    return MapEntry<String?, List<HealthEntry>>(name, sorted);
  }).toList();
}

List<MapEntry<String?, List<HealthEntry>>> _pdfGroupByPetType(
  List<HealthEntry> entries,
  Map<String, Pet> petMap,
) {
  final grouped = <String, List<HealthEntry>>{};
  for (final e in entries) {
    final species = petMap[e.petId]?.species ?? 'Other';
    grouped.putIfAbsent(species, () => []).add(e);
  }
  final sortedKeys = grouped.keys.toList()..sort();
  return sortedKeys.map((species) {
    final label = species.endsWith('s') ? species : '${species}s';
    final sorted = grouped[species]!
      ..sort((a, b) {
        final ad = a.nextDueDate ?? DateTime(2100);
        final bd = b.nextDueDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });
    return MapEntry<String?, List<HealthEntry>>(label, sorted);
  }).toList();
}
