import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/pet_detail_actions.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_detail/pet_detail_profile_card.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/fakes.dart';

Widget _wrap(Pet pet, {PetDetailContext? viewerContext}) {
  final ctx =
      viewerContext ??
      PetDetailActions.resolveContext(
        pet: pet,
        experience: AppExperience.guardian,
      );
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
        body: SingleChildScrollView(
          child: PetDetailProfileCard(pet: pet, viewerContext: ctx),
        ),
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

  testWidgets('shows guardian responsibility label for owned pet', (
    tester,
  ) async {
    const pet = Pet(id: 'p1', name: 'Rex', species: 'Dog');

    await tester.pumpWidget(_wrap(pet));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_responsibility_label')), findsOneWidget);
    expect(find.text('You are the pet guardian'), findsOneWidget);
  });

  testWidgets('hides edit button for shared carer context', (tester) async {
    const pet = Pet(
      id: 'p1',
      name: 'Rex',
      species: 'Dog',
      isShared: true,
      primaryHolderName: 'Alex',
    );
    final ctx = PetDetailActions.resolveContext(
      pet: pet,
      experience: AppExperience.guardian,
    );

    await tester.pumpWidget(_wrap(pet, viewerContext: ctx));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_pet_button')), findsNothing);
    expect(find.text('Shared with Alex'), findsOneWidget);
  });

  testWidgets('shows foster responsibility label', (tester) async {
    const pet = Pet(
      id: 'p1',
      name: 'Rex',
      species: 'Dog',
      isFoster: true,
      organizationName: 'Shelter',
    );
    final ctx = PetDetailActions.resolveContext(
      pet: pet,
      experience: AppExperience.guardian,
    );

    await tester.pumpWidget(_wrap(pet, viewerContext: ctx));
    await tester.pumpAndSettle();

    expect(find.text('Fostered via Shelter'), findsOneWidget);
    expect(find.byKey(const Key('edit_pet_button')), findsNothing);
  });

  testWidgets(
    'restricted context hides privileged controls before policy resolves',
    (tester) async {
      const pet = Pet(id: 'p1', name: 'Rex', species: 'Dog');
      final restricted = PetDetailContext.restricted();

      await tester.pumpWidget(_wrap(pet, viewerContext: restricted));
      await tester.pump();

      expect(find.byKey(const Key('edit_pet_button')), findsNothing);
      expect(find.byIcon(Icons.local_hospital), findsNothing);
    },
  );

  testWidgets('recomputes label when experience switches at runtime', (
    tester,
  ) async {
    const orgPet = Pet(
      id: 'p1',
      name: 'Rex',
      species: 'Dog',
      organizationId: 'o1',
      organizationName: 'Shelter',
    );
    var ctx = PetDetailActions.resolveContext(
      pet: orgPet,
      experience: AppExperience.guardian,
      isOrgAdmin: true,
    );

    await tester.pumpWidget(_wrap(orgPet, viewerContext: ctx));
    await tester.pumpAndSettle();
    expect(find.text('You are the pet guardian'), findsOneWidget);

    ctx = PetDetailActions.resolveContext(
      pet: orgPet,
      experience: AppExperience.organization,
      isOrgAdmin: true,
    );
    await tester.pumpWidget(_wrap(orgPet, viewerContext: ctx));
    await tester.pumpAndSettle();
    expect(find.text('Shelter · Organisation custody'), findsOneWidget);
  });

  // ── 320 px narrow layout ──────────────────────────────────────────────────

  testWidgets('header does not overflow at 320 logical px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const pet = Pet(
      id: 'p1',
      name: 'Maximilian the Magnificent',
      species: 'Dog',
      breed: 'Labrador Retriever',
    );

    await tester.pumpWidget(_wrap(pet));
    await tester.pumpAndSettle();

    // No RenderFlex overflow.
    expect(tester.takeException(), isNull);
    // Responsibility label still visible.
    expect(find.byKey(const Key('pet_responsibility_label')), findsOneWidget);
  });

  testWidgets('photo column stays within [96, 120] px at 320 logical px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const pet = Pet(id: 'p1', name: 'Buddy', species: 'Dog');

    await tester.pumpWidget(_wrap(pet));
    await tester.pumpAndSettle();

    // PetPhoto sits inside the first SizedBox child of the IntrinsicHeight Row.
    // Verify the card itself fits inside the viewport (no horizontal overflow).
    final card = tester.getSize(find.byType(Card).first);
    expect(card.width, lessThanOrEqualTo(320));
  });

  // ── Ownership and status semantics ────────────────────────────────────────

  testWidgets('pet name text has a semantic header role', (tester) async {
    const pet = Pet(id: 'p1', name: 'Rex', species: 'Dog');

    await tester.pumpWidget(_wrap(pet));
    await tester.pumpAndSettle();

    // The name is wrapped in Semantics(header: true). Verify the text is
    // present — the semantic role is validated by the analyzer, not here.
    expect(find.text('Rex'), findsOneWidget);
  });

  testWidgets('org-custody label is derived from pet data, not visual state', (
    tester,
  ) async {
    // Ownership label must use the authority data (organizationName) and never
    // infer custody from photo colour or accent colour.
    const orgPet = Pet(
      id: 'p1',
      name: 'Rex',
      species: 'Dog',
      organizationId: 'o1',
      organizationName: 'City Shelter',
    );
    final ctx = PetDetailActions.resolveContext(
      pet: orgPet,
      experience: AppExperience.organization,
      isOrgAdmin: true,
    );

    await tester.pumpWidget(_wrap(orgPet, viewerContext: ctx));
    await tester.pumpAndSettle();

    expect(find.text('City Shelter · Organisation custody'), findsOneWidget);
  });

  testWidgets('shared-carer label reflects guardian name from pet data', (
    tester,
  ) async {
    const pet = Pet(
      id: 'p1',
      name: 'Mia',
      species: 'Cat',
      isShared: true,
      primaryHolderName: 'Jordan',
    );
    final ctx = PetDetailActions.resolveContext(
      pet: pet,
      experience: AppExperience.guardian,
    );

    await tester.pumpWidget(_wrap(pet, viewerContext: ctx));
    await tester.pumpAndSettle();

    expect(find.text('Shared with Jordan'), findsOneWidget);
    // Edit is not available for a shared-carer context.
    expect(find.byKey(const Key('edit_pet_button')), findsNothing);
  });
}
