import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_viewer_role.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/invite_preview.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/pet_access.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/pet_share_access.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/share_link.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/share_preview.dart';
import 'package:pet_profile_app/features/sharing/domain/repositories/sharing_repository.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/share_pet_providers.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/sharing_providers.dart';

import '../../../../helpers/fakes.dart';

class _FakeSharingRepository implements SharingRepository {
  final List<String> cancelledInvites = [];
  CreateShareInviteResult? lastCreateResult;

  @override
  Future<List<PetShareAccess>> listAccessForPets(
    List<String> petIds,
    String token,
  ) async {
    return [
      PetShareAccess(
        petId: petIds.first,
        access: const [],
        pendingInvites: const [],
      ),
    ];
  }

  @override
  Future<CreateShareInviteResult> createInvite({
    required String inviteeEmail,
    required List<String> petIds,
    required String role,
    required String token,
    String? locale,
  }) async {
    lastCreateResult = CreateShareInviteResult(
      inviteId: 'inv-1',
      code: 'abc123',
      includedPetIds: petIds,
    );
    return lastCreateResult!;
  }

  @override
  Future<void> cancelInvite(String inviteId, String token) async {
    cancelledInvites.add(inviteId);
  }

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
    return const SharePreview(pet: {'name': 'Buddy'});
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
  Future<void> removeAccess(String petId, String userId, String token) async {}

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
  }) async {}

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

  @override
  Future<InvitePreview> getInvitePreview(String code) async {
    return InvitePreview(
      inviteId: 'inv-1',
      code: code,
      role: PetAccessRole.carer,
      status: 'pending',
    );
  }

  @override
  Future<AcceptShareInviteResult> acceptInviteByCode(
    String code,
    String token,
  ) async {
    return const AcceptShareInviteResult(inviteId: 'inv-1', status: 'accepted');
  }

  @override
  Future<void> declineInvite(String inviteId, String token) async {}
}

void main() {
  ProviderContainer makeContainer(_FakeSharingRepository repo) {
    return ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        sharingRepositoryProvider.overrideWithValue(repo),
        allPetsIncludingOrgProvider.overrideWith(
          (ref) async => const [
            Pet(id: 'pet-1', name: 'Buddy', species: 'dog'),
          ],
        ),
      ],
    );
  }

  test('sharePetNotifier sendInvite delegates to repository', () async {
    final repo = _FakeSharingRepository();
    final container = makeContainer(repo);
    final sub = container.listen(
      sharePetNotifierProvider(['pet-1']),
      (_, __) {},
    );
    addTearDown(() {
      sub.close();
      container.dispose();
    });

    await Future<void>.delayed(Duration.zero);
    await container
        .read(sharePetNotifierProvider(['pet-1']).notifier)
        .sendInvite(
          inviteeEmail: 'carer@example.com',
          role: PetAccessRole.carer,
        );

    expect(repo.lastCreateResult?.includedPetIds, ['pet-1']);
  });

  test('sharePetViewerRole resolves guardian and carer roles', () {
    const owner = Pet(id: 'p1', name: 'A', species: 'dog');
    const carer = Pet(id: 'p2', name: 'B', species: 'cat', isShared: true);
    const foster = Pet(id: 'p3', name: 'C', species: 'dog', isFoster: true);

    expect(sharePetViewerRole(owner), PetViewerRole.guardian);
    expect(sharePetViewerRole(carer), PetViewerRole.sharedCarer);
    expect(sharePetViewerRole(foster), PetViewerRole.fosterCarer);
  });
}
