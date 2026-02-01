/// Результат одного теста
class FitnessTestResult {
  final String exerciseId;
  final String exerciseName;
  final int reps;
  final DateTime testDate;

  const FitnessTestResult({
    required this.exerciseId,
    required this.exerciseName,
    required this.reps,
    required this.testDate,
  });
}

/// Модель теста физической подготовки
class FitnessTest {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String description;
  final int maxReps;
  final DateTime testDate;

  const FitnessTest({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.description,
    required this.maxReps,
    required this.testDate,
  });

  /// Определить уровень подготовки на основе результатов
  String getFitnessLevel() {
    switch (exerciseId) {
      case 'pushups':
        if (maxReps >= 30) return 'advanced';
        if (maxReps >= 15) return 'intermediate';
        return 'beginner';
      
      case 'squats':
        if (maxReps >= 50) return 'advanced';
        if (maxReps >= 25) return 'intermediate';
        return 'beginner';
      
      case 'plank':
        if (maxReps >= 120) return 'advanced'; // секунды
        if (maxReps >= 60) return 'intermediate';
        return 'beginner';
      
      case 'crunches':
        if (maxReps >= 40) return 'advanced';
        if (maxReps >= 20) return 'intermediate';
        return 'beginner';
      
      default:
        if (maxReps >= 20) return 'advanced';
        if (maxReps >= 10) return 'intermediate';
        return 'beginner';
    }
  }
}

/// Результаты всех тестов пользователя
class FitnessTestResults {
  final Map<String, FitnessTest> testResults;
  final DateTime lastTestDate;

  const FitnessTestResults({
    required this.testResults,
    required this.lastTestDate,
  });

  /// Получить общий уровень подготовки
  String getOverallFitnessLevel() {
    if (testResults.isEmpty) return 'beginner';
    
    final levels = testResults.values.map((test) => test.getFitnessLevel()).toList();
    final advancedCount = levels.where((level) => level == 'advanced').length;
    final intermediateCount = levels.where((level) => level == 'intermediate').length;
    
    if (advancedCount >= levels.length * 0.6) return 'advanced';
    if (intermediateCount >= levels.length * 0.5) return 'intermediate';
    return 'beginner';
  }

  /// Получить рекомендуемое количество повторений для упражнения
  int getRecommendedReps(String exerciseId) {
    final test = testResults[exerciseId];
    if (test == null) return 10; // по умолчанию
    
    // Рекомендуем 60-80% от максимума
    return (test.maxReps * 0.7).round();
  }

  /// Получить рекомендуемое количество подходов
  int getRecommendedSets(String exerciseId) {
    final level = testResults[exerciseId]?.getFitnessLevel() ?? 'beginner';
    
    switch (level) {
      case 'advanced':
        return 4;
      case 'intermediate':
        return 3;
      default:
        return 2;
    }
  }
}