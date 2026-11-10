import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/experience_home_screens.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fakes.dart';

var _homePetListAttempts = 0;

class _FlakyHomePetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async {
    _homePetListAttempts++;
    if (_homePetListAttempts < 2) {
      throw Exception('DioException connection failed');
    }
    return [const Pet(id: 'p1', name: 'Buddy', species: 'Dog')];
  }
}

void main() {
  setUp(() {
    _homePetListAttempts = 0;
    SharedPreferences.setMockInitialValues({
      'pet_care_onboarding_completed': true,
    });
  });

  testWidgets('Home pet-list error shows localized Retry then loads pets', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/pc/home',
      routes: [
        GoRoute(
          path: '/pc/home',
          builder: (context, state) => const PetCareHomeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          petListProvider.overrideWith(() => _FlakyHomePetListNotifier()),
          notificationsProvider.overrideWith(() => FakeNotificationsNotifier()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load your pets"), findsOneWidget);
    expect(find.textContaining('DioException'), findsNothing);

    await tester.tap(find.byKey(const Key('home_pet_list_retry')));
    await tester.pumpAndSettle();

    expect(find.text('Buddy'), findsWidgets);
    expect(find.textContaining('DioException'), findsNothing);
  });
}
