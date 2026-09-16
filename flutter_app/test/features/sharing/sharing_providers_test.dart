import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/pet_access.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/share_link.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/share_preview.dart';
import 'package:pet_profile_app/features/sharing/domain/repositories/sharing_repository.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';

import '../../helpers/fakes.dart';

class RecordingSharingRepository implements SharingRepository {
  final List<String> hiddenPets = [];
  final List<String> removedAccess = [];

  @override
  Future<String> createShare(
    String petId,
    String token, {
    String accessRole = 'carer',
  }) async => 'code';

  @override
  Future<String> acceptShare(String code, String token) async => 'pet-1';

  @override
  Future<SharePreview> getSharePreview(String code) async {
    return const SharePreview(
      pet: {'name': 'Buddy', 'species': 'Dog'},
      owner: {'first_name': 'Alice'},
    );
  }

  @override
  Future<List<PetAccess>> getAccess(String petId, String token) async => [];

  @override
  Future<void> updateRole(
    String petId,
    String userId,
    String role,
    String token,
  ) async {}

  @override
  Future<void> removeAccess(String petId, String userId, String token) async {
    removedAccess.add(userId);
  }

  @override
  Future<List<ShareLink>> getShareLinks(String petId, String token) async => [];

  @override
  Future<void> deleteShareLink(String linkId, String token) async {}

  @override
  Future<void> stopFollowing(String petId, String token) async {}

  @override
  Future<void> hideSharedPet(
    String petId,
    String token, {
    required bool hidden,
  }) async {
    if (hidden) hiddenPets.add(petId);
  }

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
  return ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      sharingRepositoryProvider.overrideWithValue(repo),
      allPetsIncludingOrgProvider.overrideWith((ref) async => <Pet>[]),
    ],
  );
}

void main() {
  test(
    'hiddenSharedPetsProvider hideSharedPet delegates to repository',
    () async {
      final repo = RecordingSharingRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(hiddenSharedPetsProvider.future);
      await container
          .read(hiddenSharedPetsProvider.notifier)
          .hideSharedPet('pet-1');

      expect(repo.hiddenPets, ['pet-1']);
    },
  );

  test('petAccessNotifier removeAccess delegates to repository', () async {
    final repo = RecordingSharingRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    container.read(petShareLinksNotifierProvider('pet-1').notifier);
    await container
        .read(petAccessNotifierProvider('pet-1').notifier)
        .removeAccess('user-2');
    await Future<void>.delayed(Duration.zero);

    expect(repo.removedAccess, ['user-2']);
  });

  test('PetAccessRole wire mapping', () {
    expect(PetAccessRoleWire.fromWire('carer'), PetAccessRole.carer);
    expect(PetAccessRoleWire.fromWire('co_parent'), PetAccessRole.coParent);
    expect(PetAccessRoleWire.fromWire('shared'), PetAccessRole.carer);
    expect(PetAccessRole.coParent.toWire(), 'co_parent');
  });
}
