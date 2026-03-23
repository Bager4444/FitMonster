import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';
import 'package:fitmonster/features/diet/domain/models/recipe.dart';
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
  static const String usersBox = 'users';
  static const String foodsBox = 'foods'; // База продуктов
  static const String recipesBox = 'recipes'; // База рецептов
  static const String barcodesBox = 'barcodes'; // Маппинг штрих-кодов -> foodId
  static const String favoritesBox =
      'favorites'; // Избранные продукты (userId -> [foodIds])
  static const String recentBox =
      'recent'; // Недавно использованные (userId -> [foodIds])
  static const String plansBox = 'plans'; // Планы питания
  static const String templatesBox = 'templates'; // Шаблоны приемов пищи
  static const String foodLogsBox = 'food_logs'; // Записи питания (дневник)

  /// Инициализация Hive
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();

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
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(FoodServingAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(RecipeAdapter());
      }
      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(RecipeIngredientAdapter());
      }

      // Открыть боксы с правильными типами
      // Используем проверку, чтобы не открывать уже открытые коробки
      final boxesToOpen = <Future>[];

      if (!Hive.isBoxOpen(userBox)) {
        boxesToOpen.add(Hive.openBox(userBox));
      }
      if (!Hive.isBoxOpen(workoutsBox)) {
        boxesToOpen.add(Hive.openBox(workoutsBox));
      }
      if (!Hive.isBoxOpen(mealsBox)) {
        boxesToOpen.add(Hive.openBox(mealsBox));
      }
      if (!Hive.isBoxOpen(settingsBox)) {
        boxesToOpen.add(Hive.openBox(settingsBox));
      }
      if (!Hive.isBoxOpen(usersBox)) {
        boxesToOpen.add(Hive.openBox(usersBox));
      }
      if (!Hive.isBoxOpen(foodsBox)) {
        boxesToOpen.add(Hive.openBox<FoodItem>(foodsBox));
      }
      if (!Hive.isBoxOpen(recipesBox)) {
        boxesToOpen.add(Hive.openBox<Recipe>(recipesBox));
      }
      if (!Hive.isBoxOpen(barcodesBox)) {
        boxesToOpen.add(Hive.openBox<String>(barcodesBox));
      }
      if (!Hive.isBoxOpen(favoritesBox)) {
        boxesToOpen.add(Hive.openBox<List<String>>(favoritesBox));
      }
      if (!Hive.isBoxOpen(recentBox)) {
        boxesToOpen.add(Hive.openBox<List<String>>(recentBox));
      }
      if (!Hive.isBoxOpen(plansBox)) {
        boxesToOpen.add(Hive.openBox(plansBox));
      }
      if (!Hive.isBoxOpen(templatesBox)) {
        boxesToOpen.add(Hive.openBox(templatesBox));
      }
      if (!Hive.isBoxOpen(foodLogsBox)) {
        boxesToOpen.add(Hive.openBox<FoodLog>(foodLogsBox));
      }

      if (boxesToOpen.isNotEmpty) {
        await Future.wait(boxesToOpen);
      }
      if (kDebugMode) debugPrint('Hive initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing Hive: $e');
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
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving to Hive: $e');
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
      if (kDebugMode) debugPrint('Error getting from Hive: $e');
      return defaultValue;
    }
  }

  /// Удалить данные
  static Future<void> delete({required String box, required String key}) async {
    try {
      await getBox(box).delete(key);
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting from Hive: $e');
      rethrow;
    }
  }

  /// Очистить бокс
  static Future<void> clearBox(String box) async {
    try {
      await getBox(box).clear();
    } catch (e) {
      if (kDebugMode) debugPrint('Error clearing box: $e');
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
        clearBox(usersBox),
        clearBox(foodsBox),
        clearBox(recipesBox),
        clearBox(barcodesBox),
        clearBox(favoritesBox),
        clearBox(recentBox),
        clearBox(plansBox),
        clearBox(templatesBox),
        clearBox(foodLogsBox),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('Error clearing all data: $e');
      rethrow;
    }
  }

  /// Закрыть Hive
  static Future<void> close() async {
    await Hive.close();
  }
}
