import 'food_item.dart';

/// Источник результатов поиска
enum SearchSource {
  local,  // Только из Hive
  mixed,  // Hive + API
  remote, // Только из API
}

/// Результат поиска продуктов с метаданными
class FoodSearchResult {
  final List<FoodItem> items;
  final bool isOffline;
  final bool hasMore;
  final String? error;
  final SearchSource source;

  const FoodSearchResult({
    required this.items,
    this.isOffline = false,
    this.hasMore = false,
    this.error,
    this.source = SearchSource.local,
  });

  /// Пустой результат
  const FoodSearchResult.empty()
      : items = const [],
        isOffline = false,
        hasMore = false,
        error = null,
        source = SearchSource.local;

  /// Офлайн результат
  factory FoodSearchResult.offline(List<FoodItem> items) {
    return FoodSearchResult(
      items: items,
      isOffline: true,
      source: SearchSource.local,
    );
  }

  /// Результат с ошибкой
  factory FoodSearchResult.withError(String error, [List<FoodItem>? fallbackItems]) {
    return FoodSearchResult(
      items: fallbackItems ?? const [],
      error: error,
      source: SearchSource.local,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get count => items.length;
  bool get hasError => error != null;
  
  /// Первый элемент (для поиска по штрих-коду)
  FoodItem? get first => items.isNotEmpty ? items.first : null;

  @override
  String toString() {
    return 'FoodSearchResult(count: $count, source: $source, offline: $isOffline, error: $error)';
  }
}
