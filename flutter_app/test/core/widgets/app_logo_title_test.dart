import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/app_logo_title.dart';

void main() {
  testWidgets('centers logo and title as one compact block in AppBar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: const SizedBox(width: 132, height: 48),
            actions: const [SizedBox(width: 48, height: 48)],
            title: const AppLogoTitle(title: 'My Pets dashboard'),
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final row = tester.getRect(find.byType(Row).last);
    final logo = tester.getRect(find.byType(Image));
    final text = tester.getRect(find.text('My Pets dashboard'));
    final blockCenter = (logo.left + text.right) / 2;
    final screenCenter = 390 / 2;

    expect(row.width, lessThan(300));
    expect((blockCenter - screenCenter).abs(), lessThan(20));
    expect(logo.left, lessThan(text.left));
  });
}
