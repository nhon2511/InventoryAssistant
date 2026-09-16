// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller that manages authentication state.
///
/// Uses [AsyncNotifier] pattern with Riverpod code generation.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Controller that manages authentication state.
///
/// Uses [AsyncNotifier] pattern with Riverpod code generation.
final class AuthControllerProvider
    extends $NotifierProvider<AuthController, AuthState> {
  /// Controller that manages authentication state.
  ///
  /// Uses [AsyncNotifier] pattern with Riverpod code generation.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authControllerHash() => r'21441499de2b9c1c3ed4ce2dce56a926e4c9b74e';

/// Controller that manages authentication state.
///
/// Uses [AsyncNotifier] pattern with Riverpod code generation.

abstract class _$AuthController extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
