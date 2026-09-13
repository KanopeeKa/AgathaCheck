import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_establishment.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/care_progression_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_care_section/pet_care_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  _FakeHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;
  int markTakenCalls = 0;
  String? lastMarkTakenId;

  @override
  Future<List<HealthEntry>> build() async => _entries;

  @override
  Future<void> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async {
    markTakenCalls++;
    lastMarkTakenId = id;
    _entries.removeWhere((entry) => entry.id == id);
    state = AsyncValue.data(List<HealthEntry>.from(_entries));
  }
}

HealthEntry _entry({
  required String id,
  required String petId,
  required String name,
  required DateTime nextDue,
  int remindDaysBefore = 3,
  HealthFrequency frequency = HealthFrequency.daily,
  CareFamily? careFamily,
  HealthEntryType type = HealthEntryType.medication,
}) {
  return HealthEntry(
    id: id,
    petId: petId,
    name: name,
    type: type,
    frequency: frequency,
    startDate: nextDue.subtract(const Duration(days: 1)),
    nextDueDate: nextDue,
    remindDaysBefore: remindDaysBefore,
    careFamily: careFamily,
  );
}

DateTime _todayDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Widget _wrap({
  required List<HealthEntry> entries,
  required HealthEntriesNotifier Function() notifierFactory,
  List<CareEstablishment> establishments = const [],
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: PetCareSection(
            petId: 'pet-1',
            pet: const Pet(id: 'pet-1', name: 'Buddy', species: 'Dog'),
          ),
        ),
      ),
      GoRoute(
        path: '/pet/:petId/events',
        builder: (context, state) =>
            const Scaffold(body: Text('All care destination')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      healthEntriesNotifierProvider.overrideWith(notifierFactory),
      petCareEstablishmentsProvider.overrideWith(
        (ref, petId) => Future.value(establishments),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('renders temporal groups and omits empty groups', (tester) async {
    final today = _todayDate();
    final entries = [
      _entry(
        id: 'overdue-1',
        petId: 'pet-1',
        name: 'Overdue med',
        nextDue: today.subtract(const Duration(days: 2)),
      ),
      _entry(
        id: 'today-1',
        petId: 'pet-1',
        name: 'Morning walk',
        nextDue: today,
      ),
      _entry(
        id: 'upcoming-1',
        petId: 'pet-1',
        name: 'Nail trim',
        nextDue: today.add(const Duration(days: 2)),
        remindDaysBefore: 3,
      ),
    ];

    await tester.pumpWidget(
      _wrap(
        entries: entries,
        notifierFactory: () => _FakeHealthEntriesNotifier(entries),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Buddy's care"), findsOneWidget);
    expect(
      find.byKey(const Key('pet_care_group_needsAttention')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pet_care_group_today')), findsOneWidget);
    expect(find.byKey(const Key('pet_care_group_upcoming')), findsOneWidget);
    expect(find.text('Overdue med'), findsOneWidget);
    expect(find.text('Morning walk'), findsOneWidget);
    expect(find.text('Nail trim'), findsOneWidget);
    expect(find.byKey(const Key('pet_care_view_all')), findsOneWidget);
  });

  testWidgets('shows empty state when no open care items', (tester) async {
    await tester.pumpWidget(
      _wrap(
        entries: const [],
        notifierFactory: () => _FakeHealthEntriesNotifier(const []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_care_section_empty')), findsOneWidget);
    expect(find.text('All caught up'), findsOneWidget);
    expect(find.byKey(const Key('pet_care_group_today')), findsNothing);
  });

  testWidgets('renders uncategorised item and established marker', (
    tester,
  ) async {
    final today = _todayDate();
    final entries = [
      _entry(
        id: 'uncat-1',
        petId: 'pet-1',
        name: 'Mystery care',
        nextDue: today,
        careFamily: null,
        type: HealthEntryType.other,
      ),
      _entry(
        id: 'weight-1',
        petId: 'pet-1',
        name: 'Weekly weight',
        nextDue: today.add(const Duration(days: 1)),
        careFamily: CareFamily.weightMonitoring,
        remindDaysBefore: 3,
      ),
    ];
    final establishments = [
      CareEstablishment(
        id: 'est-1',
        careFamily: CareFamily.weightMonitoring,
        healthEntryId: 'weight-1',
        establishedAt: DateTime(2025, 1, 1),
        policyVersion: 'v1',
      ),
    ];

    await tester.pumpWidget(
      _wrap(
        entries: entries,
        notifierFactory: () => _FakeHealthEntriesNotifier(entries),
        establishments: establishments,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mystery care'), findsOneWidget);
    expect(find.text('Weekly weight'), findsOneWidget);
    expect(find.textContaining('Established'), findsOneWidget);
    expect(find.text('Done'), findsWidgets);
  });

  testWidgets('optimistic completion removes item from its group', (
    tester,
  ) async {
    final today = _todayDate();
    final entries = [
      _entry(
        id: 'today-1',
        petId: 'pet-1',
        name: 'Morning supplement',
        nextDue: today,
      ),
    ];
    final notifier = _FakeHealthEntriesNotifier(entries);

    await tester.pumpWidget(
      _wrap(entries: entries, notifierFactory: () => notifier),
    );
    await tester.pumpAndSettle();

    expect(find.text('Morning supplement'), findsOneWidget);
    expect(find.byKey(const Key('pet_care_group_today')), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Morning supplement'), findsNothing);
    expect(find.byKey(const Key('pet_care_section_empty')), findsOneWidget);
    expect(notifier.markTakenCalls, 1);
    expect(notifier.lastMarkTakenId, 'today-1');
  });
}
