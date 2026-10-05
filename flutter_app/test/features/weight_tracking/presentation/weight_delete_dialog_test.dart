import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_fulfils.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_write_outcomes.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/widgets/weight_delete_dialog.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _DeleteNotifier extends WeightEntriesNotifier {
  @override
  Future<List<WeightEntry>> build(String arg) async => [];

  @override
  Future<WeightDeleteOutcome> deleteEntry(String id) async {
    return const WeightDeleteOutcome();
  }
}

class _DeleteLinkedNotifier extends WeightEntriesNotifier {
  @override
  Future<List<WeightEntry>> build(String arg) async => [];

  @override
  Future<WeightDeleteOutcome> deleteEntry(String id) async {
    return const WeightDeleteOutcome(
      reopened: WeightReopenedOccurrence(
        careEntryId: 'care-1',
        occurrenceId: 'occ-1',
      ),
    );
  }
}

void main() {
  final standalone = WeightEntry(
    id: 'w1',
    petId: 'pet-1',
    date: DateTime(2026, 1, 1),
    weight: 10,
  );

  final linked = WeightEntry(
    id: 'w2',
    petId: 'pet-1',
    date: DateTime(2026, 2, 1),
    weight: 11,
    fulfils: WeightFulfils(
      entryId: 'care-1',
      entryName: 'Weekly weigh-in',
      occurrenceId: 'occ-1',
      scheduledDate: DateTime(2026, 2, 1),
    ),
  );

  testWidgets('FW-10 standalone delete copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weightEntriesNotifierProvider.overrideWith(_DeleteNotifier.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => confirmDeleteWeightEntry(
                  context,
                  ref,
                  petId: 'pet-1',
                  entry: standalone,
                ),
                child: const Text('delete'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
    expect(find.text('This can\'t be undone.'), findsOneWidget);
  });

  testWidgets('FW-10 linked delete copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weightEntriesNotifierProvider.overrideWith(_DeleteNotifier.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => confirmDeleteWeightEntry(
                      context,
                      ref,
                      petId: 'pet-1',
                      entry: linked,
                    ),
                    child: const Text('delete'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('It counted as Weekly weigh-in'),
      findsOneWidget,
    );
  });
}
