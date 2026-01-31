import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Адаптивная система обучения с персонализацией и прогрессивным улучшением
class AdaptiveLearningSystem {
  // Персональный профиль обучения
  final _PersonalLearningProfile _profile = _PersonalLearningProfile();
  
  // Система адаптации сложности
  final _DifficultyAdapter _difficultyAdapter = _DifficultyAdapter();
  
  // Анализатор прогресса
  final _ProgressAnalyzer _progressAnalyzer = _ProgressAnalyzer();
  
  // Система рекомендаций
  final _RecommendationEngine _recommendationEngine = _RecommendationEngine();
  
  // Детектор плато в обучении
  final _PlateauDetector _plateauDetector = _PlateauDetector();
  
  // Мотивационная система
  final _MotivationSystem _motivationSystem = _MotivationSystem();
  
  String _userId = '';
  bool _isInitialized = false;
  
  /// Инициализация системы обучения
  Future<void> initialize(String userId) async {
    _userId = userId;
    await _profile.loadProfile(userId);
    await _progressAnalyzer.loadHistory(userId);
    _difficultyAdapter.calibrate(_profile);
    _recommendationEngine.initialize(_profile);
    _isInitialized = true;
  }
  
  /// Адаптивный анализ с обучением
  Future<AdaptiveLearningResult> analyzeAndLearn(
    Pose pose,
    String exerciseType,
    double currentPerformance,
  ) async {
    if (!_isInitialized) {
      throw StateError('AdaptiveLearningSystem не инициализирован');
    }
    
    // Обновление профиля на основе текущего выполнения
    await _profile.updateWithPerformance(exerciseType, currentPerformance, pose);
    
    // Анализ прогресса
    final progressAnalysis = _progressAnalyzer.analyzeProgress(exerciseType, currentPerformance);
    
    // Адаптация сложности
    final difficultyAdjustment = _difficultyAdapter.adjustDifficulty(
      exerciseType, 
      progressAnalysis,
      _profile.getSkillLevel(exerciseType),
    );
    
    // Детекция плато
    final plateauStatus = _plateauDetector.checkForPlateau(exerciseType, progressAnalysis);
    
    // Генерация рекомендаций
    final recommendations = await _recommendationEngine.generateRecommendations(
      exerciseType,
      progressAnalysis,
      plateauStatus,
      difficultyAdjustment,
    );
    
    // Мотивационные элементы
    final motivation = _motivationSystem.generateMotivation(
      progressAnalysis,
      _profile.getPersonalityType(),
    );
    
    return AdaptiveLearningResult(
      progressAnalysis: progressAnalysis,
      difficultyAdjustment: difficultyAdjustment,
      recommendations: recommendations,
      plateauStatus: plateauStatus,
      motivation: motivation,
      personalizedFeedback: _generatePersonalizedFeedback(progressAnalysis, motivation),
      nextGoals: _generateNextGoals(progressAnalysis, difficultyAdjustment),
    );
  }
  
  String _generatePersonalizedFeedback(ProgressAnalysis progress, MotivationPackage motivation) {
    final baseMessages = [
      'Отличная работа! Ваш прогресс составляет ${(progress.improvementRate * 100).toInt()}%',
      'Продолжайте в том же духе! Техника улучшается',
      'Великолепно! Вы превосходите свои предыдущие результаты',
    ];
    
    var message = baseMessages[math.Random().nextInt(baseMessages.length)];
    
    // Добавляем мотивационные элементы
    if (motivation.achievementUnlocked != null) {
      message += ' ${motivation.achievementUnlocked!.emoji} ${motivation.achievementUnlocked!.title}!';
    }
    
    return message;
  }
  
  List<PersonalGoal> _generateNextGoals(ProgressAnalysis progress, DifficultyAdjustment difficulty) {
    final goals = <PersonalGoal>[];
    
    // Цели на основе текущего прогресса
    if (progress.improvementRate > 0.1) {
      goals.add(PersonalGoal(
        title: 'Мастер техники',
        description: 'Достигните 95% точности выполнения',
        targetValue: 0.95,
        currentValue: progress.currentAccuracy,
        deadline: DateTime.now().add(const Duration(days: 7)),
        reward: 'Разблокировка нового упражнения',
      ));
    }
    
    if (difficulty.shouldIncrease) {
      goals.add(PersonalGoal(
        title: 'Повышение уровня',
        description: 'Выполните ${difficulty.newTargetReps} повторений',
        targetValue: difficulty.newTargetReps.toDouble(),
        currentValue: progress.averageReps.toDouble(),
        deadline: DateTime.now().add(const Duration(days: 3)),
        reward: 'Новый уровень сложности',
      ));
    }
    
    return goals;
  }
}

