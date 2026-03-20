import 'dart:ui';
import 'package:flutter/material.dart';

/// Deep Blue Glassmorphism: единая тема и переиспользуемые виджеты для всего приложения.
class GlassTheme {
  GlassTheme._();

  // ——— Цвета (строго по ТЗ) ———
  static const Color gradientTop = Color(0xFF2979FF);
  static const Color gradientBottom = Color(0xFF0D1B2A);
  static const Color glowCyan = Color(0xFF00E5FF);

  static const LinearGradient scaffoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientBottom],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
  );

  // Типографика
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  static TextStyle get titleStyle => const TextStyle(
        fontWeight: FontWeight.bold,
        color: textPrimary,
        shadows: [
          Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
        ],
      );

  static TextStyle get bodyStyle => const TextStyle(
        color: textSecondary,
        shadows: [
          Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 1),
        ],
      );

  /// Фон для всего приложения: градиент под статус/навбар.
  static Widget buildScaffoldBackground() => Container(
        decoration: const BoxDecoration(
          gradient: scaffoldGradient,
        ),
      );
}

/// Переиспользуемый стеклянный контейнер с размытием и обводкой.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.onTap,
    this.blurSigma = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }
    return content;
  }
}
