import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/command_outcome.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_schedule_command_feedback.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('refreshFailed shows non-blocking saved hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showCareScheduleCommandSnackBar(
                  context,
                  outcome: const CommandOutcome(
                    committed: true,
                    refreshFailed: true,
                  ),
                  successMessage: 'Saved',
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(
      find.text("Saved — couldn't refresh. Pull to refresh."),
      findsOneWidget,
    );
  });
}
