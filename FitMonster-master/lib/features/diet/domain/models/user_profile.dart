import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// Профиль пользователя для расчета калорий
@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final int age;

  @HiveField(2)
  final double height; // в см

  @HiveField(3)
  final double weight; // в кг

  @HiveField(4)
  final Gender gender;

  @HiveField(5)
  final ActivityLevel activityLevel;

  @HiveField(6)
  final Goal goal;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final List<String> allergies; // Список аллергий

  @HiveField(10)
  final List<String> contraindications; // Противопоказания

  @HiveField(11)
  final String? name; // Имя пользователя

  UserProfile({
    required this.userId,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.createdAt,
    required this.updatedAt,
    this.allergies = const [],
    this.contraindications = const [],
    this.name,
  });

  /// Создать пустой профиль
  factory UserProfile.empty() {
    return UserProfile(
      userId: '',
      age: 25,
      height: 170,
      weight: 70,
      gender: Gender.male,
      activityLevel: ActivityLevel.moderate,
      goal: Goal.maintain,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Копирование с изменениями
  UserProfile copyWith({
    String? userId,
    int? age,
    double? height,
    double? weight,
    Gender? gender,
    ActivityLevel? activityLevel,
    Goal? goal,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? allergies,
    List<String>? contraindications,
    String? name,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      allergies: allergies ?? this.allergies,
      contraindications: contraindications ?? this.contraindications,
      name: name ?? this.name,
    );
  }

  /// Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender.name,
      'activityLevel': activityLevel.name,
      'goal': goal.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'allergies': allergies,
      'contraindications': contraindications,
      'name': name,
    };
  }

  /// Создание из Map (Firestore)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String,
      age: map['age'] as int,
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      gender: Gender.values.firstWhere((e) => e.name == map['gender']),
      activityLevel: ActivityLevel.values.firstWhere((e) => e.name == map['activityLevel']),
      goal: Goal.values.firstWhere((e) => e.name == map['goal']),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      allergies: map['allergies'] != null ? List<String>.from(map['allergies']) : [],
      contraindications: map['contraindications'] != null ? List<String>.from(map['contraindications']) : [],
      name: map['name'] as String?,
    );
  }
}

/// Пол
@HiveType(typeId: 2)
enum Gender {
  @HiveField(0)
  male,
  
  @HiveField(1)
  female,
}

/// Уровень активности
@HiveType(typeId: 3)
enum ActivityLevel {
  @HiveField(0)
  sedentary, // Сидячий образ жизни
  
  @HiveField(1)
  light, // Легкая активность (1-3 дня в неделю)
  
  @HiveField(2)
  moderate, // Умеренная активность (3-5 дней в неделю)
  
  @HiveField(3)
  active, // Высокая активность (6-7 дней в неделю)
  
  @HiveField(4)
  veryActive, // Очень высокая активность (2 раза в день)
}

/// Цель
@HiveType(typeId: 4)
enum Goal {
  @HiveField(0)
  lose, // Похудение
  
  @HiveField(1)
  maintain, // Поддержание веса
  
  @HiveField(2)
  gain, // Набор массы
}

/// Расширения для удобства
extension ActivityLevelExtension on ActivityLevel {
  /// Коэффициент активности для расчета калорий
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }

  /// Описание на русском
  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Сидячий образ жизни';
      case ActivityLevel.light:
        return 'Легкая активность (1-3 дня/неделю)';
      case ActivityLevel.moderate:
        return 'Умеренная активность (3-5 дней/неделю)';
      case ActivityLevel.active:
        return 'Высокая активность (6-7 дней/неделю)';
      case ActivityLevel.veryActive:
        return 'Очень высокая активность (2 раза/день)';
    }
  }
}

extension GoalExtension on Goal {
  /// Процент калорийного дефицита/профицита
  double get calorieMultiplier {
    switch (this) {
      case Goal.lose:
        return 0.85; // -15% для похудения
      case Goal.maintain:
        return 1.0; // 0% для поддержания
      case Goal.gain:
        return 1.15; // +15% для набора массы
    }
  }

  /// Описание на русском
  String get description {
    switch (this) {
      case Goal.lose:
        return 'Похудение (-15%)';
      case Goal.maintain:
        return 'Поддержание веса';
      case Goal.gain:
        return 'Набор массы (+15%)';
    }
  }
}
/// Дополнительные поля и методы для UserProfile
extension UserProfileExtension on UserProfile {
  /// Инициалы пользователя
  String get initials {
    // Простая реализация - первые буквы имени
    return 'U'; // Заглушка, так как у нас нет поля name
  }

  /// Отображаемое имя
  String get displayName {
    return name ?? 'Пользователь';
  }

  /// Количество выполненных упражнений
  int get completedExercises {
    return 0; // Заглушка - можно получать из статистики
  }

  /// Любимое упражнение
  String get favoriteExercise {
    return 'Отжимания'; // Заглушка
  }

  /// Индекс массы тела
  double get bmi {
    if (height <= 0 || weight <= 0) return 0.0;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Категория ИМТ
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Недостаточный вес';
    if (bmiValue < 25) return 'Нормальный вес';
    if (bmiValue < 30) return 'Избыточный вес';
    return 'Ожирение';
  }
}