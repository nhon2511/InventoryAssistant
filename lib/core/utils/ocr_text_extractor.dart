/// Extracts expiry date and lot number from raw OCR text.
///
/// Supports common label formats found on warehouse product labels:
/// - `EXP: DD/MM/YYYY`, `EXP DD/MM/YYYY`, `HSD: DD/MM/YYYY`
/// - `LOT: XXXXX`, `Lot No: XXXXX`, `BATCH: XXXXX`
class OcrTextExtractor {
  const OcrTextExtractor._();

  /// Regex patterns for expiry date extraction.
  static final _expiryPatterns = [
    // EXP: 25/12/2027 or HSD: 25/12/2027
    RegExp(r'(?:EXP|HSD|NSX|MFG)[:\s]*(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})', caseSensitive: false),
    // Standalone date pattern DD/MM/YYYY
    RegExp(r'\b(\d{2}[/\-\.]\d{2}[/\-\.]\d{4})\b'),
  ];

  /// Regex patterns for lot number extraction.
  static final _lotPatterns = [
    RegExp(r'\b(?:LOT|BATCH|Lô)\b[:\s]+([A-Za-z0-9\-]{3,20})', caseSensitive: false),
    RegExp(r'\b(?:Lot\s*No|Batch\s*No)\b[.:\s]+([A-Za-z0-9\-]{3,20})', caseSensitive: false),
  ];

  /// Extracts the first expiry date string found in [text].
  ///
  /// Returns `null` if no date pattern is found.
  static String? extractExpiryDate(String text) {
    for (final pattern in _expiryPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  /// Extracts the first lot/batch number found in [text].
  ///
  /// Returns `null` if no lot pattern is found.
  static String? extractLotNumber(String text) {
    for (final pattern in _lotPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  /// Extracts both expiry date and lot number from [text].
  ///
  /// Returns a record with nullable fields.
  static ({String? expiryDate, String? lotNumber}) extractAll(String text) {
    return (
      expiryDate: extractExpiryDate(text),
      lotNumber: extractLotNumber(text),
    );
  }
}
