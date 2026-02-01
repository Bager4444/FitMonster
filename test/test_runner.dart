import 'package:flutter_test/flutter_test.dart';

// Unit Tests
import 'services/hive_service_test.dart' as hive_tests;
import 'services/calorie_calculator_test.dart' as calorie_tests;

// Security Tests
import 'security/encryption_test.dart' as encryption_tests;
import 'security/api_security_test.dart' as api_security_tests;

// Offline Tests
import 'offline/offline_mode_test.dart' as offline_tests;

// Performance Tests
import 'performance/performance_test.dart' as performance_tests;

// Accessibility Tests
import 'accessibility/accessibility_test.dart' as accessibility_tests;

/// Главный файл для запуска всех тестов
void main() {
  group('🧪 FitMonster Test Suite', () {
    group('📦 Unit Tests', () {
      hive_tests.main();
      calorie_tests.main();
    });

    group('🔒 Security Tests', () {
      encryption_tests.main();
      api_security_tests.main();
    });

    group('📱 Offline Mode Tests', () {
      offline_tests.main();
    });

    group('⚡ Performance Tests', () {
      performance_tests.main();
    });

    group('♿ Accessibility Tests', () {
      accessibility_tests.main();
    });
  });
}