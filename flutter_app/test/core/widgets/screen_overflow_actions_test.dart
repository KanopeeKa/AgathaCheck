import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/screen_overflow_actions.dart';

void main() {
  testWidgets('single action renders icon button', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScreenOverflowActions(
            actions: [
              ScreenOverflowAction(
                key: const Key('only_action'),
                label: 'Share',
                icon: Icons.share,
                onPressed: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('only_action')), findsOneWidget);
    await tester.tap(find.byKey(const Key('only_action')));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('multiple actions render overflow menu with labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScreenOverflowActions(
            menuKey: const Key('overflow_menu'),
            actions: const [
              ScreenOverflowAction(
                menuItemKey: Key('share_item'),
                label: 'Sharing',
                icon: Icons.people_outline,
                onPressed: _noop,
              ),
              ScreenOverflowAction(
                menuItemKey: Key('export_item'),
                label: 'Download report',
                icon: Icons.picture_as_pdf_outlined,
                onPressed: _noop,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('overflow_menu')), findsOneWidget);
    await tester.tap(find.byKey(const Key('overflow_menu')));
    await tester.pumpAndSettle();
    expect(find.text('Sharing'), findsOneWidget);
    expect(find.text('Download report'), findsOneWidget);
  });
}

void _noop() {}
