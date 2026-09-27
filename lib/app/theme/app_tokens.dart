import 'package:flutter/material.dart';
import 'package:smart_wms/app/theme/app_colors.dart';

/// Shared dimensions and semantic colors for warehouse screens.
abstract final class AppTokens {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double touchTarget = 48;
  static const double navigationBreakpoint = 600;
  static const double textSmall = 12;
  static const double textBody = 14;
  static const double textLarge = 16;
  static const double textTitle = 20;
  static const double textHeadline = 28;

  static const Color inStock = AppColors.inStock;
  static const Color lowStock = AppColors.lowStock;
  static const Color outOfStock = AppColors.outOfStock;
  static const Color expiring = AppColors.warning;
  static const Color expired = AppColors.error;
  static const Color draft = Colors.blueGrey;
  static const Color pending = AppColors.warning;
  static const Color confirmed = AppColors.info;
  static const Color completed = AppColors.success;
}
