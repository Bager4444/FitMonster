import 'package:fitmonster/features/profile/services/profile_service.dart';

/// Сервис начисления опыта (делегирует в ProfileService).
class ExperienceService {
  static final ProfileService _profile = ProfileService();

  static Future<int> addExperience(int amount) async {
    return _profile.addExperience(amount);
  }
}
