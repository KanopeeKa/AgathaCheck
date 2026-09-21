/// Where / who delivers care.
enum CareSetting {
  home,
  vet,
  other,
}

extension CareSettingWire on CareSetting {
  String get wireValue {
    switch (this) {
      case CareSetting.home:
        return 'home';
      case CareSetting.vet:
        return 'vet';
      case CareSetting.other:
        return 'other';
    }
  }

  static CareSetting? fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'home' => CareSetting.home,
      'vet' => CareSetting.vet,
      'other' => CareSetting.other,
      _ => null,
    };
  }
}
