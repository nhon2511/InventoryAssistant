// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReportsController)
final reportsControllerProvider = ReportsControllerProvider._();

final class ReportsControllerProvider
    extends $AsyncNotifierProvider<ReportsController, InventorySummary> {
  ReportsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportsControllerHash();

  @$internal
  @override
  ReportsController create() => ReportsController();
}

String _$reportsControllerHash() => r'f697664aeb61128080a33c76e137f60c6e638dba';

abstract class _$ReportsController extends $AsyncNotifier<InventorySummary> {
  FutureOr<InventorySummary> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<InventorySummary>, InventorySummary>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<InventorySummary>, InventorySummary>,
              AsyncValue<InventorySummary>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
