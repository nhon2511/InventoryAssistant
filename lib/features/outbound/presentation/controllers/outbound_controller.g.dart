// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbound_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OutboundController)
final outboundControllerProvider = OutboundControllerProvider._();

final class OutboundControllerProvider
    extends $AsyncNotifierProvider<OutboundController, List<WarehouseOrder>> {
  OutboundControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outboundControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outboundControllerHash();

  @$internal
  @override
  OutboundController create() => OutboundController();
}

String _$outboundControllerHash() =>
    r'72dbc950ef49e8112366114c546093f301849dc1';

abstract class _$OutboundController
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
