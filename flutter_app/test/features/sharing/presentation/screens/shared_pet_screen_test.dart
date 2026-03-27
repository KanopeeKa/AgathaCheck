import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agathacheck/features/sharing/presentation/screens/shared_pet_screen.dart';

void main() {
  testWidgets('SharedPetScreen renders loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SharedPetScreen(shareCode: 'abc'))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
