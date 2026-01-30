import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Тесты для проверки шифрования данных
void main() {
  group('Encryption Tests', () {
    test('SHA-256 хеширование паролей', () {
      const password = 'test_password_123';
      const salt = 'random_salt_456';
      
      // Создаем хеш пароля с солью
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);
      final hashedPassword = digest.toString();
      
      // Проверяем что хеш создается корректно
      expect(hashedPassword, isNotEmpty);
      expect(hashedPassword.length, equals(64)); // SHA-256 = 64 символа в hex
      
      // Проверяем что одинаковые пароли дают одинаковый хеш
      final bytes2 = utf8.encode(password + salt);
      final digest2 = sha256.convert(bytes2);
      expect(digest2.toString(), equals(hashedPassword));
      
      // Проверяем что разные пароли дают разные хеши
      final differentBytes = utf8.encode('different_password' + salt);
      final differentDigest = sha256.convert(differentBytes);
      expect(differentDigest.toString(), isNot(equals(hashedPassword)));
    });

    test('Генерация случайной соли', () {
      // Простая генерация соли (в реальном приложении используйте crypto-библиотеки)
      String generateSalt() {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final random = timestamp.toString() + 'fitmonster_salt';
        return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
      }
      
      final salt1 = generateSalt();
      final salt2 = generateSalt();
      
      expect(salt1, isNotEmpty);
      expect(salt2, isNotEmpty);
      expect(salt1.length, equals(16));
      expect(salt2.length, equals(16));
      // Соли должны быть разными (с высокой вероятностью)
      expect(salt1, isNot(equals(salt2)));
    });

    test('Валидация хешированного пароля', () {
      const password = 'user_password';
      const salt = 'user_salt_123';
      
      // Создаем хеш
      final bytes = utf8.encode(password + salt);
      final originalHash = sha256.convert(bytes).toString();
      
      // Функция проверки пароля
      bool validatePassword(String inputPassword, String storedHash, String storedSalt) {
        final inputBytes = utf8.encode(inputPassword + storedSalt);
        final inputHash = sha256.convert(inputBytes).toString();
        return inputHash == storedHash;
      }
      
      // Проверяем правильный пароль
      expect(validatePassword(password, originalHash, salt), isTrue);
      
      // Проверяем неправильный пароль
      expect(validatePassword('wrong_password', originalHash, salt), isFalse);
    });

    test('Безопасное хранение чувствительных данных', () {
      // Симуляция шифрования чувствительных данных
      String encryptSensitiveData(String data, String key) {
        // Простое XOR шифрование для демонстрации
        final dataBytes = utf8.encode(data);
        final keyBytes = utf8.encode(key);
        final encrypted = <int>[];
        
        for (int i = 0; i < dataBytes.length; i++) {
          encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
        }
        
        return base64.encode(encrypted);
      }
      
      String decryptSensitiveData(String encryptedData, String key) {
        final encryptedBytes = base64.decode(encryptedData);
        final keyBytes = utf8.encode(key);
        final decrypted = <int>[];
        
        for (int i = 0; i < encryptedBytes.length; i++) {
          decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
        }
        
        return utf8.decode(decrypted);
      }
      
      const sensitiveData = 'Личные медицинские данные пользователя';
      const encryptionKey = 'fitmonster_encryption_key_2024';
      
      // Шифруем данные
      final encrypted = encryptSensitiveData(sensitiveData, encryptionKey);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(sensitiveData)));
      
      // Расшифровываем данные
      final decrypted = decryptSensitiveData(encrypted, encryptionKey);
      expect(decrypted, equals(sensitiveData));
      
      // Проверяем что с неправильным ключом данные не расшифровываются
      final wrongDecrypted = decryptSensitiveData(encrypted, 'wrong_key');
      expect(wrongDecrypted, isNot(equals(sensitiveData)));
    });

    test('Проверка целостности данных', () {
      // Создание контрольной суммы для проверки целостности
      String createChecksum(String data) {
        return sha256.convert(utf8.encode(data)).toString();
      }
      
      bool verifyIntegrity(String data, String expectedChecksum) {
        final actualChecksum = createChecksum(data);
        return actualChecksum == expectedChecksum;
      }
      
      const originalData = '{"userId":"123","weight":75,"height":180}';
      final checksum = createChecksum(originalData);
      
      // Проверяем неизмененные данные
      expect(verifyIntegrity(originalData, checksum), isTrue);
      
      // Проверяем измененные данные
      const modifiedData = '{"userId":"123","weight":80,"height":180}';
      expect(verifyIntegrity(modifiedData, checksum), isFalse);
    });

    test('Безопасная очистка чувствительных данных из памяти', () {
      // Симуляция безопасной очистки
      void secureWipe(Uint8List data) {
        // Перезаписываем данные нулями
        for (int i = 0; i < data.length; i++) {
          data[i] = 0;
        }
      }
      
      final sensitiveBytes = Uint8List.fromList(utf8.encode('sensitive_password'));
      final originalLength = sensitiveBytes.length;
      
      // Проверяем что данные есть
      expect(sensitiveBytes.any((byte) => byte != 0), isTrue);
      
      // Безопасно очищаем
      secureWipe(sensitiveBytes);
      
      // Проверяем что все байты обнулены
      expect(sensitiveBytes.every((byte) => byte == 0), isTrue);
      expect(sensitiveBytes.length, equals(originalLength));
    });
  });
}