import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_form/pet_form_vet_section.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';

import '../../../people/presentation/people_test_harness.dart';

class _VetRosterNotifier extends RosterNotifier {
  @override
  Future<Roster> build() async => Roster(
    households: const [],
    contacts: [
      ContactSummary(
        id: 'vet-1',
        directory: const ContactDirectoryRef(type: 'personal'),
        kind: ContactKind.organisation,
        name: 'Greenhill',
        roles: const [ContactRole.vet],
        group: ContactGroup.professional,
        status: ContactStatus.active,
      ),
    ],
    pendingInvites: const [],
  );
}

void main() {
  testWidgets('PetFormVetSection exposes people picker semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rosterProvider.overrideWith(_VetRosterNotifier.new)],
        child: peopleTestApp(
          child: Material(
            child: PetFormVetSection(
              selectedPrimaryVetContactId: null,
              onPrimaryVetContactIdChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('people_picker_field_pet_primary_vet'),
      findsOneWidget,
    );
  });
}
