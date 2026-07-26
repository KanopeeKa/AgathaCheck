class OrgLegalDocument {
  const OrgLegalDocument({
    required this.id,
    required this.templateKey,
    required this.templateType,
    required this.label,
    this.description = '',
    this.sortOrder = 0,
  });

  final String id;
  final String templateKey;
  final String templateType;
  final String label;
  final String description;
  final int sortOrder;

  factory OrgLegalDocument.fromJson(Map<String, dynamic> json) {
    return OrgLegalDocument(
      id: json['id']?.toString() ?? '',
      templateKey: json['template_key']?.toString() ?? '',
      templateType: json['template_type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    );
  }
}

Map<String, List<OrgLegalDocument>> parseGroupedLegalDocuments(
  Map<String, dynamic> json,
) {
  final grouped = <String, List<OrgLegalDocument>>{};
  for (final entry in json.entries) {
    final items = entry.value;
    if (items is! List) continue;
    grouped[entry.key] = items
        .whereType<Map>()
        .map(
          (item) => OrgLegalDocument.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
  return grouped;
}
