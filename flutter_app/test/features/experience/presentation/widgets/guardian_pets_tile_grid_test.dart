import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_dashboard_pet_card.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_dashboard_section_header.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_pets_tile_grid.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
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

  group('GuardianPetsTileGrid', () {
    testWidgets('renders dashboard cards in a wrap grid', (tester) async {
      final pets = [
        const Pet(id: '1', name: 'Milo', species: 'Cat'),
        const Pet(id: '2', name: 'Rex', species: 'Dog'),
      ];

      await tester.pumpWidget(
        wrap(
          GuardianPetsTileGrid(pets: pets, careSummary: null, onPetTap: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GuardianDashboardPetCard), findsNWidgets(2));
      expect(find.text('Milo'), findsOneWidget);
      expect(find.text('Rex'), findsOneWidget);
    });
  });

  group('guardianPetsListCardMinWidth', () {
    test('uses wider minimums than dashboard rail cards', () {
      expect(
        guardianPetsListCardMinWidth(320),
        greaterThan(guardianDashboardPetCardWidth(320)),
      );
    });
  });
}
