import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/recurrence_anchor.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/care_item_detail/care_item_schedule_section.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_item_stat_row.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('CareItemScheduleSection renders stat row and edit affordance', (
    tester,
  ) async {
    final entry = HealthEntry(
      id: 'entry-1',
      petId: 'pet-1',
      name: 'Heartworm',
      type: HealthEntryType.preventive,
      frequency: HealthFrequency.monthly,
      frequencyInterval: 1,
      startDate: DateTime(2025, 1, 1),
      nextDueDate: DateTime(2025, 6, 15),
      recurrenceAnchor: RecurrenceAnchor.fromDueDate,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CareItemScheduleSection(
            entry: entry,
            petId: 'pet-1',
            muted: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_item_schedule_section')), findsOneWidget);
    expect(find.byType(CareItemStatRow), findsOneWidget);
    expect(find.byKey(const Key('care_item_edit_schedule')), findsOneWidget);
    expect(find.text('Fixed schedule'), findsOneWidget);
  });
}
