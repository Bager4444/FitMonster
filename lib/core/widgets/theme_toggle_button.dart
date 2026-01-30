import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

/// Кнопка переключения между дневным и ночным режимами
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () {
            print('Theme toggle tapped! Current mode: ${themeProvider.isDarkMode}');
            themeProvider.toggleTheme();
            print('New mode: ${themeProvider.isDarkMode}');
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.grey,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
                key: ValueKey(themeProvider.isDarkMode),
                color: themeProvider.isDarkMode ? Colors.yellow : Colors.blue,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}