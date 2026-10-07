// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbound_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InboundController)
final inboundControllerProvider = InboundControllerProvider._();

final class InboundControllerProvider
    extends $AsyncNotifierProvider<InboundController, List<WarehouseOrder>> {
  InboundControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboundControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboundControllerHash();

  @$internal
  @override
  InboundController create() => InboundController();
}

String _$inboundControllerHash() => r'b644e7e9815a2891178b69a1b7289164a978bdc8';

abstract class _$InboundController
    extends $AsyncNotifier<List<WarehouseOrder>> {
  FutureOr<List<WarehouseOrder>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<WarehouseOrder>>, List<WarehouseOrder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<WarehouseOrder>>,
                List<WarehouseOrder>
              >,
              AsyncValue<List<WarehouseOrder>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
