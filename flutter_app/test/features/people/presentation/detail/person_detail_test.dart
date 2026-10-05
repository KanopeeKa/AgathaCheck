import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_detail.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/household.dart';
import 'package:pet_profile_app/features/people/domain/entities/household_invite.dart';
import 'package:pet_profile_app/features/people/domain/entities/related_care.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/domain/repositories/people_repository.dart';
import 'package:pet_profile_app/features/people/presentation/detail/person_detail_page.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../hub/people_hub_test_support.dart';
import '../../application/people_providers_test.dart';

class DetailFakePeopleRepository extends FakePeopleRepository {
  DetailFakePeopleRepository(this.details);

  final Map<String, ContactDetail> details;

  @override
  Future<ContactDetail> fetchContactDetail(String id) async {
    final found = details[id];
    if (found != null) return found;
    return ContactDetail(
      id: id,
      directoryId: 'dir-1',
      directory: const ContactDirectoryRef(type: 'personal'),
      kind: ContactKind.person,
      name: 'Unknown',
      roles: const [],
      group: ContactGroup.carer,
      status: ContactStatus.active,
    );
  }

  @override
  Future<RelatedCare> fetchRelatedCare(String id) async =>
      const RelatedCare(pets: [], careItems: [], absences: [], historyCount: 0);
}

class TrackingPeopleRepository extends DetailFakePeopleRepository {
  TrackingPeopleRepository(super.details);

  int linkCalls = 0;
  String? lastPetId;

  @override
  Future<void> addContactPetRelationship({
    required String petId,
    required String contactId,
    required RelationshipKind relationshipKind,
  }) async {
    linkCalls += 1;
    lastPetId = petId;
  }
}

ContactDetail _vetDetail() => const ContactDetail(
  id: 'vet-1',
  directoryId: 'dir-1',
  directory: ContactDirectoryRef(type: 'personal'),
  kind: ContactKind.organisation,
  name: 'Greenhill Vet',
  roles: [ContactRole.vet],
  group: ContactGroup.professional,
  status: ContactStatus.active,
  phone: '555-0100',
  email: 'desk@greenhill.example',
);

Widget _detailApp({required Widget child, required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

List<Override> _baseOverrides(Roster roster, PeopleRepository repo) {
  return [
    rosterProvider.overrideWith(() => TestRosterNotifier(roster)),
    peopleRepositoryProvider.overrideWithValue(repo),
    householdsRepositoryProvider.overrideWithValue(FakeHouseholdsRepository()),
  ];
}

void main() {
  testWidgets('contact detail shows tabs and call action', (tester) async {
    final roster = sampleHubRoster();
    final repo = DetailFakePeopleRepository({'vet-1': _vetDetail()});
    await tester.pumpWidget(
      _detailApp(
        overrides: _baseOverrides(roster, repo),
        child: const PersonDetailPage(personId: 'vet-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Pets & access'), findsOneWidget);
    expect(find.text('Related care'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('555-0100'), findsOneWidget);
  });

  testWidgets('link to a pet calls repository and invalidates detail', (
    tester,
  ) async {
    final roster = sampleHubRoster();
    final repo = TrackingPeopleRepository({
      'carer-1': const ContactDetail(
        id: 'carer-1',
        directoryId: 'dir-1',
        directory: ContactDirectoryRef(type: 'personal'),
        kind: ContactKind.person,
        name: 'Jamie Taylor',
        roles: [ContactRole.sitter],
        group: ContactGroup.carer,
        status: ContactStatus.active,
      ),
    });
    final container = ProviderContainer(
      overrides: _baseOverrides(roster, repo),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PersonDetailPage(personId: 'carer-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pets & access'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('people_detail_link_to_pet')));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(RadioListTile<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Provides care'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('people_detail_link_pet_confirm')));
    await tester.pumpAndSettle();

    expect(repo.linkCalls, 1);
    expect(repo.lastPetId, 'pet-1');
    expect(container.read(personDetailProvider('carer-1')).isLoading, isTrue);
  });

  testWidgets('pending invite variant shows single-page status', (
    tester,
  ) async {
    final roster = sampleHubRoster();
    await tester.pumpWidget(
      _detailApp(
        overrides: _baseOverrides(roster, FakePeopleRepository()),
        child: const PersonDetailPage(personId: 'inv-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('pat@example.com'), findsWidgets);
    expect(find.text('Invited'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
  });

  testWidgets('household member with contact shows pets and notes tabs only', (
    tester,
  ) async {
    final roster = Roster(
      households: [
        Household(
          id: 'hh-1',
          name: 'Morgan',
          myTier: 'full',
          myIsOrganiser: true,
          members: [
            HouseholdMember(
              userId: 'user-2',
              displayName: 'Morgan Lee',
              firstName: 'Morgan',
              tier: 'full',
              isOrganiser: false,
              isYou: false,
              ownsPetIds: ['pet-1'],
              sharesPetIds: const [],
            ),
          ],
        ),
      ],
      contacts: [
        ContactSummary(
          id: 'contact-member',
          directory: const ContactDirectoryRef(
            type: 'household',
            householdId: 'hh-1',
          ),
          kind: ContactKind.person,
          name: 'Morgan Lee',
          roles: const [],
          group: ContactGroup.carer,
          status: ContactStatus.active,
          linkedUserId: 'user-2',
        ),
      ],
      pendingInvites: const [],
    );

    final repo = DetailFakePeopleRepository({
      'contact-member': const ContactDetail(
        id: 'contact-member',
        directoryId: 'dir-hh',
        directory: ContactDirectoryRef(type: 'household', householdId: 'hh-1'),
        kind: ContactKind.person,
        name: 'Morgan Lee',
        roles: [],
        group: ContactGroup.carer,
        status: ContactStatus.active,
      ),
    });
    await tester.pumpWidget(
      _detailApp(
        overrides: _baseOverrides(roster, repo),
        child: const PersonDetailPage(personId: 'user-2'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsNothing);
    expect(find.text('Pets & access'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });
}
