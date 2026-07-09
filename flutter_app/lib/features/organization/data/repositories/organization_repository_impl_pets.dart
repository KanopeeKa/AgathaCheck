import '../../domain/entities/archived_pet.dart';
import 'organization_repository_impl_base.dart';

mixin OrganizationRepositoryPetsMixin on OrganizationRepositoryImplBase {
  @override
  Future<List<Map<String, dynamic>>> getOrganizationPets(
    String orgId,
    String token,
  ) async {
    return await dataSource.getOrganizationPets(orgId, token);
  }

  @override
  Future<Map<String, dynamic>> createOrganizationPet(
    String orgId,
    Map<String, dynamic> petJson,
    String token,
  ) async {
    return await dataSource.createOrganizationPet(orgId, petJson, token);
  }

  @override
  Future<void> transferPetToUser(
    String orgId,
    String petId, {
    required String recipientEmail,
    String transferType = 'adoption',
    String notes = '',
    required String token,
  }) async {
    await dataSource.transferPetToUser(
      orgId,
      petId,
      recipientEmail: recipientEmail,
      transferType: transferType,
      notes: notes,
      token: token,
    );
  }

  @override
  Future<void> transferPetToOrg(
    String petId,
    String orgId, {
    String notes = '',
    required String token,
  }) async {
    await dataSource.transferPetToOrg(petId, orgId, notes: notes, token: token);
  }

  @override
  Future<List<ArchivedPet>> getOrganizationArchivedPets(
    String orgId,
    String token,
  ) async {
    return await dataSource.getOrganizationArchivedPets(orgId, token);
  }

  @override
  Future<List<ArchivedPet>> getUserArchivedPets(String token) async {
    return await dataSource.getUserArchivedPets(token);
  }

  @override
  Future<List<Map<String, dynamic>>> getFamilyEvents(
    String token,
    String petId,
  ) async {
    return await dataSource.getFamilyEvents(token, petId);
  }

  @override
  Future<Map<String, dynamic>> createFamilyEvent(
    String token,
    String petId,
    Map<String, dynamic> body,
  ) async {
    return await dataSource.createFamilyEvent(token, petId, body);
  }

  @override
  Future<void> updateFamilyEvent(
    String token,
    String petId,
    String eventId,
    Map<String, dynamic> body,
  ) async {
    await dataSource.updateFamilyEvent(token, petId, eventId, body);
  }

  @override
  Future<void> deleteFamilyEvent(
    String token,
    String petId,
    String eventId,
  ) async {
    await dataSource.deleteFamilyEvent(token, petId, eventId);
  }
}
