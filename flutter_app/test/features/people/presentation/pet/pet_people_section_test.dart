import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/application/people_commands.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/pet_people.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/domain/repositories/people_repository.dart';
import 'package:pet_profile_app/features/people/presentation/pet/pet_emergency_manage_sheet.dart';
import 'package:pet_profile_app/features/people/presentation/pet/pet_people_section.dart';
import '../../application/people_providers_test.dart';
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
}) {
  final repository = repo ?? FakePeopleRepository();
  return ProviderScope(
    overrides: [
      peopleRepositoryProvider.overrideWithValue(repository),
      petPeopleProvider.overrideWith((ref, petId) async => people),
      peopleCommandsProvider.overrideWith(
        (ref) => PeopleCommands(ref),
      ),
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
  testWidgets('owner sees Manage and household At home group', (tester) async {
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
    expect(find.text("Buddy · Alex's pet"), findsOneWidget);
    expect(find.text('At home'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Greenhill Vet'), findsWidgets);
    expect(find.byKey(const Key('pet_emergency_manage_button')), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('pet_emergency_call_primary_vet'),
      findsOneWidget,
    );
  });

  testWidgets('can log care handover hides Manage and At home', (tester) async {
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
    expect(find.text('At home'), findsNothing);
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

  testWidgets('setPetSlot clears out-of-hours vet via commands', (tester) async {
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

    await tester.pumpWidget(_wrap(people: people, canManage: true, repo: tracking));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PetPeopleSection)),
    );
    await container.read(peopleCommandsProvider).setPetSlot(
      contactId: 'vet-ooh',
      petId: 'p1',
      slotKind: RelationshipKind.outOfHoursVet,
      slotContactId: null,
    );
    expect(tracking.lastSlotKind, RelationshipKind.outOfHoursVet);
    expect(tracking.lastSlotContactId, isNull);
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
