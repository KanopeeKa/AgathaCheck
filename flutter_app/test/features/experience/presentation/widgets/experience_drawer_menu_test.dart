import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/domain/entities/drawer_menu_group.dart';
import 'package:pet_profile_app/features/experience/domain/entities/drawer_menu_item.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_drawer_menu.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  final sampleEntries = [
    const DrawerMenuEntry.item(
      DrawerMenuItem(
        semanticKey: 'drawer_my_pets',
        label: 'Pet Care',
        group: DrawerMenuGroup.petCarePlum,
        route: '/pc/home',
      ),
    ),
    const DrawerMenuEntry.separator(),
    const DrawerMenuEntry.item(
      DrawerMenuItem(
        semanticKey: 'drawer_org_view',
        label: 'Organisation view',
        group: DrawerMenuGroup.organizationGreen,
        route: '/organizations',
      ),
    ),
    const DrawerMenuEntry.separator(),
    const DrawerMenuEntry.item(
      DrawerMenuItem(
        semanticKey: 'drawer_settings',
        label: 'Settings',
        group: DrawerMenuGroup.utility,
        route: '/pc/settings',
      ),
    ),
  ];

  Widget buildApp({bool inDrawer = false}) {
    final menu = ExperienceDrawerMenu(
      entries: sampleEntries,
      onItemTap: (_) {},
    );
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        drawer: inDrawer ? Drawer(child: menu) : null,
        body: inDrawer ? const SizedBox.shrink() : menu,
      ),
    );
  }

  testWidgets('renders menu labels in order', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Pet Care'), findsOneWidget);
    expect(find.text('Organisation view'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('menu rows use semantic keys', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drawer_my_pets')), findsOneWidget);
    expect(find.byKey(const Key('drawer_org_view')), findsOneWidget);
    expect(find.byKey(const Key('drawer_settings')), findsOneWidget);
  });

  testWidgets('invokes onItemTap when row tapped', (tester) async {
    DrawerMenuItem? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExperienceDrawerMenu(
            entries: sampleEntries,
            onItemTap: (item) => tapped = item,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pet Care'));
    expect(tapped?.semanticKey, 'drawer_my_pets');
  });
}
