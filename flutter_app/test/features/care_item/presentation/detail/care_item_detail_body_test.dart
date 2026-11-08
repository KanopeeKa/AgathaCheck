import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_absence_context_model.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/care_item_absence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/occurrence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry_photo.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/pet_event_view_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/core/care/care_item_observation_section.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/detail/care_item_detail_body.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/widgets/weight_care_item_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _EmptyWeightEntriesNotifier extends WeightEntriesNotifier {
  @override
  Future<List<WeightEntry>> build(String arg) async => [];
}

void main() {
  const pet = Pet(
    id: 'pet-1',
    name: 'Bella',
    species: 'Dog',
    colorValue: 0xFF2196F3,
  );

  final entry = HealthEntry(
    id: 'entry-1',
    petId: 'pet-1',
    name: 'Heartworm',
    type: HealthEntryType.preventive,
    frequency: HealthFrequency.monthly,
    frequencyInterval: 1,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 6, 1),
  );

  testWidgets('CareItemDetailBody uses two columns at wide breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('care_item_detail_two_column')),
      findsOneWidget,
    );

    final stripRect = tester.getRect(
      find.byKey(const Key('care_item_context_strip')),
    );
    final rowRect = tester.getRect(
      find.byKey(const Key('care_item_detail_two_column')),
    );
    expect(stripRect.top, lessThan(rowRect.top));
    expect(stripRect.width, greaterThanOrEqualTo(rowRect.width));

    final detailsRect = tester.getRect(
      find.byKey(const Key('care_item_details_module')),
    );
    expect(detailsRect.top, lessThan(rowRect.top));
  });

  testWidgets(
    'CareItemDetailBody places Details above Needs attention on mobile',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('http://test.local'),
            careItemAbsenceContextProvider('entry-1').overrideWith(
              (ref) async => const HealthEntryAbsenceContext(
                healthEntryId: 'entry-1',
                petId: 'pet-1',
                absences: [],
              ),
            ),
            entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CareItemDetailBody(
                petId: 'pet-1',
                entry: entry,
                pet: pet,
                history: const <HealthHistoryEntry>[],
                isClosed: false,
                isEstablished: false,
                onSeeHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final detailsRect = tester.getRect(
        find.byKey(const Key('care_item_details_module')),
      );
      final datesRect = tester.getRect(
        find.byKey(const Key('care_item_dates_section')),
      );
      expect(detailsRect.top, lessThan(datesRect.top));
    },
  );

  testWidgets(
    'FW-17 weigh-in routine shows weight section; medication does not',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Widget buildFor(HealthEntry healthEntry) {
        return ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('http://test.local'),
            careItemAbsenceContextProvider(healthEntry.id).overrideWith(
              (ref) async => HealthEntryAbsenceContext(
                healthEntryId: healthEntry.id,
                petId: 'pet-1',
                absences: [],
              ),
            ),
            entryOccurrencesProvider(
              healthEntry.id,
            ).overrideWith((ref) async => []),
            careItemObservationSectionProvider.overrideWith(
              (ref) =>
                  (
                    context, {
                    required petId,
                    required entryId,
                    required observationKind,
                  }) {
                    if (observationKind == 'numeric_weight') {
                      return WeightCareItemSection(
                        petId: petId,
                        entryId: entryId,
                      );
                    }
                    return null;
                  },
            ),
            weightEntriesNotifierProvider.overrideWith(
              () => _EmptyWeightEntriesNotifier(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CareItemDetailBody(
                petId: 'pet-1',
                entry: healthEntry,
                pet: pet,
                history: const <HealthHistoryEntry>[],
                isClosed: false,
                isEstablished: false,
                onSeeHistory: () {},
              ),
            ),
          ),
        );
      }

      final weightEntry = HealthEntry(
        id: 'weight-entry',
        petId: 'pet-1',
        name: 'Weekly weigh-in',
        type: HealthEntryType.preventive,
        frequency: HealthFrequency.monthly,
        frequencyInterval: 1,
        startDate: DateTime(2025, 1, 1),
        nextDueDate: DateTime(2025, 6, 1),
        careFamily: CareFamily.weightMonitoring,
      );

      await tester.pumpWidget(buildFor(weightEntry));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('weight_care_item_section')), findsOneWidget);
    },
  );

  testWidgets('FW-17 medication care item hides weight section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final medicationEntry = HealthEntry(
      id: 'med-entry',
      petId: 'pet-1',
      name: 'Heartworm',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      frequencyInterval: 1,
      startDate: DateTime(2025, 1, 1),
      nextDueDate: DateTime(2025, 6, 1),
      careFamily: CareFamily.medication,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('med-entry').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'med-entry',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('med-entry').overrideWith((ref) async => []),
          careItemObservationSectionProvider.overrideWith(
            (ref) =>
                (
                  context, {
                  required petId,
                  required entryId,
                  required observationKind,
                }) {
                  if (observationKind == 'numeric_weight') {
                    return WeightCareItemSection(
                      petId: petId,
                      entryId: entryId,
                    );
                  }
                  return null;
                },
          ),
          weightEntriesNotifierProvider.overrideWith(
            () => _EmptyWeightEntriesNotifier(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: medicationEntry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weight_care_item_section')), findsNothing);
  });

  testWidgets('History module shows one past-occurrences list without unmark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final past = List.generate(
      2,
      (i) => HealthOccurrence(
        id: 'hist-$i',
        entryId: 'entry-1',
        scheduledDate: DateTime(2025, 5, 2 - i),
        status: 'completed',
        completedOn: DateTime(2025, 5, 2 - i),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
          entryPastOccurrencesProvider(
            'entry-1',
          ).overrideWith((ref) async => past),
          healthEntryPhotosProvider('entry-1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_item_history_module')), findsOneWidget);
    expect(
      find.byKey(const Key('pet_event_past_iterations_header')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('pet_event_past_occurrences_header')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('pet_event_past_occurrence_hist-0')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('unmark_done_hist-0')), findsNothing);
  });

  testWidgets(
    'Schedule and History use one section gap when optional modules hidden',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final medicationEntry = HealthEntry(
        id: 'med-gap',
        petId: 'pet-1',
        name: 'Daily pill',
        type: HealthEntryType.medication,
        frequency: HealthFrequency.daily,
        frequencyInterval: 1,
        startDate: DateTime(2025, 1, 1),
        nextDueDate: DateTime(2025, 6, 1),
        careFamily: CareFamily.medication,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiBaseUrlProvider.overrideWithValue('http://test.local'),
            careItemAbsenceContextProvider('med-gap').overrideWith(
              (ref) async => const HealthEntryAbsenceContext(
                healthEntryId: 'med-gap',
                petId: 'pet-1',
                absences: [],
              ),
            ),
            entryOccurrencesProvider('med-gap').overrideWith((ref) async => []),
            entryPastOccurrencesProvider(
              'med-gap',
            ).overrideWith((ref) async => []),
            healthEntryPhotosProvider(
              'med-gap',
            ).overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CareItemDetailBody(
                petId: 'pet-1',
                entry: medicationEntry,
                pet: pet,
                history: const <HealthHistoryEntry>[],
                isClosed: false,
                isEstablished: false,
                onSeeHistory: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scheduleBottom = tester
          .getRect(find.byKey(const Key('care_item_schedule_section')))
          .bottom;
      final historyTop = tester
          .getRect(find.byKey(const Key('care_item_history_module')))
          .top;
      expect(historyTop - scheduleBottom, 16.0);
    },
  );

  testWidgets('Documents module appears above History when files exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final photo = EventPhoto(
      id: 'p1',
      eventId: 'entry-1',
      photoPath: '/files/a.pdf',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
          entryPastOccurrencesProvider(
            'entry-1',
          ).overrideWith((ref) async => []),
          healthEntryPhotosProvider(
            'entry-1',
          ).overrideWith((ref) async => [photo]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final documentsRect = tester.getRect(
      find.byKey(const Key('care_item_documents_module')),
    );
    final historyRect = tester.getRect(
      find.byKey(const Key('care_item_history_module')),
    );
    expect(documentsRect.top, lessThan(historyRect.top));
    expect(
      find.descendant(
        of: find.byKey(const Key('care_item_documents_module')),
        matching: find.text('Documents'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('History lists not_recorded past occurrences', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final past = [
      HealthOccurrence(
        id: 'hist-nr',
        entryId: 'entry-1',
        scheduledDate: DateTime(2025, 4, 1),
        status: 'not_recorded',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
          entryPastOccurrencesProvider(
            'entry-1',
          ).overrideWith((ref) async => past),
          healthEntryPhotosProvider('entry-1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pet_event_past_occurrence_hist-nr')),
      findsOneWidget,
    );
    expect(find.text('No history yet.'), findsNothing);
  });

  testWidgets('History shows empty copy and hides documents strip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
          entryPastOccurrencesProvider(
            'entry-1',
          ).overrideWith((ref) async => []),
          healthEntryPhotosProvider('entry-1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_item_documents_module')), findsNothing);
    expect(find.byKey(const Key('care_item_history_module')), findsOneWidget);
    expect(find.text('No history yet.'), findsOneWidget);
    expect(find.text('up to 4 documents'), findsNothing);
  });

  testWidgets('Close care sits below History on mobile when callback set', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
              onCloseCare: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('care_item_close_care_button')),
      findsOneWidget,
    );
    final historyBottom = tester
        .getRect(find.byKey(const Key('care_item_history_module')))
        .bottom;
    final closeButtonTop = tester
        .getRect(find.byKey(const Key('care_item_close_care_button')))
        .top;
    expect(closeButtonTop, greaterThan(historyBottom));
  });

  testWidgets('Close care sits below History in main column on wide layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
              onCloseCare: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final closeButton = find.byKey(const Key('care_item_close_care_button'));
    expect(closeButton, findsOneWidget);
    final historyRect = tester.getRect(
      find.byKey(const Key('care_item_history_module')),
    );
    final buttonRect = tester.getRect(closeButton);
    expect(buttonRect.width, closeTo(historyRect.width / 3, 2));
    expect(buttonRect.right, closeTo(historyRect.right, 2));

    final closeButtonTop = tester.getRect(closeButton).top;
    expect(closeButtonTop, greaterThan(historyRect.bottom));
  });

  testWidgets('omits Close care when no callback', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_item_close_care_button')), findsNothing);
  });

  testWidgets('Close care label fits French at one-third mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          careItemAbsenceContextProvider('entry-1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'entry-1',
              petId: 'pet-1',
              absences: [],
            ),
          ),
          entryOccurrencesProvider('entry-1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDetailBody(
              petId: 'pet-1',
              entry: entry,
              pet: pet,
              history: const <HealthHistoryEntry>[],
              isClosed: false,
              isEstablished: false,
              onSeeHistory: () {},
              onCloseCare: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('care_item_close_care_button')),
      findsOneWidget,
    );
  });
}
