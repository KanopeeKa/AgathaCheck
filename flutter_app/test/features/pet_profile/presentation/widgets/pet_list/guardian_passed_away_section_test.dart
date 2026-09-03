import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_list/guardian_passed_away_section.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/unified_pet_tile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('GuardianPassedAwaySection is collapsed by default', (
    tester,
  ) async {
    final pets = [
      const Pet(
        id: 'memorial',
        name: 'Memorial',
        species: 'Dog',
        passedAway: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l = AppLocalizations.of(context)!;
            return Scaffold(
              body: GuardianPassedAwaySection(
                pets: pets,
                title: l.rainbowBridge,
                careSummary: null,
                onPetTap: (_) {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rainbow bridge'), findsOneWidget);
    expect(find.text('Memorial'), findsNothing);
    expect(find.byType(UnifiedPetTile), findsNothing);

    await tester.tap(find.text('Rainbow bridge'));
    await tester.pumpAndSettle();

    expect(find.text('Memorial'), findsOneWidget);
    expect(find.byType(UnifiedPetTile), findsOneWidget);
  });
}
