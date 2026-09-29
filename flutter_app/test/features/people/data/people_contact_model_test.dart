import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/data/models/people_contact_model.dart';

void main() {
  test('fromJson maps roles and private note', () {
    final model = PeopleContactModel.fromJson({
      'id': 'c1',
      'kind': 'person',
      'name': 'Jamie',
      'roles': ['sitter'],
      'private_note': 'Neighbour',
    });
    expect(model.name, 'Jamie');
    expect(model.roles, ['sitter']);
    expect(model.privateNote, 'Neighbour');
    expect(model.toEntity().isCarer, isTrue);
  });

  test('buildPatchComparedTo sends only deltas and empty string to clear', () {
    final original = PeopleContactModel(
      id: 'c1',
      kind: 'person',
      name: 'Greenhill',
      roles: ['vet'],
      phone: '1',
      email: 'a@b.com',
      address: '1 St',
    );
    final draft = PeopleContactModel(
      id: 'c1',
      kind: 'person',
      name: 'Greenhill',
      roles: ['vet'],
      phone: '',
      email: 'a@b.com',
      address: '2 St',
      privateNote: 'note',
    );
    final patch = draft.buildPatchComparedTo(original);
    expect(patch.containsKey('name'), isFalse);
    expect(patch['phone'], '');
    expect(patch['address'], '2 St');
    expect(patch['private_note'], 'note');
  });

  test('toCreateJson omits empty optional fields', () {
    final model = PeopleContactModel(
      id: '',
      kind: 'person',
      name: 'Alex',
      roles: ['vet'],
    );
    final json = model.toCreateJson();
    expect(json['name'], 'Alex');
    expect(json['roles'], ['vet']);
    expect(json.containsKey('phone'), isFalse);
  });
}
