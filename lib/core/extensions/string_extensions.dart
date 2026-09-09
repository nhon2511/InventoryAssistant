/// Useful extensions on [String].
extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Example: `'hello world'.capitalize` → `'Hello world'`
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of each word.
  ///
  /// Example: `'hello world'.titleCase` → `'Hello World'`
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Returns `null` if the string is empty, otherwise returns itself.
  String? get nullIfEmpty => isEmpty ? null : this;
}
