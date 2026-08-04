import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/member_privacy_settings.dart';
import '../../domain/entities/organization_member.dart';
import 'org_provider_deps.dart';

class MemberPrivacyNotifier
    extends FamilyAsyncNotifier<MemberPrivacySettings, String> {
  @override
  Future<MemberPrivacySettings> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    return ref
        .read(organizationRepositoryProvider)
        .getMemberPrivacy(orgId, token);
  }

  Future<void> save(MemberPrivacySettings settings) async {
    final orgId = arg;
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref
          .read(organizationRepositoryProvider)
          .updateMemberPrivacy(orgId, settings, token);
    });
  }
}

final memberPrivacyProvider =
    AsyncNotifierProvider.family<
      MemberPrivacyNotifier,
      MemberPrivacySettings,
      String
    >(MemberPrivacyNotifier.new);

OrgMemberRole? orgRoleFromWire(String? role) {
  if (role == null || role.isEmpty) return null;
  return OrgMemberRole.fromWire(role);
}
