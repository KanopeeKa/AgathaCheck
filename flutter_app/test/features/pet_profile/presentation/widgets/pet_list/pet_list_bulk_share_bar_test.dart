import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_list/pet_list_bulk_share_bar.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Future<void> _pumpBar(
  WidgetTester tester, {
  required bool bulkShareMode,
  required VoidCallback onToggle,
  required VoidCallback onAction,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => PetListBulkShareBar(
            bulkShareMode: bulkShareMode,
            l: AppLocalizations.of(context)!,
            onToggle: onToggle,
            onAction: onAction,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the inactive bulk-share state and toggles it', (
    tester,
  ) async {
    var toggleCount = 0;

    await _pumpBar(
      tester,
      bulkShareMode: false,
      onToggle: () => toggleCount += 1,
      onAction: () {},
    );

    expect(find.text('All pets'), findsOneWidget);
    expect(find.text('Bulk share'), findsOneWidget);
    expect(find.byKey(const Key('bulk_share_action')), findsNothing);

    await tester.tap(find.byKey(const Key('bulk_share_toggle')));

    expect(toggleCount, 1);
  });

  testWidgets('shows the active actions and invokes both callbacks', (
    tester,
  ) async {
    var toggleCount = 0;
    var actionCount = 0;

    await _pumpBar(
      tester,
      bulkShareMode: true,
      onToggle: () => toggleCount += 1,
      onAction: () => actionCount += 1,
    );

    expect(find.text('Select pets to share'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Share selected'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bulk_share_action')));
    await tester.tap(find.byKey(const Key('bulk_share_toggle')));

    expect(actionCount, 1);
    expect(toggleCount, 1);
  });
}
