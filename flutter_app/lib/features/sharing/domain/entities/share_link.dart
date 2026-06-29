class ShareLink {
  const ShareLink({
    required this.id,
    required this.code,
    required this.status,
    this.createdAt,
    this.claimedAt,
    this.claimedBy,
    this.claimedByName,
  });

  final String id;
  final String code;
  final String status;
  final DateTime? createdAt;
  final DateTime? claimedAt;
  final String? claimedBy;
  final String? claimedByName;

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';

  factory ShareLink.fromJson(Map<String, dynamic> json) {
    return ShareLink(
      id: json['id']?.toString() ?? '',
      code: (json['code'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      claimedAt: DateTime.tryParse(json['claimed_at']?.toString() ?? ''),
      claimedBy: json['claimed_by']?.toString(),
      claimedByName: json['claimed_by_name']?.toString(),
    );
  }
}
