import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';

import 'people_hub_test_support.dart';

void main() {
  testWidgets('RosterList shows carer, professional, and invite sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      peopleHubTestApp(
        router: buildTestPeopleRouter(),
        overrides: [
          rosterProvider.overrideWith(
            () => TestRosterNotifier(sampleHubRoster()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trusted carers'), findsOneWidget);
    expect(find.text('Pet professionals'), findsOneWidget);
    expect(find.text('Pending invites'), findsOneWidget);
    expect(find.textContaining('pat@example.com'), findsOneWidget);
  });

  testWidgets('RosterList search hides non-matching contacts', (tester) async {
    await tester.pumpWidget(
      peopleHubTestApp(
        router: buildTestPeopleRouter(
          initialLocation: '/pc/people?q=greenhill',
        ),
        overrides: [
          rosterProvider.overrideWith(
            () => TestRosterNotifier(sampleHubRoster()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Greenhill Vet'), findsOneWidget);
    expect(find.text('Jamie Taylor'), findsNothing);
  });

  testWidgets('RosterList error state offers retry', (tester) async {
    await tester.pumpWidget(
      peopleHubTestApp(
        router: buildTestPeopleRouter(),
        overrides: [rosterProvider.overrideWith(() => _ErrorRosterNotifier())],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('people_roster_retry')), findsOneWidget);
  });
}

class _ErrorRosterNotifier extends RosterNotifier {
  @override
  Future<Roster> build() async {
    throw StateError('network');
  }
}
