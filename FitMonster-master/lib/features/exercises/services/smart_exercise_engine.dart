import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'enhanced_exercise_analyzer.dart';
import 'improved_rep_counter.dart';

/// Умный движок для анализа упражнений, объединяющий улучшенный анализатор и счетчик повторений
class SmartExerciseEngine {
  final EnhancedExerciseAnalyzer _analyzer = EnhancedExerciseAnalyzer();
  final ImprovedRepCounter _repCounter = ImprovedRepCounter();
  
  // Состояние движка
  String _currentExercise = 'squats';
  int _frameCount = 0;
  DateTime _lastAnalysis = DateTime.now();
  
  // Адаптивные параметры
  bool _isHighPerformanceMode = true;
  double _confidenceThreshold = 0.6;
  int _analysisInterval = 1; // Анализируем каждый кадр в высокопроизводительном режиме
  
  // Кэш результатов для оптимизации
  SmartExerciseResult? _lastResult;
  DateTime _lastResultTime = DateTime.now();
  
  // Статистика производительности
  final List<double> _fpsHistory = [];
  static const int _fpsHistorySize = 10;
  
  /// Устанавливает тип упражнения
  void setExercise(String exerciseType) {
    if (_currentExercise != exerciseType) {
      _currentExercise = exerciseType;
      _repCounter.setExerciseType(exerciseType);
      _analyzer.clearCache();
      _lastResult = null;
      _frameCount = 0;
    }
  }
  
  /// Сбрасывает состояние движка
  void reset() {
    _repCounter.reset();
    _analyzer.clearCache();
    _lastResult = null;
    _frameCount = 0;
    _fpsHistory.clear();
  }
  
  /// Основной метод анализа позы
  SmartExerciseResult analyzePose(Pose pose) {
    _frameCount++;
    final now = DateTime.now();
    
    // Адаптивная оптимизация FPS
    _updatePerformanceMetrics(now);
    
    // Проверяем, нужно ли пропустить анализ для экономии ресурсов
    if (_shouldSkipAnalysis()) {
      return _getOptimizedResult();
    }
    
    // Выполняем полный анализ
    final analysisResult = _analyzer.analyzeExercise(pose, _currentExercise);
    final repResult = _repCounter.analyzePose(pose);
    
    // Объединяем результаты
    final combinedResult = _combineResults(analysisResult, repResult, now);
    
    // Кэшируем результат
    _lastResult = combinedResult;
    _lastResultTime = now;
    _lastAnalysis = now;
    
    return combinedResult;
  }
  
  /// Обновляет метрики производительности
  void _updatePerformanceMetrics(DateTime now) {
    final timeDiff = now.difference(_lastAnalysis).inMilliseconds;
    if (timeDiff > 0) {
      final currentFps = 1000.0 / timeDiff;
      _fpsHistory.add(currentFps);
      
      if (_fpsHistory.length > _fpsHistorySize) {
        _fpsHistory.removeAt(0);
      }
      
      // Адаптивная настройка производительности
      _adaptPerformanceSettings();
    }
  }
  
  /// Адаптивная настройка параметров производительности
  void _adaptPerformanceSettings() {
    if (_fpsHistory.length < 3) return;
    
    final avgFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    
    if (avgFps < 5.0) {
      // Низкий FPS - переходим в режим экономии
      _isHighPerformanceMode = false;
      _analysisInterval = 3;
      _confidenceThreshold = 0.5;
    } else if (avgFps > 8.0) {
      // Высокий FPS - можем позволить себе больше
      _isHighPerformanceMode = true;
      _analysisInterval = 1;
      _confidenceThreshold = 0.7;
    } else {
      // Средний FPS - сбалансированный режим
      _isHighPerformanceMode = true;
      _analysisInterval = 2;
      _confidenceThreshold = 0.6;
    }
  }
  
