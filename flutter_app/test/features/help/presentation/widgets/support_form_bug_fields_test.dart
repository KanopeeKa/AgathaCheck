import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/support/form/domain/support_ticket_category.dart';
import 'package:pet_profile_app/features/support/form/presentation/widgets/support_form_bug_fields.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('bug fields expand without autofocus', (tester) async {
    final expected = TextEditingController();
    final actual = TextEditingController();
    final steps = TextEditingController();
    addTearDown(expected.dispose);
    addTearDown(actual.dispose);
    addTearDown(steps.dispose);

    Future<void> pumpFields({required bool visible}) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SupportFormBugFields(
              visible: visible,
              expectedController: expected,
              actualController: actual,
              stepsController: steps,
              frequency: null,
              onFrequencyChanged: (_) {},
            ),
          ),
        ),
      );
    }

    await pumpFields(visible: false);
    expect(find.byKey(const Key('support_form_bug_fields')), findsNothing);

    await pumpFields(visible: true);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('support_form_bug_fields')), findsOneWidget);
    expect(find.byKey(const Key('support_form_expected')), findsOneWidget);
    expect(find.byKey(const Key('support_form_actual')), findsOneWidget);
    expect(find.byKey(const Key('support_form_steps')), findsOneWidget);
  });
}
