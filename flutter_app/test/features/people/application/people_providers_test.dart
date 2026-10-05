import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/application/people_commands.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_detail.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/household.dart';
import 'package:pet_profile_app/features/people/domain/entities/pet_people.dart';
import 'package:pet_profile_app/features/people/domain/entities/related_care.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/domain/repositories/people_repository.dart';
import 'package:pet_profile_app/features/people/application/legacy_people_providers.dart';
import 'package:pet_profile_app/features/people/application/people_commands.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';

class FakePeopleRepository implements PeopleRepository {
  FakePeopleRepository();

  int detailFetchCount = 0;
  final List<String> invalidatedPetIds = [];

  static final _summary = ContactSummary(
    id: 'c1',
    directory: const ContactDirectoryRef(type: 'personal'),
    kind: ContactKind.person,
    name: 'Jamie',
    roles: [ContactRole.sitter],
    group: ContactGroup.carer,
    status: ContactStatus.active,
  );

  static final _detail = ContactDetail(
    id: 'c1',
    directoryId: 'dir-1',
    directory: const ContactDirectoryRef(type: 'personal'),
    kind: ContactKind.person,
    name: 'Jamie',
    roles: [ContactRole.sitter],
    group: ContactGroup.carer,
    status: ContactStatus.active,
  );

  @override
  Future<ContactDetail> createContact(Map<String, dynamic> body) async =>
      _detail;

  @override
  Future<void> deleteContact(String id) async {}

  @override
  Future<ContactDetail> fetchContactDetail(String id) async {
    detailFetchCount += 1;
    return _detail;
  }

  @override
  Future<PetPeople> fetchPetPeople(String petId) async {
    return PetPeople(
      petId: petId,
      petName: 'Buddy',
      scope: 'full',
      owner: const PetPeopleOwner(userId: 'u1', displayName: 'Alex'),
      householdMembers: const [],
      relationships: const [],
    );
  }

  @override
  Future<RelatedCare> fetchRelatedCare(String id) async =>
      const RelatedCare(pets: [], careItems: [], absences: [], historyCount: 0);

  @override
  Future<Roster> fetchRoster({bool includeInactive = false}) async => Roster(
    households: const [],
    contacts: [_summary],
    pendingInvites: const [],
  );

  @override
  Future<List<ContactSummary>> listContactSummaries({
    bool includeInactive = false,
  }) async => [_summary];

  @override
  Future<ContactDetail> patchContact(
    String id,
    Map<String, dynamic> patch,
  ) async => _detail;

  @override
  Future<void> addContactPetRelationship({
    required String petId,
    required String contactId,
    required RelationshipKind relationshipKind,
  }) async {}

  @override
  Future<List<PetRelationship>> fetchPetRelationships(String petId) async =>
      const [];

  @override
  Future<List<PetRelationship>> setPetRelationshipSlot({
    required String petId,
    required RelationshipKind slotKind,
    required String? contactId,
  }) async => const [];

  @override
  Future<List<PetRelationship>> removePetRelationship({
    required String petId,
    required String relationshipId,
  }) async => const [];

  @override
  Future<List<PetRelationship>> replacePetRelationships(
    String petId,
    List<Map<String, dynamic>> relationships,
  ) async => const [];

  @override
  Future<String?> contactIdForLegacyVet(String vetId) async => null;
}

class FakeHouseholdsRepository implements HouseholdsRepository {
  @override
  Future<List<Household>> listHouseholds() async => const [];

  @override
  Future<Household> createHousehold(String name) async => Household(
    id: 'hh-1',
    name: name,
    myTier: 'full_access',
    myIsOrganiser: true,
    members: const [],
  );

  @override
  Future<void> createHouseholdInvite({
    required String householdId,
    required String inviteeEmail,
    required String contactId,
    String accessTier = 'full_access',
  }) async {}

  @override
  Future<void> revokeHouseholdInvite({
    required String householdId,
    required String inviteId,
  }) async {}

  @override
  Future<HouseholdMemberRemovalPreview> fetchMemberRemovalPreview({
    required String householdId,
    required String memberUserId,
  }) async => const HouseholdMemberRemovalPreview(
    remainingAccess: [],
    requiresSuccessor: false,
  );

  @override
  Future<void> removeHouseholdMember({
    required String householdId,
    required String memberUserId,
    bool removeAllAccessToMyPets = false,
    String? successorUserId,
  }) async {}
}

void main() {
  test('personDetailProvider performs a single fetch per open (B1)', () async {
    final fake = FakePeopleRepository();
    final container = ProviderContainer(
      overrides: [
        peopleRepositoryProvider.overrideWithValue(fake),
        householdsRepositoryProvider.overrideWithValue(
          FakeHouseholdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(personDetailProvider('c1'), (_, __) {});
    await container.read(personDetailProvider('c1').future);
    await container.read(personDetailProvider('c1').future);
    sub.close();
    expect(fake.detailFetchCount, 1);
  });

  test(
    'peopleCommands invalidates roster, detail, relatedCare, petPeople',
    () async {
      final fake = FakePeopleRepository();
      final container = ProviderContainer(
        overrides: [
          peopleRepositoryProvider.overrideWithValue(fake),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(rosterProvider.future);
      await container.read(personDetailProvider('c1').future);
      await container.read(relatedCareProvider('c1').future);
      await container.read(petPeopleProvider('p1').future);

      await container
          .read(peopleCommandsProvider)
          .afterPetLinkChange('c1', 'p1');

      expect(container.read(rosterProvider).isRefreshing, isFalse);
      expect(container.read(personDetailProvider('c1')).isLoading, isTrue);
      expect(container.read(relatedCareProvider('c1')).isLoading, isTrue);
      expect(container.read(petPeopleProvider('p1')).isLoading, isTrue);
    },
  );

  test('legacy detail provider does not mutate contacts list', () async {
    final fake = FakePeopleRepository();
    final container = ProviderContainer(
      overrides: [
        peopleRepositoryProvider.overrideWithValue(fake),
        householdsRepositoryProvider.overrideWithValue(
          FakeHouseholdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(peopleContactsProvider.future);
    final before = container.read(peopleContactsProvider).value!;
    await container.read(peopleContactDetailProvider('c1').future);
    final after = container.read(peopleContactsProvider).value!;
    expect(after, before);
  });
}
