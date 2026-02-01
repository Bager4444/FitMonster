import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Оптимизированный счетчик повторений с фокусом на 10 ключевых точек
class OptimizedRepCounter {
  // Состояние для отслеживания повторений
  int _repCount = 0;
  bool _isInDownPosition = false;
  DateTime? _lastRepTime;
  
  // Настройки для предотвращения ложных срабатываний
  static const int _minTimeBetweenReps = 500; // мс
  static const double _minConfidence = 0.3; // понижена для лучшей работы
  
  // История для сглаживания
  final List<Map<String, double>> _keyPointsHistory = [];
  static const int _historySize = 3;
  
  // Текущий тип упражнения
  String _currentExerciseType = 'squats';
  
  int get repCount => _repCount;
  bool get isInDownPosition => _isInDownPosition;
  
  /// Устанавливает тип упражнения
  void setExerciseType(String exerciseId) {
    _currentExerciseType = exerciseId;
  }
  
  /// Сбрасывает счетчик
  void reset() {
    _repCount = 0;
    _isInDownPosition = false;
    _lastRepTime = null;
    _keyPointsHistory.clear();
  }
  
  /// Анализирует позу используя только ключевые точки
  OptimizedRepCountResult analyzePose(Pose pose) {
    // Получаем ключевые точки для текущего упражнения
    final keyPoints = _getKeyPointsForExercise(_currentExerciseType);
    
    // Проверяем защиту от слишком частого подсчета
    if (_lastRepTime != null && 
        DateTime.now().difference(_lastRepTime!).inMilliseconds < _minTimeBetweenReps) {
      return OptimizedRepCountResult(
        repCount: _repCount,
        isInDownPosition: _isInDownPosition,
        feedback: 'Подождите...',
        confidence: 0.0,
        keyPointsUsed: keyPoints,
        allPointsVisible: true,
      );
    }
    
    // Извлекаем координаты ключевых точек
    final keyPointData = _extractKeyPointData(pose, keyPoints);
    
    if (!keyPointData.isValid) {
      return OptimizedRepCountResult(
        repCount: _repCount,
        isInDownPosition: _isInDownPosition,
        feedback: keyPointData.feedback,
        confidence: 0.0,
        keyPointsUsed: keyPoints,
        allPointsVisible: true,
      );
    }
    
    // Добавляем в историю для сглаживания
    _keyPointsHistory.add(keyPointData.metrics);
    if (_keyPointsHistory.length > _historySize) {
      _keyPointsHistory.removeAt(0);
    }
    
    // Вычисляем сглаженные метрики
    final smoothedMetrics = _calculateSmoothedMetrics();
    
    // Анализируем упражнение на основе ключевых точек
    final analysis = _analyzeExercise(smoothedMetrics, _currentExerciseType);
    
    String feedback = 'Продолжайте!';
    
    // Подсчитываем повторение
    if (_isInDownPosition && analysis.isUpPosition) {
      _repCount++;
      _lastRepTime = DateTime.now();
      _isInDownPosition = false;
      feedback = 'Повторение $_repCount! 💪';
    } else if (analysis.isDownPosition && !_isInDownPosition) {
      _isInDownPosition = true;
      feedback = 'Отлично! Теперь вверх!';
    } else if (_isInDownPosition) {
      feedback = analysis.feedback;
    } else if (!analysis.isUpPosition && !analysis.isDownPosition) {
      feedback = analysis.feedback;
    }
    
    return OptimizedRepCountResult(
      repCount: _repCount,
      isInDownPosition: _isInDownPosition,
      feedback: feedback,
      confidence: keyPointData.confidence,
      keyPointsUsed: keyPoints,
      allPointsVisible: true,
      exerciseQuality: analysis.quality,
      formCorrection: analysis.formCorrection,
    );
  }
  
