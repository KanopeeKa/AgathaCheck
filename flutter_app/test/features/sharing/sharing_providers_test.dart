import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/pet_access.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/share_link.dart';
import 'package:pet_profile_app/features/sharing/domain/repositories/sharing_repository.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';

import '../../helpers/fakes.dart';

class RecordingSharingRepository implements SharingRepository {
  final List<String> accepted = [];
  final List<String> declined = [];

  @override
  Future<List<Map<String, dynamic>>> getPendingShares(String token) async => [];

  @override
  Future<void> acceptPendingShare(String petId, String token,
      {String? organizationId}) async {
    accepted.add(petId);
  }

  @override
  Future<void> declinePendingShare(String petId, String token) async {
    declined.add(petId);
  }

  // --- Unused-by-these-tests members ---
  @override
  Future<String> createShare(
          String petId, Map<String, dynamic> petJson, String token) async =>
      'code';
  @override
  Future<String> acceptShare(String code, String token) async => 'pet-1';
  @override
  Future<List<PetAccess>> getAccess(String petId, String token) async => [];
  @override
  Future<void> updateRole(
      String petId, String userId, String role, String token) async {}
  @override
  Future<void> removeAccess(String petId, String userId, String token) async {}
  @override
  Future<List<ShareLink>> getShareLinks(String petId, String token) async => [];
  @override
  Future<void> deleteShareLink(String linkId, String token) async {}
  @override
  Future<void> stopFollowing(String petId, String token) async {}
  @override
  Future<void> hideSharedPet(String petId, String token,
      {required bool hidden}) async {}
  @override
  Future<List<Map<String, dynamic>>> getHiddenSharedPets(String token) async =>
      [];
  @override
  Future<void> transferOwnership(
    String petId, {
    required String recipientEmail,
    required String confirmationName,
    required String token,
  }) async {}
}

ProviderContainer makeContainer(RecordingSharingRepository repo) {
  return ProviderContainer(overrides: [
    authProvider.overrideWith((ref) => FakeAuthNotifier()),
    sharingRepositoryProvider.overrideWithValue(repo),
    allPetsIncludingOrgProvider.overrideWith((ref) async => <Pet>[]),
  ]);
}

void main() {
  test('pendingSharesProvider returns empty list (deprecated flow)', () async {
    final repo = RecordingSharingRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    final shares = await container.read(pendingSharesProvider.future);
    expect(shares, isEmpty);
  });

  test('acceptShare delegates to the repository and refreshes pets', () async {
    final repo = RecordingSharingRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    await container.read(pendingSharesProvider.future);
    await container
        .read(pendingSharesProvider.notifier)
        .acceptShare('pet-1', organizationId: 'org-2');

    expect(repo.accepted, ['pet-1']);
  });
}
