import 'package:hive_flutter/hive_flutter.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/features/diet/data/services/food_data_import_service.dart';
import 'package:fitmonster/features/diet/data/services/food_database_service.dart';

/// Сервис для инициализации базы данных при первом запуске
class DatabaseInitService {
  static final DatabaseInitService _instance = DatabaseInitService._internal();
  factory DatabaseInitService() => _instance;
  DatabaseInitService._internal();

  static const String _initKey = 'database_initialized';

  /// Проверить, была ли база данных инициализирована
  Future<bool> isInitialized() async {
    final settingsBox = Hive.box(HiveService.settingsBox);
    return settingsBox.get(_initKey, defaultValue: false) as bool;
  }

  /// Инициализировать базу данных (импорт базовых данных)
  /// 
  /// Вызывается один раз при первом запуске приложения
  Future<void> initializeDatabase({
    Function(String message)? onProgress,
    Function(String error)? onError,
  }) async {
    try {
      // Проверка, не инициализирована ли уже
      if (await isInitialized()) {
        onProgress?.call('База данных уже инициализирована');
        return;
      }

      onProgress?.call('Начало инициализации базы данных...');

      final importService = FoodDataImportService();

      // Импорт Foundation Foods из assets (если есть)
      try {
        onProgress?.call('Импорт базовых продуктов...');
        await importService.importUSDAJson(
          'assets/data/usda/FoodData_Central_foundation_food_json_2025-12-18.json',
          fromAssets: true,
          onProgress: (current, total) {
            onProgress?.call('Импорт продуктов: $current / $total');
          },
        );
        onProgress?.call('✅ Продукты импортированы');
      } catch (e) {
        // Файл может отсутствовать - это нормально для базовой версии
        onError?.call('Предупреждение: не удалось импортировать продукты из assets: $e');
      }

      // Импорт базовых рецептов (если есть)
      try {
        onProgress?.call('Импорт базовых рецептов...');
        await importService.importRecipes(
          'assets/data/recipes/basic_recipes.json',
          fromAssets: true,
          onProgress: (current, total) {
            onProgress?.call('Импорт рецептов: $current / $total');
          },
        );
        onProgress?.call('✅ Рецепты импортированы');
      } catch (e) {
        // Файл может отсутствовать - это нормально
        onError?.call('Предупреждение: не удалось импортировать рецепты: $e');
      }

      // Построение поискового индекса
      try {
        onProgress?.call('Построение поискового индекса...');
        await importService.buildSearchIndex();
        onProgress?.call('✅ Индекс построен');
      } catch (e) {
        onError?.call('Предупреждение: не удалось построить индекс: $e');
      }

      // Пометить как инициализированную
      final settingsBox = Hive.box(HiveService.settingsBox);
      await settingsBox.put(_initKey, true);

      onProgress?.call('✅ База данных успешно инициализирована');
    } catch (e) {
      onError?.call('Ошибка инициализации базы данных: $e');
      rethrow;
    }
  }

  /// Сбросить флаг инициализации (для тестирования)
  Future<void> resetInitialization() async {
    final settingsBox = Hive.box(HiveService.settingsBox);
    await settingsBox.put(_initKey, false);
  }
}
