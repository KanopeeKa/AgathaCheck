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
import 'package:pet_profile_app/features/people/presentation/add/add_person_create_body.dart';
import 'package:pet_profile_app/features/people/presentation/add/add_person_entry.dart';
import 'package:pet_profile_app/features/people/presentation/add/add_person_flow.dart';
import 'package:pet_profile_app/features/people/presentation/add/add_person_providers.dart';
import 'package:pet_profile_app/features/people/presentation/edit/person_form_controller.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../application/people_providers_test.dart'
    show FakeHouseholdsRepository, FakePeopleRepository;

void main() {
  group('AddPersonEntry', () {
    test('professional requires roles and skips app access', () {
      expect(AddPersonEntry.professional.requiresRoles, isTrue);
      expect(AddPersonEntry.professional.showsAppAccessStep, isFalse);
      expect(AddPersonEntry.professional.contactKind, ContactKind.person);
    });

    test('organisation kind is organisation', () {
      expect(AddPersonEntry.organisation.contactKind, ContactKind.organisation);
      expect(AddPersonEntry.organisation.requiresRoles, isFalse);
    });

    test('household shows app access', () {
      expect(AddPersonEntry.household.showsAppAccessStep, isTrue);
      expect(AddPersonEntry.household.requiresRoles, isFalse);
    });
  });

  group('buildAddPersonCreateBody', () {
    test('includes explicit kind and pet_links', () {
      final form = PersonFormController.forNewContact(kind: ContactKind.person);
      form.setName('Jamie');
      form.toggleRole(ContactRole.vet);
      final body = buildAddPersonCreateBody(form: form, pets: []);
      expect(body['kind'], 'person');
      expect(body['name'], 'Jamie');
      expect(body['roles'], ['vet']);
    });
  });

  testWidgets('professional tile path reaches roles step', (tester) async {
    final fakePeople = _RecordingPeopleRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          peopleRepositoryProvider.overrideWithValue(fakePeople),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
          addPersonPetsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AddPersonFlow(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('people_add_tile_professional')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('people_add_name_field')),
      'Dr. Ada',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('How do they help?'), findsOneWidget);
    await tester.tap(find.text('Vet'));
    await tester.pumpAndSettle();
    expect(rolesValidForAdd({ContactRole.vet}, requiresRoles: true), isTrue);
  });
}

class _RecordingPeopleRepository extends FakePeopleRepository {
  _RecordingPeopleRepository() : super();
  @override
  Future<ContactDetail> createContact(Map<String, dynamic> body) async {
    return ContactDetail(
      id: 'new-1',
      directoryId: 'dir',
      directory: const ContactDirectoryRef(type: 'personal'),
      kind: ContactKind.fromWire(body['kind']?.toString()),
      name: body['name']?.toString() ?? '',
      roles: ContactRole.fromWireList(body['roles'] as List?),
      group: ContactGroup.professional,
      status: ContactStatus.active,
    );
  }
}
