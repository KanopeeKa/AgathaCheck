import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/app_undo_snackbar.dart';

void main() {
  testWidgets(
    'showUndoSnackBar uses bounded duration, close icon, persist false',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showUndoSnackBar(
                      content: const Text('Marked done'),
                      undoLabel: 'Undo',
                      onUndo: () {},
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, kUndoSnackBarDuration);
      expect(snackBar.persist, isFalse);
      expect(snackBar.showCloseIcon, isTrue);
      expect(snackBar.action!.label, 'Undo');
      expect(find.byIcon(Icons.close), findsOneWidget);
    },
  );

  testWidgets('showUndoSnackBar auto-dismisses after duration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showUndoSnackBar(
                    content: const Text('Marked done'),
                    undoLabel: 'Undo',
                    onUndo: () {},
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Marked done'), findsOneWidget);

    await tester.pump(kUndoSnackBarDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Marked done'), findsNothing);
  });
}
