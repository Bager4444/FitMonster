import 'package:flutter/material.dart';

/// Палитра «стекла»: тёмная и светлая тема через [ThemeExtension].
@immutable
class FitMonsterColors extends ThemeExtension<FitMonsterColors> {
  const FitMonsterColors({
    required this.brightness,
    required this.scaffoldGradient,
    required this.frameGradient,
    required this.primaryButtonGradient,
    required this.surfaceCard,
    required this.surfaceCardMuted,
    required this.outlineMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.glowCyan,
    required this.gradientHeaderTop,
    required this.gradientHeaderBottom,
    required this.accentButtonTint,
    required this.dialogBackground,
  });

  final Brightness brightness;
  final LinearGradient scaffoldGradient;
  final LinearGradient frameGradient;
  final LinearGradient primaryButtonGradient;
  final Color surfaceCard;
  final Color surfaceCardMuted;
  final Color outlineMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color glowCyan;
  final Color gradientHeaderTop;
  final Color gradientHeaderBottom;
  final Color accentButtonTint;
  final Color dialogBackground;

  bool get isDark => brightness == Brightness.dark;

  TextStyle get titleStyle => TextStyle(
        fontWeight: FontWeight.bold,
        color: textPrimary,
        shadows: [
          Shadow(
            color: isDark ? const Color(0x66000000) : const Color(0x14000000),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      );

  TextStyle get bodyStyle => TextStyle(
        color: textSecondary,
        fontSize: 15,
        height: 1.5,
        shadows: isDark
            ? const [
                Shadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ]
            : null,
      );

  static const LinearGradient _frame = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFFEC4899),
      Color(0xFF7C3AED),
    ],
    stops: [0.0, 0.48, 1.0],
  );

  static const LinearGradient _primaryBtn = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFFE879F9),
      Color(0xFF8B5CF6),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const FitMonsterColors dark = FitMonsterColors(
    brightness: Brightness.dark,
    scaffoldGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF242428),
        Color(0xFF141416),
        Color(0xFF0A0A0B),
      ],
      stops: [0.0, 0.45, 1.0],
    ),
    frameGradient: _frame,
    primaryButtonGradient: _primaryBtn,
    surfaceCard: Color(0xFF121214),
    surfaceCardMuted: Color(0xFF18181C),
    outlineMuted: Color(0x3AFFFFFF),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFB8B8C0),
    glowCyan: Color(0xFFE879F9),
    gradientHeaderTop: Color(0xFF2A2A2E),
    gradientHeaderBottom: Color(0xFF0C0C0E),
    accentButtonTint: Color(0xFF2A2A2E),
    dialogBackground: Color(0xFF121214),
  );

  /// Светлая тема — та же иерархия, что у [dark]: вертикальный градиент фона,
  /// карточка / приглушённая карточка, те же акценты и рамки по смыслу; тона светлые, текст тёмный.
  static const FitMonsterColors light = FitMonsterColors(
    brightness: Brightness.light,
    scaffoldGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFECECEF),
        Color(0xFFDCDCE4),
        Color(0xFFD0D0D8),
      ],
      stops: [0.0, 0.45, 1.0],
    ),
    frameGradient: _frame,
    primaryButtonGradient: _primaryBtn,
    surfaceCard: Color(0xFFF2F2F4),
    surfaceCardMuted: Color(0xFFEAEAED),
    outlineMuted: Color(0x45000000),
    textPrimary: Color(0xFF0A0A0C),
    textSecondary: Color(0xFF5E5E68),
    glowCyan: Color(0xFFE879F9),
    gradientHeaderTop: Color(0xFFD5D5DC),
    gradientHeaderBottom: Color(0xFFBEBEC8),
    accentButtonTint: Color(0xFF3A3A42),
    dialogBackground: Color(0xFFF0F0F2),
  );

  @override
  FitMonsterColors copyWith({
    Brightness? brightness,
    LinearGradient? scaffoldGradient,
    LinearGradient? frameGradient,
    LinearGradient? primaryButtonGradient,
    Color? surfaceCard,
    Color? surfaceCardMuted,
    Color? outlineMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? glowCyan,
    Color? gradientHeaderTop,
    Color? gradientHeaderBottom,
    Color? accentButtonTint,
    Color? dialogBackground,
  }) {
    return FitMonsterColors(
      brightness: brightness ?? this.brightness,
      scaffoldGradient: scaffoldGradient ?? this.scaffoldGradient,
      frameGradient: frameGradient ?? this.frameGradient,
      primaryButtonGradient:
          primaryButtonGradient ?? this.primaryButtonGradient,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceCardMuted: surfaceCardMuted ?? this.surfaceCardMuted,
      outlineMuted: outlineMuted ?? this.outlineMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      glowCyan: glowCyan ?? this.glowCyan,
      gradientHeaderTop: gradientHeaderTop ?? this.gradientHeaderTop,
      gradientHeaderBottom:
          gradientHeaderBottom ?? this.gradientHeaderBottom,
      accentButtonTint: accentButtonTint ?? this.accentButtonTint,
      dialogBackground: dialogBackground ?? this.dialogBackground,
    );
  }

  @override
  FitMonsterColors lerp(ThemeExtension<FitMonsterColors>? other, double t) {
    if (other is! FitMonsterColors) return this;
    if (t <= 0) return this;
    if (t >= 1) return other;
    return t < 0.5 ? this : other;
  }
}

extension FitMonsterColorsContext on BuildContext {
  FitMonsterColors get fm {
    final ext = Theme.of(this).extension<FitMonsterColors>();
    return ext ?? FitMonsterColors.dark;
  }
}
