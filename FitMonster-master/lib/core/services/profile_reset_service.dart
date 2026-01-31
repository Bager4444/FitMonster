import 'package:fitmonster/core/services/profile_service.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';

/// Сервис для работы с нулевыми профилями пользователя
class ProfileResetService {
  static final ProfileResetService _instance = ProfileResetService._internal();
  factory ProfileResetService() => _instance;
  ProfileResetService._internal();

  final ProfileService _profileService = ProfileService();

  /// Получить существующий профиль или создать нулевой
  Future<UserProfile> getOrCreateZeroProfile(String userId) async {
    try {
      // ProfileService теперь автоматически создает нулевой профиль если его нет
      final profile = await _profileService.getUserProfile(userId);
      return profile!; // Не может быть null, так как создается автоматически
    } catch (e) {
      print('❌ Error getting or creating profile: $e');
      rethrow;
    }
  }

  /// Проверить, есть ли данные пользователя
  Future<bool> hasUserData(String userId) async {
    try {
      final profile = await _profileService.getUserProfile(userId);
      return profile != null;
    } catch (e) {
      print('❌ Error checking user data: $e');
      return false;
    }
  }
}
}
}