// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import 'package:fitmonster/main.dart';

void main() {
  setUpAll(() async {
    // Инициализация Hive для тестов с временной директорией
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    // Очистка после тестов
    await Hive.close();
  });

  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FitMonsterApp());

    // Verify that navigation bar is present
    expect(find.text('Упражнения'), findsWidgets);
    expect(find.text('Диета'), findsWidgets);
    expect(find.text('Профиль'), findsWidgets);
    
    // Verify navigation works
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
