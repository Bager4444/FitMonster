import 'package:google_sign_in/google_sign_in.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// Сервис аутентификации: локальный пользователь и вход через Google
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  String? _currentUserId;

  /// Текущий ID пользователя (локальный или google_xxx)
  String? get currentUserId => _currentUserId;

  /// Вошёл ли пользователь через Google
  bool get isGoogleUser =>
      _currentUserId != null && _currentUserId!.startsWith('google_');

  /// Email от Google (если вошли через Google)
  String? get googleEmail =>
      HiveService.get(box: HiveService.settingsBox, key: 'google_email') as String?;

  /// Имя/фамилия от Google (если вошли через Google)
  String? get googleDisplayName =>
      HiveService.get(box: HiveService.settingsBox, key: 'google_display_name') as String?;

  /// Авторизован ли пользователь
  bool get isAuthenticated => _currentUserId != null;

  /// Вход через Google
  /// Возвращает true при успехе, false при отмене или ошибке
  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final userId = 'google_${account.id}';
      _currentUserId = userId;

      await HiveService.put(
        box: HiveService.settingsBox,
        key: 'current_user_id',
        value: userId,
      );
      await HiveService.put(
        box: HiveService.settingsBox,
        key: 'google_email',
        value: account.email ?? '',
      );
      await HiveService.put(
        box: HiveService.settingsBox,
        key: 'google_display_name',
        value: account.displayName ?? '',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Войти по ID (локальный пользователь)
  Future<void> signIn(String userId) async {
    _currentUserId = userId;
    await HiveService.put(
      box: HiveService.settingsBox,
      key: 'current_user_id',
      value: userId,
    );
  }

  /// Выйти из системы (в т.ч. из Google). После выхода создаётся гость.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUserId = null;
    await HiveService.delete(
      box: HiveService.settingsBox,
      key: 'current_user_id',
    );
    await HiveService.delete(
      box: HiveService.settingsBox,
      key: 'google_email',
    );
    await HiveService.delete(
      box: HiveService.settingsBox,
      key: 'google_display_name',
    );
    await createUser();
  }

  /// Восстановить сессию при запуске приложения
  Future<void> restoreSession() async {
    final savedUserId = HiveService.get(
      box: HiveService.settingsBox,
      key: 'current_user_id',
    ) as String?;

    if (savedUserId != null) {
      _currentUserId = savedUserId;
      if (isGoogleUser) {
        try {
          await _googleSignIn.signInSilently();
        } catch (_) {
          // Сессия Google истекла — пользователь остаётся с тем же userId
        }
      }
    }
  }

  /// Создать локального пользователя (гость, без Google)
  Future<String> createUser() async {
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await signIn(userId);
    return userId;
  }
}
