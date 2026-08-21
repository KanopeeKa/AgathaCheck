import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_dashboard_helpers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_dashboard_pet_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildCard(
    Pet pet, {
    GuardianTodayPetCareState careState = GuardianTodayPetCareState.clear,
    VoidCallback? onTap,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 160,
            child: GuardianDashboardPetCard(
              pet: pet,
              careState: careState,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses compact photo-led proportions and a concise care line', (
    tester,
  ) async {
    const pet = Pet(id: 'miso', name: 'Miso', species: 'Cat');
    await tester.pumpWidget(
      buildCard(pet, careState: GuardianTodayPetCareState.dueToday),
    );

    expect(
      tester.getSize(
        find.byKey(const Key('guardian_dashboard_pet_photo_miso')),
      ),
      const Size(160, 104),
    );
    expect(find.text('Due today'), findsOneWidget);
    expect(find.bySemanticsLabel('Miso, My Pets, Due today'), findsOneWidget);
  });

  testWidgets('keeps foster and shared context in visible and semantic text', (
    tester,
  ) async {
    const foster = Pet(
      id: 'foster',
      name: 'Luna',
      species: 'Dog',
      isFoster: true,
    );
    await tester.pumpWidget(
      buildCard(foster, careState: GuardianTodayPetCareState.upcoming),
    );

    expect(find.text('My Fostered Pets'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Luna, My Fostered Pets, Care coming up'),
      findsOneWidget,
    );
  });

  testWidgets('keeps a long name available in semantics when it truncates', (
    tester,
  ) async {
    const longName = 'Sir Whiskers the Exceptionally Long-Named Cat';
    const pet = Pet(id: 'long', name: longName, species: 'Cat', isShared: true);
    await tester.pumpWidget(buildCard(pet));

    final text = tester.widget<Text>(find.text(longName));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(
      find.bySemanticsLabel('$longName, Shared Pets, All clear'),
      findsOneWidget,
    );
    final node = tester.getSemantics(
      find.byKey(const Key('guardian_dashboard_pet_card_long')),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    await tester.pumpWidget(buildCard(pet, textScaler: TextScaler.linear(2)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a species placeholder for missing and malformed photos', (
    tester,
  ) async {
    const missing = Pet(id: 'missing', name: 'Missing', species: 'Dog');
    await tester.pumpWidget(buildCard(missing));
    expect(find.byType(Icon), findsOneWidget);

    const malformed = Pet(
      id: 'malformed',
      name: 'Malformed',
      species: 'Dog',
      photoPath: 'not-base64',
    );
    await tester.pumpWidget(buildCard(malformed));
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('keeps base64, local assets, and passed-away treatment supported', (
    tester,
  ) async {
    const base64Pet = Pet(
      id: 'memory',
      name: 'Memory',
      species: 'Dog',
      photoPath:
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL5aQAAAABJRU5ErkJggg==',
    );
    await tester.pumpWidget(buildCard(base64Pet));
    expect(tester.widget<Image>(find.byType(Image)).image, isA<MemoryImage>());

    const assetPet = Pet(
      id: 'asset',
      name: 'Asset',
      species: 'Dog',
      photoPath: 'asset://assets/rainbow_wings.png',
    );
    await tester.pumpWidget(buildCard(assetPet));
    expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());

    const memorial = Pet(
      id: 'memorial',
      name: 'Memorial',
      species: 'Dog',
      passedAway: true,
    );
    await tester.pumpWidget(buildCard(memorial));
    expect(find.byType(ColorFiltered), findsOneWidget);
  });

  testWidgets('preserves the pet-detail tap callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      buildCard(
        const Pet(id: 'tap', name: 'Tap', species: 'Dog'),
        onTap: () => taps++,
      ),
    );

    tester.widget<InkWell>(find.byType(InkWell)).onTap!();
    expect(taps, 1);
  });
}
