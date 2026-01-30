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

  @HiveField(9)
  final String? barcode; // Штрих-код продукта (EAN-13, UPC и т.д.)

  @HiveField(10)
  final List<String> allergens; // Список аллергенов (gluten, dairy, nuts и т.д.)

  @HiveField(11)
  final List<FoodServing> servings; // Различные порции продукта (чашка, штука и т.д.)

  @HiveField(12)
  final bool isVegan; // Веганский продукт

  @HiveField(13)
  final bool isVegetarian; // Вегетарианский продукт

  @HiveField(14)
  final String? source; // Источник: 'local', 'openfoodfacts', 'usda_api'

  @HiveField(15)
  final DateTime? cachedAt; // Когда закэширован (для очистки старых)

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
    this.barcode,
    this.allergens = const [],
    this.servings = const [],
    this.isVegan = false,
    this.isVegetarian = false,
    this.source,
    this.cachedAt,
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
      'barcode': barcode,
      'allergens': allergens,
      'servings': servings.map((s) => s.toMap()).toList(),
      'isVegan': isVegan,
      'isVegetarian': isVegetarian,
      'source': source,
      'cachedAt': cachedAt?.toIso8601String(),
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
      barcode: map['barcode'] as String?,
      allergens: (map['allergens'] as List<dynamic>?)?.cast<String>() ?? [],
      servings: (map['servings'] as List<dynamic>?)?.map((s) => FoodServing.fromMap(s as Map<String, dynamic>)).toList() ?? [],
      isVegan: map['isVegan'] as bool? ?? false,
      isVegetarian: map['isVegetarian'] as bool? ?? false,
      source: map['source'] as String?,
      cachedAt: map['cachedAt'] != null ? DateTime.tryParse(map['cachedAt'] as String) : null,
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

/// Порция продукта (чашка, штука, столовая ложка и т.д.)
@HiveType(typeId: 9)
class FoodServing extends HiveObject {
  @HiveField(0)
  final String name; // Название порции (cup, piece, tablespoon)

  @HiveField(1)
  final String nameRu; // Название на русском (чашка, штука, столовая ложка)

  @HiveField(2)
  final double grams; // Вес порции в граммах

  @HiveField(3)
  final double? quantity; // Количество (например, 1 чашка = 240г)

  FoodServing({
    required this.name,
    required this.nameRu,
    required this.grams,
    this.quantity,
  });

  /// Конвертация в Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameRu': nameRu,
      'grams': grams,
      'quantity': quantity,
    };
  }

  /// Создание из Map
  factory FoodServing.fromMap(Map<String, dynamic> map) {
    return FoodServing(
      name: map['name'] as String,
      nameRu: map['nameRu'] as String,
      grams: (map['grams'] as num).toDouble(),
      quantity: map['quantity'] != null ? (map['quantity'] as num).toDouble() : null,
    );
  }
}
