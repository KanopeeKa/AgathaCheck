import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agathacheck/features/auth/presentation/screens/my_details_screen.dart';

void main() {
  testWidgets('MyDetailsScreen renders and shows not logged in if user is null', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: MyDetailsScreen())));
    expect(find.textContaining('not logged in', findRichText: true), findsWidgets);
  });
}
