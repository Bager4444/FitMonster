// import 'package:hive/hive.dart'; // TODO: Раскомментировать после генерации

// part 'exercise.g.dart'; // TODO: Сгенерировать с помощью build_runner

/// Модель упражнения
// @HiveType(typeId: 10) // TODO: Раскомментировать после генерации
class Exercise {
  // @HiveField(0)
  final String id;

  // @HiveField(1)
  final String nameRu;

  // @HiveField(2)
  final String nameEn;

  // @HiveField(3)
  final String description;

  // @HiveField(4)
  final ExerciseCategory category;

  // @HiveField(5)
  final ExerciseDifficulty difficulty;

  // @HiveField(6)
  final List<String> muscleGroups;

  // @HiveField(7)
  final String? videoUrl;

  // @HiveField(8)
  final String? imageUrl;

  // @HiveField(9)
  final int caloriesPerMinute;

  // @HiveField(10)
  final List<String> instructions;

  // @HiveField(11)
  final List<String> commonMistakes;

  const Exercise({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.muscleGroups,
    this.videoUrl,
    this.imageUrl,
    required this.caloriesPerMinute,
    required this.instructions,
    required this.commonMistakes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameRu': nameRu,
      'nameEn': nameEn,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'muscleGroups': muscleGroups,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'caloriesPerMinute': caloriesPerMinute,
      'instructions': instructions,
      'commonMistakes': commonMistakes,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      nameRu: map['nameRu'] as String,
      nameEn: map['nameEn'] as String,
      description: map['description'] as String,
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == map['category'],
      ),
      difficulty: ExerciseDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
      ),
      muscleGroups: List<String>.from(map['muscleGroups'] as List),
      videoUrl: map['videoUrl'] as String?,
      imageUrl: map['imageUrl'] as String?,
      caloriesPerMinute: map['caloriesPerMinute'] as int,
      instructions: List<String>.from(map['instructions'] as List),
      commonMistakes: List<String>.from(map['commonMistakes'] as List),
    );
  }
}

/// Категория упражнения
// @HiveType(typeId: 11) // TODO: Раскомментировать после генерации
enum ExerciseCategory {
  // @HiveField(0)
  strength, // Силовые

  // @HiveField(1)
  cardio, // Кардио

  // @HiveField(2)
  flexibility, // Гибкость

  // @HiveField(3)
  balance, // Баланс
}

extension ExerciseCategoryExtension on ExerciseCategory {
  String get nameRu {
    switch (this) {
      case ExerciseCategory.strength:
        return 'Силовые';
      case ExerciseCategory.cardio:
        return 'Кардио';
      case ExerciseCategory.flexibility:
        return 'Гибкость';
      case ExerciseCategory.balance:
        return 'Баланс';
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseCategory.strength:
        return '💪';
      case ExerciseCategory.cardio:
        return '🏃';
      case ExerciseCategory.flexibility:
        return '🧘';
      case ExerciseCategory.balance:
        return '⚖️';
    }
  }
}

/// Сложность упражнения
// @HiveType(typeId: 12) // TODO: Раскомментировать после генерации
enum ExerciseDifficulty {
  // @HiveField(0)
  beginner, // Начинающий

  // @HiveField(1)
  intermediate, // Средний

  // @HiveField(2)
  advanced, // Продвинутый
}

extension ExerciseDifficultyExtension on ExerciseDifficulty {
  String get nameRu {
    switch (this) {
      case ExerciseDifficulty.beginner:
        return 'Начинающий';
      case ExerciseDifficulty.intermediate:
        return 'Средний';
      case ExerciseDifficulty.advanced:
        return 'Продвинутый';
    }
  }

  String get emoji {
    switch (this) {
      case ExerciseDifficulty.beginner:
        return '🟢';
      case ExerciseDifficulty.intermediate:
        return '🟡';
      case ExerciseDifficulty.advanced:
        return '🔴';
    }
  }
}
