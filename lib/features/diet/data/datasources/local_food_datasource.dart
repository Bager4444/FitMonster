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

  /// Поиск продуктов по названию (без учёта регистра).
  /// Запрос разбивается на слова; продукт подходит, если в названии есть все слова.
  /// Частичное совпадение слов поддерживается (например, «картоф» находит «Картофель»).
  Future<List<FoodItem>> search({
    required String query,
    int maxResults = 30,
    FoodCategory? category,
  }) async {
    final queryLower = query.trim().toLowerCase();
    if (queryLower.isEmpty) return getPopular(maxResults: maxResults);

    // Убираем пустые слова (двойные пробелы и т.п.)
    final queryWords = queryLower
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (queryWords.isEmpty) return getPopular(maxResults: maxResults);

    final results = <FoodItem>[];
    for (final food in _foodsBox.values) {
      if (category != null && food.category != category) continue;

      final nameLower = food.name.toLowerCase();
      final nameRuLower = food.nameRu.toLowerCase();

      final matchesAll = queryWords.every((word) =>
          nameLower.contains(word) || nameRuLower.contains(word));

      if (matchesAll) {
        results.add(food);
        if (results.length >= maxResults) break;
      }
    }

    // Сортировка: точное совпадение выше, затем по началу названия
    results.sort((a, b) {
      final aRu = a.nameRu.toLowerCase();
      final bRu = b.nameRu.toLowerCase();
      if (aRu == queryLower && bRu != queryLower) return -1;
      if (aRu != queryLower && bRu == queryLower) return 1;
      if (aRu.startsWith(queryLower) && !bRu.startsWith(queryLower)) return -1;
      if (!aRu.startsWith(queryLower) && bRu.startsWith(queryLower)) return 1;
      return aRu.compareTo(bRu);
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
