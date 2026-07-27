import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/sharing/domain/entities/share_link.dart';

void main() {
  group('ShareLink', () {
    test('fromJson parses claim fields', () {
      final link = ShareLink.fromJson({
        'id': 'link-1',
        'code': 'ABC123',
        'status': 'active',
        'created_at': '2025-01-01T00:00:00.000Z',
        'claimed_at': '2025-01-02T00:00:00.000Z',
        'claimed_by': 'user-1',
        'claimed_by_name': 'Alex',
      });

      expect(link.code, 'ABC123');
      expect(link.isActive, isTrue);
      expect(link.isPending, isFalse);
      expect(link.claimedByName, 'Alex');
    });

    test('defaults status to pending', () {
      final link = ShareLink.fromJson({'id': 'link-2'});
      expect(link.isPending, isTrue);
      expect(link.code, '');
    });
  });
}
