import 'package:flutter_test/flutter_test.dart';
import 'package:fitmonster/core/security/security_utils.dart';
import 'dart:typed_data';

void main() {
  group('SecurityUtils Tests', () {
    test('generateSalt - создание уникальных солей', () {
      final salt1 = SecurityUtils.generateSalt();
      final salt2 = SecurityUtils.generateSalt();

      expect(salt1, isNotEmpty);
      expect(salt2, isNotEmpty);
      expect(salt1.length, equals(32));
      expect(salt2.length, equals(32));
      expect(salt1, isNot(equals(salt2)));

      // Тест кастомной длины
      final shortSalt = SecurityUtils.generateSalt(length: 16);
      expect(shortSalt.length, equals(16));
    });

    test('hashPassword и verifyPassword - хеширование и проверка паролей', () {
      const password = 'test_password_123';
      final salt = SecurityUtils.generateSalt();

      // Хешируем пароль
      final hash = SecurityUtils.hashPassword(password, salt);
      expect(hash, isNotEmpty);
      expect(hash.length, equals(64)); // SHA-256 = 64 символа в hex

      // Проверяем правильный пароль
      expect(SecurityUtils.verifyPassword(password, hash, salt), isTrue);

      // Проверяем неправильный пароль
      expect(SecurityUtils.verifyPassword('wrong_password', hash, salt), isFalse);

      // Проверяем с неправильной солью
      final wrongSalt = SecurityUtils.generateSalt();
      expect(SecurityUtils.verifyPassword(password, hash, wrongSalt), isFalse);
    });

    test('generateSecureToken - генерация безопасных токенов', () {
      final token1 = SecurityUtils.generateSecureToken();
      final token2 = SecurityUtils.generateSecureToken();

      expect(token1, isNotEmpty);
      expect(token2, isNotEmpty);
      expect(token1.length, equals(32));
      expect(token2.length, equals(32));
      expect(token1, isNot(equals(token2)));

      // Проверяем что токены содержат только допустимые символы
      final validChars = RegExp(r'^[a-zA-Z0-9]+$');
      expect(validChars.hasMatch(token1), isTrue);
      expect(validChars.hasMatch(token2), isTrue);
    });

    test('encryptData и decryptData - шифрование и расшифровка', () {
      const originalData = 'Секретные данные пользователя';
      const encryptionKey = 'my_secret_key_2024';

      // Шифруем данные
      final encrypted = SecurityUtils.encryptData(originalData, encryptionKey);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(originalData)));

      // Расшифровываем данные
      final decrypted = SecurityUtils.decryptData(encrypted, encryptionKey);
      expect(decrypted, equals(originalData));

      // Проверяем что с неправильным ключом данные не расшифровываются корректно
      final wrongDecrypted = SecurityUtils.decryptData(encrypted, 'wrong_key');
      expect(wrongDecrypted, isNot(equals(originalData)));
      // Может вернуть пустую строку или некорректные данные
    });

    test('isValidInput - валидация пользовательского ввода', () {
      // Валидные данные
      expect(SecurityUtils.isValidInput('Иван Петров'), isTrue);
      expect(SecurityUtils.isValidInput('ivan@example.com'), isTrue);
      expect(SecurityUtils.isValidInput('Продукт 123'), isTrue);

      // Потенциально опасные данные
      expect(SecurityUtils.isValidInput('<script>alert("xss")</script>'), isFalse);
      expect(SecurityUtils.isValidInput('javascript:alert(1)'), isFalse);
      expect(SecurityUtils.isValidInput('DROP TABLE users'), isFalse);
      expect(SecurityUtils.isValidInput('SELECT * FROM passwords'), isFalse);
      expect(SecurityUtils.isValidInput('onload=malicious()'), isFalse);

      // Слишком длинные данные
      final longString = 'a' * 101;
      expect(SecurityUtils.isValidInput(longString), isFalse);

      // Пустые данные
      expect(SecurityUtils.isValidInput(''), isFalse);
    });

    test('sanitizeHtml - санитизация HTML', () {
      expect(SecurityUtils.sanitizeHtml('<script>'), equals('&lt;script&gt;'));
      expect(SecurityUtils.sanitizeHtml('Test "quote"'), equals('Test &quot;quote&quot;'));
      expect(SecurityUtils.sanitizeHtml("Test 'apostrophe'"), equals('Test &#x27;apostrophe&#x27;'));
      expect(SecurityUtils.sanitizeHtml('A & B'), equals('A &amp; B'));
      expect(SecurityUtils.sanitizeHtml('  spaced  '), equals('spaced'));
    });

    test('maskSensitiveData - маскировка чувствительных данных', () {
      // Email
      expect(SecurityUtils.maskSensitiveData('ivan@example.com', 'email'), 
             equals('iv**@example.com'));
      expect(SecurityUtils.maskSensitiveData('a@test.com', 'email'), 
             equals('a@test.com'));

      // Телефон (12 символов: +79161234567)
      expect(SecurityUtils.maskSensitiveData('+79161234567', 'phone'), 
             equals('********4567'));
      expect(SecurityUtils.maskSensitiveData('1234', 'phone'), 
             equals('1234'));

      // Имя (Петров = 6 символов, маскируется как П*****)
      expect(SecurityUtils.maskSensitiveData('Иван Петров', 'name'), 
             equals('И*** П*****'));
      expect(SecurityUtils.maskSensitiveData('А', 'name'), 
             equals('А'));

      // Неизвестный тип
      expect(SecurityUtils.maskSensitiveData('test', 'unknown'), 
             equals('test'));
    });

    test('createChecksum и verifyIntegrity - проверка целостности', () {
      const originalData = '{"userId":"123","weight":75,"height":180}';
      final checksum = SecurityUtils.createChecksum(originalData);

      expect(checksum, isNotEmpty);
      expect(checksum.length, equals(64)); // SHA-256

      // Проверяем неизмененные данные
      expect(SecurityUtils.verifyIntegrity(originalData, checksum), isTrue);

      // Проверяем измененные данные
      const modifiedData = '{"userId":"123","weight":80,"height":180}';
      expect(SecurityUtils.verifyIntegrity(modifiedData, checksum), isFalse);
    });

    test('secureWipe - безопасная очистка памяти', () {
      final sensitiveBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final originalLength = sensitiveBytes.length;

      // Проверяем что данные есть
      expect(sensitiveBytes.any((byte) => byte != 0), isTrue);

      // Безопасно очищаем
      SecurityUtils.secureWipe(sensitiveBytes);

      // Проверяем что все байты обнулены
      expect(sensitiveBytes.every((byte) => byte == 0), isTrue);
      expect(sensitiveBytes.length, equals(originalLength));
    });

    test('isFileSizeValid - валидация размера файлов', () {
      expect(SecurityUtils.isFileSizeValid(1024 * 1024), isTrue); // 1MB
      expect(SecurityUtils.isFileSizeValid(5 * 1024 * 1024), isTrue); // 5MB
      expect(SecurityUtils.isFileSizeValid(15 * 1024 * 1024), isFalse); // 15MB
      expect(SecurityUtils.isFileSizeValid(0), isFalse); // Пустой файл
      expect(SecurityUtils.isFileSizeValid(-1), isFalse); // Отрицательный размер

      // Кастомный лимит
      expect(SecurityUtils.isFileSizeValid(2 * 1024 * 1024, maxSizeMB: 1), isFalse);
    });

    test('isFileTypeAllowed - проверка типов файлов', () {
      expect(SecurityUtils.isFileTypeAllowed('photo.jpg'), isTrue);
      expect(SecurityUtils.isFileTypeAllowed('image.PNG'), isTrue);
      expect(SecurityUtils.isFileTypeAllowed('avatar.gif'), isTrue);
      expect(SecurityUtils.isFileTypeAllowed('picture.webp'), isTrue);
      expect(SecurityUtils.isFileTypeAllowed('document.pdf'), isFalse);
      expect(SecurityUtils.isFileTypeAllowed('script.js'), isFalse);
      expect(SecurityUtils.isFileTypeAllowed('malware.exe'), isFalse);
      expect(SecurityUtils.isFileTypeAllowed('noextension'), isFalse);
    });

    test('isRequestAllowed - rate limiting', () {
      SecurityUtils.clearRateLimiter();
      
      const clientId = 'test_client';

      // Первые 10 запросов должны пройти (по умолчанию)
      for (int i = 0; i < 10; i++) {
        expect(SecurityUtils.isRequestAllowed(clientId), isTrue);
      }

      // 11-й запрос должен быть заблокирован
      expect(SecurityUtils.isRequestAllowed(clientId), isFalse);

      // Другой клиент должен иметь свой лимит
      expect(SecurityUtils.isRequestAllowed('other_client'), isTrue);

      // Тест с кастомными параметрами
      SecurityUtils.clearRateLimiter();
      expect(SecurityUtils.isRequestAllowed(
        'limited_client',
        maxRequests: 2,
        timeWindow: Duration(seconds: 1),
      ), isTrue);
      expect(SecurityUtils.isRequestAllowed(
        'limited_client',
        maxRequests: 2,
        timeWindow: Duration(seconds: 1),
      ), isTrue);
      expect(SecurityUtils.isRequestAllowed(
        'limited_client',
        maxRequests: 2,
        timeWindow: Duration(seconds: 1),
      ), isFalse);
    });
  });
}