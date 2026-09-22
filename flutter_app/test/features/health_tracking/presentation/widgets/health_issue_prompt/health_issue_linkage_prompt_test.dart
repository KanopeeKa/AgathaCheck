import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_issue.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_issue_prompt/health_issue_linkage_prompt.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('unplanned vet prompt is dismissible', (tester) async {
    late VetHealthIssuePromptChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showUnplannedVetHealthIssuePrompt(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text('Was this visit related to a health issue?'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('vet_health_issue_prompt_dismiss')),
    );
    await tester.pumpAndSettle();

    expect(result, VetHealthIssuePromptChoice.dismiss);
  });

  testWidgets('planned completion prompt offers re-plan action', (tester) async {
    late VetHealthIssuePromptChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showPlannedVetCompletionHealthIssuePrompt(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text('Did the vet identify anything new to track?'),
      findsOneWidget,
    );
    expect(find.text('Plan the next visit'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('vet_health_issue_prompt_planNextVisit')),
    );
    await tester.pumpAndSettle();

    expect(result, VetHealthIssuePromptChoice.planNextVisit);
  });

  testWidgets('health issue picker returns selected issue', (tester) async {
    const issues = [
      HealthIssue(id: 'i1', petId: 'p1', title: 'Dental'),
      HealthIssue(id: 'i2', petId: 'p1', title: 'Limping'),
    ];
    late HealthIssue? picked;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                picked = await showHealthIssuePickerSheet(context, issues);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_issue_pick_i2')));
    await tester.pumpAndSettle();

    expect(picked?.id, 'i2');
  });

  testWidgets('add health issue sheet supports neutering quick pick', (
    tester,
  ) async {
    late ({String title, String description})? created;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                created = await showAddHealthIssueFromVetPrompt(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_issue_quick_pick_neutering')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vet_health_issue_save_button')));
    await tester.pumpAndSettle();

    expect(created?.title, 'Neutering / spay');
  });
}
