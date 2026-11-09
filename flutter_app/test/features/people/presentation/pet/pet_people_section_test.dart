import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/application/people_api_exception.dart';
import 'package:pet_profile_app/features/people/application/people_commands.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/pet_people.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/domain/repositories/people_repository.dart';
import 'package:pet_profile_app/features/people/presentation/pet/pet_emergency_manage_sheet.dart';
import 'package:pet_profile_app/features/people/presentation/pet/pet_people_section.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import '../../../../helpers/fakes.dart';
import '../../application/people_providers_test.dart';
import '../hub/people_hub_test_support.dart';
import '../people_test_harness.dart';

PetPeople _samplePeople({
  String scope = 'full',
  List<PetRelationship> relationships = const [],
}) {
  return PetPeople(
    petId: 'p1',
    petName: 'Buddy',
    scope: scope,
    owner: const PetPeopleOwner(userId: 'u1', displayName: 'Alex'),
    householdMembers: const [
      HouseholdMemberSnapshot(
        userId: 'u1',
        displayName: 'Alex',
        firstName: 'Alex',
        tier: 'full_access',
        isOrganiser: true,
      ),
      HouseholdMemberSnapshot(
        userId: 'u2',
        displayName: 'Sam',
        firstName: 'Sam',
        tier: 'full_access',
        isOrganiser: false,
      ),
    ],
    relationships: relationships,
  );
}

