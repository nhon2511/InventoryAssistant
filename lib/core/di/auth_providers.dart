import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_wms/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smart_wms/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_wms/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:smart_wms/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smart_wms/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:smart_wms/features/auth/domain/usecases/sign_up_usecase.dart';

/// Creates the authentication data source from the app-wide Supabase client.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

/// Exposes the authentication repository contract to the presentation layer.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentProfileUseCaseProvider = Provider<GetCurrentProfileUseCase>((
  ref,
) {
  return GetCurrentProfileUseCase(ref.watch(authRepositoryProvider));
});
