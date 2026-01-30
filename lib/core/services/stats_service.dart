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

  /// Обновить streak (дни подряд)
  Future<void> updateWorkoutStreak(String userId) async {
    final stats = await getUserStats(userId);
    final now = DateTime.now();
    final lastWorkout = stats.lastWorkoutDate;

    // Проверяем, была ли тренировка вчера
    final daysDiff = now.difference(lastWorkout).inDays;

    int newStreak;
    if (daysDiff == 0) {
      // Сегодня уже была тренировка
      newStreak = stats.workoutStreak;
    } else if (daysDiff == 1) {
      // Вчера была тренировка - продолжаем streak
      newStreak = stats.workoutStreak + 1;
    } else {
      // Пропустили дни - начинаем заново
      newStreak = 1;
    }

    final updatedStats = stats.copyWith(
      workoutStreak: newStreak,
      totalWorkouts: stats.totalWorkouts + 1,
      lastWorkoutDate: now,
    );

    await saveUserStats(userId, updatedStats);
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
