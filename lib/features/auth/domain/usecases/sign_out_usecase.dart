import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/auth/domain/repositories/auth_repository.dart';

/// Signs out the currently authenticated user.
class SignOutUseCase extends UseCase<void, NoParams> {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  FutureVoid call(NoParams params) => _repository.signOut();
}
