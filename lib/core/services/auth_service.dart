import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/core/services/user_account_firestore_sync.dart';
import 'package:fitmonster/core/services/user_account_service.dart';

/// Результат регистрации
class AuthResult {
  final bool success;
  final String? message;
  final bool emailVerificationSent;

  const AuthResult({
    required this.success,
    this.message,
    this.emailVerificationSent = false,
  });
}

/// Сервис аутентификации: гость (локально) или почта/пароль через Firebase с проверкой почты
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserAccountService _userAccountService = UserAccountService();

  String? _currentUserId;

  /// Гарантирует документ в Firestore после входа (Auth ≠ база данных).
  Future<void> _mirrorAccountToFirestore(String userId) async {
    if (!userId.startsWith('firebase_')) return;
    final acc = await _userAccountService.getByUserId(userId);
    if (acc != null) {
      await UserAccountFirestoreSync.instance.pushAfterLocalSave(acc);
    }
  }

  /// Текущий ID пользователя (локальный user_xxx или firebase_uid)
  String? get currentUserId => _currentUserId;

  /// Вошёл ли пользователь по почте (Firebase)
  bool get isEmailUser =>
      _currentUserId != null && _currentUserId!.startsWith('firebase_');

  /// Email текущего пользователя (если вошёл по почте)
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  /// Подтверждена ли почта у текущего пользователя
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  /// Авторизован ли пользователь
  bool get isAuthenticated => _currentUserId != null;

  /// Регистрация по почте и паролю. Отправляет письмо для подтверждения почты.
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) {
        return const AuthResult(
          success: false,
          message: 'Ошибка создания аккаунта',
        );
      }
      await credential.user!.sendEmailVerification();
      _currentUserId = 'firebase_${credential.user!.uid}';
      await _saveSession();
      await _userAccountService.upsertFromAuth(
        userId: _currentUserId!,
        email: credential.user!.email,
        plainPassword: password,
      );
      await UserAccountFirestoreSync.instance.pullMergeIfRemoteNewer(
        _currentUserId!,
      );
      await _mirrorAccountToFirestore(_currentUserId!);
      return const AuthResult(
        success: true,
        emailVerificationSent: true,
        message: 'На вашу почту отправлено письмо для подтверждения',
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Ошибка регистрации';
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Эта почта уже зарегистрирована';
          break;
        case 'invalid-email':
          msg = 'Некорректный адрес почты';
          break;
        case 'weak-password':
          msg = 'Пароль должен быть не короче 6 символов';
          break;
        default:
          msg = e.message ?? msg;
      }
      return AuthResult(success: false, message: msg);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }

  /// Вход по почте и паролю
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user == null) {
        return const AuthResult(success: false, message: 'Ошибка входа');
      }
      _currentUserId = 'firebase_${credential.user!.uid}';
      await _saveSession();
      await _userAccountService.upsertFromAuth(
        userId: _currentUserId!,
        email: credential.user!.email,
      );
      await UserAccountFirestoreSync.instance.pullMergeIfRemoteNewer(
        _currentUserId!,
      );
      await _mirrorAccountToFirestore(_currentUserId!);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      String msg = 'Ошибка входа';
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Неверная почта или пароль';
          break;
        case 'invalid-email':
          msg = 'Некорректный адрес почты';
          break;
        case 'user-disabled':
          msg = 'Аккаунт отключён';
          break;
        default:
          msg = e.message ?? msg;
      }
      return AuthResult(success: false, message: msg);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }

  /// Повторно отправить письмо для подтверждения почты
  Future<AuthResult> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const AuthResult(
        success: false,
        message: 'Сначала войдите в аккаунт',
      );
    }
    if (user.emailVerified) {
      return const AuthResult(success: true, message: 'Почта уже подтверждена');
    }
    try {
      await user.sendEmailVerification();
      return AuthResult(
        success: true,
        emailVerificationSent: true,
        message: 'Письмо отправлено на ${user.email}',
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Ошибка отправки';
      if (e.code == 'too-many-requests') {
        msg =
            'Письмо уже отправлялось недавно. Подождите 2 минуты и нажмите «Отправить письмо снова».';
      } else {
        msg = e.message ?? msg;
      }
      return AuthResult(success: false, message: msg);
    }
  }

  /// Обновить данные пользователя с сервера (в т.ч. emailVerified)
  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  /// Сохранить сессию в Hive
  Future<void> _saveSession() async {
    if (_currentUserId != null) {
      await HiveService.put(
        box: HiveService.settingsBox,
        key: 'current_user_id',
        value: _currentUserId,
      );
    }
  }

  /// Войти как локальный пользователь (гость)
  Future<void> signIn(String userId) async {
    _currentUserId = userId;
    await _saveSession();
    await _userAccountService.upsertFromAuth(userId: userId);
  }

  /// Выйти. Если был вход по почте — после выхода создаётся гость.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _currentUserId = null;
    await HiveService.delete(
      box: HiveService.settingsBox,
      key: 'current_user_id',
    );
    await createUser();
  }

  /// Восстановить сессию при запуске приложения
  Future<void> restoreSession() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      _currentUserId = 'firebase_${user.uid}';
      await _saveSession();
      await _userAccountService.upsertFromAuth(
        userId: _currentUserId!,
        email: user.email,
      );
      await UserAccountFirestoreSync.instance.pullMergeIfRemoteNewer(
        _currentUserId!,
      );
      await _mirrorAccountToFirestore(_currentUserId!);
      return;
    }
    final savedUserId =
        HiveService.get(box: HiveService.settingsBox, key: 'current_user_id')
            as String?;
    if (savedUserId != null) {
      _currentUserId = savedUserId;
      await _userAccountService.upsertFromAuth(
        userId: savedUserId,
        email: _firebaseAuth.currentUser?.email,
      );
    }
  }

  /// Создать гостевого пользователя (локально)
  Future<String> createUser() async {
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await signIn(userId);
    return userId;
  }
}
