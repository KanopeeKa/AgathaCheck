class OrgPrimaryContact {
  const OrgPrimaryContact({
    required this.id,
    required this.recordId,
    this.userId,
    required this.displayName,
    this.email,
    this.phone = '',
    this.photoUrl,
    this.role = '',
  });

  final String id;
  final String recordId;
  final String? userId;
  final String displayName;
  final String? email;
  final String phone;
  final String? photoUrl;
  final String role;

  factory OrgPrimaryContact.fromJson(Map<String, dynamic> json) {
    return OrgPrimaryContact(
      id: json['id']?.toString() ?? '',
      recordId: json['record_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      role: json['role']?.toString() ?? '',
    );
  }
}
