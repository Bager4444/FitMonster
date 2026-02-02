/// Модель статистики пользователя
class UserStats {
  final int workoutStreak; // Дней подряд (тренировка или еда)
  final int totalWorkouts; // Всего тренировок
  final double? currentWeight; // Текущий вес
  final double? targetWeight; // Целевой вес
  final int totalCalories; // Калории за неделю
  final DateTime lastWorkoutDate; // Последняя тренировка
  final DateTime? lastDietLogDate; // Последнее занесение еды в дневник

  UserStats({
    this.workoutStreak = 0,
    this.totalWorkouts = 0,
    this.currentWeight,
    this.targetWeight,
    this.totalCalories = 0,
    DateTime? lastWorkoutDate,
    this.lastDietLogDate,
  }) : lastWorkoutDate = lastWorkoutDate ?? DateTime.now();

  /// Последняя активность (тренировка или еда) — для расчёта стрика
  DateTime get lastActivityDate {
    final diet = lastDietLogDate;
    if (diet == null) return lastWorkoutDate;
    return diet.isAfter(lastWorkoutDate) ? diet : lastWorkoutDate;
  }

  /// Создать из Map (для Firestore/Hive)
  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      workoutStreak: map['workoutStreak'] ?? 0,
      totalWorkouts: map['totalWorkouts'] ?? 0,
      currentWeight: map['currentWeight']?.toDouble(),
      targetWeight: map['targetWeight']?.toDouble(),
      totalCalories: map['totalCalories'] ?? 0,
      lastWorkoutDate: map['lastWorkoutDate'] != null
          ? DateTime.parse(map['lastWorkoutDate'])
          : DateTime.now(),
      lastDietLogDate: map['lastDietLogDate'] != null
          ? DateTime.parse(map['lastDietLogDate'])
          : null,
    );
  }

  /// Конвертировать в Map (для Firestore/Hive)
  Map<String, dynamic> toMap() {
    return {
      'workoutStreak': workoutStreak,
      'totalWorkouts': totalWorkouts,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'totalCalories': totalCalories,
      'lastWorkoutDate': lastWorkoutDate.toIso8601String(),
      if (lastDietLogDate != null) 'lastDietLogDate': lastDietLogDate!.toIso8601String(),
    };
  }

  /// Копировать с изменениями
  UserStats copyWith({
    int? workoutStreak,
    int? totalWorkouts,
    double? currentWeight,
    double? targetWeight,
    int? totalCalories,
    DateTime? lastWorkoutDate,
    DateTime? lastDietLogDate,
  }) {
    return UserStats(
      workoutStreak: workoutStreak ?? this.workoutStreak,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      totalCalories: totalCalories ?? this.totalCalories,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      lastDietLogDate: lastDietLogDate ?? this.lastDietLogDate,
    );
  }
}
