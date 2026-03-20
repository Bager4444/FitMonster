import 'package:hive/hive.dart';

part 'recipe.g.dart';

/// Рецепт блюда
@HiveType(typeId: 10)
class Recipe extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String nameRu;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final List<RecipeIngredient> ingredients; // Ингредиенты рецепта

  @HiveField(5)
  final List<String> instructions; // Инструкции по приготовлению

  @HiveField(6)
  final int prepTimeMinutes; // Время подготовки в минутах

  @HiveField(7)
  final int cookTimeMinutes; // Время готовки в минутах

  @HiveField(8)
  final int servings; // Количество порций

  @HiveField(9)
  final int totalCalories; // Общая калорийность рецепта

  @HiveField(10)
  final double totalProtein; // Общий белок (г)

  @HiveField(11)
  final double totalFat; // Общий жир (г)

  @HiveField(12)
  final double totalCarbs; // Общие углеводы (г)

  @HiveField(13)
  final String? imageUrl; // URL изображения рецепта

  @HiveField(14)
  final List<String> tags; // Теги (breakfast, lunch, dinner, vegetarian, vegan и т.д.)

  @HiveField(15)
  final String? source; // Источник рецепта

  @HiveField(16)
  final String? sourceUrl; // URL источника

  Recipe({
    required this.id,
    required this.name,
    required this.nameRu,
    this.description,
    required this.ingredients,
    required this.instructions,
    this.prepTimeMinutes = 0,
    this.cookTimeMinutes = 0,
    this.servings = 1,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalFat = 0,
    this.totalCarbs = 0,
    this.imageUrl,
    this.tags = const [],
    this.source,
    this.sourceUrl,
  });

  /// Рассчитать макросы на одну порцию
  RecipeMacros getMacrosPerServing() {
    if (servings <= 0) return RecipeMacros.empty();
    
    return RecipeMacros(
      calories: (totalCalories / servings).round(),
      protein: totalProtein / servings,
      fat: totalFat / servings,
      carbs: totalCarbs / servings,
    );
  }

  /// Конвертация в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameRu': nameRu,
      'description': description,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'instructions': instructions,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'totalCarbs': totalCarbs,
      'imageUrl': imageUrl,
      'tags': tags,
      'source': source,
      'sourceUrl': sourceUrl,
    };
  }

  /// Создание из Map
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      name: map['name'] as String,
      nameRu: map['nameRu'] as String,
      description: map['description'] as String?,
      ingredients: (map['ingredients'] as List<dynamic>)
          .map((i) => RecipeIngredient.fromMap(i as Map<String, dynamic>))
          .toList(),
      instructions: (map['instructions'] as List<dynamic>).cast<String>(),
      prepTimeMinutes: map['prepTimeMinutes'] as int? ?? 0,
      cookTimeMinutes: map['cookTimeMinutes'] as int? ?? 0,
      servings: map['servings'] as int? ?? 1,
      totalCalories: map['totalCalories'] as int? ?? 0,
      totalProtein: (map['totalProtein'] as num?)?.toDouble() ?? 0,
      totalFat: (map['totalFat'] as num?)?.toDouble() ?? 0,
      totalCarbs: (map['totalCarbs'] as num?)?.toDouble() ?? 0,
      imageUrl: map['imageUrl'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      source: map['source'] as String?,
      sourceUrl: map['sourceUrl'] as String?,
    );
  }
}

/// Ингредиент рецепта (typeId 14 — 11 занят RepData)
@HiveType(typeId: 14)
class RecipeIngredient extends HiveObject {
  @HiveField(0)
  final String foodId; // ID продукта из базы (может быть null если продукт не найден)

  @HiveField(1)
  final String foodName; // Название продукта

  @HiveField(2)
  final double amount; // Количество

  @HiveField(3)
  final String unit; // Единица измерения (г, мл, шт, чашка и т.д.)

  @HiveField(4)
  final String unitRu; // Единица измерения на русском

  @HiveField(5)
  final int calories; // Калории этого ингредиента

  @HiveField(6)
  final double protein; // Белок (г)

  @HiveField(7)
  final double fat; // Жир (г)

  @HiveField(8)
  final double carbs; // Углеводы (г)

  RecipeIngredient({
    required this.foodId,
    required this.foodName,
    required this.amount,
    required this.unit,
    required this.unitRu,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
  });

  /// Конвертация в Map
  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'amount': amount,
      'unit': unit,
      'unitRu': unitRu,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
    };
  }

  /// Создание из Map
  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      foodId: map['foodId'] as String,
      foodName: map['foodName'] as String,
      amount: (map['amount'] as num).toDouble(),
      unit: map['unit'] as String,
      unitRu: map['unitRu'] as String,
      calories: map['calories'] as int? ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Макросы рецепта
class RecipeMacros {
  final int calories;
  final double protein;
  final double fat;
  final double carbs;

  const RecipeMacros({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  static RecipeMacros empty() {
    return const RecipeMacros(
      calories: 0,
      protein: 0,
      fat: 0,
      carbs: 0,
    );
  }

  @override
  String toString() {
    return 'RecipeMacros(calories: ${calories}kcal, protein: ${protein}g, fat: ${fat}g, carbs: ${carbs}g)';
  }
}
