import 'package:hive/hive.dart';

/// Сервис для обновления статистик пользователя
class StatsUpdateService {
  static const String _statsBoxName = 'user_stats';
  
  /// Добавляет повторения к общей статистике
  static Future<void> addRepetitions(int reps) async {
    try {
      final box = await Hive.openBox(_statsBoxName);
      final currentReps = box.get('total_reps', defaultValue: 0) as int;
      await box.put('total_reps', currentReps + reps);
      print('✅ Добавлено $reps повторений. Всего: ${currentReps + reps}');
    } catch (e) {
      print('❌ Ошибка добавления повторений: $e');
    }
  }
  
  /// Добавляет тренировку к общей статистике
  static Future<void> addWorkout() async {
    try {
      final box = await Hive.openBox(_statsBoxName);
      final currentWorkouts = box.get('total_workouts', defaultValue: 0) as int;
      await box.put('total_workouts', currentWorkouts + 1);
      print('✅ Добавлена тренировка. Всего: ${currentWorkouts + 1}');
    } catch (e) {
      print('❌ Ошибка добавления тренировки: $e');
    }
  }
  
  /// Добавляет время к общей статистике (в секундах)
  static Future<void> addTime(int seconds) async {
    try {
      final box = await Hive.openBox(_statsBoxName);
      final currentMinutes = box.get('total_minutes', defaultValue: 0) as int;
      final additionalMinutes = (seconds / 60).ceil();
      await box.put('total_minutes', currentMinutes + additionalMinutes);
      print('✅ Добавлено $additionalMinutes минут. Всего: ${currentMinutes + additionalMinutes}');
    } catch (e) {
      print('❌ Ошибка добавления времени: $e');
    }
  }
  
  /// Получает текущие статистики
  static Future<Map<String, int>> getCurrentStats() async {
    try {
      final box = await Hive.openBox(_statsBoxName);
      return {
        'total_workouts': box.get('total_workouts', defaultValue: 0) as int,
        'total_reps': box.get('total_reps', defaultValue: 0) as int,
        'total_minutes': box.get('total_minutes', defaultValue: 0) as int,
      };
    } catch (e) {
      print('❌ Ошибка получения статистик: $e');
      return {
        'total_workouts': 0,
        'total_reps': 0,
        'total_minutes': 0,
      };
    }
  }
  
  /// Очищает все статистики
  static Future<void> clearStats() async {
    try {
      final box = await Hive.openBox(_statsBoxName);
      await box.clear();
      print('✅ Статистики очищены');
    } catch (e) {
      print('❌ Ошибка очистки статистик: $e');
    }
  }
  
  /// Обрабатывает завершение упражнения
  static Future<void> completeExercise({
    required String exerciseType,
    required int repetitions,
    required int durationSeconds,
  }) async {
    // Добавляем повторения если они есть
    if (repetitions > 0) {
      await addRepetitions(repetitions);
    }
    
    // Добавляем время
    if (durationSeconds > 0) {
      await addTime(durationSeconds);
    }
    
    // Добавляем тренировку если выполнено хотя бы 1 повторение или 10 секунд
    if (repetitions >= 1 || durationSeconds >= 10) {
      await addWorkout();
    }
    
    print('🎯 Упражнение завершено: $exerciseType, повторений: $repetitions, секунд: $durationSeconds');
  }
}