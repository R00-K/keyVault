import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextTheme {
  AppTextTheme._();

  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  static const heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  static const body = TextStyle(fontSize: 16, color: AppColors.textPrimary);

  static const bodyMuted = TextStyle(fontSize: 15, color: AppColors.textMuted);

  static const caption = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );
}
