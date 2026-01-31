import 'package:fitmonster/features/exercises/domain/models/workout_complex.dart';

/// База данных комплексов упражнений
class WorkoutComplexesDatabase {
  static final List<WorkoutComplex> _complexes = [
    // Комплексы для начинающих
    WorkoutComplex(
      id: 'beginner_full_body',
      name: 'Полное тело для новичков',
      description: 'Базовый комплекс для проработки всех групп мышц. Идеально подходит для начинающих.',
      exerciseIds: ['squats', 'pushups', 'plank', 'lunges'],
      estimatedDuration: 15,
      difficulty: 'beginner',
      category: 'full_body',
      imageUrl: '🏋️‍♀️',
      targetMuscles: ['Ноги', 'Грудь', 'Кор', 'Руки'],
    ),
    
    WorkoutComplex(
      id: 'beginner_cardio',
      name: 'Кардио для начинающих',
      description: 'Лёгкий кардио комплекс для улучшения выносливости и сжигания калорий.',
      exerciseIds: ['jumping_jacks', 'high_knees', 'jump_in_place'],
      estimatedDuration: 10,
      difficulty: 'beginner',
      category: 'cardio',
      imageUrl: '❤️',
      targetMuscles: ['Сердце', 'Ноги'],
    ),

    // Комплексы среднего уровня
    WorkoutComplex(
      id: 'intermediate_strength',
      name: 'Силовая тренировка',
      description: 'Интенсивный силовой комплекс для развития мышечной массы и силы.',
      exerciseIds: ['squats', 'pushups', 'lunges', 'burpees', 'plank'],
      estimatedDuration: 25,
      difficulty: 'intermediate',
      category: 'strength',
      imageUrl: '💪',
      targetMuscles: ['Ноги', 'Грудь', 'Кор', 'Руки', 'Спина'],
    ),

    WorkoutComplex(
      id: 'intermediate_cardio',
      name: 'Интенсивное кардио',
      description: 'Высокоинтенсивная кардио тренировка для максимального сжигания калорий.',
      exerciseIds: ['burpees', 'jumping_jacks', 'mountain_climbers', 'high_knees'],
      estimatedDuration: 20,
      difficulty: 'intermediate',
      category: 'cardio',
      imageUrl: '🔥',
      targetMuscles: ['Сердце', 'Всё тело'],
    ),

    WorkoutComplex(
      id: 'core_focus',
      name: 'Фокус на кор',
      description: 'Специальный комплекс для укрепления мышц кора и пресса.',
      exerciseIds: ['plank', 'crunches', 'bicycle_crunches', 'russian_twists', 'leg_raises'],
      estimatedDuration: 18,
      difficulty: 'intermediate',
      category: 'strength',
      imageUrl: '🎯',
      targetMuscles: ['Пресс', 'Кор', 'Спина'],
    ),

    // Продвинутые комплексы
    WorkoutComplex(
      id: 'advanced_hiit',
      name: 'HIIT тренировка',
      description: 'Высокоинтенсивная интервальная тренировка для опытных спортсменов.',
      exerciseIds: ['burpees', 'mountain_climbers', 'jump_squats', 'burpee_pushup', 'plank_leg_lifts'],
      estimatedDuration: 30,
      difficulty: 'advanced',
      category: 'cardio',
      imageUrl: '⚡',
      targetMuscles: ['Всё тело', 'Сердце'],
    ),

    WorkoutComplex(
      id: 'advanced_strength',
      name: 'Продвинутая силовая',
      description: 'Комплексная силовая тренировка для максимального развития мышц.',
      exerciseIds: ['jump_squats', 'pushups', 'single_leg_deadlift', 'burpees', 'plank_leg_lifts', 'lateral_lunges'],
      estimatedDuration: 35,
      difficulty: 'advanced',
      category: 'strength',
      imageUrl: '🏆',
      targetMuscles: ['Всё тело', 'Сила', 'Баланс'],
    ),

    // Специализированные комплексы
    WorkoutComplex(
      id: 'flexibility_stretch',
      name: 'Растяжка и гибкость',
      description: 'Комплекс упражнений для улучшения гибкости и восстановления мышц.',
      exerciseIds: ['downward_dog', 'side_plank', 'superman', 'glute_bridge'],
      estimatedDuration: 15,
      difficulty: 'beginner',
      category: 'flexibility',
      imageUrl: '🧘‍♀️',
      targetMuscles: ['Спина', 'Ноги', 'Гибкость'],
    ),

    WorkoutComplex(
      id: 'lower_body_focus',
      name: 'Фокус на ноги',
      description: 'Специальный комплекс для проработки мышц ног и ягодиц.',
      exerciseIds: ['squats', 'lunges', 'jump_squats', 'sumo_squats', 'calf_raises', 'glute_bridge'],
      estimatedDuration: 22,
      difficulty: 'intermediate',
      category: 'strength',
      imageUrl: '🦵',
      targetMuscles: ['Ноги', 'Ягодицы', 'Икры'],
    ),

    WorkoutComplex(
      id: 'upper_body_focus',
      name: 'Фокус на верх тела',
      description: 'Комплекс для развития мышц рук, груди и спины.',
      exerciseIds: ['pushups', 'knee_pushups', 'plank', 'superman', 'side_plank'],
      estimatedDuration: 20,
      difficulty: 'intermediate',
      category: 'strength',
      imageUrl: '💪',
      targetMuscles: ['Руки', 'Грудь', 'Спина', 'Плечи'],
    ),
  ];

  /// Получить все комплексы
  static List<WorkoutComplex> getAllComplexes() {
    return List.unmodifiable(_complexes);
  }

  /// Получить комплексы по категории
  static List<WorkoutComplex> getComplexesByCategory(String category) {
    return _complexes.where((complex) => complex.category == category).toList();
  }

  /// Получить комплексы по уровню сложности
  static List<WorkoutComplex> getComplexesByDifficulty(String difficulty) {
    return _complexes.where((complex) => complex.difficulty == difficulty).toList();
  }

  /// Получить комплекс по ID
  static WorkoutComplex? getComplexById(String id) {
    try {
      return _complexes.firstWhere((complex) => complex.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить рекомендуемые комплексы для начинающих
  static List<WorkoutComplex> getRecommendedForBeginners() {
    return _complexes.where((complex) => 
      complex.difficulty == 'beginner' || 
      (complex.difficulty == 'intermediate' && complex.estimatedDuration <= 20)
    ).toList();
  }

  /// Получить все категории
  static List<String> getAllCategories() {
    return _complexes.map((complex) => complex.category).toSet().toList();
  }

  /// Получить все уровни сложности
  static List<String> getAllDifficulties() {
    return _complexes.map((complex) => complex.difficulty).toSet().toList();
  }
}