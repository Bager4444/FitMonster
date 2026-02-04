import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/app_theme.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/core/constants/app_constants.dart';
import 'package:fitmonster/core/app_navigator.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/core/services/connectivity_service.dart';
import 'package:fitmonster/features/diet/data/services/database_init_service.dart';
import 'package:fitmonster/features/diet/data/services/food_database_service.dart';
import 'package:fitmonster/features/diet/data/datasources/local_food_datasource.dart';
import 'package:fitmonster/features/diet/data/repositories/food_repository.dart';
import 'package:fitmonster/features/home/presentation/pages/home_page.dart';
import 'package:fitmonster/core/providers/nav_index_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase не настроен (нет google-services.json) — работаем только как гость
  }

  await Hive.initFlutter();
  await HiveService.initialize();

  final auth = AuthService();
  await auth.restoreSession();
  if (!auth.isAuthenticated) {
    await auth.createUser();
  }
  
  // Миграция: очистить старые продукты и перейти на загрузку из JSON (один раз)
  final initService = DatabaseInitService();
  await initService.migrateToLocalFoodsIfNeeded();

  // Инициализация базы данных (импорт продуктов из foods.json и рецептов при первом запуске)
  if (!await initService.isInitialized()) {
    print('🔄 Начинаю инициализацию базы данных...');
    // Запускаем инициализацию и ждем завершения
    try {
      await initService.initializeDatabase(
        onProgress: (message) => print('📊 DB Init: $message'),
        onError: (error) => print('⚠️ DB Init Error: $error'),
      );
      print('✅ Инициализация базы данных завершена');
      
      // Проверить количество продуктов после инициализации
      final dbService = FoodDatabaseService();
      final foodsCount = dbService.getFoodsCount();
      final recipesCount = dbService.getRecipesCount();
      print('📊 Продуктов в базе: $foodsCount, Рецептов: $recipesCount');
    } catch (e, stackTrace) {
      print('❌ Критическая ошибка инициализации: $e');
      print('Stack trace: $stackTrace');
      // Продолжаем запуск приложения даже если инициализация не удалась
    }
  } else {
    print('✅ База данных уже инициализирована');
    // Проверить количество продуктов
    final dbService = FoodDatabaseService();
    final foodsCount = dbService.getFoodsCount();
    final recipesCount = dbService.getRecipesCount();
    print('📊 Продуктов в базе: $foodsCount, Рецептов: $recipesCount');
  }
  
  runApp(const FitMonsterApp());
}

class FitMonsterApp extends StatelessWidget {
  const FitMonsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Тема
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Индекс вкладки навигации (плавающая капсула)
        ChangeNotifierProvider(create: (_) => NavIndexProvider()),
        // Сервис подключения к сети
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        
        // Локальный источник продуктов (JSON → Hive)
        Provider(create: (_) => LocalFoodDatasource()),
        ProxyProvider<LocalFoodDatasource, FoodRepository>(
          update: (_, local, __) => FoodRepository(local: local),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            home: const HomePage(),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ru', 'RU'),
              Locale('en', 'US'),
            ],
            locale: const Locale('ru', 'RU'),
          );
        },
      ),
    );
  }
}
