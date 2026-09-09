// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authControllerHash() => r'd4e5f6g7h8i9j0k1l2m3';

abstract class _$AuthController extends BuildlessNotifier<AuthState> {
  late final AuthState _$state;

  @override
  AuthState build();

  AuthState get state => _$state;

  set state(AuthState value) {
    _$state = value;
    ref.notifyListeners();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>.internal(
  AuthController.new,
  name: r'authControllerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthControllerRef = NotifierRef<AuthState>;
