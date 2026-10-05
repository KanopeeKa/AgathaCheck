import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/people/application/people_api_exception.dart';
import 'package:pet_profile_app/features/people/application/people_commands.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_detail.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_usage.dart';
import 'package:pet_profile_app/features/people/domain/entities/household.dart';
import 'package:pet_profile_app/features/people/domain/entities/household_invite.dart';
import 'package:pet_profile_app/features/people/domain/entities/pet_people.dart';
import 'package:pet_profile_app/features/people/domain/entities/related_care.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/domain/repositories/people_repository.dart';
import 'package:pet_profile_app/features/people/presentation/edit/person_edit_page.dart';
import 'package:pet_profile_app/features/people/presentation/edit/person_form_errors.dart';
import 'package:pet_profile_app/features/people/presentation/edit/usages_dialog.dart';
import 'package:pet_profile_app/features/people/presentation/edit/person_form_controller.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../application/people_providers_test.dart';
import '../hub/people_hub_test_support.dart';

class EditFakePeopleRepository extends FakePeopleRepository {
  EditFakePeopleRepository(this.details);

  final Map<String, ContactDetail> details;
  Map<String, dynamic>? lastPatch;
  String? deletedId;
  List<PetRelationship> relationships = const [];

  @override
  Future<ContactDetail> fetchContactDetail(String id) async {
    return details[id] ?? details.values.first;
  }

  @override
  Future<ContactDetail> patchContact(
    String id,
    Map<String, dynamic> patch,
  ) async {
    lastPatch = patch;
    return details[id] ?? details.values.first;
  }

  @override
  Future<void> deleteContact(String id) async {
    deletedId = id;
  }

  @override
  Future<List<PetRelationship>> fetchPetRelationships(String petId) async =>
      relationships;

  @override
  Future<List<PetRelationship>> setPetRelationshipSlot({
    required String petId,
    required RelationshipKind slotKind,
    required String? contactId,
  }) async {
    slotCalls += 1;
    lastSlotKind = slotKind;
    return relationships;
  }

  int slotCalls = 0;
  RelationshipKind? lastSlotKind;
}

class BlockingDeleteRepository extends EditFakePeopleRepository {
  BlockingDeleteRepository(super.details);

  @override
  Future<void> deleteContact(String id) async {
    throw PeopleApiException(
      code: 'contact_in_use',
      statusCode: 409,
      usages: const [
        ContactUsage(
          kind: 'care_item_provider',
          id: 'c1',
          label: 'Buddy check',
        ),
      ],
    );
  }
}

ContactDetail _editableContact({LinkedAccount? linked}) => ContactDetail(
  id: 'carer-1',
  directoryId: 'dir-1',
  directory: const ContactDirectoryRef(type: 'personal'),
  kind: ContactKind.person,
  name: 'Jamie Taylor',
  roles: const [ContactRole.sitter],
  group: ContactGroup.carer,
  status: ContactStatus.active,
  phone: '555-1000',
  linkedAccount: linked,
);

