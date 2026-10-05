import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_detail.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/repositories/people_repository.dart';
import 'package:pet_profile_app/features/people/domain/services/people_query.dart';
import 'package:pet_profile_app/features/people/presentation/picker/people_picker_field.dart';
import 'package:pet_profile_app/features/people/presentation/picker/people_picker_result.dart';
import 'package:pet_profile_app/features/people/presentation/picker/people_picker_sheet.dart';

import '../application/people_providers_test.dart';
import 'people_test_harness.dart';

ContactSummary _active({required String id, required String name}) {
  return ContactSummary(
    id: id,
    directory: const ContactDirectoryRef(type: 'personal'),
    kind: ContactKind.person,
    name: name,
    roles: const [ContactRole.sitter],
    group: ContactGroup.carer,
    status: ContactStatus.active,
  );
}

ContactSummary _inactive(String id) {
  return ContactSummary(
    id: id,
    directory: const ContactDirectoryRef(type: 'personal'),
    kind: ContactKind.person,
    name: 'Inactive $id',
    roles: const [ContactRole.sitter],
    group: ContactGroup.carer,
    status: ContactStatus.inactive,
  );
}

class _TestRosterNotifier extends RosterNotifier {
  _TestRosterNotifier(this._roster);

  final Roster _roster;

  @override
  Future<Roster> build() async => _roster;
}

class PickerFakeRepository extends FakePeopleRepository {
  PickerFakeRepository(this.roster, {this.onCreate});

  final Roster roster;
  final Future<ContactDetail> Function(Map<String, dynamic> body)? onCreate;

  @override
  Future<Roster> fetchRoster({bool includeInactive = false}) async => roster;

  @override
  Future<ContactDetail> createContact(Map<String, dynamic> body) async {
    if (onCreate != null) return onCreate!(body);
    return ContactDetail(
      id: 'new-id',
      directoryId: 'd',
      directory: const ContactDirectoryRef(type: 'personal'),
      kind: ContactKind.person,
      name: body['name'] as String,
      roles: const [ContactRole.sitter],
      group: ContactGroup.carer,
      status: ContactStatus.active,
    );
  }
}

Widget _pickerHarness({
  required Widget child,
  required PeopleRepository repo,
  required Roster roster,
}) {
  return ProviderScope(
    overrides: [
      peopleRepositoryProvider.overrideWithValue(repo),
      householdsRepositoryProvider.overrideWithValue(
        FakeHouseholdsRepository(),
      ),
      rosterProvider.overrideWith(() => _TestRosterNotifier(roster)),
    ],
    child: peopleTestApp(child: child),
  );
}

void main() {
  testWidgets('picker excludes inactive except pinned current', (tester) async {
    final roster = Roster(
      households: const [],
      contacts: [
        _active(id: 'a', name: 'Alex'),
        _inactive('old'),
      ],
      pendingInvites: const [],
    );

    await tester.pumpWidget(
      _pickerHarness(
        repo: PickerFakeRepository(roster),
        roster: roster,
        child: PeoplePickerSheet(
          query: const PeopleQuery(currentId: 'old'),
          purpose: 'test',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('people_picker_option_a')), findsOneWidget);
    expect(find.byKey(const Key('people_picker_option_old')), findsOneWidget);
    expect(find.text('Current selection'), findsOneWidget);
    expect(find.text('Inactive'), findsWidgets);
  });

  testWidgets('picker none option when allowNone', (tester) async {
    PeoplePickerResult? result;
    final roster = Roster(
      households: const [],
      contacts: [_active(id: 'a', name: 'Alex')],
      pendingInvites: const [],
    );

    await tester.pumpWidget(
      _pickerHarness(
        repo: PickerFakeRepository(roster),
        roster: roster,
        child: Consumer(
          builder: (context, ref, _) => FilledButton(
            onPressed: () async {
              result = await showPeoplePickerSheet(
                context: context,
                ref: ref,
                query: const PeopleQuery(allowNone: true),
                purpose: 'care',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('people_picker_option_none')));
    await tester.pumpAndSettle();
    expect(result, isA<PeoplePickerNoneResult>());
  });

  testWidgets('quick add returns created person', (tester) async {
    PeoplePickerResult? result;
    final roster = Roster(
      households: const [],
      contacts: const [],
      pendingInvites: const [],
    );

    await tester.pumpWidget(
      _pickerHarness(
        repo: PickerFakeRepository(roster),
        roster: roster,
        child: Consumer(
          builder: (context, ref, _) => FilledButton(
            onPressed: () async {
              result = await showPeoplePickerSheet(
                context: context,
                ref: ref,
                query: const PeopleQuery(),
                purpose: 'add',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New Person');
    await tester.pump();
    await tester.tap(find.byKey(const Key('people_picker_add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();
    expect(result, isA<PeoplePickerContactResult>());
    expect((result! as PeoplePickerContactResult).contact.name, 'New Person');
  });

  testWidgets('typed name option when allowTypedName', (tester) async {
    PeoplePickerResult? result;
    final roster = Roster(
      households: const [],
      contacts: const [],
      pendingInvites: const [],
    );

    await tester.pumpWidget(
      _pickerHarness(
        repo: PickerFakeRepository(roster),
        roster: roster,
        child: Consumer(
          builder: (context, ref, _) => FilledButton(
            onPressed: () async {
              result = await showPeoplePickerSheet(
                context: context,
                ref: ref,
                query: const PeopleQuery(allowTypedName: true),
                purpose: 'provider',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Walk-in');
    await tester.pump();
    await tester.tap(find.textContaining('without saving'));
    await tester.pumpAndSettle();
    expect(result, isA<PeoplePickerTypedNameResult>());
    expect((result! as PeoplePickerTypedNameResult).name, 'Walk-in');
  });

  testWidgets('PeoplePickerField exposes semantics identifier', (tester) async {
    await tester.pumpWidget(
      _pickerHarness(
        repo: PickerFakeRepository(
          Roster(
            households: const [],
            contacts: const [],
            pendingInvites: const [],
          ),
        ),
        roster: Roster(
          households: const [],
          contacts: const [],
          pendingInvites: const [],
        ),
        child: PeoplePickerField(
          purpose: 'works_at',
          query: const PeopleQuery(),
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      find.bySemanticsIdentifier('people_picker_field_works_at'),
      findsOneWidget,
    );
  });
}
