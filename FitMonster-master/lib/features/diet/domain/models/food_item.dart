import 'package:hive/hive.dart';

part 'food_item.g.dart';

@HiveType(typeId: 1)
class FoodItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double calories; // на 100г

  @HiveField(3)
  final double protein; // на 100г

  @HiveField(4)
  final double carbs; // на 100г

  @HiveField(5)
  final double fat; // на 100г

  @HiveField(6)
  final double fiber; // на 100г

  @HiveField(7)
  final String? barcode;

  @HiveField(8)
  final String? brand;

  @HiveField(9)
  final String? category;

  @HiveField(10)
  final Map<String, dynamic>? nutrients; // дополнительные нутриенты

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    this.barcode,
    this.brand,
    this.category,
    this.nutrients,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      barcode: json['barcode']?.toString(),
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      nutrients: json['nutrients'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'barcode': barcode,
      'brand': brand,
      'category': category,
      'nutrients': nutrients,
    };
  }

  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, calories: $calories)';
  }
}