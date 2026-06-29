import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/health_events_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _TwoPetsNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => const [
    Pet(id: 'p1', name: 'Rex', species: 'Dog'),
    Pet(id: 'p2', name: 'Milo', species: 'Cat'),
  ];
}

class _NoPetsNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => const [];
}

class _EmptyHealthEntriesNotifier extends HealthEntriesNotifier {
  @override
  Future<List<HealthEntry>> build() async => [];
}

Widget _wrap(PetListNotifier Function() notifier, {Locale? locale}) {
  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(notifier),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HealthEntryFormScreen(),
    ),
  );
}

Widget _wrapPetProfileHealthEventFlow() {
  final router = GoRouter(
    initialLocation: '/pet/p1',
    routes: [
      GoRoute(
        path: '/pet/:petId',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return Scaffold(
            appBar: AppBar(title: Text('Pet profile for $petId')),
            body: SingleChildScrollView(
              child: HealthEventsSection(petId: petId),
            ),
          );
        },
      ),
      GoRoute(
        path: '/pet/:petId/health/add',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return HealthEntryFormScreen(petId: petId);
        },
      ),
    ],
  );

  return ProviderScope(
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
  );
}

void main() {
  testWidgets('renders the add form with localized pet selector (EN)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_TwoPetsNotifier.new));
    // Resolve AppLocalizations + the petListProvider future.
    await tester.pump();
    await tester.pump();

    expect(find.byType(HealthEntryFormScreen), findsOneWidget);
    expect(find.text('Add a health event'), findsOneWidget);
    // Localized strings from the _PetSelector helper widget.
    expect(find.text('Select Pets'), findsOneWidget);
    expect(find.text('At least one pet must be selected'), findsOneWidget);
    expect(find.text('Select All'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    // The upload hint matches the accepted picker formats.
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('up to 4 documents (jpg, png, pdf), max 2 MB'),
        findsOneWidget);
    expect(healthDocumentAllowedExtensions, ['jpg', 'jpeg', 'png', 'pdf']);
    expect(healthDocumentMaxBytes, 2 * 1024 * 1024);
    // Type/frequency dropdowns are localized (not enum.label English).
    expect(find.text('Medication'), findsOneWidget);
    expect(find.text('Does not repeat'), findsOneWidget);
  });

  testWidgets('shows localized empty-pets message when no pets exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_NoPetsNotifier.new));
    await tester.pump();
    await tester.pump();

    expect(find.text('No pets found. Please add a pet first.'), findsOneWidget);
  });

  testWidgets('renders French translations when locale is fr', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_TwoPetsNotifier.new, locale: const Locale('fr')),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Ajouter un événement de santé'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Sélectionner les animaux'), findsOneWidget);
    expect(find.text('Tout sélectionner'), findsOneWidget);
    // Dropdowns localized in French too (was English enum.label before).
    expect(find.text('Médicament'), findsOneWidget);
    expect(find.text('Ne se répète pas'), findsOneWidget);
  });

  testWidgets(
    'pet profile add flow preselects that pet and back returns to profile',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapPetProfileHealthEventFlow());
      await tester.pumpAndSettle();

      expect(find.text('Pet profile for p1'), findsOneWidget);

      await tester.tap(find.text('Health Events'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_health_event_button')));
      await tester.pumpAndSettle();

      expect(find.byType(HealthEntryFormScreen), findsOneWidget);

      final rexChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Rex'),
      );
      final miloChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Milo'),
      );
      expect(rexChip.selected, isTrue);
      expect(miloChip.selected, isFalse);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(HealthEntryFormScreen), findsNothing);
      expect(find.text('Pet profile for p1'), findsOneWidget);
    },
  );
}
