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
