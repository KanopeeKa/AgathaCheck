/// Scheduling intent: plan ahead vs record after the fact.
enum CarePlanningMode {
  planned,
  unplanned,
}

extension CarePlanningModeWire on CarePlanningMode {
  String get wireValue {
    switch (this) {
      case CarePlanningMode.planned:
        return 'planned';
      case CarePlanningMode.unplanned:
        return 'unplanned';
    }
  }

  static CarePlanningMode? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'planned' => CarePlanningMode.planned,
      'unplanned' => CarePlanningMode.unplanned,
      _ => null,
    };
  }
}
