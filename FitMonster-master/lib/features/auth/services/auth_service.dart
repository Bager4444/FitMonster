import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Сервис аутентификации и управления пользователями
class AuthService {
  static const String _usersBoxName = 'users';
  static const String _currentUserKey = 'current_user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  
  static Box<UserModel>? _usersBox;
  static UserModel? _currentUser;
  
  /// Инициализация сервиса
  static Future<void> initialize() async {
    _usersBox = await Hive.openBox<UserModel>(_usersBoxName);
  }
  
  /// Регистрация нового пользователя
  static Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      if (_usersBox == null) {
        await initialize();
      }
      
      // Проверка на существование пользователя
      if (await _userExists(email, username)) {
        return AuthResult(
          success: false,
          message: 'Пользователь с таким email или именем уже существует',
        );
      }
      
      // Валидация данных
      final validation = _validateRegistrationData(email, username, password);
      if (!validation.isValid) {
        return AuthResult(
          success: false,
          message: validation.message,
        );
      }
      
      // Создание нового пользователя
      final userId = _generateUserId();
      final hashedPassword = _hashPassword(password);
      
      final user = UserModel(
        id: userId,
        email: email.toLowerCase().trim(),
        username: username.trim(),
        firstName: firstName?.trim(),
        lastName: lastName?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: {
          'password_hash': hashedPassword,
          'theme': 'dark',
          'notifications': true,
          'language': 'ru',
        },
      );
      
      // Сохранение пользователя
      await _usersBox!.put(userId, user);
      
      return AuthResult(
        success: true,
        message: 'Регистрация успешна!',
        user: user,
      );
      
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Ошибка регистрации: $e',
      );
    }
  }
  
  /// Вход в систему
  static Future<AuthResult> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      if (_usersBox == null) {
        await initialize();
      }
      
      // Поиск пользователя
      final user = await _findUser(emailOrUsername);
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'Пользователь не найден',
        );
      }
      
      // Проверка пароля
      final hashedPassword = user.preferences?['password_hash'] as String?;
      if (hashedPassword == null || !_verifyPassword(password, hashedPassword)) {
        return AuthResult(
          success: false,
          message: 'Неверный пароль',
        );
      }
      
      // Установка текущего пользователя
      await _setCurrentUser(user);
      
      return AuthResult(
        success: true,
        message: 'Вход выполнен успешно!',
        user: user,
      );
      
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Ошибка входа: $e',
      );
    }
  }
  
  /// Выход из системы
  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
  
  /// Получение текущего пользователя
  static Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserKey);
    
    if (userId != null && _usersBox != null) {
      _currentUser = _usersBox!.get(userId);
      return _currentUser;
    }
    
    return null;
  }
  
  /// Проверка авторизации
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
  
  /// Обновление профиля пользователя
  static Future<AuthResult> updateProfile(UserModel updatedUser) async {
    try {
      if (_usersBox == null) {
        await initialize();
      }
      
      final user = updatedUser.copyWith(updatedAt: DateTime.now());
      await _usersBox!.put(user.id, user);
      _currentUser = user;
      
      return AuthResult(
        success: true,
        message: 'Профиль обновлен успешно!',
        user: user,
      );
      
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Ошибка обновления профиля: $e',
      );
    }
  }
  
  /// Смена пароля
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'Пользователь не авторизован',
        );
      }
      
      // Проверка текущего пароля
      final currentHash = user.preferences?['password_hash'] as String?;
      if (currentHash == null || !_verifyPassword(currentPassword, currentHash)) {
        return AuthResult(
          success: false,
          message: 'Неверный текущий пароль',
        );
      }
      
      // Валидация нового пароля
      if (!_isValidPassword(newPassword)) {
        return AuthResult(
          success: false,
          message: 'Новый пароль должен содержать минимум 6 символов',
        );
      }
      
      // Обновление пароля
      final newHash = _hashPassword(newPassword);
      final updatedPreferences = Map<String, dynamic>.from(user.preferences ?? {});
      updatedPreferences['password_hash'] = newHash;
      
      final updatedUser = user.copyWith(
        preferences: updatedPreferences,
        updatedAt: DateTime.now(),
      );
      
      await _usersBox!.put(user.id, updatedUser);
      _currentUser = updatedUser;
      
      return AuthResult(
        success: true,
        message: 'Пароль изменен успешно!',
        user: updatedUser,
      );
      
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Ошибка смены пароля: $e',
      );
    }
  }
  
  /// Удаление аккаунта
  static Future<AuthResult> deleteAccount(String password) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'Пользователь не авторизован',
        );
      }
      
      // Проверка пароля
      final hashedPassword = user.preferences?['password_hash'] as String?;
      if (hashedPassword == null || !_verifyPassword(password, hashedPassword)) {
        return AuthResult(
          success: false,
          message: 'Неверный пароль',
        );
      }
      
      // Удаление пользователя
      await _usersBox!.delete(user.id);
      await logout();
      
      return AuthResult(
        success: true,
        message: 'Аккаунт удален успешно',
      );
      
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Ошибка удаления аккаунта: $e',
      );
    }
  }
  
  // Приватные методы
  
  static Future<bool> _userExists(String email, String username) async {
    final users = _usersBox!.values;
    return users.any((user) => 
      user.email.toLowerCase() == email.toLowerCase() || 
      user.username.toLowerCase() == username.toLowerCase()
    );
  }
  
  static Future<UserModel?> _findUser(String emailOrUsername) async {
    final users = _usersBox!.values;
    return users.cast<UserModel?>().firstWhere(
      (user) => user != null && (
        user.email.toLowerCase() == emailOrUsername.toLowerCase() ||
        user.username.toLowerCase() == emailOrUsername.toLowerCase()
      ),
      orElse: () => null,
    );
  }
  
  static Future<void> _setCurrentUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, user.id);
    await prefs.setBool(_isLoggedInKey, true);
  }
  
  static String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9000 * (DateTime.now().microsecond / 1000000))).round()}';
  }
  
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'fitmonster_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  static bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }
  
  static ValidationResult _validateRegistrationData(String email, String username, String password) {
    if (!_isValidEmail(email)) {
      return ValidationResult(false, 'Некорректный email адрес');
    }
    
    if (!_isValidUsername(username)) {
      return ValidationResult(false, 'Имя пользователя должно содержать 3-20 символов (буквы, цифры, _)');
    }
    
    if (!_isValidPassword(password)) {
      return ValidationResult(false, 'Пароль должен содержать минимум 6 символов');
    }
    
    return ValidationResult(true, 'Данные корректны');
  }
  
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }
  
  static bool _isValidPassword(String password) {
    return password.length >= 6;
  }
}

/// Результат операции аутентификации
class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;
  
  const AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

/// Результат валидации
class ValidationResult {
  final bool isValid;
  final String message;
  
  const ValidationResult(this.isValid, this.message);
}