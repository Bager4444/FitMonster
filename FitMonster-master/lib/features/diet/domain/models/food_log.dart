import 'package:hive/hive.dart';
import 'food_item.dart';

part 'food_log.g.dart';

/// Запись в журнале питания
@HiveType(typeId: 7)
class FoodLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String foodId;

  @HiveField(3)
  final String foodName;

  @HiveField(4)
  final double grams;

  @HiveField(5)
  final int calories;

  @HiveField(6)
  final double protein;

  @HiveField(7)
  final double fat;

  @HiveField(8)
  final double carbs;

  @HiveField(9)
  final MealType mealType;

  @HiveField(10)
  final DateTime timestamp;

  FoodLog({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.mealType,
    required this.timestamp,
  });

  /// Создать запись из продукта
  factory FoodLog.fromFood({
    required String id,
    required String userId,
    required FoodItem food,
    required double grams,
    required MealType mealType,
    required DateTime timestamp,
  }) {
    final macros = food.calculateMacros(grams);
    return FoodLog(
      id: id,
      userId: userId,
      foodId: food.id,
      foodName: food.nameRu,
      grams: grams,
      calories: macros.calories,
      protein: macros.protein,
      fat: macros.fat,
      carbs: macros.carbs,
      mealType: mealType,
      timestamp: timestamp,
    );
  }

  /// Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'foodId': foodId,
      'foodName': foodName,
      'grams': grams,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'mealType': mealType.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Создание из Map (Firestore)
  factory FoodLog.fromMap(Map<String, dynamic> map) {
    return FoodLog(
      id: map['id'] as String,
      userId: map['userId'] as String,
      foodId: map['foodId'] as String,
      foodName: map['foodName'] as String,
      grams: (map['grams'] as num).toDouble(),
      calories: map['calories'] as int,
      protein: (map['protein'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      mealType: MealType.values.firstWhere((e) => e.name == map['mealType']),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// Тип приема пищи
@HiveType(typeId: 8)
enum MealType {
  @HiveField(0)
  breakfast,
  
  @HiveField(1)
  lunch,
  
  @HiveField(2)
  dinner,
  
  @HiveField(3)
  snack,
}

extension MealTypeExtension on MealType {
  String get nameRu {
    switch (this) {
      case MealType.breakfast:
        return 'Завтрак';
      case MealType.lunch:
        return 'Обед';
      case MealType.dinner:
        return 'Ужин';
      case MealType.snack:
        return 'Перекус';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍎';
    }
  }
}

/// Итоги дня
class DailySummary {
  final DateTime date;
  final int totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final List<FoodLog> logs;

  const DailySummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    required this.logs,
  });

  /// Создать итоги из списка записей
  factory DailySummary.fromLogs(DateTime date, List<FoodLog> logs) {
    int totalCalories = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCarbs = 0;

    for (final log in logs) {
      totalCalories += log.calories;
      totalProtein += log.protein;
      totalFat += log.fat;
      totalCarbs += log.carbs;
    }

    return DailySummary(
      date: date,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalFat: totalFat,
      totalCarbs: totalCarbs,
      logs: logs,
    );
  }

  /// Получить записи по типу приема пищи
  List<FoodLog> getLogsByMealType(MealType mealType) {
    return logs.where((log) => log.mealType == mealType).toList();
  }

  /// Получить калории по типу приема пищи
  int getCaloriesByMealType(MealType mealType) {
    return getLogsByMealType(mealType)
        .fold(0, (sum, log) => sum + log.calories);
  }
}
