import 'package:hive/hive.dart';
import '../../domain/models/food_item.dart';
import '../../../../core/services/hive_service.dart';

/// Локальный источник данных (Hive)
/// Рефакторинг поисковой логики из FoodDatabaseService
class LocalFoodDatasource {
  Box<FoodItem> get _foodsBox {
    try {
      return Hive.box<FoodItem>(HiveService.foodsBox);
    } catch (e) {
      print('⚠️ Foods box type issue, using cast: $e');
      return Hive.box(HiveService.foodsBox) as Box<FoodItem>;
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

  /// Поиск продуктов по названию
  Future<List<FoodItem>> search({
    required String query,
    int maxResults = 30,
    FoodCategory? category,
  }) async {
    final queryLower = query.toLowerCase().trim();
    if (queryLower.isEmpty) return getPopular(maxResults: maxResults);

    final results = <FoodItem>[];
    final queryWords = queryLower.split(RegExp(r'\s+'));

    for (final food in _foodsBox.values) {
      // Фильтр по категории
      if (category != null && food.category != category) continue;

      // Поиск по всем словам запроса
      final nameLower = food.name.toLowerCase();
      final nameRuLower = food.nameRu.toLowerCase();
      
      final matchesAll = queryWords.every((word) =>
        nameLower.contains(word) || nameRuLower.contains(word)
      );

      if (matchesAll) {
        results.add(food);
        if (results.length >= maxResults) break;
      }
    }

    // Сортировка: точные совпадения выше
    results.sort((a, b) {
      final aExact = a.nameRu.toLowerCase() == queryLower ? 0 : 1;
      final bExact = b.nameRu.toLowerCase() == queryLower ? 0 : 1;
      return aExact.compareTo(bExact);
    });

    return results;
  }

  /// Поиск по штрих-коду
  Future<FoodItem?> findByBarcode(String barcode) async {
    final foodId = _barcodesBox.get(barcode);
    if (foodId != null) {
      return _foodsBox.get(foodId);
    }
    return null;
  }

  /// Получить популярные продукты
  List<FoodItem> getPopular({int maxResults = 20}) {
    return _foodsBox.values.take(maxResults).toList();
  }

  /// Получить продукт по ID
  FoodItem? getById(String id) {
    return _foodsBox.get(id);
  }

  /// Кэшировать продукты из API
  Future<void> cacheItems(List<FoodItem> items) async {
    for (final item in items) {
      await _foodsBox.put(item.id, item);
      if (item.barcode != null && item.barcode!.isNotEmpty) {
        await _barcodesBox.put(item.barcode!, item.id);
      }
    }
    print('💾 Cached ${items.length} food items');
  }

  /// Кэшировать один продукт
  Future<void> cacheItem(FoodItem item) async {
    await _foodsBox.put(item.id, item);
    if (item.barcode != null && item.barcode!.isNotEmpty) {
      await _barcodesBox.put(item.barcode!, item.id);
    }
  }

  /// Проверить, есть ли продукт в кэше
  bool exists(String id) => _foodsBox.containsKey(id);
  
  /// Проверить по штрих-коду
  bool existsByBarcode(String barcode) => _barcodesBox.containsKey(barcode);

  /// Количество продуктов в локальной базе
  int get count => _foodsBox.length;

  /// Очистить кэшированные из API продукты (старше указанного времени)
  Future<int> clearOldCachedItems({Duration maxAge = const Duration(days: 30)}) async {
    final cutoffDate = DateTime.now().subtract(maxAge);
    int deleted = 0;

    final keysToDelete = <String>[];
    
    for (final entry in _foodsBox.toMap().entries) {
      final food = entry.value;
      // Удалять только продукты из API (не локальные)
      if (food.source != null && 
          food.source != 'local' && 
          food.cachedAt != null &&
          food.cachedAt!.isBefore(cutoffDate)) {
        keysToDelete.add(entry.key);
      }
    }

    for (final key in keysToDelete) {
      final food = _foodsBox.get(key);
      if (food?.barcode != null) {
        await _barcodesBox.delete(food!.barcode);
      }
      await _foodsBox.delete(key);
      deleted++;
    }

    if (deleted > 0) {
      print('🗑️ Cleared $deleted old cached items');
    }
    
    return deleted;
  }
}
