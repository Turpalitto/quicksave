import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ios_tokens.dart';

/// Material 3 themes for QuickSave — iOS-inspired dark UI.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: IosTokens.blue,
      onPrimary: Colors.white,
      secondary: IosTokens.purple,
      onSecondary: Colors.white,
      error: IosTokens.red,
      onError: Colors.white,
      surface: isDark ? IosTokens.bg : const Color(0xFFF2F2F7),
      onSurface: isDark ? IosTokens.label : Colors.black,
      onSurfaceVariant: isDark ? IosTokens.label2 : const Color(0x993C3C43),
      surfaceContainerHighest: isDark ? IosTokens.elevated2 : Colors.white,
      surfaceContainerHigh: isDark ? IosTokens.elevated : Colors.white,
      primaryContainer: IosTokens.blue.withValues(alpha: 0.15),
      onPrimaryContainer: IosTokens.blue,
      tertiaryContainer: IosTokens.purple.withValues(alpha: 0.15),
      onTertiaryContainer: IosTokens.purple,
      errorContainer: IosTokens.red.withValues(alpha: 0.15),
      onErrorContainer: IosTokens.red,
      outline: IosTokens.separator,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? IosTokens.bg : const Color(0xFFF2F2F7),
      fontFamily: '.AppleSystemUIFont',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: IosTokens.largeTitle.copyWith(fontSize: 34),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: IosTokens.blurBar,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: selected ? IosTokens.blue : IosTokens.label3,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? IosTokens.blue : IosTokens.label3,
            size: 26,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: IosTokens.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: IosTokens.headline,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: IosTokens.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: IosTokens.body.copyWith(color: IosTokens.label3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: IosTokens.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: IosTokens.separator,
        thickness: 0.5,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: IosTokens.elevated2,
        contentTextStyle: IosTokens.subhead,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
