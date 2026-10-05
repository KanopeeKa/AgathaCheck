class HouseholdInvitePreview {
  const HouseholdInvitePreview({
    required this.inviteId,
    required this.code,
    required this.householdId,
    required this.householdName,
    required this.inviterName,
    required this.accessTier,
    required this.isOrganiser,
    required this.inviteeEmail,
  });

  final String inviteId;
  final String code;
  final String householdId;
  final String householdName;
  final String inviterName;
  final String accessTier;
  final bool isOrganiser;
  final String inviteeEmail;

  @override
  bool operator ==(Object other) {
    return other is HouseholdInvitePreview &&
        other.inviteId == inviteId &&
        other.code == code &&
        other.householdId == householdId &&
        other.householdName == householdName &&
        other.inviterName == inviterName &&
        other.accessTier == accessTier &&
        other.isOrganiser == isOrganiser &&
        other.inviteeEmail == inviteeEmail;
  }

  @override
  int get hashCode => Object.hash(
    inviteId,
    code,
    householdId,
    householdName,
    inviterName,
    accessTier,
    isOrganiser,
    inviteeEmail,
  );
}
