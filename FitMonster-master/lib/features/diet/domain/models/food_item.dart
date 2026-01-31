import 'package:hive/hive.dart';

part 'food_item.g.dart';

/// Продукт питания
@HiveType(typeId: 5)
class FoodItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String nameRu;

  @HiveField(3)
  final double calories; // на 100г

  @HiveField(4)
  final double protein; // на 100г

  @HiveField(5)
  final double fat; // на 100г

  @HiveField(6)
  final double carbs; // на 100г

  @HiveField(7)
  final FoodCategory category;

  @HiveField(8)
  final String? brand;

  FoodItem({
    required this.id,
    required this.name,
    required this.nameRu,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.category,
    this.brand,
  });

  /// Рассчитать макросы для определенного веса
  FoodMacros calculateMacros(double grams) {
    final multiplier = grams / 100;
    return FoodMacros(
      calories: (calories * multiplier).round(),
      protein: (protein * multiplier * 10).round() / 10,
      fat: (fat * multiplier * 10).round() / 10,
      carbs: (carbs * multiplier * 10).round() / 10,
    );
  }

  /// Конвертация в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameRu': nameRu,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'category': category.name,
      'brand': brand,
    };
  }

  /// Создание из Map
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      nameRu: map['nameRu'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      category: FoodCategory.values.firstWhere((e) => e.name == map['category']),
      brand: map['brand'] as String?,
    );
  }
}

/// Категория продукта
@HiveType(typeId: 6)
enum FoodCategory {
  @HiveField(0)
  fruits,
  
  @HiveField(1)
  vegetables,
  
  @HiveField(2)
  grains,
  
  @HiveField(3)
  protein,
  
  @HiveField(4)
  dairy,
  
  @HiveField(5)
  fats,
  
  @HiveField(6)
  sweets,
  
  @HiveField(7)
  beverages,
  
  @HiveField(8)
  other,
}

extension FoodCategoryExtension on FoodCategory {
  String get nameRu {
    switch (this) {
      case FoodCategory.fruits:
        return 'Фрукты';
      case FoodCategory.vegetables:
        return 'Овощи';
      case FoodCategory.grains:
        return 'Крупы и злаки';
      case FoodCategory.protein:
        return 'Белковые продукты';
      case FoodCategory.dairy:
        return 'Молочные продукты';
      case FoodCategory.fats:
        return 'Жиры и масла';
      case FoodCategory.sweets:
        return 'Сладости';
      case FoodCategory.beverages:
        return 'Напитки';
      case FoodCategory.other:
        return 'Другое';
    }
  }
}

/// Макросы продукта
class FoodMacros {
  final int calories;
  final double protein;
  final double fat;
  final double carbs;

  const FoodMacros({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  @override
  String toString() {
    return 'FoodMacros(calories: ${calories}kcal, protein: ${protein}g, fat: ${fat}g, carbs: ${carbs}g)';
  }
}
