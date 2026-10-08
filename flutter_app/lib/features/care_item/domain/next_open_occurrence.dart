import 'care_occurrence.dart';

/// Next open slot after [currentId] in schedule list order (D-OSM-006).
OpenOccurrence? nextOpenOccurrenceAfter({
  required List<OpenOccurrence> openOccurrences,
  required String currentId,
  required DateTime currentDate,
  String? currentTime,
}) {
  final open = openOccurrences;
  final index = open.indexWhere((o) => o.id == currentId);
  if (index >= 0) {
    if (index + 1 < open.length) return open[index + 1];
    return null;
  }

  final currentKey = OpenOccurrence(
    id: currentId,
    date: currentDate,
    time: currentTime,
    status: CareOccurrenceStatus.due,
    origin: CareOccurrenceOrigin.schedule,
  );

  for (final o in open) {
    final cmp = o.compareTo(currentKey);
    if (cmp > 0) return o;
    if (cmp == 0 && o.id != currentId) return o;
  }
  return null;
}
