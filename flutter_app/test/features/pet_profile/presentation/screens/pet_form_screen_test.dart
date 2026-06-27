import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_form_screen.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _ExistingPetNotifier extends PetListNotifier {
  _ExistingPetNotifier(this.pet);

  final Pet pet;

  @override
  Future<List<Pet>> build() async => [pet];
}

class _VetsNotifier extends VetListNotifier {
  @override
  Future<List<Vet>> build() async => const [
    Vet(
      id: 'vet-1',
      name: 'Dr Smith',
      phone: '01234',
      email: 'vet@example.com',
      address: '1 Vet Road',
    ),
  ];
}

Widget _wrap(Pet pet) {
  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(() => _ExistingPetNotifier(pet)),
      vetListProvider.overrideWith(_VetsNotifier.new),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PetFormScreen(petId: 'pet-1'),
    ),
  );
}

String _fieldText(WidgetTester tester, Key fieldKey) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(fieldKey),
      matching: find.byType(EditableText),
    ),
  );
  return editable.controller.text;
}

void main() {
  testWidgets('prefills existing pet information when editing', (tester) async {
    final pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      breed: 'Collie',
      dateOfBirth: DateTime(2020, 3, 15),
      weight: 12.5,
      gender: 'Female',
      bio: 'Loves long walks',
      insurance: 'PetPlan policy 123',
      neuteredDate: DateTime(2021, 6, 20),
      chipId: 'CHIP-123',
      vetId: 'vet-1',
    );

    await tester.pumpWidget(_wrap(pet));
    await tester.pump();
    await tester.pump();

    expect(_fieldText(tester, const Key('pet_name_field')), 'Bella');
    expect(_fieldText(tester, const Key('pet_breed_field')), 'Collie');
    expect(_fieldText(tester, const Key('pet_weight_field')), '12.5');
    expect(_fieldText(tester, const Key('pet_bio_field')), 'Loves long walks');
    expect(
      _fieldText(tester, const Key('pet_insurance_field')),
      'PetPlan policy 123',
    );
    expect(_fieldText(tester, const Key('pet_chip_id_field')), 'CHIP-123');

    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('15/03/2020'), findsOneWidget);
    expect(find.text('Jun 20, 2021'), findsOneWidget);
    expect(find.text('Dr Smith'), findsOneWidget);
  });
}
