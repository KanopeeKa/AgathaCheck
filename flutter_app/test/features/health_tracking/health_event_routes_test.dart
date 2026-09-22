import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/router/pet_care_route_redirects.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_planning_mode.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _TwoPetsNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => const [
    Pet(id: 'p1', name: 'Rex', species: 'Dog'),
  ];
}

class _EmptyHealthEntriesNotifier extends HealthEntriesNotifier {
  @override
  Future<List<HealthEntry>> build() async => [];
}

void main() {
  group('pet care add route planning query', () {
    testWidgets('?planning=unplanned opens record mode', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/pet/p1/care/add?planning=unplanned',
        routes: [
          GoRoute(
            path: '/pet/:petId/care/add',
            builder: (context, state) {
              final planningParam = state.uri.queryParameters['planning'];
              final initialPlanningMode = planningParam == 'unplanned'
                  ? CarePlanningMode.unplanned
                  : null;
              return HealthEntryFormScreen(
                petId: state.pathParameters['petId'],
                initialPlanningMode: initialPlanningMode,
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            petListProvider.overrideWith(_TwoPetsNotifier.new),
            healthEntriesNotifierProvider.overrideWith(
              _EmptyHealthEntriesNotifier.new,
            ),
            apiBaseUrlProvider.overrideWithValue('http://test.local'),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Record care'), findsOneWidget);
      expect(find.text('Does not repeat'), findsNothing);
      expect(
        find.byKey(const Key('care_planning_toggle')),
        findsOneWidget,
      );

      final params = HealthEntryFormParams(
        petId: 'p1',
        initialPlanningMode: CarePlanningMode.unplanned,
      );
      final element = tester.element(find.byType(HealthEntryFormScreen));
      final container = ProviderScope.containerOf(element);
      final state = container.read(healthEntryFormControllerProvider(params));
      expect(state.carePlanning, CarePlanningMode.unplanned);
      expect(state.completedOn, isNotNull);
      expect(state.remindDaysBefore, 0);
    });
  });

  group('legacyPetEventEditRedirectForPath', () {
    test('maps legacy health edit path', () {
      expect(
        legacyPetEventEditRedirectForPath('/pet/pet-1/health/edit/entry-9'),
        '/pet/pet-1/events/entry-9/edit',
      );
    });

    test('maps legacy other edit path', () {
      expect(
        legacyPetEventEditRedirectForPath('/pet/pet-2/other/edit/entry-3'),
        '/pet/pet-2/events/entry-3/edit',
      );
    });

    test('returns null for unrelated paths', () {
      expect(
        legacyPetEventEditRedirectForPath('/pet/pet-1/events/entry-9/edit'),
        isNull,
      );
      expect(
        legacyPetEventEditRedirectForPath('/pet/pet-1/care/add'),
        isNull,
      );
    });
  });

  group('legacyCareAddRedirectForPath', () {
    test('maps legacy pet health add path', () {
      expect(
        legacyCareAddRedirectForPath('/pet/pet-1/health/add'),
        '/pet/pet-1/care/add',
      );
    });

    test('maps legacy pet other add path', () {
      expect(
        legacyCareAddRedirectForPath('/pet/pet-2/other/add'),
        '/pet/pet-2/care/add',
      );
    });

    test('maps legacy global health add path', () {
      expect(legacyCareAddRedirectForPath('/health/add'), '/care/add');
    });

    test('returns null for canonical care add paths', () {
      expect(legacyCareAddRedirectForPath('/pet/pet-1/care/add'), isNull);
      expect(legacyCareAddRedirectForPath('/care/add'), isNull);
    });
  });
}
