import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_pet_care_sync.dart';
import 'core/care/care_item_observation_section.dart';
import 'core/providers/analytics_providers.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/pet_care_sync.dart';
import 'core/router/app_router.dart';
import 'core/services/consent_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'core/weight/weight_unit_preference.dart';
import 'core/widgets/consent_banner.dart';
import 'package:pet_profile_app/features/auth/auth.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/features/subscription/subscription.dart';
import 'package:pet_profile_app/features/weight_tracking/weight_tracking.dart';

/// Global messenger so session-expiry notices can be shown from anywhere,
/// independent of the currently routed screen.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  await initializeSubscriptionSdk();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        careItemHttpClientProvider.overrideWith(
          (ref) => ref.watch(authHttpClientProvider),
        ),
        careDataChangedProvider.overrideWith(
          (ref) => () async {
            await ref.read(healthEntriesNotifierProvider.notifier).refresh();
            ref.invalidate(weightEntriesNotifierProvider);
            ref.invalidate(weightOverviewProvider);
            ref.invalidate(weightFulfilmentCandidatesProvider);
          },
        ),
        weightUnitPreferenceProvider.overrideWith(
          (ref) => weightUnitFromWire(ref.watch(authProvider).user?.weightUnit),
        ),
        setWeightUnitPreferenceProvider.overrideWith(
          (ref) => (unit) async {
            await ref
                .read(authProvider.notifier)
                .updateProfile(weightUnit: weightUnitToWire(unit));
          },
        ),
        petCareSyncProvider.overrideWith((ref) => AppPetCareSync(ref)),
        careItemObservationSectionProvider.overrideWith(
          (ref) =>
              (
                context, {
                required petId,
                required entryId,
                required observationKind,
              }) {
                if (observationKind == 'numeric_weight') {
                  return WeightCareItemSection(petId: petId, entryId: entryId);
                }
                return null;
              },
        ),
      ],
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
      supportedLocales: const [
        ...AppLocalizations.supportedLocales,
        Locale('en', 'GB'),
        Locale('fr', 'FR'),
      ],
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
          Positioned.fill(
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: const ConsentBanner(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
