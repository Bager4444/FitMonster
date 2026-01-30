import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';

// Мок-версия HiveService для тестов
class MockHiveService {
  static final Map<String, Box> _boxes = {};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    Hive.init('./test/hive_test');
    
    // Регистрируем адаптеры если нужно
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(GenderAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ActivityLevelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(GoalAdapter());
    }
    
    _initialized = true;
  }

  static Future<Box> getBox(String boxName) async {
    if (!_boxes.containsKey(boxName)) {
      _boxes[boxName] = await Hive.openBox(boxName);
    }
    return _boxes[boxName]!;
  }

  static Future<void> put({
    required String box,
    required String key,
    required dynamic value,
  }) async {
    final boxInstance = await getBox(box);
    await boxInstance.put(key, value);
  }

  static Future<dynamic> get({
    required String box,
    required String key,
    dynamic defaultValue,
  }) async {
    final boxInstance = await getBox(box);
    return boxInstance.get(key, defaultValue: defaultValue);
  }

  static Future<void> delete({
    required String box,
    required String key,
  }) async {
    final boxInstance = await getBox(box);
    await boxInstance.delete(key);
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

  // Константы боксов
  static const String userBox = 'user';
  static const String workoutsBox = 'workouts';
  static const String mealsBox = 'meals';
  static const String settingsBox = 'settings';
}

void main() {
  group('HiveService Tests', () {
    setUpAll(() async {
      await MockHiveService.initialize();
    });

    tearDownAll(() async {
      await MockHiveService.close();
    });

    test('initialize - успешная инициализация', () async {
      await expectLater(MockHiveService.initialize(), completes);
    });

    test('put и get - сохранение и загрузка', () async {
      const testData = 'test_value';
      const boxName = 'test_box';
      const key = 'test_key';

      // Сохраняем данные
      await MockHiveService.put(box: boxName, key: key, value: testData);

      // Загружаем данные
      final loadedData = await MockHiveService.get(box: boxName, key: key);
      expect(loadedData, equals(testData));
    });

    test('put - перезапись данных', () async {
      const boxName = 'test_box';
      const key = 'test_key';
      const oldValue = 'old_value';
      const newValue = 'new_value';

      // Сохраняем старое значение
      await MockHiveService.put(box: boxName, key: key, value: oldValue);
      expect(await MockHiveService.get(box: boxName, key: key), equals(oldValue));

      // Перезаписываем новым значением
      await MockHiveService.put(box: boxName, key: key, value: newValue);
      expect(await MockHiveService.get(box: boxName, key: key), equals(newValue));
    });

    test('delete - удаление данных', () async {
      const boxName = 'test_box';
      const key = 'test_key';
      const testData = 'test_value';

      // Сохраняем данные
      await MockHiveService.put(box: boxName, key: key, value: testData);
      expect(await MockHiveService.get(box: boxName, key: key), equals(testData));

      // Удаляем данные
      await MockHiveService.delete(box: boxName, key: key);
      expect(await MockHiveService.get(box: boxName, key: key), isNull);
    });

    test('clearBox - очистка всего box', () async {
      const boxName = 'test_box';

      // Добавляем несколько записей
      await MockHiveService.put(box: boxName, key: 'key1', value: 'value1');
      await MockHiveService.put(box: boxName, key: 'key2', value: 'value2');

      // Проверяем что данные есть
      expect(await MockHiveService.get(box: boxName, key: 'key1'), equals('value1'));
      expect(await MockHiveService.get(box: boxName, key: 'key2'), equals('value2'));

      // Очищаем box
      await MockHiveService.clearBox(boxName);

      // Проверяем что данные удалены
      expect(await MockHiveService.get(box: boxName, key: 'key1'), isNull);
      expect(await MockHiveService.get(box: boxName, key: 'key2'), isNull);
    });

    test('UserProfile - сохранение и загрузка модели', () async {
      final profile = UserProfile(
        userId: 'test_user',
        age: 30,
        height: 180,
        weight: 80,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.maintain,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        allergies: ['Молоко', 'Орехи'],
        contraindications: ['Диабет'],
      );

      const boxName = MockHiveService.userBox;
      const key = 'test_user';

      // Сохраняем профиль
      await MockHiveService.put(box: boxName, key: key, value: profile);

      // Загружаем профиль
      final loadedProfile = await MockHiveService.get(box: boxName, key: key) as UserProfile?;

      expect(loadedProfile, isNotNull);
      expect(loadedProfile!.userId, equals(profile.userId));
      expect(loadedProfile.age, equals(profile.age));
      expect(loadedProfile.height, equals(profile.height));
      expect(loadedProfile.weight, equals(profile.weight));
      expect(loadedProfile.gender, equals(profile.gender));
      expect(loadedProfile.allergies, equals(profile.allergies));
      expect(loadedProfile.contraindications, equals(profile.contraindications));
    });

    test('get с defaultValue - возврат значения по умолчанию', () async {
      const boxName = 'test_box';
      const key = 'nonexistent_key';
      const defaultValue = 'default';

      final result = await MockHiveService.get(
        box: boxName, 
        key: key, 
        defaultValue: defaultValue,
      );
      expect(result, equals(defaultValue));
    });

    test('clearAll - очистка всех боксов', () async {
      // Добавляем данные в разные боксы
      await MockHiveService.put(box: MockHiveService.userBox, key: 'user1', value: 'data1');
      await MockHiveService.put(box: MockHiveService.workoutsBox, key: 'workout1', value: 'data2');
      await MockHiveService.put(box: MockHiveService.mealsBox, key: 'meal1', value: 'data3');

      // Проверяем что данные есть
      expect(await MockHiveService.get(box: MockHiveService.userBox, key: 'user1'), equals('data1'));
      expect(await MockHiveService.get(box: MockHiveService.workoutsBox, key: 'workout1'), equals('data2'));
      expect(await MockHiveService.get(box: MockHiveService.mealsBox, key: 'meal1'), equals('data3'));

      // Очищаем все
      await MockHiveService.clearAll();

      // Проверяем что все данные удалены
      expect(await MockHiveService.get(box: MockHiveService.userBox, key: 'user1'), isNull);
      expect(await MockHiveService.get(box: MockHiveService.workoutsBox, key: 'workout1'), isNull);
      expect(await MockHiveService.get(box: MockHiveService.mealsBox, key: 'meal1'), isNull);
    });
  });
}