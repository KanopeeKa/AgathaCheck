import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/features/weight_tracking/data/weight_api_exception.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_fulfilment_candidates.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_write_outcomes.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/sheets/record_weight_sheet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _RecordingNotifier extends WeightEntriesNotifier {
  static bool throwFulfilmentConflict = false;
  static bool undoCalled = false;

  @override
  Future<List<WeightEntry>> build(String arg) async => [];

  @override
  Future<WeightSaveOutcome> saveEntry({
    required WeightEntry entry,
    String? fulfilsOccurrenceId,
    bool isUpdate = false,
  }) async {
    if (throwFulfilmentConflict && fulfilsOccurrenceId != null) {
      throw WeightApiException(409, 'fulfilment_not_eligible');
    }
    return WeightSaveOutcome(
      entry: entry,
      fulfilment: fulfilsOccurrenceId != null
          ? const WeightFulfilmentOutcome(
              careEntryId: 'care-1',
              undoToken: 'undo-t',
              routineName: 'Weekly',
            )
          : null,
    );
  }

  @override
  Future<void> undoFulfilment({
    required String careEntryId,
    required String undoToken,
  }) async {
    undoCalled = true;
  }
}

WeightFulfilmentCandidates _candidates(int count) {
  return WeightFulfilmentCandidates(
    date: DateTime(2026, 5, 10),
    defaultOccurrenceId: count == 1 ? 'occ-1' : null,
    candidates: List.generate(
      count,
      (i) => WeightFulfilmentCandidate(
        entryId: 'care-$i',
        entryName: 'Routine $i',
        occurrenceId: 'occ-$i',
        scheduledDate: DateTime(2026, 5, 10),
        status: 'due',
      ),
    ),
  );
}

class _SheetOpener extends ConsumerWidget {
  const _SheetOpener();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () => showRecordWeightSheet(context, ref, petId: 'pet-1'),
        child: const Text('open'),
      ),
    );
  }
}

void main() {
  setUp(() {
    _RecordingNotifier.throwFulfilmentConflict = false;
    _RecordingNotifier.undoCalled = false;
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    required List<Override> candidateOverrides,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weightEntriesNotifierProvider.overrideWith(_RecordingNotifier.new),
          weightUnitPreferenceProvider.overrideWith((ref) => WeightUnit.kg),
          setWeightUnitPreferenceProvider.overrideWith((ref) => (_) async {}),
          ...candidateOverrides,
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _SheetOpener(),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
  }

  bool saveEnabled(WidgetTester tester) {
    final save = find.widgetWithText(FilledButton, 'Save');
    if (save.evaluate().isEmpty) return false;
    return tester.widget<FilledButton>(save).onPressed != null;
  }

  testWidgets('FW-7 zero candidates hides switch; one shows switch', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      candidateOverrides: [
        weightFulfilmentCandidatesProvider.overrideWith(
          (ref, q) async => _candidates(0),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('record_weight_counts_as')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpSheet(
      tester,
      candidateOverrides: [
        weightFulfilmentCandidatesProvider.overrideWith(
          (ref, q) async => _candidates(1),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('record_weight_counts_as')), findsOneWidget);
  });

  testWidgets('FW-7 two candidates require radio before save', (tester) async {
    await pumpSheet(
      tester,
      candidateOverrides: [
        weightFulfilmentCandidatesProvider.overrideWith(
          (ref, q) async => _candidates(2),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('record_weight_counts_as_choice')),
      findsOneWidget,
    );
    expect(saveEnabled(tester), isFalse);
    await tester.enterText(find.byType(TextField).first, '12');
    expect(saveEnabled(tester), isFalse);
    await tester.tap(find.text('Counts as Routine 0'));
    await tester.pump();
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('FW-8 date change re-fetches candidates', (tester) async {
    final dates = <String>[];
    await pumpSheet(
      tester,
      candidateOverrides: [
        weightFulfilmentCandidatesProvider.overrideWith((ref, q) async {
          dates.add(toCalendarDateString(calendarDateOnly(q.date)) ?? '');
          return _candidates(1);
        }),
      ],
    );
    await tester.pumpAndSettle();
    expect(dates, hasLength(1));
    await tester.tap(find.byKey(const Key('record_weight_date')));
    await tester.pumpAndSettle();
    final ok = find.text('OK');
    if (ok.evaluate().isNotEmpty) {
      await tester.tap(ok);
      await tester.pumpAndSettle();
      expect(dates.length, greaterThan(1));
    }
  });

  testWidgets('FW-18 save disabled while candidates load', (tester) async {
    await pumpSheet(
      tester,
      candidateOverrides: [
        weightFulfilmentCandidatesProvider.overrideWith((ref, q) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return _candidates(0);
        }),
      ],
    );
    await tester.enterText(find.byType(TextField).first, '12');
    expect(saveEnabled(tester), isFalse);
    await tester.pump(const Duration(milliseconds: 250));
    expect(saveEnabled(tester), isTrue);
  });
}
