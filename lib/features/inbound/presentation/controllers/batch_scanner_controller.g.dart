// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_scanner_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the state during batch barcode scanning sessions.
///
/// Tracks scanned barcodes, counts duplicates, and provides
/// haptic/sound feedback triggers.

@ProviderFor(BatchScannerController)
final batchScannerControllerProvider = BatchScannerControllerProvider._();

/// Manages the state during batch barcode scanning sessions.
///
/// Tracks scanned barcodes, counts duplicates, and provides
/// haptic/sound feedback triggers.
final class BatchScannerControllerProvider
    extends $NotifierProvider<BatchScannerController, BatchScannerState> {
  /// Manages the state during batch barcode scanning sessions.
  ///
  /// Tracks scanned barcodes, counts duplicates, and provides
  /// haptic/sound feedback triggers.
  BatchScannerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchScannerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchScannerControllerHash();

  @$internal
  @override
  BatchScannerController create() => BatchScannerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatchScannerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatchScannerState>(value),
    );
  }
}

String _$batchScannerControllerHash() =>
    r'8bf8f5ba9840dd14bc26bbc6405124b214ca8e45';

/// Manages the state during batch barcode scanning sessions.
///
/// Tracks scanned barcodes, counts duplicates, and provides
/// haptic/sound feedback triggers.

abstract class _$BatchScannerController extends $Notifier<BatchScannerState> {
  BatchScannerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BatchScannerState, BatchScannerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BatchScannerState, BatchScannerState>,
              BatchScannerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