  /// Получает список ключевых точек для конкретного упражнения
  List<PoseLandmarkType> _getKeyPointsForExercise(String exerciseId) {
    switch (exerciseId) {
      // Приседания - фокус на ноги, таз, спина
      case 'squats':
      case 'jump_squats':
      case 'sumo_squats':
        return [
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.leftAnkle,
          PoseLandmarkType.rightAnkle,
          PoseLandmarkType.leftHeel,
          PoseLandmarkType.rightHeel,
        ];
      
      // Отжимания - фокус на руки, плечи, корпус
      case 'pushups':
      case 'knee_pushups':
        return [
          PoseLandmarkType.nose,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.leftWrist,
          PoseLandmarkType.rightWrist,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.leftKnee,
        ];
      
      // Выпады - фокус на ноги и баланс
      case 'lunges':
      case 'reverse_lunges':
      case 'lateral_lunges':
        return [
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.leftAnkle,
          PoseLandmarkType.rightAnkle,
          PoseLandmarkType.leftFootIndex,
          PoseLandmarkType.rightFootIndex,
        ];
      
      // Упражнения на пресс - фокус на корпус
      case 'crunches':
      case 'bicycle_crunches':
      case 'reverse_crunches':
      case 'russian_twists':
      case 'sit_ups':
        return [
          PoseLandmarkType.nose,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.leftAnkle,
        ];
      
      // Планка и статические упражнения
      case 'plank':
      case 'side_plank':
      case 'plank_leg_lifts':
        return [
          PoseLandmarkType.nose,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.leftAnkle,
        ];
      
      // Кардио упражнения - фокус на движение всего тела
      case 'jumping_jacks':
      case 'mountain_climbers':
      case 'high_knees':
      case 'burpees':
      case 'burpee_pushup':
      case 'running_in_place':
      case 'jump_in_place':
        return [
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.leftAnkle,
          PoseLandmarkType.rightAnkle,
        ];
      
      // Упражнения на ноги и ягодицы
      case 'leg_raises':
      case 'glute_bridge':
      case 'calf_raises':
      case 'superman':
        return [
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.leftAnkle,
          PoseLandmarkType.rightAnkle,
          PoseLandmarkType.leftHeel,
          PoseLandmarkType.rightHeel,
        ];
      
      // Упражнения на растяжку и баланс
      case 'downward_dog':
      case 'single_leg_deadlift':
        return [
          PoseLandmarkType.nose,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftWrist,
          PoseLandmarkType.rightWrist,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.leftAnkle,
        ];
      
      // Прыжки со скакалкой
      case 'jump_rope':
        return [
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.leftWrist,
          PoseLandmarkType.rightWrist,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.leftAnkle,
          PoseLandmarkType.rightAnkle,
        ];
      
      default:
        // Универсальный набор для неизвестных упражнений
        return [
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.leftAnkle,
          PoseLandmarkType.rightAnkle,
        ];
    }
  }
  
  /// Извлекает данные ключевых точек
  _KeyPointData _extractKeyPointData(Pose pose, List<PoseLandmarkType> keyPoints) {
    final Map<String, double> metrics = {};
    double totalConfidence = 0.0;
    int validPoints = 0;
    
    // Проверяем доступность ключевых точек
    for (final pointType in keyPoints) {
      final landmark = pose.landmarks[pointType];
      if (landmark != null && landmark.likelihood > _minConfidence) {
        validPoints++;
        totalConfidence += landmark.likelihood;
      }
    }
    
    if (validPoints < 4) { // Минимум 4 из 10 точек должны быть видны
      return _KeyPointData(
        metrics: {},
        confidence: 0.0,
        isValid: false,
        feedback: 'Встаньте полностью в кадр (видно $validPoints из ${keyPoints.length} точек)',
      );
    }
    
    final avgConfidence = totalConfidence / validPoints;
    
    // Вычисляем специфичные для упражнения метрики
    metrics.addAll(_calculateExerciseSpecificMetrics(pose, keyPoints, _currentExerciseType));
    
    return _KeyPointData(
      metrics: metrics,
      confidence: avgConfidence,
      isValid: true,
      feedback: 'OK',
    );
  }
  
  /// Вычисляет метрики специфичные для упражнения
  Map<String, double> _calculateExerciseSpecificMetrics(
    Pose pose, 
    List<PoseLandmarkType> keyPoints, 
    String exerciseType
  ) {
    final Map<String, double> metrics = {};
    
    switch (exerciseType) {
      case 'squats':
      case 'jump_squats':
      case 'sumo_squats':
        metrics.addAll(_calculateSquatMetrics(pose));
        break;
      case 'pushups':
      case 'knee_pushups':
        metrics.addAll(_calculatePushupMetrics(pose));
        break;
      case 'lunges':
      case 'reverse_lunges':
      case 'lateral_lunges':
        metrics.addAll(_calculateLungeMetrics(pose));
        break;
      default:
        metrics.addAll(_calculateGeneralMetrics(pose, keyPoints));
    }
    
    return metrics;
  }
  
