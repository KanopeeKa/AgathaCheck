import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/core/widgets/care_mark_done_button.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/care_progression_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/all_care/all_care_list.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/care_schedule_entries.dart';

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
  testWidgets(
    'planned care uses the agenda; ended care follows without a tick',
    (tester) async {
      await tester.pumpWidget(
        _wrap([
          scheduledEntry(id: 'overdue', name: 'overdue', dueInDays: -1),
          scheduledEntry(id: 'today', name: 'today', dueInDays: 0),
          scheduledEntry(id: 'upcoming', name: 'upcoming', dueInDays: 2),
          _entry(
            id: 'one-off-done',
            nextDue: DateTime(9999),
            frequency: HealthFrequency.once,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('all_care_list')), findsOneWidget);
      expect(find.byKey(const Key('care_agenda_today')), findsOneWidget);
      expect(find.byKey(const Key('care_agenda_due_soon')), findsOneWidget);
      expect(find.byKey(const Key('pet_care_action_overdue')), findsOneWidget);
      expect(find.byKey(const Key('pet_care_action_today')), findsOneWidget);
      expect(find.byKey(const Key('pet_care_action_upcoming')), findsOneWidget);
      expect(
        find.byKey(const Key('all_care_inactive_section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('pet_care_action_one-off-done')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('pet_care_action_done_one-off-done')),
        findsNothing,
      );
      expect(find.byType(CareMarkDoneButton), findsNWidgets(3));
    },
  );

  testWidgets('shows empty state when pet has no care items', (tester) async {
    await tester.pumpWidget(_wrap([]));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('all_care_empty')), findsOneWidget);
    expect(find.text('Start their care routine'), findsOneWidget);
  });
}
