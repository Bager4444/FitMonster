import 'package:hive_flutter/hive_flutter.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/data/services/food_data_import_service.dart';
import 'package:fitmonster/features/diet/data/services/food_database_service.dart';

/// Сервис для инициализации базы данных при первом запуске
class DatabaseInitService {
  static final DatabaseInitService _instance = DatabaseInitService._internal();
  factory DatabaseInitService() => _instance;
  DatabaseInitService._internal();

  static const String _initKey = 'database_initialized';

  /// Версия источника продуктов: 1 = старая (USDA/API), 2 = локальный JSON
  static const String _foodsVersionKey = 'foods_data_version';
  static const int _localJsonVersion = 2;

  /// Очистить базу продуктов и сбросить инициализацию, чтобы загрузить данные из JSON.
  /// Вызывается при миграции со старой схемы на локальный foods.json.
  Future<void> clearFoodsAndResetForJson() async {
    final settingsBox = Hive.box(HiveService.settingsBox);
    final foodsBox = Hive.box<FoodItem>(HiveService.foodsBox);
    final barcodesBox = Hive.box<String>(HiveService.barcodesBox);
    await foodsBox.clear();
    await barcodesBox.clear();
    await settingsBox.put(_initKey, false);
    await settingsBox.put(_foodsVersionKey, _localJsonVersion);
    print(
      '🗑️ База продуктов очищена, инициализация сброшена для загрузки из JSON',
    );
  }

  /// Миграция: если база была инициализирована по старой схеме — очистить продукты и сбросить init.
  /// После этого при запуске выполнится загрузка из assets/data/foods.json.
  Future<void> migrateToLocalFoodsIfNeeded() async {
    final settingsBox = Hive.box(HiveService.settingsBox);
    final version = settingsBox.get(_foodsVersionKey, defaultValue: 0) as int;
    if (version >= _localJsonVersion) return;

    print('🔄 Миграция на локальный JSON: очистка старых продуктов...');
    await clearFoodsAndResetForJson();
  }

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

      // Импорт продуктов из локального JSON (основной источник)
      try {
        onProgress?.call('Импорт продуктов из локального файла...');
        await importService.importLocalFoodsJson(
          'assets/data/foods.json',
          fromAssets: true,
          onProgress: (current, total) {
            onProgress?.call('Импорт продуктов: $current / $total');
          },
        );
        onProgress?.call('✅ Продукты импортированы');
      } catch (e) {
        onError?.call(
          'Не удалось загрузить продукты из assets/data/foods.json: $e',
        );
      }

      // Пометить как инициализированную и версию источника продуктов
      final settingsBox = Hive.box(HiveService.settingsBox);
      await settingsBox.put(_initKey, true);
      await settingsBox.put(_foodsVersionKey, _localJsonVersion);

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
