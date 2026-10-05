import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/pet_care_illustrated_empty_state.dart';

void main() {
  testWidgets('shows title, body, and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetCareIllustratedEmptyState(
            title: 'No pets yet',
            body: 'Add a pet to get started.',
            actionLabel: 'Add pet',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(find.text('No pets yet'), findsOneWidget);
    expect(find.text('Add a pet to get started.'), findsOneWidget);
    expect(find.text('Add pet'), findsOneWidget);
  });
}
