import '../../domain/entities/pet_access.dart';
import '../../domain/repositories/sharing_repository.dart';
import '../datasources/sharing_remote_datasource.dart';

/// [SharingRepository] backed by the remote datasource (passthrough; sharing has
/// no local cache).
class SharingRepositoryImpl implements SharingRepository {
  SharingRepositoryImpl(this._dataSource);

  final SharingRemoteDataSource _dataSource;

  @override
  Future<String> createShare(
      String petId, Map<String, dynamic> petJson, String token) {
    return _dataSource.createShare(petId, petJson, token);
  }

  @override
  Future<String> acceptShare(String code, String token) {
    return _dataSource.acceptShare(code, token);
  }

  @override
  Future<List<PetAccess>> getAccess(String petId, String token) {
    return _dataSource.getAccess(petId, token);
  }

  @override
  Future<void> updateRole(
      String petId, int userId, String role, String token) {
    return _dataSource.updateRole(petId, userId, role, token);
  }

  @override
  Future<void> removeAccess(String petId, int userId, String token) {
    return _dataSource.removeAccess(petId, userId, token);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingShares(String token) {
    return _dataSource.getPendingShares(token);
  }

  @override
  Future<void> acceptPendingShare(String petId, String token,
      {String? organizationId}) {
    return _dataSource.acceptPendingShare(petId, token,
        organizationId: organizationId);
  }

  @override
  Future<void> declinePendingShare(String petId, String token) {
    return _dataSource.declinePendingShare(petId, token);
  }

  @override
  Future<void> hideSharedPet(String petId, String token,
      {required bool hidden}) {
    return _dataSource.hideSharedPet(petId, token, hidden: hidden);
  }

  @override
  Future<List<Map<String, dynamic>>> getHiddenSharedPets(String token) {
    return _dataSource.getHiddenSharedPets(token);
  }
}
