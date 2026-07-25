import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/core/widgets/dashboard_section.dart';

void main() {
  testWidgets('renders title, preview, header action, and end link', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSection(
            title: 'My Pets',
            headerAction: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add),
            ),
            previewBuilder: (context) => const Text('Preview A'),
            endLink: DashboardSectionLink(
              label: 'See all',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('My Pets'), findsOneWidget);
    expect(find.text('Preview A'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('supports a second preview shape without end link', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSection(
            title: 'Events',
            previewBuilder: (context) => Column(
              children: const [
                ListTile(title: Text('Row one')),
                ListTile(title: Text('Row two')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Row one'), findsOneWidget);
    expect(find.text('Row two'), findsOneWidget);
    expect(find.text('See all'), findsNothing);
  });
}
