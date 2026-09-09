import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/core/enums/user_role.dart';

void main() {
  group('UserRole', () {
    test('fromString parses ADMIN', () {
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
    });

    test('fromString parses case-insensitively', () {
      expect(UserRole.fromString('staff'), UserRole.staff);
    });

    test('fromString throws for unknown value', () {
      expect(() => UserRole.fromString('UNKNOWN'), throwsArgumentError);
    });

    test('isManagerOrAbove returns true for admin and manager', () {
      expect(UserRole.admin.isManagerOrAbove, isTrue);
      expect(UserRole.manager.isManagerOrAbove, isTrue);
      expect(UserRole.staff.isManagerOrAbove, isFalse);
    });
  });
}
