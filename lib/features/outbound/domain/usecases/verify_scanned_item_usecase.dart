/// Verifies a scanned barcode against the pick list.
///
/// Returns a [VerifyResult] indicating whether the scan matches,
/// mismatches, or exceeds the expected quantity.
class VerifyScannedItemUseCase {
  const VerifyScannedItemUseCase();

  VerifyResult call({
    required String scannedBarcode,
    required String expectedBarcode,
    required int currentPicked,
    required int expectedQuantity,
  }) {
    if (scannedBarcode != expectedBarcode) {
      return VerifyResult.mismatch;
    }
    if (currentPicked + 1 > expectedQuantity) {
      return VerifyResult.overQuantity;
    }
    return VerifyResult.match;
  }
}

/// Result of a pick verification scan.
enum VerifyResult {
  /// Scanned barcode matches the expected item.
  match,

  /// Scanned barcode does not match any item in the pick list.
  mismatch,

  /// Scanned quantity exceeds the expected quantity.
  overQuantity,
}
