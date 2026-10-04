import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/notifications/domain/entities/notification_kind.dart';

void main() {
  group('NotificationKind.fromWire (v2)', () {
    test('parses relationship, suggestion, and account without falling back to care', () {
      expect(NotificationKind.fromWire('relationship'), NotificationKind.relationship);
      expect(NotificationKind.fromWire('suggestion'), NotificationKind.suggestion);
      expect(NotificationKind.fromWire('account'), NotificationKind.account);
    });

    test('preserves legacy kinds', () {
      expect(NotificationKind.fromWire('care'), NotificationKind.care);
      expect(NotificationKind.fromWire('administrative'), NotificationKind.administrative);
    });

    test('unknown wire values map to administrative (not care)', () {
      expect(NotificationKind.fromWire('bogus'), NotificationKind.administrative);
      expect(NotificationKind.fromWire(null), NotificationKind.administrative);
    });
  });
}
