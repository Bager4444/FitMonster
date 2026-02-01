import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'workout_session.g.dart';

/// Данные о повторении
@HiveType(typeId: 11)
class RepData extends HiveObject {
  @HiveField(0)
  final int repNumber;

  @HiveField(1)
  final double? formScore; // Оценка техники (0-100)

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final bool isCorrect; // Правильно ли выполнено

  RepData({
    required this.repNumber,
    this.formScore,
    required this.timestamp,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'repNumber': repNumber,
      'formScore': formScore,
      'timestamp': timestamp.toIso8601String(),
      'isCorrect': isCorrect,
    };
  }

  factory RepData.fromMap(Map<String, dynamic> map) {
    return RepData(
      repNumber: map['repNumber'] as int,
      formScore: map['formScore']?.toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      isCorrect: map['isCorrect'] as bool,
    );
  }
}

/// Статус тренировки
@HiveType(typeId: 12)
enum WorkoutStatus {
  @HiveField(0)
  notStarted,
  
  @HiveField(1)
  inProgress,
  
  @HiveField(2)
  paused,
  
  @HiveField(3)
  completed,
  
  @HiveField(4)
  cancelled,
  
  @HiveField(5)
  failed,
}

/// Сессия тренировки
@HiveType(typeId: 13)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String exerciseId;

  @HiveField(3)
  final String exerciseName;

  @HiveField(4)
  final DateTime startTime;

  @HiveField(5)
  final DateTime? endTime;

  @HiveField(6)
  final int targetReps; // Целевое количество повторений

  @HiveField(7)
  final List<RepData> repsData; // Данные о каждом повторении

  @HiveField(8)
  final WorkoutStatus status;

  @HiveField(9)
  final int caloriesBurned; // Сожженные калории

  @HiveField(10)
  final List<String> mistakes; // Обнаруженные ошибки

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.startTime,
    this.endTime,
    required this.targetReps,
    required this.repsData,
    required this.status,
    required this.caloriesBurned,
    required this.mistakes,
  });

  /// Создать новую сессию
  factory WorkoutSession.create({
    required String id,
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required int targetReps,
  }) {
    return WorkoutSession(
      id: id,
      userId: userId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      startTime: DateTime.now(),
      endTime: null,
      targetReps: targetReps,
      repsData: [],
      status: WorkoutStatus.notStarted,
      caloriesBurned: 0,
      mistakes: [],
    );
  }

  /// Копировать с изменениями
  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? exerciseName,
    DateTime? startTime,
    DateTime? endTime,
    int? targetReps,
    List<RepData>? repsData,
    WorkoutStatus? status,
    int? caloriesBurned,
    List<String>? mistakes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      targetReps: targetReps ?? this.targetReps,
      repsData: repsData ?? this.repsData,
      status: status ?? this.status,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      mistakes: mistakes ?? this.mistakes,
    );
  }

  /// Общее количество повторений
  int get totalReps => repsData.length;

  /// Длительность тренировки
  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    } else if (status == WorkoutStatus.inProgress) {
      return DateTime.now().difference(startTime);
    }
    return Duration.zero;
  }

  /// Средняя оценка техники
  double get averageFormScore {
    if (repsData.isEmpty) return 0.0;
    
    final scores = repsData
        .where((rep) => rep.formScore != null)
        .map((rep) => rep.formScore!)
        .toList();
    
    if (scores.isEmpty) return 0.0;
    
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Лучшая оценка техники
  double get bestFormScore {
    if (repsData.isEmpty) return 0.0;
    
    final scores = repsData
        .where((rep) => rep.formScore != null)
        .map((rep) => rep.formScore!)
        .toList();
    
    if (scores.isEmpty) return 0.0;
    
    return scores.reduce((a, b) => a > b ? a : b);
  }

  /// Процент выполнения
  double get completionPercentage {
    if (targetReps == 0) return 0.0;
    return (totalReps / targetReps * 100).clamp(0.0, 100.0);
  }

  /// Среднее количество повторений в минуту
  double get averageRepsPerMinute {
    if (totalReps == 0 || duration.inSeconds == 0) return 0.0;
    return totalReps / (duration.inSeconds / 60.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'targetReps': targetReps,
      'repsData': repsData.map((rep) => rep.toMap()).toList(),
      'status': status.name,
      'caloriesBurned': caloriesBurned,
      'mistakes': mistakes,
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as String,
      userId: map['userId'] as String,
      exerciseId: map['exerciseId'] as String,
      exerciseName: map['exerciseName'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      targetReps: map['targetReps'] as int,
      repsData: (map['repsData'] as List)
          .map((rep) => RepData.fromMap(Map<String, dynamic>.from(rep)))
          .toList(),
      status: WorkoutStatus.values.firstWhere((e) => e.name == map['status']),
      caloriesBurned: map['caloriesBurned'] as int,
      mistakes: List<String>.from(map['mistakes'] as List),
    );
  }
}

/// Расширения для WorkoutStatus
extension WorkoutStatusExtension on WorkoutStatus {
  /// Цвет статуса
  Color get color {
    switch (this) {
      case WorkoutStatus.notStarted:
        return Colors.grey;
      case WorkoutStatus.inProgress:
        return Colors.blue;
      case WorkoutStatus.paused:
        return Colors.orange;
      case WorkoutStatus.completed:
        return Colors.green;
      case WorkoutStatus.cancelled:
        return Colors.red;
      case WorkoutStatus.failed:
        return Colors.red.shade700;
    }
  }

  /// Отображаемое имя
  String get displayName {
    switch (this) {
      case WorkoutStatus.notStarted:
        return 'Не начата';
      case WorkoutStatus.inProgress:
        return 'В процессе';
      case WorkoutStatus.paused:
        return 'Приостановлена';
      case WorkoutStatus.completed:
        return 'Завершена';
      case WorkoutStatus.cancelled:
        return 'Отменена';
      case WorkoutStatus.failed:
        return 'Неудачна';
    }
  }
}