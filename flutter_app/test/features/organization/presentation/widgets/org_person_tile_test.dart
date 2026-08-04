import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_screen_theme.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_person_tile.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_person_tile_grid.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: orgThemed(child: Scaffold(body: child)),
      ),
    );
  }

  testWidgets('org person tile shows role bar, name, and phone', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 200,
          height: 200,
          child: OrgPersonTile(
            recordId: 'ou-1',
            displayName: 'Grace Admin',
            initials: 'GA',
            role: OrgMemberRole.admin,
            phone: '555-0200',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grace Admin'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('555-0200'), findsOneWidget);
    expect(find.byKey(const Key('org_person_tile_ou-1')), findsOneWidget);
  });

  testWidgets('org person tile hides phone when not provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 200,
          height: 200,
          child: OrgPersonTile(
            recordId: 'ou-2',
            displayName: 'Bob Admin',
            initials: 'BA',
            role: OrgMemberRole.superAdmin,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Super admin'), findsOneWidget);
    expect(find.textContaining('555'), findsNothing);
  });

  testWidgets('tapping org person tile invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 200,
          height: 200,
          child: OrgPersonTile(
            recordId: 'ou-nav',
            displayName: 'Nav Person',
            initials: 'NP',
            role: OrgMemberRole.admin,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('org_person_tile_ou-nav')));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('org person tile grid uses pet tile sizing', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 400,
          child: OrgPersonTileGrid(
            tiles: [
              OrgPersonTile(
                recordId: 'a',
                displayName: 'Alice',
                initials: 'A',
                role: OrgMemberRole.admin,
              ),
              OrgPersonTile(
                recordId: 'b',
                displayName: 'Bob',
                initials: 'B',
                role: OrgMemberRole.foster,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
    final gridTile = sizedBoxes.firstWhere(
      (box) => box.child is OrgPersonTile,
      orElse: () => throw StateError('grid tile not found'),
    );
    expect(
      gridTile.width,
      closeTo((400 - 2 * PetCard.tileSpacing) / 3, 0.01),
    );
    expect(gridTile.height, gridTile.width);
  });

  testWidgets('role bar colours follow D-v3-TILE-2 mapping', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 200,
          height: 200,
          child: OrgPersonTile(
            recordId: 'super',
            displayName: 'Super',
            initials: 'S',
            role: OrgMemberRole.superAdmin,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final barFinder = find.byKey(const Key('org_person_role_bar_Super admin'));
    expect(barFinder, findsOneWidget);
    final bar = tester.widget<Container>(barFinder);
    final decoration = bar.decoration! as BoxDecoration;
    expect(decoration.color, Colors.black);
  });
}
