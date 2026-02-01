import '../datasources/local_food_datasource.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_search_result.dart';

/// Репозиторий продуктов — только локальный источник (JSON → Hive)
class FoodRepository {
  final LocalFoodDatasource _local;

  static const int _maxLocalResults = 100;

  FoodRepository({
    required LocalFoodDatasource local,
  }) : _local = local;

  LocalFoodDatasource get local => _local;

  /// Поиск продуктов по названию (локально)
  Future<FoodSearchResult> searchFoods({
    required String query,
    FoodCategory? category,
  }) async {
    if (query.trim().isEmpty) {
      return FoodSearchResult(
        items: _local.getPopular(maxResults: 20),
        source: SearchSource.local,
      );
    }

    final results = await _local.search(
      query: query,
      maxResults: _maxLocalResults,
      category: category,
    );

    return FoodSearchResult(
      items: results,
      source: SearchSource.local,
    );
  }

  /// Поиск по штрих-коду (только локально; в JSON можно добавить поле barcode)
  Future<FoodSearchResult> findByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) {
      return const FoodSearchResult.empty();
    }

    final food = await _local.findByBarcode(barcode);
    if (food != null) {
      return FoodSearchResult(
        items: [food],
        source: SearchSource.local,
      );
    }
    return const FoodSearchResult.empty();
  }

  /// Получить продукт по ID
  Future<FoodItem?> getFoodById(String foodId) async {
    return _local.getById(foodId);
  }

  /// Получить популярные продукты
  List<FoodItem> getPopularFoods({int maxResults = 20}) {
    return _local.getPopular(maxResults: maxResults);
  }

  /// Количество продуктов в базе
  int get localCount => _local.count;

  /// Всегда false — работа только с локальным JSON, без сети
  bool get isOffline => false;
}
