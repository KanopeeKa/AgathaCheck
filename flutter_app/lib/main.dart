import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/analytics_providers.dart';
import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/consent_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'core/widgets/consent_banner.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/pet_profile/presentation/providers/pet_providers.dart';
import 'features/subscription/data/services/revenuecat_service.dart';

/// Global messenger so session-expiry notices can be shown from anywhere,
/// independent of the currently routed screen.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  await RevenueCatService().initialize();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PetProfileApp(),
    ),
  );
}

class PetProfileApp extends ConsumerWidget {
  const PetProfileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(analyticsCoordinatorProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    ref.listen<AuthState>(authProvider, (AuthState? prev, AuthState? next) {
      if ((next?.sessionExpired ?? false) && !(prev?.sessionExpired ?? false)) {
        final messengerContext = rootScaffoldMessengerKey.currentContext;
        final message = messengerContext != null
            ? AppLocalizations.of(messengerContext)!.sessionExpired
            : 'Session expired. Please log in again.';
        rootScaffoldMessengerKey.currentState
          ?..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));
        ref.read(authProvider.notifier).clearSessionExpired();
      }
    });

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: AppConstants.appTitle,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return _ConsentOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _ConsentOverlay extends ConsumerWidget {
  const _ConsentOverlay({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(consentServiceProvider);

    return Stack(
      children: [
        child,
        if (!consent.hasResponded)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const ConsentBanner(),
          ),
      ],
    );
  }
}