/// Персональный профиль обучения
class _PersonalLearningProfile {
  String _userId = '';
  final Map<String, SkillLevel> _skillLevels = {};
  final Map<String, List<PerformanceRecord>> _performanceHistory = {};
  final Map<String, LearningPreferences> _preferences = {};
  PersonalityType _personalityType = PersonalityType.balanced;
  final Map<String, MovementCharacteristics> _movementPatterns = {};
  
  Future<void> loadProfile(String userId) async {
    _userId = userId;
    // Загрузка из базы данных
    await _loadSkillLevels();
    await _loadPerformanceHistory();
    await _loadPreferences();
    await _detectPersonalityType();
  }
  
  Future<void> _loadSkillLevels() async {
    // Инициализация базовых уровней
    _skillLevels['squats'] = SkillLevel.beginner;
    _skillLevels['pushups'] = SkillLevel.beginner;
    _skillLevels['lunges'] = SkillLevel.beginner;
  }
  
  Future<void> _loadPerformanceHistory() async {
    // Загрузка истории выполнения
    for (final exercise in _skillLevels.keys) {
      _performanceHistory[exercise] = [];
    }
  }
  
  Future<void> _loadPreferences() async {
    // Загрузка предпочтений пользователя
    for (final exercise in _skillLevels.keys) {
      _preferences[exercise] = LearningPreferences(
        preferredFeedbackStyle: FeedbackStyle.encouraging,
        difficultyPreference: DifficultyPreference.gradual,
        motivationStyle: MotivationStyle.achievement,
      );
    }
  }
  
  Future<void> _detectPersonalityType() async {
    // Анализ поведения для определения типа личности
    final totalSessions = _performanceHistory.values
        .expand((records) => records)
        .length;
    
    if (totalSessions < 5) {
      _personalityType = PersonalityType.explorer;
    } else {
      // Анализ паттернов поведения
      final consistencyScore = _calculateConsistency();
      final challengeSeekingScore = _calculateChallengeSeekingBehavior();
      
      if (consistencyScore > 0.8 && challengeSeekingScore < 0.3) {
        _personalityType = PersonalityType.methodical;
      } else if (challengeSeekingScore > 0.7) {
        _personalityType = PersonalityType.competitive;
      } else {
        _personalityType = PersonalityType.balanced;
      }
    }
  }
  
  double _calculateConsistency() {
    // Расчет консистентности тренировок
    return 0.7;
  }
  
  double _calculateChallengeSeekingBehavior() {
    // Анализ стремления к сложным задачам
    return 0.5;
  }
  
  Future<void> updateWithPerformance(String exercise, double performance, Pose pose) async {
    final record = PerformanceRecord(
      timestamp: DateTime.now(),
      performance: performance,
      pose: pose,
      sessionDuration: const Duration(minutes: 5),
    );
    
    _performanceHistory[exercise]?.add(record);
    
    // Ограничиваем историю последними 100 записями
    if (_performanceHistory[exercise]!.length > 100) {
      _performanceHistory[exercise]!.removeAt(0);
    }
    
    // Обновляем характеристики движения
    _updateMovementCharacteristics(exercise, pose);
    
    // Проверяем необходимость повышения уровня
    _checkForLevelUp(exercise);
  }
  
  void _updateMovementCharacteristics(String exercise, Pose pose) {
    if (!_movementPatterns.containsKey(exercise)) {
      _movementPatterns[exercise] = MovementCharacteristics();
    }
    
    final characteristics = _movementPatterns[exercise]!;
    characteristics.updateWithPose(pose);
  }
  
  void _checkForLevelUp(String exercise) {
    final history = _performanceHistory[exercise] ?? [];
    if (history.length < 10) return;
    
    final recentPerformance = history.takeLast(10).map((r) => r.performance).toList();
    final averagePerformance = recentPerformance.reduce((a, b) => a + b) / recentPerformance.length;
    
    final currentLevel = _skillLevels[exercise] ?? SkillLevel.beginner;
    
    if (averagePerformance > 0.85 && currentLevel == SkillLevel.beginner) {
      _skillLevels[exercise] = SkillLevel.intermediate;
    } else if (averagePerformance > 0.92 && currentLevel == SkillLevel.intermediate) {
      _skillLevels[exercise] = SkillLevel.advanced;
    }
  }
  
  SkillLevel getSkillLevel(String exercise) {
    return _skillLevels[exercise] ?? SkillLevel.beginner;
  }
  
