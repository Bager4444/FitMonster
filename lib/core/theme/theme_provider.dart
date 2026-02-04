import 'package:flutter/material.dart';

/// Провайдер темы для переключения между дневным и ночным режимами
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    print('Toggling theme from $_isDarkMode to ${!_isDarkMode}');
    _isDarkMode = !_isDarkMode;
    print('Current gradient: ${_isDarkMode ? "dark" : "light"}');
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  /// Дневной градиент: создается через RadialGradient для плавности
  Gradient get lightGradient => RadialGradient(
    center: Alignment.topCenter,
    radius: 1.2,
    colors: [
      Colors.white,                    // Белый в центре
      const Color(0xFFF8FDF8),        // Очень светло-зеленый
      const Color(0xFFE8F5E8),        // Светло-зеленый
      const Color(0xFFD0E8D0),        // Мягкий зеленый
      const Color(0xFF81C784),        // Приглушенный зеленый по краям
    ],
    stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
  );

  /// Deep Blue градиент (glassmorphism)
  Gradient get darkGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2979FF),
      Color(0xFF0D1B2A),
    ],
  );

  /// Текущий градиент в зависимости от темы
  Gradient get currentGradient => _isDarkMode ? darkGradient : lightGradient;

  /// Цвет текста для текущей темы
  Color get textColor => _isDarkMode ? Colors.white : Colors.black87;

  /// Цвет вторичного текста
  Color get secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.black54;

  /// Цвет карточек
  Color get cardColor => _isDarkMode 
      ? const Color(0xFF1E293B) // Темно-серый для темной темы
      : Colors.white.withValues(alpha: 0.8);

  /// Цвет поля ввода
  Color get inputFieldColor => _isDarkMode 
      ? const Color(0xFF1F2937) // Темно-серый для темной темы
      : Colors.white; // Белый для светлой темы

  /// Цвет текста в поле ввода
  Color get inputTextColor => _isDarkMode 
      ? Colors.white // Белый текст в темной теме
      : Colors.black87; // Черный текст в светлой теме

  /// Цвет подсказки в поле ввода
  Color get inputHintColor => _isDarkMode 
      ? Colors.white54 // Полупрозрачный белый в темной теме
      : Colors.black54; // Полупрозрачный черный в светлой теме

  /// Цвет границ карточек
  Color get cardBorderColor => _isDarkMode 
      ? Colors.white.withValues(alpha: 0.2) 
      : Colors.black.withValues(alpha: 0.1);

  /// Цвет кнопок
  Color get buttonColor => _isDarkMode ? const Color(0xFF1E3A8A) : const Color(0xFF4CAF50);

  /// Цвет акцента
  Color get accentColor => _isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2E7D32);

  /// Цвет фона
  Color get backgroundColor => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF5F5F5);
}