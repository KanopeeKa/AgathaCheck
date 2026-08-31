class SessionChecklistItem {
  const SessionChecklistItem({
    required this.key,
    required this.label,
    this.completed = false,
    this.isRequired = false,
  });

  final String key;
  final String label;
  final bool completed;
  final bool isRequired;

  factory SessionChecklistItem.fromJson(Map<String, dynamic> json) {
    return SessionChecklistItem(
      key: json['key']?.toString() ?? json['template_key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      completed: json['completed'] == true,
      isRequired: json['is_required'] == true,
    );
  }
}

class SessionChecklist {
  const SessionChecklist({this.items = const []});

  final List<SessionChecklistItem> items;

  factory SessionChecklist.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SessionChecklist();
    final rawItems = json['items'];
    if (rawItems is! List) return const SessionChecklist();
    return SessionChecklist(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SessionChecklistItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toChecklistMap() => {
    'items': items
        .map(
          (item) => {
            'key': item.key,
            'label': item.label,
            'completed': item.completed,
            'is_required': item.isRequired,
          },
        )
        .toList(),
  };
}