Widget _wrap({
  required PetPeople people,
  required bool canManage,
  FakePeopleRepository? repo,
  Roster? roster,
  PetPeople? Function()? asyncLoader,
}) {
  final repository = repo ?? FakePeopleRepository();
  final rosterData =
      roster ?? const Roster(households: [], contacts: [], pendingInvites: []);
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      peopleRepositoryProvider.overrideWithValue(repository),
      rosterProvider.overrideWith(() => TestRosterNotifier(rosterData)),
      petPeopleProvider.overrideWith((ref, petId) async {
        if (asyncLoader != null) return asyncLoader();
        return people;
      }),
      peopleCommandsProvider.overrideWith((ref) => PeopleCommands(ref)),
    ],
    child: peopleTestApp(
      child: SingleChildScrollView(
        child: PetPeopleSection(
          petId: 'p1',
          petName: 'Buddy',
          canManage: canManage,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('owner sees Manage, vets group, and household At home', (
    tester,
  ) async {
    final people = _samplePeople(
      relationships: [
        PetRelationship(
          id: 'r1',
          petId: 'p1',
          contactId: 'vet1',
          relationshipKind: RelationshipKind.primaryVet,
          isPrimary: true,
          active: true,
          contactKind: 'organisation',
          contactName: 'Greenhill Vet',
          contactPhone: '555-0100',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(people: people, canManage: true));
    await tester.pumpAndSettle();

    expect(find.text('People around Buddy'), findsOneWidget);
    expect(find.text('VETS'), findsOneWidget);
    expect(find.text('AT HOME'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Parent of Buddy'), findsOneWidget);
    expect(find.text('Greenhill Vet'), findsWidgets);
    expect(
      find.byKey(const Key('pet_emergency_manage_button')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('pet_emergency_call_primary_vet'),
      findsOneWidget,
    );
  });

  testWidgets('can log care handover hides Manage but shows owner At home', (
    tester,
  ) async {
    final people = _samplePeople(
      scope: 'handover',
      relationships: [
        PetRelationship(
          id: 'r1',
          petId: 'p1',
          contactId: 'vet1',
          relationshipKind: RelationshipKind.primaryVet,
          isPrimary: true,
          active: true,
          contactKind: 'organisation',
          contactName: 'Greenhill Vet',
          contactPhone: '555-0100',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(people: people, canManage: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_emergency_manage_button')), findsNothing);
    expect(find.text('AT HOME'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Sam'), findsNothing);
    expect(find.text('Greenhill Vet'), findsWidgets);
  });

  testWidgets('call action hidden without phone', (tester) async {
    final people = _samplePeople(
      relationships: [
        PetRelationship(
          id: 'r1',
          petId: 'p1',
          contactId: 'vet1',
          relationshipKind: RelationshipKind.primaryVet,
          isPrimary: true,
          active: true,
          contactKind: 'organisation',
          contactName: 'Greenhill Vet',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(people: people, canManage: false));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('pet_emergency_call_primary_vet'),
      findsNothing,
    );
  });

  testWidgets('loading state renders inside the module', (tester) async {
    final loading = Completer<PetPeople?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          peopleRepositoryProvider.overrideWithValue(FakePeopleRepository()),
          petPeopleProvider.overrideWith((ref, petId) => loading.future),
        ],
        child: peopleTestApp(
          child: const PetPeopleSection(
            petId: 'p1',
            petName: 'Buddy',
            canManage: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state renders inside the module', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          peopleRepositoryProvider.overrideWithValue(FakePeopleRepository()),
          petPeopleProvider.overrideWith((ref, petId) async {
            throw PeopleApiException(
              code: 'server_error',
              statusCode: 500,
              message: 'fail',
            );
          }),
        ],
        child: peopleTestApp(
          child: const PetPeopleSection(
            petId: 'p1',
            petName: 'Buddy',
            canManage: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load contacts. Try again.'), findsOneWidget);
  });

  testWidgets('manage sheet lists out-of-hours vet row', (tester) async {
    final people = _samplePeople(
      relationships: [
        PetRelationship(
          id: 'r-ooh',
          petId: 'p1',
          contactId: 'vet-ooh',
          relationshipKind: RelationshipKind.outOfHoursVet,
          isPrimary: true,
          active: true,
          contactKind: 'organisation',
          contactName: 'Night Vet',
          contactPhone: '555-0200',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(people: people, canManage: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pet_emergency_manage_button')));
    await tester.pumpAndSettle();

    expect(find.byType(PetEmergencyManageSheet), findsOneWidget);
    expect(find.text('Out-of-hours vet'), findsWidgets);
    expect(find.text('Night Vet'), findsWidgets);
  });

  testWidgets('setPetSlot clears out-of-hours vet via commands', (
    tester,
  ) async {
    final tracking = _TrackingPeopleRepository();
    final people = _samplePeople(
      relationships: [
        PetRelationship(
          id: 'r-ooh',
          petId: 'p1',
          contactId: 'vet-ooh',
          relationshipKind: RelationshipKind.outOfHoursVet,
          isPrimary: true,
          active: true,
          contactKind: 'organisation',
          contactName: 'Night Vet',
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(people: people, canManage: true, repo: tracking),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PetPeopleSection)),
    );
    await container
        .read(peopleCommandsProvider)
        .setPetSlot(
          contactId: 'vet-ooh',
          petId: 'p1',
          slotKind: RelationshipKind.outOfHoursVet,
          slotContactId: null,
        );
    expect(tracking.lastSlotKind, RelationshipKind.outOfHoursVet);
    expect(tracking.lastSlotContactId, isNull);
  });

  testWidgets('primary vet picker lists directory vets for an unlinked pet', (
    tester,
  ) async {
    final vetRepo = _DirectoryVetRepository();
  final vetRoster = await vetRepo.fetchRoster();
    await tester.pumpWidget(
      _wrap(
        people: _samplePeople(),
        canManage: true,
        repo: vetRepo,
        roster: vetRoster,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pet_emergency_manage_button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsIdentifier('people_picker_field_pet_slot_primary_vet'),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('people_picker_option_clinic-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('people_picker_option_vet-person-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('people_picker_option_groomer-1')),
      findsNothing,
    );
  });

  testWidgets('emergency contacts show reorder controls in manage sheet', (
    tester,
  ) async {
    final people = _samplePeople(
      relationships: [
        PetRelationship(
          id: 'e1',
          petId: 'p1',
          contactId: 'c1',
          relationshipKind: RelationshipKind.emergencyContact,
          isPrimary: false,
          active: true,
          contactKind: 'person',
          contactName: 'Jamie',
          contactPhone: '555-0300',
        ),
        PetRelationship(
          id: 'e2',
          petId: 'p1',
          contactId: 'c2',
          relationshipKind: RelationshipKind.emergencyContact,
          isPrimary: false,
          active: true,
          contactKind: 'person',
          contactName: 'Ruth',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(people: people, canManage: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pet_emergency_manage_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_emergency_up_e2')), findsOneWidget);
    expect(find.byKey(const Key('pet_emergency_down_e1')), findsOneWidget);
  });
}

class _TrackingPeopleRepository extends FakePeopleRepository {
  RelationshipKind? lastSlotKind;
  String? lastSlotContactId;

  @override
  Future<List<PetRelationship>> setPetRelationshipSlot({
    required String petId,
    required RelationshipKind slotKind,
    required String? contactId,
  }) async {
    lastSlotKind = slotKind;
    lastSlotContactId = contactId;
    return const [];
  }
}

class _DirectoryVetRepository extends FakePeopleRepository {
  static ContactSummary _c(
    String id,
    String name,
    ContactKind kind,
    ContactRole role,
    ContactGroup group,
  ) => ContactSummary(
    id: id,
    directory: const ContactDirectoryRef(type: 'personal'),
    kind: kind,
    name: name,
    roles: [role],
    group: group,
    status: ContactStatus.active,
  );

  @override
  Future<Roster> fetchRoster({bool includeInactive = false}) async => Roster(
    households: const [],
    contacts: [
      _c(
        'clinic-1',
        'Happy Paws',
        ContactKind.organisation,
        ContactRole.vet,
        ContactGroup.professional,
      ),
      _c(
        'vet-person-1',
        'Dr. Mitchell',
        ContactKind.person,
        ContactRole.vet,
        ContactGroup.professional,
      ),
      _c(
        'groomer-1',
        'Fluffy Groom',
        ContactKind.person,
        ContactRole.groomer,
        ContactGroup.professional,
      ),
    ],
    pendingInvites: const [],
  );
}
