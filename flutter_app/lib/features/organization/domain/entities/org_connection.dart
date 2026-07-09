class OrgConnection {
  const OrgConnection({
    required this.id,
    required this.peerOrgId,
    required this.peerOrgName,
    this.peerOrgType,
    this.peerOrgEmail,
    this.connectedAt,
  });

  final String id;
  final String peerOrgId;
  final String peerOrgName;
  final String? peerOrgType;
  final String? peerOrgEmail;
  final DateTime? connectedAt;
}

class OrgConnectionRequest {
  const OrgConnectionRequest({
    required this.id,
    required this.requestingOrgId,
    required this.targetOrgId,
    required this.token,
    required this.status,
    required this.expiresAt,
    this.createdAt,
    this.revokedAt,
  });

  final String id;
  final String requestingOrgId;
  final String targetOrgId;
  final String token;
  final String status;
  final DateTime expiresAt;
  final DateTime? createdAt;
  final DateTime? revokedAt;

  bool get isPending => status == 'pending';
}
