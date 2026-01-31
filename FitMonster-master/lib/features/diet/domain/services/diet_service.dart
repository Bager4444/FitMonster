import 'package:hive/hive.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';

/// Сервис для работы с диетой и питанием
class DietService {
  static const String _profileBoxName = 'user_profile';
  static const String _foodLogsBoxName = 'food_logs';

  /// Получить ID текущего пользователя (локальная реализация)
  static String _getCurrentUserId() {
    // Используем фиксированный ID для локального пользователя
    return 'local_user';
  }

  /// Сохранить профиль пользователя
  static Future<void> saveUserProfile(UserProfile profile) async {
    final box = await Hive.openBox<UserProfile>(_profileBoxName);
    await box.put(profile.userId, profile);
  }

  /// Получить профиль текущего пользователя
  static Future<UserProfile?> getUserProfile() async {
    final userId = _getCurrentUserId();
    final box = await Hive.openBox<UserProfile>(_profileBoxName);
    return box.get(userId);
  }

  /// Удалить профиль пользователя
  static Future<void> deleteUserProfile(String userId) async {
    final box = await Hive.openBox<UserProfile>(_profileBoxName);
    await box.delete(userId);
  }

  /// Удалить все данные текущего пользователя
  static Future<void> clearCurrentUserData() async {
    final userId = _getCurrentUserId();
    await deleteUserProfile(userId);
    await clearUserFoodLogs(userId);
  }

  /// Добавить запись о еде
  static Future<void> addFoodLog(FoodLog log) async {
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    await box.put(log.id, log);
  }

  /// Получить записи за день для текущего пользователя
  static Future<List<FoodLog>> getFoodLogsForDate(DateTime date) async {
    final userId = _getCurrentUserId();
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return box.values
        .where((log) =>
            log.userId == userId &&
            log.timestamp.isAfter(startOfDay) &&
            log.timestamp.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Получить записи за период
  static Future<List<FoodLog>> getFoodLogsForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    return box.values
        .where((log) =>
            log.timestamp.isAfter(start) && log.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Обновить запись о еде
  static Future<void> updateFoodLog(FoodLog log) async {
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    await box.put(log.id, log);
  }

  /// Удалить запись о еде
  static Future<void> deleteFoodLog(String id) async {
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    await box.delete(id);
  }

  /// Получить все записи текущего пользователя
  static Future<List<FoodLog>> getAllFoodLogs() async {
    final userId = _getCurrentUserId();
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    return box.values
        .where((log) => log.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Очистить записи за день для текущего пользователя
  static Future<void> clearFoodLogsForDate(DateTime date) async {
    final userId = _getCurrentUserId();
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final logsToDelete = box.values
        .where((log) =>
            log.userId == userId &&
            log.timestamp.isAfter(startOfDay) &&
            log.timestamp.isBefore(endOfDay))
        .toList();

    for (final log in logsToDelete) {
      await box.delete(log.id);
    }
  }

  /// Очистить все записи конкретного пользователя
  static Future<void> clearUserFoodLogs(String userId) async {
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    final logsToDelete = box.values
        .where((log) => log.userId == userId)
        .toList();

    for (final log in logsToDelete) {
      await box.delete(log.id);
    }
  }

  /// Очистить все записи (для выхода из системы)
  static Future<void> clearAllFoodLogs() async {
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    await box.clear();
  }



  /// Получить статистику за неделю
  static Future<Map<String, int>> getWeeklyStats() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final logs = await getFoodLogsForPeriod(weekAgo, now);

    int totalCalories = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCarbs = 0;

    for (final log in logs) {
      totalCalories += log.calories;
      totalProtein += log.protein;
      totalFat += log.fat;
      totalCarbs += log.carbs;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein.round(),
      'fat': totalFat.round(),
      'carbs': totalCarbs.round(),
      'days': 7,
    };
  }
}
