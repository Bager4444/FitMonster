/// Модель комплекса упражнений
class WorkoutComplex {
  final String id;
  final String name;
  final String description;
  final List<String> exerciseIds; // ID упражнений из базы
  final int estimatedDuration; // в минутах
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final String category; // 'strength', 'cardio', 'flexibility', 'full_body'
  final String imageUrl;
  final List<String> targetMuscles;

  const WorkoutComplex({
    required this.id,
    required this.name,
    required this.description,
    required this.exerciseIds,
    required this.estimatedDuration,
    required this.difficulty,
    required this.category,
    required this.imageUrl,
    required this.targetMuscles,
  });

  /// Получить уровень сложности как число (1-3)
  int get difficultyLevel {
    switch (difficulty) {
      case 'beginner':
        return 1;
      case 'intermediate':
        return 2;
      case 'advanced':
        return 3;
      default:
        return 1;
    }
  }

  /// Получить название сложности на русском
  String get difficultyName {
    switch (difficulty) {
      case 'beginner':
        return 'Начинающий';
      case 'intermediate':
        return 'Средний';
      case 'advanced':
        return 'Продвинутый';
      default:
        return 'Начинающий';
    }
  }

  /// Получить название категории на русском
  String get categoryName {
    switch (category) {
      case 'strength':
        return 'Силовые';
      case 'cardio':
        return 'Кардио';
      case 'flexibility':
        return 'Растяжка';
      case 'full_body':
        return 'Всё тело';
      default:
        return 'Общие';
    }
  }
}