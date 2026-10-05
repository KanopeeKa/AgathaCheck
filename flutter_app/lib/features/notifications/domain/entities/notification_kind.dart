enum NotificationKind {
  care,
  administrative,
  relationship,
  suggestion,
  account;

  String get wireValue {
    switch (this) {
      case NotificationKind.care:
        return 'care';
      case NotificationKind.administrative:
        return 'administrative';
      case NotificationKind.relationship:
        return 'relationship';
      case NotificationKind.suggestion:
        return 'suggestion';
      case NotificationKind.account:
        return 'account';
    }
  }

  static NotificationKind fromWire(String? value) {
    switch (value?.toLowerCase()) {
      case 'administrative':
        return NotificationKind.administrative;
      case 'relationship':
        return NotificationKind.relationship;
      case 'suggestion':
        return NotificationKind.suggestion;
      case 'account':
        return NotificationKind.account;
      case 'care':
        return NotificationKind.care;
      default:
        return NotificationKind.administrative;
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
