import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_detail.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/pet_people.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/presentation/detail/linkable_pets_provider.dart';
import 'package:pet_profile_app/features/people/presentation/detail/person_detail_target.dart';
import 'package:pet_profile_app/features/people/presentation/detail/widgets/link_pet_sheet.dart';

import '../../application/people_providers_test.dart';
import '../hub/people_hub_test_support.dart';
import '../people_test_harness.dart';

class LinkPetSheetFakeRepository extends FakePeopleRepository {
  LinkPetSheetFakeRepository({
    required this.detail,
    this.relationshipsByPet = const {},
  });

  final ContactDetail detail;
  final Map<String, List<PetRelationship>> relationshipsByPet;

  int addLinkCalls = 0;
  int setSlotCalls = 0;
  RelationshipKind? lastSlotKind;
  String? lastLinkPetId;

  @override
  Future<ContactDetail> fetchContactDetail(String id) async => detail;

  @override
  Future<List<PetRelationship>> fetchPetRelationships(String petId) async =>
      relationshipsByPet[petId] ?? const [];

  @override
  Future<void> addContactPetRelationship({
    required String petId,
    required String contactId,
    required RelationshipKind relationshipKind,
  }) async {
    addLinkCalls += 1;
    lastLinkPetId = petId;
  }

  @override
  Future<List<PetRelationship>> setPetRelationshipSlot({
    required String petId,
    required RelationshipKind slotKind,
    required String? contactId,
  }) async {
    setSlotCalls += 1;
    lastSlotKind = slotKind;
    lastLinkPetId = petId;
    return const [];
  }
}

ContactDetail _vetDetail({String id = 'vet-2'}) => ContactDetail(
  id: id,
  directoryId: 'dir-1',
  directory: const ContactDirectoryRef(type: 'personal'),
  kind: ContactKind.organisation,
  name: 'Second Vet Clinic',
  roles: const [ContactRole.vet],
  group: ContactGroup.professional,
  status: ContactStatus.active,
);

Roster _rosterWithVet(String vetId, String name) {
  final base = sampleHubRoster();
  return Roster(
    households: base.households,
    contacts: [
      ...base.contacts,
      ContactSummary(
        id: vetId,
        directory: const ContactDirectoryRef(type: 'personal'),
        kind: ContactKind.organisation,
        name: name,
        roles: const [ContactRole.vet],
        group: ContactGroup.professional,
        status: ContactStatus.active,
      ),
    ],
    pendingInvites: base.pendingInvites,
  );
}

const _threePets = [
  RosterPetOption(petId: 'pet-1', petName: 'Buddy'),
  RosterPetOption(petId: 'pet-2', petName: 'Whiskers'),
  RosterPetOption(petId: 'pet-3', petName: 'Pebble'),
];

class _OpenLinkPetSheet extends ConsumerWidget {
  const _OpenLinkPetSheet({
    required this.contactId,
    this.linkedPets = const [],
  });

