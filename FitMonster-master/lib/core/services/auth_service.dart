import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Модель пользователя
class User {
  final String username;
  final String email;
  final String country;
  final DateTime createdAt;

  User({
    required this.username,
    required this.email,
    required this.country,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'country': country,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      country: map['country'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Сервис аутентификации
class AuthService {
  static const String _usersBoxName = 'users';
  static const String _currentUserBoxName = 'current_user';

  /// Хеширует пароль
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Регистрирует нового пользователя
  static Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String country,
  }) async {
    try {
      final usersBox = await Hive.openBox(_usersBoxName);
      
      // Проверяем, существует ли пользователь с таким username или email
      final existingUsers = usersBox.values.toList();
      for (var userData in existingUsers) {
        if (userData is Map) {
          final user = User.fromMap(Map<String, dynamic>.from(userData));
          if (user.username == username || user.email == email) {
            return false; // Пользователь уже существует
          }
        }
      }

      // Создаем нового пользователя
      final user = User(
        username: username,
        email: email,
        country: country,
        createdAt: DateTime.now(),
      );

      // Сохраняем пользователя и пароль
      final hashedPassword = _hashPassword(password);
      await usersBox.put(username, {
        ...user.toMap(),
        'password': hashedPassword,
      });

      print('✅ Пользователь $username зарегистрирован');
      return true;
    } catch (e) {
      print('❌ Ошибка регистрации: $e');
      return false;
    }
  }

  /// Авторизует пользователя
  static Future<User?> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final usersBox = await Hive.openBox(_usersBoxName);
      final hashedPassword = _hashPassword(password);

      // Ищем пользователя по username или email
      final existingUsers = usersBox.values.toList();
      for (var userData in existingUsers) {
        if (userData is Map) {
          final userMap = Map<String, dynamic>.from(userData);
          final user = User.fromMap(userMap);
          
          if ((user.username == usernameOrEmail || user.email == usernameOrEmail) &&
              userMap['password'] == hashedPassword) {
            
            // Сохраняем текущего пользователя
            final currentUserBox = await Hive.openBox(_currentUserBoxName);
            await currentUserBox.put('current_user', user.toMap());
            
            print('✅ Пользователь ${user.username} вошел в систему');
            return user;
          }
        }
      }

      print('❌ Неверные учетные данные');
      return null;
    } catch (e) {
      print('❌ Ошибка входа: $e');
      return null;
    }
  }

  /// Получает текущего пользователя
  static Future<User?> getCurrentUser() async {
    try {
      final currentUserBox = await Hive.openBox(_currentUserBoxName);
      final userData = currentUserBox.get('current_user');
      
      if (userData != null) {
        return User.fromMap(Map<String, dynamic>.from(userData));
      }
      
      return null;
    } catch (e) {
      print('❌ Ошибка получения текущего пользователя: $e');
      return null;
    }
  }

  /// Проверяет, авторизован ли пользователь
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Выходит из системы
  static Future<void> logout() async {
    try {
      final currentUserBox = await Hive.openBox(_currentUserBoxName);
      await currentUserBox.clear();
      print('✅ Пользователь вышел из системы');
    } catch (e) {
      print('❌ Ошибка выхода: $e');
    }
  }

  /// Получает ID текущего пользователя
  static Future<String?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?.username;
  }

  /// Получает список всех стран
  static List<Map<String, String>> getCountries() {
    return [
      {'name': 'Россия', 'flag': '🇷🇺', 'code': 'RU'},
      {'name': 'США', 'flag': '🇺🇸', 'code': 'US'},
      {'name': 'Германия', 'flag': '🇩🇪', 'code': 'DE'},
      {'name': 'Франция', 'flag': '🇫🇷', 'code': 'FR'},
      {'name': 'Великобритания', 'flag': '🇬🇧', 'code': 'GB'},
      {'name': 'Италия', 'flag': '🇮🇹', 'code': 'IT'},
      {'name': 'Испания', 'flag': '🇪🇸', 'code': 'ES'},
      {'name': 'Канада', 'flag': '🇨🇦', 'code': 'CA'},
      {'name': 'Австралия', 'flag': '🇦🇺', 'code': 'AU'},
      {'name': 'Япония', 'flag': '🇯🇵', 'code': 'JP'},
      {'name': 'Китай', 'flag': '🇨🇳', 'code': 'CN'},
      {'name': 'Южная Корея', 'flag': '🇰🇷', 'code': 'KR'},
      {'name': 'Индия', 'flag': '🇮🇳', 'code': 'IN'},
      {'name': 'Бразилия', 'flag': '🇧🇷', 'code': 'BR'},
      {'name': 'Мексика', 'flag': '🇲🇽', 'code': 'MX'},
      {'name': 'Аргентина', 'flag': '🇦🇷', 'code': 'AR'},
      {'name': 'Турция', 'flag': '🇹🇷', 'code': 'TR'},
      {'name': 'Польша', 'flag': '🇵🇱', 'code': 'PL'},
      {'name': 'Нидерланды', 'flag': '🇳🇱', 'code': 'NL'},
      {'name': 'Швеция', 'flag': '🇸🇪', 'code': 'SE'},
    ];
  }
}