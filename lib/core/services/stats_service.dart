import 'package:fitmonster/core/models/user_stats.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// Сервис для работы со статистикой
class StatsService {
  /// Получить статистику пользователя
  Future<UserStats> getUserStats(String userId) async {
    try {
      // Получаем из Hive (локально)
      final localData = HiveService.get(
        box: HiveService.userBox,
        key: 'stats_$userId',
      );

      if (localData != null) {
        if (localData is Map<String, dynamic>) {
          return UserStats.fromMap(localData);
        }
      }

      // Если нет данных, возвращаем пустую статистику
      return UserStats();
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return UserStats();
    }
  }

  /// Сохранить статистику пользователя
  Future<void> saveUserStats(String userId, UserStats stats) async {
    try {
      // Сохраняем локально
      await HiveService.put(
        box: HiveService.userBox,
        key: 'stats_$userId',
        value: stats.toMap(),
      );

      print('✅ User stats saved');
    } catch (e) {
      print('❌ Error saving user stats: $e');
      rethrow;
    }
  }

  /// Обновить стрик после тренировки (учитывается и последняя активность — тренировка или еда)
  Future<void> updateWorkoutStreak(String userId) async {
    final stats = await getUserStats(userId);
    final now = DateTime.now();
    final last = stats.lastActivityDate;
    final daysDiff = now.difference(DateTime(last.year, last.month, last.day)).inDays;

    int newStreak;
    if (stats.totalWorkouts == 0 && stats.lastDietLogDate == null) {
      newStreak = 1;
    } else if (daysDiff == 0) {
      newStreak = stats.workoutStreak;
    } else if (daysDiff == 1) {
      newStreak = stats.workoutStreak + 1;
    } else {
      newStreak = 1;
    }

    await saveUserStats(userId, stats.copyWith(
      workoutStreak: newStreak,
      totalWorkouts: stats.totalWorkouts + 1,
      lastWorkoutDate: now,
    ));
  }

  /// Обновить стрик после занесения еды в дневник (общий стрик: тренировка или еда)
  Future<void> updateDietLogStreak(String userId) async {
    final stats = await getUserStats(userId);
    final now = DateTime.now();
    final last = stats.lastActivityDate;
    final daysDiff = now.difference(DateTime(last.year, last.month, last.day)).inDays;

    int newStreak;
    if (stats.totalWorkouts == 0 && stats.lastDietLogDate == null) {
      newStreak = 1;
    } else if (daysDiff == 0) {
      newStreak = stats.workoutStreak;
    } else if (daysDiff == 1) {
      newStreak = stats.workoutStreak + 1;
    } else {
      newStreak = 1;
    }

    await saveUserStats(userId, stats.copyWith(
      workoutStreak: newStreak,
      lastDietLogDate: now,
    ));
  }

  /// Стрик по датам активности: сколько дней подряд до сегодня включительно (для согласованности с календарём)
  static int computeStreakFromDates(Set<DateTime> activityDates) {
    if (activityDates.isEmpty) return 0;
    final now = DateTime.now();
    var today = DateTime(now.year, now.month, now.day);
    if (!activityDates.contains(today)) return 0;
    var count = 1;
    var date = today.subtract(const Duration(days: 1));
    while (activityDates.contains(date)) {
      count++;
      date = date.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Обновить вес
  Future<void> updateWeight(String userId, double weight) async {
    final stats = await getUserStats(userId);
    final updatedStats = stats.copyWith(currentWeight: weight);
    await saveUserStats(userId, updatedStats);
  }

  /// Добавить калории
  Future<void> addCalories(String userId, int calories) async {
    final stats = await getUserStats(userId);
    final updatedStats = stats.copyWith(
      totalCalories: stats.totalCalories + calories,
    );
    await saveUserStats(userId, updatedStats);
  }
}
