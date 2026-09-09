import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/core/utils/barcode_parser.dart';

void main() {
  group('BarcodeParser', () {
    group('detectFormat', () {
      test('detects EAN-13 format', () {
        expect(
          BarcodeParser.detectFormat('4006381333931'),
          BarcodeFormat.ean13,
        );
      });

      test('detects EAN-8 format', () {
        expect(
          BarcodeParser.detectFormat('96385074'),
          BarcodeFormat.ean8,
        );
      });

      test('detects Code128 format', () {
        expect(
          BarcodeParser.detectFormat('ABC-123-XYZ'),
          BarcodeFormat.code128,
        );
      });

      test('defaults to QR code for other formats', () {
        expect(
          BarcodeParser.detectFormat('https://example.com/product/123'),
          BarcodeFormat.qrCode,
        );
      });
    });

    group('isValidEan13', () {
      test('returns true for valid EAN-13', () {
        expect(BarcodeParser.isValidEan13('4006381333931'), isTrue);
      });

      test('returns false for invalid check digit', () {
        expect(BarcodeParser.isValidEan13('4006381333932'), isFalse);
      });

      test('returns false for wrong length', () {
        expect(BarcodeParser.isValidEan13('12345'), isFalse);
      });

      test('returns false for non-numeric', () {
        expect(BarcodeParser.isValidEan13('400638133393A'), isFalse);
      });
    });
  });
}
