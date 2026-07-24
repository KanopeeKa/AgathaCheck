import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/theme/experience_colors.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/utils/ownership_accent.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('guardian-owned pet resolves plum accent', (tester) async {
    const pet = Pet(id: 'p1', name: 'Buddy', species: 'Dog', breed: 'Mix');

    late PetOwnershipAccent accent;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            accent = resolvePetOwnershipAccent(
              context,
              pet,
              AppLocalizations.of(context)!,
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(accent.kind, PetOwnershipKind.guardianOwned);
    expect(accent.showsFosterLabel, isFalse);
    expect(
      accent.accentColor,
      AppTheme.lightTheme.extension<ExperienceColors>()!.guardianPrimary,
    );
  });

  testWidgets('org-linked pet resolves green accent and foster label', (
    tester,
  ) async {
    const pet = Pet(
      id: 'p2',
      name: 'Max',
      species: 'Dog',
      breed: 'Lab',
      organizationId: 'org-1',
      fosterPlacementStatus: 'in_progress',
      fosterName: 'Jane',
    );

    late PetOwnershipAccent accent;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            accent = resolvePetOwnershipAccent(
              context,
              pet,
              AppLocalizations.of(context)!,
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(accent.kind, PetOwnershipKind.organizationLinked);
    expect(accent.showsFosterLabel, isTrue);
    expect(accent.fosterLabel, contains('In foster care'));
    expect(
      accent.accentColor,
      AppTheme.lightTheme.extension<ExperienceColors>()!.organizationPrimary,
    );
  });

  testWidgets('isFoster flag shows green foster label', (tester) async {
    const pet = Pet(
      id: 'p3',
      name: 'Luna',
      species: 'Cat',
      breed: '',
      isFoster: true,
    );

    late PetOwnershipAccent accent;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            accent = resolvePetOwnershipAccent(
              context,
              pet,
              AppLocalizations.of(context)!,
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(accent.showsFosterLabel, isTrue);
    expect(accent.fosterLabel, 'In foster care');
  });
}
