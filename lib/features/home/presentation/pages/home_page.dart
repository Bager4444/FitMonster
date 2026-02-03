import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/core/widgets/theme_toggle_button.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercises_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/diet_page.dart';
import 'package:fitmonster/features/exercises/presentation/pages/workout_complexes_page.dart';
import 'package:fitmonster/features/profile/presentation/pages/profile_page.dart';

/// Главная страница с навигацией
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  List<Widget> _buildPages() => [
    const ExercisesPage(),
    const WorkoutComplexesPage(),
    const DietPage(),
    ProfilePage(isCurrentTab: _currentIndex == 3),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
              statusBarBrightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.currentGradient,
            ),
            child: IndexedStack(
              index: _currentIndex,
              children: _buildPages(),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode 
                  ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.fitness_center,
                      label: 'Упражнения',
                      index: 0,
                      currentIndex: _currentIndex,
                      themeProvider: themeProvider,
                    ),
                    _buildNavItem(
                      icon: Icons.view_list,
                      label: 'Комплексы',
                      index: 1,
                      currentIndex: _currentIndex,
                      themeProvider: themeProvider,
                    ),
                    _buildNavItem(
                      icon: Icons.restaurant,
                      label: 'Диета',
                      index: 2,
                      currentIndex: _currentIndex,
                      themeProvider: themeProvider,
                    ),
                    _buildNavItem(
                      icon: Icons.person,
                      label: 'Профиль',
                      index: 3,
                      currentIndex: _currentIndex,
                      themeProvider: themeProvider,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required ThemeProvider themeProvider,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected
        ? (themeProvider.isDarkMode ? Colors.white : const Color(0xFF4CAF50))
        : (themeProvider.isDarkMode ? Colors.white54 : Colors.grey[600]!);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFF4CAF50).withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
