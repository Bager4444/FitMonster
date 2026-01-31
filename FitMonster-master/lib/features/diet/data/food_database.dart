import '../domain/models/food_item.dart';

/// База продуктов питания
/// Данные основаны на USDA Food Database
class FoodDatabase {
  static final List<FoodItem> _foods = [
    // Фрукты
    FoodItem(
      id: 'fruit_001',
      name: 'Apple',
      nameRu: 'Яблоко',
      calories: 52,
      protein: 0.3,
      fat: 0.2,
      carbs: 14,
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'fruit_002',
      name: 'Banana',
      nameRu: 'Банан',
      calories: 89,
      protein: 1.1,
      fat: 0.3,
      carbs: 23,
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'fruit_003',
      name: 'Orange',
      nameRu: 'Апельсин',
      calories: 47,
      protein: 0.9,
      fat: 0.1,
      carbs: 12,
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'fruit_004',
      name: 'Strawberry',
      nameRu: 'Клубника',
      calories: 32,
      protein: 0.7,
      fat: 0.3,
      carbs: 8,
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'fruit_005',
      name: 'Grapes',
      nameRu: 'Виноград',
      calories: 69,
      protein: 0.7,
      fat: 0.2,
      carbs: 18,
      category: FoodCategory.fruits,
    ),

    // Овощи
    FoodItem(
      id: 'veg_001',
      name: 'Broccoli',
      nameRu: 'Брокколи',
      calories: 34,
      protein: 2.8,
      fat: 0.4,
      carbs: 7,
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'veg_002',
      name: 'Carrot',
      nameRu: 'Морковь',
      calories: 41,
      protein: 0.9,
      fat: 0.2,
      carbs: 10,
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'veg_003',
      name: 'Tomato',
      nameRu: 'Помидор',
      calories: 18,
      protein: 0.9,
      fat: 0.2,
      carbs: 3.9,
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'veg_004',
      name: 'Cucumber',
      nameRu: 'Огурец',
      calories: 15,
      protein: 0.7,
      fat: 0.1,
      carbs: 3.6,
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'veg_005',
      name: 'Spinach',
      nameRu: 'Шпинат',
      calories: 23,
      protein: 2.9,
      fat: 0.4,
      carbs: 3.6,
      category: FoodCategory.vegetables,
    ),

    // Крупы и злаки
    FoodItem(
      id: 'grain_001',
      name: 'Rice (white, cooked)',
      nameRu: 'Рис белый (вареный)',
      calories: 130,
      protein: 2.7,
      fat: 0.3,
      carbs: 28,
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'grain_002',
      name: 'Oatmeal (cooked)',
      nameRu: 'Овсянка (вареная)',
      calories: 71,
      protein: 2.5,
      fat: 1.4,
      carbs: 12,
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'grain_003',
      name: 'Buckwheat (cooked)',
      nameRu: 'Гречка (вареная)',
      calories: 92,
      protein: 3.4,
      fat: 0.6,
      carbs: 20,
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'grain_004',
      name: 'Pasta (cooked)',
      nameRu: 'Макароны (вареные)',
      calories: 131,
      protein: 5,
      fat: 1.1,
      carbs: 25,
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'grain_005',
      name: 'Bread (white)',
      nameRu: 'Хлеб белый',
      calories: 265,
      protein: 9,
      fat: 3.2,
      carbs: 49,
      category: FoodCategory.grains,
    ),

    // Белковые продукты
    FoodItem(
      id: 'protein_001',
      name: 'Chicken breast (cooked)',
      nameRu: 'Куриная грудка (вареная)',
      calories: 165,
      protein: 31,
      fat: 3.6,
      carbs: 0,
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'protein_002',
      name: 'Beef (lean, cooked)',
      nameRu: 'Говядина (постная, вареная)',
      calories: 250,
      protein: 26,
      fat: 15,
      carbs: 0,
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'protein_003',
      name: 'Salmon (cooked)',
      nameRu: 'Лосось (приготовленный)',
      calories: 206,
      protein: 22,
      fat: 13,
      carbs: 0,
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'protein_004',
      name: 'Eggs (boiled)',
      nameRu: 'Яйца (вареные)',
      calories: 155,
      protein: 13,
      fat: 11,
      carbs: 1.1,
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'protein_005',
      name: 'Tuna (canned)',
      nameRu: 'Тунец (консервированный)',
      calories: 116,
      protein: 26,
      fat: 0.8,
      carbs: 0,
      category: FoodCategory.protein,
    ),

    // Молочные продукты
    FoodItem(
      id: 'dairy_001',
      name: 'Milk (2%)',
      nameRu: 'Молоко (2%)',
      calories: 50,
      protein: 3.3,
      fat: 2,
      carbs: 4.8,
      category: FoodCategory.dairy,
    ),
    FoodItem(
      id: 'dairy_002',
      name: 'Greek yogurt',
      nameRu: 'Греческий йогурт',
      calories: 59,
      protein: 10,
      fat: 0.4,
      carbs: 3.6,
      category: FoodCategory.dairy,
    ),
    FoodItem(
      id: 'dairy_003',
      name: 'Cottage cheese',
      nameRu: 'Творог',
      calories: 98,
      protein: 11,
      fat: 4.3,
      carbs: 3.4,
      category: FoodCategory.dairy,
    ),
    FoodItem(
      id: 'dairy_004',
      name: 'Cheddar cheese',
      nameRu: 'Сыр чеддер',
      calories: 403,
      protein: 25,
      fat: 33,
      carbs: 1.3,
      category: FoodCategory.dairy,
    ),
    FoodItem(
      id: 'dairy_005',
      name: 'Butter',
      nameRu: 'Сливочное масло',
      calories: 717,
      protein: 0.9,
      fat: 81,
      carbs: 0.1,
      category: FoodCategory.dairy,
    ),

    // Жиры и масла
    FoodItem(
      id: 'fat_001',
      name: 'Olive oil',
      nameRu: 'Оливковое масло',
      calories: 884,
      protein: 0,
      fat: 100,
      carbs: 0,
      category: FoodCategory.fats,
    ),
    FoodItem(
      id: 'fat_002',
      name: 'Avocado',
      nameRu: 'Авокадо',
      calories: 160,
      protein: 2,
      fat: 15,
      carbs: 9,
      category: FoodCategory.fats,
    ),
    FoodItem(
      id: 'fat_003',
      name: 'Almonds',
      nameRu: 'Миндаль',
      calories: 579,
      protein: 21,
      fat: 50,
      carbs: 22,
      category: FoodCategory.fats,
    ),
    FoodItem(
      id: 'fat_004',
      name: 'Walnuts',
      nameRu: 'Грецкие орехи',
      calories: 654,
      protein: 15,
      fat: 65,
      carbs: 14,
      category: FoodCategory.fats,
    ),
    FoodItem(
      id: 'fat_005',
      name: 'Peanut butter',
      nameRu: 'Арахисовая паста',
      calories: 588,
      protein: 25,
      fat: 50,
      carbs: 20,
      category: FoodCategory.fats,
    ),

    // Сладости
    FoodItem(
      id: 'sweet_001',
      name: 'Chocolate (dark)',
      nameRu: 'Шоколад (темный)',
      calories: 546,
      protein: 5,
      fat: 31,
      carbs: 61,
      category: FoodCategory.sweets,
    ),
    FoodItem(
      id: 'sweet_002',
      name: 'Honey',
      nameRu: 'Мед',
      calories: 304,
      protein: 0.3,
      fat: 0,
      carbs: 82,
      category: FoodCategory.sweets,
    ),
    FoodItem(
      id: 'sweet_003',
      name: 'Ice cream',
      nameRu: 'Мороженое',
      calories: 207,
      protein: 3.5,
      fat: 11,
      carbs: 24,
      category: FoodCategory.sweets,
    ),

    // Напитки
    FoodItem(
      id: 'bev_001',
      name: 'Coffee (black)',
      nameRu: 'Кофе (черный)',
      calories: 2,
      protein: 0.3,
      fat: 0,
      carbs: 0,
      category: FoodCategory.beverages,
    ),
    FoodItem(
      id: 'bev_002',
      name: 'Orange juice',
      nameRu: 'Апельсиновый сок',
      calories: 45,
      protein: 0.7,
      fat: 0.2,
      carbs: 10,
      category: FoodCategory.beverages,
    ),
    FoodItem(
      id: 'bev_003',
      name: 'Green tea',
      nameRu: 'Зеленый чай',
      calories: 1,
      protein: 0,
      fat: 0,
      carbs: 0,
      category: FoodCategory.beverages,
    ),
  ];

  /// Получить все продукты
  static List<FoodItem> getAllFoods() => List.unmodifiable(_foods);

  /// Поиск продуктов по названию
  static List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) return getAllFoods();
    
    final lowerQuery = query.toLowerCase();
    return _foods.where((food) {
      return food.nameRu.toLowerCase().contains(lowerQuery) ||
             food.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Получить продукты по категории
  static List<FoodItem> getFoodsByCategory(FoodCategory category) {
    return _foods.where((food) => food.category == category).toList();
  }

  /// Получить продукт по ID
  static FoodItem? getFoodById(String id) {
    try {
      return _foods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить популярные продукты (первые 10)
  static List<FoodItem> getPopularFoods() {
    return _foods.take(10).toList();
  }
}
