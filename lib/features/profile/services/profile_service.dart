import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/core/services/stats_service.dart';
import 'package:fitmonster/features/profile/domain/models/app_profile.dart';
import 'package:fitmonster/features/profile/domain/models/achievement.dart';

/// Ключи в user box для текущего пользователя
String _key(String suffix) {
  final userId = AuthService().currentUserId ?? 'default';
  return 'profile_${userId}_$suffix';
}

/// Сервис профиля: имя, аватар, опыт, уровни, достижения
class ProfileService {
  final AuthService _auth = AuthService();
  final StatsService _stats = StatsService();

  static const String _userBox = HiveService.userBox;

  // ——— Имя и аватар ———
  Future<AppProfile> getAppProfile() async {
    final userId = _auth.currentUserId;
    if (userId == null) return const AppProfile();

    final name = HiveService.get(box: _userBox, key: _key('display_name')) as String?;
    final path = HiveService.get(box: _userBox, key: _key('avatar_path')) as String?;
    return AppProfile(
      displayName: name ?? 'Спортсмен',
      avatarPath: path,
    );
  }

  Future<void> setDisplayName(String name) async {
    await HiveService.put(box: _userBox, key: _key('display_name'), value: name);
  }

  Future<void> setAvatarPath(String? path) async {
    if (path == null) {
      await HiveService.delete(box: _userBox, key: _key('avatar_path'));
    } else {
      await HiveService.put(box: _userBox, key: _key('avatar_path'), value: path);
    }
  }

  // ——— Опыт и уровни ———
  /// Уровень 1 = 0–99 XP, уровень 2 = 100–199, уровень 3 = 200–299...
  static int levelFromXp(int xp) {
    if (xp < 0) return 1;
    return (1 + (xp / 100).floor()).clamp(1, 99);
  }

  /// XP внутри текущего уровня (0..99)
  static int xpProgressInLevel(int xp) {
    if (xp <= 0) return 0;
    return (xp % 100).clamp(0, 99);
  }

  /// Сколько XP нужно до следующего уровня (всегда 100 в текущей формуле)
  static int xpNeededInLevel(int xp) => 100;

  Future<int> getExperience() async {
    final userId = _auth.currentUserId;
    if (userId == null) return 0;
    final v = HiveService.get(box: _userBox, key: _key('xp'));
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return 0;
  }

  /// Добавить опыт, возвращает новый общий XP
  Future<int> addExperience(int amount) async {
    final userId = _auth.currentUserId;
    if (userId == null) return 0;
    final current = await getExperience();
    final next = current + amount;
    await HiveService.put(box: _userBox, key: _key('xp'), value: next);
    return next;
  }

  // ——— Достижения ———
  static const List<Achievement> allAchievements = [
    Achievement(id: 'first_workout', title: 'Первая тренировка', description: 'Завершите первую тренировку', icon: '🎯'),
    Achievement(id: 'streak_3', title: 'Три дня подряд', description: 'Тренируйтесь 3 дня подряд', icon: '🔥'),
    Achievement(id: 'streak_7', title: 'Неделя силы', description: '7 дней подряд', icon: '💪'),
    Achievement(id: 'workouts_10', title: '10 тренировок', description: 'Всего 10 завершённых тренировок', icon: '⭐'),
    Achievement(id: 'workouts_50', title: 'Полтинник', description: '50 тренировок', icon: '🏅'),
    Achievement(id: 'level_5', title: 'Уровень 5', description: 'Достигните 5 уровня', icon: '📈'),
    Achievement(id: 'early_bird', title: 'Ранняя пташка', description: 'Тренировка до 9:00', icon: '🌅'),
  ];

  /// Опыт за разблокировку достижения
  static const Map<String, int> _achievementXp = {
    'first_workout': 10,
    'streak_3': 25,
    'streak_7': 50,
    'workouts_10': 30,
    'workouts_50': 100,
    'level_5': 75,
    'early_bird': 20,
  };

  Future<List<String>> _getUnlockedIds() async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    final v = HiveService.get(box: _userBox, key: _key('achievements'));
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  Future<void> _unlockAchievement(String id) async {
    final ids = await _getUnlockedIds();
    if (ids.contains(id)) return;
    ids.add(id);
    await HiveService.put(box: _userBox, key: _key('achievements'), value: ids);
    final xp = _achievementXp[id] ?? 15;
    await addExperience(xp);
  }

  Future<List<Achievement>> getAchievements() async {
    final unlocked = await _getUnlockedIds();
    final stats = _auth.currentUserId != null
        ? await _stats.getUserStats(_auth.currentUserId!)
        : null;
    final xp = await getExperience();
    final level = levelFromXp(xp);
    final streak = stats?.workoutStreak ?? 0;
    final total = stats?.totalWorkouts ?? 0;

    // Проверяем и при необходимости разблокируем
    if (total >= 1 && !unlocked.contains('first_workout')) await _unlockAchievement('first_workout');
    if (streak >= 3 && !unlocked.contains('streak_3')) await _unlockAchievement('streak_3');
    if (streak >= 7 && !unlocked.contains('streak_7')) await _unlockAchievement('streak_7');
    if (total >= 10 && !unlocked.contains('workouts_10')) await _unlockAchievement('workouts_10');
    if (total >= 50 && !unlocked.contains('workouts_50')) await _unlockAchievement('workouts_50');
    if (level >= 5 && !unlocked.contains('level_5')) await _unlockAchievement('level_5');

    final unlockedAfter = await _getUnlockedIds();
    final unlockedSet = unlockedAfter.toSet();

    return allAchievements.map((a) {
      final at = unlockedSet.contains(a.id) ? DateTime.now() : null;
      return Achievement(
        id: a.id,
        title: a.title,
        description: a.description,
        icon: a.icon,
        unlockedAt: at,
      );
    }).toList();
  }
}
