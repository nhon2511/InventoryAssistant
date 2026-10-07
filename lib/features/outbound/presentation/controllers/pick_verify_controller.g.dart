// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pick_verify_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the pick verification flow state during outbound scanning.

@ProviderFor(PickVerifyController)
final pickVerifyControllerProvider = PickVerifyControllerProvider._();

/// Manages the pick verification flow state during outbound scanning.
final class PickVerifyControllerProvider
    extends $NotifierProvider<PickVerifyController, PickVerifyState> {
  /// Manages the pick verification flow state during outbound scanning.
  PickVerifyControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pickVerifyControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pickVerifyControllerHash();

  @$internal
  @override
  PickVerifyController create() => PickVerifyController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickVerifyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickVerifyState>(value),
    );
  }
}

String _$pickVerifyControllerHash() =>
    r'f452cfa75de637e6e249c3be962ec21e3bdcea39';

/// Manages the pick verification flow state during outbound scanning.

abstract class _$PickVerifyController extends $Notifier<PickVerifyState> {
  PickVerifyState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PickVerifyState, PickVerifyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PickVerifyState, PickVerifyState>,
              PickVerifyState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