  PersonalityType getPersonalityType() => _personalityType;
  
  List<PerformanceRecord> getPerformanceHistory(String exercise) {
    return _performanceHistory[exercise] ?? [];
  }
  
  LearningPreferences getPreferences(String exercise) {
    return _preferences[exercise] ?? LearningPreferences.defaultPreferences();
  }
}

/// Адаптер сложности
class _DifficultyAdapter {
  late _PersonalLearningProfile _profile;
  final Map<String, DifficultySettings> _currentSettings = {};
  
  void calibrate(_PersonalLearningProfile profile) {
    _profile = profile;
    
    // Инициализация настроек сложности для каждого упражнения
    for (final exercise in ['squats', 'pushups', 'lunges']) {
      _currentSettings[exercise] = DifficultySettings.forLevel(
        _profile.getSkillLevel(exercise)
      );
    }
  }
  
  DifficultyAdjustment adjustDifficulty(
    String exercise,
    ProgressAnalysis progress,
    SkillLevel currentLevel,
  ) {
    final currentSettings = _currentSettings[exercise] ?? DifficultySettings.beginner();
    
    // Анализ необходимости изменения сложности
    bool shouldIncrease = false;
    bool shouldDecrease = false;
    
    if (progress.improvementRate > 0.15 && progress.currentAccuracy > 0.9) {
      shouldIncrease = true;
    } else if (progress.improvementRate < -0.1 || progress.currentAccuracy < 0.6) {
      shouldDecrease = true;
    }
    
    // Расчет новых параметров
    int newTargetReps = currentSettings.targetReps;
    double newSpeedMultiplier = currentSettings.speedMultiplier;
    double newAccuracyThreshold = currentSettings.accuracyThreshold;
    
    if (shouldIncrease) {
      newTargetReps = (currentSettings.targetReps * 1.2).round();
      newSpeedMultiplier = math.min(currentSettings.speedMultiplier * 1.1, 2.0);
      newAccuracyThreshold = math.min(currentSettings.accuracyThreshold + 0.05, 0.95);
    } else if (shouldDecrease) {
      newTargetReps = math.max((currentSettings.targetReps * 0.8).round(), 5);
      newSpeedMultiplier = math.max(currentSettings.speedMultiplier * 0.9, 0.5);
      newAccuracyThreshold = math.max(currentSettings.accuracyThreshold - 0.05, 0.6);
    }
    
    // Обновляем настройки
    if (shouldIncrease || shouldDecrease) {
      _currentSettings[exercise] = DifficultySettings(
        targetReps: newTargetReps,
        speedMultiplier: newSpeedMultiplier,
        accuracyThreshold: newAccuracyThreshold,
      );
    }
    
    return DifficultyAdjustment(
      shouldIncrease: shouldIncrease,
      shouldDecrease: shouldDecrease,
      newTargetReps: newTargetReps,
      newSpeedMultiplier: newSpeedMultiplier,
      newAccuracyThreshold: newAccuracyThreshold,
      reasoning: _generateDifficultyReasoning(shouldIncrease, shouldDecrease, progress),
    );
  }
  
  String _generateDifficultyReasoning(bool increase, bool decrease, ProgressAnalysis progress) {
    if (increase) {
      return 'Отличный прогресс! Повышаем сложность для дальнейшего развития';
    } else if (decrease) {
      return 'Снижаем сложность для лучшего освоения техники';
    } else {
      return 'Текущий уровень сложности оптимален';
    }
  }
}

/// Анализатор прогресса
class _ProgressAnalyzer {
  final Map<String, List<ProgressDataPoint>> _progressHistory = {};
  
  Future<void> loadHistory(String userId) async {
    // Загрузка истории прогресса
    for (final exercise in ['squats', 'pushups', 'lunges']) {
      _progressHistory[exercise] = [];
    }
  }
  
  ProgressAnalysis analyzeProgress(String exercise, double currentPerformance) {
    final history = _progressHistory[exercise] ?? [];
    
    // Добавляем текущую точку данных
    history.add(ProgressDataPoint(
      timestamp: DateTime.now(),
      performance: currentPerformance,
    ));
    
    // Ограничиваем историю
    if (history.length > 50) {
      history.removeAt(0);
    }
    
    // Анализ трендов
    final improvementRate = _calculateImprovementRate(history);
    final consistency = _calculateConsistency(history);
    final currentAccuracy = currentPerformance;
    final averageReps = _calculateAverageReps(history);
    final bestPerformance = history.isNotEmpty 
        ? history.map((p) => p.performance).reduce(math.max)
        : 0.0;
    
    return ProgressAnalysis(
      improvementRate: improvementRate,
      consistency: consistency,
      currentAccuracy: currentAccuracy,
      averageReps: averageReps,
      bestPerformance: bestPerformance,
      sessionsCompleted: history.length,
      trend: _determineTrend(improvementRate, consistency),
    );
  }
  