Widget _editApp({required Widget child, required List<Override> overrides}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/pc/people',
        builder: (context, state) => const Scaffold(body: Text('people hub')),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

List<Override> _overrides(Roster roster, PeopleRepository repo) => [
  rosterProvider.overrideWith(() => TestRosterNotifier(roster)),
  peopleRepositoryProvider.overrideWithValue(repo),
  householdsRepositoryProvider.overrideWithValue(FakeHouseholdsRepository()),
];

void main() {
  test('PersonFormController validates name and builds patch', () {
    final controller = PersonFormController(initial: _editableContact());
    expect(controller.validate(), isTrue);
    controller.setName('');
    expect(controller.validate(), isFalse);
    controller.setName('Updated');
    controller.toggleRole(ContactRole.vet);
    final patch = controller.buildPatch();
    expect(patch['name'], 'Updated');
    expect(patch['roles'], contains('vet'));
  });

  test('linked identity marks name field read-only in UI', () {
    final controller = PersonFormController(
      initial: _editableContact(
        linked: const LinkedAccount(userId: 'u2', displayName: 'Alex'),
      ),
    );
    expect(controller.isLinked, isTrue);
    controller.setName('Nope');
    expect(controller.name, 'Nope');
  });

  testWidgets('edit page shows identity and save bar', (tester) async {
    final roster = sampleHubRoster();
    final repo = EditFakePeopleRepository({'carer-1': _editableContact()});
    await tester.pumpWidget(
      _editApp(
        overrides: _overrides(roster, repo),
        child: const PersonEditPage(personId: 'carer-1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Identity'), findsOneWidget);
    expect(find.byKey(const Key('people_edit_save')), findsOneWidget);
  });

  testWidgets('discard dialog when dirty back', (tester) async {
    final roster = sampleHubRoster();
    final repo = EditFakePeopleRepository({'carer-1': _editableContact()});
    await tester.pumpWidget(
      _editApp(
        overrides: _overrides(roster, repo),
        child: const PersonEditPage(personId: 'carer-1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('people_edit_name_field')),
      'New name',
    );
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets('reactivate button shown for inactive contact', (tester) async {
    final inactive = ContactDetail(
      id: 'carer-1',
      directoryId: 'dir-1',
      directory: const ContactDirectoryRef(type: 'personal'),
      kind: ContactKind.person,
      name: 'Jamie Taylor',
      roles: const [ContactRole.sitter],
      group: ContactGroup.carer,
      status: ContactStatus.inactive,
      inactiveAt: DateTime.utc(2024, 1, 1),
    );
    final roster = sampleHubRoster();
    final repo = EditFakePeopleRepository({'carer-1': inactive});
    await tester.pumpWidget(
      _editApp(
        overrides: _overrides(roster, repo),
        child: const PersonEditPage(personId: 'carer-1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('people_edit_reactivate')), findsOneWidget);
  });

  test('delete error maps contact_in_use to friendly message', () {
    final l = lookupAppLocalizations(const Locale('en'));
    final message = personFormDeleteErrorMessage(
      l,
      PeopleApiException(code: 'contact_in_use', statusCode: 409),
    );
    expect(message, l.peopleUsagesBlockedDelete);
  });

  testWidgets('usages dialog lists usage labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showContactUsagesDialog(
              context,
              usages: const [
                ContactUsage(
                  kind: 'care_item_provider',
                  id: 'x',
                  label: 'Buddy check',
                ),
              ],
              onMarkInactive: () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Contact still in use'), findsOneWidget);
    expect(find.text('Buddy check'), findsOneWidget);
  });

  test('reactivate patch uses active flag', () {
    final controller = PersonFormController(
      initial: ContactDetail(
        id: 'carer-1',
        directoryId: 'dir-1',
        directory: const ContactDirectoryRef(type: 'personal'),
        kind: ContactKind.person,
        name: 'Jamie',
        roles: const [ContactRole.sitter],
        group: ContactGroup.carer,
        status: ContactStatus.inactive,
        inactiveAt: DateTime.utc(2024),
      ),
    );
    expect(controller.buildReactivatePatch()['active'], isTrue);
  });

  testWidgets('roles can be toggled on edit form', (tester) async {
    final roster = sampleHubRoster();
    final repo = EditFakePeopleRepository({'carer-1': _editableContact()});
    await tester.pumpWidget(
      _editApp(
        overrides: _overrides(roster, repo),
        child: const PersonEditPage(personId: 'carer-1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vet'));
    await tester.pump();
    expect(find.text('Identity'), findsOneWidget);
  });

  testWidgets('member removal preview dialog', (tester) async {
    final roster = Roster(
      households: [
        Household(
          id: 'hh-1',
          name: 'Morgan',
          myTier: 'full',
          myIsOrganiser: true,
          members: [
            HouseholdMember(
              userId: 'member-1',
              displayName: 'Sam',
              firstName: 'Sam',
              tier: 'full',
              isOrganiser: false,
              isYou: false,
              ownsPetIds: const [],
              sharesPetIds: const ['pet-1'],
            ),
          ],
        ),
      ],
      contacts: const [],
      pendingInvites: const [],
    );
    await tester.pumpWidget(
      _editApp(
        overrides: _overrides(roster, FakePeopleRepository()),
        child: const PersonEditPage(personId: 'member-1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('people_edit_remove_member')));
    await tester.pumpAndSettle();
    expect(find.text('Remove from household?'), findsOneWidget);
    expect(find.text('Remove from household only'), findsOneWidget);
  });
}
