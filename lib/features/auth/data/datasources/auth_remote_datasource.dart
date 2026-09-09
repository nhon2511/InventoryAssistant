import 'package:smart_wms/core/constants/app_constants.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/features/auth/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Remote data source for authentication using Supabase Auth & profiles table.
abstract class AuthRemoteDataSource {
  Future<ProfileModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<ProfileModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  Future<void> signOut();

  Future<ProfileModel> getProfile(String userId);

  Stream<supabase.AuthState> get onAuthStateChange;
}

/// Implementation of [AuthRemoteDataSource] using Supabase SDK.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<ProfileModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final userId = response.user?.id;
      if (userId == null) {
        throw const AuthException(message: 'Đăng nhập thất bại.');
      }
      return await getProfile(userId);
    } on supabase.AuthException catch (e) {
      throw AuthException(message: e.message, statusCode: 401);
    }
  }

  @override
  Future<ProfileModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      final userId = response.user?.id;
      if (userId == null) {
        throw const AuthException(message: 'Đăng ký thất bại.');
      }

      // Create profile record in the profiles table.
      await _client.from(AppConstants.profilesTable).insert({
        'id': userId,
        'full_name': fullName,
        'role': 'STAFF', // Default role for new users
        'phone_number': phoneNumber,
      });

      return await getProfile(userId);
    } on supabase.AuthException catch (e) {
      throw AuthException(message: e.message, statusCode: 400);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(message: e.message, statusCode: e.code as int?);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(message: e.message);
    }
  }

  @override
  Future<ProfileModel> getProfile(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .single();
      return ProfileModel.fromJson(data);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChange {
    return _client.auth.onAuthStateChange;
  }
}
