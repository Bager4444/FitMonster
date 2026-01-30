import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Утилиты для обеспечения безопасности приложения
class SecurityUtils {
  static final _random = Random.secure();

  /// Генерация безопасной соли для хеширования паролей
  static String generateSalt({int length = 32}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (index) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  /// Хеширование пароля с солью (SHA-256)
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Проверка пароля
  static bool verifyPassword(String password, String hash, String salt) {
    final computedHash = hashPassword(password, salt);
    return computedHash == hash;
  }

  /// Генерация безопасного токена
  static String generateSecureToken({int length = 32}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (index) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  /// Простое XOR шифрование для демонстрации
  /// В продакшене используйте AES или другие стандартные алгоритмы
  static String encryptData(String data, String key) {
    final dataBytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];

    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encrypted);
  }

  /// Расшифровка данных
  static String decryptData(String encryptedData, String key) {
    try {
      final encryptedBytes = base64.decode(encryptedData);
      final keyBytes = utf8.encode(key);
      final decrypted = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      // Возвращаем пустую строку при ошибке расшифровки
      return '';
    }
  }

  /// Валидация пользовательского ввода
  static bool isValidInput(String input, {int maxLength = 100}) {
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

  /// Санитизация HTML
  static String sanitizeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .trim();
  }

  /// Маскировка чувствительных данных
  static String maskSensitiveData(String data, String type) {
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
        if (data.length <= 4) return data;
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

  /// Создание контрольной суммы для проверки целостности
  static String createChecksum(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Проверка целостности данных
  static bool verifyIntegrity(String data, String expectedChecksum) {
    final actualChecksum = createChecksum(data);
    return actualChecksum == expectedChecksum;
  }

  /// Безопасная очистка чувствительных данных из памяти
  static void secureWipe(Uint8List data) {
    for (int i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }

  /// Валидация размера файла
  static bool isFileSizeValid(int fileSizeBytes, {int maxSizeMB = 10}) {
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return fileSizeBytes > 0 && fileSizeBytes <= maxSizeBytes;
  }

  /// Проверка допустимых типов файлов
  static bool isFileTypeAllowed(String fileName) {
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = fileName.toLowerCase();
    final dotIndex = extension.lastIndexOf('.');
    if (dotIndex == -1) return false;
    
    final ext = extension.substring(dotIndex);
    return allowedExtensions.contains(ext);
  }

  /// Rate Limiter для ограничения частоты запросов
  static final Map<String, List<DateTime>> _rateLimitRequests = {};

  static bool isRequestAllowed(
    String clientId, {
    int maxRequests = 10,
    Duration timeWindow = const Duration(minutes: 1),
  }) {
    final now = DateTime.now();
    final clientRequests = _rateLimitRequests[clientId] ?? [];

    // Удаляем старые запросы
    clientRequests.removeWhere(
      (time) => now.difference(time) > timeWindow,
    );

    // Проверяем лимит
    if (clientRequests.length >= maxRequests) {
      return false;
    }

    // Добавляем текущий запрос
    clientRequests.add(now);
    _rateLimitRequests[clientId] = clientRequests;

    return true;
  }

  /// Очистка rate limiter (для тестов)
  static void clearRateLimiter() {
    _rateLimitRequests.clear();
  }
}