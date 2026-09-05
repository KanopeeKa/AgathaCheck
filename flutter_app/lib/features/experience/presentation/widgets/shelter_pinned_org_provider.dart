import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../config/shelter_primary_destinations.dart';

/// `pinned_organization_id` from the authenticated user (`GET /auth/me`).
///
/// Returns null until [AuthUser] exposes this field from the phase-1 API payload.
String? shelterPinnedOrgIdFromAuthUser(AuthUser? user) {
  if (user == null) return null;
  return _readPinnedOrganizationId(user);
}

String? _readPinnedOrganizationId(AuthUser user) {
  final pinId = user.pinnedOrganizationId;
  if (pinId == null || pinId.isEmpty) return null;
  return pinId;
}

/// Pinned org id for Shelter primary nav (account preference).
final shelterPinnedOrgIdProvider = Provider<String?>((ref) {
  return shelterPinnedOrgIdFromAuthUser(ref.watch(authProvider).user);
});

/// Resolved pinned org metadata for Shelter nav widgets.
final shelterPinnedOrganizationProvider = Provider<ShelterPinnedOrganization?>((
  ref,
) {
  final pinId = ref.watch(shelterPinnedOrgIdProvider);
  if (pinId == null || pinId.isEmpty) return null;

  final orgs = ref.watch(organizationListProvider).valueOrNull;
  if (orgs == null) return null;

  Organization? org;
  for (final candidate in orgs) {
    if (candidate.id == pinId) {
      org = candidate;
      break;
    }
  }
  if (org == null) return null;

  return ShelterPinnedOrganization(
    id: org.id,
    name: org.name,
    logoUrl: org.logoUrl,
  );
});
