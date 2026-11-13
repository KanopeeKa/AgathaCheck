/// Support intake category codes accepted by the API.
enum SupportTicketCategory {
  bug('bug'),
  suggestion('suggestion'),
  account('account'),
  billing('billing');

  const SupportTicketCategory(this.apiValue);

  final String apiValue;

  static SupportTicketCategory? fromApiValue(String? value) {
    if (value == null) return null;
    for (final c in SupportTicketCategory.values) {
      if (c.apiValue == value) return c;
    }
    return null;
  }
}

/// Bug report frequency codes.
enum SupportBugFrequency {
  always('always'),
  sometimes('sometimes'),
  once('once');

  const SupportBugFrequency(this.apiValue);

  final String apiValue;
}