  double _calculateImprovementRate(List<ProgressDataPoint> history) {
    if (history.length < 2) return 0.0;
    
    final recent = history.takeLast(5).map((p) => p.performance).toList();
    final older = history.length > 10 
        ? history.skip(history.length - 10).take(5).map((p) => p.performance).toList()
        : history.take(5).map((p) => p.performance).toList();
    
    if (recent.isEmpty || older.isEmpty) return 0.0;
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    return olderAvg > 0 ? (recentAvg - olderAvg) / olderAvg : 0.0;
  }
  
  double _calculateConsistency(List<ProgressDataPoint> history) {
    if (history.length < 3) return 0.0;
    
    final performances = history.map((p) => p.performance).toList();
    final mean = performances.reduce((a, b) => a + b) / performances.length;
    final variance = performances
        .map((p) => math.pow(p - mean, 2))
        .reduce((a, b) => a + b) / performances.length;
    
    final standardDeviation = math.sqrt(variance);
    return mean > 0 ? 1.0 - (standardDeviation / mean).clamp(0.0, 1.0) : 0.0;
  }
  
  int _calculateAverageReps(List<ProgressDataPoint> history) {
    // Упрощенный расчет среднего количества повторений
    return history.isNotEmpty ? (history.length * 1.5).round() : 0;
  }
  
  ProgressTrend _determineTrend(double improvementRate, double consistency) {
    if (improvementRate > 0.1 && consistency > 0.7) {
      return ProgressTrend.steadyImprovement;
    } else if (improvementRate > 0.05) {
      return ProgressTrend.slowImprovement;
    } else if (improvementRate < -0.05) {
      return ProgressTrend.declining;
    } else {
      return ProgressTrend.plateau;
    }
  }
}

// ========== МОДЕЛИ ДАННЫХ ==========

class AdaptiveLearningResult {
  final ProgressAnalysis progressAnalysis;
  final DifficultyAdjustment difficultyAdjustment;
  final List<PersonalizedRecommendation> recommendations;
  final PlateauStatus plateauStatus;
  final MotivationPackage motivation;
  final String personalizedFeedback;
  final List<PersonalGoal> nextGoals;
  
  const AdaptiveLearningResult({
    required this.progressAnalysis,
    required this.difficultyAdjustment,
    required this.recommendations,
    required this.plateauStatus,
    required this.motivation,
    required this.personalizedFeedback,
    required this.nextGoals,
  });
}

class ProgressAnalysis {
  final double improvementRate;
  final double consistency;
  final double currentAccuracy;
  final int averageReps;
  final double bestPerformance;
  final int sessionsCompleted;
  final ProgressTrend trend;
  
  const ProgressAnalysis({
    required this.improvementRate,
    required this.consistency,
    required this.currentAccuracy,
    required this.averageReps,
    required this.bestPerformance,
    required this.sessionsCompleted,
    required this.trend,
  });
}

enum ProgressTrend {
  steadyImprovement,
  slowImprovement,
  plateau,
  declining,
}

class DifficultyAdjustment {
  final bool shouldIncrease;
  final bool shouldDecrease;
  final int newTargetReps;
  final double newSpeedMultiplier;
  final double newAccuracyThreshold;
  final String reasoning;
  
  const DifficultyAdjustment({
    required this.shouldIncrease,
    required this.shouldDecrease,
    required this.newTargetReps,
    required this.newSpeedMultiplier,
    required this.newAccuracyThreshold,
    required this.reasoning,
  });
}

class PersonalizedRecommendation {
  final String title;
  final String description;
  final RecommendationType type;
  final int priority;
  final Duration estimatedTime;
  
  const PersonalizedRecommendation({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.estimatedTime,
  });
}

enum RecommendationType {
  technique,
  frequency,
  intensity,
  recovery,
  motivation,
}

class PlateauStatus {
  final bool isInPlateau;
  final Duration plateauDuration;
  final List<String> breakoutStrategies;
  
  const PlateauStatus({
    required this.isInPlateau,
    required this.plateauDuration,
    required this.breakoutStrategies,
  });
}

class MotivationPackage {
  final String primaryMessage;
  final Achievement? achievementUnlocked;
  final List<String> encouragements;
  final MotivationLevel level;
  
