import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/app_theme.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/core/constants/app_constants.dart';
import 'package:fitmonster/core/app_navigator.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/core/services/user_account_firestore_sync.dart';
import 'package:fitmonster/core/services/user_account_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/core/services/stats_service.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';
import 'package:fitmonster/core/services/connectivity_service.dart';
import 'package:fitmonster/features/diet/data/services/database_init_service.dart';
import 'package:fitmonster/features/diet/data/datasources/local_food_datasource.dart';
import 'package:fitmonster/features/diet/data/repositories/food_repository.dart';
import 'package:fitmonster/features/home/presentation/pages/home_page.dart';
import 'package:fitmonster/core/providers/nav_index_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    UserAccountService().attachFirestorePush(
      UserAccountFirestoreSync.instance.pushAfterLocalSave,
    );
    StatsService.onAfterStatsPersist =
        UserAccountFirestoreSync.instance.onLocalStatsMaybeChanged;
    DietService.onAfterProfileSaved =
        UserAccountFirestoreSync.instance.onLocalStatsMaybeChanged;
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

  // Запуск UI сразу; инициализация БД — в фоне (не блокирует старт)
  runApp(const FitMonsterApp());

  // Инициализация базы данных в фоне при первом запуске
  if (!await initService.isInitialized()) {
    initService.initializeDatabase(
      onProgress: (message) => debugPrint('DB Init: $message'),
      onError: (error) => debugPrint('DB Init Error: $error'),
    ).then((_) {
      debugPrint('Инициализация базы данных завершена');
    }).catchError((e, stackTrace) {
      debugPrint('Ошибка инициализации БД: $e');
    });
  }
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
          update: (_, local, _) => FoodRepository(local: local),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: AppConstants.appName,
            theme: AppTheme.glassLightTheme,
            darkTheme: AppTheme.glassDarkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
