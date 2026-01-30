import '../datasources/local_food_datasource.dart';
import '../datasources/remote_food_datasource.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_search_result.dart';
import '../../../../core/services/connectivity_service.dart';

/// Репозиторий продуктов — объединяет local + remote источники
class FoodRepository {
  final LocalFoodDatasource _local;
  final RemoteFoodDatasource _remote;
  final ConnectivityService _connectivity;

  // Настройки
  static const int _localThreshold = 10;  // Минимум локальных результатов для пропуска API
  static const int _maxLocalResults = 50;
  static const int _maxRemoteResults = 30;

  FoodRepository({
    required LocalFoodDatasource local,
    required RemoteFoodDatasource remote,
    required ConnectivityService connectivity,
  })  : _local = local,
        _remote = remote,
        _connectivity = connectivity;

  /// Локальный datasource (для прямого доступа)
  LocalFoodDatasource get local => _local;

  /// Поиск продуктов (гибридный: local + API)
  Future<FoodSearchResult> searchFoods({
    required String query,
    FoodCategory? category,
  }) async {
    // Пустой запрос — популярные продукты
    if (query.trim().isEmpty) {
      return FoodSearchResult(
        items: _local.getPopular(maxResults: _localThreshold),
        source: SearchSource.local,
      );
    }

    // 1. Локальный поиск (мгновенный)
    final localResults = await _local.search(
      query: query,
      maxResults: _maxLocalResults,
      category: category,
    );

    print('📦 Local search "$query": ${localResults.length} results');

    // 2. Проверить интернет
    final hasConnection = await _connectivity.checkConnection();
    print('🌐 Connection status: ${hasConnection ? "online" : "offline"}');
    
    if (!hasConnection) {
      print('📴 Offline mode, returning local results only');
      return FoodSearchResult.offline(localResults);
    }

    // 3. Если локальных достаточно — вернуть без API
    if (localResults.length >= _localThreshold) {
      print('✅ Enough local results (${localResults.length} >= $_localThreshold), skipping API');
      return FoodSearchResult(
        items: localResults,
        source: SearchSource.local,
      );
    }
    
    print('🔍 Local results (${localResults.length}) < threshold ($_localThreshold), calling API...');

    // 4. Дозапросить из Open Food Facts API
    try {
      final remoteResults = await _remote.search(
        query: query,
        maxResults: _maxRemoteResults,
      );

      if (remoteResults.isEmpty) {
        return FoodSearchResult(
          items: localResults,
          source: SearchSource.local,
        );
      }

      // 5. Дедупликация (по barcode и названию)
      final existingBarcodes = localResults
          .where((f) => f.barcode != null && f.barcode!.isNotEmpty)
          .map((f) => f.barcode!)
          .toSet();
      
      final existingNames = localResults
          .map((f) => f.nameRu.toLowerCase().trim())
          .toSet();

      final newItems = remoteResults.where((item) {
        // Пропустить если совпадает barcode
        if (item.barcode != null && existingBarcodes.contains(item.barcode)) {
          return false;
        }
        // Пропустить если очень похожее название
        final nameNormalized = item.nameRu.toLowerCase().trim();
        if (existingNames.contains(nameNormalized)) {
          return false;
        }
        return true;
      }).toList();

      print('🆕 New items from API: ${newItems.length}');

      // 6. Кэшировать новые
      if (newItems.isNotEmpty) {
        await _local.cacheItems(newItems);
      }

      // 7. Объединить и вернуть
      final combinedResults = [...localResults, ...newItems];
      
      return FoodSearchResult(
        items: combinedResults,
        source: newItems.isNotEmpty ? SearchSource.mixed : SearchSource.local,
        hasMore: remoteResults.length >= _maxRemoteResults,
      );
    } catch (e) {
      print('❌ API search error: $e');
      // При ошибке API — вернуть локальные
      return FoodSearchResult(
        items: localResults,
        source: SearchSource.local,
        error: e.toString(),
      );
    }
  }

  /// Поиск по штрих-коду (гибридный)
  Future<FoodSearchResult> findByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) {
      return const FoodSearchResult.empty();
    }

    print('🔍 Barcode search: $barcode');

    // 1. Локальный поиск
    final localFood = await _local.findByBarcode(barcode);
    if (localFood != null) {
      print('✅ Found in local cache');
      return FoodSearchResult(
        items: [localFood],
        source: SearchSource.local,
      );
    }

    // 2. Проверить интернет
    if (!await _connectivity.checkConnection()) {
      print('📴 Offline, barcode not in local cache');
      return FoodSearchResult.offline([]);
    }

    // 3. Запрос к Open Food Facts API
    try {
      final remoteFood = await _remote.findByBarcode(barcode);
      
      if (remoteFood != null) {
        print('✅ Found via API, caching...');
        // 4. Кэшировать
        await _local.cacheItem(remoteFood);
        
        return FoodSearchResult(
          items: [remoteFood],
          source: SearchSource.remote,
        );
      }

      print('⚠️ Barcode not found anywhere');
      return const FoodSearchResult.empty();
    } catch (e) {
      print('❌ API barcode error: $e');
      return FoodSearchResult.withError(e.toString());
    }
  }

  /// Получить продукт по ID
  Future<FoodItem?> getFoodById(String foodId) async {
    return _local.getById(foodId);
  }

  /// Получить популярные продукты
  List<FoodItem> getPopularFoods({int maxResults = 20}) {
    return _local.getPopular(maxResults: maxResults);
  }

  /// Количество локальных продуктов
  int get localCount => _local.count;

  /// Состояние сети
  bool get isOnline => _connectivity.isOnline;
  bool get isOffline => _connectivity.isOffline;

  /// Очистить старые кэшированные продукты
  Future<int> clearOldCache({Duration maxAge = const Duration(days: 30)}) async {
    return _local.clearOldCachedItems(maxAge: maxAge);
  }
}