  const MotivationPackage({
    required this.primaryMessage,
    this.achievementUnlocked,
    required this.encouragements,
    required this.level,
  });
}

class Achievement {
  final String title;
  final String description;
  final String emoji;
  final int points;
  
  const Achievement({
    required this.title,
    required this.description,
    required this.emoji,
    required this.points,
  });
}

enum MotivationLevel { low, medium, high, peak }

class PersonalGoal {
  final String title;
  final String description;
  final double targetValue;
  final double currentValue;
  final DateTime deadline;
  final String reward;
  
  const PersonalGoal({
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.deadline,
    required this.reward,
  });
  
  double get progress => currentValue / targetValue;
  bool get isCompleted => currentValue >= targetValue;
}

// Дополнительные классы для поддержки системы
class PerformanceRecord {
  final DateTime timestamp;
  final double performance;
  final Pose pose;
  final Duration sessionDuration;
  
  const PerformanceRecord({
    required this.timestamp,
    required this.performance,
    required this.pose,
    required this.sessionDuration,
  });
}

class ProgressDataPoint {
  final DateTime timestamp;
  final double performance;
  
  const ProgressDataPoint({
    required this.timestamp,
    required this.performance,
  });
}

enum SkillLevel { beginner, intermediate, advanced, expert }

enum PersonalityType { methodical, competitive, explorer, balanced }

enum FeedbackStyle { direct, encouraging, detailed, minimal }

enum DifficultyPreference { gradual, aggressive, adaptive }

enum MotivationStyle { achievement, progress, social, personal }

class LearningPreferences {
  final FeedbackStyle preferredFeedbackStyle;
  final DifficultyPreference difficultyPreference;
  final MotivationStyle motivationStyle;
  
  const LearningPreferences({
    required this.preferredFeedbackStyle,
    required this.difficultyPreference,
    required this.motivationStyle,
  });
  
  static LearningPreferences defaultPreferences() {
    return const LearningPreferences(
      preferredFeedbackStyle: FeedbackStyle.encouraging,
      difficultyPreference: DifficultyPreference.gradual,
      motivationStyle: MotivationStyle.progress,
    );
  }
}

class DifficultySettings {
  final int targetReps;
  final double speedMultiplier;
  final double accuracyThreshold;
  
  const DifficultySettings({
    required this.targetReps,
    required this.speedMultiplier,
    required this.accuracyThreshold,
  });
  
  static DifficultySettings forLevel(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return const DifficultySettings(
          targetReps: 5,
          speedMultiplier: 0.8,
          accuracyThreshold: 0.7,
        );
      case SkillLevel.intermediate:
        return const DifficultySettings(
          targetReps: 10,
          speedMultiplier: 1.0,
          accuracyThreshold: 0.8,
        );
      case SkillLevel.advanced:
        return const DifficultySettings(
          targetReps: 15,
          speedMultiplier: 1.2,
          accuracyThreshold: 0.9,
        );
      case SkillLevel.expert:
        return const DifficultySettings(
          targetReps: 20,
          speedMultiplier: 1.5,
          accuracyThreshold: 0.95,
        );
    }
  }
  
  static DifficultySettings beginner() => forLevel(SkillLevel.beginner);
}

class MovementCharacteristics {
  double averageSpeed = 0.0;
  double averageAmplitude = 0.0;
  double preferredTempo = 1.0;
  int updateCount = 0;
  
  void updateWithPose(Pose pose) {
    // Упрощенное обновление характеристик движения
    updateCount++;
    
    // В реальной реализации здесь был бы анализ позы
    // для определения скорости, амплитуды и темпа движения
  }
}

// Заглушки для дополнительных классов
class _PlateauDetector {
  PlateauStatus checkForPlateau(String exercise, ProgressAnalysis progress) {
    return const PlateauStatus(
      isInPlateau: false,
      plateauDuration: Duration.zero,
      breakoutStrategies: [],
    );
  }
}

class _RecommendationEngine {
  void initialize(_PersonalLearningProfile profile) {}
  
  Future<List<PersonalizedRecommendation>> generateRecommendations(
    String exercise,
    ProgressAnalysis progress,
    PlateauStatus plateau,
    DifficultyAdjustment difficulty,
  ) async {
    return [];
  }
}

class _MotivationSystem {
  MotivationPackage generateMotivation(ProgressAnalysis progress, PersonalityType personality) {
    return const MotivationPackage(
      primaryMessage: 'Отличная работа!',
      encouragements: ['Продолжайте в том же духе!'],
      level: MotivationLevel.medium,
    );
  }
}

// Расширение для List
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}