import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_adaptive_nav_title.dart';

void main() {
  ThemeData themeWithTitleMedium() {
    return ThemeData(
      textTheme: const TextTheme(titleMedium: TextStyle(fontSize: 16)),
    );
  }

  Future<void> pumpTitle(
    WidgetTester tester, {
    required String title,
    required double maxWidth,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: themeWithTitleMedium(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: maxWidth,
              child: OrgAdaptiveNavTitle(title: title),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextStyle? titleStyle(WidgetTester tester) {
    final text = tester.widget<Text>(find.byType(Text));
    return text.style;
  }

  testWidgets('uses titleMedium size for short single-line titles', (
    tester,
  ) async {
    await pumpTitle(tester, title: 'Pets', maxWidth: 240);

    expect(titleStyle(tester)?.fontSize, 16);
    expect(find.text('Pets'), findsOneWidget);
  });

  testWidgets('wraps long titles up to two lines before scaling', (
    tester,
  ) async {
    await pumpTitle(
      tester,
      title: 'Northamptonshire Animal Rescue and Rehoming Centre',
      maxWidth: 180,
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect((text.style?.fontSize ?? 16), lessThanOrEqualTo(16));
    expect((text.style?.fontSize ?? 16), greaterThanOrEqualTo(12));
  });

  testWidgets('scales down to at least 12sp for very long titles', (
    tester,
  ) async {
    await pumpTitle(
      tester,
      title:
          'International Association of Very Long Organisation Names That Must Shrink',
      maxWidth: 120,
    );

    final fontSize = titleStyle(tester)?.fontSize ?? 16;
    expect(fontSize, greaterThanOrEqualTo(12));
    expect(fontSize, lessThan(16));
  });

  testWidgets('ellipsizes when text still overflows at minimum size', (
    tester,
  ) async {
    await pumpTitle(
      tester,
      title:
          'Supercalifragilisticexpialidocious Rescue Organisation of Greater Metropolitan Springfield',
      maxWidth: 80,
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.maxLines, 2);
    expect(titleStyle(tester)?.fontSize, 12);
  });
}
