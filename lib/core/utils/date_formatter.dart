import 'package:intl/intl.dart';

/// Utility for formatting dates in Vietnamese locale.
class DateFormatter {
  const DateFormatter._();

  static final _vnDateFormat = DateFormat('dd/MM/yyyy');
  static final _vnDateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Formats a [DateTime] as `dd/MM/yyyy`.
  static String toVnDate(DateTime date) => _vnDateFormat.format(date);

  /// Formats a [DateTime] as `dd/MM/yyyy HH:mm`.
  static String toVnDateTime(DateTime date) => _vnDateTimeFormat.format(date);

  /// Formats a [DateTime] as `yyyy-MM-dd` (ISO / PostgreSQL DATE).
  static String toIsoDate(DateTime date) => _isoDateFormat.format(date);

  /// Parses a VN date string `dd/MM/yyyy` into a [DateTime].
  ///
  /// Returns `null` if parsing fails.
  static DateTime? parseVnDate(String input) {
    try {
      return _vnDateFormat.parseStrict(input);
    } on FormatException {
      return null;
    }
  }

  /// Parses an ISO date string `yyyy-MM-dd` into a [DateTime].
  ///
  /// Returns `null` if parsing fails.
  static DateTime? parseIsoDate(String input) {
    try {
      return _isoDateFormat.parseStrict(input);
    } on FormatException {
      return null;
    }
  }
}
