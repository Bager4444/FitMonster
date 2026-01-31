/// Сервис, который всегда возвращает нулевую статистику
class ZeroStatsService {
  static const Map<String, dynamic> zeroStats = {
    // Основная статистика
    'calories': 0,
    'minutes': 0,
    'days_streak': 0,
    'workouts': 0,
    'repetitions': 0,
    'points': 0,
    
    // Упражнения
    'pushups': 0,
    'squats': 0,
    'plank_seconds': 0,
    'crunches': 0,
    'pullups': 0,
    'burpees': 0,
    
    // Достижения
    'achievements': [],
    'rank': 'Не участвует',
    'region': 'Не выбран',
    
    // Лидерборды
    'global_rank': 'Очищен',
    'russia_rank': 'Очищен',
    'moscow_rank': 'Очищен',
    'spb_rank': 'Очищен',
    'novosibirsk_rank': 'Очищен',
    'ekaterinburg_rank': 'Очищен',
    'kazan_rank': 'Очищен',
    'nizhny_novgorod_rank': 'Очищен',
  };
  
  /// Получить нулевую статистику
  static Map<String, dynamic> getZeroStats() {
    return Map<String, dynamic>.from(zeroStats);
  }
  
  /// Получить значение статистики (всегда 0)
  static int getStatValue(String key) {
    final value = zeroStats[key];
    return value is int ? value : 0;
  }
  
  /// Получить строковое значение статистики
  static String getStatString(String key) {
    final value = zeroStats[key];
    return value?.toString() ?? '0';
  }
  
  /// Проверить, есть ли достижения (всегда false)
  static bool hasAchievements() {
    return false;
  }
  
  /// Получить список достижений (всегда пустой)
  static List<dynamic> getAchievements() {
    return [];
  }
  
  /// Получить статус лидерборда (всегда "Очищен")
  static String getLeaderboardStatus(String region) {
    return 'Очищен';
  }
}