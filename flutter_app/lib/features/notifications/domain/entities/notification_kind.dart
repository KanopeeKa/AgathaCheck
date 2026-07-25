enum NotificationKind {
  care,
  administrative;

  String get wireValue {
    switch (this) {
      case NotificationKind.care:
        return 'care';
      case NotificationKind.administrative:
        return 'administrative';
    }
  }

  static NotificationKind fromWire(String? value) {
    switch (value?.toLowerCase()) {
      case 'administrative':
        return NotificationKind.administrative;
      case 'care':
      default:
        return NotificationKind.care;
    }
  }
}

enum NotificationPriority {
  normal,
  urgent;

  String get wireValue {
    switch (this) {
      case NotificationPriority.normal:
        return 'normal';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }

  static NotificationPriority fromWire(String? value) {
    switch (value?.toLowerCase()) {
      case 'urgent':
        return NotificationPriority.urgent;
      case 'normal':
      default:
        return NotificationPriority.normal;
    }
  }
}
