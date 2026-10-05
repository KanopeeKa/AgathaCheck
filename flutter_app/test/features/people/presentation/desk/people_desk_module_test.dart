import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/presentation/desk/people_desk_module.dart';

import '../people_test_harness.dart';
import '../hub/people_hub_test_support.dart';

void main() {
  testWidgets('desk shows localized vet role line (B5)', (tester) async {
    final roster = Roster(
      households: const [],
      contacts: [
        ContactSummary(
          id: 'vet-1',
          directory: const ContactDirectoryRef(type: 'personal'),
          kind: ContactKind.person,
          name: 'Desk Vet',
          roles: const [ContactRole.vet],
          group: ContactGroup.professional,
          status: ContactStatus.active,
          legacyVetId: 'legacy-v1',
          pets: const [
            ContactPetLink(
              petId: 'pet-1',
              petName: 'Buddy',
              relationshipKind: RelationshipKind.primaryVet,
              isPrimary: true,
            ),
          ],
        ),
      ],
      pendingInvites: const [],
    );

    await tester.pumpWidget(
      peopleTestApp(
        child: ProviderScope(
          overrides: [
            rosterProvider.overrideWith(() => TestRosterNotifier(roster)),
          ],
          child: const PeopleDeskModule(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vet team'), findsOneWidget);
    expect(find.text('Desk Vet'), findsOneWidget);
    expect(find.text('Vet'), findsWidgets);
  });

  testWidgets('desk ranks vet team by linked pets', (tester) async {
    final roster = Roster(
      households: const [],
      contacts: [
        ContactSummary(
          id: 'low',
          directory: const ContactDirectoryRef(type: 'personal'),
          kind: ContactKind.person,
          name: 'Low Vet',
          roles: const [ContactRole.vet],
          group: ContactGroup.professional,
          status: ContactStatus.active,
        ),
        ContactSummary(
          id: 'high',
          directory: const ContactDirectoryRef(type: 'personal'),
          kind: ContactKind.person,
          name: 'High Vet',
          roles: const [ContactRole.vet],
          group: ContactGroup.professional,
          status: ContactStatus.active,
          pets: const [
            ContactPetLink(
              petId: 'p1',
              petName: 'A',
              relationshipKind: RelationshipKind.primaryVet,
            ),
            ContactPetLink(
              petId: 'p2',
              petName: 'B',
              relationshipKind: RelationshipKind.primaryVet,
            ),
          ],
        ),
      ],
      pendingInvites: const [],
    );

    await tester.pumpWidget(
      peopleTestApp(
        child: ProviderScope(
          overrides: [
            rosterProvider.overrideWith(() => TestRosterNotifier(roster)),
          ],
          child: const PeopleDeskModule(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_care_people_pro_high')), findsOneWidget);
    expect(find.byKey(const Key('pet_care_people_pro_low')), findsOneWidget);
    final highY = tester
        .getTopLeft(find.byKey(const Key('pet_care_people_pro_high')))
        .dy;
    final lowY = tester
        .getTopLeft(find.byKey(const Key('pet_care_people_pro_low')))
        .dy;
    expect(highY, lessThan(lowY));
  });
}