  final String contactId;
  final List<ContactPetLink> linkedPets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      key: const Key('open_link_pet_sheet'),
      onPressed: () => showLinkPetSheet(
        context: context,
        ref: ref,
        contactId: contactId,
        linkedPets: linkedPets,
      ),
      child: const Text('Open'),
    );
  }
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open_link_pet_sheet')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('vet contact shows primary and out-of-hours vet chips', (
    tester,
  ) async {
    const vetId = 'vet-2';
    final repo = LinkPetSheetFakeRepository(detail: _vetDetail());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkablePetOptionsProvider.overrideWith((ref) async => _threePets),
          rosterProvider.overrideWith(
            () =>
                TestRosterNotifier(_rosterWithVet(vetId, 'Second Vet Clinic')),
          ),
          peopleRepositoryProvider.overrideWithValue(repo),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(child: const _OpenLinkPetSheet(contactId: vetId)),
      ),
    );
    await _openSheet(tester);

    expect(find.widgetWithText(FilterChip, 'Primary vet'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Out-of-hours vet'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Provides care'), findsOneWidget);
  });

  testWidgets('vet primary vet link calls setPetSlot not add relationship', (
    tester,
  ) async {
    const vetId = 'vet-2';
    final repo = LinkPetSheetFakeRepository(detail: _vetDetail());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkablePetOptionsProvider.overrideWith((ref) async => _threePets),
          rosterProvider.overrideWith(
            () =>
                TestRosterNotifier(_rosterWithVet(vetId, 'Second Vet Clinic')),
          ),
          peopleRepositoryProvider.overrideWithValue(repo),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(child: const _OpenLinkPetSheet(contactId: vetId)),
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Whiskers'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Primary vet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Primary vet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('people_detail_link_pet_confirm')));
    await tester.pumpAndSettle();

    expect(repo.setSlotCalls, 1);
    expect(repo.lastSlotKind, RelationshipKind.primaryVet);
    expect(repo.lastLinkPetId, 'pet-2');
    expect(repo.addLinkCalls, 0);
  });

  testWidgets('pet without primary vet preselects Primary vet', (tester) async {
    const vetId = 'vet-2';
    final repo = LinkPetSheetFakeRepository(detail: _vetDetail());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkablePetOptionsProvider.overrideWith((ref) async => _threePets),
          rosterProvider.overrideWith(
            () =>
                TestRosterNotifier(_rosterWithVet(vetId, 'Second Vet Clinic')),
          ),
          peopleRepositoryProvider.overrideWithValue(repo),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(child: const _OpenLinkPetSheet(contactId: vetId)),
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Whiskers'));
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Primary vet'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('out-of-hours vet calls setPetSlot(outOfHoursVet)', (
    tester,
  ) async {
    const vetId = 'vet-2';
    final repo = LinkPetSheetFakeRepository(detail: _vetDetail());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkablePetOptionsProvider.overrideWith((ref) async => _threePets),
          rosterProvider.overrideWith(
            () =>
                TestRosterNotifier(_rosterWithVet(vetId, 'Second Vet Clinic')),
          ),
          peopleRepositoryProvider.overrideWithValue(repo),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(child: const _OpenLinkPetSheet(contactId: vetId)),
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Whiskers'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Out-of-hours vet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('people_detail_link_pet_confirm')));
    await tester.pumpAndSettle();

    expect(repo.setSlotCalls, 1);
    expect(repo.lastSlotKind, RelationshipKind.outOfHoursVet);
    expect(repo.addLinkCalls, 0);
  });

  testWidgets('replace confirmation cancel skips setPetSlot', (tester) async {
    const vetId = 'vet-2';
    final repo = LinkPetSheetFakeRepository(
      detail: _vetDetail(),
      relationshipsByPet: {
        'pet-2': [
          PetRelationship(
            id: 'r-incumbent',
            petId: 'pet-2',
            contactId: 'vet-happy',
            relationshipKind: RelationshipKind.primaryVet,
            isPrimary: true,
            active: true,
            contactKind: 'organisation',
            contactName: 'Happy Paws',
          ),
        ],
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkablePetOptionsProvider.overrideWith((ref) async => _threePets),
          rosterProvider.overrideWith(
            () =>
                TestRosterNotifier(_rosterWithVet(vetId, 'Second Vet Clinic')),
          ),
          peopleRepositoryProvider.overrideWithValue(repo),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(child: const _OpenLinkPetSheet(contactId: vetId)),
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Whiskers'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Primary vet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('people_detail_link_pet_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Replace vet slot?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repo.setSlotCalls, 0);
    expect(repo.addLinkCalls, 0);
  });

  testWidgets('replace confirmation confirm calls setPetSlot', (tester) async {
    const vetId = 'vet-2';
    final repo = LinkPetSheetFakeRepository(
      detail: _vetDetail(),
      relationshipsByPet: {
        'pet-2': [
          PetRelationship(
            id: 'r-incumbent',
            petId: 'pet-2',
            contactId: 'vet-happy',
            relationshipKind: RelationshipKind.primaryVet,
            isPrimary: true,
            active: true,
            contactKind: 'organisation',
            contactName: 'Happy Paws',
          ),
        ],
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkablePetOptionsProvider.overrideWith((ref) async => _threePets),
          rosterProvider.overrideWith(
            () =>
                TestRosterNotifier(_rosterWithVet(vetId, 'Second Vet Clinic')),
          ),
          peopleRepositoryProvider.overrideWithValue(repo),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(child: const _OpenLinkPetSheet(contactId: vetId)),
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Whiskers'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Primary vet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('people_detail_link_pet_confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(repo.setSlotCalls, 1);
    expect(repo.lastSlotKind, RelationshipKind.primaryVet);
  });

  testWidgets('non-vet contact keeps three relationship chips', (tester) async {
    const carerId = 'carer-1';
    final repo = LinkPetSheetFakeRepository(
      detail: const ContactDetail(
        id: carerId,
        directoryId: 'dir-1',
        directory: ContactDirectoryRef(type: 'personal'),
        kind: ContactKind.person,
        name: 'Jamie Taylor',
        roles: [ContactRole.sitter],
        group: ContactGroup.carer,
        status: ContactStatus.active,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkablePetOptionsProvider.overrideWith((ref) async => _threePets),
          rosterProvider.overrideWith(
            () => TestRosterNotifier(sampleHubRoster()),
          ),
          peopleRepositoryProvider.overrideWithValue(repo),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(
          child: const _OpenLinkPetSheet(contactId: carerId),
        ),
      ),
    );
    await _openSheet(tester);

    expect(find.widgetWithText(FilterChip, 'Primary vet'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Provides care'), findsOneWidget);
    expect(
      find.widgetWithText(FilterChip, 'Emergency contact'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilterChip, 'Other link'), findsOneWidget);
  });

  testWidgets('pet selected without kind disables confirm and shows hint', (
    tester,
  ) async {
    const vetId = 'vet-2';
    final repo = LinkPetSheetFakeRepository(
      detail: _vetDetail(),
      relationshipsByPet: {
        'pet-2': [
          PetRelationship(
            id: 'r-incumbent',
            petId: 'pet-2',
            contactId: 'vet-happy',
            relationshipKind: RelationshipKind.primaryVet,
            isPrimary: true,
            active: true,
            contactKind: 'organisation',
            contactName: 'Happy Paws',
          ),
        ],
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkablePetOptionsProvider.overrideWith((ref) async => _threePets),
          rosterProvider.overrideWith(
            () =>
                TestRosterNotifier(_rosterWithVet(vetId, 'Second Vet Clinic')),
          ),
          peopleRepositoryProvider.overrideWithValue(repo),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(child: const _OpenLinkPetSheet(contactId: vetId)),
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Whiskers'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('people_detail_link_pet_confirm')),
    );
    expect(button.onPressed, isNull);
    expect(find.text("Choose how they're linked to continue."), findsOneWidget);
  });

  testWidgets('lists all owned pets and omits subtitle for unlinked pet', (
    tester,
  ) async {
    const vetId = 'vet-2';
    final repo = LinkPetSheetFakeRepository(detail: _vetDetail());
    const linked = [
      ContactPetLink(
        petId: 'pet-1',
        petName: 'Buddy',
        relationshipKind: RelationshipKind.careProvider,
      ),
      ContactPetLink(
        petId: 'pet-2',
        petName: 'Whiskers',
        relationshipKind: RelationshipKind.primaryVet,
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkablePetOptionsProvider.overrideWith((ref) async => _threePets),
          rosterProvider.overrideWith(
            () =>
                TestRosterNotifier(_rosterWithVet(vetId, 'Second Vet Clinic')),
          ),
          peopleRepositoryProvider.overrideWithValue(repo),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(
          child: const _OpenLinkPetSheet(contactId: vetId, linkedPets: linked),
        ),
      ),
    );
    await _openSheet(tester);

    expect(find.byType(RadioListTile<String>), findsNWidgets(3));
    expect(find.text('Pebble'), findsOneWidget);
    final pebbleTile = tester.widget<RadioListTile<String>>(
      find.widgetWithText(RadioListTile<String>, 'Pebble'),
    );
    expect(pebbleTile.subtitle, isNull);
    expect(find.text('Primary vet'), findsWidgets);
  });
}
