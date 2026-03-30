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
  });

  final String id;
  final String petId;
  final String organizationId;
  final String? assignedToUserId;
  final String assignedName;
  final String assignedEmail;
  final DateTime fromDate;
  final DateTime? toDate;
  final String notes;
  final String? createdBy;
  final DateTime? createdAt;

  factory FamilyEvent.fromJson(Map<String, dynamic> json) {
    return FamilyEvent(
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      assignedToUserId: json['assigned_to_user_id']?.toString(),
      assignedName: (json['assigned_name'] ?? '').toString(),
      assignedEmail: (json['assigned_email'] ?? '').toString(),
      fromDate: DateTime.parse(json['from_date'].toString()),
      toDate: json['to_date'] != null ? DateTime.tryParse(json['to_date'].toString()) : null,
      notes: (json['notes'] ?? '').toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  String get assignedDisplay {
    if (assignedName.isNotEmpty) return assignedName;
    if (assignedEmail.isNotEmpty) return assignedEmail;
    return '';
  }
}
