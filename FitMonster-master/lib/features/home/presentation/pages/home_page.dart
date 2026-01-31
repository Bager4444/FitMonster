import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/core/widgets/theme_toggle_button.dart';
import 'package:fitmonster/features/exercises/presentation/pages/modern_exercises_page.dart';
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

  // Используем IndexedStack для сохранения состояния вкладок
  final List<Widget> _pages = const [
    ModernExercisesPage(),
    WorkoutComplexesPage(),
    DietPage(),
    ProfilePage(),
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: const ThemeToggleButton(),
              ),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.currentGradient,
            ),
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.isDarkMode 
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1E293B), // Темно-синий сверху
                        Colors.black,             // Черный снизу
                      ],
                    )
                  : null, // Для светлой темы градиента нет
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: themeProvider.isDarkMode 
                  ? Colors.transparent 
                  : themeProvider.cardColor, // Белый для светлой темы
              indicatorColor: themeProvider.isDarkMode 
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.green.withValues(alpha: 0.8), // Более яркий зеленый для дневной темы
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.fitness_center, 
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[600]),
                  selectedIcon: Icon(Icons.fitness_center, 
                    color: themeProvider.isDarkMode ? Colors.white : Colors.green[800]),
                  label: 'Упражнения',
                ),
                NavigationDestination(
                  icon: Icon(Icons.view_list,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[600]),
                  selectedIcon: Icon(Icons.view_list,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.green[800]),
                  label: 'Комплексы',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[600]),
                  selectedIcon: Icon(Icons.restaurant,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.green[800]),
                  label: 'Диета',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[600]),
                  selectedIcon: Icon(Icons.person,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.green[800]),
                  label: 'Профиль',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
