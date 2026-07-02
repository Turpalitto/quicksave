import 'package:flutter/material.dart';

/// iOS-style design tokens from the new-chat design system.
abstract final class IosTokens {
  static const bg = Color(0xFF000000);
  static const elevated = Color(0xFF1C1C1E);
  static const elevated2 = Color(0xFF2C2C2E);
  static const separator = Color(0x80545458);
  static const blue = Color(0xFF0A84FF);
  static const green = Color(0xFF30D158);
  static const red = Color(0xFFFF453A);
  static const orange = Color(0xFFFF9F0A);
  static const purple = Color(0xFFBF5AF2);
  static const pink = Color(0xFFFF375F);
  static const label = Color(0xFFFFFFFF);
  static const label2 = Color(0x99EBEBF5);
  static const label3 = Color(0x4DEBEBF5);
  static const fill = Color(0x33787880);
  static const fill2 = Color(0x52787880);
  static const blurBar = Color(0xC7121214);
  static const desktopBg = Color(0xFF0A0A0C);
  static const segmentActive = Color(0xFF636366);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, pink, purple],
  );

  static const libraryGradients = <LinearGradient>[
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF30D158), Color(0xFF34C759)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF9F0A), Color(0xFFFF375F)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFBF5AF2), Color(0xFF5E5CE6)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF375F), Color(0xFFFF9F0A)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF64D2FF), Color(0xFF0A84FF)],
    ),
  ];

  static const avatarColors = [
    blue,
    green,
    orange,
    purple,
    pink,
    Color(0xFF64D2FF),
  ];

  static TextStyle largeTitle = const TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    height: 41 / 34,
    color: label,
  );

  static TextStyle title3 = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.45,
    color: label,
  );

  static TextStyle headline = const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.43,
    color: label,
  );

  static TextStyle body = const TextStyle(
    fontSize: 17,
    letterSpacing: -0.43,
    color: label,
  );

  static TextStyle callout = const TextStyle(
    fontSize: 16,
    letterSpacing: -0.31,
    color: label,
  );

  static TextStyle subhead = const TextStyle(
    fontSize: 15,
    letterSpacing: -0.23,
    color: label,
  );

  static TextStyle footnote = const TextStyle(
    fontSize: 13,
    letterSpacing: -0.08,
    color: label2,
  );

  static TextStyle caption1 = const TextStyle(
    fontSize: 12,
    color: label2,
  );

  static TextStyle caption2 = const TextStyle(
    fontSize: 11,
    letterSpacing: 0.06,
    color: label2,
  );

  static TextStyle sectionHeader = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: label2,
  );
}
