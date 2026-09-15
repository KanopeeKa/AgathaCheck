import '../domain/entities/planned_absence.dart';
import 'planned_absence_date_rules.dart';

class PlannedAbsenceHubPartition {
  const PlannedAbsenceHubPartition._();
  static const cancelledStatus = 'cancelled';
  static ({List<PlannedAbsence> upcoming, List<PlannedAbsence> past}) partition(
    List<PlannedAbsence> absences, {
    DateTime? today,
  }) {
    final todayIso = PlannedAbsenceDateRules.startsOnWire(
      today ?? PlannedAbsenceDateRules.todayCalendar(),
    );
    if (todayIso == null) return (upcoming: const [], past: const []);
    final upcoming = <PlannedAbsence>[];
    final past = <PlannedAbsence>[];
    for (final absence in absences) {
      if (absence.status == cancelledStatus) continue;
      if (absence.endsOn.compareTo(todayIso) >= 0)
        upcoming.add(absence);
      else
        past.add(absence);
    }
    upcoming.sort((a, b) => a.startsOn.compareTo(b.startsOn));
    past.sort((a, b) => b.startsOn.compareTo(a.startsOn));
    return (upcoming: upcoming, past: past);
  }
}
