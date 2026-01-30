import 'package:fitmonster/core/services/hive_service.dart';

/// Простой сервис аутентификации для локального использования
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _currentUserId;

  /// Получить текущего пользователя
  String? get currentUserId => _currentUserId;

  /// Проверить, авторизован ли пользователь
  bool get isAuthenticated => _currentUserId != null;

  /// Войти в систему (простая реализация)
  Future<void> signIn(String userId) async {
    _currentUserId = userId;
    
    // Сохраняем в локальном хранилище
    await HiveService.put(
      box: HiveService.settingsBox,
      key: 'current_user_id',
      value: userId,
    );
    
    print('✅ User signed in: $userId');
  }

  /// Выйти из системы
  Future<void> signOut() async {
    _currentUserId = null;
    
    // Удаляем из локального хранилища
    await HiveService.delete(
      box: HiveService.settingsBox,
      key: 'current_user_id',
    );
    
    print('✅ User signed out');
  }

  /// Восстановить сессию при запуске приложения
  Future<void> restoreSession() async {
    final savedUserId = HiveService.get(
      box: HiveService.settingsBox,
      key: 'current_user_id',
    ) as String?;
    
    if (savedUserId != null) {
      _currentUserId = savedUserId;
      print('✅ Session restored for user: $savedUserId');
    }
  }

  /// Создать нового пользователя (простая реализация)
  Future<String> createUser() async {
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await signIn(userId);
    return userId;
  }
}