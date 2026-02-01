import 'package:flutter_test/flutter_test.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';

/// Тесты производительности и нагрузки
void main() {
  group('Performance Tests', () {
    setUpAll(() async {
      await HiveService.initialize();
    });

    tearDownAll(() async {
      await HiveService.clearAll();
      await HiveService.close();
    });

    setUp(() async {
      await HiveService.clearAll();
    });

    test('Производительность сохранения большого количества записей', () async {
      const recordCount = 1000;
      final stopwatch = Stopwatch()..start();

      // Создаем и сохраняем 1000 записей
      for (int i = 0; i < recordCount; i++) {
        final foodItem = FoodItem(
          id: 'food_$i',
          name: 'Product $i',
          nameRu: 'Продукт $i',
          category: FoodCategory.grains,
          calories: 100 + (i % 50).toDouble(),
          protein: 5.0 + (i % 10),
          fat: 2.0 + (i % 5),
          carbs: 20.0 + (i % 15),
        );

        final grams = 100 + (i % 200).toDouble();
        final macros = foodItem.calculateMacros(grams);
        
        final foodLog = FoodLog(
          id: 'log_$i',
          userId: 'performance_user',
          foodId: foodItem.id,
          foodName: foodItem.nameRu,
          grams: grams,
          mealType: MealType.values[i % MealType.values.length],
          timestamp: DateTime.now().subtract(Duration(minutes: i)),
          calories: macros.calories,
          protein: macros.protein,
          fat: macros.fat,
          carbs: macros.carbs,
        );

        await HiveService.put(
          box: HiveService.mealsBox,
          key: foodLog.id,
          value: foodLog,
        );
      }

      stopwatch.stop();
      final saveTime = stopwatch.elapsedMilliseconds;

      print('Время сохранения $recordCount записей: ${saveTime}ms');
      print('Среднее время на запись: ${saveTime / recordCount}ms');

      // Проверяем что время сохранения разумное (менее 10 секунд)
      expect(saveTime, lessThan(10000));

      // Проверяем что все записи сохранились
      final testRecord = HiveService.get(
        box: HiveService.mealsBox,
        key: 'log_${recordCount - 1}',
      ) as FoodLog?;
      expect(testRecord, isNotNull);
    });

    test('Производительность чтения большого количества записей', () async {
      const recordCount = 500;

      // Сначала создаем записи
      for (int i = 0; i < recordCount; i++) {
        final data = {
          'id': 'record_$i',
          'value': 'test_value_$i',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        await HiveService.put(
          box: 'performance_test',
          key: 'record_$i',
          value: data,
        );
      }

      // Измеряем время чтения
      final stopwatch = Stopwatch()..start();

      final readRecords = <Map<String, dynamic>>[];
      for (int i = 0; i < recordCount; i++) {
        final record = HiveService.get(
          box: 'performance_test',
          key: 'record_$i',
        ) as Map<String, dynamic>?;
        
        if (record != null) {
          readRecords.add(record);
        }
      }

      stopwatch.stop();
      final readTime = stopwatch.elapsedMilliseconds;

      print('Время чтения $recordCount записей: ${readTime}ms');
      print('Среднее время на чтение: ${readTime / recordCount}ms');

      // Проверяем производительность (менее 5 секунд)
      expect(readTime, lessThan(5000));
      expect(readRecords.length, equals(recordCount));
    });

    test('Тест памяти при работе с большими объектами', () async {
      // Создаем большой объект пользователя с историей
      final largeProfile = UserProfile(
        userId: 'memory_test_user',
        age: 30,
        height: 175,
        weight: 70,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.maintain,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        allergies: List.generate(100, (i) => 'Аллерген $i'), // Большой список
        contraindications: List.generate(50, (i) => 'Противопоказание $i'),
      );

      final stopwatch = Stopwatch()..start();

      // Сохраняем и загружаем большой объект несколько раз
      for (int i = 0; i < 100; i++) {
        await HiveService.put(
          box: HiveService.userBox,
          key: 'large_profile_$i',
          value: largeProfile,
        );

        final loaded = HiveService.get(
          box: HiveService.userBox,
          key: 'large_profile_$i',
        ) as UserProfile?;

        expect(loaded, isNotNull);
        expect(loaded!.allergies.length, equals(100));
      }

      stopwatch.stop();
      print('Время работы с большими объектами: ${stopwatch.elapsedMilliseconds}ms');

      // Проверяем что операции выполняются быстро
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    test('Стресс-тест: одновременные операции чтения/записи', () async {
      const operationCount = 200;
      final futures = <Future>[];

      final stopwatch = Stopwatch()..start();

      // Запускаем множество операций параллельно
      for (int i = 0; i < operationCount; i++) {
        // Операции записи
        futures.add(
          HiveService.put(
            box: 'stress_test',
            key: 'write_$i',
            value: {
              'data': 'test_data_$i',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'index': i,
            },
          ),
        );

        // Операции чтения (если данные уже есть)
        if (i > 10) {
          futures.add(
            Future(() {
              return HiveService.get(
                box: 'stress_test',
                key: 'write_${i - 10}',
              );
            }),
          );
        }
      }

      // Ждем завершения всех операций
      await Future.wait(futures);

      stopwatch.stop();
      print('Время выполнения $operationCount параллельных операций: ${stopwatch.elapsedMilliseconds}ms');

      // Проверяем что все операции завершились успешно
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));

      // Проверяем целостность данных
      final testRecord = HiveService.get(
        box: 'stress_test',
        key: 'write_${operationCount - 1}',
      ) as Map<String, dynamic>?;
      expect(testRecord, isNotNull);
      expect(testRecord!['index'], equals(operationCount - 1));
    });

    test('Тест производительности поиска в больших данных', () async {
      const dataSize = 1000;
      final searchTerms = ['яблоко', 'банан', 'молоко', 'хлеб', 'мясо'];

      // Создаем большую базу продуктов
      for (int i = 0; i < dataSize; i++) {
        final randomTerm = searchTerms[i % searchTerms.length];
        final foodItem = {
          'id': 'food_$i',
          'name': '$randomTerm $i',
          'category': 'category_${i % 10}',
          'calories': 100 + (i % 300),
          'searchable': '$randomTerm $i category_${i % 10}'.toLowerCase(),
        };

        await HiveService.put(
          box: 'food_database',
          key: 'food_$i',
          value: foodItem,
        );
      }

      // Тестируем поиск
      final stopwatch = Stopwatch()..start();

      final searchResults = <Map<String, dynamic>>[];
      const searchTerm = 'яблоко';

      // Простой поиск по всем записям
      for (int i = 0; i < dataSize; i++) {
        final item = HiveService.get(
          box: 'food_database',
          key: 'food_$i',
        ) as Map<String, dynamic>?;

        if (item != null && 
            item['searchable'].toString().contains(searchTerm.toLowerCase())) {
          searchResults.add(item);
        }
      }

      stopwatch.stop();
      print('Время поиска в $dataSize записях: ${stopwatch.elapsedMilliseconds}ms');
      print('Найдено результатов: ${searchResults.length}');

      // Проверяем производительность поиска
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(searchResults.length, greaterThan(0));
    });

    test('Тест производительности очистки данных', () async {
      const recordCount = 500;

      // Создаем данные для очистки
      for (int i = 0; i < recordCount; i++) {
        await HiveService.put(
          box: 'cleanup_test',
          key: 'record_$i',
          value: {'data': 'test_$i'},
        );
      }

      // Проверяем что данные созданы
      final beforeCleanup = HiveService.get(box: 'cleanup_test', key: 'record_0');
      expect(beforeCleanup, isNotNull);

      // Измеряем время очистки
      final stopwatch = Stopwatch()..start();
      await HiveService.clearBox('cleanup_test');
      stopwatch.stop();

      print('Время очистки $recordCount записей: ${stopwatch.elapsedMilliseconds}ms');

      // Проверяем что очистка быстрая
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Проверяем что данные удалены
      final afterCleanup = HiveService.get(box: 'cleanup_test', key: 'record_0');
      expect(afterCleanup, isNull);
    });
  });
}