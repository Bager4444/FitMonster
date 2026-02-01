import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

// Мок-сервис для тестов производительности
class MockPerformanceService {
  static final Map<String, Box> _boxes = {};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    Hive.init('./test/hive_performance');
    _initialized = true;
  }

  static Future<Box> getBox(String boxName) async {
    if (!_boxes.containsKey(boxName)) {
      _boxes[boxName] = await Hive.openBox(boxName);
    }
    return _boxes[boxName]!;
  }

  static Future<void> put(String box, String key, dynamic value) async {
    final boxInstance = await getBox(box);
    await boxInstance.put(key, value);
  }

  static Future<dynamic> get(String box, String key) async {
    final boxInstance = await getBox(box);
    return boxInstance.get(key);
  }

  static Future<void> clearBox(String box) async {
    final boxInstance = await getBox(box);
    await boxInstance.clear();
  }

  static Future<void> clearAll() async {
    for (final box in _boxes.values) {
      await box.clear();
    }
  }

  static Future<void> close() async {
    for (final box in _boxes.values) {
      await box.close();
    }
    _boxes.clear();
    _initialized = false;
  }
}

/// Тесты производительности и нагрузки
void main() {
  group('Performance Tests', () {
    setUpAll(() async {
      await MockPerformanceService.initialize();
    });

    tearDownAll(() async {
      await MockPerformanceService.close();
    });

    setUp(() async {
      await MockPerformanceService.clearAll();
    });

    test('Производительность сохранения большого количества записей', () async {
      const recordCount = 1000;
      final stopwatch = Stopwatch()..start();

      // Создаем и сохраняем 1000 записей
      for (int i = 0; i < recordCount; i++) {
        final data = {
          'id': 'record_$i',
          'name': 'Продукт $i',
          'calories': 100 + (i % 50),
          'protein': 5.0 + (i % 10),
          'fat': 2.0 + (i % 5),
          'carbs': 20.0 + (i % 15),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        await MockPerformanceService.put('performance_test', 'record_$i', data);
      }

      stopwatch.stop();
      final saveTime = stopwatch.elapsedMilliseconds;

      print('Время сохранения $recordCount записей: ${saveTime}ms');
      print('Среднее время на запись: ${saveTime / recordCount}ms');

      // Проверяем что время сохранения разумное (менее 10 секунд)
      expect(saveTime, lessThan(10000));

      // Проверяем что все записи сохранились
      final testRecord = await MockPerformanceService.get('performance_test', 'record_${recordCount - 1}');
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

        await MockPerformanceService.put('performance_test', 'record_$i', data);
      }

      // Измеряем время чтения
      final stopwatch = Stopwatch()..start();

      final readRecords = <Map<String, dynamic>>[];
      for (int i = 0; i < recordCount; i++) {
        final record = await MockPerformanceService.get('performance_test', 'record_$i') as Map<String, dynamic>?;
        
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
      // Создаем большой объект
      final largeData = {
        'userId': 'memory_test_user',
        'profile': {
          'age': 30,
          'height': 175,
          'weight': 70,
          'allergies': List.generate(100, (i) => 'Аллерген $i'),
          'contraindications': List.generate(50, (i) => 'Противопоказание $i'),
        },
        'history': List.generate(200, (i) => {
          'date': DateTime.now().subtract(Duration(days: i)).toIso8601String(),
          'weight': 70 + (i % 10),
          'calories': 2000 + (i % 500),
        }),
      };

      final stopwatch = Stopwatch()..start();

      // Сохраняем и загружаем большой объект несколько раз
      for (int i = 0; i < 100; i++) {
        await MockPerformanceService.put('memory_test', 'large_data_$i', largeData);

        final loaded = await MockPerformanceService.get('memory_test', 'large_data_$i');
        expect(loaded, isNotNull);
      }

      stopwatch.stop();
      print('Время работы с большими объектами: ${stopwatch.elapsedMilliseconds}ms');

      // Проверяем что операции выполняются быстро
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('Стресс-тест: одновременные операции чтения/записи', () async {
      const operationCount = 200;
      final futures = <Future>[];

      final stopwatch = Stopwatch()..start();

      // Запускаем множество операций параллельно
      for (int i = 0; i < operationCount; i++) {
        // Операции записи
        futures.add(
          MockPerformanceService.put(
            'stress_test',
            'write_$i',
            {
              'data': 'test_data_$i',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'index': i,
            },
          ),
        );

        // Операции чтения (если данные уже есть)
        if (i > 10) {
          futures.add(
            MockPerformanceService.get('stress_test', 'write_${i - 10}'),
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
      final testRecord = await MockPerformanceService.get('stress_test', 'write_${operationCount - 1}') as Map<String, dynamic>?;
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

        await MockPerformanceService.put('food_database', 'food_$i', foodItem);
      }

      // Тестируем поиск
      final stopwatch = Stopwatch()..start();

      final searchResults = <Map<String, dynamic>>[];
      const searchTerm = 'яблоко';

      // Простой поиск по всем записям
      for (int i = 0; i < dataSize; i++) {
        final item = await MockPerformanceService.get('food_database', 'food_$i') as Map<String, dynamic>?;

        if (item != null && 
            item['searchable'].toString().contains(searchTerm.toLowerCase())) {
          searchResults.add(item);
        }
      }

      stopwatch.stop();
      print('Время поиска в $dataSize записях: ${stopwatch.elapsedMilliseconds}ms');
      print('Найдено результатов: ${searchResults.length}');

      // Проверяем производительность поиска
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      expect(searchResults.length, greaterThan(0));
    });

    test('Тест производительности очистки данных', () async {
      const recordCount = 500;

      // Создаем данные для очистки
      for (int i = 0; i < recordCount; i++) {
        await MockPerformanceService.put('cleanup_test', 'record_$i', {'data': 'test_$i'});
      }

      // Проверяем что данные созданы
      final beforeCleanup = await MockPerformanceService.get('cleanup_test', 'record_0');
      expect(beforeCleanup, isNotNull);

      // Измеряем время очистки
      final stopwatch = Stopwatch()..start();
      await MockPerformanceService.clearBox('cleanup_test');
      stopwatch.stop();

      print('Время очистки $recordCount записей: ${stopwatch.elapsedMilliseconds}ms');

      // Проверяем что очистка быстрая
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));

      // Проверяем что данные удалены
      final afterCleanup = await MockPerformanceService.get('cleanup_test', 'record_0');
      expect(afterCleanup, isNull);
    });
  });
}