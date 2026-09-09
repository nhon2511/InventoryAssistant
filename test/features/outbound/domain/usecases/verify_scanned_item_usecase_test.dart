import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/features/outbound/domain/usecases/verify_scanned_item_usecase.dart';

void main() {
  const useCase = VerifyScannedItemUseCase();

  group('VerifyScannedItemUseCase', () {
    test('returns match when barcode matches and quantity is within limit', () {
      final result = useCase(
        scannedBarcode: '4006381333931',
        expectedBarcode: '4006381333931',
        currentPicked: 2,
        expectedQuantity: 5,
      );
      expect(result, VerifyResult.match);
    });

    test('returns mismatch when barcode does not match', () {
      final result = useCase(
        scannedBarcode: '4006381333931',
        expectedBarcode: '1234567890123',
        currentPicked: 0,
        expectedQuantity: 5,
      );
      expect(result, VerifyResult.mismatch);
    });

    test('returns overQuantity when picked exceeds expected', () {
      final result = useCase(
        scannedBarcode: '4006381333931',
        expectedBarcode: '4006381333931',
        currentPicked: 5,
        expectedQuantity: 5,
      );
      expect(result, VerifyResult.overQuantity);
    });
  });
}
