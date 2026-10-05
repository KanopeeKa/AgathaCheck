import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';

void main() {
  group('FW-3 AuthUser weight_unit', () {
    test('parses weight_unit from profile JSON', () {
      final user = AuthUser.fromJson({
        'id': 'u-1',
        'email': 'a@b.com',
        'weight_unit': 'lb',
      });
      expect(user.weightUnit, 'lb');
    });

    test('defaults weight_unit to kg when absent', () {
      final user = AuthUser.fromJson({'id': 'u-1', 'email': 'a@b.com'});
      expect(user.weightUnit, 'kg');
    });
  });
}
