import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/domain/care_occurrence.dart';
import 'package:pet_profile_app/features/care_item/domain/occurrence_detail.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_status_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('shows Done pill for a completed occurrence', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final detail = OccurrenceDetail(
      item: CareItemSummary(
        id: 'e1',
        petId: 'p1',
        name: 'Groom',
        isFixedSchedule: true,
        status: 'active',
        asOf: CareAsOf(
          date: DateTime(2026, 10, 6),
          time: '09:00',
          timezone: 'UTC',
        ),
      ),
      occurrence: CareOccurrence(
        id: 'o1',
        date: DateTime(2026, 10, 6),
        status: CareOccurrenceStatus.done,
        origin: CareOccurrenceOrigin.schedule,
        isOpen: false,
        completedOn: DateTime(2026, 10, 6),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: OccurrenceStatusSection(detail: detail)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l.done), findsOneWidget);
    expect(find.text(l.careStatusComingUp), findsNothing);
  });
}
