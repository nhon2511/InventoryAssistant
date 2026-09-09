import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/core/utils/ocr_text_extractor.dart';

void main() {
  group('OcrTextExtractor', () {
    group('extractExpiryDate', () {
      test('extracts EXP date from label text', () {
        const text = 'Product ABC\nEXP: 25/12/2027\nLot: L2024A';
        expect(OcrTextExtractor.extractExpiryDate(text), '25/12/2027');
      });

      test('extracts HSD date from label text', () {
        const text = 'HSD: 01/06/2028';
        expect(OcrTextExtractor.extractExpiryDate(text), '01/06/2028');
      });

      test('returns null when no date found', () {
        const text = 'Product ABC without date';
        expect(OcrTextExtractor.extractExpiryDate(text), isNull);
      });
    });

    group('extractLotNumber', () {
      test('extracts LOT number', () {
        const text = 'LOT: ABC-123\nEXP: 25/12/2027';
        expect(OcrTextExtractor.extractLotNumber(text), 'ABC-123');
      });

      test('extracts Batch number', () {
        const text = 'BATCH: X2024Y';
        expect(OcrTextExtractor.extractLotNumber(text), 'X2024Y');
      });

      test('returns null when no lot found', () {
        const text = 'Plain text without code';
        expect(OcrTextExtractor.extractLotNumber(text), isNull);
      });
    });

    group('extractAll', () {
      test('extracts both date and lot', () {
        const text = 'EXP: 15/03/2028\nLOT: L2024-001';
        final result = OcrTextExtractor.extractAll(text);
        expect(result.expiryDate, '15/03/2028');
        expect(result.lotNumber, 'L2024-001');
      });
    });
  });
}
