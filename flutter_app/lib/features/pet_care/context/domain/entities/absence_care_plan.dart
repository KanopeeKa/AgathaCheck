class AbsenceCarePlan {
  const AbsenceCarePlan({
    required this.absenceId,
    required this.today,
    required this.startsOn,
    required this.endsOn,
    required this.pets,
  });

  final String absenceId;
  final String today;
  final String startsOn;
  final String endsOn;
  final List<AbsenceCarePlanPet> pets;
}

class AbsenceCarePlanPet {
  const AbsenceCarePlanPet({
    required this.petId,
    required this.suggestions,
    required this.carerTasks,
  });

  final String petId;
  final List<CarePlannerSuggestion> suggestions;
  final CarePlannerCarerTasks carerTasks;
}

class CarePlannerSuggestion {
  const CarePlannerSuggestion({
    required this.healthEntryId,
    required this.occurrenceId,
    required this.fromDate,
    required this.toDate,
    required this.direction,
    required this.inWindowBefore,
    required this.inWindowAfter,
    required this.flexibility,
    required this.rationaleCode,
  });

  final String healthEntryId;
  final String occurrenceId;
  final String fromDate;
  final String toDate;
  final String direction;
  final int inWindowBefore;
  final int inWindowAfter;
  final String flexibility;
  final String rationaleCode;
}

class CarePlannerCarerTasks {
  const CarePlannerCarerTasks({required this.count, required this.byEntry});

  final int count;
  final List<CarePlannerCarerTaskEntry> byEntry;
}

class CarePlannerCarerTaskEntry {
  const CarePlannerCarerTaskEntry({
    required this.healthEntryId,
    required this.count,
    required this.reason,
  });

  final String healthEntryId;
  final int count;
  final String reason;
}