  /// Метрики для приседаний
  Map<String, double> _calculateSquatMetrics(Pose pose) {
    final metrics = <String, double>{};
    
    // Угол в коленях
    final leftKneeAngle = _calculateAngleIfExists(
      pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    final rightKneeAngle = _calculateAngleIfExists(
      pose, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    
    if (leftKneeAngle != null && rightKneeAngle != null) {
      metrics['knee_angle'] = (leftKneeAngle + rightKneeAngle) / 2;
    }
    
    // Угол спины (вертикальность)
    final backAngle = _calculateAngleIfExists(
      pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    if (backAngle != null) {
      metrics['back_angle'] = backAngle;
    }
    
    // Симметрия (разница между левой и правой стороной)
    if (leftKneeAngle != null && rightKneeAngle != null) {
      metrics['symmetry'] = (leftKneeAngle - rightKneeAngle).abs();
    }
    
    return metrics;
  }
  
  /// Метрики для отжиманий
  Map<String, double> _calculatePushupMetrics(Pose pose) {
    final metrics = <String, double>{};
    
    // Угол в локтях
    final leftElbowAngle = _calculateAngleIfExists(
      pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    final rightElbowAngle = _calculateAngleIfExists(
      pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    
    if (leftElbowAngle != null && rightElbowAngle != null) {
      metrics['elbow_angle'] = (leftElbowAngle + rightElbowAngle) / 2;
    }
    
    // Прямота тела (планка)
    final bodyLine = _calculateAngleIfExists(
      pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    if (bodyLine != null) {
      metrics['body_line'] = bodyLine;
    }
    
    return metrics;
  }
  
  /// Метрики для выпадов
  Map<String, double> _calculateLungeMetrics(Pose pose) {
    final metrics = <String, double>{};
    
    // Угол переднего колена
    final frontKneeAngle = _calculateAngleIfExists(
      pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    if (frontKneeAngle != null) {
      metrics['front_knee_angle'] = frontKneeAngle;
    }
    
    // Вертикальность корпуса
    final torsoAngle = _calculateAngleIfExists(
      pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    if (torsoAngle != null) {
      metrics['torso_angle'] = torsoAngle;
    }
    
    return metrics;
  }
  
  /// Общие метрики
  Map<String, double> _calculateGeneralMetrics(Pose pose, List<PoseLandmarkType> keyPoints) {
    final metrics = <String, double>{};
    
    // Центр масс
    double sumX = 0, sumY = 0;
    int count = 0;
    
    for (final pointType in keyPoints) {
      final landmark = pose.landmarks[pointType];
      if (landmark != null) {
        sumX += landmark.x;
        sumY += landmark.y;
        count++;
      }
    }
    
    if (count > 0) {
      metrics['center_x'] = sumX / count;
      metrics['center_y'] = sumY / count;
    }
    
    return metrics;
  }
  
  /// Вычисляет угол если все точки существуют
  double? _calculateAngleIfExists(Pose pose, PoseLandmarkType p1, PoseLandmarkType p2, PoseLandmarkType p3) {
    final point1 = pose.landmarks[p1];
    final point2 = pose.landmarks[p2];
    final point3 = pose.landmarks[p3];
    
    if (point1 == null || point2 == null || point3 == null) return null;
    
    // Понижаем требования к уверенности для лучшей работы
    const minAngleConfidence = 0.2;
    if (point1.likelihood < minAngleConfidence || 
        point2.likelihood < minAngleConfidence || 
        point3.likelihood < minAngleConfidence) return null;
    
    return _calculateAngle(point1.x, point1.y, point2.x, point2.y, point3.x, point3.y);
  }
  
  /// Вычисляет угол между тремя точками
  double _calculateAngle(double x1, double y1, double x2, double y2, double x3, double y3) {
    final dx1 = x1 - x2;
    final dy1 = y1 - y2;
    final dx2 = x3 - x2;
    final dy2 = y3 - y2;
    
    final dot = dx1 * dx2 + dy1 * dy2;
    final mag1 = math.sqrt(dx1 * dx1 + dy1 * dy1);
    final mag2 = math.sqrt(dx2 * dx2 + dy2 * dy2);
    
    if (mag1 == 0 || mag2 == 0) return 0;
    
    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180 / math.pi;
  }
  
  /// Вычисляет сглаженные метрики
  Map<String, double> _calculateSmoothedMetrics() {
    if (_keyPointsHistory.isEmpty) return {};
    
    final smoothed = <String, double>{};
    final allKeys = _keyPointsHistory.expand((m) => m.keys).toSet();
    
    for (final key in allKeys) {
      final values = _keyPointsHistory
          .where((m) => m.containsKey(key))
          .map((m) => m[key]!)
          .toList();
      
      if (values.isNotEmpty) {
        smoothed[key] = values.reduce((a, b) => a + b) / values.length;
      }
    }
    
    return smoothed;
  }
  
  /// Анализирует упражнение на основе метрик
  _ExerciseAnalysis _analyzeExercise(Map<String, double> metrics, String exerciseType) {
    switch (exerciseType) {
      case 'squats':
      case 'jump_squats':
      case 'sumo_squats':
        return _analyzeSquats(metrics);
      case 'pushups':
      case 'knee_pushups':
        return _analyzePushups(metrics);
      default:
        return _analyzeGeneral(metrics);
    }
  }
  
  /// Анализ приседаний
  _ExerciseAnalysis _analyzeSquats(Map<String, double> metrics) {
    final kneeAngle = metrics['knee_angle'] ?? 180;
    final backAngle = metrics['back_angle'] ?? 180;
    final symmetry = metrics['symmetry'] ?? 0;
    
    final isDown = kneeAngle < 140;
    final isUp = kneeAngle > 160;
    
    String feedback = 'Продолжайте!';
    double quality = 1.0;
    List<String> corrections = [];
    
    // Отладочная информация
    if (metrics.isEmpty) {
      feedback = 'Встаньте в кадр полностью';
    } else if (!metrics.containsKey('knee_angle')) {
      feedback = 'Не видно коленей - встаньте ближе';
    } else {
      feedback = 'Угол колен: ${kneeAngle.toInt()}°';
    }
    
    if (isDown) {
      if (kneeAngle > 120) {
        feedback = 'Опускайтесь глубже! (${kneeAngle.toInt()}°)';
        quality *= 0.8;
        corrections.add('Опускайтесь до параллели бедер с полом');
      } else {
        feedback = 'Отлично! Теперь вверх! (${kneeAngle.toInt()}°)';
      }
      if (backAngle < 160) {
        quality *= 0.7;
        corrections.add('Держите спину прямее');
      }
      if (symmetry > 15) {
        quality *= 0.8;
        corrections.add('Распределите вес равномерно на обе ноги');
      }
    } else if (isUp) {
      feedback = 'Готов к следующему приседанию (${kneeAngle.toInt()}°)';
    }
    
    return _ExerciseAnalysis(
      isDownPosition: isDown,
      isUpPosition: isUp,
      feedback: feedback,
      quality: quality,
      formCorrection: corrections,
    );
  }
  
  /// Анализ отжиманий
  _ExerciseAnalysis _analyzePushups(Map<String, double> metrics) {
    final elbowAngle = metrics['elbow_angle'] ?? 180;
    final bodyLine = metrics['body_line'] ?? 180;
    
    final isDown = elbowAngle < 120;
    final isUp = elbowAngle > 160;
    
    String feedback = 'Продолжайте!';
    double quality = 1.0;
    List<String> corrections = [];
    
    if (bodyLine < 160 || bodyLine > 200) {
      quality *= 0.7;
      corrections.add('Держите тело прямо как планка');
    }
    
    if (isDown && elbowAngle > 100) {
      feedback = 'Опускайтесь ниже!';
      quality *= 0.8;
      corrections.add('Опускайтесь до касания грудью пола');
    }
    
    return _ExerciseAnalysis(
      isDownPosition: isDown,
      isUpPosition: isUp,
      feedback: feedback,
      quality: quality,
      formCorrection: corrections,
    );
  }
  
  /// Общий анализ
  _ExerciseAnalysis _analyzeGeneral(Map<String, double> metrics) {
    return _ExerciseAnalysis(
      isDownPosition: false,
      isUpPosition: true,
      feedback: 'Продолжайте!',
      quality: 1.0,
      formCorrection: [],
    );
  }
}

/// Данные ключевых точек
class _KeyPointData {
  final Map<String, double> metrics;
  final double confidence;
  final bool isValid;
  final String feedback;
  
  const _KeyPointData({
    required this.metrics,
    required this.confidence,
    required this.isValid,
    required this.feedback,
  });
}

/// Анализ упражнения
class _ExerciseAnalysis {
  final bool isDownPosition;
  final bool isUpPosition;
  final String feedback;
  final double quality;
  final List<String> formCorrection;
  
  const _ExerciseAnalysis({
    required this.isDownPosition,
    required this.isUpPosition,
    required this.feedback,
    required this.quality,
    required this.formCorrection,
  });
}

/// Результат оптимизированного подсчета повторений
class OptimizedRepCountResult {
  final int repCount;
  final bool isInDownPosition;
  final String feedback;
  final double confidence;
  final List<PoseLandmarkType> keyPointsUsed;
  final bool allPointsVisible;
  final double? exerciseQuality;
  final List<String>? formCorrection;
  
  const OptimizedRepCountResult({
    required this.repCount,
    required this.isInDownPosition,
    required this.feedback,
    required this.confidence,
    required this.keyPointsUsed,
    required this.allPointsVisible,
    this.exerciseQuality,
    this.formCorrection,
  });
}