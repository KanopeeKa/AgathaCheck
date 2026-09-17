class SharePreview {
  const SharePreview({
    required this.pet,
    this.owner,
    this.linkStatus,
    this.accessRole,
    this.expiresAt,
  });

  final Map<String, dynamic> pet;
  final Map<String, dynamic>? owner;
  final String? linkStatus;
  final String? accessRole;
  final String? expiresAt;

  factory SharePreview.fromJson(Map<String, dynamic> json) {
    return SharePreview(
      pet: (json['pet'] as Map<String, dynamic>?) ?? {},
      owner: json['owner'] as Map<String, dynamic>?,
      linkStatus: json['link_status']?.toString(),
      accessRole: json['access_role']?.toString(),
      expiresAt: json['expires_at']?.toString(),
    );
  }
}
