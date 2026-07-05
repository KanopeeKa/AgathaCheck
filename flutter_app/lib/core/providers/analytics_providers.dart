import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../services/analytics_service.dart';
import '../services/consent_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.create();
});

/// Keeps PostHog in sync with consent and auth state.
final analyticsCoordinatorProvider = Provider<void>((ref) {
  final service = ref.watch(analyticsServiceProvider);

  ref.listen<ConsentState>(consentServiceProvider, (prev, next) async {
    await service.applyConsent(
      hasResponded: next.hasResponded,
      analyticsConsent: next.analyticsConsent,
    );
    if (next.hasResponded && next.analyticsConsent) {
      final auth = ref.read(authProvider);
      if (auth.isLoggedIn && auth.user != null) {
        await service.onLogin(auth.user!);
      }
    }
  }, fireImmediately: true);

  ref.listen<AuthState>(authProvider, (prev, next) async {
    final wasLoggedIn = prev?.isLoggedIn ?? false;
    final isLoggedIn = next.isLoggedIn;
    if (!wasLoggedIn && isLoggedIn && next.user != null) {
      await service.onLogin(next.user!);
    } else if (wasLoggedIn && !isLoggedIn) {
      await service.onLogout();
    }
  });
});

class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._onScreen);

  final void Function(String? screenName) _onScreen;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _track(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _track(previousRoute);
    super.didPop(route, previousRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name;
    _onScreen(name);
  }
}

final analyticsRouteObserverProvider = Provider<AnalyticsRouteObserver>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  return AnalyticsRouteObserver((screenName) {
    service.trackScreen(screenName);
  });
});
