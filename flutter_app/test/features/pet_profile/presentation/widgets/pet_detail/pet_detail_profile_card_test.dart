import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_detail/pet_detail_profile_card.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/fakes.dart';

Widget _wrap(Pet pet) {
  return ProviderScope(
    overrides: [
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
      vetListProvider.overrideWith(FakeVetListNotifier.new),
      latestWeightProvider.overrideWith((ref, arg) => null),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: PetDetailProfileCard(pet: pet)),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the pet name, species chip, and edit button', (
    tester,
  ) async {
    const pet = Pet(id: 'p1', name: 'Rex', species: 'Dog', breed: 'Labrador');

    await tester.pumpWidget(_wrap(pet));
    await tester.pumpAndSettle();

    expect(find.text('Rex'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Labrador'), findsOneWidget);
    expect(find.byKey(const Key('edit_pet_button')), findsOneWidget);
  });

  testWidgets('renders the neutered row when a neuter date is set', (
    tester,
  ) async {
    final pet = Pet(
      id: 'p1',
      name: 'Rex',
      species: 'Dog',
      neuteredDate: DateTime(2024, 1, 15),
    );

    await tester.pumpWidget(_wrap(pet));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
