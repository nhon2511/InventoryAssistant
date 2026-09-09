/// Utility class to parse and validate barcode strings.
///
/// Supports EAN-13, Code 128, QR Code, and DataMatrix formats
/// as specified in PRD Story 1.
class BarcodeParser {
  const BarcodeParser._();

  /// Determines the barcode format from a raw scanned string.
  static BarcodeFormat detectFormat(String raw) {
    final trimmed = raw.trim();

    // EAN-13: exactly 13 numeric digits
    if (RegExp(r'^\d{13}$').hasMatch(trimmed)) {
      return BarcodeFormat.ean13;
    }

    // EAN-8: exactly 8 numeric digits
    if (RegExp(r'^\d{8}$').hasMatch(trimmed)) {
      return BarcodeFormat.ean8;
    }

    // Code 128: alphanumeric, typically 6–48 chars
    if (RegExp(r'^[A-Za-z0-9\-\.\/\s]{6,48}$').hasMatch(trimmed)) {
      return BarcodeFormat.code128;
    }

    // Default: treat as QR / DataMatrix (any content)
    return BarcodeFormat.qrCode;
  }

  /// Validates the EAN-13 check digit.
  static bool isValidEan13(String code) {
    if (code.length != 13 || !RegExp(r'^\d{13}$').hasMatch(code)) {
      return false;
    }
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final digit = int.parse(code[i]);
      sum += i.isEven ? digit : digit * 3;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(code[12]);
  }
}

/// Supported barcode formats.
enum BarcodeFormat {
  ean13,
  ean8,
  code128,
  qrCode,
  dataMatrix,
}
