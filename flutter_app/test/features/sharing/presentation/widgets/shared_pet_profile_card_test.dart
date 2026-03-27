import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agathacheck/features/sharing/presentation/widgets/shared_pet_profile_card.dart';

void main() {
  testWidgets('SharedPetProfileCard displays pet info', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SharedPetProfileCard(
        name: 'Buddy',
        species: 'Dog',
        breed: 'Labrador',
        ageDisplay: '2 yrs',
        weight: 20.5,
        vetName: 'Dr. Vet',
        bio: 'Friendly dog',
        photoPath: '',
        colorScheme: ThemeData().colorScheme,
        theme: ThemeData(),
        buildPhoto: (photoPath, colorScheme) => Container(),
        buildChip: (icon, label, colorScheme) => Text(label),
      ),
    ));
    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Labrador'), findsOneWidget);
    expect(find.text('2 yrs'), findsOneWidget);
    expect(find.text('20.5 kg'), findsOneWidget);
    expect(find.text('Dr. Vet'), findsOneWidget);
    expect(find.text('Friendly dog'), findsOneWidget);
  });
}
