import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';
import 'package:smart_wms/features/auth/domain/repositories/auth_repository.dart';

/// Retrieves the profile of the currently authenticated user.
class GetCurrentProfileUseCase extends UseCase<Profile, NoParams> {
  const GetCurrentProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  FutureEither<Profile> call(NoParams params) {
    return _repository.getCurrentProfile();
  }
}
