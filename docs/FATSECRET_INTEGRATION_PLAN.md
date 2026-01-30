# План разработки модуля диеты с локальной базой данных

**Дата создания:** 18 января 2026  
**Последнее обновление:** 18 января 2026  
**Статус:** Планирование  
**Приоритет:** Высокий  
**Подход:** Локальная база данных (без API, без атрибуции)

## 🎯 Краткое резюме

План включает:
- ✅ **Базовую функциональность:** импорт данных, поиск, сканирование штрих-кодов
- ✅ **Улучшения UX/UI:** Dashboard с графиками, умные рекомендации, статистика
- ✅ **Планирование питания:** планирование на день/неделю, шаблоны
- ✅ **Мотивация:** достижения, Streak, бейджи
- ✅ **Быстрые действия:** избранные продукты, недавние, копирование дней

**Всего этапов:** 16 этапов разработки

## 📋 Содержание

1. [Обзор источников данных](#обзор-источников-данных)
2. [Текущее состояние модуля диеты](#текущее-состояние-модуля-диеты)
3. [План разработки](#план-разработки)
4. [Технические детали](#технические-детали)
5. [Этапы разработки](#этапы-разработки)
6. [Риски и ограничения](#риски-и-ограничения)

---

## 🔍 Обзор источников данных

### USDA FoodData Central (Продукты)

**USDA FoodData Central** ([https://fdc.nal.usda.gov](https://fdc.nal.usda.gov)) — открытая база данных продуктов питания от Министерства сельского хозяйства США:

- **~375,000 продуктов** с полной информацией о нутриентах
- **Бесплатно и открыто** — можно скачать и использовать без ограничений
- **Без атрибуции** — не требуется указывать источник
- **Полная информация:**
  - Калории, белки, жиры, углеводы
  - Витамины и минералы
  - Размеры порций
  - Категории продуктов
- **Формат данных:** CSV, JSON, Excel
- **Обновления:** Регулярные обновления базы данных

### Open Food Facts (Дополнительные продукты)

**Open Food Facts** ([https://world.openfoodfacts.org](https://world.openfoodfacts.org)) — открытая база продуктов с штрих-кодами:

- **Миллионы продуктов** (включая брендированные)
- **Штрих-коды (UPC/EAN)** для сканирования
- **Бесплатно и открыто**
- **Формат:** CSV, JSON, SQL дампы
- **Обновления:** Ежедневные обновления

### Датасеты рецептов

**Источники рецептов:**
- **Kaggle датасеты** — тысячи готовых датасетов с рецептами
- **Recipe1M+** — 1+ миллион рецептов (требует обработки)
- **Epicurious Recipes** — открытые данные рецептов
- **GitHub репозитории** — готовые JSON/CSV файлы с рецептами

**Что включают:**
- Ингредиенты с количеством
- Пошаговые инструкции
- Время приготовления
- Количество порций
- Изображения (URL)

### Преимущества локального подхода

✅ **Нет зависимости от API** — работа офлайн  
✅ **Нет лимитов запросов** — неограниченный доступ  
✅ **Нет атрибуции** — полная свобода использования  
✅ **Быстрый доступ** — данные локально, мгновенный поиск  
✅ **Полный контроль** — можно модифицировать и расширять  
✅ **Бесплатно** — все источники открытые и бесплатные

---

## 📊 Текущее состояние модуля диеты

### Реализовано

✅ **Профиль пользователя**
- Ввод антропометрических данных
- Расчет калорий (Mifflin-St Jeor)
- Расчет БЖУ
- Аллергии и противопоказания

✅ **Журнал питания**
- Добавление продуктов вручную
- Отслеживание по приемам пищи (завтрак, обед, ужин, перекусы)
- Прогресс-бары калорий и макросов
- Ежедневные итоги

✅ **Локальная база данных**
- ~40 продуктов в `FoodDatabase`
- Простой поиск по названию
- Категории продуктов

### Ограничения текущей реализации

❌ **Маленькая база продуктов** (~40 vs 1.9M в FatSecret)  
❌ **Нет сканирования штрих-кодов**  
❌ **Нет распознавания изображений**  
❌ **Нет обработки естественного языка** ("стакан молока")  
❌ **Нет рецептов**  
❌ **Ограниченная информация об аллергенах**  
❌ **Нет брендированных продуктов**  
❌ **Нет информации о ресторанах**

---

## 🎯 План разработки

### Цели разработки

#### Базовые функции
1. **Расширить базу продуктов** с 40 до 375,000+ (USDA) + миллионы (Open Food Facts)
2. **Добавить сканирование штрих-кодов** используя Open Food Facts базу
3. **Улучшить поиск** с автодополнением, фильтрами, избранными
4. **Добавить рецепты** из открытых датасетов
5. **Улучшить информацию об аллергенах** из USDA и Open Food Facts
6. **Офлайн-работа** — все данные локально

#### Улучшения UX/UI
7. **Dashboard с визуализацией** — графики прогресса, статистика
8. **Умные рекомендации** — подсказки для достижения целей
9. **Планирование питания** — планирование на день/неделю
10. **Статистика и аналитика** — детальный анализ за периоды
11. **Мотивация** — достижения, Streak, бейджи
12. **Быстрые действия** — избранные, шаблоны, копирование дней
13. **Навигация по истории** — выбор любой даты, просмотр прошлого

### Архитектура решения

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (Flutter)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Dashboard    │  │ FoodLogPage   │  │ Statistics   │  │
│  │ (Главный)    │  │ (Журнал)     │  │ (Аналитика)  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │          │
│  ┌──────▼─────────────────▼─────────────────▼──────┐   │
│  │  AddFoodDialog  │  MealPlanning  │  RecipeSearch │  │
│  └──────────────────────────────────────────────────┘   │
└─────────┼─────────────────┼─────────────────┼──────────┘
          │                 │                 │
┌─────────┼─────────────────┼─────────────────┼──────────┐
│         │                 │                 │          │
│  ┌──────▼─────────────────▼─────────────────▼──────┐   │
│  │         Services Layer (Dart)                    │   │
│  │  ┌──────────────────────────────────────────┐  │   │
│  │  │ FoodDatabaseService                        │  │   │
│  │  │  - searchFoods()                           │  │   │
│  │  │  - getFavorites() / getRecent()            │  │   │
│  │  │  - findFoodByBarcode()                     │  │   │
│  │  └──────────────────────────────────────────┘  │   │
│  │  ┌──────────────────────────────────────────┐  │   │
│  │  │ RecommendationService                     │  │   │
│  │  │  - getRecommendations()                    │  │   │
│  │  └──────────────────────────────────────────┘  │   │
│  │  ┌──────────────────────────────────────────┐  │   │
│  │  │ DietStatisticsService                     │  │   │
│  │  │  - getPeriodStatistics()                  │  │   │
│  │  │  - getCaloriesChartData()                 │  │   │
│  │  └──────────────────────────────────────────┘  │   │
│  │  ┌──────────────────────────────────────────┐  │   │
│  │  │ MealPlanningService                       │  │   │
│  │  │  - savePlan() / copyPlan()                │  │   │
│  │  └──────────────────────────────────────────┘  │   │
│  └──────┬──────────────────────────────────────────┘   │
│         │                                               │
│  ┌──────▼──────────────────────────────────────────┐   │
│  │      Local Database (Hive)                        │   │
│  │  ┌──────────────────────────────────────────┐   │   │
│  │  │  foods_box: 375,000+ продуктов (USDA)        │   │   │
│  │  │  recipes_box: 10,000+ рецептов            │   │   │
│  │  │  barcodes_box: штрих-коды (Open FF)       │   │   │
│  │  │  favorites_box: избранные продукты        │   │   │
│  │  │  recent_box: недавно использованные        │   │   │
│  │  │  plans_box: планы питания                  │   │   │
│  │  │  templates_box: шаблоны приемов пищи        │   │   │
│  │  └──────────────────────────────────────────┘   │   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Data Import Service (одноразовый импорт)        │   │
│  │  - Парсинг USDA CSV/JSON                         │   │
│  │  - Парсинг Open Food Facts                       │   │
│  │  - Импорт рецептов из датасетов                  │   │
│  │  - Индексация для быстрого поиска                │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## 🔧 Технические детали

### 1. Скачивание и подготовка данных

#### USDA FoodData Central

**Шаги:**
1. Перейти на [fdc.nal.usda.gov/download-datasets.html](https://fdc.nal.usda.gov/download-datasets.html)
2. Скачать **Foundation Foods** или **Branded Foods** (CSV или JSON)
3. Размер файла: ~100-500 MB (в зависимости от выбора)
4. Формат: CSV с разделителями или JSON

**Рекомендуемый набор данных:**
- **Foundation Foods** — базовые продукты (~8,000 записей, компактный)
- **Branded Foods** — брендированные продукты (~300,000+ записей, большой)

#### Open Food Facts

**Шаги:**
1. Перейти на [world.openfoodfacts.org/data](https://world.openfoodfacts.org/data)
2. Скачать **CSV дамп** или **JSON дамп**
3. Размер: ~1-2 GB (полная база)
4. Или использовать **API для выборочной загрузки**

#### Рецепты

**Источники:**
1. **Kaggle** — поиск "recipe dataset" или "cooking recipes"
2. **GitHub** — готовые JSON/CSV файлы
3. **Recipe1M+** — большой датасет (требует обработки)

**Рекомендуемый формат:**
- JSON с полями: name, ingredients, instructions, nutrition, servings

### 2. Структура хранения в Hive

```dart
// Боксы Hive
static const String foodsBox = 'foods';           // Все продукты
static const String recipesBox = 'recipes';      // Все рецепты
static const String barcodesBox = 'barcodes';    // Индекс штрих-кодов
static const String searchIndexBox = 'search_index'; // Индекс для поиска
```

### 4. Модели данных

#### Расширение FoodItem

```dart
class FoodItem {
  // Существующие поля
  final String id;
  final String name;
  final String nameRu;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final FoodCategory category;
  final String? brand;
  
  // Новые поля из FatSecret
  final String? fatSecretId;        // ID продукта в FatSecret
  final String? barcode;             // UPC/EAN код
  final String? imageUrl;           // URL изображения продукта
  final List<String> allergens;     // Список аллергенов
  final bool isVegan;                // Веганский продукт
  final bool isVegetarian;           // Вегетарианский продукт
  final List<FoodServing> servings;  // Различные порции
  final String? description;         // Описание продукта
  final DateTime? lastUpdated;       // Дата последнего обновления
}

class FoodServing {
  final String servingId;
  final String description;          // "1 чашка", "100г", "1 порция"
  final double grams;                 // Вес в граммах
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
}
```

### 3. Сервисный слой

```dart
class FoodDatabaseService {
  final Box<FoodItem> _foodsBox;
  final Box<Recipe> _recipesBox;
  final Box<String> _barcodesBox; // barcode -> foodId mapping
  final Box<List<String>> _searchIndexBox; // search terms -> foodIds
  final Box<List<String>> _favoritesBox; // userId -> [foodIds]
  final Box<List<String>> _recentBox; // userId -> [foodIds] (последние 10)
  
  /// Поиск продуктов (локальный)
  Future<List<FoodItem>> searchFoods({
    required String query,
    int maxResults = 20,
    FoodCategory? category,
    double? maxCalories,
  }) async {
    final queryLower = query.toLowerCase();
    final results = <FoodItem>[];
    
    for (final food in _foodsBox.values) {
      // Фильтр по категории
      if (category != null && food.category != category) continue;
      
      // Фильтр по калориям
      if (maxCalories != null && food.calories > maxCalories) continue;
      
      // Поиск по названию
      if (queryLower.isEmpty || 
          food.nameRu.toLowerCase().contains(queryLower) ||
          food.name.toLowerCase().contains(queryLower)) {
        results.add(food);
        if (results.length >= maxResults) break;
      }
    }
    
    return results;
  }
  
  /// Получить избранные продукты
  Future<List<FoodItem>> getFavoriteFoods(String userId) async {
    final favoriteIds = _favoritesBox.get(userId, defaultValue: <String>[]);
    return favoriteIds.map((id) => _foodsBox.get(id)).whereType<FoodItem>().toList();
  }
  
  /// Добавить в избранное
  Future<void> addToFavorites(String userId, String foodId) async {
    final favorites = _favoritesBox.get(userId, defaultValue: <String>[]);
    if (!favorites.contains(foodId)) {
      favorites.add(foodId);
      await _favoritesBox.put(userId, favorites);
    }
  }
  
  /// Получить недавно использованные продукты
  Future<List<FoodItem>> getRecentFoods(String userId) async {
    final recentIds = _recentBox.get(userId, defaultValue: <String>[]);
    return recentIds.map((id) => _foodsBox.get(id)).whereType<FoodItem>().toList();
  }
  
  /// Добавить в недавние
  Future<void> addToRecent(String userId, String foodId) async {
    final recent = _recentBox.get(userId, defaultValue: <String>[]);
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
  
  /// Поиск рецептов (локальный)
  Future<List<Recipe>> searchRecipes({
    required String query,
    int maxResults = 20,
  }) async {
    final queryLower = query.toLowerCase();
    final results = <Recipe>[];
    
    for (final recipe in _recipesBox.values) {
      if (recipe.name.toLowerCase().contains(queryLower) ||
          recipe.ingredients.any((ing) => ing.toLowerCase().contains(queryLower))) {
        results.add(recipe);
        if (results.length >= maxResults) break;
      }
    }
    
    return results;
  }
  
  /// Получить детали рецепта
  Future<Recipe?> getRecipeDetails(String recipeId) async {
    return _recipesBox.get(recipeId);
  }
}

/// Сервис рекомендаций
class RecommendationService {
  final FoodDatabaseService _foodService;
  final DietService _dietService;
  
  /// Получить рекомендации для текущего дня
  Future<List<FoodRecommendation>> getRecommendations({
    required String userId,
    required DateTime date,
    required Macros targetMacros,
  }) async {
    final logs = await DietService.getFoodLogsForDate(date);
    final summary = DailySummary.fromLogs(date, logs);
    
    final recommendations = <FoodRecommendation>[];
    
    // Анализ недостающих макронутриентов
    final proteinDeficit = targetMacros.protein - summary.totalProtein.round();
    final fatDeficit = targetMacros.fat - summary.totalFat.round();
    final carbDeficit = targetMacros.carbs - summary.totalCarbs.round();
    final calorieDeficit = targetMacros.calories - summary.totalCalories;
    
    // Рекомендации по белку
    if (proteinDeficit > 20) {
      final proteinFoods = await _foodService.searchFoods(
        query: '',
        maxResults: 5,
        category: FoodCategory.protein,
      );
      recommendations.add(FoodRecommendation(
        type: RecommendationType.proteinDeficit,
        message: 'Недостаточно белка. Добавьте:',
        foods: proteinFoods,
      ));
    }
    
    // Рекомендации по калориям
    if (calorieDeficit > 200) {
      recommendations.add(FoodRecommendation(
        type: RecommendationType.calorieDeficit,
        message: 'Осталось $calorieDeficit ккал. Рекомендуем:',
        foods: await _getBalancedFoods(calorieDeficit),
      ));
    }
    
    return recommendations;
  }
  
  Future<List<FoodItem>> _getBalancedFoods(int targetCalories) async {
    // Подбор продуктов для достижения целевых калорий
    // с балансом БЖУ
    return [];
  }
}

class FoodRecommendation {
  final RecommendationType type;
  final String message;
  final List<FoodItem> foods;
  
  FoodRecommendation({
    required this.type,
    required this.message,
    required this.foods,
  });
}

enum RecommendationType {
  proteinDeficit,
  fatDeficit,
  carbDeficit,
  calorieDeficit,
  calorieExcess,
}

/// Сервис статистики
class DietStatisticsService {
  /// Получить статистику за период
  Future<PeriodStatistics> getPeriodStatistics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final logs = await DietService.getFoodLogsForPeriod(startDate, endDate);
    
    // Расчет средних показателей
    final days = endDate.difference(startDate).inDays + 1;
    int totalCalories = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCarbs = 0;
    
    for (final log in logs) {
      totalCalories += log.calories;
      totalProtein += log.protein;
      totalFat += log.fat;
      totalCarbs += log.carbs;
    }
    
    return PeriodStatistics(
      period: endDate.difference(startDate),
      averageCalories: (totalCalories / days).round(),
      averageProtein: totalProtein / days,
      averageFat: totalFat / days,
      averageCarbs: totalCarbs / days,
      totalDays: days,
      daysWithLogs: _countDaysWithLogs(logs),
    );
  }
  
  int _countDaysWithLogs(List<FoodLog> logs) {
    final uniqueDays = logs.map((log) => 
      DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day)
    ).toSet();
    return uniqueDays.length;
  }
  
  /// Получить данные для графика калорий
  Future<List<ChartDataPoint>> getCaloriesChartData({
    required String userId,
    required int days,
  }) async {
    final now = DateTime.now();
    final data = <ChartDataPoint>[];
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final logs = await DietService.getFoodLogsForDate(date);
      final summary = DailySummary.fromLogs(date, logs);
      
      data.add(ChartDataPoint(
        date: date,
        value: summary.totalCalories,
      ));
    }
    
    return data;
  }
}

class PeriodStatistics {
  final Duration period;
  final int averageCalories;
  final double averageProtein;
  final double averageFat;
  final double averageCarbs;
  final int totalDays;
  final int daysWithLogs;
  
  PeriodStatistics({
    required this.period,
    required this.averageCalories,
    required this.averageProtein,
    required this.averageFat,
    required this.averageCarbs,
    required this.totalDays,
    required this.daysWithLogs,
  });
}

class ChartDataPoint {
  final DateTime date;
  final int value;
  
  ChartDataPoint({
    required this.date,
    required this.value,
  });
}

/// Сервис планирования питания
class MealPlanningService {
  final Box<MealPlan> _plansBox;
  
  /// Сохранить план на день
  Future<void> savePlan(MealPlan plan) async {
    await _plansBox.put(plan.id, plan);
  }
  
  /// Получить план на день
  Future<MealPlan?> getPlanForDate(DateTime date) async {
    final dateKey = _dateToKey(date);
    return _plansBox.get(dateKey);
  }
  
  /// Копировать план с одной даты на другую
  Future<void> copyPlan(DateTime fromDate, DateTime toDate) async {
    final fromPlan = await getPlanForDate(fromDate);
    if (fromPlan != null) {
      final newPlan = fromPlan.copyWith(
        id: _dateToKey(toDate),
        date: toDate,
      );
      await savePlan(newPlan);
    }
  }
  
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}

class MealPlan {
  final String id;
  final DateTime date;
  final Map<MealType, List<PlannedFood>> plannedMeals;
  
  MealPlan({
    required this.id,
    required this.date,
    required this.plannedMeals,
  });
  
  MealPlan copyWith({
    String? id,
    DateTime? date,
    Map<MealType, List<PlannedFood>>? plannedMeals,
  }) {
    return MealPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      plannedMeals: plannedMeals ?? this.plannedMeals,
    );
  }
}

class PlannedFood {
  final String foodId;
  final String foodName;
  final double grams;
  final int calories;
  
  PlannedFood({
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.calories,
  });
}
```

### 4. Сервис импорта данных

```dart
class FoodDataImportService {
  /// Импорт USDA данных из CSV
  Future<void> importUSDAData(String csvFilePath) async {
    final file = File(csvFilePath);
    final lines = await file.readAsLines();
    
    // Пропустить заголовок
    for (int i = 1; i < lines.length; i++) {
      final fields = _parseCSVLine(lines[i]);
      final food = _createFoodItemFromUSDA(fields);
      await Hive.box<FoodItem>('foods').put(food.id, food);
    }
  }
  
  /// Импорт рецептов из JSON
  Future<void> importRecipes(String jsonFilePath) async {
    final file = File(jsonFilePath);
    final jsonData = json.decode(await file.readAsString());
    
    for (final recipeData in jsonData) {
      final recipe = Recipe.fromJson(recipeData);
      await Hive.box<Recipe>('recipes').put(recipe.id, recipe);
    }
  }
  
  /// Создание индекса для быстрого поиска
  Future<void> buildSearchIndex() async {
    // Индексировать названия продуктов для быстрого поиска
  }
}
```

---

## 📅 Этапы разработки

### Этап 1: Подготовка данных и структуры (2-3 дня) ✅ ЗАВЕРШЕНО

**Задачи:**
- [x] Скачать USDA FoodData Central CSV/JSON
- [x] Скачать или найти датасет рецептов (Kaggle/GitHub)
- [x] Создать структуру Hive боксов для продуктов и рецептов
- [x] Расширить модель `FoodItem` новыми полями (barcode, allergens, servings)
- [x] Создать модель `Recipe` для рецептов
- [x] Создать `FoodDataImportService` для импорта данных
- [x] Написать парсер для USDA CSV/JSON формата

**Результат:** Готова структура для хранения данных, скачаны исходные файлы

**Дополнительно:**
- [ ] Настроить Firebase Storage (или альтернативу)
- [ ] Загрузить большие файлы в облачное хранилище
- [ ] Создать сервис для скачивания данных из облака

---

### Этап 2: Импорт базовой БД в приложение (2-3 дня)

**Задачи:**
- [ ] Реализовать парсинг USDA Foundation Foods JSON
- [ ] Импортировать Foundation Foods (~8,000 продуктов) в Hive
- [ ] Импортировать популярные рецепты (~1,000) в Hive
- [ ] Создать индекс штрих-кодов для базовой БД
- [ ] Оптимизировать размер (только нужные поля)
- [ ] Встроить базовую БД в assets приложения

**UI изменения:**
- Импорт происходит автоматически при первом запуске
- Показывать прогресс импорта (если нужно)
- Приложение работает сразу с базовой БД

**Результат:** Базовая БД (~10-20 MB) встроена в приложение

---

### Этап 2.5: Настройка облачного хранилища (2-3 дня)

**Задачи:**
- [ ] Настроить Firebase Storage (или альтернативу)
- [ ] Загрузить полную базу USDA в облако
- [ ] Загрузить полную базу рецептов в облако
- [ ] Настроить правила доступа (публичное чтение)
- [ ] Создать `CloudFoodDatabaseService` для работы с облаком
- [ ] Реализовать скачивание данных по требованию
- [ ] Реализовать кэширование скачанных данных

**Результат:** Большие файлы доступны из облака, скачивание по требованию

---

### Этап 3: Локальный поиск продуктов (2-3 дня)

**Задачи:**
- [ ] Реализовать `FoodDatabaseService` с локальным поиском
- [ ] Оптимизировать поиск (индексация, фильтрация)
- [ ] Реализовать автодополнение при вводе
- [ ] Интеграция с существующим `AddFoodDialog`
- [ ] Замена статического `FoodDatabase` на Hive поиск
- [ ] Добавить пагинацию для больших результатов

**UI изменения:**
- Обновить `AddFoodDialog` для локального поиска
- Добавить debounce для поиска (не более 1 обновления в 300мс)
- Показывать результаты мгновенно (без индикатора загрузки)

**Результат:** Быстрый локальный поиск продуктов работает

---

### Этап 4: Детали продукта и порции (2 дня)

**Задачи:**
- [ ] Реализовать `getFoodDetails()` из Hive
- [ ] Добавить поддержку различных порций из USDA данных
- [ ] Обновить UI для выбора порции
- [ ] Сохранение выбранной порции в `FoodLog`
- [ ] Отображение полной информации о продукте (витамины, минералы)

**UI изменения:**
- В `AddFoodDialog` показывать список доступных порций из USDA
- Позволить пользователю выбрать порцию или ввести вес вручную
- Показывать расширенную информацию о нутриентах

**Результат:** Пользователи могут выбирать различные порции продуктов

---

### Этап 5: Сканирование штрих-кодов (3-4 дня)

**Задачи:**
- [ ] Добавить зависимость `mobile_scanner` или `barcode_scan`
- [ ] Импортировать данные Open Food Facts с штрих-кодами
- [ ] Реализовать `findFoodByBarcode()` метод (поиск в Hive)
- [ ] Создать экран сканирования штрих-кодов
- [ ] Интеграция с `AddFoodDialog` (кнопка "Сканировать штрих-код")
- [ ] Обработка случаев, когда продукт не найден

**UI изменения:**
- Добавить кнопку сканера в `AddFoodDialog`
- Создать `BarcodeScannerPage` с камерой
- Показывать результат сканирования с деталями продукта

**Результат:** Пользователи могут сканировать штрих-коды для быстрого добавления продуктов

---

### Этап 6: Улучшение информации об аллергенах (1-2 дня)

**Задачи:**
- [ ] Расширить модель `FoodItem` полями `allergens`, `isVegan`, `isVegetarian`
- [ ] Обновить `ProfileSetupPage` для синхронизации аллергенов
- [ ] Добавить проверку аллергенов при добавлении продукта
- [ ] Показывать предупреждения о аллергенах в UI

**UI изменения:**
- В `AddFoodDialog` показывать предупреждение, если продукт содержит аллерген
- В профиле показывать совместимость продуктов с аллергиями

**Результат:** Улучшенная система проверки аллергенов

---

### Этап 7: Выбор даты и навигация по истории (2 дня)

**Задачи:**
- [ ] Реализовать выбор даты (исправить TODO в `FoodLogPage`)
- [ ] Создать календарный виджет для выбора даты
- [ ] Добавить навигацию: вчера/сегодня/завтра
- [ ] Сохранение выбранной даты в состоянии
- [ ] Загрузка данных для выбранной даты

**UI изменения:**
- Добавить календарь в AppBar (кнопка уже есть)
- Добавить стрелки навигации по датам
- Показывать выбранную дату в заголовке
- Подсветка дат с записями в календаре

**Результат:** Пользователи могут просматривать и редактировать записи за любую дату

---

### Этап 8: Улучшенный поиск продуктов (2-3 дня)

**Задачи:**
- [ ] Добавить "Избранные продукты" (звездочка, сохранение в Hive)
- [ ] Реализовать "Недавно использованные" (последние 10 продуктов)
- [ ] Добавить фильтры поиска (категория, калории, БЖУ)
- [ ] Улучшить автодополнение
- [ ] Добавить сортировку результатов (по релевантности, популярности)

**UI изменения:**
- В `AddFoodDialog` добавить вкладки: "Все", "Избранные", "Недавние"
- Добавить кнопку "⭐" для добавления в избранное
- Показывать фильтры над списком продуктов
- Улучшить визуальное отображение результатов

**Результат:** Более удобный и быстрый поиск продуктов

---

### Этап 9: Dashboard с графиками и статистикой (4-5 дней)

**Задачи:**
- [ ] Создать `DietDashboardPage` как главный экран
- [ ] Реализовать переключение периодов (сегодня/неделя/месяц)
- [ ] Интегрировать `fl_chart` для графиков
- [ ] Создать график калорий за 7 дней (линейный)
- [ ] Создать круговую диаграмму БЖУ
- [ ] Добавить карточки статистики (средние показатели)
- [ ] Реализовать сравнение с предыдущими периодами

**UI изменения:**
- Создать новый Dashboard экран
- Добавить табы для переключения периодов
- Красивые графики с fl_chart
- Карточки с метриками
- Анимации при загрузке данных

**Результат:** Визуализация прогресса и статистики

---

### Этап 10: Умные рекомендации (3-4 дня)

**Задачи:**
- [ ] Создать `RecommendationService` для анализа питания
- [ ] Реализовать алгоритм рекомендаций:
  - Анализ текущего дня
  - Расчет недостающих/избыточных макронутриентов
  - Подбор продуктов для балансировки
  - Учет аллергий и противопоказаний
- [ ] Интеграция рекомендаций в Dashboard
- [ ] Показывать рекомендации в `AddFoodDialog`

**UI изменения:**
- Добавить секцию "💡 Рекомендации" в Dashboard
- Показывать контекстные подсказки
- Кнопка "Добавить рекомендованный продукт"
- Визуальные индикаторы (недостаточно белка, превышение калорий)

**Результат:** Умные рекомендации помогают достигать целей

---

### Этап 11: Планирование питания (3-4 дня)

**Задачи:**
- [ ] Создать `MealPlanningService` для планирования
- [ ] Реализовать планирование на день
- [ ] Реализовать планирование на неделю
- [ ] Создать шаблоны приемов пищи
- [ ] Добавить копирование предыдущих дней
- [ ] Связь планирования с журналом питания

**UI изменения:**
- Создать `MealPlanningPage` с календарем
- Показывать запланированные приемы пищи
- Кнопки "Копировать вчерашний день", "Использовать шаблон"
- Индикация выполненных/невыполненных планов

**Результат:** Пользователи могут планировать питание заранее

---

### Этап 12: Рецепты (3-4 дня)

**Задачи:**
- [ ] Создать модель `Recipe` с Hive адаптером
- [ ] Реализовать `searchRecipes()` и `getRecipeDetails()` (локальный поиск)
- [ ] Создать `RecipeSearchPage`
- [ ] Создать `RecipeDetailPage` с ингредиентами и инструкциями
- [ ] Добавить возможность добавления рецепта в журнал питания
- [ ] Расчет макросов для всего рецепта на основе ингредиентов
- [ ] Связывание ингредиентов рецепта с продуктами из базы

**UI изменения:**
- Добавить вкладку "Рецепты" в модуль диеты
- Показывать рецепты с изображениями (если есть в датасете)
- Позволить добавлять рецепт как прием пищи
- Показывать детальную информацию о рецепте

**Результат:** Пользователи могут искать и использовать рецепты

---

### Этап 13: Мотивация и достижения (2-3 дня)

**Задачи:**
- [ ] Создать систему достижений (AchievementService)
- [ ] Реализовать Streak (дни подряд в пределах нормы)
- [ ] Добавить бейджи и достижения
- [ ] Создать мотивационные сообщения
- [ ] Интеграция в Dashboard

**UI изменения:**
- Добавить секцию "🏆 Достижения" в Dashboard
- Показывать текущий Streak
- Анимации при получении достижений
- Мотивационные сообщения при достижении целей

**Результат:** Мотивационная система для пользователей

---

### Этап 14: Статистика и аналитика (3-4 дня)

**Задачи:**
- [ ] Создать `DietStatisticsService` для расчетов
- [ ] Реализовать статистику за неделю/месяц/3 месяца
- [ ] Расчет средних показателей
- [ ] Анализ трендов
- [ ] Сравнение периодов
- [ ] Создать `StatisticsPage` с графиками

**UI изменения:**
- Создать отдельную страницу "Статистика"
- Графики калорий, БЖУ за разные периоды
- Таблицы со средними показателями
- Сравнение с предыдущими периодами

**Результат:** Детальная аналитика питания

---

### Этап 15: Быстрые действия и шаблоны (2 дня)

**Задачи:**
- [ ] Реализовать "Быстрое добавление" (избранные продукты)
- [ ] Создать шаблоны приемов пищи (сохранение в Hive)
- [ ] Реализовать копирование вчерашнего дня
- [ ] Добавить "Повторить последний продукт"
- [ ] Создать часто используемые комбинации

**UI изменения:**
- Кнопка "Быстрое добавление" в FAB меню
- Диалог выбора шаблона
- Кнопка "Копировать вчера" в календаре
- Быстрые действия в контекстном меню

**Результат:** Ускорение добавления продуктов

---

### Этап 16: Оптимизация и финальные улучшения (3-4 дня)

**Задачи:**
- [ ] Оптимизировать поиск (создать полнотекстовый индекс)
- [ ] Оптимизировать загрузку данных (ленивая загрузка)
- [ ] Добавить возможность обновления базы данных
- [ ] Оптимизировать размер базы данных (сжатие)
- [ ] Улучшить производительность графиков
- [ ] Тестирование производительности на различных устройствах
- [ ] Оптимизация памяти для больших баз данных

**Результат:** Оптимизированная и быстрая работа приложения

---

## ☁️ Архитектура хранения данных

### Гибридный подход (рекомендуется)

**Проблема:** Большие файлы (67+ GB) нельзя хранить на телефонах пользователей.

**Решение:** Гибридная архитектура

```
┌─────────────────────────────────────────────────────────┐
│              Приложение (на телефоне)                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Базовая БД (локально в Hive)                     │  │
│  │  - Foundation Foods: ~8,000 продуктов (~6 MB)     │  │
│  │  - Популярные рецепты: ~1,000 рецептов (~5 MB)    │  │
│  │  - Избранные/недавние продукты                     │  │
│  └──────────────────────────────────────────────────┘  │
│                        ↕                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Облачное хранилище (Firebase Storage / CDN)     │  │
│  │  - Полная база USDA: 375,000+ продуктов          │  │
│  │  - Полная база рецептов: 2M+ рецептов            │  │
│  │  - Open Food Facts: миллионы продуктов            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Варианты облачного хранилища

#### 1. Firebase Storage (рекомендуется)
- ✅ Уже упоминается в проекте
- ✅ Бесплатный tier: 5 GB хранилища, 1 GB/день трафика
- ✅ Интеграция с Flutter: `firebase_storage`
- ✅ CDN встроен
- ✅ Безопасность через правила

**Стоимость:**
- Бесплатно: 5 GB хранилища, 1 GB/день
- Платно: $0.026/GB хранилища, $0.12/GB трафика

#### 2. AWS S3 + CloudFront
- ✅ Очень дешево для статических файлов
- ✅ Глобальный CDN
- ✅ Надежность 99.99%
- ❌ Требует настройки AWS аккаунта

**Стоимость:**
- S3: $0.023/GB хранилища
- CloudFront: $0.085/GB трафика (первые 10 TB)

#### 3. Google Cloud Storage
- ✅ Интеграция с Firebase
- ✅ CDN встроен
- ✅ Похожая стоимость на AWS

#### 4. GitHub Releases (бесплатно, но не для продакшена)
- ✅ Полностью бесплатно
- ✅ CDN через jsDelivr
- ❌ Ограничения: 2 GB на файл, не для коммерческого использования

### Реализация гибридного подхода

#### Этап 1: Базовая БД в приложении
- Foundation Foods (~8,000 продуктов) — встроено в APK/IPA
- Популярные рецепты (~1,000) — встроено
- Размер приложения: ~10-20 MB

#### Этап 2: Облачное хранилище
- Полная база USDA — на Firebase Storage
- Полная база рецептов — на Firebase Storage
- Скачивание по требованию

#### Этап 3: Кэширование
- Скачанные данные сохраняются локально в Hive
- Проверка обновлений раз в неделю
- Удаление неиспользуемых данных через месяц

### Пример использования

```dart
class FoodDatabaseService {
  final Box<FoodItem> _localBox; // Локальная БД
  final FirebaseStorage _storage; // Облачное хранилище
  
  /// Поиск продукта
  Future<List<FoodItem>> searchFoods(String query) async {
    // 1. Сначала ищем в локальной БД
    final localResults = _searchLocal(query);
    if (localResults.length >= 20) {
      return localResults;
    }
    
    // 2. Если мало результатов, ищем в облаке
    final cloudResults = await _searchCloud(query);
    
    // 3. Сохраняем популярные результаты локально
    await _cachePopular(cloudResults);
    
    return [...localResults, ...cloudResults];
  }
  
  /// Скачать полную базу (опционально)
  Future<void> downloadFullDatabase() async {
    // Скачать с Firebase Storage
    // Импортировать в Hive
    // Использовать локально
  }
}
```

---

## ⚠️ Риски и ограничения

### Технические риски

1. **Размер базы данных**
   - Риск: Большой размер файлов (375,000+ продуктов = несколько GB)
   - Митигация: 
     - **Гибридный подход:** базовая БД в приложении, остальное в облаке
     - Импортировать только нужные поля
     - Использовать сжатие Hive
     - Опциональная загрузка полной базы
     - Начать с Foundation Foods (меньше размер)

2. **Производительность поиска**
   - Риск: Медленный поиск по большой базе
   - Митигация:
     - Создать индекс для поиска
     - Использовать фильтрацию вместо полного перебора
     - Кэшировать популярные запросы
     - Ограничить результаты поиска

3. **Импорт данных**
   - Риск: Долгий процесс импорта при первом запуске
   - Митигация:
     - Показывать прогресс-бар
     - Импортировать в фоновом режиме
     - Предустановить базовый набор продуктов в приложении
     - Разделить импорт на этапы

4. **Обновление данных**
   - Риск: Данные могут устареть
   - Митигация:
     - Периодически обновлять базу (раз в квартал)
     - Позволить пользователю обновить вручную
     - Использовать версионирование данных

### Ограничения гибридного подхода

- ⚠️ **Требуется интернет** для доступа к полной базе
- ⚠️ **Стоимость облака** — может быть платно при большом трафике
- ⚠️ **Задержка** — первый поиск в облаке медленнее
- ⚠️ **Локализация** — USDA данные в основном на английском
- ⚠️ **Региональные продукты** — может не хватать локальных продуктов

### Преимущества гибридного подхода

- ✅ **Маленький размер приложения** — только базовая БД (~10-20 MB)
- ✅ **Быстрый старт** — работает сразу с базовой БД
- ✅ **Полная база по требованию** — доступ к миллионам продуктов
- ✅ **Офлайн-работа** — базовая БД работает без интернета
- ✅ **Автоматические обновления** — можно обновлять данные в облаке
- ✅ **Масштабируемость** — легко добавить новые источники данных
- ✅ **Кэширование** — популярные данные сохраняются локально
- ✅ **Бесплатно для MVP** — Firebase free tier достаточен

---

## 📦 Необходимые зависимости

```yaml
dependencies:
  # Сканирование штрих-кодов
  mobile_scanner: ^3.5.0  # или barcode_scan: ^2.0.0
  
  # Работа с CSV файлами
  csv: ^6.0.0
  
  # Работа с JSON
  # dart:convert уже есть в стандартной библиотеке
  
  # Работа с файлами
  # dart:io уже есть в стандартной библиотеке
  path_provider: ^2.1.2  # уже есть в проекте
  
  # Облачное хранилище (для больших файлов)
  firebase_storage: ^11.6.0  # или firebase_core + firebase_storage
  # Альтернатива: AWS S3
  # flutter_s3: ^1.0.0
  
  # HTTP для скачивания данных
  http: ^1.1.0
  
  # Графики и визуализация
  fl_chart: ^0.66.0  # уже есть в проекте
  
  # Календарь для выбора даты
  table_calendar: ^3.0.9  # или syncfusion_flutter_calendar
  
  # Кэширование (Hive уже есть)
  # hive: ^2.2.3  # уже есть
  # hive_flutter: ^1.1.0  # уже есть
```

---

## 🧪 Тестирование

### Unit тесты
- Тестирование парсинга CSV/JSON данных
- Тестирование импорта данных в Hive
- Тестирование поиска продуктов
- Тестирование поиска рецептов

### Integration тесты
- Тестирование полного цикла импорта
- Тестирование поиска по большой базе
- Тестирование сканирования штрих-кодов
- Тестирование производительности поиска

### Manual тесты
- Импорт данных (проверка времени и размера)
- Поиск различных продуктов
- Сканирование реальных штрих-кодов
- Проверка работы офлайн
- Проверка производительности на разных устройствах

---

## 📈 Метрики успеха

### Базовые метрики
- ✅ Увеличение базы продуктов с 40 до 375,000+ (USDA) + миллионы (Open Food Facts)
- ✅ Мгновенный поиск продуктов (локальный, без задержек API)
- ✅ Увеличение конверсии добавления продуктов (благодаря сканированию)
- ✅ Улучшение точности данных о продуктах (официальные источники)
- ✅ Полная офлайн-работа без зависимости от интернета
- ✅ Нет атрибуции — полная свобода использования

### Улучшения UX
- ✅ Визуализация прогресса (графики, диаграммы)
- ✅ Умные рекомендации для достижения целей
- ✅ Планирование питания на день/неделю
- ✅ Статистика и аналитика за периоды
- ✅ Мотивация через достижения и Streak
- ✅ Быстрый доступ к избранным и недавним продуктам
- ✅ Навигация по истории (выбор любой даты)

---

## 🔗 Полезные ссылки

### Источники данных
- [USDA FoodData Central](https://fdc.nal.usda.gov) — база продуктов
- [USDA Download Datasets](https://fdc.nal.usda.gov/download-datasets.html) — скачать данные
- [Open Food Facts](https://world.openfoodfacts.org) — открытая база продуктов
- [Open Food Facts Data](https://world.openfoodfacts.org/data) — скачать данные
- [Kaggle Recipe Datasets](https://www.kaggle.com/datasets?search=recipe) — датасеты рецептов

### Библиотеки
- [Hive Package](https://pub.dev/packages/hive) — локальная БД
- [CSV Package](https://pub.dev/packages/csv) — парсинг CSV
- [Mobile Scanner](https://pub.dev/packages/mobile_scanner) — сканирование штрих-кодов

---

## 📝 Примечания

1. **Размер базы данных:** Рекомендуется начать с Foundation Foods (~8,000 продуктов) для тестирования, затем добавить полную базу при необходимости.

2. **Импорт данных:** Импорт можно сделать одноразово при первом запуске или предустановить базовый набор в приложении.

3. **Обновления:** Периодически обновлять базу данных (раз в квартал) для актуальности информации.

4. **Приоритизация:** Начать с Этапов 1-5 (базовая функциональность), затем добавить улучшения UX (Этапы 7-11), и в конце расширенные функции (Этапы 12-16).

---

## 📊 Итоговая сводка этапов

### Базовые функции (Этапы 1-6) - ~15-20 дней
- Импорт данных и структура
- Поиск продуктов
- Сканирование штрих-кодов
- Аллергены

### Улучшения UX (Этапы 7-11) - ~15-18 дней
- Выбор даты
- Улучшенный поиск
- Dashboard и графики
- Умные рекомендации
- Планирование питания

### Расширенные функции (Этапы 12-16) - ~13-18 дней
- Рецепты
- Мотивация и достижения
- Статистика
- Быстрые действия
- Оптимизация

**Общее время разработки:** ~43-56 дней (6-8 недель)

### Приоритизация для MVP

**MVP (Минимально жизнеспособный продукт):**
- Этапы 1-5: Базовая функциональность (импорт, поиск, сканирование)
- Этап 7: Выбор даты (критично для UX)
- Этап 8: Улучшенный поиск (избранные, недавние)

**Версия 1.0:**
- + Этап 9: Dashboard с графиками
- + Этап 10: Умные рекомендации
- + Этап 6: Аллергены

**Версия 1.1:**
- + Этап 11: Планирование питания
- + Этап 12: Рецепты
- + Этап 13: Мотивация

**Версия 1.2:**
- + Этап 14: Статистика
- + Этап 15: Быстрые действия
- + Этап 16: Оптимизация

---

**Автор:** AI Assistant  
**Последнее обновление:** 18 января 2026  
**Версия документа:** 2.0 (с улучшениями UX/UI)
