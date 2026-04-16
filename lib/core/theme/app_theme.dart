import 'package:flutter/material.dart';
import 'package:fitmonster/core/theme/fit_monster_colors.dart';

/// Стиль «стекла» под тёмный чёрно-серый UI.
class AppGlassTheme {
  AppGlassTheme._();

  static const Color primaryElectric = Color(0xFFE879F9);
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textSecondaryOnDark = Color(0xFFB8B8C0);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF242428),
      Color(0xFF121214),
      Color(0xFF0A0A0B),
    ],
    stops: [0.0, 0.45, 1.0],
  );
}

/// Тема приложения FitMonster
/// Минималистичный стиль с зеленым для успеха и красным для ошибок
class AppTheme {
  // Цветовая палитра
  static const Color primaryGreen = Color(0xFF4CAF50); // Зеленый для успеха
  static const Color errorRed = Color(0xFFE53935); // Красный для ошибок
  static const Color warningOrange = Color(0xFFFF9800); // Оранжевый для предупреждений
  static const Color backgroundLight = Color(0xFFFAFAFA); // Светлый фон
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Белый для карточек
  static const Color textDark = Color(0xFF212121); // Темный текст
  static const Color textGrey = Color(0xFF757575); // Серый текст

  /// Тёмная тема приложения (стекло + [FitMonsterColors]).
  static ThemeData get glassDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE879F9),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0B),
      extensions: const [FitMonsterColors.dark],
    );
  }

  /// Светлая тема приложения (стекло + [FitMonsterColors]).
  static ThemeData get glassLightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFD0D0D8),
      extensions: const [FitMonsterColors.light],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Цветовая схема
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryGreen,
        error: errorRed,
        surface: surfaceWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: textDark,
      ),
      
      // Фон
      scaffoldBackgroundColor: backgroundLight,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: surfaceWhite,
        foregroundColor: textDark,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Карточки
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: surfaceWhite,
      ),
      
      // Кнопки
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Текстовые кнопки
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
        ),
      ),
      
      // Поля ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Иконки
      iconTheme: const IconThemeData(
        color: textDark,
      ),
      
      // Текст
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textDark),
        bodyLarge: TextStyle(fontSize: 16, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, color: textDark),
        bodySmall: TextStyle(fontSize: 12, color: textGrey),
      ),
    );
  }
}
