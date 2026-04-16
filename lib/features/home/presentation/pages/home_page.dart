import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/core/providers/nav_index_provider.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercises_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/diet_page.dart';
import 'package:fitmonster/features/exercises/presentation/pages/workout_complexes_page.dart';
import 'package:fitmonster/features/profile/presentation/pages/profile_page.dart';
import 'package:fitmonster/features/ai/presentation/pages/ai_chat_page.dart';

/// Главная страница: тёмный фон, плавающая навигация со стеклянными карточками.
/// Вкладки создаются лениво — только при первом открытии, чтобы не строить все экраны при старте.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _navBottomMargin = 20;
  static const double _navHorizontalMargin = 8;
  /// Высота капсулы навигации + зазор до FAB (чат не перекрывает табы).
  static const double _aiFabClearanceAboveNav = 88;

  final List<Widget?> _cachedTabs = [null, null]; // только Упражнения и Комплексы кэшируем

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            GlassTheme.buildScaffoldBackground(context),
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
            Positioned(
              right: 20,
              bottom: _navBottomMargin +
                  MediaQuery.of(context).padding.bottom +
                  _aiFabClearanceAboveNav,
              child: Tooltip(
                message: 'AI ассистент',
                child: GlassContainer(
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (context) => const AiChatPage(),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(14),
                  borderRadius: 28,
                  child: Icon(
                    Icons.smart_toy,
                    color: context.fm.textPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Поверх контента вкладок и навигации (последний в Stack).
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: Tooltip(
                message: isDark
                    ? 'Включить светлую тему'
                    : 'Включить тёмную тему',
                child: Consumer<ThemeProvider>(
                  builder: (context, theme, _) {
                    return SizedBox(
                      width: 44,
                      height: 44,
                      child: GlassContainer(
                        borderRadius: 22,
                        padding: EdgeInsets.zero,
                        onTap: () => theme.toggleTheme(),
                        child: Center(
                          child: Icon(
                            theme.isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: context.fm.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
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
        final fm = context.fm;
        final inactiveBorder =
            fm.isDark ? const Color(0x33FFFFFF) : const Color(0x33000000);
        return GestureDetector(
          onTap: () => nav.setIndex(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? (fm.isDark
                      ? const Color(0xFF2E2E34)
                      : fm.surfaceCardMuted)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isActive
                  ? Border.all(color: const Color(0xFFEC4899), width: 2.5)
                  : Border.all(color: inactiveBorder, width: 1),
              boxShadow: isActive
                  ? const [
                      BoxShadow(
                        color: Color(0x664C1D95),
                        blurRadius: 10,
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
                    color: isActive ? fm.textPrimary : fm.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: isActive ? fm.textPrimary : fm.textSecondary,
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
