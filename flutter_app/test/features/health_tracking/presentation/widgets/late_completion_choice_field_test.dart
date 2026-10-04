import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/late_completion_choice_field.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('D2 offers Keep, Skip and (Fixed schedule) Move; never Ask me', (
    tester,
  ) async {
    String? chosen = 'unset';
    await tester.pumpWidget(
      _wrap(
        LateCompletionChoiceField(value: null, onChanged: (v) => chosen = v),
      ),
    );
    expect(find.text('Keep the next date'), findsOneWidget);
    await tester.tap(find.byKey(const Key('care_item_if_done_late')));
    await tester.pumpAndSettle();
    expect(find.text('Skip the next date'), findsWidgets);
    expect(find.text('Move this and following'), findsWidgets);
    expect(find.textContaining('Ask'), findsNothing);
    await tester.tap(find.text('Skip the next date').last);
    await tester.pumpAndSettle();
    expect(chosen, 'skip_next');
  });

  testWidgets('After it\'s done hides Move this and following', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LateCompletionChoiceField(
          value: null,
          allowShift: false,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('care_item_if_done_late')));
    await tester.pumpAndSettle();
    expect(find.text('Move this and following'), findsNothing);
  });

  test('the choice round-trips on the wire; Keep clears it', () {
    final entry = HealthEntryModel.fromJson({
      'id': 'e',
      'pet_id': 'p',
      'name': 'Pill',
      'type': 'medication',
      'frequency': 'daily',
      'start_date': '2026-06-01',
      'late_completion_choice': 'skip_next',
    });
    expect(entry.lateCompletionChoice, 'skip_next');
    final cleared = HealthEntryModel.fromEntity(
      entry.copyWith(clearLateCompletionChoice: true),
    ).toJson();
    expect(cleared.containsKey('late_completion_choice'), isTrue);
    expect(cleared['late_completion_choice'], isNull);
    expect(entry.frequency, HealthFrequency.daily);
  });
}
