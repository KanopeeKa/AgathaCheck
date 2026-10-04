import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/occurrence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/occurrence_review_flow.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  group('pickOccurrenceForReview', () {
    test('prefers occurrence matching preferred date', () {
      final head = parseCalendarDate('2026-10-27')!;
      final other = parseCalendarDate('2026-10-28')!;
      final picked = OccurrenceReviewFlow.pickOccurrenceForReview([
        HealthOccurrence(
          id: 'b',
          entryId: 'e1',
          scheduledDate: other,
          status: 'pending',
        ),
        HealthOccurrence(
          id: 'a',
          entryId: 'e1',
          scheduledDate: head,
          status: 'pending',
        ),
      ], preferredDate: head);
      expect(picked?.id, 'a');
    });
  });

  testWidgets('open skips occurrence fetch when initial occurrence id is set', (
    tester,
  ) async {
    final entry = HealthEntry(
      id: 'entry-1',
      petId: 'pet-1',
      name: 'Med',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      nextDueDate: DateTime(2026, 10, 27),
    );
    final scheduled = parseCalendarDate('2026-10-27')!;
    var fetchCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryOccurrencesProvider.overrideWith((ref, id) async {
            fetchCount++;
            throw StateError('fetch should not run');
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _OpenReviewHarness(
            entry: entry,
            scheduled: scheduled,
            occurrenceId: 'occ-known',
          ),
        ),
      ),
    );

    await tester.tap(find.text('review'));
    await tester.pumpAndSettle();

    expect(fetchCount, 0);
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.careItemOccurrenceReviewTitle), findsOneWidget);
  });

  testWidgets('open loads open occurrences when occurrence id is missing', (
    tester,
  ) async {
    final entry = HealthEntry(
      id: 'entry-1',
      petId: 'pet-1',
      name: 'Med',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      nextDueDate: DateTime(2026, 10, 27),
    );
    final scheduled = parseCalendarDate('2026-10-27')!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryOccurrencesProvider.overrideWith((ref, id) async {
            expect(id, 'entry-1');
            return [
              HealthOccurrence(
                id: 'occ-new',
                entryId: id,
                scheduledDate: scheduled,
                status: 'pending',
              ),
            ];
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _OpenReviewHarness(entry: entry, scheduled: scheduled),
        ),
      ),
    );

    await tester.tap(find.text('review'));
    await tester.pumpAndSettle();

    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.careItemOccurrenceReviewTitle), findsOneWidget);
    expect(find.byKey(const Key('occurrence_review_sheet')), findsOneWidget);
  });
}

class _OpenReviewHarness extends ConsumerWidget {
  const _OpenReviewHarness({
    required this.entry,
    required this.scheduled,
    this.occurrenceId = '',
  });

  final HealthEntry entry;
  final DateTime scheduled;
  final String occurrenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () {
          OccurrenceReviewFlow.open(
            context,
            ref,
            entry,
            absenceId: 'abs-1',
            initialOccurrence: HealthOccurrence(
              id: occurrenceId,
              entryId: entry.id,
              scheduledDate: scheduled,
              status: 'pending',
            ),
          );
        },
        child: const Text('review'),
      ),
    );
  }
}
