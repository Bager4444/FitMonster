import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';

/// Сервис для работы с диетой и питанием
class DietService {
  static const String _profileBoxName = 'user_profile';
  static const String _foodLogsBoxName = 'food_logs';
  static const String _keyFoodLogsClearedOnce = 'diet_food_logs_cleared_once_v1';

  /// Однократная очистка записей питания (миграция после исправления фильтра по пользователю)
  static Future<void> runOneTimeFoodLogsClearIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyFoodLogsClearedOnce) == true) return;
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    await box.clear();
    await prefs.setBool(_keyFoodLogsClearedOnce, true);
  }

  /// ID текущего пользователя — данные привязаны к аккаунту (публичный для создания логов с тем же id)
  static String get currentUserId =>
      AuthService().currentUserId ?? 'local_user';

  static String _getCurrentUserId() => currentUserId;

  /// Сохранить профиль пользователя
  static Future<void> saveUserProfile(UserProfile profile) async {
    final box = await Hive.openBox<UserProfile>(_profileBoxName);
    await box.put(profile.userId, profile);
    print('Profile saved with userId: ${profile.userId}');
  }

  /// Получить профиль текущего пользователя
  static Future<UserProfile?> getUserProfile() async {
    final userId = _getCurrentUserId();
    final box = await Hive.openBox<UserProfile>(_profileBoxName);
    final profile = box.get(userId);
    print('Loading profile for userId: $userId, found: ${profile != null}');
    return profile;
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
    await box.flush();
    print('🍽 DietService.addFoodLog: id=${log.id} userId=${log.userId} totalInBox=${box.length}');
  }

  /// Получить записи за день для текущего пользователя
  static Future<List<FoodLog>> getFoodLogsForDate(DateTime date) async {
    final userId = _getCurrentUserId();
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final allLogs = box.values.toList();
    final filtered = allLogs
        .where((log) =>
            log.userId == userId &&
            !log.timestamp.isBefore(startOfDay) &&
            log.timestamp.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    print('🍽 DietService.getFoodLogsForDate: date=$date userId=$userId boxTotal=${box.length} filtered=${filtered.length}');
    if (box.length > 0 && filtered.isEmpty) {
      final sample = allLogs.first;
      print('🍽   sample log in box: userId=${sample.userId} timestamp=${sample.timestamp}');
    }
    return filtered;
  }

  /// Получить записи за период только для текущего пользователя
  static Future<List<FoodLog>> getFoodLogsForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final userId = _getCurrentUserId();
    final box = await Hive.openBox<FoodLog>(_foodLogsBoxName);
    return box.values
        .where((log) =>
            log.userId == userId &&
            log.timestamp.isAfter(start) &&
            log.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Даты, когда была занесена еда в дневник, за последние [days] дней (для стрик-календаря)
  static Future<Set<DateTime>> getFoodLogDatesLastNDays(int days) async {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 1));
    final start = now.subtract(Duration(days: days));
    final logs = await getFoodLogsForPeriod(start, end);
    final dates = <DateTime>{};
    for (final log in logs) {
      dates.add(DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day));
    }
    return dates;
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
