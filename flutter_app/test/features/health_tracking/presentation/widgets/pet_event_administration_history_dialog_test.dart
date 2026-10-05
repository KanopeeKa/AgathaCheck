import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/pet_event_administration_history_dialog.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('FW-19 history dialog shows weight for completed weigh-in rows', (
    tester,
  ) async {
    final history = [
      HealthHistoryEntry(
        id: 'h1',
        entryId: 'entry-1',
        markedAt: DateTime(2026, 3, 1, 10),
        dueDate: DateTime(2026, 3, 1),
        completedOn: DateTime(2026, 3, 1),
        linkedWeight: const HealthHistoryLinkedWeight(valueKg: 12.4),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weightUnitPreferenceProvider.overrideWith((ref) => WeightUnit.kg),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showPetEventAdministrationHistoryDialog(
                  context,
                  history: history,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('12.4 kg'), findsOneWidget);
    expect(find.byKey(const Key('history_row_linked_weight_h1')), findsOneWidget);
  });
}
