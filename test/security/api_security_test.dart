import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:math';

/// Тесты безопасности API и сетевых запросов
void main() {
  group('API Security Tests', () {
    test('Валидация входных данных - предотвращение инъекций', () {
      // Функция валидации пользовательского ввода
      bool isValidInput(String input, {int maxLength = 100}) {
        if (input.isEmpty || input.length > maxLength) return false;
        
        // Проверка на потенциально опасные символы
        final dangerousPatterns = [
          '<script',
          'javascript:',
          'onload=',
          'onerror=',
          'eval(',
          'document.cookie',
          'DROP TABLE',
          'SELECT * FROM',
          'INSERT INTO',
          'UPDATE SET',
          'DELETE FROM',
        ];
        
        final lowerInput = input.toLowerCase();
        for (final pattern in dangerousPatterns) {
          if (lowerInput.contains(pattern.toLowerCase())) {
            return false;
          }
        }
        
        return true;
      }

      // Тестируем валидные данные
      expect(isValidInput('Иван Петров'), isTrue);
      expect(isValidInput('ivan@example.com'), isTrue);
      expect(isValidInput('Продукт 123'), isTrue);

      // Тестируем потенциально опасные данные
      expect(isValidInput('<script>alert("xss")</script>'), isFalse);
      expect(isValidInput('javascript:alert(1)'), isFalse);
      expect(isValidInput('DROP TABLE users'), isFalse);
      expect(isValidInput('SELECT * FROM passwords'), isFalse);
      expect(isValidInput('onload=malicious()'), isFalse);

      // Тестируем слишком длинные данные
      final longString = 'a' * 101;
      expect(isValidInput(longString), isFalse);
    });

    test('Санитизация данных перед сохранением', () {
      String sanitizeInput(String input) {
        return input
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#x27;')
            .replaceAll('&', '&amp;')
            .trim();
      }

      // Тестируем санитизацию
      expect(sanitizeInput('<script>'), equals('&lt;script&gt;'));
      expect(sanitizeInput('Test "quote"'), equals('Test &quot;quote&quot;'));
      expect(sanitizeInput("Test 'apostrophe'"), equals('Test &#x27;apostrophe&#x27;'));
      expect(sanitizeInput('A & B'), equals('A &amp; B'));
      expect(sanitizeInput('  spaced  '), equals('spaced'));
    });

    test('Генерация безопасных токенов', () {
      String generateSecureToken({int length = 32}) {
        const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        final random = Random.secure();
        return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
      }

      final token1 = generateSecureToken();
      final token2 = generateSecureToken();

      // Проверяем длину токенов
      expect(token1.length, equals(32));
      expect(token2.length, equals(32));

      // Проверяем что токены разные
      expect(token1, isNot(equals(token2)));

      // Проверяем что токены содержат только допустимые символы
      final validChars = RegExp(r'^[a-zA-Z0-9]+$');
      expect(validChars.hasMatch(token1), isTrue);
      expect(validChars.hasMatch(token2), isTrue);

      // Тестируем кастомную длину
      final shortToken = generateSecureToken(length: 16);
      expect(shortToken.length, equals(16));
    });

    test('Валидация JWT токенов (симуляция)', () {
      // Симуляция структуры JWT токена
      Map<String, dynamic> createMockJWT(Map<String, dynamic> payload) {
        final header = {'alg': 'HS256', 'typ': 'JWT'};
        final encodedHeader = base64Url.encode(utf8.encode(json.encode(header)));
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        
        return {
          'header': encodedHeader,
          'payload': encodedPayload,
          'signature': 'mock_signature_for_testing',
          'full_token': '$encodedHeader.$encodedPayload.mock_signature_for_testing',
        };
      }

      bool validateJWTStructure(String token) {
        final parts = token.split('.');
        if (parts.length != 3) return false;
        
        try {
          // Проверяем что части можно декодировать
          base64Url.decode(parts[0]); // header
          base64Url.decode(parts[1]); // payload
          return true;
        } catch (e) {
          return false;
        }
      }

      bool isTokenExpired(Map<String, dynamic> payload) {
        if (!payload.containsKey('exp')) return true;
        
        final expiration = payload['exp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return now > expiration;
      }

      // Создаем валидный токен
      final validPayload = {
        'userId': 'user123',
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600, // +1 час
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      final validToken = createMockJWT(validPayload);

      // Создаем просроченный токен
      final expiredPayload = {
        'userId': 'user123',
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600, // -1 час
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      final expiredToken = createMockJWT(expiredPayload);

      // Тестируем валидацию структуры
      expect(validateJWTStructure(validToken['full_token']), isTrue);
      expect(validateJWTStructure('invalid.token'), isFalse);
      expect(validateJWTStructure('invalid'), isFalse);

      // Тестируем проверку срока действия
      expect(isTokenExpired(validPayload), isFalse);
      expect(isTokenExpired(expiredPayload), isTrue);
      expect(isTokenExpired({}), isTrue); // Нет поля exp
    });

    test('Защита от CSRF атак', () {
      String generateCSRFToken() {
        final random = Random.secure();
        final bytes = List<int>.generate(32, (i) => random.nextInt(256));
        return base64Url.encode(bytes);
      }

      bool validateCSRFToken(String? requestToken, String? sessionToken) {
        if (requestToken == null || sessionToken == null) return false;
        if (requestToken.isEmpty || sessionToken.isEmpty) return false;
        return requestToken == sessionToken;
      }

      final sessionToken = generateCSRFToken();
      
      // Валидный запрос
      expect(validateCSRFToken(sessionToken, sessionToken), isTrue);
      
      // Невалидные запросы
      expect(validateCSRFToken(null, sessionToken), isFalse);
      expect(validateCSRFToken('wrong_token', sessionToken), isFalse);
      expect(validateCSRFToken('', sessionToken), isFalse);
      expect(validateCSRFToken(sessionToken, null), isFalse);
    });

    test('Ограничение частоты запросов (Rate Limiting)', () {
      // Простая реализация rate limiter для тестирования
      final Map<String, List<DateTime>> requests = {};
      const int maxRequests = 5;
      const Duration timeWindow = Duration(minutes: 1);

      bool isAllowed(String clientId) {
        final now = DateTime.now();
        final clientRequests = requests[clientId] ?? [];

        // Удаляем старые запросы
        clientRequests.removeWhere((time) => 
            now.difference(time) > timeWindow);

        // Проверяем лимит
        if (clientRequests.length >= maxRequests) {
          return false;
        }

        // Добавляем текущий запрос
        clientRequests.add(now);
        requests[clientId] = clientRequests;
        return true;
      }
      
      const clientId = 'test_client';

      // Первые 5 запросов должны пройти
      for (int i = 0; i < maxRequests; i++) {
        expect(isAllowed(clientId), isTrue);
      }

      // 6-й запрос должен быть заблокирован
      expect(isAllowed(clientId), isFalse);

      // Другой клиент должен иметь свой лимит
      expect(isAllowed('other_client'), isTrue);
    });

    test('Валидация размера загружаемых файлов', () {
      bool isFileSizeValid(int fileSizeBytes, {int maxSizeMB = 10}) {
        final maxSizeBytes = maxSizeMB * 1024 * 1024;
        return fileSizeBytes > 0 && fileSizeBytes <= maxSizeBytes;
      }

      bool isFileTypeAllowed(String fileName) {
        final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
        final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
        return allowedExtensions.contains(extension);
      }

      // Тестируем размер файлов
      expect(isFileSizeValid(1024 * 1024), isTrue); // 1MB
      expect(isFileSizeValid(5 * 1024 * 1024), isTrue); // 5MB
      expect(isFileSizeValid(15 * 1024 * 1024), isFalse); // 15MB
      expect(isFileSizeValid(0), isFalse); // Пустой файл
      expect(isFileSizeValid(-1), isFalse); // Отрицательный размер

      // Тестируем типы файлов
      expect(isFileTypeAllowed('photo.jpg'), isTrue);
      expect(isFileTypeAllowed('image.PNG'), isTrue);
      expect(isFileTypeAllowed('avatar.gif'), isTrue);
      expect(isFileTypeAllowed('document.pdf'), isFalse);
      expect(isFileTypeAllowed('script.js'), isFalse);
      expect(isFileTypeAllowed('malware.exe'), isFalse);
    });

    test('Защита персональных данных', () {
      String maskSensitiveData(String data, String type) {
        switch (type) {
          case 'email':
            final parts = data.split('@');
            if (parts.length != 2) return data;
            final username = parts[0];
            final domain = parts[1];
            final maskedUsername = username.length > 2 
                ? '${username.substring(0, 2)}${'*' * (username.length - 2)}'
                : username;
            return '$maskedUsername@$domain';
            
          case 'phone':
            if (data.length < 4) return data;
            return '${'*' * (data.length - 4)}${data.substring(data.length - 4)}';
            
          case 'name':
            final parts = data.split(' ');
            return parts.map((part) {
              if (part.length <= 1) return part;
              return '${part[0]}${'*' * (part.length - 1)}';
            }).join(' ');
            
          default:
            return data;
        }
      }

      // Тестируем маскировку email
      expect(maskSensitiveData('ivan@example.com', 'email'), equals('iv**@example.com'));
      expect(maskSensitiveData('a@test.com', 'email'), equals('a@test.com'));

      // Тестируем маскировку телефона
      expect(maskSensitiveData('+79161234567', 'phone'), equals('*******4567'));
      expect(maskSensitiveData('123', 'phone'), equals('123'));

      // Тестируем маскировку имени
      expect(maskSensitiveData('Иван Петров', 'name'), equals('И*** П******'));
      expect(maskSensitiveData('А', 'name'), equals('А'));
    });
  });
}