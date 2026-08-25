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

  static TextStyle caption1 = const TextStyle(fontSize: 12, color: label2);

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

  // Light mode surfaces (iOS grouped background style)
  static const bgLight = Color(0xFFF2F2F7);
  static const elevatedLight = Color(0xFFFFFFFF);
  static const elevated2Light = Color(0xFFE5E5EA);
  static const labelLight = Color(0xFF000000);
  static const label2Light = Color(0x993C3C43);
  static const label3Light = Color(0x4D3C3C43);
  static const fillLight = Color(0x1F787880);
  static const fill2Light = Color(0x29787880);
  static const blurBarLight = Color(0xF2F9F9FB);
  static const separatorLight = Color(0x4C3C3C43);
}

/// Resolves iOS tokens for the current Material brightness.
class IosPalette {
  const IosPalette._(this.isDark);

  final bool isDark;

  factory IosPalette.of(BuildContext context) =>
      IosPalette._(Theme.of(context).brightness == Brightness.dark);

  Color get bg => isDark ? IosTokens.bg : IosTokens.bgLight;
  Color get elevated => isDark ? IosTokens.elevated : IosTokens.elevatedLight;
  Color get elevated2 =>
      isDark ? IosTokens.elevated2 : IosTokens.elevated2Light;
  Color get label => isDark ? IosTokens.label : IosTokens.labelLight;
  Color get label2 => isDark ? IosTokens.label2 : IosTokens.label2Light;
  Color get label3 => isDark ? IosTokens.label3 : IosTokens.label3Light;
  Color get fill => isDark ? IosTokens.fill : IosTokens.fillLight;
  Color get fill2 => isDark ? IosTokens.fill2 : IosTokens.fill2Light;
  Color get blurBar => isDark ? IosTokens.blurBar : IosTokens.blurBarLight;
  Color get separator =>
      isDark ? IosTokens.separator : IosTokens.separatorLight;

  TextStyle get largeTitle => IosTokens.largeTitle.copyWith(color: label);
  TextStyle get headline => IosTokens.headline.copyWith(color: label);
  TextStyle get body => IosTokens.body.copyWith(color: label);
  TextStyle get subhead => IosTokens.subhead.copyWith(color: label);
  TextStyle get footnote => IosTokens.footnote.copyWith(color: label2);
  TextStyle get caption1 => IosTokens.caption1.copyWith(color: label2);
  TextStyle get sectionHeader =>
      IosTokens.sectionHeader.copyWith(color: label2);
}
