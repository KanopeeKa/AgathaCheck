import '../entities/invite_preview.dart';
import '../entities/pet_access.dart';
import '../entities/pet_share_access.dart';
import '../entities/share_link.dart';
import '../entities/share_preview.dart';

/// Data seam for the pet-sharing feature. The presentation layer depends on this
/// abstraction rather than the remote datasource directly (clean architecture).
abstract class SharingRepository {
  Future<String> createShare(String petId, String token, {String accessRole});
  Future<String> acceptShare(String code, String token);
  Future<SharePreview> getSharePreview(String code);

  Future<List<PetAccess>> getAccess(String petId, String token);
  Future<void> updateRole(
    String petId,
    String userId,
    String role,
    String token,
  );
  Future<void> removeAccess(String petId, String userId, String token);

  Future<List<ShareLink>> getShareLinks(String petId, String token);
  Future<void> deleteShareLink(String linkId, String token);
  Future<void> stopFollowing(String petId, String token);

  Future<void> hideSharedPet(
    String petId,
    String token, {
    required bool hidden,
  });
  Future<void> transferOwnership(
    String petId, {
    required String recipientEmail,
    required String confirmationName,
    required String token,
  });
  Future<List<Map<String, dynamic>>> getHiddenSharedPets(String token);

  Future<CreateShareInviteResult> createInvite({
    required String inviteeEmail,
    required List<String> petIds,
    required String role,
    required String token,
    String? locale,
  });

  Future<List<PetShareAccess>> listAccessForPets(
    List<String> petIds,
    String token,
  );

  Future<InvitePreview> getInvitePreview(String code);

  Future<AcceptShareInviteResult> acceptInviteByCode(String code, String token);

  Future<void> declineInvite(String inviteId, String token);

  Future<void> cancelInvite(String inviteId, String token);
}
