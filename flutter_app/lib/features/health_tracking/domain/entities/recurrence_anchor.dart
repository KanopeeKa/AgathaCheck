/// How the next occurrence is scheduled after completion.
enum RecurrenceAnchor {
  /// Next due = completed on + interval (default for new entries).
  fromCompletion,

  /// Next due = original due date + interval.
  fromDueDate,
}

extension RecurrenceAnchorApi on RecurrenceAnchor {
  String get apiValue {
    switch (this) {
      case RecurrenceAnchor.fromCompletion:
        return 'from_completion';
      case RecurrenceAnchor.fromDueDate:
        return 'from_due_date';
    }
  }

  static RecurrenceAnchor fromApi(String? value) {
    switch (value) {
      case 'from_due_date':
        return RecurrenceAnchor.fromDueDate;
      case 'from_completion':
      default:
        return RecurrenceAnchor.fromCompletion;
    }
  }
}
