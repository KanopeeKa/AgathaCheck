import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/org_context_collection_filter.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildWidget({required List<String> orgNames}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PetListOrgCollectionFilterBar(
          orgNames: orgNames,
          showFosteredChoice: true,
          selectedFilter: null,
          onFilterChanged: (_) {},
        ),
      ),
    );
  }

  testWidgets('renders collection filter dimension trigger', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 900));
    await tester.pumpWidget(buildWidget(orgNames: ['Shelter A']));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('filter_dimension_trigger_context')),
      findsOneWidget,
    );
  });
}
