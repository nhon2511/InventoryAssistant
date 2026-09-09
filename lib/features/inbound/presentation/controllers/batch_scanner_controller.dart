import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'batch_scanner_controller.g.dart';

/// Manages the state during batch barcode scanning sessions.
///
/// Tracks scanned barcodes, counts duplicates, and provides
/// haptic/sound feedback triggers.
@riverpod
class BatchScannerController extends _$BatchScannerController {
  @override
  BatchScannerState build() {
    return const BatchScannerState();
  }

  /// Adds a scanned barcode. Auto-increments count if already scanned.
  void addBarcode(String barcode) {
    final currentItems = Map<String, int>.from(state.scannedItems);
    currentItems[barcode] = (currentItems[barcode] ?? 0) + 1;

    state = state.copyWith(
      scannedItems: currentItems,
      lastScannedBarcode: barcode,
      totalScans: state.totalScans + 1,
    );
  }

  /// Removes a barcode entry from the scanned list.
  void removeBarcode(String barcode) {
    final currentItems = Map<String, int>.from(state.scannedItems)
      ..remove(barcode);

    state = state.copyWith(scannedItems: currentItems);
  }

  /// Clears all scanned items.
  void reset() {
    state = const BatchScannerState();
  }
}

/// State for the batch scanner.
class BatchScannerState {
  const BatchScannerState({
    this.scannedItems = const {},
    this.lastScannedBarcode,
    this.totalScans = 0,
    this.isScanning = false,
  });

  /// Map of barcode → count (duplicates are auto-incremented).
  final Map<String, int> scannedItems;

  /// The last barcode that was scanned.
  final String? lastScannedBarcode;

  /// Total number of scans performed in this session.
  final int totalScans;

  /// Whether the camera is actively scanning.
  final bool isScanning;

  /// Number of unique barcodes scanned.
  int get uniqueCount => scannedItems.length;

  BatchScannerState copyWith({
    Map<String, int>? scannedItems,
    String? lastScannedBarcode,
    int? totalScans,
    bool? isScanning,
  }) {
    return BatchScannerState(
      scannedItems: scannedItems ?? this.scannedItems,
      lastScannedBarcode: lastScannedBarcode ?? this.lastScannedBarcode,
      totalScans: totalScans ?? this.totalScans,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}
