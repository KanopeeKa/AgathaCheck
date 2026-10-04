import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/ensure_open_occurrence_result.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/occurrence_review_flow.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _EnsureTestRepository implements HealthRepository {
  _EnsureTestRepository({required this.onEnsure});

  final Future<EnsureOpenOccurrenceResult> Function(
    String entryId, {
    DateTime? scheduledDate,
    String? reasonCode,
  })
  onEnsure;

  int ensureCallCount = 0;

  @override
  Future<EnsureOpenOccurrenceResult> ensureOpenOccurrence(
    String entryId, {
    DateTime? scheduledDate,
    String? reasonCode,
  }) {
    ensureCallCount++;
    return onEnsure(
      entryId,
      scheduledDate: scheduledDate,
      reasonCode: reasonCode,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('pickOccurrenceForReview', () {
    test('prefers occurrence matching head_date', () {
      final head = parseCalendarDate('2026-10-27')!;
      final other = parseCalendarDate('2026-10-28')!;
      final picked = OccurrenceReviewFlow.pickOccurrenceForReview(
        EnsureOpenOccurrenceResult(
          occurrences: [
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
          ],
          created: true,
          headDate: head,
        ),
        'e1',
      );
      expect(picked?.id, 'a');
    });
  });

  testWidgets('open skips ensure-open when initial occurrence id is set', (
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
    final repository = _EnsureTestRepository(
      onEnsure: (_, {scheduledDate, reasonCode}) async {
        throw StateError('ensure-open should not run');
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthRepositoryProvider.overrideWithValue(repository)],
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

    expect(repository.ensureCallCount, 0);
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.careItemOccurrenceReviewTitle), findsOneWidget);
  });

  testWidgets('open calls ensure-open when occurrence id is missing', (
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
    late _EnsureTestRepository repository;

    repository = _EnsureTestRepository(
      onEnsure: (entryId, {scheduledDate, reasonCode}) async {
        expect(entryId, 'entry-1');
        expect(scheduledDate, scheduled);
        expect(reasonCode, 'absence_review');
        return EnsureOpenOccurrenceResult(
          occurrences: [
            HealthOccurrence(
              id: 'occ-new',
              entryId: entryId,
              scheduledDate: scheduled,
              status: 'pending',
            ),
          ],
          created: true,
          headDate: scheduled,
        );
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _OpenReviewHarness(entry: entry, scheduled: scheduled),
        ),
      ),
    );

    await tester.tap(find.text('review'));
    await tester.pumpAndSettle();

    expect(repository.ensureCallCount, 1);
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
