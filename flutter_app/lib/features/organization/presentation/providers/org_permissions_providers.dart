import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/services/org_permissions.dart';
import 'org_provider_deps.dart';

typedef MemberPermissionsKey = ({String orgId, String userId});

class PermissionBundlesNotifier
    extends FamilyAsyncNotifier<Map<String, dynamic>, String> {
  @override
  Future<Map<String, dynamic>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return {'presets': []};
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getPermissionBundles(orgId, token);
  }
}

final permissionBundlesProvider =
    AsyncNotifierProvider.family<
      PermissionBundlesNotifier,
      Map<String, dynamic>,
      String
    >(PermissionBundlesNotifier.new);

class MemberPermissionsNotifier
    extends FamilyAsyncNotifier<Map<String, dynamic>, MemberPermissionsKey> {
  @override
  Future<Map<String, dynamic>> build(MemberPermissionsKey key) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return {};
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getMemberPermissions(key.orgId, key.userId, token);
  }

  Future<void> applyBundle(String preset) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.applyPermissionBundle(
      arg.orgId,
      arg.userId,
      preset,
      token,
    );
    state = AsyncData(result);
    ref.invalidate(orgAuditEventsProvider(arg.orgId));
    ref.invalidate(orgEffectivePermissionsProvider(arg.orgId));
  }

  Future<void> grantPermission(String permissionKey) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.grantMemberPermission(
      arg.orgId,
      arg.userId,
      permissionKey,
      token,
    );
    state = AsyncData(result);
    ref.invalidate(orgAuditEventsProvider(arg.orgId));
    ref.invalidate(orgEffectivePermissionsProvider(arg.orgId));
  }

  Future<void> revokePermission(String permissionKey) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.revokeMemberPermission(
      arg.orgId,
      arg.userId,
      permissionKey,
      token,
    );
    state = AsyncData(result);
    ref.invalidate(orgAuditEventsProvider(arg.orgId));
    ref.invalidate(orgEffectivePermissionsProvider(arg.orgId));
  }
}

final memberPermissionsProvider =
    AsyncNotifierProvider.family<
      MemberPermissionsNotifier,
      Map<String, dynamic>,
      MemberPermissionsKey
    >(MemberPermissionsNotifier.new);

class OrgAuditEventsNotifier
    extends FamilyAsyncNotifier<List<Map<String, dynamic>>, String> {
  @override
  Future<List<Map<String, dynamic>>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getOrgAuditEvents(orgId, token);
  }
}

final orgAuditEventsProvider =
    AsyncNotifierProvider.family<
      OrgAuditEventsNotifier,
      List<Map<String, dynamic>>,
      String
    >(OrgAuditEventsNotifier.new);

class DocumentTemplatesNotifier
    extends FamilyAsyncNotifier<Map<String, dynamic>, String> {
  @override
  Future<Map<String, dynamic>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return {};
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getDocumentTemplates(orgId, token);
  }
}

final documentTemplatesProvider =
    AsyncNotifierProvider.family<
      DocumentTemplatesNotifier,
      Map<String, dynamic>,
      String
    >(DocumentTemplatesNotifier.new);

void _syncOverrideCache(String orgId, Map<String, dynamic> data) {
  final overrides = (data['overrides'] as List? ?? [])
      .map((row) => (row as Map<String, dynamic>)['permission_key'] as String)
      .toSet();
  setViewerPermissionOverrides(orgId, overrides);
}

/// Effective permission keys for the signed-in viewer in [orgId] (server source of truth).
final orgEffectivePermissionsProvider =
    FutureProvider.family<Set<String>, String>((ref, orgId) async {
      final token = ref.watch(orgTokenProvider);
      if (token == null) {
        clearViewerPermissionOverrides(orgId);
        return {};
      }
      try {
        final repo = ref.read(organizationRepositoryProvider);
        final data = await repo.getMyPermissions(orgId, token);
        _syncOverrideCache(orgId, data);
        final keys = (data['effective_permissions'] as List? ?? [])
            .cast<String>();
        return keys.toSet();
      } catch (_) {
        clearViewerPermissionOverrides(orgId);
        return {};
      }
    });

/// Preloads viewer overrides via [orgEffectivePermissionsProvider] for legacy [hasPermission] calls.
final viewerPermissionOverridesProvider = FutureProvider.family<void, String>((
  ref,
  orgId,
) async {
  await ref.watch(orgEffectivePermissionsProvider(orgId).future);
});
