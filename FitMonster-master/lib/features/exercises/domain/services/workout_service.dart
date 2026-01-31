import 'package:fitmonster/features/exercises/domain/models/workout_session.dart';
import 'package:fitmonster/features/exercises/domain/models/exercise.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/core/services/stats_service.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// Сервис для управления тренировками
class WorkoutService {
  final AuthService _authService = AuthService();
  final StatsService _statsService = StatsService();

  /// Создает новую сессию тренировки
  Future<WorkoutSession> startWorkout({
    required Exercise exercise,
    int targetReps = 10,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    final sessionId = 'workout_${DateTime.now().millisecondsSinceEpoch}';
    final session = WorkoutSession.create(
      id: sessionId,
      userId: userId,
      exerciseId: exercise.id,
      exerciseName: exercise.nameRu,
      targetReps: targetReps,
    );

    // Сохраняем локально
    await HiveService.put(
      box: HiveService.workoutsBox,
      key: sessionId,
      value: session,
    );

    print('✅ Workout started: ${exercise.nameRu}');
    return session;
  }

  /// Добавляет повторение к тренировке
  Future<WorkoutSession> addRep(
    WorkoutSession session, {
    double? formScore,
    bool isCorrect = true,
  }) async {
    final repData = RepData(
      repNumber: session.totalReps + 1,
      formScore: formScore,
      timestamp: DateTime.now(),
      isCorrect: isCorrect,
    );

    final updatedRepsData = List<RepData>.from(session.repsData)..add(repData);
    final updatedSession = session.copyWith(
      repsData: updatedRepsData,
      status: WorkoutStatus.inProgress,
    );

    // Сохраняем обновленную сессию
    await HiveService.put(
      box: HiveService.workoutsBox,
      key: session.id,
      value: updatedSession,
    );

    print('✅ Rep added: ${repData.repNumber}/${session.targetReps}');
    return updatedSession;
  }

  /// Приостанавливает тренировку
  Future<WorkoutSession> pauseWorkout(WorkoutSession session) async {
    final updatedSession = session.copyWith(
      status: WorkoutStatus.paused,
    );

    await HiveService.put(
      box: HiveService.workoutsBox,
      key: session.id,
      value: updatedSession,
    );

    return updatedSession;
  }

  /// Возобновляет тренировку
  Future<WorkoutSession> resumeWorkout(WorkoutSession session) async {
    final updatedSession = session.copyWith(
      status: WorkoutStatus.inProgress,
    );

    await HiveService.put(
      box: HiveService.workoutsBox,
      key: session.id,
      value: updatedSession,
    );

    return updatedSession;
  }

  /// Завершает тренировку
  Future<WorkoutSession> completeWorkout(WorkoutSession session) async {
    final updatedSession = session.copyWith(
      status: WorkoutStatus.completed,
      endTime: DateTime.now(),
    );

    await HiveService.put(
      box: HiveService.workoutsBox,
      key: session.id,
      value: updatedSession,
    );

    // Обновляем статистику
    try {
      await _statsService.updateWorkoutStreak(session.userId);
      print('✅ Workout completed: ${session.exerciseName}');
    } catch (e) {
      print('❌ Error updating stats: $e');
    }

    return updatedSession;
  }

  /// Отменяет тренировку
  Future<WorkoutSession> cancelWorkout(WorkoutSession session) async {
    final updatedSession = session.copyWith(
      status: WorkoutStatus.cancelled,
      endTime: DateTime.now(),
    );

    await HiveService.put(
      box: HiveService.workoutsBox,
      key: session.id,
      value: updatedSession,
    );

    return updatedSession;
  }

  /// Получает историю тренировок пользователя
  Future<List<WorkoutSession>> getUserWorkouts(String userId) async {
    try {
      final workoutBox = HiveService.getBox(HiveService.workoutsBox);
      final allWorkouts = workoutBox.values.cast<WorkoutSession>().toList();
      
      // Фильтруем по пользователю и сортируем по дате
      final userWorkouts = allWorkouts
          .where((workout) => workout.userId == userId)
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      return userWorkouts;
    } catch (e) {
      print('❌ Error getting user workouts: $e');
      return [];
    }
  }

  /// Получает статистику тренировок
  Future<Map<String, dynamic>> getWorkoutStats(String userId) async {
    final workouts = await getUserWorkouts(userId);
    final completedWorkouts = workouts
        .where((w) => w.status == WorkoutStatus.completed)
        .toList();

    if (completedWorkouts.isEmpty) {
      return {
        'totalWorkouts': 0,
        'totalReps': 0,
        'averageFormScore': 0.0,
        'totalDuration': Duration.zero,
      };
    }

    final totalReps = completedWorkouts.fold<int>(
        0, (sum, workout) => sum + workout.totalReps);
    final averageFormScore = completedWorkouts.fold<double>(
        0.0, (sum, workout) => sum + workout.averageFormScore) / 
        completedWorkouts.length;
    final totalDuration = completedWorkouts.fold<Duration>(
        Duration.zero, (sum, workout) => sum + workout.duration);

    return {
      'totalWorkouts': completedWorkouts.length,
      'totalReps': totalReps,
      'averageFormScore': averageFormScore,
      'totalDuration': totalDuration,
    };
  }

  /// Удаляет тренировку
  Future<void> deleteWorkout(String workoutId) async {
    try {
      await HiveService.delete(
        box: HiveService.workoutsBox,
        key: workoutId,
      );
      print('✅ Workout deleted: $workoutId');
    } catch (e) {
      print('❌ Error deleting workout: $e');
      rethrow;
    }
  }
}