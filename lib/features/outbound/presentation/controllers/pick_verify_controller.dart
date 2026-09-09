import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/features/outbound/domain/usecases/verify_scanned_item_usecase.dart';

part 'pick_verify_controller.g.dart';

/// Manages the pick verification flow state during outbound scanning.
@riverpod
class PickVerifyController extends _$PickVerifyController {
  @override
  PickVerifyState build() => const PickVerifyState();

  /// Verifies a scanned barcode against the expected item.
  void verifyScan({
    required String scannedBarcode,
    required String expectedBarcode,
    required int currentPicked,
    required int expectedQuantity,
  }) {
    const verifyUseCase = VerifyScannedItemUseCase();
    final result = verifyUseCase(
      scannedBarcode: scannedBarcode,
      expectedBarcode: expectedBarcode,
      currentPicked: currentPicked,
      expectedQuantity: expectedQuantity,
    );

    state = state.copyWith(lastResult: result);
  }

  void reset() {
    state = const PickVerifyState();
  }
}

class PickVerifyState {
  const PickVerifyState({this.lastResult});

  final VerifyResult? lastResult;

  bool get hasError =>
      lastResult == VerifyResult.mismatch ||
      lastResult == VerifyResult.overQuantity;

  PickVerifyState copyWith({VerifyResult? lastResult}) {
    return PickVerifyState(lastResult: lastResult ?? this.lastResult);
  }
}
