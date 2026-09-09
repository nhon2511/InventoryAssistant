import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Abstract repository contract for authentication operations.
///
/// Implemented by [AuthRepositoryImpl] in the data layer.
abstract class AuthRepository {
  /// Signs in with email and password.
  FutureEither<Profile> signIn({
    required String email,
    required String password,
  });

  /// Registers a new user with profile data.
  FutureEither<Profile> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  /// Signs out the current user.
  FutureVoid signOut();

  /// Gets the currently authenticated user's profile.
  FutureEither<Profile> getCurrentProfile();

  /// Stream of auth state changes.
  Stream<supabase.AuthState> get onAuthStateChange;
}
