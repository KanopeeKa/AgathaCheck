import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/org_filter_chips.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildWidget({required List<String> orgNames}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context)!;
          return Scaffold(
            body: OrgFilterChips(
              orgNames: orgNames,
              selected: null,
              onSelected: (_) {},
              l: l,
            ),
          );
        },
      ),
    );
  }

  testWidgets('renders localized filter chip labels', (tester) async {
    await tester.pumpWidget(buildWidget(orgNames: ['Shelter A']));
    await tester.pumpAndSettle();

    expect(find.text('All pets'), findsOneWidget);
    expect(find.text('My Pets'), findsOneWidget);
    expect(find.text('Shelter A'), findsOneWidget);
  });
}
