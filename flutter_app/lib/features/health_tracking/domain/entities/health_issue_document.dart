class HealthIssueDocument {
  const HealthIssueDocument({
    required this.id,
    required this.healthIssueId,
    required this.url,
    this.createdAt,
  });

  final String id;
  final String healthIssueId;
  final String url;
  final DateTime? createdAt;

  factory HealthIssueDocument.fromJson(Map<String, dynamic> json) {
    return HealthIssueDocument(
      id: json['id'] as String? ?? '',
      healthIssueId: json['health_issue_id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