  /// Определяет, нужно ли пропустить анализ
  bool _shouldSkipAnalysis() {
    // В режиме экономии пропускаем кадры
    if (!_isHighPerformanceMode && _frameCount % _analysisInterval != 0) {
      return true;
    }
    
    // Если последний результат свежий и уверенный, можем его переиспользовать
    if (_lastResult != null) {
      final timeSinceLastResult = DateTime.now().difference(_lastResultTime).inMilliseconds;
      if (timeSinceLastResult < 100 && _lastResult!.confidence > 0.8) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Возвращает оптимизированный результат без полного анализа
  SmartExerciseResult _getOptimizedResult() {
    if (_lastResult != null) {
      // Обновляем только счетчик времени для статических упражнений
      if (_isStaticExercise(_currentExercise)) {
        final updatedRepCount = _repCounter.staticTimeSeconds;
        return SmartExerciseResult(
          repCount: updatedRepCount,
          isValidPose: _lastResult!.isValidPose,
          confidence: _lastResult!.confidence * 0.9, // Немного снижаем уверенность
          feedback: _lastResult!.feedback,
          technicalScore: _lastResult!.technicalScore,
          movementPhase: _lastResult!.movementPhase,
          keyAngles: _lastResult!.keyAngles,
          isInDownPosition: _lastResult!.isInDownPosition,
          performanceMode: _isHighPerformanceMode ? 'high' : 'eco',
          avgFps: _getAverageFps(),
        );
      }
      
      // Для динамических упражнений возвращаем кэшированный результат
      return _lastResult!.copyWith(
        confidence: _lastResult!.confidence * 0.95,
        performanceMode: _isHighPerformanceMode ? 'high' : 'eco',
        avgFps: _getAverageFps(),
      );
    }
    
    // Fallback результат
    return SmartExerciseResult(
      repCount: _repCounter.repCount,
      isValidPose: false,
      confidence: 0.3,
      feedback: 'Анализ...',
      technicalScore: 0.5,
      movementPhase: MovementPhase.unknown,
      keyAngles: {},
      isInDownPosition: false,
      performanceMode: 'eco',
      avgFps: _getAverageFps(),
    );
  }
  
  /// Объединяет результаты анализатора и счетчика
  SmartExerciseResult _combineResults(
    ExerciseAnalysisResult analysisResult,
    RepCountResult repResult,
    DateTime timestamp,
  ) {
    // Определяем лучший источник обратной связи
    String feedback;
    if (analysisResult.confidence > repResult.confidence) {
      feedback = analysisResult.feedback;
    } else {
      feedback = repResult.feedback;
    }
    
    // Комбинируем уверенность
    final combinedConfidence = (analysisResult.confidence + repResult.confidence) / 2;
    
    // Для статических упражнений используем время из счетчика
    int finalRepCount;
    if (_isStaticExercise(_currentExercise)) {
      finalRepCount = _repCounter.staticTimeSeconds;
    } else {
      finalRepCount = repResult.repCount;
    }
    
    // Улучшенная обратная связь с учетом технической оценки
    final enhancedFeedback = _enhanceFeedback(
      feedback,
      analysisResult.technicalScore,
      combinedConfidence,
      analysisResult.movementPhase,
    );
    
    return SmartExerciseResult(
      repCount: finalRepCount,
      isValidPose: analysisResult.isValidPose,
      confidence: combinedConfidence,
      feedback: enhancedFeedback,
      technicalScore: analysisResult.technicalScore,
      movementPhase: analysisResult.movementPhase,
      keyAngles: analysisResult.keyAngles,
      isInDownPosition: repResult.isInDownPosition,
      performanceMode: _isHighPerformanceMode ? 'high' : 'eco',
      avgFps: _getAverageFps(),
    );
  }
  
  /// Улучшает обратную связь с учетом технических показателей
  String _enhanceFeedback(
    String baseFeedback,
    double technicalScore,
    double confidence,
    MovementPhase phase,
  ) {
    // Добавляем индикаторы качества
    String qualityIndicator = '';
    if (technicalScore > 0.9) {
      qualityIndicator = ' ⭐';
    } else if (technicalScore > 0.8) {
      qualityIndicator = ' 🔥';
    } else if (technicalScore > 0.7) {
      qualityIndicator = ' 💪';
    } else if (technicalScore < 0.5) {
      qualityIndicator = ' ⚠️';
    }
    
    // Добавляем индикатор режима производительности
    String performanceIndicator = '';
    if (_isHighPerformanceMode) {
      final fps = _getAverageFps();
      if (fps > 7) {
        performanceIndicator = ' 🚀';
      } else if (fps > 5) {
        performanceIndicator = ' ⚡';
      }
    } else {
      performanceIndicator = ' 🔋'; // Режим экономии
    }
    
    return baseFeedback + qualityIndicator + performanceIndicator;
  }
  
  /// Проверяет, является ли упражнение статическим
  bool _isStaticExercise(String exerciseType) {
    return exerciseType.toLowerCase().contains('plank') ||
           exerciseType.toLowerCase().contains('hold') ||
           exerciseType.toLowerCase().contains('static');
  }
  
  /// Возвращает средний FPS
  double _getAverageFps() {
    if (_fpsHistory.isEmpty) return 0.0;
    return _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
  }
  
  /// Получает детальную статистику производительности
  Map<String, dynamic> getPerformanceStats() {
    final analyzerStats = _analyzer.getPerformanceStats();
    
    return {
      'engine_fps': _getAverageFps(),
      'frame_count': _frameCount,
      'performance_mode': _isHighPerformanceMode ? 'high' : 'eco',
      'analysis_interval': _analysisInterval,
      'confidence_threshold': _confidenceThreshold,
      'analyzer_stats': analyzerStats,
      'rep_count': _repCounter.repCount,
      'static_time': _repCounter.staticTimeSeconds,
    };
  }
  
  /// Принудительно переключает режим производительности
  void setPerformanceMode(bool highPerformance) {
    _isHighPerformanceMode = highPerformance;
    if (highPerformance) {
      _analysisInterval = 1;
      _confidenceThreshold = 0.7;
    } else {
      _analysisInterval = 3;
      _confidenceThreshold = 0.5;
    }
  }
  
  /// Получает рекомендации по оптимизации
  List<String> getOptimizationRecommendations() {
    final recommendations = <String>[];
    final avgFps = _getAverageFps();
    
    if (avgFps < 4) {
      recommendations.add('Критически низкий FPS. Закройте другие приложения');
      recommendations.add('Уменьшите разрешение камеры');
      recommendations.add('Улучшите освещение для лучшего распознавания');
    } else if (avgFps < 6) {
      recommendations.add('Низкий FPS. Рекомендуется режим экономии');
      recommendations.add('Проверьте загрузку процессора');
    } else if (avgFps > 10) {
      recommendations.add('Отличная производительность!');
      recommendations.add('Можно включить дополнительные функции анализа');
    }
    
    if (_lastResult != null && _lastResult!.confidence < 0.5) {
      recommendations.add('Улучшите освещение для лучшего распознавания');
      recommendations.add('Встаньте так, чтобы было видно все тело');
    }
    
    return recommendations;
  }
  
  /// Очищает все кэши и сбрасывает статистику
  void clearAll() {
    reset();
    _fpsHistory.clear();
    _frameCount = 0;
  }
}

/// Результат работы умного движка упражнений
class SmartExerciseResult {
  final int repCount;
  final bool isValidPose;
  final double confidence;
  final String feedback;
  final double technicalScore;
  final MovementPhase movementPhase;
  final Map<String, double> keyAngles;
  final bool isInDownPosition;
  final String performanceMode;
  final double avgFps;
  
  const SmartExerciseResult({
    required this.repCount,
    required this.isValidPose,
    required this.confidence,
    required this.feedback,
    required this.technicalScore,
    required this.movementPhase,
    required this.keyAngles,
    required this.isInDownPosition,
    required this.performanceMode,
    required this.avgFps,
  });
  
  /// Создает копию с измененными параметрами
  SmartExerciseResult copyWith({
    int? repCount,
    bool? isValidPose,
    double? confidence,
    String? feedback,
    double? technicalScore,
    MovementPhase? movementPhase,
    Map<String, double>? keyAngles,
    bool? isInDownPosition,
    String? performanceMode,
    double? avgFps,
  }) {
    return SmartExerciseResult(
      repCount: repCount ?? this.repCount,
      isValidPose: isValidPose ?? this.isValidPose,
      confidence: confidence ?? this.confidence,
      feedback: feedback ?? this.feedback,
      technicalScore: technicalScore ?? this.technicalScore,
      movementPhase: movementPhase ?? this.movementPhase,
      keyAngles: keyAngles ?? this.keyAngles,
      isInDownPosition: isInDownPosition ?? this.isInDownPosition,
      performanceMode: performanceMode ?? this.performanceMode,
      avgFps: avgFps ?? this.avgFps,
    );
  }
  
  /// Преобразует в Map для отладки
  Map<String, dynamic> toMap() {
    return {
      'repCount': repCount,
      'isValidPose': isValidPose,
      'confidence': confidence,
      'feedback': feedback,
      'technicalScore': technicalScore,
      'movementPhase': movementPhase.toString(),
      'keyAngles': keyAngles,
      'isInDownPosition': isInDownPosition,
      'performanceMode': performanceMode,
      'avgFps': avgFps,
    };
  }
}