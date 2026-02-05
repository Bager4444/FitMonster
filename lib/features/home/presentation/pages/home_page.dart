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
/// Вкладки создаются лениво — только при первом открытии, чтобы не строить все экраны при старте.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _navBottomMargin = 20;
  static const double _navHorizontalMargin = 8;

  final List<Widget?> _cachedTabs = [null, null]; // только Упражнения и Комплексы кэшируем

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
                builder: (context, nav, _) {
                  final i = nav.index;
                  if (i < 2 && _cachedTabs[i] == null) {
                    _cachedTabs[i] = i == 0 ? const ExercisesPage() : const WorkoutComplexesPage();
                  }
                  return IndexedStack(
                    index: i,
                    children: [
                      _cachedTabs[0] ?? const SizedBox.shrink(),
                      _cachedTabs[1] ?? const SizedBox.shrink(),
                      DietPage(isCurrentTab: i == 2),
                      ProfilePage(isCurrentTab: i == 3),
                    ],
                  );
                },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: isActive ? GlassTheme.glowCyan : GlassTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      ),
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
