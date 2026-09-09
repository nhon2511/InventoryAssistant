import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_wms/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smart_wms/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:smart_wms/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smart_wms/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:smart_wms/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';

part 'auth_controller.g.dart';

/// Controller that manages authentication state.
///
/// Uses [AsyncNotifier] pattern with Riverpod code generation.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  late final SignInUseCase _signInUseCase;
  late final SignUpUseCase _signUpUseCase;
  late final SignOutUseCase _signOutUseCase;
  late final GetCurrentProfileUseCase _getCurrentProfileUseCase;

  @override
  AuthState build() {
    final client = ref.watch(supabaseClientProvider);
    final dataSource = AuthRemoteDataSourceImpl(client);
    final repository = AuthRepositoryImpl(dataSource);

    _signInUseCase = SignInUseCase(repository);
    _signUpUseCase = SignUpUseCase(repository);
    _signOutUseCase = SignOutUseCase(repository);
    _getCurrentProfileUseCase = GetCurrentProfileUseCase(repository);

    // Check initial auth state.
    _checkCurrentUser();

    return const AuthInitial();
  }

  Future<void> _checkCurrentUser() async {
    state = const AuthLoading();
    final result = await _getCurrentProfileUseCase(const NoParams());
    state = result.fold(
      (failure) => const AuthUnauthenticated(),
      (profile) => AuthAuthenticated(profile),
    );
  }

  /// Signs in with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await _signInUseCase(
      SignInParams(email: email, password: password),
    );
    state = result.fold(
      (failure) => AuthError(failure.message),
      (profile) => AuthAuthenticated(profile),
    );
  }

  /// Registers a new user.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    state = const AuthLoading();
    final result = await _signUpUseCase(
      SignUpParams(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      ),
    );
    state = result.fold(
      (failure) => AuthError(failure.message),
      (profile) => AuthAuthenticated(profile),
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AuthLoading();
    final result = await _signOutUseCase(const NoParams());
    state = result.fold(
      (failure) => AuthError(failure.message),
      (_) => const AuthUnauthenticated(),
    );
  }
}
