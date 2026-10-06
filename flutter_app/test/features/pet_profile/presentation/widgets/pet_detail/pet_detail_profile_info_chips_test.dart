import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/widgets/pet_detail/pet_detail_profile_info_chips.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

void main() {
  testWidgets('PetDetailProfileInfoChips renders species and weight', (
    tester,
  ) async {
    const pet = Pet(
      id: 'p1',
      name: 'Rex',
      species: 'Dog',
      breed: 'Lab',
      weight: 12,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PetDetailProfileInfoChips(
            pet: pet,
            weightChipLabel: '12.0 kg',
          ),
        ),
      ),
    );

    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Lab'), findsOneWidget);
    expect(find.text('12.0 kg'), findsOneWidget);
  });
}
