import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';
import 'package:smart_wms/features/auth/domain/repositories/auth_repository.dart';

/// Registers a new user account with profile data.
class SignUpUseCase extends UseCase<Profile, SignUpParams> {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  FutureEither<Profile> call(SignUpParams params) {
    return _repository.signUp(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      phoneNumber: params.phoneNumber,
    );
  }
}

/// Parameters for [SignUpUseCase].
class SignUpParams {
  const SignUpParams({
    required this.email,
    required this.password,
    required this.fullName,
    this.phoneNumber,
  });

  final String email;
  final String password;
  final String fullName;
  final String? phoneNumber;
}
