/// Route extra for bulk share: pet IDs or [SharePetRouteArgs].
class SharePetRouteArgs {
  const SharePetRouteArgs({
    required this.petIds,
    this.initialPetId,
    this.prefillEmail,
    this.contactId,
  });

  final List<String> petIds;
  final String? initialPetId;
  final String? prefillEmail;
  final String? contactId;
}
