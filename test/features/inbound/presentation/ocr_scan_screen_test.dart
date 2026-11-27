import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/core/services/image_ocr_service.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/ocr_scan_screen.dart';

class _FakeImageOcrService implements ImageOcrService {
  _FakeImageOcrService({this.result, this.error});

  final ImageOcrResult? result;
  final Exception? error;

  @override
  Future<ImageOcrResult?> pickAndRecognize({
    required OcrProgressCallback onProgress,
  }) async {
    onProgress('recognizing text', 0.65);
    if (error case final error?) throw error;
    return result;
  }

  @override
  void revokePreview(String previewUrl) {}
}

void main() {
  testWidgets('image OCR result can be reviewed, edited and applied', (
    tester,
  ) async {
    Map<String, String>? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: OcrScanScreen(
          ocrService: _FakeImageOcrService(
            result: const ImageOcrResult(
              previewUrl: 'about:blank',
              text: 'LOT: ABC-123\nEXP: 25/12/2027',
            ),
          ),
          onApply: (values) => applied = values,
        ),
      ),
    );

    await tester.tap(find.text('Chọn ảnh hoặc chụp ảnh'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Kiểm tra và chỉnh kết quả'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, 'LOT: ABC-123\nEXP: 25/12/2027');
    expect(fields[1].controller!.text, 'ABC-123');
    expect(fields[2].controller!.text, '25/12/2027');

    await tester.enterText(find.byType(TextField).at(1), 'MANUAL-LOT');
    await tester.tap(find.text('Dùng kết quả xem trước'));
    expect(applied, {'lotNumber': 'MANUAL-LOT', 'expiryDate': '25/12/2027'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('OCR failure shows a localized recovery message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OcrScanScreen(
          ocrService: _FakeImageOcrService(error: Exception('browser detail')),
        ),
      ),
    );

    await tester.tap(find.text('Chọn ảnh hoặc chụp ảnh'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Không nhận diện được ảnh'), findsOneWidget);
    expect(find.textContaining('browser detail'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
