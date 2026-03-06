import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/shared_preferences_provider.dart';

class ConsentState {
  final bool hasResponded;
  final bool essentialConsent;
  final bool analyticsConsent;
  final bool marketingConsent;
  final String? consentTimestamp;

  const ConsentState({
    this.hasResponded = false,
    this.essentialConsent = true,
    this.analyticsConsent = false,
    this.marketingConsent = false,
    this.consentTimestamp,
  });

  ConsentState copyWith({
    bool? hasResponded,
    bool? essentialConsent,
    bool? analyticsConsent,
    bool? marketingConsent,
    String? consentTimestamp,
  }) {
    return ConsentState(
      hasResponded: hasResponded ?? this.hasResponded,
      essentialConsent: essentialConsent ?? this.essentialConsent,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
    );
  }
}

class ConsentService extends StateNotifier<ConsentState> {
  final SharedPreferences _prefs;

  static const _keyHasResponded = 'consent_has_responded';
  static const _keyEssential = 'consent_essential';
  static const _keyAnalytics = 'consent_analytics';
  static const _keyMarketing = 'consent_marketing';
  static const _keyTimestamp = 'consent_timestamp';

  ConsentService(this._prefs) : super(const ConsentState()) {
    _load();
  }

  void _load() {
    state = ConsentState(
      hasResponded: _prefs.getBool(_keyHasResponded) ?? false,
      essentialConsent: _prefs.getBool(_keyEssential) ?? true,
      analyticsConsent: _prefs.getBool(_keyAnalytics) ?? false,
      marketingConsent: _prefs.getBool(_keyMarketing) ?? false,
      consentTimestamp: _prefs.getString(_keyTimestamp),
    );
  }

  Future<void> acceptAll() async {
    final timestamp = DateTime.now().toIso8601String();
    await _prefs.setBool(_keyHasResponded, true);
    await _prefs.setBool(_keyEssential, true);
    await _prefs.setBool(_keyAnalytics, true);
    await _prefs.setBool(_keyMarketing, true);
    await _prefs.setString(_keyTimestamp, timestamp);
    state = ConsentState(
      hasResponded: true,
      essentialConsent: true,
      analyticsConsent: true,
      marketingConsent: true,
      consentTimestamp: timestamp,
    );
  }

  Future<void> savePreferences({
    required bool analyticsConsent,
    required bool marketingConsent,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    await _prefs.setBool(_keyHasResponded, true);
    await _prefs.setBool(_keyEssential, true);
    await _prefs.setBool(_keyAnalytics, analyticsConsent);
    await _prefs.setBool(_keyMarketing, marketingConsent);
    await _prefs.setString(_keyTimestamp, timestamp);
    state = ConsentState(
      hasResponded: true,
      essentialConsent: true,
      analyticsConsent: analyticsConsent,
      marketingConsent: marketingConsent,
      consentTimestamp: timestamp,
    );
  }

  Future<void> withdrawAll() async {
    final timestamp = DateTime.now().toIso8601String();
    await _prefs.setBool(_keyHasResponded, true);
    await _prefs.setBool(_keyEssential, true);
    await _prefs.setBool(_keyAnalytics, false);
    await _prefs.setBool(_keyMarketing, false);
    await _prefs.setString(_keyTimestamp, timestamp);
    state = ConsentState(
      hasResponded: true,
      essentialConsent: true,
      analyticsConsent: false,
      marketingConsent: false,
      consentTimestamp: timestamp,
    );
  }
}

final consentServiceProvider =
    StateNotifierProvider<ConsentService, ConsentState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ConsentService(prefs);
});
