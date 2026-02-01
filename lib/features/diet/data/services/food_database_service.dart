import 'package:hive/hive.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/domain/models/recipe.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// Сервис для работы с локальной базой данных продуктов и рецептов
class FoodDatabaseService {
  static final FoodDatabaseService _instance = FoodDatabaseService._internal();
  factory FoodDatabaseService() => _instance;
  FoodDatabaseService._internal();

  Box<FoodItem> get _foodsBox {
    try {
      return Hive.box<FoodItem>(HiveService.foodsBox);
    } catch (e) {
      // Если коробка открыта с другим типом, используем безопасное приведение
      print('⚠️ Foods box type issue, using cast: $e');
      return Hive.box(HiveService.foodsBox) as Box<FoodItem>;
    }
  }
  
  Box<Recipe> get _recipesBox {
    try {
      return Hive.box<Recipe>(HiveService.recipesBox);
    } catch (e) {
      print('⚠️ Recipes box type issue, using cast: $e');
      return Hive.box(HiveService.recipesBox) as Box<Recipe>;
    }
  }
  
  Box<String> get _barcodesBox {
    try {
      return Hive.box<String>(HiveService.barcodesBox);
    } catch (e) {
      print('⚠️ Barcodes box type issue, using cast: $e');
      return Hive.box(HiveService.barcodesBox) as Box<String>;
    }
  }
  
  Box<List<String>> get _favoritesBox {
    try {
      return Hive.box<List<String>>(HiveService.favoritesBox);
    } catch (e) {
      print('⚠️ Favorites box type issue, using cast: $e');
      return Hive.box(HiveService.favoritesBox) as Box<List<String>>;
    }
  }
  
  Box<List<String>> get _recentBox {
    try {
      return Hive.box<List<String>>(HiveService.recentBox);
    } catch (e) {
      print('⚠️ Recent box type issue, using cast: $e');
      return Hive.box(HiveService.recentBox) as Box<List<String>>;
    }
  }

  /// Поиск продуктов (локальный)
  Future<List<FoodItem>> searchFoods({
    required String query,
    int maxResults = 20,
    FoodCategory? category,
    double? maxCalories,
  }) async {
    final queryLower = query.toLowerCase().trim();
    if (queryLower.isEmpty) {
      return getPopularFoods(maxResults: maxResults);
    }

    final results = <FoodItem>[];

    for (final food in _foodsBox.values) {
      // Фильтр по категории
      if (category != null && food.category != category) continue;

      // Фильтр по калориям
      if (maxCalories != null && food.calories > maxCalories) continue;

      // Поиск по названию (английскому и русскому)
      final matchesName = food.name.toLowerCase().contains(queryLower);
      final matchesNameRu = food.nameRu.toLowerCase().contains(queryLower);

      if (matchesName || matchesNameRu) {
        results.add(food);
        if (results.length >= maxResults) break;
      }
    }

    return results;
  }

  /// Получить популярные продукты
  List<FoodItem> getPopularFoods({int maxResults = 20}) {
    return _foodsBox.values.take(maxResults).toList();
  }

  /// Получить избранные продукты
  Future<List<FoodItem>> getFavoriteFoods(String userId) async {
    final favoriteIds = _favoritesBox.get(userId, defaultValue: <String>[])!;
    final favorites = <FoodItem>[];
    
    for (final id in favoriteIds) {
      final food = _foodsBox.get(id);
      if (food != null) {
        favorites.add(food);
      }
    }
    
    return favorites;
  }

  /// Добавить в избранное
  Future<void> addToFavorites(String userId, String foodId) async {
    final favorites = _favoritesBox.get(userId, defaultValue: <String>[])!;
    if (!favorites.contains(foodId)) {
      favorites.add(foodId);
      await _favoritesBox.put(userId, favorites);
    }
  }

  /// Удалить из избранного
  Future<void> removeFromFavorites(String userId, String foodId) async {
    final favorites = _favoritesBox.get(userId, defaultValue: <String>[])!;
    favorites.remove(foodId);
    await _favoritesBox.put(userId, favorites);
  }

  /// Проверить, в избранном ли продукт
  Future<bool> isFavorite(String userId, String foodId) async {
    final favorites = _favoritesBox.get(userId, defaultValue: <String>[])!;
    return favorites.contains(foodId);
  }

  /// Получить недавно использованные продукты
  Future<List<FoodItem>> getRecentFoods(String userId, {int maxResults = 10}) async {
    final recentIds = _recentBox.get(userId, defaultValue: <String>[])!;
    final recent = <FoodItem>[];
    
    for (final id in recentIds.take(maxResults)) {
      final food = _foodsBox.get(id);
      if (food != null) {
        recent.add(food);
      }
    }
    
    return recent;
  }

  /// Добавить в недавние
  Future<void> addToRecent(String userId, String foodId) async {
    final recent = _recentBox.get(userId, defaultValue: <String>[])!;
    recent.remove(foodId); // Убрать если уже есть
    recent.insert(0, foodId); // Добавить в начало
    if (recent.length > 10) recent.removeLast(); // Оставить только 10
    await _recentBox.put(userId, recent);
  }

  /// Получить детали продукта
  Future<FoodItem?> getFoodDetails(String foodId) async {
    return _foodsBox.get(foodId);
  }

  /// Поиск по штрих-коду
  Future<FoodItem?> findFoodByBarcode(String barcode) async {
    final foodId = _barcodesBox.get(barcode);
    if (foodId != null) {
      return _foodsBox.get(foodId);
    }
    return null;
  }

  /// Получить продукты по категории
  Future<List<FoodItem>> getFoodsByCategory(FoodCategory category, {int maxResults = 50}) async {
    return _foodsBox.values
        .where((food) => food.category == category)
        .take(maxResults)
        .toList();
  }

  /// Поиск рецептов (локальный)
  Future<List<Recipe>> searchRecipes({
    required String query,
    int maxResults = 20,
  }) async {
    final queryLower = query.toLowerCase().trim();
    if (queryLower.isEmpty) {
      return getPopularRecipes(maxResults: maxResults);
    }

    final results = <Recipe>[];

    for (final recipe in _recipesBox.values) {
      final matchesName = recipe.name.toLowerCase().contains(queryLower);
      final matchesNameRu = recipe.nameRu.toLowerCase().contains(queryLower);
      final matchesIngredient = recipe.ingredients.any(
        (ing) => ing.foodName.toLowerCase().contains(queryLower),
      );

      if (matchesName || matchesNameRu || matchesIngredient) {
        results.add(recipe);
        if (results.length >= maxResults) break;
      }
    }

    return results;
  }

  /// Получить популярные рецепты
  List<Recipe> getPopularRecipes({int maxResults = 20}) {
    return _recipesBox.values.take(maxResults).toList();
  }

  /// Получить детали рецепта
  Future<Recipe?> getRecipeDetails(String recipeId) async {
    return _recipesBox.get(recipeId);
  }

  /// Получить количество продуктов в базе
  int getFoodsCount() {
    return _foodsBox.length;
  }

  /// Получить количество рецептов в базе
  int getRecipesCount() {
    return _recipesBox.length;
  }
}
