import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/domain/models/recipe.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// Сервис для импорта данных о продуктах и рецептах
class FoodDataImportService {
  /// Импорт USDA данных из CSV
  /// 
  /// Формат USDA CSV:
  /// fdc_id,description,data_type,publication_date,ndb_number,...
  /// 
  /// Для начала используем Foundation Foods (меньший размер)
  Future<void> importUSDAData(String csvFilePath, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      final file = File(csvFilePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found: $csvFilePath');
      }

      final lines = await file.readAsLines();
      if (lines.isEmpty) {
        throw FormatException('CSV file is empty');
      }

      // Пропустить заголовок
      final header = lines[0];
      final dataLines = lines.skip(1).toList();
      final total = dataLines.length;

      print('📥 Начало импорта USDA данных: $total записей');

      final foodsBox = Hive.box(HiveService.foodsBox) as Box<FoodItem>;
      final barcodesBox = Hive.box(HiveService.barcodesBox) as Box<String>;

      int imported = 0;
      int skipped = 0;

      for (int i = 0; i < dataLines.length; i++) {
        try {
          final fields = _parseCSVLine(dataLines[i]);
          final food = _createFoodItemFromUSDA(fields, header);
          
          if (food != null) {
            await foodsBox.put(food.id, food);
            
            // Сохранить штрих-код если есть
            if (food.barcode != null && food.barcode!.isNotEmpty) {
              await barcodesBox.put(food.barcode!, food.id);
            }
            
            imported++;
          } else {
            skipped++;
          }

          // Прогресс
          if (onProgress != null && (i + 1) % 100 == 0) {
            onProgress(i + 1, total);
          }
        } catch (e) {
          print('⚠️ Ошибка при обработке строки ${i + 1}: $e');
          skipped++;
        }
      }

      print('✅ Импорт завершен: $imported импортировано, $skipped пропущено');
    } catch (e) {
      print('❌ Ошибка импорта USDA данных: $e');
      rethrow;
    }
  }

  /// Импорт USDA данных из JSON (assets или файловая система)
  /// 
  /// Формат USDA JSON: массив объектов с полями fdc_id, description, foodNutrients и т.д.
  Future<void> importUSDAJson(String jsonFilePath, {
    Function(int current, int total)? onProgress,
    bool fromAssets = false,
  }) async {
    try {
      String jsonString;
      
      if (fromAssets) {
        // Чтение из assets
        print('📂 Загрузка файла из assets: $jsonFilePath');
        try {
          jsonString = await rootBundle.loadString(jsonFilePath);
          print('✅ Файл загружен, размер: ${jsonString.length} символов');
        } catch (e) {
          print('❌ Ошибка загрузки файла из assets: $e');
          print('Проверьте, что файл добавлен в pubspec.yaml в секции assets');
          rethrow;
        }
      } else {
        // Чтение из файловой системы
        final file = File(jsonFilePath);
        if (!await file.exists()) {
          throw FileSystemException('File not found: $jsonFilePath');
        }
        jsonString = await file.readAsString();
      }

      print('🔄 Парсинг JSON...');
      final jsonData = json.decode(jsonString) as List<dynamic>;
      print('✅ JSON распарсен, записей: ${jsonData.length}');
      print('📥 Начало импорта USDA JSON данных: ${jsonData.length} записей');

      final foodsBox = Hive.box(HiveService.foodsBox) as Box<FoodItem>;
      final barcodesBox = Hive.box(HiveService.barcodesBox) as Box<String>;

      int imported = 0;
      int skipped = 0;

      for (int i = 0; i < jsonData.length; i++) {
        try {
          final foodData = jsonData[i] as Map<String, dynamic>;
          final food = _createFoodItemFromUSDAJson(foodData);
          
          if (food != null) {
            await foodsBox.put(food.id, food);
            
            // Сохранить штрих-код если есть
            if (food.barcode != null && food.barcode!.isNotEmpty) {
              await barcodesBox.put(food.barcode!, food.id);
            }
            
            imported++;
          } else {
            skipped++;
          }

          // Прогресс
          if (onProgress != null && (i + 1) % 100 == 0) {
            onProgress(i + 1, jsonData.length);
          }
        } catch (e) {
          print('⚠️ Ошибка при обработке записи ${i + 1}: $e');
          skipped++;
        }
      }

      print('✅ Импорт завершен: $imported импортировано, $skipped пропущено');
    } catch (e) {
      print('❌ Ошибка импорта USDA JSON данных: $e');
      rethrow;
    }
  }

  /// Импорт рецептов из JSON (assets или файловая система)
  /// 
  /// Формат JSON: массив объектов Recipe
  Future<void> importRecipes(String jsonFilePath, {
    Function(int current, int total)? onProgress,
    bool fromAssets = false,
  }) async {
    try {
      String jsonString;
      
      if (fromAssets) {
        // Чтение из assets
        print('📂 Загрузка рецептов из assets: $jsonFilePath');
        try {
          jsonString = await rootBundle.loadString(jsonFilePath);
          print('✅ Файл рецептов загружен, размер: ${jsonString.length} символов');
        } catch (e) {
          print('❌ Ошибка загрузки рецептов из assets: $e');
          rethrow;
        }
      } else {
        // Чтение из файловой системы
        final file = File(jsonFilePath);
        if (!await file.exists()) {
          throw FileSystemException('File not found: $jsonFilePath');
        }
        jsonString = await file.readAsString();
      }

      print('🔄 Парсинг JSON рецептов...');
      final jsonData = json.decode(jsonString) as List<dynamic>;
      print('✅ JSON рецептов распарсен, записей: ${jsonData.length}');
      print('📥 Начало импорта рецептов: ${jsonData.length} записей');

      final recipesBox = Hive.box(HiveService.recipesBox) as Box<Recipe>;

      int imported = 0;
      int skipped = 0;

      for (int i = 0; i < jsonData.length; i++) {
        try {
          final recipeData = jsonData[i] as Map<String, dynamic>;
          final recipe = Recipe.fromMap(recipeData);
          
          await recipesBox.put(recipe.id, recipe);
          imported++;

          // Прогресс
          if (onProgress != null && (i + 1) % 50 == 0) {
            onProgress(i + 1, jsonData.length);
          }
        } catch (e) {
          print('⚠️ Ошибка при обработке рецепта ${i + 1}: $e');
          skipped++;
        }
      }

      print('✅ Импорт рецептов завершен: $imported импортировано, $skipped пропущено');
    } catch (e) {
      print('❌ Ошибка импорта рецептов: $e');
      rethrow;
    }
  }

  /// Создание индекса для быстрого поиска
  /// 
  /// Создает индекс по названиям продуктов для ускорения поиска
  Future<void> buildSearchIndex() async {
    try {
      print('🔍 Создание индекса поиска...');
      
      final foodsBox = Hive.box(HiveService.foodsBox) as Box<FoodItem>;
      
      // Открыть коробку индекса, если она еще не открыта
      Box<List<String>> indexBox;
      if (Hive.isBoxOpen('search_index')) {
        indexBox = Hive.box('search_index') as Box<List<String>>;
      } else {
        indexBox = await Hive.openBox<List<String>>('search_index');
      }
      
      // Очистить старый индекс
      await indexBox.clear();
      
      final index = <String, List<String>>{};
      
      for (final food in foodsBox.values) {
        // Индексировать по словам в названии (английском и русском)
        final words = [
          ...food.name.toLowerCase().split(RegExp(r'[\s\-_]+')),
          ...food.nameRu.toLowerCase().split(RegExp(r'[\s\-_]+')),
        ];
        
        for (final word in words) {
          if (word.length >= 2) { // Игнорировать слишком короткие слова
            if (!index.containsKey(word)) {
              index[word] = [];
            }
            if (!index[word]!.contains(food.id)) {
              index[word]!.add(food.id);
            }
          }
        }
      }
      
      // Сохранить индекс
      for (final entry in index.entries) {
        await indexBox.put(entry.key, entry.value);
      }
      
      print('✅ Индекс создан: ${index.length} ключей');
    } catch (e) {
      print('❌ Ошибка создания индекса: $e');
      rethrow;
    }
  }

  // ========== Приватные методы парсинга ==========

  /// Парсинг CSV строки с учетом кавычек
  List<String> _parseCSVLine(String line) {
    final result = <String>[];
    final current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    
    result.add(current.toString());
    return result;
  }

  /// Создание FoodItem из USDA CSV данных
  /// 
  /// Это упрощенная версия - полный парсинг требует знания структуры USDA CSV
  FoodItem? _createFoodItemFromUSDA(List<String> fields, String header) {
    try {
      // Базовые поля (зависит от формата USDA)
      // Примерная структура: fdc_id, description, data_type, ...
      if (fields.length < 2) return null;
      
      final id = fields[0].trim();
      final description = fields[1].trim();
      
      if (id.isEmpty || description.isEmpty) return null;
      
      // Упрощенная версия - нужно будет доработать под реальный формат USDA
      // Здесь предполагаем, что у нас есть поля с нутриентами
      return FoodItem(
        id: 'usda_$id',
        name: description,
        nameRu: description, // TODO: добавить перевод
        calories: 0, // TODO: извлечь из foodNutrients
        protein: 0,
        fat: 0,
        carbs: 0,
        category: FoodCategory.other,
      );
    } catch (e) {
      print('⚠️ Ошибка создания FoodItem из CSV: $e');
      return null;
    }
  }

  /// Создание FoodItem из USDA JSON данных
  FoodItem? _createFoodItemFromUSDAJson(Map<String, dynamic> data) {
    try {
      final fdcId = data['fdc_id']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      
      if (fdcId.isEmpty || description.isEmpty) return null;

      // Извлечение нутриентов из foodNutrients
      final nutrients = data['foodNutrients'] as List<dynamic>? ?? [];
      
      double calories = 0;
      double protein = 0;
      double fat = 0;
      double carbs = 0;
      
      for (final nutrient in nutrients) {
        final nutrientData = nutrient as Map<String, dynamic>;
        // USDA может иметь nutrient как объект или напрямую nutrientId
        final nutrientObj = nutrientData['nutrient'] as Map<String, dynamic>?;
        final nutrientId = nutrientObj?['id'] ?? nutrientData['nutrientId'];
        final amount = (nutrientData['amount'] as num?)?.toDouble() ?? 0;
        
        // USDA Nutrient IDs:
        // 1008 = Energy (kcal) - но может быть 1062 = Energy (kJ), нужно конвертировать
        // 1003 = Protein
        // 1004 = Total lipid (fat)
        // 1005 = Carbohydrate, by difference
        if (nutrientId == 1008) {
          calories = amount;
        } else if (nutrientId == 1062) {
          // Energy в kJ - конвертируем в kcal (1 kcal = 4.184 kJ)
          calories = amount / 4.184;
        } else if (nutrientId == 1003) {
          protein = amount;
        } else if (nutrientId == 1004) {
          fat = amount;
        } else if (nutrientId == 1005) {
          carbs = amount;
        }
      }

      // Определение категории (упрощенно)
      final category = _determineCategory(description);

      // Извлечение штрих-кода если есть
      final barcode = data['gtinUpc']?.toString();

      // Извлечение аллергенов (если есть в данных)
      final allergens = <String>[];
      // TODO: парсинг аллергенов из данных USDA

      return FoodItem(
        id: 'usda_$fdcId',
        name: description,
        nameRu: description, // TODO: добавить перевод
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        category: category,
        barcode: barcode,
        allergens: allergens,
      );
    } catch (e) {
      print('⚠️ Ошибка создания FoodItem из JSON: $e');
      return null;
    }
  }

  /// Определение категории продукта по описанию
  FoodCategory _determineCategory(String description) {
    final desc = description.toLowerCase();
    
    // Простая эвристика для определения категории
    if (desc.contains('fruit') || desc.contains('apple') || desc.contains('banana')) {
      return FoodCategory.fruits;
    } else if (desc.contains('vegetable') || desc.contains('carrot') || desc.contains('tomato')) {
      return FoodCategory.vegetables;
    } else if (desc.contains('grain') || desc.contains('rice') || desc.contains('wheat')) {
      return FoodCategory.grains;
    } else if (desc.contains('meat') || desc.contains('chicken') || desc.contains('beef') || desc.contains('fish')) {
      return FoodCategory.protein;
    } else if (desc.contains('milk') || desc.contains('cheese') || desc.contains('yogurt')) {
      return FoodCategory.dairy;
    } else if (desc.contains('oil') || desc.contains('butter')) {
      return FoodCategory.fats;
    } else if (desc.contains('sugar') || desc.contains('candy') || desc.contains('chocolate')) {
      return FoodCategory.sweets;
    } else if (desc.contains('juice') || desc.contains('drink') || desc.contains('beverage')) {
      return FoodCategory.beverages;
    }
    
    return FoodCategory.other;
  }
}
