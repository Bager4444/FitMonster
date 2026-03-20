import 'package:flutter/material.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';

/// Карточка в стиле стекла: размытие, полупрозрачный фон и обводка (Deep Blue Glassmorphism).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding ?? const EdgeInsets.all(14),
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }
}
