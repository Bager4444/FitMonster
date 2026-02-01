import 'package:hive/hive.dart';

part 'recipe.g.dart';

@HiveType(typeId: 2)
class Recipe extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<String> ingredients;

  @HiveField(4)
  final List<String> instructions;

  @HiveField(5)
  final int prepTime; // в минутах

  @HiveField(6)
  final int cookTime; // в минутах

  @HiveField(7)
  final int servings;

  @HiveField(8)
  final double calories; // на порцию

  @HiveField(9)
  final double protein; // на порцию

  @HiveField(10)
  final double carbs; // на порцию

  @HiveField(11)
  final double fat; // на порцию

  @HiveField(12)
  final String? imageUrl;

  @HiveField(13)
  final String? category;

  @HiveField(14)
  final List<String>? tags;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
    this.category,
    this.tags,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      prepTime: json['prepTime'] ?? 0,
      cookTime: json['cookTime'] ?? 0,
      servings: json['servings'] ?? 1,
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      imageUrl: json['imageUrl']?.toString(),
      category: json['category']?.toString(),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
      'category': category,
      'tags': tags,
    };
  }

  int get totalTime => prepTime + cookTime;

  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, servings: $servings)';
  }
}