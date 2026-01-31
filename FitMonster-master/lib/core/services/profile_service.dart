import 'package:fitmonster/features/diet/domain/models/user_profile.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// Сервис для работы с профилем пользователя
class ProfileService {
  /// Получить профиль пользователя
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      // Получаем из Hive (локально)
      final localData = HiveService.get(
        box: HiveService.userBox,
        key: 'profile_$userId',
      );

      if (localData != null) {
        if (localData is UserProfile) {
          return localData;
        } else if (localData is Map<String, dynamic>) {
          return UserProfile.fromMap(localData);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Сохранить профиль пользователя
  Future<void> saveUserProfile(String userId, UserProfile profile) async {
    try {
      // Сохраняем локально
      await HiveService.put(
        box: HiveService.userBox,
        key: 'profile_$userId',
        value: profile,
      );

      print('✅ User profile saved');
    } catch (e) {
      print('❌ Error saving user profile: $e');
      rethrow;
    }
  }

  /// Обновить профиль пользователя
  Future<void> updateUserProfile({
    required String userId,
    int? age,
    double? height,
    double? weight,
    Gender? gender,
    ActivityLevel? activityLevel,
    Goal? goal,
    List<String>? allergies,
    List<String>? contraindications,
  }) async {
    try {
      final currentProfile = await getUserProfile(userId);
      if (currentProfile == null) return;

      final updatedProfile = currentProfile.copyWith(
        age: age,
        height: height,
        weight: weight,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
        allergies: allergies,
        contraindications: contraindications,
        updatedAt: DateTime.now(),
      );

      await saveUserProfile(userId, updatedProfile);
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Обновить личные данные пользователя
  Future<void> updatePersonalInfo({
    required String userId,
    String? name,
    int? age,
    double? weight,
    double? height,
  }) async {
    await updateUserProfile(
      userId: userId,
      age: age,
      height: height,
      weight: weight,
    );
  }
}