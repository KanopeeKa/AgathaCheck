import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/pet_event_close_confirm_dialog.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('shows Record them first when started dates exist', (tester) async {
    CloseCareDialogResult? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showCloseCareConfirmDialog(
                context,
                startedOpenCount: 2,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Close care?'), findsOneWidget);
    expect(find.byKey(const Key('care_close_record_first_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('care_close_confirm_button')));
    await tester.pumpAndSettle();
    expect(result, CloseCareDialogResult.confirmClose);
  });
}
