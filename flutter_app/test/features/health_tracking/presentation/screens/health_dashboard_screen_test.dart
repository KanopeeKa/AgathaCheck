import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_dashboard_screen.dart';

void main() {
  testWidgets('HealthDashboardScreen renders tab bar', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HealthDashboardScreen())));
    expect(find.byType(TabBar), findsOneWidget);
  });
}
