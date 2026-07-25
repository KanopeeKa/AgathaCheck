import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';

import '../../../helpers/fakes.dart';
import 'recording_organization_repository_base.dart';
import 'recording_organization_repository_connections_mixin.dart';
import 'recording_organization_repository_core_mixin.dart';
import 'recording_organization_repository_foster_mixin.dart';
import 'recording_organization_repository_placements_mixin.dart';

export 'recording_organization_repository_base.dart';
export 'recording_organization_repository_connections_mixin.dart';
export 'recording_organization_repository_core_mixin.dart';
export 'recording_organization_repository_foster_mixin.dart';
export 'recording_organization_repository_placements_mixin.dart';

/// Records calls so we can assert what the notifiers delegated to the repository.
class RecordingOrganizationRepository extends RecordingOrganizationRepositoryBase
    with
        RecordingOrganizationRepositoryCoreMixin,
        RecordingOrganizationRepositoryFosterMixin,
        RecordingOrganizationRepositoryPlacementsMixin,
        RecordingOrganizationRepositoryConnectionsMixin {}

/// Tracks foster/people provider delegation beyond the base recording repo.
class FosterTrackingOrganizationRepository
    extends RecordingOrganizationRepository {
  final List<Map<String, dynamic>> createExternalCalls = [];
  final List<String> deletedIds = [];
  final List<Map<String, dynamic>> updateContactCalls = [];
  int peopleFetchCount = 0;

  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async {
    peopleFetchCount += 1;
    return const [];
  }

  @override
  Future<FosterParent> createExternalFosterParent(
    String orgId, {
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
    required String token,
  }) async {
    createExternalCalls.add({
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'fosterAddress': fosterAddress,
      'notes': notes,
      'lawfulBasisConfirmed': lawfulBasisConfirmed,
    });
    return FosterParent(
      id: 'fp-new',
      kind: FosterParentKind.external,
      displayName: displayName,
      email: email,
    );
  }

  @override
  Future<void> deleteExternalFosterParent(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    deletedIds.add(fosterParentId);
  }

  @override
  Future<OrgPersonDetail> updatePersonContact(
    String orgId,
    OrgPersonKind kind,
    String recordId, {
    String? fosterPhone,
    String? fosterAddress,
    String? adminNotes,
    String? displayName,
    String? email,
    required String token,
  }) async {
    updateContactCalls.add({
      'displayName': displayName,
      'email': email,
      'fosterPhone': fosterPhone,
      'fosterAddress': fosterAddress,
      'adminNotes': adminNotes,
    });
    return OrgPersonDetail(
      id: '${kind.wire}:$recordId',
      kind: kind,
      recordId: recordId,
      displayName: displayName ?? 'Updated',
      email: email,
      fosterPhone: fosterPhone ?? '',
      fosterAddress: fosterAddress ?? '',
      adminNotes: adminNotes ?? '',
    );
  }
}

ProviderContainer makeOrgProviderTestContainer(
  RecordingOrganizationRepository repo,
) {
  return ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      organizationRepositoryProvider.overrideWithValue(repo),
    ],
  );
}
