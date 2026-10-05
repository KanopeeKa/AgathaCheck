import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_provider_field.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';

import '../../../people/presentation/people_test_harness.dart';

class _EmptyRosterNotifier extends RosterNotifier {
  @override
  Future<Roster> build() async =>
      const Roster(households: [], contacts: [], pendingInvites: []);
}

void main() {
  testWidgets('CareProviderField exposes care provider picker', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rosterProvider.overrideWith(_EmptyRosterNotifier.new)],
        child: peopleTestApp(
          child: Material(
            child: CareProviderField(onChanged: ({contactId, typedName}) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('people_picker_field_care_provider'),
      findsOneWidget,
    );
  });
}
