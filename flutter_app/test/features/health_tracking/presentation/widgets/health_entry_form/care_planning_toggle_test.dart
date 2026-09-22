import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_planning_mode.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_form/care_planning_toggle.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('renders planned and record segments', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CarePlanningToggle(
            value: CarePlanningMode.planned,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_planning_toggle')), findsOneWidget);
    expect(find.text('Plan this care'), findsOneWidget);
    expect(find.text('Record what happened'), findsOneWidget);
  });

  testWidgets('invokes callback when record segment selected', (
    WidgetTester tester,
  ) async {
    CarePlanningMode? selected;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CarePlanningToggle(
            value: CarePlanningMode.planned,
            onChanged: (mode) => selected = mode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record what happened'));
    await tester.pumpAndSettle();

    expect(selected, CarePlanningMode.unplanned);
  });
}
