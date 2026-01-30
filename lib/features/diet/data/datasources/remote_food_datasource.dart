import 'package:dio/dio.dart';
import '../../domain/models/food_item.dart';
import '../../../../core/services/dio_client.dart';

/// Удалённый источник данных (Open Food Facts API)
class RemoteFoodDatasource {
  final Dio _dio = DioClient.instance;

  // Open Food Facts API endpoints
  static const String _offBaseUrl = 'https://world.openfoodfacts.org';
  static const String _offSearchUrl = '$_offBaseUrl/cgi/search.pl';
  static const String _offProductUrl = '$_offBaseUrl/api/v2/product';

  /// Поиск продуктов по названию
  Future<List<FoodItem>> search({
    required String query,
    int maxResults = 50,
    String language = 'ru',
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      print('🔍 OFF API search: "$query"');
      
      final response = await _dio.get(
        _offSearchUrl,
        queryParameters: {
          'search_terms': query,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': maxResults,
          'lc': language,
          'fields': 'code,product_name,product_name_ru,brands,'
              'nutriments,categories_tags,allergens_tags,'
              'labels_tags,serving_size',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final products = data['products'] as List<dynamic>? ?? [];
        
        print('📦 OFF API raw products: ${products.length}');
        
        final results = products
            .map((p) => _parseOpenFoodFactsProduct(p as Map<String, dynamic>))
            .whereType<FoodItem>()
            .toList();
        
        print('✅ OFF API parsed: ${results.length} products');
        return results;
      }
      
      print('⚠️ OFF API response: ${response.statusCode}');
      return [];
    } on DioException catch (e) {
      print('❌ OFF API search error: ${e.type} - ${e.message}');
      return [];
    } catch (e) {
      print('❌ OFF API search error: $e');
      return [];
    }
  }

  /// Поиск по штрих-коду
  Future<FoodItem?> findByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;

    try {
      print('🔍 OFF API barcode: $barcode');
      
      final response = await _dio.get(
        '$_offProductUrl/$barcode',
        queryParameters: {
          'fields': 'code,product_name,product_name_ru,brands,'
              'nutriments,categories_tags,allergens_tags,'
              'labels_tags,serving_size',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['status'] == 1) {
          final product = _parseOpenFoodFactsProduct(
            data['product'] as Map<String, dynamic>,
          );
          
          if (product != null) {
            print('✅ OFF API found product: ${product.nameRu}');
          }
          return product;
        } else {
          print('⚠️ OFF API: product not found');
        }
      }
      
      return null;
    } on DioException catch (e) {
      print('❌ OFF API barcode error: ${e.type} - ${e.message}');
      return null;
    } catch (e) {
      print('❌ OFF API barcode error: $e');
      return null;
    }
  }

