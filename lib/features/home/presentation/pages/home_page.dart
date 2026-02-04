import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/providers/nav_index_provider.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercises_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/diet_page.dart';
import 'package:fitmonster/features/exercises/presentation/pages/workout_complexes_page.dart';
import 'package:fitmonster/features/profile/presentation/pages/profile_page.dart';

/// Главная страница: Deep Blue градиент, плавающая стеклянная навигация.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const double _navBottomMargin = 20;
  static const double _navHorizontalMargin = 20;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            GlassTheme.buildScaffoldBackground(),
            SafeArea(
              top: true,
              bottom: false,
              child: Consumer<NavIndexProvider>(
                builder: (context, nav, _) => IndexedStack(
                  index: nav.index,
                  children: [
                    const ExercisesPage(),
                    const WorkoutComplexesPage(),
                    const DietPage(),
                    ProfilePage(isCurrentTab: nav.index == 3),
                  ],
                ),
              ),
            ),
            Positioned(
              left: _navHorizontalMargin,
              right: _navHorizontalMargin,
              bottom: _navBottomMargin + MediaQuery.of(context).padding.bottom,
              child: _FloatingNavCapsule(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavCapsule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 28,
      child: Consumer<NavIndexProvider>(
        builder: (context, nav, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _NavItem(icon: Icons.fitness_center, label: 'Упражнения', index: 0)),
            Expanded(child: _NavItem(icon: Icons.view_list, label: 'Комплексы', index: 1)),
            Expanded(child: _NavItem(icon: Icons.restaurant, label: 'Диета', index: 2)),
            Expanded(child: _NavItem(icon: Icons.person, label: 'Профиль', index: 3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final String label;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<NavIndexProvider>(
      builder: (context, nav, _) {
        final isActive = nav.index == index;
        return GestureDetector(
          onTap: () => nav.setIndex(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? GlassTheme.glowCyan.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: GlassTheme.glowCyan.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isActive ? GlassTheme.glowCyan : GlassTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? GlassTheme.glowCyan : GlassTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
