import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/presentation/widgets/care_team_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const vet = Vet(
    id: 'vet-1',
    name: 'Sevetys',
    address: '12 rue Haute, Bergerac',
  );

  const linkedPets = [
    Pet(id: 'pet-1', name: 'Poppy', species: 'Dog', vetId: 'vet-1'),
    Pet(id: 'pet-2', name: 'Dino', species: 'Cat', vetId: 'vet-1'),
    Pet(id: 'pet-3', name: 'Milo', species: 'Dog', vetId: 'vet-1'),
    Pet(id: 'pet-4', name: 'Nova', species: 'Cat', vetId: 'vet-1'),
  ];

  Widget buildCard({
    Vet cardVet = vet,
    List<Pet> pets = linkedPets,
    int? linkedPetCount = 4,
    Locale? locale,
    TextScaler textScaler = TextScaler.noScaling,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      locale: locale,
      theme: AppTheme.lightTheme.copyWith(
        splashFactory: NoSplash.splashFactory,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: CareTeamCard(
            vet: cardVet,
            linkedPets: pets,
            linkedPetCount: linkedPetCount,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows initials, clinic subtitle, caring copy, and chevron', (
    tester,
  ) async {
    await tester.pumpWidget(buildCard());
    await tester.pumpAndSettle();

    expect(find.text('SV'), findsOneWidget);
    expect(find.text('Sevetys'), findsOneWidget);
    expect(find.text('Veterinary clinic · Bergerac'), findsOneWidget);
    expect(find.text('Caring for 4 pets'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('omits pet row while linked count is unresolved', (tester) async {
    await tester.pumpWidget(buildCard(linkedPetCount: null, pets: const []));
    await tester.pumpAndSettle();

    expect(find.text('Sevetys'), findsOneWidget);
    expect(find.textContaining('Caring for'), findsNothing);
    expect(find.textContaining('pet'), findsNothing);
  });

  testWidgets('omits pet row when no pets are linked', (tester) async {
    await tester.pumpWidget(buildCard(linkedPetCount: 0, pets: const []));
    await tester.pumpAndSettle();

    expect(find.text('Sevetys'), findsOneWidget);
    expect(find.textContaining('Caring for'), findsNothing);
  });

  testWidgets('uses localized caring copy', (tester) async {
    await tester.pumpWidget(
      buildCard(linkedPetCount: 1, pets: linkedPets.take(1).toList(), locale: const Locale('fr')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Soigne 1 animal'), findsOneWidget);
    expect(find.text('Clinique vétérinaire · Bergerac'), findsOneWidget);
  });

  testWidgets('keeps long names readable at phone width and 200% scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const longVet = Vet(
      id: 'long-vet',
      name: 'Clinique vétérinaire des animaux de compagnie du quartier nord',
      address: '42 avenue des Tilleuls, 75019 Paris',
    );

    await tester.pumpWidget(
      buildCard(
        cardVet: longVet,
        linkedPetCount: 6,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(longVet.name), findsOneWidget);
    expect(find.text('Veterinary clinic · 75019 Paris'), findsOneWidget);
    expect(find.text('Caring for 6 pets'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes one semantic button and supports tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(buildCard(onTap: () => taps++));
    await tester.pumpAndSettle();

    final semantics = tester.ensureSemantics();
    final card = find.bySemanticsLabel(
      'Sevetys, Veterinary clinic · Bergerac, Caring for 4 pets',
    );
    expect(card, findsOneWidget);
    semantics.dispose();

    await tester.tap(card);
    expect(taps, 1);
  });
}
