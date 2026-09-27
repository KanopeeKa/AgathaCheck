import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/occurrence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/care_item_detail/care_item_dates_section.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_item_status_pill.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

HealthOccurrence _occ({
  required String id,
  required DateTime date,
  String? scheduledTime = '08:00',
}) {
  return HealthOccurrence(
    id: id,
    entryId: 'entry-1',
    scheduledDate: date,
    scheduledTime: scheduledTime,
    status: 'pending',
  );
}

void main() {
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

  testWidgets('CareItemDatesSection wraps zoned rows in module with status pills', (
    tester,
  ) async {
    final today = calendarDateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryOccurrencesProvider('entry-1').overrideWith(
            (ref) async => [
              _occ(id: 'occ-missed', date: yesterday),
              _occ(id: 'occ-today', date: today, scheduledTime: '23:59'),
            ],
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemDatesSection(entry: entry, muted: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('care_item_needs_attention_section')),
      findsOneWidget,
    );
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Heartworm'), findsNWidgets(2));
    expect(find.byType(CareItemStatusPill), findsNWidgets(2));
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(
      find.byKey(const Key('care_item_occurrence_mark_done_occ-today')),
      findsOneWidget,
    );
  });
}
