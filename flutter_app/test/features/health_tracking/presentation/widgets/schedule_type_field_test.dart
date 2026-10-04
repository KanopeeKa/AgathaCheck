import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/recurrence_anchor.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_form/schedule_type_field.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('F35 schedule type uses Schedule type title and segment labels', (
    tester,
  ) async {
    RecurrenceAnchor? chosen;
    await tester.pumpWidget(
      _wrap(
        ScheduleTypeField(
          value: RecurrenceAnchor.fromCompletion,
          onChanged: (v) => chosen = v,
        ),
      ),
    );
    expect(find.text('Schedule type'), findsOneWidget);
    expect(find.text('Next due date'), findsNothing);
    expect(find.text("After it's done"), findsOneWidget);
    expect(find.text('Fixed schedule'), findsOneWidget);
    await tester.tap(find.text('Fixed schedule'));
    await tester.pumpAndSettle();
    expect(chosen, RecurrenceAnchor.fromDueDate);
  });

  testWidgets('info body uses Overdue wording not 1 day late', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ScheduleTypeField(
          value: RecurrenceAnchor.fromCompletion,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('care_schedule_type_info')));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 day late'), findsNothing);
    expect(find.textContaining('Overdue'), findsOneWidget);
  });
}
