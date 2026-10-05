class WeightReference {
  const WeightReference({
    required this.valueKg,
    required this.authority,
    this.managementContext = 'none',
  });

  final double valueKg;
  final String authority;
  final String managementContext;
}

class WeightRoutineNext {
  const WeightRoutineNext({
    required this.occurrenceId,
    required this.scheduledDate,
    required this.status,
  });

  final String occurrenceId;
  final DateTime scheduledDate;
  final String status;
}

class WeightRoutine {
  const WeightRoutine({
    required this.entryId,
    required this.name,
    required this.status,
    this.next,
  });

  final String entryId;
  final String name;

  /// `active`, `paused`, etc.
  final String status;
  final WeightRoutineNext? next;
}

class WeightOverview {
  const WeightOverview({
    required this.petId,
    required this.routines,
    this.reference,
  });

  final String petId;
  final List<WeightRoutine> routines;
  final WeightReference? reference;
}
