import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/data/dto/people_dtos.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';

void main() {
  test('ContactSummaryDto round-trip includes unknown enum values', () {
    final json = {
      'id': 'c1',
      'directory': {'type': 'personal', 'household_id': null},
      'kind': 'person',
      'name': 'Jamie',
      'roles': ['sitter', 'future_role'],
      'group': 'carer',
      'status': 'active',
      'pets': [
        {
          'pet_id': 'p1',
          'pet_name': 'Buddy',
          'relationship_kind': 'future_kind',
          'is_primary': true,
        },
      ],
    };
    final entity = ContactSummaryDto.fromJson(json);
    expect(entity.roles.last, ContactRole.other);
    expect(entity.pets.first.relationshipKind, RelationshipKind.other);

    final roundTrip = ContactSummaryDto.toJson(entity);
    expect(roundTrip['roles'], ['sitter', 'other']);
    expect((roundTrip['pets'] as List).first['relationship_kind'], 'other');
  });

  test('ContactDetailDto maps detail fields', () {
    final detail = ContactDetailDto.fromJson({
      'id': 'c1',
      'directory_id': 'dir-1',
      'directory': {'type': 'personal'},
      'kind': 'person',
      'name': 'Jamie',
      'roles': ['vet'],
      'group': 'professional',
      'status': 'active',
      'private_note': 'note',
      'usage_counts': {'pet_relationship': 1},
      'staff': [],
    });
    expect(detail.group, ContactGroup.professional);
    expect(detail.privateNote, 'note');
    expect(detail.usageCounts['pet_relationship'], 1);
  });
}
