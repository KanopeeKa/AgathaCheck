import '../domain/support_ticket_category.dart';

class SupportTicketSubmitPayload {
  SupportTicketSubmitPayload({
    required this.category,
    required this.title,
    required this.description,
    required this.locale,
    required this.context,
    this.email,
    this.expected,
    this.actual,
    this.steps,
    this.frequency,
  });

  final SupportTicketCategory category;
  final String title;
  final String description;
  final String locale;
  final Map<String, String> context;
  final String? email;
  final String? expected;
  final String? actual;
  final String? steps;
  final SupportBugFrequency? frequency;

  Map<String, dynamic> toJson() {
    return {
      'category': category.apiValue,
      'title': title,
      'description': description,
      'locale': locale,
      'context': context,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (expected != null && expected!.isNotEmpty) 'expected': expected,
      if (actual != null && actual!.isNotEmpty) 'actual': actual,
      if (steps != null && steps!.isNotEmpty) 'steps': steps,
      if (frequency != null) 'frequency': frequency!.apiValue,
    };
  }
}
