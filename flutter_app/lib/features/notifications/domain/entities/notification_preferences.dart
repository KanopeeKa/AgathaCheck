class NotificationPreferences {
  const NotificationPreferences({
    this.emailRemindersEnabled = false,
    this.reminderDaysBefore = 1,
    this.notifyOverdue = true,
    this.notifyDueSoon = true,
  });

  final bool emailRemindersEnabled;
  final int reminderDaysBefore;
  final bool notifyOverdue;
  final bool notifyDueSoon;

  NotificationPreferences copyWith({
    bool? emailRemindersEnabled,
    int? reminderDaysBefore,
    bool? notifyOverdue,
    bool? notifyDueSoon,
  }) {
    return NotificationPreferences(
      emailRemindersEnabled:
          emailRemindersEnabled ?? this.emailRemindersEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notifyOverdue: notifyOverdue ?? this.notifyOverdue,
      notifyDueSoon: notifyDueSoon ?? this.notifyDueSoon,
    );
  }
}
