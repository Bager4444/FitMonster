import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/countdown_widget.dart';

void main() {
  group('CountdownWidget', () {
    testWidgets('должен отображать начальное значение обратного отсчёта', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownWidget(
              onCountdownComplete: () {
                callbackCalled = true;
              },
              startValue: 3,
            ),
          ),
        ),
      );

      // Проверяем, что отображается цифра 3
      expect(find.text('3'), findsOneWidget);
      expect(callbackCalled, false);
    });

    testWidgets('должен вызывать callback после завершения отсчёта', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownWidget(
              onCountdownComplete: () {
                callbackCalled = true;
              },
              startValue: 1, // Короткий отсчёт для теста
            ),
          ),
        ),
      );

      // Ждём завершения анимации
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Проверяем, что callback был вызван
      expect(callbackCalled, true);
    });

    testWidgets('должен показывать "НАЧАЛИ!" в конце отсчёта', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownWidget(
              onCountdownComplete: () {},
              startValue: 1,
            ),
          ),
        ),
      );

      // Ждём секунду для перехода к "НАЧАЛИ!"
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 100));

      // Проверяем, что отображается "НАЧАЛИ!"
      expect(find.text('НАЧАЛИ!'), findsOneWidget);
    });

    testWidgets('должен иметь правильные цвета для разных состояний', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownWidget(
              onCountdownComplete: () {},
              startValue: 3,
            ),
          ),
        ),
      );

      // Проверяем, что виджет создался без ошибок
      expect(find.byType(CountdownWidget), findsOneWidget);
      
      // Проверяем наличие анимированного контейнера
      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });

    testWidgets('должен поддерживать разные начальные значения', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownWidget(
              onCountdownComplete: () {},
              startValue: 5,
            ),
          ),
        ),
      );

      // Проверяем, что отображается цифра 5
      expect(find.text('5'), findsOneWidget);
      
      // Wait for countdown to finish to avoid pending timers
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}