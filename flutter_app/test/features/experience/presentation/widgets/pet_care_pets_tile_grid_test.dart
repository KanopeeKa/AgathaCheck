import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/pet_care_dashboard_section_header.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/pet_care_pets_tile_grid.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/utils/pet_tile_dimensions.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/unified_pet_tile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('PetCarePetsTileGrid', () {
    testWidgets('renders unified tiles in a wrap grid', (tester) async {
      final pets = [
        const Pet(id: '1', name: 'Milo', species: 'Cat'),
        const Pet(id: '2', name: 'Rex', species: 'Dog'),
      ];

      await tester.pumpWidget(
        wrap(
          PetCarePetsTileGrid(pets: pets, careSummary: null, onPetTap: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UnifiedPetTile), findsNWidgets(2));
      expect(find.text('Milo'), findsOneWidget);
      expect(find.text('Rex'), findsOneWidget);
    });

    testWidgets('sorts pets by creation order (oldest first)', (tester) async {
      final pets = [
        Pet(
          id: 'new',
          name: 'Newer',
          species: 'Cat',
          createdAt: DateTime(2024, 6, 1),
        ),
        Pet(
          id: 'old',
          name: 'Older',
          species: 'Dog',
          createdAt: DateTime(2023, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            child: PetCarePetsTileGrid(
              pets: pets,
              careSummary: null,
              onPetTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final names = tester
          .widgetList<UnifiedPetTile>(find.byType(UnifiedPetTile))
          .map((tile) => tile.pet.name)
          .toList();
      expect(names, ['Older', 'Newer']);
    });

    testWidgets('selection mode toggles via onToggleSelection', (tester) async {
      final pets = [const Pet(id: '1', name: 'Milo', species: 'Cat')];
      Pet? toggled;

      await tester.pumpWidget(
        wrap(
          PetCarePetsTileGrid(
            pets: pets,
            careSummary: null,
            selectionMode: true,
            selectedPetIds: const {},
            onToggleSelection: (pet) => toggled = pet,
            onPetTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UnifiedPetTile));
      await tester.pumpAndSettle();

      expect(toggled?.id, '1');
    });
  });

  group('PetCarePetsTileGrid.tileWidthFor', () {
    test('clamps to unified tile dimensions', () {
      final width = PetCarePetsTileGrid.tileWidthFor(400);
      expect(width, lessThanOrEqualTo(PetTileDimensions.maxWidth));
      expect(width, greaterThanOrEqualTo(PetTileDimensions.minWidth));
    });
  });

  group('petCarePetsListCardMinWidth', () {
    test('uses wider minimums than dashboard rail cards', () {
      expect(
        petCarePetsListCardMinWidth(320),
        greaterThan(petCareDashboardPetCardWidth(320)),
      );
    });
  });
}
