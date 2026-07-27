import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/custody_transfer.dart';
import '../../domain/entities/org_home_hidden_pet.dart';
import 'org_provider_deps.dart';
import 'org_provider_pets.dart';

class PendingCustodyTransfersNotifier
    extends AsyncNotifier<List<CustodyTransfer>> {
  @override
  Future<List<CustodyTransfer>> build() async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getPendingCustodyTransfers(token);
  }

  Future<void> accept(String transferId) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.acceptCustodyTransfer(transferId, token);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
    ref.invalidate(orgArchivedPetsProvider);
  }

  Future<void> cancel(String transferId, {String reason = ''}) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.cancelCustodyTransfer(transferId, token, reason: reason);
    ref.invalidateSelf();
  }
}

final pendingCustodyTransfersProvider =
    AsyncNotifierProvider<
      PendingCustodyTransfersNotifier,
      List<CustodyTransfer>
    >(PendingCustodyTransfersNotifier.new);

class OrgHomeHiddenPetsNotifier
    extends FamilyAsyncNotifier<List<OrgHomeHiddenPet>, String> {
  @override
  Future<List<OrgHomeHiddenPet>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getHomeHiddenPets(orgId, token);
  }

  Future<void> unhide(String petId) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.setPetHomeHidden(arg, petId, hidden: false, token: token);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
    ref.invalidate(petListProvider);
  }

  Future<void> hide(String petId) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.setPetHomeHidden(arg, petId, hidden: true, token: token);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
    ref.invalidate(petListProvider);
  }
}

final orgHomeHiddenPetsProvider =
    AsyncNotifierProvider.family<
      OrgHomeHiddenPetsNotifier,
      List<OrgHomeHiddenPet>,
      String
    >(OrgHomeHiddenPetsNotifier.new);

Future<void> requestCustodyTransferAction(
  WidgetRef ref, {
  required String orgId,
  required String petId,
  required String transferKind,
  String? toOrgId,
  String? toUserId,
  String notes = '',
}) async {
  final token = ref.read(orgTokenProvider);
  if (token == null) return;
  final repo = ref.read(organizationRepositoryProvider);
  await repo.requestCustodyTransfer(
    orgId,
    petId,
    transferKind: transferKind,
    toOrgId: toOrgId,
    toUserId: toUserId,
    notes: notes,
    token: token,
  );
  ref.invalidate(pendingCustodyTransfersProvider);
  ref.invalidate(orgPetsProvider(orgId));
}
