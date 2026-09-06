import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/pet_care_bottom_action_bar.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('shows add pet and more actions with share menu item', (
    tester,
  ) async {
    var shareTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PetCareBottomActionBar(
            onAddPet: () {},
            onSharePets: () => shareTapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add_pet_button')), findsOneWidget);
    expect(find.text('Add Pet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pets_more_actions_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share_pets_menu_item')));
    await tester.pumpAndSettle();
    expect(shareTapped, isTrue);
  });
}
