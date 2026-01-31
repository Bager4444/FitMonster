import 'package:hive_flutter/hive_flutter.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';
import 'package:fitmonster/features/exercises/domain/models/workout_session.dart';

/// Сервис для работы с локальным хранилищем Hive
class HiveService {
  // Singleton
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Названия боксов
  static const String userBox = 'user';
  static const String workoutsBox = 'workouts';
  static const String mealsBox = 'meals';
  static const String settingsBox = 'settings';

  /// Инициализация Hive
  static Future<void> initialize({String? testPath}) async {
    try {
      if (testPath != null) {
        Hive.init(testPath);
      } else {
        await Hive.initFlutter();
      }
      
      // Регистрация адаптеров
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(GenderAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ActivityLevelAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(GoalAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(FoodItemAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(FoodCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(FoodLogAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(MealTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(RepDataAdapter());
      }
      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(WorkoutStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(WorkoutSessionAdapter());
      }
      
      // Открыть боксы
      await Future.wait([
        Hive.openBox(userBox),
        Hive.openBox(workoutsBox),
        Hive.openBox(mealsBox),
        Hive.openBox(settingsBox),
      ]);
      
      print('✅ Hive initialized successfully');
    } catch (e) {
      print('❌ Error initializing Hive: $e');
      rethrow;
    }
  }

  /// Получить бокс
  static Box getBox(String boxName) {
    return Hive.box(boxName);
  }

  /// Сохранить данные
  static Future<void> put({
    required String box,
    required String key,
    required dynamic value,
  }) async {
    try {
      await getBox(box).put(key, value);
      print('✅ Data saved to Hive: $box/$key');
    } catch (e) {
      print('❌ Error saving to Hive: $e');
      rethrow;
    }
  }

  /// Получить данные
  static dynamic get({
    required String box,
    required String key,
    dynamic defaultValue,
  }) {
    try {
      return getBox(box).get(key, defaultValue: defaultValue);
    } catch (e) {
      print('❌ Error getting from Hive: $e');
      return defaultValue;
    }
  }

  /// Удалить данные
  static Future<void> delete({
    required String box,
    required String key,
  }) async {
    try {
      await getBox(box).delete(key);
      print('✅ Data deleted from Hive: $box/$key');
    } catch (e) {
      print('❌ Error deleting from Hive: $e');
      rethrow;
    }
  }

  /// Очистить бокс
  static Future<void> clearBox(String box) async {
    try {
      await getBox(box).clear();
      print('✅ Box cleared: $box');
    } catch (e) {
      print('❌ Error clearing box: $e');
      rethrow;
    }
  }

  /// Очистить все данные
  static Future<void> clearAll() async {
    try {
      await Future.wait([
        clearBox(userBox),
        clearBox(workoutsBox),
        clearBox(mealsBox),
        clearBox(settingsBox),
      ]);
      print('✅ All Hive data cleared');
    } catch (e) {
      print('❌ Error clearing all data: $e');
      rethrow;
    }
  }

  /// Закрыть Hive
  static Future<void> close() async {
    await Hive.close();
    print('✅ Hive closed');
  }
}
