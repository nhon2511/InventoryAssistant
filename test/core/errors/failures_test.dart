import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/core/errors/failures.dart';

void main() {
  group('Failures', () {
    test('ServerFailure equality', () {
      const failure1 = ServerFailure(message: 'test', statusCode: 500);
      const failure2 = ServerFailure(message: 'test', statusCode: 500);
      expect(failure1, equals(failure2));
    });

    test('AuthFailure equality', () {
      const failure1 = AuthFailure(message: 'auth error');
      const failure2 = AuthFailure(message: 'auth error');
      expect(failure1, equals(failure2));
    });

    test('NetworkFailure has default message', () {
      const failure = NetworkFailure();
      expect(failure.message, contains('kết nối mạng'));
    });

    test('different failure types are not equal', () {
      const server = ServerFailure(message: 'error');
      const auth = AuthFailure(message: 'error');
      expect(server, isNot(equals(auth)));
    });
  });
}
