import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/foster_self_prefs.dart';
import 'org_provider_people.dart';

class FosterSelfPrefsNotifier extends StateNotifier<FosterSelfPrefs> {
  FosterSelfPrefsNotifier(this._orgId, this._ref)
    : super(const FosterSelfPrefs());

  final String _orgId;
  final Ref _ref;

  void loadFromParent(FosterSelfPrefs prefs) {
    state = prefs;
  }

  Future<void> persist() async {
    await _ref
        .read(orgFosterParentsProvider(_orgId).notifier)
        .updateSelfVisibility(state);
  }

  void updateVisibleTo(FosterVisibleTo value) {
    state = state.copyWith(visibleTo: value);
  }

  void updateAddressVisibility(FosterAddressVisibility value) {
    state = state.copyWith(addressVisibility: value);
  }

  void updateContactVisibility(FosterContactVisibility value) {
    state = state.copyWith(contactVisibility: value);
  }

  void updateMessageChannel(FosterMessageNotificationChannel value) {
    state = state.copyWith(messageChannel: value);
  }

  Future<void> withdrawAgreement(String confirmation) async {
    await _ref
        .read(orgFosterParentsProvider(_orgId).notifier)
        .withdrawAgreement(confirmation);
    state = state.copyWith(clearRulesAgreement: true);
  }
}

final fosterSelfPrefsProvider =
    StateNotifierProvider.family<
      FosterSelfPrefsNotifier,
      FosterSelfPrefs,
      String
    >((ref, orgId) => FosterSelfPrefsNotifier(orgId, ref));
