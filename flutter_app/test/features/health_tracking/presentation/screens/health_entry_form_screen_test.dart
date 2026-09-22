import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/create_health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/get_health_entries.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/update_health_entry.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_importance.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_setting.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_constants.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/health_events_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeHealthRepository implements HealthRepository {
  _FakeHealthRepository(this.entry, {this.onUpdate});

  final HealthEntry entry;
  final void Function(HealthEntry entry)? onUpdate;

  @override
  Future<HealthEntry?> getEntry(String id) async => entry;

  @override
  Future<List<HealthEntry>> getEntries({
    String? petId,
    HealthEntryType? type,
  }) async => [entry];

  @override
  Future<HealthEntry> updateEntry(HealthEntry entry) async {
    onUpdate?.call(entry);
    return entry;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

class _TestHealthEntriesNotifier extends HealthEntriesNotifier {
  static HealthEntry? lastUpdated;

  @override
  Future<List<HealthEntry>> build() async => [];

  @override
  Future<void> updateEntry(HealthEntry entry) async {
    lastUpdated = entry;
  }
}

class _RecordingHealthRepository implements HealthRepository {
  _RecordingHealthRepository(this.seed);

  final HealthEntry seed;
  HealthEntry? lastCreated;
  HealthEntry? lastUpdated;

  @override
  Future<HealthEntry> createEntry(HealthEntry entry) async {
    lastCreated = entry;
    return entry.copyWith(id: 'created-entry');
  }

  @override
  Future<HealthEntry?> getEntry(String id) async => seed;

  @override
  Future<List<HealthEntry>> getEntries({
    String? petId,
    HealthEntryType? type,
  }) async => [seed];

  @override
  Future<HealthEntry> updateEntry(HealthEntry entry) async {
    lastUpdated = entry;
    return entry;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

HealthEntry _sampleEntry({
  HealthEntryType type = HealthEntryType.preventive,
  HealthFrequency frequency = HealthFrequency.monthly,
  CareFamily? careFamily = CareFamily.parasitePrevention,
}) {
  return HealthEntry(
    id: 'entry-1',
    petId: 'p1',
    name: 'Heartworm',
    type: type,
    dosage: '1 tablet',
    frequency: frequency,
    frequencyInterval: 1,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 8, 1),
    careFamily: careFamily,
  );
}

Widget _wrapAddFlow({required _RecordingHealthRepository repository}) {
  final router = GoRouter(
    initialLocation: '/pet/p1/health/add',
    routes: [
      GoRoute(
        path: '/pet/:petId/health/add',
        builder: (context, state) =>
            HealthEntryFormScreen(petId: state.pathParameters['petId']),
      ),
      GoRoute(
        path: '/pet/:petId',
        builder: (context, state) =>
            Scaffold(body: Text('Pet ${state.pathParameters['petId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(_TwoPetsNotifier.new),
      healthEntriesNotifierProvider.overrideWith(
        _EmptyHealthEntriesNotifier.new,
      ),
      createHealthEntryProvider.overrideWithValue(
        CreateHealthEntry(repository),
      ),
      getHealthEntriesProvider.overrideWithValue(GetHealthEntries(repository)),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _fillMinimalAddForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('health_name_field')),
    'Evening pill',
  );
  final completedField = find.bySemanticsLabel(RegExp(r'Completed on:'));
  await _scrollTo(tester, completedField);
  await tester.tap(completedField);
  await tester.pumpAndSettle();
  final ok = find.widgetWithText(TextButton, 'OK');
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok);
  } else {
    await tester.tap(find.text('OK'));
  }
  await tester.pumpAndSettle();
}

Future<void> _selectCareFamily(WidgetTester tester, String label) async {
  await _scrollTo(tester, find.byKey(const Key('care_family_picker')));
  await tester.tap(find.byKey(const Key('care_family_picker')));
  await tester.pumpAndSettle();
  final option = find.text(label).last;
  await _scrollTo(tester, option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Widget _wrapEditFlow({
  required HealthEntry entry,
  String initialLocation = '/pet/p1/events/entry-1/edit',
  void Function(HealthEntry entry)? onUpdate,
}) {
  final repository = onUpdate == null
      ? _FakeHealthRepository(entry)
      : _FakeHealthRepository(entry, onUpdate: onUpdate);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/pet/:petId/events/:entryId/edit',
        builder: (context, state) => HealthEntryFormScreen(
          entryId: state.pathParameters['entryId'],
          petId: state.pathParameters['petId'],
          allowedTypes: kAllPetEventTypes,
        ),
      ),
      GoRoute(
        path: '/pet/:petId/events/:entryId',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('View entry'))),
      ),
      GoRoute(
        path: '/pet/:petId/health/edit/:id',
        redirect: (context, state) => redirectLegacyPetEventEditPath(state),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(_TwoPetsNotifier.new),
      healthRepositoryProvider.overrideWithValue(repository),
      healthEntriesNotifierProvider.overrideWith(
        _TestHealthEntriesNotifier.new,
      ),
      getHealthEntriesProvider.overrideWithValue(GetHealthEntries(repository)),
      updateHealthEntryProvider.overrideWithValue(
        UpdateHealthEntry(repository),
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
    expect(
      find.text('up to 4 documents (jpg, png, pdf), max 2 MB'),
      findsOneWidget,
    );
    expect(healthDocumentAllowedExtensions, ['jpg', 'jpeg', 'png', 'pdf']);
    expect(healthDocumentMaxBytes, 2 * 1024 * 1024);
    // Classification section and frequency are localized (not enum.label English).
    expect(find.text('Care category'), findsOneWidget);
    expect(find.text('Where'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
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
    // Classification section localized in French too.
    expect(find.text('Catégorie de soins'), findsOneWidget);
    expect(find.text('Où'), findsOneWidget);
    expect(find.text('Priorité'), findsOneWidget);
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

  testWidgets(
    'edit form omits administration history and legacy type picker',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapEditFlow(entry: _sampleEntry(type: HealthEntryType.other)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Edit Entry'), findsOneWidget);
      expect(find.text('Administration History'), findsNothing);
      expect(
        find.byKey(const Key('delete_health_entry_button')),
        findsOneWidget,
      );
      expect(find.byType(DropdownButtonFormField<HealthEntryType>), findsNothing);
      expect(find.byKey(const Key('care_setting_picker')), findsOneWidget);
      expect(find.byKey(const Key('care_importance_optional')), findsOneWidget);
    },
  );

  test('recurring delete copy warns all iterations are removed', () {
    final l = lookupAppLocalizations(const Locale('en'));
    expect(
      l.deleteRecurringEntryNamedConfirm('Heartworm'),
      contains('permanently removed'),
    );
    expect(
      l.deleteRecurringEntryNamedConfirm('Heartworm'),
      contains('iterations'),
    );
  });

  testWidgets('add flow blocks submit until care family is chosen', (
    WidgetTester tester,
  ) async {
    final repository = _RecordingHealthRepository(
      HealthEntry(
        id: '',
        petId: 'p1',
        name: '',
        type: HealthEntryType.medication,
        dosage: '',
        frequency: HealthFrequency.once,
        frequencyInterval: 1,
        startDate: DateTime(2025, 1, 1),
      ),
    );
    await tester.pumpWidget(_wrapAddFlow(repository: repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_family_picker')), findsOneWidget);

    await _fillMinimalAddForm(tester);
    await _scrollTo(tester, find.byKey(const Key('save_health_entry_button')));
    await tester.tap(find.byKey(const Key('save_health_entry_button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Choose a care category before saving.'), findsOneWidget);
    expect(repository.lastCreated, isNull);

    await _selectCareFamily(tester, 'Medication');
    await _scrollTo(tester, find.byKey(const Key('save_health_entry_button')));
    await tester.tap(find.byKey(const Key('save_health_entry_button')));
    await tester.pumpAndSettle();

    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('Keep active'));
      await tester.pumpAndSettle();
    }

    expect(repository.lastCreated, isNotNull);
    expect(repository.lastCreated!.careFamily, CareFamily.medication);
    expect(repository.lastCreated!.careSetting, CareSetting.home);
    expect(repository.lastCreated!.careImportance, CareImportance.essential);
  });

  testWidgets(
    'editing uncategorised entry shows dismissible suggestion banner',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapEditFlow(entry: _sampleEntry(careFamily: null)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('care_family_suggestion_banner')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('care_family_picker')), findsNothing);

      await _scrollTo(
        tester,
        find.byKey(const Key('care_family_suggestion_dismiss')),
      );
      await tester.tap(find.byKey(const Key('care_family_suggestion_dismiss')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('care_family_suggestion_banner')),
        findsNothing,
      );
    },
  );

  testWidgets('editing categorised entry shows picker without suggestion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapEditFlow(
        entry: _sampleEntry(careFamily: CareFamily.parasitePrevention),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('care_family_suggestion_banner')),
      findsNothing,
    );
    expect(find.byKey(const Key('care_family_picker')), findsOneWidget);
  });

  testWidgets('legacy health edit path redirects to unified edit route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapEditFlow(
        entry: _sampleEntry(),
        initialLocation: '/pet/p1/health/edit/entry-1',
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Edit Entry'), findsOneWidget);
    expect(find.byType(HealthEntryFormScreen), findsOneWidget);
  });
}
