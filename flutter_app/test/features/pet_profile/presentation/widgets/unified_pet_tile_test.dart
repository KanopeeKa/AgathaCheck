import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/utils/pet_tile_dimensions.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_tile_status_line.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/unified_pet_tile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const pet = Pet(
    id: 'pet-1',
    name: 'Buddy',
    species: 'Dog',
    colorValue: 0xFF7E57C2,
  );

  Widget wrap(Widget child, {double width = 160}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  testWidgets('renders name and care status line', (tester) async {
    await tester.pumpWidget(
      wrap(
        UnifiedPetTile(
          pet: pet,
          onTap: () {},
          statusLine: const PetTileStatusLineData(
            label: 'All clear',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            showCareStyling: true,
          ),
        ),
      ),
    );

    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('All clear'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('uses target height near 140px at default text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        UnifiedPetTile(
          pet: pet,
          onTap: () {},
          height: PetTileDimensions.baseHeight,
          width: 148,
        ),
        width: 148,
      ),
    );

    final box = tester.getSize(find.byType(UnifiedPetTile));
    expect(box.height, PetTileDimensions.baseHeight);
    expect(box.width, 148);
  });

  testWidgets('shows wings overlay for passed-away pets', (tester) async {
    const passed = Pet(
      id: 'pet-pa',
      name: 'Star',
      species: 'Cat',
      passedAway: true,
    );

    await tester.pumpWidget(
      wrap(
        UnifiedPetTile(
          pet: passed,
          onTap: () {},
          statusLine: const PetTileStatusLineData(label: 'Passed Away'),
        ),
      ),
    );

    expect(find.byType(Image), findsWidgets);
    expect(find.text('Star'), findsOneWidget);
    expect(find.text('Passed Away'), findsOneWidget);
  });

  testWidgets('ownership stripe is present', (tester) async {
    await tester.pumpWidget(wrap(UnifiedPetTile(pet: pet, onTap: () {})));

    expect(find.byType(ColoredBox), findsWidgets);
  });
}
