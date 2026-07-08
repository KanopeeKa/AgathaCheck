import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/organization_model.dart';
import '../../domain/entities/organization.dart';
import 'org_provider_deps.dart';
import 'org_provider_people.dart';

class OrganizationListNotifier extends AsyncNotifier<List<Organization>> {
  @override
  Future<List<Organization>> build() async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getOrganizations(token);
  }

  Future<Organization> createOrganization(Map<String, dynamic> data) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    // The form passes a raw map; convert to the domain entity for the repository.
    final org = await repo.createOrganization(
      OrganizationModel.fromJson(data),
      token,
    );
    ref.invalidateSelf();
    return org;
  }

  Future<void> updateOrganization(
    String orgId,
    Map<String, dynamic> data,
  ) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.updateOrganization(
      OrganizationModel.fromJson({...data, 'id': orgId}),
      token,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteOrganization(String orgId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.deleteOrganization(orgId, token);
    ref.invalidateSelf();
  }

  Future<Organization> uploadPhoto(
    String orgId,
    Uint8List bytes,
    String filename,
  ) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final org = await repo.uploadPhoto(orgId, bytes, filename, token);
    ref.invalidateSelf();
    return org;
  }

  Future<Organization> uploadLogo(
    String orgId,
    Uint8List bytes,
    String filename,
  ) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final org = await repo.uploadLogo(orgId, bytes, filename, token);
    ref.invalidateSelf();
    return org;
  }

  Future<Organization> setPrimaryContact(String orgId, String recordId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final org = await repo.setPrimaryContact(orgId, recordId, token);
    ref.invalidateSelf();
    ref.invalidate(orgPeopleProvider(orgId));
    return org;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final organizationListProvider =
    AsyncNotifierProvider<OrganizationListNotifier, List<Organization>>(
      OrganizationListNotifier.new,
    );
