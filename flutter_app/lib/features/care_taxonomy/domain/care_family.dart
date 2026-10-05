/// Semantic care domain for rhythms, icons, and intelligence rules.
enum CareFamily {
  medication,
  vaccination,
  parasitePrevention,
  wellnessReview,
  dental,
  weightMonitoring,
  grooming,
  nailCare,
  other,
}

extension CareFamilyWire on CareFamily {
  String get wireValue {
    switch (this) {
      case CareFamily.medication:
        return 'medication';
      case CareFamily.vaccination:
        return 'vaccination';
      case CareFamily.parasitePrevention:
        return 'parasite_prevention';
      case CareFamily.wellnessReview:
        return 'wellness_review';
      case CareFamily.dental:
        return 'dental';
      case CareFamily.weightMonitoring:
        return 'weight_monitoring';
      case CareFamily.grooming:
        return 'grooming';
      case CareFamily.nailCare:
        return 'nail_care';
      case CareFamily.other:
        return 'other';
    }
  }

  static CareFamily? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'medication' => CareFamily.medication,
      'vaccination' => CareFamily.vaccination,
      'parasite_prevention' => CareFamily.parasitePrevention,
      'wellness_review' => CareFamily.wellnessReview,
      'dental' => CareFamily.dental,
      'weight_monitoring' => CareFamily.weightMonitoring,
      'grooming' => CareFamily.grooming,
      'nail_care' => CareFamily.nailCare,
      'other' => CareFamily.other,
      _ => null,
    };
  }
}
