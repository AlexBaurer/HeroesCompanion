import 'package:flutter/material.dart';

abstract final class AppTheme {
  /// Единая тема Material 3: стили кнопок заданы здесь, виджеты не
  /// хардкодят оформление (кроме цветов фракций — они из данных).
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
