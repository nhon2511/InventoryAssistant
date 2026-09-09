import 'package:smart_wms/features/auth/domain/entities/profile.dart';

/// Sealed class representing all possible auth UI states.
sealed class AuthState {
  const AuthState();
}

/// Initial state before any auth check.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth operation in progress (sign in / sign up / sign out).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.profile);

  final Profile profile;
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Auth operation failed.
class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}
