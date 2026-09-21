/// Prioritisation weight for planned care (not notification urgency).
enum CareImportance {
  essential,
  recommended,
  optional,
}

extension CareImportanceWire on CareImportance {
  String get wireValue {
    switch (this) {
      case CareImportance.essential:
        return 'essential';
      case CareImportance.recommended:
        return 'recommended';
      case CareImportance.optional:
        return 'optional';
    }
  }

  static CareImportance? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'essential' => CareImportance.essential,
      'recommended' => CareImportance.recommended,
      'optional' => CareImportance.optional,
      _ => null,
    };
  }
}
