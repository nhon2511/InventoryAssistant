import 'package:flutter/material.dart';

/// Useful extensions on [BuildContext].
extension ContextExtensions on BuildContext {
  /// Shorthand for `Theme.of(this)`.
  ThemeData get theme => Theme.of(this);

  /// Shorthand for `Theme.of(this).colorScheme`.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Shorthand for `Theme.of(this).textTheme`.
  TextTheme get textTheme => theme.textTheme;

  /// Shorthand for `MediaQuery.sizeOf(this)`.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Shows a [SnackBar] with the given [message].
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? colorScheme.error
              : colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Whether the current screen width is considered "wide" (tablet / web).
  bool get isWideScreen => screenSize.width >= 768;
}
