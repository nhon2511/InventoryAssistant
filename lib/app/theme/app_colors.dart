import 'package:flutter/material.dart';

/// Application color palette.
///
/// Uses Material 3 seed-based color scheme with a warehouse-themed
/// primary color (deep teal / blue-green).
abstract final class AppColors {
  // ── Seed Color ────────────────────────────────────────────────────
  static const Color seed = Color(0xFF2563EB);

  // ── Brand Colors ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF14253D);

  // ── Semantic Colors ───────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  // ── Stock Status Colors ───────────────────────────────────────────
  static const Color inStock = Color(0xFF2E7D32);
  static const Color lowStock = Color(0xFFED6C02);
  static const Color outOfStock = Color(0xFFD32F2F);

  // ── Surface Colors ────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
}
