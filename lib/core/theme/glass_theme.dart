import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fitmonster/core/theme/fit_monster_colors.dart';

export 'fit_monster_colors.dart';

/// Константы обводки; цвета и градиенты — из [FitMonsterColors] через `context.fm`.
class GlassTheme {
  GlassTheme._();

  static const double outlineStrokeWidth = 1.0;

  static Widget buildScaffoldBackground(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: context.fm.scaffoldGradient,
        ),
      );

  /// Карточка: градиентная рамка + непрозрачный фон.
  static Widget framedOpaque({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    double borderRadius = 24,
    double frameWidth = 2,
  }) {
    final fm = context.fm;
    final innerR = (borderRadius - frameWidth).clamp(1.0, borderRadius);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: EdgeInsets.all(frameWidth),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: fm.frameGradient,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fm.surfaceCard,
            borderRadius: BorderRadius.circular(innerR),
            border: Border.all(
              color: fm.outlineMuted,
              width: outlineStrokeWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Стеклянный блок: градиентная обводка, непрозрачный фон.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.onTap,
    this.blurSigma = 0,
    this.borderWidth = 2.75,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double blurSigma;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final fm = context.fm;
    final innerRadius = (borderRadius - borderWidth).clamp(0.0, borderRadius);

    final inner = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fm.surfaceCard,
        borderRadius: BorderRadius.circular(innerRadius),
        border: Border.all(
          color: fm.outlineMuted,
          width: GlassTheme.outlineStrokeWidth,
        ),
      ),
      child: child,
    );

    final clippedInner = ClipRRect(
      borderRadius: BorderRadius.circular(innerRadius),
      child: blurSigma > 0.5
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: inner,
            )
          : inner,
    );

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: fm.frameGradient,
        ),
        child: clippedInner,
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
