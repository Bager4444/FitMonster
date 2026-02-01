import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitmonster/main.dart' as app;
import 'package:fitmonster/core/services/hive_service.dart';

/// Integration тесты для основных пользовательских сценариев
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Flow Integration Tests', () {
    setUpAll(() async {
      await HiveService.initialize();
    });

    tearDownAll(() async {
      await HiveService.clearAll();
      await HiveService.close();
    });

    testWidgets('Полный цикл: регистрация -> настройка профиля -> добавление еды', (tester) async {
      // Запускаем приложение
      app.main();
      await tester.pumpAndSettle();

      // Шаг 1: Проверяем экран приветствия/входа
      expect(find.text('FitMonster'), findsOneWidget);

      // Шаг 2: Переходим к созданию профиля (если есть кнопка)
      final createProfileButton = find.text('Создать профиль');
      if (createProfileButton.evaluate().isNotEmpty) {
        await tester.tap(createProfileButton);
        await tester.pumpAndSettle();
      }

      // Шаг 3: Заполняем данные профиля
      await tester.enterText(find.byKey(Key('age_field')), '25');
      await tester.enterText(find.byKey(Key('height_field')), '170');
      await tester.enterText(find.byKey(Key('weight_field')), '65');
      
      // Выбираем пол
      await tester.tap(find.byKey(Key('gender_female')));
      await tester.pumpAndSettle();

      // Выбираем уровень активности
      await tester.tap(find.byKey(Key('activity_moderate')));
      await tester.pumpAndSettle();

      // Выбираем цель
      await tester.tap(find.byKey(Key('goal_lose')));
      await tester.pumpAndSettle();

      // Сохраняем профиль
      await tester.tap(find.byKey(Key('save_profile_button')));
      await tester.pumpAndSettle();

      // Шаг 4: Проверяем переход на главный экран
      expect(find.text('Главная'), findsOneWidget);

      // Шаг 5: Переходим к добавлению еды
      await tester.tap(find.byIcon(Icons.restaurant));
      await tester.pumpAndSettle();

      // Шаг 6: Добавляем продукт
      await tester.tap(find.byKey(Key('add_food_button')));
      await tester.pumpAndSettle();

      // Ищем продукт
      await tester.enterText(find.byKey(Key('food_search')), 'яблоко');
      await tester.pumpAndSettle();

      // Выбираем первый результат
      await tester.tap(find.byKey(Key('food_item_0')));
      await tester.pumpAndSettle();

      // Указываем количество
      await tester.enterText(find.byKey(Key('quantity_field')), '150');
      
      // Сохраняем
      await tester.tap(find.byKey(Key('save_food_log')));
      await tester.pumpAndSettle();

      // Шаг 7: Проверяем что еда добавилась
      expect(find.text('Яблоко'), findsOneWidget);
      expect(find.text('150 г'), findsOneWidget);
    });

    testWidgets('Тест оффлайн-режима: сохранение данных без интернета', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Симулируем отсутствие интернета
      // (в реальном тесте можно использовать mock для проверки сетевых запросов)
      
      // Добавляем данные в оффлайне
      await tester.tap(find.byIcon(Icons.restaurant));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('add_food_button')));
      await tester.pumpAndSettle();

      // Добавляем продукт из локального кеша
      await tester.enterText(find.byKey(Key('food_search')), 'банан');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('food_item_0')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('quantity_field')), '120');
      await tester.tap(find.byKey(Key('save_food_log')));
      await tester.pumpAndSettle();

      // Проверяем что данные сохранились локально
      expect(find.text('Банан'), findsOneWidget);
      
      // Проверяем индикатор оффлайн-режима
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('Тест камеры для упражнений', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переходим к упражнениям
      await tester.tap(find.byIcon(Icons.fitness_center));
      await tester.pumpAndSettle();

      // Выбираем упражнение
      await tester.tap(find.text('Отжимания'));
      await tester.pumpAndSettle();

      // Запускаем камеру для проверки техники
      await tester.tap(find.byKey(Key('start_exercise_camera')));
      await tester.pumpAndSettle();

      // Проверяем что камера запустилась
      expect(find.text('Камера'), findsOneWidget);
      expect(find.text('Проверка техники'), findsOneWidget);

      // Симулируем завершение упражнения
      await tester.tap(find.byKey(Key('stop_exercise')));
      await tester.pumpAndSettle();

      // Проверяем результаты
      expect(find.text('Упражнение завершено'), findsOneWidget);
      expect(find.text('Техника: Хорошо'), findsOneWidget);
    });

    testWidgets('Тест настроек и безопасности', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переходим в настройки
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Проверяем настройки приватности
      expect(find.text('Приватность'), findsOneWidget);
      
      // Включаем шифрование данных
      await tester.tap(find.byKey(Key('encryption_toggle')));
      await tester.pumpAndSettle();

      // Проверяем что настройка сохранилась
      final encryptionSwitch = tester.widget<Switch>(find.byKey(Key('encryption_toggle')));
      expect(encryptionSwitch.value, isTrue);

      // Тестируем экспорт данных
      await tester.tap(find.text('Экспорт данных'));
      await tester.pumpAndSettle();

      expect(find.text('Данные экспортированы'), findsOneWidget);

      // Тестируем удаление аккаунта
      await tester.tap(find.text('Удалить аккаунт'));
      await tester.pumpAndSettle();

      // Подтверждаем удаление
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();

      // Проверяем что вернулись на экран входа
      expect(find.text('Добро пожаловать'), findsOneWidget);
    });

    testWidgets('Тест синхронизации данных', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Добавляем данные в оффлайне
      await tester.tap(find.byIcon(Icons.restaurant));
      await tester.pumpAndSettle();

      // Добавляем несколько записей
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('add_food_button')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(Key('food_search')), 'продукт $i');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(Key('food_item_0')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(Key('quantity_field')), '100');
        await tester.tap(find.byKey(Key('save_food_log')));
        await tester.pumpAndSettle();
      }

      // Симулируем восстановление соединения
      await tester.tap(find.byKey(Key('sync_button')));
      await tester.pumpAndSettle();

      // Ждем завершения синхронизации
      await tester.pump(Duration(seconds: 2));

      // Проверяем что данные синхронизировались
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.text('Синхронизация завершена'), findsOneWidget);
    });
  });
}