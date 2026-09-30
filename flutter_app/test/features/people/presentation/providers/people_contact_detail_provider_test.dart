import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/data/datasources/people_remote_datasource.dart';
import 'package:pet_profile_app/features/people/data/models/people_contact_model.dart';
import 'package:pet_profile_app/features/people/presentation/providers/people_providers.dart';

/// Counts server calls so the tests can prove the detail provider settles.
class _CountingPeopleDataSource implements PeopleRemoteDataSource {
  _CountingPeopleDataSource(this._contact);

  PeopleContactModel _contact;
  int getContactCalls = 0;

  @override
  Future<List<PeopleContactModel>> listContacts({
    bool includeInactive = false,
  }) async => [_contact];

  @override
  Future<PeopleContactModel> getContact(String id) async {
    getContactCalls += 1;
    // A fresh instance each time, as the real HTTP data source returns.
    return PeopleContactModel(
      id: _contact.id,
      kind: _contact.kind,
      name: _contact.name,
      roles: [..._contact.roles],
      phone: _contact.phone,
    );
  }

  @override
  Future<PeopleContactModel> updateContact(
    String id,
    Map<String, dynamic> patch,
  ) async {
    _contact = PeopleContactModel(
      id: _contact.id,
      kind: _contact.kind,
      name: _contact.name,
      roles: _contact.roles,
      phone: patch['phone'] as String? ?? _contact.phone,
    );
    return _contact;
  }

  @override
  Future<PeopleContactModel> createContact(PeopleContactModel draft) async =>
      draft;

  @override
  Future<void> deleteContact(String id) async {}
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _CountingPeopleDataSource ds;
  late ProviderContainer container;

  setUp(() {
    ds = _CountingPeopleDataSource(
      PeopleContactModel(
        id: 'contact-1',
        kind: 'person',
        name: 'Dr Vet',
        roles: const ['vet'],
        phone: '0100',
      ),
    );
    container = ProviderContainer(
      overrides: [peopleRemoteDataSourceProvider.overrideWithValue(ds)],
    );
    addTearDown(container.dispose);
  });

  test(
    'detail provider fetches once and settles even when the contact list is loaded',
    () async {
      // Load the list first so the fetched contact replaces an existing entry.
      await container.read(peopleContactsProvider.future);
      final sub = container.listen(
        peopleContactDetailProvider('contact-1'),
        (_, __) {},
      );
      addTearDown(sub.close);

      final contact = await container.read(
        peopleContactDetailProvider('contact-1').future,
      );
      await _settle();

      expect(contact?.name, 'Dr Vet');
      expect(ds.getContactCalls, 1);
      expect(
        container.read(peopleContactDetailProvider('contact-1')).hasValue,
        isTrue,
      );
    },
  );

  test('detail provider settles when opened by deep link before the list loads', () async {
    final sub = container.listen(
      peopleContactDetailProvider('contact-1'),
      (_, __) {},
    );
    addTearDown(sub.close);

    await container.read(peopleContactDetailProvider('contact-1').future);
    await container.read(peopleContactsProvider.future);
    await _settle();

    expect(ds.getContactCalls, 1);
    expect(
      container.read(peopleContactDetailProvider('contact-1')).hasValue,
      isTrue,
    );
  });

  test('updateContactPatch refetches the detail exactly once', () async {
    await container.read(peopleContactsProvider.future);
    final sub = container.listen(
      peopleContactDetailProvider('contact-1'),
      (_, __) {},
    );
    addTearDown(sub.close);
    await container.read(peopleContactDetailProvider('contact-1').future);
    await _settle();

    await container
        .read(peopleContactsProvider.notifier)
        .updateContactPatch('contact-1', {'phone': '0200'});
    final refreshed = await container.read(
      peopleContactDetailProvider('contact-1').future,
    );
    await _settle();

    expect(refreshed?.phone, '0200');
    expect(ds.getContactCalls, 2);
  });
}
