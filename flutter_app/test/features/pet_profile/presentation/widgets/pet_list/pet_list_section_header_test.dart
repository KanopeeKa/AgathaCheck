import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_list/pet_list_section_header.dart';

void main() {
  group('PetListSectionHeader', () {
    testWidgets('shows title and count badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PetListSectionHeader(
              icon: Icons.pets,
              title: 'My Pets',
              count: 3,
            ),
          ),
        ),
      );

      expect(find.text('My Pets'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('shows zero count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PetListSectionHeader(
              icon: Icons.person,
              title: 'Empty',
              count: 0,
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });
  });
}
