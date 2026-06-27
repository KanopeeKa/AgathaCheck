import '../entities/pet_access.dart';

/// Data seam for the pet-sharing feature. The presentation layer depends on this
/// abstraction rather than the remote datasource directly (clean architecture).
abstract class SharingRepository {
  Future<String> createShare(
      String petId, Map<String, dynamic> petJson, String token);
  Future<String> acceptShare(String code, String token);

  Future<List<PetAccess>> getAccess(String petId, String token);
  Future<void> updateRole(String petId, String userId, String role, String token);
  Future<void> removeAccess(String petId, String userId, String token);

  Future<List<Map<String, dynamic>>> getPendingShares(String token);
  Future<void> acceptPendingShare(String petId, String token,
      {String? organizationId});
  Future<void> declinePendingShare(String petId, String token);

  Future<void> hideSharedPet(String petId, String token, {required bool hidden});
  Future<List<Map<String, dynamic>>> getHiddenSharedPets(String token);
}
