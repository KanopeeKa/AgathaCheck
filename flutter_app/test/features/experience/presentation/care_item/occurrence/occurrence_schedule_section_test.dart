import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_schedule_section.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_absence_context_model.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/care_item_absence_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

OccurrenceDetail _openDetail() {
  return OccurrenceDetail(
    item: CareItemSummary(
      id: 'e1',
      petId: 'p1',
      name: 'Flea',
      careFamily: 'parasite_prevention',
      isFixedSchedule: true,
      status: 'active',
      asOf: CareAsOf(
        date: DateTime(2026, 6, 10),
        time: '09:00',
        timezone: 'UTC',
      ),
    ),
    occurrence: CareOccurrence(
      id: 'o1',
      date: DateTime(2026, 6, 10),
      status: CareOccurrenceStatus.due,
      origin: CareOccurrenceOrigin.schedule,
      isOpen: true,
    ),
    schedule: CareItemSchedule(
      entryId: 'e1',
      petId: 'p1',
      name: 'Flea',
      isFixedSchedule: true,
      status: 'active',
      openOccurrences: const [],
      asOf: CareAsOf(
        date: DateTime(2026, 6, 10),
        time: '09:00',
        timezone: 'UTC',
      ),
    ),
  );
}

void main() {
  testWidgets('open occurrence shows due row and skip control', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careItemAbsenceContextProvider('e1').overrideWith(
            (ref) async => const HealthEntryAbsenceContext(
              healthEntryId: 'e1',
              petId: 'p1',
              absences: [],
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OccurrenceScheduleSection(
              entryId: 'e1',
              detail: _openDetail(),
              onChanged: () async {},
              scheduleActionsBusy: false,
              onChangeDate: () {},
              onSkip: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('occurrence_due_label')), findsOneWidget);
    expect(find.byKey(const Key('occurrence_skip')), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('occurrence_schedule_section'),
      findsOneWidget,
    );
  });
}
