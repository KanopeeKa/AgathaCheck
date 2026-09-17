import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/invite_preview.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/pet_access.dart';

void main() {
  test('InvitePreview.fromJson parses pets and role', () {
    final preview = InvitePreview.fromJson({
      'invite_id': 'inv-1',
      'code': 'abc12345',
      'role': 'co_parent',
      'status': 'pending',
      'inviter_name': 'Alice Owner',
      'pets': [
        {'pet_id': 'pet-1', 'pet_name': 'Buddy'},
        {'pet_id': 'pet-2', 'pet_name': 'Max'},
      ],
    });

    expect(preview.inviteId, 'inv-1');
    expect(preview.code, 'abc12345');
    expect(preview.role, PetAccessRole.coParent);
    expect(preview.petNamesDisplay, 'Buddy, Max');
    expect(preview.isPending, isTrue);
  });
}
