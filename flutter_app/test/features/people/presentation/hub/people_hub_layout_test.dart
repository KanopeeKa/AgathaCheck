import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';

import 'people_hub_test_support.dart';

void main() {
  testWidgets('wide hub keeps search query when selecting a person (B4)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = buildTestPeopleRouter(initialLocation: '/pc/people?q=jam');
    await tester.pumpWidget(
      peopleHubTestApp(
        router: router,
        overrides: [
          rosterProvider.overrideWith(
            () => TestRosterNotifier(sampleHubRoster()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('people_hub_detail_placeholder')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('people_list_search')), findsOneWidget);

    await tester.tap(find.text('Jamie Taylor'));
    await tester.pumpAndSettle();

    expect(router.state.uri.queryParameters['q'], 'jam');
    expect(
      find.byKey(const Key('people_hub_detail_placeholder')),
      findsNothing,
    );
    expect(find.byKey(const Key('people_list_search')), findsOneWidget);
  });
}
