import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'org_provider_deps.dart';
import 'org_provider_list.dart';

class PendingOrgInvite {
  final String id;
  final String organizationId;
  final String organizationName;
  final String organizationType;
  final String desiredRole;
  final String inviterName;
  final String inviterEmail;
  final String createdAt;

  const PendingOrgInvite({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.organizationType,
    required this.desiredRole,
    required this.inviterName,
    required this.inviterEmail,
    required this.createdAt,
  });

  factory PendingOrgInvite.fromJson(Map<String, dynamic> json) {
    return PendingOrgInvite(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      organizationName: json['organization_name']?.toString() ?? '',
      organizationType: json['organization_type']?.toString() ?? '',
      desiredRole: json['desired_role']?.toString() ?? 'member',
      inviterName: json['inviter_name']?.toString() ?? '',
      inviterEmail: json['inviter_email']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class PendingOrgInvitesNotifier extends AsyncNotifier<List<PendingOrgInvite>> {
  @override
  Future<List<PendingOrgInvite>> build() async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    final raw = await repo.getPendingInvites(token);
    return raw.map((e) => PendingOrgInvite.fromJson(e)).toList();
  }

  Future<String> acceptInvite(String inviteId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.acceptInvite(inviteId, token);
    ref.invalidateSelf();
    ref.invalidate(organizationListProvider);
    return result['organization_id']?.toString() ?? '';
  }

  Future<void> declineInvite(String inviteId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.declineInvite(inviteId, token);
    ref.invalidateSelf();
  }
}

final pendingOrgInvitesProvider =
    AsyncNotifierProvider<PendingOrgInvitesNotifier, List<PendingOrgInvite>>(
      PendingOrgInvitesNotifier.new,
    );
