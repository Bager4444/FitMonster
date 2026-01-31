import '../models/user_profile.dart';

/// Калькулятор калорий и макронутриентов
class CalorieCalculator {
  /// Рассчитать базовый метаболизм (BMR) по формуле Mifflin-St Jeor
  /// 
  /// Для мужчин: BMR = 10 * вес(кг) + 6.25 * рост(см) - 5 * возраст(лет) + 5
  /// Для женщин: BMR = 10 * вес(кг) + 6.25 * рост(см) - 5 * возраст(лет) - 161
  static double calculateBMR(UserProfile profile) {
    final baseCalc = (10 * profile.weight) + 
                     (6.25 * profile.height) - 
                     (5 * profile.age);
    
    return profile.gender == Gender.male 
        ? baseCalc + 5 
        : baseCalc - 161;
  }

  /// Рассчитать общий расход калорий (TDEE)
  /// TDEE = BMR * коэффициент активности
  static double calculateTDEE(UserProfile profile) {
    final bmr = calculateBMR(profile);
    return bmr * profile.activityLevel.multiplier;
  }

  /// Рассчитать целевые калории с учетом цели
  static int calculateTargetCalories(UserProfile profile) {
    final tdee = calculateTDEE(profile);
    final target = tdee * profile.goal.calorieMultiplier;
    return target.round();
  }

  /// Рассчитать макронутриенты (белки, жиры, углеводы)
  /// 
  /// Стандартное распределение:
  /// - Белки: 30% калорий (4 ккал/г)
  /// - Жиры: 30% калорий (9 ккал/г)
  /// - Углеводы: 40% калорий (4 ккал/г)
  static Macros calculateMacros(UserProfile profile) {
    final targetCalories = calculateTargetCalories(profile);
    
    // Белки: 30% калорий
    final proteinCalories = targetCalories * 0.30;
    final proteinGrams = (proteinCalories / 4).round();
    
    // Жиры: 30% калорий
    final fatCalories = targetCalories * 0.30;
    final fatGrams = (fatCalories / 9).round();
    
    // Углеводы: 40% калорий
    final carbCalories = targetCalories * 0.40;
    final carbGrams = (carbCalories / 4).round();
    
    return Macros(
      protein: proteinGrams,
      fat: fatGrams,
      carbs: carbGrams,
      calories: targetCalories,
    );
  }

  /// Рассчитать идеальный вес по формуле Devine
  /// 
  /// Для мужчин: 50 кг + 2.3 кг на каждый дюйм выше 5 футов
  /// Для женщин: 45.5 кг + 2.3 кг на каждый дюйм выше 5 футов
  static double calculateIdealWeight(UserProfile profile) {
    final heightInInches = profile.height / 2.54; // см в дюймы
    final inchesOver5Feet = heightInInches - 60; // 5 футов = 60 дюймов
    
    if (inchesOver5Feet <= 0) {
      return profile.gender == Gender.male ? 50.0 : 45.5;
    }
    
    final baseWeight = profile.gender == Gender.male ? 50.0 : 45.5;
    return baseWeight + (2.3 * inchesOver5Feet);
  }

  /// Рассчитать индекс массы тела (BMI)
  static double calculateBMI(double weight, double height) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Получить категорию BMI
  static BMICategory getBMICategory(double bmi) {
    if (bmi < 18.5) return BMICategory.underweight;
    if (bmi < 25) return BMICategory.normal;
    if (bmi < 30) return BMICategory.overweight;
    return BMICategory.obese;
  }

  /// Рассчитать время достижения цели (в неделях)
  /// 
  /// Предполагается потеря/набор 0.5 кг в неделю (безопасный темп)
  static int calculateWeeksToGoal(UserProfile profile, double targetWeight) {
    final weightDifference = (targetWeight - profile.weight).abs();
    const safeWeeklyChange = 0.5; // кг в неделю
    return (weightDifference / safeWeeklyChange).ceil();
  }
}

/// Макронутриенты
class Macros {
  final int protein; // граммы
  final int fat; // граммы
  final int carbs; // граммы
  final int calories; // ккал

  const Macros({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
  });

  /// Копирование с изменениями
  Macros copyWith({
    int? protein,
    int? fat,
    int? carbs,
    int? calories,
  }) {
    return Macros(
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      calories: calories ?? this.calories,
    );
  }

  /// Сложение макросов
  Macros operator +(Macros other) {
    return Macros(
      protein: protein + other.protein,
      fat: fat + other.fat,
      carbs: carbs + other.carbs,
      calories: calories + other.calories,
    );
  }

  /// Вычитание макросов
  Macros operator -(Macros other) {
    return Macros(
      protein: protein - other.protein,
      fat: fat - other.fat,
      carbs: carbs - other.carbs,
      calories: calories - other.calories,
    );
  }

  /// Процент от целевых макросов
  double percentOf(Macros target) {
    if (target.calories == 0) return 0;
    return (calories / target.calories) * 100;
  }

  @override
  String toString() {
    return 'Macros(protein: ${protein}g, fat: ${fat}g, carbs: ${carbs}g, calories: ${calories}kcal)';
  }
}

/// Категория BMI
enum BMICategory {
  underweight,
  normal,
  overweight,
  obese,
}

extension BMICategoryExtension on BMICategory {
  String get description {
    switch (this) {
      case BMICategory.underweight:
        return 'Недостаточный вес';
      case BMICategory.normal:
        return 'Нормальный вес';
      case BMICategory.overweight:
        return 'Избыточный вес';
      case BMICategory.obese:
        return 'Ожирение';
    }
  }

  String get recommendation {
    switch (this) {
      case BMICategory.underweight:
        return 'Рекомендуется набор веса';
      case BMICategory.normal:
        return 'Поддерживайте текущий вес';
      case BMICategory.overweight:
        return 'Рекомендуется снижение веса';
      case BMICategory.obese:
        return 'Необходимо снижение веса';
    }
  }
}
