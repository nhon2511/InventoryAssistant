import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class _MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class _MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class _MockSupabaseQueryBuilder extends Mock
    implements supabase.SupabaseQueryBuilder {}

class _FakePostgrestFilterBuilder<T> extends Fake
    implements supabase.PostgrestFilterBuilder<T> {
  _FakePostgrestFilterBuilder(this._future);

  final Future<T> _future;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);
}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;
  late _MockSupabaseQueryBuilder queryBuilder;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    queryBuilder = _MockSupabaseQueryBuilder();

    when(() => client.auth).thenReturn(auth);
    when(() => client.from(any())).thenAnswer((_) => queryBuilder);

    dataSource = AuthRemoteDataSourceImpl(client);
  });

  group('signUpWithEmail', () {
    test('maps PostgrestException with alphanumeric code to ServerException without TypeError', () async {
      final authResponse = supabase.AuthResponse(
        user: const supabase.User(
          id: 'user-123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01',
        ),
      );

      when(
        () => auth.signUp(email: 'test@example.com', password: 'password123'),
      ).thenAnswer((_) async => authResponse);

      when(() => queryBuilder.insert(any())).thenAnswer(
        (_) => _FakePostgrestFilterBuilder(
          Future<dynamic>.error(
            const supabase.PostgrestException(
              message: 'duplicate key value violates unique constraint',
              code: '23505',
            ),
          ),
        ),
      );

      expect(
        () => dataSource.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          fullName: 'Test User',
        ),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', contains('duplicate key'))
              .having((e) => e.statusCode, 'statusCode', equals(23505)),
        ),
      );
    });

    test('maps PostgrestException with non-numeric code to ServerException with null statusCode', () async {
      final authResponse = supabase.AuthResponse(
        user: const supabase.User(
          id: 'user-123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01',
        ),
      );

      when(
        () => auth.signUp(email: 'test@example.com', password: 'password123'),
      ).thenAnswer((_) async => authResponse);

      when(() => queryBuilder.insert(any())).thenAnswer(
        (_) => _FakePostgrestFilterBuilder(
          Future<dynamic>.error(
            const supabase.PostgrestException(
              message: 'relation profiles does not exist',
              code: 'PGRST116',
            ),
          ),
        ),
      );

      expect(
        () => dataSource.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          fullName: 'Test User',
        ),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', contains('relation'))
              .having((e) => e.statusCode, 'statusCode', isNull),
        ),
      );
    });
  });
}
