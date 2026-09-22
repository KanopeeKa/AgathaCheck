import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_care/domain/care_temporal_group.dart';
import 'package:pet_profile_app/features/pet_care/domain/services/care_temporal_grouping_service.dart';
import 'package:pet_profile_app/features/pet_care/presentation/providers/care_temporal_grouping_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/care_progression_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/all_care/all_care_list.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  _FakeHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

HealthEntry _entry({
  required String id,
  required DateTime nextDue,
  HealthFrequency frequency = HealthFrequency.daily,
}) {
  return HealthEntry(
    id: id,
    petId: 'pet-1',
    name: id,
    type: HealthEntryType.medication,
    frequency: frequency,
    startDate: nextDue.subtract(const Duration(days: 1)),
    nextDueDate: nextDue,
    remindDaysBefore: 3,
  );
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Widget _wrap(List<HealthEntry> entries, {ProviderContainer? container}) {
  final scope = container ?? _buildContainer(entries);
  return UncontrolledProviderScope(
    container: scope,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AllCareList(petId: 'pet-1')),
    ),
  );
}

ProviderContainer _buildContainer(List<HealthEntry> entries) {
  final container = ProviderContainer(
    overrides: [
      healthEntriesNotifierProvider.overrideWith(
        () => _FakeHealthEntriesNotifier(entries),
      ),
      petCareEstablishmentsProvider.overrideWith((ref, petId) async => []),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  testWidgets('renders temporal groups with care action rows', (tester) async {
    final today = _today();
    await tester.pumpWidget(
      _wrap([
        _entry(id: 'overdue', nextDue: today.subtract(const Duration(days: 1))),
        _entry(id: 'today', nextDue: today),
        _entry(id: 'upcoming', nextDue: today.add(const Duration(days: 2))),
        _entry(
          id: 'one-off-done',
          nextDue: DateTime(9999),
          frequency: HealthFrequency.once,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('all_care_list')), findsOneWidget);
    expect(
      find.byKey(const Key('pet_care_group_needsAttention')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pet_care_group_today')), findsOneWidget);
    expect(find.byKey(const Key('pet_care_group_upcoming')), findsOneWidget);
    expect(find.byKey(const Key('pet_care_action_overdue')), findsOneWidget);
    expect(find.byKey(const Key('pet_care_action_today')), findsOneWidget);
    expect(find.byKey(const Key('all_care_inactive_section')), findsOneWidget);
    expect(
      find.byKey(const Key('pet_care_action_one-off-done')),
      findsOneWidget,
    );
    expect(find.text('Done'), findsWidgets);
    expect(
      find.byKey(const Key('pet_manage_events_collection_filter_bar')),
      findsNothing,
    );
    expect(find.text('Recurring'), findsNothing);
    expect(find.text('One-time'), findsNothing);
  });

  testWidgets('shows empty state when pet has no care items', (tester) async {
    await tester.pumpWidget(_wrap([]));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('all_care_empty')), findsOneWidget);
    expect(find.text('Start their care routine'), findsOneWidget);
  });

  testWidgets('profile and All care place the same item in the same group', (
    tester,
  ) async {
    const grouping = CareTemporalGroupingService();
    final today = _today();
    final entries = [
      _entry(id: 'overdue', nextDue: today.subtract(const Duration(days: 2))),
      _entry(id: 'today', nextDue: today),
      _entry(id: 'upcoming', nextDue: today.add(const Duration(days: 1))),
    ];

    final container = _buildContainer(entries);
    await tester.pumpWidget(_wrap(entries, container: container));
    await tester.pumpAndSettle();

    final buckets = grouping.bucketsForEntries(
      entries,
      petId: 'pet-1',
      now: DateTime.now(),
    );

    // Provider agreement (issue #1139): the widget renders from
    // petCareTemporalBucketsProvider, so its grouping must match the
    // service result the test asserts against.
    final providerBuckets = container.read(
      petCareTemporalBucketsProvider('pet-1'),
    );
    for (final group in CareTemporalGroup.values) {
      final providerIds = providerBuckets
          .entriesIn(group)
          .map((entry) => entry.id)
          .toSet();
      final serviceIds = buckets
          .entriesIn(group)
          .map((entry) => entry.id)
          .toSet();
      expect(providerIds, serviceIds, reason: 'provider agrees on $group');
    }

    for (final group in CareTemporalGroup.values) {
      for (final entry in buckets.entriesIn(group)) {
        expect(
          find.byKey(Key('pet_care_group_${group.name}')),
          findsOneWidget,
          reason: 'group header for ${entry.id}',
        );
        expect(
          find.byKey(Key('pet_care_action_${entry.id}')),
          findsOneWidget,
          reason: 'action row for ${entry.id}',
        );
      }
    }
  });
}
