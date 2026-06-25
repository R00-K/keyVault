import 'package:flutter/material.dart';

class AppTextTheme {
  AppTextTheme._();

  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0,
  );

  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0,
  );

  static const heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0,
  );

  static const body = TextStyle(fontSize: 16, color: Colors.white);

  static const bodyMuted = TextStyle(fontSize: 15, color: Color(0xFFC9D1D9));

  static const caption = TextStyle(fontSize: 13, color: Color(0xFF9CA3AF));
}