  /// Парсинг продукта из Open Food Facts
  FoodItem? _parseOpenFoodFactsProduct(Map<String, dynamic> data) {
    try {
      final barcode = data['code']?.toString();
      if (barcode == null || barcode.isEmpty) return null;

      final rawName = data['product_name']?.toString() ?? '';
      final rawNameRu = data['product_name_ru']?.toString() ?? '';
      
      // Если оба названия пустые - пропускаем
      if (rawName.isEmpty && rawNameRu.isEmpty) return null;

      // Бренд
      final brand = _cleanBrand(data['brands']?.toString());

      // Нормализуем названия (обработка составных названий)
      final name = _normalizeProductName(rawName, brand);
      final nameRu = _normalizeProductName(rawNameRu, brand);

      final nutriments = data['nutriments'] as Map<String, dynamic>? ?? {};
      
      // Извлечение нутриентов (на 100г)
      // Open Food Facts использует разные ключи для одних и тех же данных
      final calories = _parseNutrientWithFallbacks(nutriments, [
        'energy-kcal_100g', 'energy_100g', 'energy-kcal', 'energy_kcal_100g',
      ], isEnergy: true);
      final protein = _parseNutrientWithFallbacks(nutriments, [
        'proteins_100g', 'proteins', 'protein_100g', 'protein',
      ]);
      final fat = _parseNutrientWithFallbacks(nutriments, [
        'fat_100g', 'fat', 'total-fat_100g', 'total_fat_100g',
      ]);
      final carbs = _parseNutrientWithFallbacks(nutriments, [
        'carbohydrates_100g', 'carbohydrates', 'carbs_100g', 'carbs',
      ]);

      // Пропускаем продукты совсем без данных (только если нет даже калорий)
      // Многие продукты в OFF имеют только калории без БЖУ - это нормально
      if (calories == 0 && protein == 0 && fat == 0 && carbs == 0) {
        // Не пропускаем, просто логируем - продукт может быть полезен по названию/штрих-коду
        print('⚠️ Product without nutrients: ${rawNameRu.isNotEmpty ? rawNameRu : rawName}');
      }

      // Аллергены
      final allergensTags = data['allergens_tags'] as List<dynamic>? ?? [];
      final allergens = allergensTags
          .map((t) => _cleanAllergenTag(t.toString()))
          .where((a) => a.isNotEmpty)
          .toList();

      // Категория
      final categoryTags = data['categories_tags'] as List<dynamic>? ?? [];
      final category = _determineCategory(categoryTags);

      // Веган/вегетарианец
      final labelsTags = data['labels_tags'] as List<dynamic>? ?? [];
      final isVegan = labelsTags.any((t) => t.toString().contains('vegan'));
      final isVegetarian = labelsTags.any((t) => 
        t.toString().contains('vegetarian') && !t.toString().contains('non-vegetarian')
      );

      return FoodItem(
        id: 'off_$barcode',
        name: name.isNotEmpty ? name : nameRu,
        nameRu: nameRu.isNotEmpty ? nameRu : name,
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        category: category,
        brand: brand,
        barcode: barcode,
        allergens: allergens,
        isVegan: isVegan,
        isVegetarian: isVegetarian,
        source: 'openfoodfacts',
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      print('⚠️ Parse OFF product error: $e');
      return null;
    }
  }

  /// Нормализация названия продукта
  /// 
  /// Обрабатывает составные названия типа "Яблоко, Вишня, черноплодная рябина"
  /// и слишком длинные названия
  String _normalizeProductName(String rawName, String? brand) {
    if (rawName.isEmpty) return '';

    String name = rawName.trim();
    
    // Убираем лишние пробелы
    name = name.replaceAll(RegExp(r'\s+'), ' ');
    
    // Проверяем, является ли это составным названием (много запятых = список ингредиентов/вкусов)
    final commaCount = ','.allMatches(name).length;
    
    if (commaCount >= 2) {
      // Это скорее всего список вкусов/ингредиентов
      // Пытаемся определить тип продукта и создать понятное название
      name = _handleCompositeProductName(name, brand);
    }
    
    // Ограничиваем длину названия (макс 60 символов)
    if (name.length > 60) {
      // Обрезаем по последнему пробелу до 60 символов
      final truncated = name.substring(0, 57);
      final lastSpace = truncated.lastIndexOf(' ');
      if (lastSpace > 30) {
        name = '${truncated.substring(0, lastSpace)}...';
      } else {
        name = '$truncated...';
      }
    }
    
    return name;
  }

  /// Обработка составного названия продукта (например "Яблоко, Вишня, черноплодная рябина")
  String _handleCompositeProductName(String name, String? brand) {
    final parts = name.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    
    if (parts.isEmpty) return name;
    
    // Определяем тип продукта по ключевым словам
    final nameLower = name.toLowerCase();
    String? productType;
    
    // Напитки
    if (nameLower.contains('сок') || nameLower.contains('juice')) {
      productType = 'Сок';
    } else if (nameLower.contains('нектар') || nameLower.contains('nectar')) {
      productType = 'Нектар';
    } else if (nameLower.contains('компот')) {
      productType = 'Компот';
    } else if (nameLower.contains('морс')) {
      productType = 'Морс';
    } else if (nameLower.contains('смузи') || nameLower.contains('smoothie')) {
      productType = 'Смузи';
    } else if (nameLower.contains('лимонад') || nameLower.contains('lemonade')) {
      productType = 'Лимонад';
    } else if (nameLower.contains('чай') || nameLower.contains('tea')) {
      productType = 'Чай';
    } else if (nameLower.contains('кофе') || nameLower.contains('coffee')) {
      productType = 'Кофе';
    // Молочные продукты  
    } else if (nameLower.contains('йогурт') || nameLower.contains('yogurt') || nameLower.contains('yoghurt')) {
      productType = 'Йогурт';
    } else if (nameLower.contains('молоко') || nameLower.contains('milk')) {
      productType = 'Молоко';
    } else if (nameLower.contains('кефир') || nameLower.contains('kefir')) {
      productType = 'Кефир';
    } else if (nameLower.contains('творог') || nameLower.contains('cottage cheese')) {
      productType = 'Творог';
    } else if (nameLower.contains('сметана') || nameLower.contains('sour cream')) {
      productType = 'Сметана';
    } else if (nameLower.contains('сыр') || nameLower.contains('cheese')) {
      productType = 'Сыр';
    } else if (nameLower.contains('масло') || nameLower.contains('butter')) {
      productType = 'Масло';
    // Детское питание
    } else if (nameLower.contains('пюре') || nameLower.contains('puree')) {
      productType = 'Пюре';
    } else if (nameLower.contains('детское питание') || nameLower.contains('baby food')) {
      productType = 'Детское питание';
    } else if (nameLower.contains('каша') || nameLower.contains('porridge') || nameLower.contains('oatmeal')) {
      productType = 'Каша';
    // Сладости и десерты
    } else if (nameLower.contains('джем') || nameLower.contains('jam')) {
      productType = 'Джем';
    } else if (nameLower.contains('варенье')) {
      productType = 'Варенье';
    } else if (nameLower.contains('мороженое') || nameLower.contains('ice cream')) {
      productType = 'Мороженое';
    } else if (nameLower.contains('шоколад') || nameLower.contains('chocolate')) {
      productType = 'Шоколад';
    } else if (nameLower.contains('печенье') || nameLower.contains('cookie') || nameLower.contains('biscuit')) {
      productType = 'Печенье';
    } else if (nameLower.contains('конфет') || nameLower.contains('candy') || nameLower.contains('sweet')) {
      productType = 'Конфеты';
    } else if (nameLower.contains('торт') || nameLower.contains('cake')) {
      productType = 'Торт';
    // Основные блюда
    } else if (nameLower.contains('суп') || nameLower.contains('soup')) {
      productType = 'Суп';
    } else if (nameLower.contains('салат') || nameLower.contains('salad')) {
      productType = 'Салат';
    } else if (nameLower.contains('соус') || nameLower.contains('sauce')) {
      productType = 'Соус';
    } else if (nameLower.contains('паста') || nameLower.contains('pasta') || nameLower.contains('макарон')) {
      productType = 'Паста';
    } else if (nameLower.contains('пицца') || nameLower.contains('pizza')) {
      productType = 'Пицца';
    // Мясо и рыба
    } else if (nameLower.contains('колбас') || nameLower.contains('sausage')) {
      productType = 'Колбаса';
    } else if (nameLower.contains('сосиск') || nameLower.contains('frankfurter')) {
      productType = 'Сосиски';
    } else if (nameLower.contains('ветчин') || nameLower.contains('ham')) {
      productType = 'Ветчина';
    } else if (nameLower.contains('консерв') || nameLower.contains('canned')) {
      productType = 'Консервы';
    // Снеки
    } else if (nameLower.contains('чипс') || nameLower.contains('chips') || nameLower.contains('crisps')) {
      productType = 'Чипсы';
    } else if (nameLower.contains('крекер') || nameLower.contains('cracker')) {
      productType = 'Крекеры';
    } else if (nameLower.contains('сухар') || nameLower.contains('crouton')) {
      productType = 'Сухарики';
    // Хлеб и выпечка
    } else if (nameLower.contains('хлеб') || nameLower.contains('bread')) {
      productType = 'Хлеб';
    } else if (nameLower.contains('батон') || nameLower.contains('baguette')) {
      productType = 'Батон';
    } else if (nameLower.contains('булк') || nameLower.contains('bun') || nameLower.contains('roll')) {
      productType = 'Булочка';
    }
    
    // Если нашли тип продукта - формируем читаемое название
    if (productType != null) {
      // Убираем тип из частей если он там есть
      final ingredients = parts.where((p) => 
        !p.toLowerCase().contains(productType!.toLowerCase())
      ).toList();
      
      if (ingredients.isNotEmpty) {
        // Берём первые 2-3 ингредиента
        final mainIngredients = ingredients.take(3).join(', ');
        return '$productType ($mainIngredients)';
      }
    }
    
    // Если тип не определён - просто сокращаем
    if (parts.length > 3) {
      // Берём первые 2 элемента и добавляем "и др."
      return '${parts[0]}, ${parts[1]} и др.';
    }
    
    // Если 3 или меньше элементов - оставляем как есть, но форматируем
    return parts.join(', ');
  }

  /// Очистка бренда
  String? _cleanBrand(String? rawBrand) {
    if (rawBrand == null || rawBrand.trim().isEmpty) return null;
    
    String brand = rawBrand.trim();
    
    // Убираем лишние пробелы
    brand = brand.replaceAll(RegExp(r'\s+'), ' ');
    
    // Если бренд слишком длинный (несколько брендов через запятую) - берём первый
    if (brand.contains(',')) {
      brand = brand.split(',').first.trim();
    }
    
    // Ограничиваем длину
    if (brand.length > 30) {
      brand = brand.substring(0, 30).trim();
    }
    
    return brand.isNotEmpty ? brand : null;
  }

  /// Парсинг нутриента с несколькими fallback ключами
  double _parseNutrientWithFallbacks(
    Map<String, dynamic> nutriments, 
    List<String> keys, 
    {bool isEnergy = false}
  ) {
    for (final key in keys) {
      final value = nutriments[key];
      if (value != null) {
        double result;
        if (value is num) {
          result = value.toDouble();
        } else {
          result = double.tryParse(value.toString()) ?? 0;
        }
        
        // Если это энергия в kJ (не kcal), конвертируем
        if (isEnergy && result > 0 && !key.contains('kcal') && key.contains('energy')) {
          // Проверяем, не слишком ли большое значение для kcal (вероятно это kJ)
          if (result > 900) { // 900 kcal на 100г - это очень много, скорее всего kJ
            result = result / 4.184;
          }
        }
        
        if (result > 0) return result;
      }
    }
    return 0;
  }

  /// Парсинг нутриента с fallback (legacy)
  double _parseNutrient(Map<String, dynamic> nutriments, String key, [String? altKey]) {
    var value = nutriments[key];
    if (value == null && altKey != null) {
      value = nutriments[altKey];
      // Если это энергия в kJ, конвертируем в kcal
      if (value != null && altKey.contains('energy') && !altKey.contains('kcal')) {
        final kj = (value is num) ? value.toDouble() : (double.tryParse(value.toString()) ?? 0);
        return kj / 4.184; // kJ to kcal
      }
    }
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  /// Очистка тега аллергена
  String _cleanAllergenTag(String tag) {
    // Убираем префиксы языков (en:, ru:, etc.)
    final cleaned = tag.replaceFirst(RegExp(r'^[a-z]{2}:'), '');
    return cleaned.replaceAll('-', ' ').replaceAll('_', ' ');
  }

  /// Определение категории по тегам
  FoodCategory _determineCategory(List<dynamic> tags) {
    final tagsStr = tags.map((t) => t.toString().toLowerCase()).join(' ');
    
    if (tagsStr.contains('fruit')) return FoodCategory.fruits;
    if (tagsStr.contains('vegetable') || tagsStr.contains('legume')) {
      return FoodCategory.vegetables;
    }
    if (tagsStr.contains('grain') || tagsStr.contains('cereal') || 
        tagsStr.contains('bread') || tagsStr.contains('pasta')) {
      return FoodCategory.grains;
    }
    if (tagsStr.contains('meat') || tagsStr.contains('fish') || 
        tagsStr.contains('egg') || tagsStr.contains('seafood') ||
        tagsStr.contains('poultry')) {
      return FoodCategory.protein;
    }
    if (tagsStr.contains('dairy') || tagsStr.contains('milk') || 
        tagsStr.contains('cheese') || tagsStr.contains('yogurt')) {
      return FoodCategory.dairy;
    }
    if (tagsStr.contains('oil') || tagsStr.contains('fat') || 
        tagsStr.contains('butter') || tagsStr.contains('margarine')) {
      return FoodCategory.fats;
    }
    if (tagsStr.contains('sweet') || tagsStr.contains('sugar') || 
        tagsStr.contains('chocolate') || tagsStr.contains('candy') ||
        tagsStr.contains('dessert')) {
      return FoodCategory.sweets;
    }
    if (tagsStr.contains('beverage') || tagsStr.contains('drink') ||
        tagsStr.contains('juice') || tagsStr.contains('soda') ||
        tagsStr.contains('water')) {
      return FoodCategory.beverages;
    }
    
    return FoodCategory.other;
  }
}
