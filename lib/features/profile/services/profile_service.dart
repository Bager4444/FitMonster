import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/core/services/stats_service.dart';
import 'package:fitmonster/core/services/user_account_service.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';
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
  final UserAccountService _accounts = UserAccountService();

  static const String _userBox = HiveService.userBox;

  // ——— Имя и аватар ———
  Future<AppProfile> getAppProfile() async {
    final userId = _auth.currentUserId;
    if (userId == null) return const AppProfile();

    final account = await _accounts.getByUserId(userId);
    final name =
        HiveService.get(box: _userBox, key: _key('display_name')) as String?;
    final path =
        HiveService.get(box: _userBox, key: _key('avatar_path')) as String?;
    return AppProfile(
      displayName: account?.name ?? name ?? 'Спортсмен',
      avatarPath: path,
      allergies: account?.allergies ?? const [],
      contraindications: account?.contraindications ?? const [],
    );
  }

  Future<void> setDisplayName(String name) async {
    await HiveService.put(
      box: _userBox,
      key: _key('display_name'),
      value: name,
    );
    final userId = _auth.currentUserId;
    if (userId != null) {
      await _accounts.updateProfile(userId: userId, name: name);
    }
  }

  Future<void> setAvatarPath(String? path) async {
    if (path == null) {
      await HiveService.delete(box: _userBox, key: _key('avatar_path'));
    } else {
      await HiveService.put(
        box: _userBox,
        key: _key('avatar_path'),
        value: path,
      );
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
    Achievement(
      id: 'first_workout',
      title: 'Первая тренировка',
      description: 'Завершите первую тренировку',
      icon: '🎯',
    ),
    Achievement(
      id: 'streak_3',
      title: 'Три дня подряд',
      description: 'Тренируйтесь 3 дня подряд',
      icon: '🔥',
    ),
    Achievement(
      id: 'streak_7',
      title: 'Неделя силы',
      description: '7 дней подряд',
      icon: '💪',
    ),
    Achievement(
      id: 'workouts_10',
      title: '10 тренировок',
      description: 'Всего 10 завершённых тренировок',
      icon: '⭐',
    ),
    Achievement(
      id: 'workouts_50',
      title: 'Полтинник',
      description: '50 тренировок',
      icon: '🏅',
    ),
    Achievement(
      id: 'level_5',
      title: 'Уровень 5',
      description: 'Достигните 5 уровня',
      icon: '📈',
    ),
    Achievement(
      id: 'early_bird',
      title: 'Ранняя пташка',
      description: 'Тренировка до 9:00',
      icon: '🌅',
    ),
    Achievement(
      id: 'workouts_100',
      title: 'Сотня',
      description: '100 завершённых тренировок',
      icon: '💯',
    ),
    Achievement(
      id: 'streak_14',
      title: 'Две недели огня',
      description: '14 дней активности подряд',
      icon: '🔥',
    ),
    Achievement(
      id: 'streak_30',
      title: 'Месяц дисциплины',
      description: '30 дней подряд',
      icon: '📅',
    ),
    Achievement(
      id: 'level_10',
      title: 'Ветеран зала',
      description: 'Достигните 10 уровня',
      icon: '🌟',
    ),
    Achievement(
      id: 'exercises_500',
      title: 'Железная выдержка',
      description: '500 зачтённых упражнений в тренировках',
      icon: '🏋️',
    ),
    Achievement(
      id: 'technician_80',
      title: 'Техника на уровне',
      description: 'Средний балл ≥80% (от 5 оценённых сессий)',
      icon: '🎓',
    ),
    Achievement(
      id: 'time_3h',
      title: 'Три часа в движении',
      description: 'Суммарно ≥3 ч активных тренировок',
      icon: '⏱️',
    ),
    Achievement(
      id: 'diet_profile_set',
      title: 'Питание под контролем',
      description: 'Заполнен профиль питания',
      icon: '🥗',
    ),
    Achievement(
      id: 'level_15',
      title: 'Легенда FitMonster',
      description: 'Достигните 15 уровня',
      icon: '👑',
    ),
    Achievement(
      id: 'workouts_200',
      title: 'Двухсотка',
      description: '200 завершённых тренировок',
      icon: '🚀',
    ),
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
    'workouts_100': 120,
    'streak_14': 60,
    'streak_30': 150,
    'level_10': 100,
    'exercises_500': 80,
    'technician_80': 90,
    'time_3h': 55,
    'diet_profile_set': 40,
    'level_15': 200,
    'workouts_200': 160,
  };

  Future<List<String>> _getUnlockedIds() async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    final account = await _accounts.getByUserId(userId);
    if (account != null) return account.achievements;
    final legacy = HiveService.get(box: _userBox, key: _key('achievements'));
    if (legacy is List) return legacy.map((e) => e.toString()).toList();
    return const [];
  }

  Future<void> _unlockAchievement(String id) async {
    final ids = await _getUnlockedIds();
    if (ids.contains(id)) return;
    ids.add(id);
    final userId = _auth.currentUserId;
    if (userId != null) {
      await _accounts.updateAchievements(userId: userId, achievementIds: ids);
    }
    await HiveService.put(box: _userBox, key: _key('achievements'), value: ids);
    final xp = _achievementXp[id] ?? 15;
    await addExperience(xp);
  }

  Future<List<Achievement>> getAchievements() async {
    var unlocked = await _getUnlockedIds();
    final userId = _auth.currentUserId;
    final stats = userId != null ? await _stats.getUserStats(userId) : null;
    final xp = await getExperience();
    final level = levelFromXp(xp);
    final streak = stats?.workoutStreak ?? 0;
    final total = stats?.totalWorkouts ?? 0;
    final account =
        userId != null ? await _accounts.getByUserId(userId) : null;
    final exercises = account?.totalExercises ?? 0;
    final avgScore = account?.averageScorePercent ?? 0;
    final scoredSessions = account?.scoredSessionsCount ?? 0;
    final timeSec = account?.totalTrainingTimeSec ?? 0;
    final dietProfile =
        userId != null ? await DietService.getUserProfile() : null;
    final dietOk =
        dietProfile != null && dietProfile.userId == userId && dietProfile.userId.isNotEmpty;

    Future<void> tryUnlock(String id, bool condition) async {
      if (condition && !unlocked.contains(id)) {
        await _unlockAchievement(id);
        unlocked = await _getUnlockedIds();
      }
    }

    await tryUnlock('first_workout', total >= 1);
    await tryUnlock('streak_3', streak >= 3);
    await tryUnlock('streak_7', streak >= 7);
    await tryUnlock('streak_14', streak >= 14);
    await tryUnlock('streak_30', streak >= 30);
    await tryUnlock('workouts_10', total >= 10);
    await tryUnlock('workouts_50', total >= 50);
    await tryUnlock('workouts_100', total >= 100);
    await tryUnlock('workouts_200', total >= 200);
    await tryUnlock('level_5', level >= 5);
    await tryUnlock('level_10', level >= 10);
    await tryUnlock('level_15', level >= 15);
    await tryUnlock('exercises_500', exercises >= 500);
    await tryUnlock('technician_80', avgScore >= 80 && scoredSessions >= 5);
    await tryUnlock('time_3h', timeSec >= 10800);
    await tryUnlock('diet_profile_set', dietOk);
    if (stats != null) {
      await tryUnlock('early_bird', stats.lastWorkoutDate.hour < 9);
    }

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
