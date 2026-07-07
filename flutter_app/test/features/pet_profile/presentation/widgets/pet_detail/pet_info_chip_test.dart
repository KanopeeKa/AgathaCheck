import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_detail/pet_info_chip.dart';

void main() {
  testWidgets('PetInfoChip renders its icon and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PetInfoChip(icon: Icons.pets, label: 'Labrador'),
        ),
      ),
    );

    expect(find.text('Labrador'), findsOneWidget);
    expect(find.byIcon(Icons.pets), findsOneWidget);
  });

  testWidgets('PetInfoChipWidget renders its custom icon widget and label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PetInfoChipWidget(
            iconWidget: Icon(Icons.star, key: Key('custom_icon')),
            label: 'Dog',
          ),
        ),
      ),
    );

    expect(find.text('Dog'), findsOneWidget);
    expect(find.byKey(const Key('custom_icon')), findsOneWidget);
  });
}
