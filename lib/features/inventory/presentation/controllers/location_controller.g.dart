// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocationController)
final locationControllerProvider = LocationControllerProvider._();

final class LocationControllerProvider
    extends $AsyncNotifierProvider<LocationController, List<Location>> {
  LocationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationControllerHash();

  @$internal
  @override
  LocationController create() => LocationController();
}

String _$locationControllerHash() =>
    r'3ecd59dafbdb2c7ccbd9d1f3e4a5d968b75cb560';

abstract class _$LocationController extends $AsyncNotifier<List<Location>> {
  FutureOr<List<Location>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Location>>, List<Location>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Location>>, List<Location>>,
              AsyncValue<List<Location>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
