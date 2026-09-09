import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';
import 'package:smart_wms/features/auth/domain/repositories/auth_repository.dart';

/// Signs in a user with email and password.
class SignInUseCase extends UseCase<Profile, SignInParams> {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  @override
  FutureEither<Profile> call(SignInParams params) {
    return _repository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}

/// Parameters for [SignInUseCase].
class SignInParams {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;
}
