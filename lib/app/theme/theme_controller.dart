import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

class ThemeController extends Notifier<ThemeMode> {
  static const _storageKey = 'smart_wms.theme_mode';
  int _selectionVersion = 0;

  @override
  ThemeMode build() {
    unawaited(_restore());
    return ThemeMode.light;
  }

  ThemeMode get mode => state;

  set mode(ThemeMode mode) {
    _selectionVersion++;
    state = mode;
    unawaited(_persist(mode));
  }

  Future<void> _restore() async {
    final versionAtStart = _selectionVersion;
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_storageKey);
      if (saved == null ||
          versionAtStart != _selectionVersion ||
          !ref.mounted) {
        return;
      }
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.light,
      );
    } on Exception {
      // Keep the current in-memory theme when browser storage is unavailable.
    }
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, mode.name);
    } on Exception {
      // Theme changes remain available for the current app session.
    }
  }
}
