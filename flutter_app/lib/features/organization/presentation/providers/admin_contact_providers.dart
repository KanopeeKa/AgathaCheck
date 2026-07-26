import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_contact_self_prefs.dart';
import '../../domain/entities/organization_member.dart';
import 'org_provider_list.dart';

/// In-memory stub until org-scoped prefs persist on `notification_preferences`.
///
/// Debt: wire to backend extension per program-contract §11/D31.
class AdminContactSelfPrefsNotifier extends StateNotifier<AdminContactSelfPrefs> {
  AdminContactSelfPrefsNotifier() : super(const AdminContactSelfPrefs());

  void updatePhoneVisibility(AdminPhoneVisibility value) {
    state = state.copyWith(phoneVisibility: value);
  }

  void updateMessageChannel(AdminMessageNotificationChannel value) {
    state = state.copyWith(messageChannel: value);
  }
}

final adminContactSelfPrefsProvider = StateNotifierProvider.family<
    AdminContactSelfPrefsNotifier,
    AdminContactSelfPrefs,
    String>((ref, orgId) => AdminContactSelfPrefsNotifier());

/// Resolved viewer role for permission gates on org routes.
final orgViewerRoleProvider = Provider.family<OrgMemberRole?, String>((
  ref,
  orgId,
) {
  final orgsAsync = ref.watch(organizationListProvider);
  return orgsAsync.whenOrNull(
    data: (orgs) {
      final org = orgs.where((o) => o.id == orgId).firstOrNull;
      if (org == null) return null;
      return OrgMemberRole.fromWire(org.role);
    },
  );
});
