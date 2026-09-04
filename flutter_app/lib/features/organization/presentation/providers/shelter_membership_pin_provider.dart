import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../experience/presentation/widgets/shelter_pinned_org_provider.dart';

/// Pin/unpin control for Shelter membership tiles (D-shelter-NAV-2).
final shelterMembershipPinControllerProvider = Provider<ShelterMembershipPinController>(
  (ref) => ShelterMembershipPinController(ref),
);

class ShelterMembershipPinController {
  ShelterMembershipPinController(this._ref);

  final Ref _ref;

  bool isPinned(String organizationId) {
    return _ref.read(shelterPinnedOrgIdProvider) == organizationId;
  }

  /// Replace-on-pin: pins [organizationId] or clears when already pinned.
  Future<void> toggle(String organizationId) async {
    final current = _ref.read(shelterPinnedOrgIdProvider);
    final next = current == organizationId ? null : organizationId;
    await _ref.read(authProvider.notifier).updatePinnedOrganization(next);
  }
}
