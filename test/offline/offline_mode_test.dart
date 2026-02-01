import 'package:flutter_test/flutter_test.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';

/// Тесты для проверки оффлайн-режима
void main() {
  group('Offline Mode Tests', () {
    setUpAll(() async {
      await HiveService.initialize();
    });

    tearDownAll(() async {
      await HiveService.clearAll();
      await HiveService.close();
    });

    setUp(() async {
      // Очищаем данные перед каждым тестом
      await HiveService.clearAll();
    });

    test('Сохранение данных пользователя в оффлайне', () async {
      final userProfile = UserProfile(
        userId: 'offline_user_1',
        age: 25,
        height: 170,
        weight: 65,
        gender: Gender.female,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.lose,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        allergies: ['Глютен'],
        contraindications: [],
      );

      // Сохраняем профиль в оффлайне
      await HiveService.put(
        box: HiveService.userBox,
        key: 'current_user',
        value: userProfile,
      );

      // Проверяем что данные сохранились
      final savedProfile = HiveService.get(
        box: HiveService.userBox,
        key: 'current_user',
      ) as UserProfile?;

      expect(savedProfile, isNotNull);
      expect(savedProfile!.userId, equals(userProfile.userId));
      expect(savedProfile.allergies, equals(['Глютен']));
    });

    test('Сохранение журнала питания в оффлайне', () async {
      final foodItem = FoodItem(
        id: 'apple_001',
        name: 'Apple',
        nameRu: 'Яблоко',
        calories: 52,
        protein: 0.3,
        fat: 0.2,
        carbs: 14,
        category: FoodCategory.fruits,
      );

      final foodLog = FoodLog(
        id: 'log_001',
        userId: 'offline_user_1',
        foodId: foodItem.id,
        foodName: foodItem.nameRu,
        grams: 150, // грамм
        calories: 78, // 52 * 1.5
        protein: 0.45,
        fat: 0.3,
        carbs: 21,
        mealType: MealType.breakfast,
        timestamp: DateTime.now(),
      );

      // Сохраняем в оффлайне
      await HiveService.put(
        box: HiveService.mealsBox,
        key: foodLog.id,
        value: foodLog,
      );

      // Проверяем сохранение
      final savedLog = HiveService.get(
        box: HiveService.mealsBox,
        key: foodLog.id,
      ) as FoodLog?;

      expect(savedLog, isNotNull);
      expect(savedLog!.foodName, equals('Яблоко'));
      expect(savedLog.grams, equals(150));
      expect(savedLog.calories, equals(78));
    });

    test('Работа с множественными записями в оффлайне', () async {
      final logs = <FoodLog>[];
      
      // Создаем несколько записей
      for (int i = 0; i < 5; i++) {
        final foodItem = FoodItem(
          id: 'food_$i',
          name: 'Product $i',
          nameRu: 'Продукт $i',
          calories: 100 + i * 10,
          protein: 5.0,
          fat: 2.0,
          carbs: 20.0,
          category: FoodCategory.grains,
        );

        final log = FoodLog(
          id: 'log_$i',
          userId: 'offline_user_1',
          foodId: foodItem.id,
          foodName: foodItem.nameRu,
          grams: 100,
          calories: 100 + i * 10,
          protein: 5.0,
          fat: 2.0,
          carbs: 20.0,
          mealType: MealType.lunch,
          timestamp: DateTime.now().subtract(Duration(hours: i)),
        );

        logs.add(log);
        
        // Сохраняем каждую запись
        await HiveService.put(
          box: HiveService.mealsBox,
          key: log.id,
          value: log,
        );
      }

      // Проверяем что все записи сохранились
      for (int i = 0; i < 5; i++) {
        final savedLog = HiveService.get(
          box: HiveService.mealsBox,
          key: 'log_$i',
        ) as FoodLog?;

        expect(savedLog, isNotNull);
        expect(savedLog!.foodName, equals('Продукт $i'));
        expect(savedLog.calories, equals(100 + i * 10));
      }
    });

    test('Синхронизация данных при восстановлении соединения', () async {
      // Симуляция оффлайн-данных
      final offlineData = <String, dynamic>{
        'pending_sync_1': {
          'type': 'food_log',
          'data': 'serialized_food_log_data',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'pending_sync_2': {
          'type': 'user_profile_update',
          'data': 'serialized_profile_data',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      };

      // Сохраняем данные ожидающие синхронизации
      for (final entry in offlineData.entries) {
        await HiveService.put(
          box: 'sync_queue',
          key: entry.key,
          value: entry.value,
        );
      }

      // Проверяем что данные сохранились в очереди синхронизации
      final syncData1 = HiveService.get(box: 'sync_queue', key: 'pending_sync_1');
      final syncData2 = HiveService.get(box: 'sync_queue', key: 'pending_sync_2');

      expect(syncData1, isNotNull);
      expect(syncData2, isNotNull);
      expect(syncData1['type'], equals('food_log'));
      expect(syncData2['type'], equals('user_profile_update'));

      // Симуляция успешной синхронизации - удаляем из очереди
      await HiveService.delete(box: 'sync_queue', key: 'pending_sync_1');
      await HiveService.delete(box: 'sync_queue', key: 'pending_sync_2');

      // Проверяем что данные удалились из очереди
      expect(HiveService.get(box: 'sync_queue', key: 'pending_sync_1'), isNull);
      expect(HiveService.get(box: 'sync_queue', key: 'pending_sync_2'), isNull);
    });

    test('Кеширование данных для оффлайн-доступа', () async {
      // Симуляция кеширования данных с сервера
      final cachedExercises = [
        {
          'id': 'ex_001',
          'name': 'Отжимания',
          'muscle_groups': ['Грудь', 'Трицепс'],
          'difficulty': 'Средний',
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
        {
          'id': 'ex_002',
          'name': 'Приседания',
          'muscle_groups': ['Ноги', 'Ягодицы'],
          'difficulty': 'Легкий',
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
      ];

      // Сохраняем кешированные упражнения
      await HiveService.put(
        box: 'cache',
        key: 'exercises',
        value: cachedExercises,
      );

      // Проверяем доступность в оффлайне
      final offlineExercises = HiveService.get(
        box: 'cache',
        key: 'exercises',
      ) as List<dynamic>?;

      expect(offlineExercises, isNotNull);
      expect(offlineExercises!.length, equals(2));
      expect(offlineExercises[0]['name'], equals('Отжимания'));
      expect(offlineExercises[1]['name'], equals('Приседания'));
    });

    test('Проверка времени жизни кеша', () async {
      final now = DateTime.now();
      final oldTimestamp = now.subtract(Duration(days: 8)).millisecondsSinceEpoch;
      final freshTimestamp = now.subtract(Duration(hours: 1)).millisecondsSinceEpoch;

      // Сохраняем данные с разными временными метками
      await HiveService.put(
        box: 'cache',
        key: 'old_data',
        value: {
          'content': 'старые данные',
          'cached_at': oldTimestamp,
        },
      );

      await HiveService.put(
        box: 'cache',
        key: 'fresh_data',
        value: {
          'content': 'свежие данные',
          'cached_at': freshTimestamp,
        },
      );

      // Функция проверки актуальности кеша (7 дней)
      bool isCacheValid(Map<String, dynamic> cacheData) {
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cacheData['cached_at']);
        final maxAge = Duration(days: 7);
        return DateTime.now().difference(cachedAt) < maxAge;
      }

      final oldData = HiveService.get(box: 'cache', key: 'old_data') as Map<String, dynamic>;
      final freshData = HiveService.get(box: 'cache', key: 'fresh_data') as Map<String, dynamic>;

      expect(isCacheValid(oldData), isFalse); // Старые данные устарели
      expect(isCacheValid(freshData), isTrue); // Свежие данные актуальны
    });

    test('Обработка конфликтов при синхронизации', () async {
      // Локальная версия данных (изменена в оффлайне)
      final localProfile = UserProfile(
        userId: 'conflict_user',
        age: 30,
        height: 175,
        weight: 70, // Изменено локально
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.maintain,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        updatedAt: DateTime.now(), // Обновлено недавно
      );

      // Серверная версия данных
      final serverProfile = UserProfile(
        userId: 'conflict_user',
        age: 30,
        height: 175,
        weight: 72, // Другое значение с сервера
        gender: Gender.male,
        activityLevel: ActivityLevel.active, // Изменено на сервере
        goal: Goal.maintain,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        updatedAt: DateTime.now().subtract(Duration(minutes: 30)), // Старше локального
      );

      // Сохраняем локальную версию
      await HiveService.put(
        box: HiveService.userBox,
        key: 'conflict_user_local',
        value: localProfile,
      );

      // Сохраняем серверную версию
      await HiveService.put(
        box: HiveService.userBox,
        key: 'conflict_user_server',
        value: serverProfile,
      );

      // Функция разрешения конфликтов (приоритет у более свежих данных)
      UserProfile resolveConflict(UserProfile local, UserProfile server) {
        if (local.updatedAt.isAfter(server.updatedAt)) {
          return local; // Локальные данные новее
        } else {
          return server; // Серверные данные новее
        }
      }

      final resolved = resolveConflict(localProfile, serverProfile);
      
      // В данном случае локальные данные новее
      expect(resolved.weight, equals(70)); // Локальное значение
      expect(resolved.updatedAt, equals(localProfile.updatedAt));
    });
  });
}