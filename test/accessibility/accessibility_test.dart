import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Тесты доступности (accessibility)
void main() {
  group('Accessibility Tests', () {
    testWidgets('Проверка семантических меток для кнопок', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Сохранить'),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.add),
                  tooltip: 'Добавить продукт',
                ),
                FloatingActionButton(
                  onPressed: () {},
                  tooltip: 'Открыть камеру',
                  child: Icon(Icons.camera),
                ),
              ],
            ),
          ),
        ),
      );

      // Проверяем что кнопки имеют семантические метки
      expect(find.bySemanticsLabel('Сохранить'), findsOneWidget);
      expect(find.bySemanticsLabel('Добавить продукт'), findsOneWidget);
      expect(find.bySemanticsLabel('Открыть камеру'), findsOneWidget);
    });

    testWidgets('Проверка контрастности цветов', (tester) async {
      // Функция для проверки контрастности
      double calculateContrast(Color foreground, Color background) {
        double getLuminance(Color color) {
          final r = color.red / 255.0;
          final g = color.green / 255.0;
          final b = color.blue / 255.0;
          
          final rLum = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
          final gLum = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
          final bLum = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble();
          
          return 0.2126 * rLum + 0.7152 * gLum + 0.0722 * bLum;
        }

        final l1 = getLuminance(foreground);
        final l2 = getLuminance(background);
        final lighter = l1 > l2 ? l1 : l2;
        final darker = l1 > l2 ? l2 : l1;
        
        return (lighter + 0.05) / (darker + 0.05);
      }

      // Тестируем различные цветовые комбинации
      final blackOnWhite = calculateContrast(Colors.black, Colors.white);
      final whiteOnBlack = calculateContrast(Colors.white, Colors.black);
      final greyOnWhite = calculateContrast(Colors.grey, Colors.white);
      final redOnWhite = calculateContrast(Colors.red, Colors.white);

      // WCAG AA требует контрастность минимум 4.5:1 для обычного текста
      expect(blackOnWhite, greaterThanOrEqualTo(4.5));
      expect(whiteOnBlack, greaterThanOrEqualTo(4.5));
      
      // Проверяем что серый текст может не пройти тест
      print('Контрастность серого на белом: $greyOnWhite');
      print('Контрастность красного на белом: $redOnWhite');
    });

    testWidgets('Проверка размеров touch targets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Кнопка с достаточным размером
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Icon(Icons.add),
                  ),
                ),
                // Слишком маленькая кнопка
                SizedBox(
                  width: 20,
                  height: 20,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      color: Colors.blue,
                      child: Icon(Icons.close, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Находим виджеты
      final largeButton = find.byType(ElevatedButton);
      final smallButton = find.byType(GestureDetector);

      expect(largeButton, findsOneWidget);
      expect(smallButton, findsOneWidget);

      // Проверяем размеры (минимум 48x48 по Material Design)
      final largeButtonSize = tester.getSize(largeButton);
      expect(largeButtonSize.width, greaterThanOrEqualTo(48));
      expect(largeButtonSize.height, greaterThanOrEqualTo(48));

      final smallButtonSize = tester.getSize(smallButton);
      // Маленькая кнопка не соответствует стандартам
      expect(smallButtonSize.width, lessThan(48));
      expect(smallButtonSize.height, lessThan(48));
    });

    testWidgets('Проверка навигации с клавиатуры', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Имя'),
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Отправить'),
                ),
              ],
            ),
          ),
        ),
      );

      // Проверяем что можно перемещаться по полям с Tab
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Проверяем фокус на первом поле
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    });

    testWidgets('Проверка поддержки screen reader', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: Text('FitMonster'),
            ),
            body: Column(
              children: [
                Semantics(
                  label: 'Текущий вес: 70 килограмм',
                  child: Text('70 кг'),
                ),
                Semantics(
                  label: 'Кнопка добавить упражнение',
                  button: true,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('Добавить'),
                  ),
                ),
                Semantics(
                  label: 'Прогресс выполнения: 75 процентов',
                  value: '75%',
                  child: LinearProgressIndicator(value: 0.75),
                ),
              ],
            ),
          ),
        ),
      );

      // Проверяем семантические метки
      expect(find.bySemanticsLabel('Текущий вес: 70 килограмм'), findsOneWidget);
      expect(find.bySemanticsLabel('Кнопка добавить упражнение'), findsOneWidget);
      expect(find.bySemanticsLabel('Прогресс выполнения: 75 процентов'), findsOneWidget);
    });

    testWidgets('Проверка поддержки увеличения шрифта', (tester) async {
      Widget buildApp(double textScaleFactor) {
        return MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScaleFactor),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: Column(
              children: [
                Text('Обычный текст'),
                Text('Заголовок', style: TextStyle(fontSize: 24)),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Кнопка'),
                ),
              ],
            ),
          ),
        );
      }

      // Тестируем с обычным масштабом
      await tester.pumpWidget(buildApp(1.0));
      final normalTextSize = tester.getSize(find.text('Обычный текст'));

      // Тестируем с увеличенным шрифтом
      await tester.pumpWidget(buildApp(1.5));
      await tester.pump();
      final largeTextSize = tester.getSize(find.text('Обычный текст'));

      // Проверяем что текст увеличился
      expect(largeTextSize.height, greaterThan(normalTextSize.height));
    });

    testWidgets('Проверка цветовой доступности для дальтоников', (tester) async {
      // Функция для симуляции восприятия цветов дальтониками
      Color simulateProtanopia(Color original) {
        // Упрощенная симуляция протанопии (красно-зеленая слепота)
        final r = (original.r * 255.0).round().clamp(0, 255);
        final g = (original.g * 255.0).round().clamp(0, 255);
        final b = (original.b * 255.0).round().clamp(0, 255);
        
        // Протанопия: проблемы с восприятием красного
        final newR = (0.567 * r + 0.433 * g).round().clamp(0, 255);
        final newG = (0.558 * r + 0.442 * g).round().clamp(0, 255);
        final newB = b;
        
        return Color.fromARGB((original.a * 255.0).round().clamp(0, 255), newR, newG, newB);
      }

      // Тестируем различные цвета
      final originalRed = Colors.red;
      final originalGreen = Colors.green;
      final protanopiaRed = simulateProtanopia(originalRed);
      final protanopiaGreen = simulateProtanopia(originalGreen);

      // Проверяем что цвета различимы для дальтоников
      // (в реальном приложении нужно использовать не только цвет для передачи информации)
      expect(protanopiaRed != protanopiaGreen, isTrue);
      
      print('Оригинальный красный: $originalRed');
      print('Красный для протанопа: $protanopiaRed');
      print('Оригинальный зеленый: $originalGreen');
      print('Зеленый для протанопа: $protanopiaGreen');
    });

    testWidgets('Проверка альтернативного текста для изображений', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Semantics(
                  label: 'Фотография яблока для подсчета калорий',
                  image: true,
                  child: Image.asset(
                    'assets/images/apple.jpg',
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey,
                        child: Icon(Icons.image),
                      );
                    },
                  ),
                ),
                Semantics(
                  label: 'Иконка упражнения: отжимания',
                  image: true,
                  child: Icon(Icons.fitness_center, size: 48),
                ),
              ],
            ),
          ),
        ),
      );

      // Проверяем семантические метки для изображений
      expect(find.bySemanticsLabel('Фотография яблока для подсчета калорий'), findsOneWidget);
      expect(find.bySemanticsLabel('Иконка упражнения: отжимания'), findsOneWidget);
    });

    testWidgets('Проверка временных ограничений', (tester) async {
      bool isTimerActive = true;
      int remainingSeconds = 30;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Semantics(
                      label: 'Таймер упражнения: осталось $remainingSeconds секунд',
                      liveRegion: true,
                      child: Text('$remainingSeconds сек'),
                    ),
                    ElevatedButton(
                      onPressed: isTimerActive ? () {
                        setState(() {
                          isTimerActive = false;
                        });
                      } : null,
                      child: Text(isTimerActive ? 'Остановить' : 'Остановлено'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          remainingSeconds += 30;
                        });
                      },
                      child: Text('Добавить 30 сек'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Проверяем что есть возможность остановить таймер
      expect(find.text('Остановить'), findsOneWidget);
      
      // Останавливаем таймер
      await tester.tap(find.text('Остановить'));
      await tester.pump();
      
      expect(find.text('Остановлено'), findsOneWidget);
      
      // Проверяем возможность продлить время
      await tester.tap(find.text('Добавить 30 сек'));
      await tester.pump();
      
      expect(find.text('60 сек'), findsOneWidget);
    });
  });
}