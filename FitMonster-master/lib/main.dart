import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/app_theme.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/core/constants/app_constants.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/features/home/presentation/pages/home_page.dart';

void main() async {
  // Инициализация Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive с адаптерами и боксами
  await HiveService.initialize();
  
  runApp(const FitMonsterApp());
}

class FitMonsterApp extends StatelessWidget {
  const FitMonsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            home: const HomePage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
