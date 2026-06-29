class FamilyEvent {
  const FamilyEvent({
    required this.id,
    required this.petId,
    required this.organizationId,
    this.assignedToUserId,
    this.assignedName = '',
    this.assignedEmail = '',
    required this.fromDate,
    this.toDate,
    this.notes = '',
    this.createdBy,
    this.createdAt,
    this.markedAt,
  });

  final String id;
  final String petId;
  final String organizationId;
  final String? assignedToUserId;
  final String assignedName;
  final String assignedEmail;

  /// Due / start date (a).
  final DateTime fromDate;

  /// Completed on date (b).
  final DateTime? toDate;
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;

  /// When completion was recorded (c).
  final DateTime? markedAt;

  bool get isCompleted => toDate != null;

  factory FamilyEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw.contains('T') ? raw : '${raw}T00:00:00');
    }

    return FamilyEvent(
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      assignedToUserId: json['assigned_to_user_id']?.toString(),
      assignedName: (json['assigned_name'] ?? '').toString(),
      assignedEmail: (json['assigned_email'] ?? '').toString(),
      fromDate: parseDate(json['from_date']?.toString()) ?? DateTime.now(),
      toDate: parseDate(json['to_date']?.toString()),
      notes: (json['notes'] ?? '').toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      markedAt: json['marked_at'] != null
          ? DateTime.tryParse(json['marked_at'].toString())
          : null,
    );
  }

  String get assignedDisplay {
    if (assignedName.isNotEmpty) return assignedName;
    if (assignedEmail.isNotEmpty) return assignedEmail;
    return '';
  }
}
