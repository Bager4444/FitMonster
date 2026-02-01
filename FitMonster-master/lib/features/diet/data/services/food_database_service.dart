import 'package:hive/hive.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/domain/models/recipe.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// Сервис для работы с локальной базой данных продуктов и рецептов
class FoodDatabaseService {
  static final FoodDatabaseService _instance = FoodDatabaseService._internal();
  factory FoodDatabaseService() => _instance;
  FoodDatabaseService._internal();

  /// Поиск продуктов по названию
  Future<List<FoodItem>> searchFoods(String query) async {
    try {
      final box = await Hive.openBox<FoodItem>('foods');
      final allFoods = box.values.toList();
      
      if (query.isEmpty) return allFoods.take(20).toList();
      
      final results = allFoods.where((food) =>
        food.name.toLowerCase().contains(query.toLowerCase())
      ).take(20).toList();
      
      return results;
    } catch (e) {
      print('❌ Error searching foods: $e');
      return [];
    }
  }

  /// Получить продукт по ID
  Future<FoodItem?> getFoodById(String id) async {
    try {
      final box = await Hive.openBox<FoodItem>('foods');
      return box.get(id);
    } catch (e) {
      print('❌ Error getting food by ID: $e');
      return null;
    }
  }

  /// Добавить продукт в избранное
  Future<void> addToFavorites(String foodId) async {
    try {
      final box = await Hive.openBox<List<String>>('favorites');
      final favorites = box.get('user_favorites', defaultValue: <String>[])!;
      
      if (!favorites.contains(foodId)) {
        favorites.add(foodId);
        await box.put('user_favorites', favorites);
      }
    } catch (e) {
      print('❌ Error adding to favorites: $e');
    }
  }

  /// Получить избранные продукты
  Future<List<FoodItem>> getFavorites() async {
    try {
      final favoritesBox = await Hive.openBox<List<String>>('favorites');
      final foodsBox = await Hive.openBox<FoodItem>('foods');
      
      final favoriteIds = favoritesBox.get('user_favorites', defaultValue: <String>[])!;
      final favorites = <FoodItem>[];
      
      for (final id in favoriteIds) {
        final food = foodsBox.get(id);
        if (food != null) {
          favorites.add(food);
        }
      }
      
      return favorites;
    } catch (e) {
      print('❌ Error getting favorites: $e');
      return [];
    }
  }
}