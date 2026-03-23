import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Максимально оптимизированный счетчик с поддержкой времени для статических упражнений
class ImprovedRepCounter {
  // Состояние для отслеживания повторений
  int _repCount = 0;
  bool _isInDownPosition = false;
  DateTime? _lastRepTime;
  
  // Для статических упражнений - отслеживание времени
  DateTime? _staticStartTime;
  int _totalStaticSeconds = 0;
  bool _isInCorrectStaticPosition = false;
  
  // Оптимизированные настройки для FPS
  static const int _minTimeBetweenReps = 400;
  static const double _minConfidence = 0.35;
  static const int _skipFrames = 1; // Анализируем каждый кадр для быстрой реакции
  
  // Кэш для вычислений
  final Map<String, double> _angleCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const int _cacheValidityMs = 100;
  
  // Умная история
  final Map<String, List<double>> _smartHistory = {};
  static const int _historySize = 5;
  
  // Счетчик кадров
  int _frameCounter = 0;
  
  // Текущий тип упражнения
  String _currentExerciseType = 'squats';
  
  // Оптимизированные конфигурации
  final Map<String, OptimizedExerciseConfig> _configs = {
    'squats': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 130,
      primaryUpAngle: 170,
      criticalPoints: [
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
      ],
      minMovementAmplitude: 0.12,
      confidenceBoost: 1.2,
      exerciseType: ExerciseType.dynamic,
    ),
    
    'pushups': OptimizedExerciseConfig(
      primaryJoint: JointType.elbow,
      primaryDownAngle: 100,
      primaryUpAngle: 170,
      criticalPoints: [
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
      ],
      minMovementAmplitude: 0.10,
      confidenceBoost: 1.1,
      exerciseType: ExerciseType.dynamic,
    ),
    
    'lunges': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 120,
      primaryUpAngle: 165,
      criticalPoints: [
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
      ],
      minMovementAmplitude: 0.15,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    
    'jumping_jacks': OptimizedExerciseConfig(
      primaryJoint: JointType.shoulder,
      primaryDownAngle: 18,  // руки внизу (низкий spread)
      primaryUpAngle: 55,    // руки вверху/в стороны (высокий spread)
      criticalPoints: [
        PoseLandmarkType.leftWrist,
        PoseLandmarkType.rightWrist,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
      ],
      minMovementAmplitude: 0.18,
      confidenceBoost: 0.9,
      exerciseType: ExerciseType.dynamic,
    ),
    
    // Статические упражнения - считаем время (плечи, бёдра, локти, колени — линия тела)
    'plank': OptimizedExerciseConfig(
      primaryJoint: JointType.elbow,
      primaryDownAngle: 150, // Допускаем слегка согнутые руки
      primaryUpAngle: 180,
      criticalPoints: [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.rightKnee,
      ],
      minMovementAmplitude: 0.02, // Минимальное движение для статики
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.static,
    ),
    
    'side_plank': OptimizedExerciseConfig(
      primaryJoint: JointType.elbow,
      primaryDownAngle: 160,
      primaryUpAngle: 180,
      criticalPoints: [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.rightKnee,
      ],
      minMovementAmplitude: 0.02,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.static,
    ),
    // Остальные упражнения — конфиги для подсчёта
    'leg_raises': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 100,
      primaryUpAngle: 165,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.12,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'crunches': OptimizedExerciseConfig(
      primaryJoint: JointType.hip,
      primaryDownAngle: 45,
      primaryUpAngle: 110,
      criticalPoints: [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.10,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'burpees': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 125,
      primaryUpAngle: 170,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.14,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'jump_rope': OptimizedExerciseConfig(
      primaryJoint: JointType.shoulder,
      primaryDownAngle: 18,
      primaryUpAngle: 55,
      criticalPoints: [PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      minMovementAmplitude: 0.18,
      confidenceBoost: 0.9,
      exerciseType: ExerciseType.dynamic,
    ),
    'downward_dog': OptimizedExerciseConfig(
      primaryJoint: JointType.elbow,
      primaryDownAngle: 155,
      primaryUpAngle: 180,
      criticalPoints: [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.02,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.static,
    ),
    'running_in_place': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 100,
      primaryUpAngle: 165,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.14,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'mountain_climbers': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 85,
      primaryUpAngle: 160,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.14,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'high_knees': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 110,
      primaryUpAngle: 165,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.14,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'jump_squats': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 125,
      primaryUpAngle: 170,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.12,
      confidenceBoost: 1.2,
      exerciseType: ExerciseType.dynamic,
    ),
    'reverse_lunges': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 115,
      primaryUpAngle: 165,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.15,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'knee_pushups': OptimizedExerciseConfig(
      primaryJoint: JointType.elbow,
      primaryDownAngle: 95,
      primaryUpAngle: 170,
      criticalPoints: [PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      minMovementAmplitude: 0.10,
      confidenceBoost: 1.1,
      exerciseType: ExerciseType.dynamic,
    ),
    'calf_raises': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 165,
      primaryUpAngle: 180,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle],
      minMovementAmplitude: 0.06,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'superman': OptimizedExerciseConfig(
      primaryJoint: JointType.hip,
      primaryDownAngle: 160,
      primaryUpAngle: 180,
      criticalPoints: [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.02,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.static,
    ),
    'glute_bridge': OptimizedExerciseConfig(
      primaryJoint: JointType.hip,
      primaryDownAngle: 115,
      primaryUpAngle: 170,
      criticalPoints: [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.12,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'bicycle_crunches': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 85,
      primaryUpAngle: 150,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.12,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'sumo_squats': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 120,
      primaryUpAngle: 170,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.12,
      confidenceBoost: 1.2,
      exerciseType: ExerciseType.dynamic,
    ),
    'plank_leg_lifts': OptimizedExerciseConfig(
      primaryJoint: JointType.elbow,
      primaryDownAngle: 158,
      primaryUpAngle: 180,
      criticalPoints: [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.02,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.static,
    ),
    'reverse_crunches': OptimizedExerciseConfig(
      primaryJoint: JointType.hip,
      primaryDownAngle: 55,
      primaryUpAngle: 120,
      criticalPoints: [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.10,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'burpee_pushup': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 125,
      primaryUpAngle: 170,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.14,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'lateral_lunges': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 115,
      primaryUpAngle: 165,
      criticalPoints: [PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.15,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'russian_twists': OptimizedExerciseConfig(
      primaryJoint: JointType.knee,
      primaryDownAngle: 100,
      primaryUpAngle: 160,
      criticalPoints: [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.10,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'single_leg_deadlift': OptimizedExerciseConfig(
      primaryJoint: JointType.hip,
      primaryDownAngle: 95,
      primaryUpAngle: 170,
      criticalPoints: [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.12,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
    'jump_in_place': OptimizedExerciseConfig(
      primaryJoint: JointType.shoulder,
      primaryDownAngle: 18,
      primaryUpAngle: 55,
      criticalPoints: [PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      minMovementAmplitude: 0.18,
      confidenceBoost: 0.9,
      exerciseType: ExerciseType.dynamic,
    ),
    'sit_ups': OptimizedExerciseConfig(
      primaryJoint: JointType.hip,
      primaryDownAngle: 45,
      primaryUpAngle: 115,
      criticalPoints: [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      minMovementAmplitude: 0.12,
      confidenceBoost: 1.0,
      exerciseType: ExerciseType.dynamic,
    ),
  };
  
  int get repCount => _repCount;
  bool get isInDownPosition => _isInDownPosition;
  
  /// Для статических упражнений возвращает время в секундах
  int get staticTimeSeconds => _totalStaticSeconds;
  
  /// Устанавливает тип упражнения
  void setExerciseType(String exerciseId) {
    if (_currentExerciseType != exerciseId) {
      _currentExerciseType = exerciseId;
      _clearCaches();
      _resetStaticTimer();
    }
  }
  
  /// Сбрасывает счетчик
  void reset() {
    _repCount = 0;
    _isInDownPosition = false;
    _lastRepTime = null;
    _clearCaches();
    _frameCounter = 0;
    _resetStaticTimer();
  }
  
  /// Сбрасывает таймер статических упражнений
  void _resetStaticTimer() {
    _staticStartTime = null;
    _totalStaticSeconds = 0;
    _isInCorrectStaticPosition = false;
  }
  
  /// Очищает кэши
  void _clearCaches() {
    _angleCache.clear();
    _cacheTimestamps.clear();
    _smartHistory.clear();
  }
  /// Основной метод анализа с оптимизацией FPS
  RepCountResult analyzePose(Pose pose) {
    _frameCounter++;
    
    // Пропускаем кадры для экономии FPS
    if (_frameCounter % _skipFrames != 0) {
      // Для статических упражнений обновляем время даже при пропуске кадров
      final config = _configs[_currentExerciseType];
      if (config?.exerciseType == ExerciseType.static && _isInCorrectStaticPosition) {
        _updateStaticTime();
      }
      
      return RepCountResult(
        repCount: config?.exerciseType == ExerciseType.static ? _totalStaticSeconds : _repCount,
        isInDownPosition: _isInDownPosition,
        feedback: 'Анализ...',
        confidence: 0.5,
      );
    }
    
    // Получаем конфигурацию
    final config = _configs[_currentExerciseType];
    if (config == null) {
      return _quickFallbackAnalysis(pose);
    }
    
    // Проверяем защиту от частого подсчета (только для динамических)
    if (config.exerciseType == ExerciseType.dynamic && 
        _lastRepTime != null && 
        DateTime.now().difference(_lastRepTime!).inMilliseconds < _minTimeBetweenReps) {
      return RepCountResult(
        repCount: _repCount,
        isInDownPosition: _isInDownPosition,
        feedback: 'Пауза между повторениями...',
        confidence: 0.3,
      );
    }
    
    // Быстрая проверка критических точек
    final criticalResult = _quickCriticalPointsCheck(pose, config);
    if (!criticalResult.isValid) {
      // Для статических упражнений останавливаем таймер при плохой позе
      if (config.exerciseType == ExerciseType.static) {
        _isInCorrectStaticPosition = false;
        _staticStartTime = null;
      }
      
      return RepCountResult(
        repCount: config.exerciseType == ExerciseType.static ? _totalStaticSeconds : _repCount,
        isInDownPosition: _isInDownPosition,
        feedback: criticalResult.feedback,
        confidence: 0.0,
      );
    }
    
    // Угол зависит от типа упражнения (приседания — без изменений, остальные — своя логика)
    double? primaryAngle = _getPrimaryAngleForExercise(pose, config);
    // Для статики: если угол не посчитался, но человек в кадре — считаем позу правильной и идём в таймер
    if (primaryAngle == null && config.exerciseType == ExerciseType.static &&
        criticalResult.isValid && criticalResult.confidence > 0.35) {
      primaryAngle = (config.primaryDownAngle + config.primaryUpAngle) / 2;
    }
    if (primaryAngle == null) {
      if (config.exerciseType == ExerciseType.static) {
        _isInCorrectStaticPosition = false;
        _staticStartTime = null;
      }
      
      return RepCountResult(
        repCount: config.exerciseType == ExerciseType.static ? _totalStaticSeconds : _repCount,
        isInDownPosition: _isInDownPosition,
        feedback: 'Встаньте в кадр полностью',
        confidence: 0.0,
      );
    }
    
    // Умное сглаживание
    final smoothedAngle = _addToSmartHistory('primary', primaryAngle);
    
    // Проверка движения
    final movementScore = _quickMovementCheck(pose, config);
    
    // Общая уверенность с бонусами
    final boostedConfidence = (criticalResult.confidence * config.confidenceBoost).clamp(0.0, 1.0);
    
    if (boostedConfidence < 0.45) {
      if (config.exerciseType == ExerciseType.static) {
        _isInCorrectStaticPosition = false;
        _staticStartTime = null;
      }
      
      return RepCountResult(
        repCount: config.exerciseType == ExerciseType.static ? _totalStaticSeconds : _repCount,
        isInDownPosition: _isInDownPosition,
        feedback: 'Улучшите позицию',
        confidence: boostedConfidence,
      );
    }
    
    // Разная логика для статических и динамических упражнений
    if (config.exerciseType == ExerciseType.static) {
      return _analyzeStaticExercise(config, smoothedAngle, boostedConfidence, movementScore);
    } else {
      return _analyzeDynamicExercise(config, smoothedAngle, boostedConfidence, movementScore);
    }
  }
  
  /// Обновляет время статического упражнения
  void _updateStaticTime() {
    if (_staticStartTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_staticStartTime!).inSeconds;
      if (elapsed > _totalStaticSeconds) {
        _totalStaticSeconds = elapsed;
      }
    }
  }
  
  /// Анализ статических упражнений (планка) - считаем время
  RepCountResult _analyzeStaticExercise(OptimizedExerciseConfig config, double smoothedAngle, 
                                       double confidence, double movementScore) {
    // Для статики учитываем только угол: движение из камеры/дрожи даёт движение=2.0 и ломало подсчёт
    final isCorrectPosition = smoothedAngle >= config.primaryDownAngle && 
                             smoothedAngle <= config.primaryUpAngle;
    
    String feedback;
    
    if (isCorrectPosition) {
      // Правильная поза - запускаем/продолжаем таймер
      if (!_isInCorrectStaticPosition) {
        _isInCorrectStaticPosition = true;
        _staticStartTime = DateTime.now();
      } else {
        // Обновляем время
        _updateStaticTime();
      }
      
      feedback = 'Отлично! Держите позу! ${_totalStaticSeconds}с 💪';
    } else {
      // Неправильная поза - останавливаем таймер
      _isInCorrectStaticPosition = false;
      _staticStartTime = null;
      
      if (smoothedAngle < config.primaryDownAngle) {
        feedback = _getStaticPositionFeedback(config.primaryJoint, 'low');
      } else if (smoothedAngle > config.primaryUpAngle) {
        feedback = _getStaticPositionFeedback(config.primaryJoint, 'high');
      } else {
        feedback = 'Примите правильную позу';
      }
    }
    
    return RepCountResult(
      repCount: _totalStaticSeconds, // Возвращаем время в секундах
      isInDownPosition: _isInCorrectStaticPosition,
      feedback: feedback,
      confidence: confidence,
      currentAngle: smoothedAngle,
    );
  }
  
  /// Анализ динамических упражнений (приседания, отжимания и т.д.)
  RepCountResult _analyzeDynamicExercise(OptimizedExerciseConfig config, double smoothedAngle, 
                                        double confidence, double movementScore) {
    // Определение позиции с мягкими порогами
    final isDown = smoothedAngle < config.primaryDownAngle && movementScore > 0.4;
    final isUp = smoothedAngle > config.primaryUpAngle && movementScore > 0.4;
    
    String feedback = 'Продолжайте!';
    
    // Умный подсчет повторений
    if (_isInDownPosition && isUp && movementScore > 0.6) {
      _repCount++;
      _lastRepTime = DateTime.now();
      _isInDownPosition = false;
      feedback = _getMotivationalFeedback(_repCount);
    } else if (isDown && !_isInDownPosition && movementScore > 0.5) {
      _isInDownPosition = true;
      feedback = 'Отлично! Теперь вверх! 💪';
    } else if (_isInDownPosition && !isUp) {
      feedback = _getPositionalFeedback(config.primaryJoint, true);
    } else if (!isDown && !_isInDownPosition) {
      feedback = _getPositionalFeedback(config.primaryJoint, false);
    } else if (movementScore < 0.4) {
      feedback = 'Выполняйте упражнение активнее!';
    }
    
    return RepCountResult(
      repCount: _repCount,
      isInDownPosition: _isInDownPosition,
      feedback: feedback,
      confidence: confidence,
      currentAngle: smoothedAngle,
    );
  }
  /// Обратная связь для статических упражнений
  String _getStaticPositionFeedback(JointType joint, String position) {
    switch (joint) {
      case JointType.elbow:
        if (position == 'low') {
          return 'Поднимите корпус выше! 🔺';
        } else {
          return 'Опустите корпус ниже! 🔻';
        }
      case JointType.knee:
        if (position == 'low') {
          return 'Выпрямите ноги! 🔺';
        } else {
          return 'Согните ноги больше! 🔻';
        }
      case JointType.shoulder:
        return 'Держите плечи ровно! 💪';
      case JointType.hip:
        return 'Держите корпус ровно! 💪';
    }
  }
  
  /// Быстрая проверка критических точек
  CriticalPointsResult _quickCriticalPointsCheck(Pose pose, OptimizedExerciseConfig config) {
    double totalConfidence = 0;
    int validPoints = 0;
    
    for (final pointType in config.criticalPoints) {
      final point = pose.landmarks[pointType];
      if (point != null && point.likelihood > _minConfidence) {
        totalConfidence += point.likelihood;
        validPoints++;
      }
    }
    
    // Для статики (планка и т.д.) допускаем 50% точек — при виде спереди не всё видно
    final minPointsRatio = config.exerciseType == ExerciseType.static ? 0.5 : 0.6;
    if (validPoints < config.criticalPoints.length * minPointsRatio) {
      return CriticalPointsResult(
        isValid: false,
        confidence: 0,
        feedback: 'Встаньте так, чтобы было видно все тело',
      );
    }
    
    final avgConfidence = totalConfidence / validPoints;
    return CriticalPointsResult(
      isValid: true,
      confidence: avgConfidence,
      feedback: 'OK',
    );
  }
  
  /// Кэшированный расчет угла
  double? _getCachedAngle(Pose pose, JointType jointType, String cacheKey) {
    final now = DateTime.now();
    
    // Проверяем кэш
    if (_angleCache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (now.difference(cacheTime).inMilliseconds < _cacheValidityMs) {
        return _angleCache[cacheKey];
      }
    }
    
    // Вычисляем новое значение
    final angleResult = _calculateOptimizedAngle(pose, jointType);
    if (angleResult.isValid) {
      _angleCache[cacheKey] = angleResult.angle;
      _cacheTimestamps[cacheKey] = now;
      return angleResult.angle;
    }
    
    return null;
  }

  /// Угол для подсчёта: приседания — как раньше, остальные упражнения — своя логика
  double? _getPrimaryAngleForExercise(Pose pose, OptimizedExerciseConfig config) {
    final result = _getPrimaryAngleResultForExercise(pose, config);
    if (result == null || !result.isValid) return null;
    return _addToSmartHistory('primary', result.angle);
  }

  _AngleResult? _getPrimaryAngleResultForExercise(Pose pose, OptimizedExerciseConfig config) {
    switch (_currentExerciseType) {
      case 'pushups':
      case 'knee_pushups':
        return _fastElbowAngleBoth(pose);
      case 'lunges':
      case 'reverse_lunges':
      case 'lateral_lunges':
      case 'mountain_climbers':
      case 'bicycle_crunches':
        return _fastKneeAngleMin(pose);
      case 'jumping_jacks':
      case 'jump_rope':
      case 'jump_in_place':
        return _fastJumpingJackSpread(pose);
      case 'plank':
      case 'side_plank':
        return config.primaryJoint == JointType.elbow ? _fastElbowAngleBoth(pose) : _calculateOptimizedAngle(pose, config.primaryJoint);
      case 'downward_dog':
      case 'superman':
      case 'plank_leg_lifts':
        return _calculateOptimizedAngle(pose, config.primaryJoint);
      case 'squats':
      case 'jump_squats':
      case 'sumo_squats':
      case 'leg_raises':
      case 'burpees':
      case 'running_in_place':
      case 'high_knees':
      case 'calf_raises':
      case 'burpee_pushup':
      case 'russian_twists':
      case 'crunches':
      case 'glute_bridge':
      case 'reverse_crunches':
      case 'single_leg_deadlift':
      case 'sit_ups':
      default:
        return _calculateOptimizedAngle(pose, config.primaryJoint);
    }
  }
  
  /// Оптимизированный расчет угла
  _AngleResult _calculateOptimizedAngle(Pose pose, JointType jointType) {
    switch (jointType) {
      case JointType.knee:
        return _fastKneeAngle(pose);
      case JointType.elbow:
        return _fastElbowAngle(pose);
      case JointType.shoulder:
        return _fastShoulderAngle(pose);
      case JointType.hip:
        return _fastHipAngle(pose);
    }
  }

  /// Угол в тазобедренном суставе (плечо–таз–колено) — для скручиваний, подъёмов корпуса, мостика
  _AngleResult _fastHipAngle(Pose pose) {
    final leftS = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftH = pose.landmarks[PoseLandmarkType.leftHip];
    final leftK = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightS = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightH = pose.landmarks[PoseLandmarkType.rightHip];
    final rightK = pose.landmarks[PoseLandmarkType.rightKnee];
    double? leftAngle;
    double? rightAngle;
    double leftConf = 0, rightConf = 0;
    if (leftS != null && leftH != null && leftK != null) {
      leftAngle = _quickAngle(leftS, leftH, leftK);
      leftConf = (leftS.likelihood + leftH.likelihood + leftK.likelihood) / 3;
    }
    if (rightS != null && rightH != null && rightK != null) {
      rightAngle = _quickAngle(rightS, rightH, rightK);
      rightConf = (rightS.likelihood + rightH.likelihood + rightK.likelihood) / 3;
    }
    if (leftAngle != null && rightAngle != null && (leftConf > _minConfidence || rightConf > _minConfidence)) {
      final avgAngle = (leftAngle * leftConf + rightAngle * rightConf) / (leftConf + rightConf);
      return _AngleResult(angle: avgAngle, confidence: (leftConf + rightConf) / 2, isValid: true, feedback: 'OK');
    }
    if (leftAngle != null && leftConf > _minConfidence) {
      return _AngleResult(angle: leftAngle!, confidence: leftConf, isValid: true, feedback: 'OK');
    }
    if (rightAngle != null && rightConf > _minConfidence) {
      return _AngleResult(angle: rightAngle!, confidence: rightConf, isValid: true, feedback: 'OK');
    }
    return _AngleResult(angle: 0, confidence: 0, isValid: false, feedback: 'Корпус не виден');
  }
  
  /// Быстрый расчет угла в колене
  _AngleResult _fastKneeAngle(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (leftHip != null && leftKnee != null && leftAnkle != null) {
      final leftAngle = _quickAngle(leftHip, leftKnee, leftAnkle);
      final leftConf = (leftHip.likelihood + leftKnee.likelihood + leftAnkle.likelihood) / 3;
      
      if (rightHip != null && rightKnee != null && rightAnkle != null) {
        final rightAngle = _quickAngle(rightHip, rightKnee, rightAnkle);
        final rightConf = (rightHip.likelihood + rightKnee.likelihood + rightAnkle.likelihood) / 3;
        
        final totalConf = leftConf + rightConf;
        final avgAngle = (leftAngle * leftConf + rightAngle * rightConf) / totalConf;
        
        return _AngleResult(
          angle: avgAngle,
          confidence: totalConf / 2,
          isValid: true,
          feedback: 'OK',
        );
      } else {
        return _AngleResult(
          angle: leftAngle,
          confidence: leftConf,
          isValid: leftConf > _minConfidence,
          feedback: leftConf > _minConfidence ? 'OK' : 'Плохая видимость',
        );
      }
    }
    
    return _AngleResult(angle: 0, confidence: 0, isValid: false, feedback: 'Ноги не видны');
  }
  
  /// Быстрый расчет угла в локте (одна рука)
  _AngleResult _fastElbowAngle(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    
    if (leftShoulder != null && leftElbow != null && leftWrist != null) {
      final angle = _quickAngle(leftShoulder, leftElbow, leftWrist);
      final conf = (leftShoulder.likelihood + leftElbow.likelihood + leftWrist.likelihood) / 3;
      
      return _AngleResult(
        angle: angle,
        confidence: conf,
        isValid: conf > _minConfidence,
        feedback: conf > _minConfidence ? 'OK' : 'Руки не видны',
      );
    }
    
    return _AngleResult(angle: 0, confidence: 0, isValid: false, feedback: 'Руки не видны');
  }

  /// Оба локтя (среднее) — для отжиманий
  _AngleResult _fastElbowAngleBoth(Pose pose) {
    final left = _fastElbowAngle(pose);
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    if (rightShoulder == null || rightElbow == null || rightWrist == null) return left;
    final rightAngle = _quickAngle(rightShoulder, rightElbow, rightWrist);
    final rightConf = (rightShoulder.likelihood + rightElbow.likelihood + rightWrist.likelihood) / 3;
    final avgAngle = (left.angle * left.confidence + rightAngle * rightConf) / (left.confidence + rightConf);
    return _AngleResult(
      angle: avgAngle,
      confidence: (left.confidence + rightConf) / 2,
      isValid: left.isValid || rightConf > _minConfidence,
      feedback: 'OK',
    );
  }

  /// Минимум из двух колен (согнутая нога в выпаде) — для выпадов
  _AngleResult _fastKneeAngleMin(Pose pose) {
    final leftRes = pose.landmarks[PoseLandmarkType.leftHip];
    final leftK = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftA = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightH = pose.landmarks[PoseLandmarkType.rightHip];
    final rightK = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightA = pose.landmarks[PoseLandmarkType.rightAnkle];
    double? leftAngle;
    double? rightAngle;
    double leftConf = 0, rightConf = 0;
    if (leftRes != null && leftK != null && leftA != null) {
      leftAngle = _quickAngle(leftRes, leftK, leftA);
      leftConf = (leftRes.likelihood + leftK.likelihood + leftA.likelihood) / 3;
    }
    if (rightH != null && rightK != null && rightA != null) {
      rightAngle = _quickAngle(rightH, rightK, rightA);
      rightConf = (rightH.likelihood + rightK.likelihood + rightA.likelihood) / 3;
    }
    if (leftAngle != null && rightAngle != null && (leftConf > _minConfidence || rightConf > _minConfidence)) {
      final minAngle = math.min(leftAngle, rightAngle);
      return _AngleResult(
        angle: minAngle,
        confidence: (leftConf + rightConf) / 2,
        isValid: true,
        feedback: 'OK',
      );
    }
    if (leftAngle != null && leftConf > _minConfidence) {
      return _AngleResult(angle: leftAngle!, confidence: leftConf, isValid: true, feedback: 'OK');
    }
    if (rightAngle != null && rightConf > _minConfidence) {
      return _AngleResult(angle: rightAngle!, confidence: rightConf, isValid: true, feedback: 'OK');
    }
    return _AngleResult(angle: 0, confidence: 0, isValid: false, feedback: 'Ноги не видны');
  }

  /// Разведение рук (расстояние между запястьями + высота) — для прыжков «ножницы»
  _AngleResult _fastJumpingJackSpread(Pose pose) {
    final leftW = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightW = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftS = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightS = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (leftW == null || rightW == null || leftS == null || rightS == null) {
      return _AngleResult(angle: 0, confidence: 0, isValid: false, feedback: 'Руки не видны');
    }
    final horiz = math.sqrt(math.pow(leftW.x - rightW.x, 2) + math.pow(leftW.y - rightW.y, 2));
    final avgY = (leftW.y + rightW.y) / 2;
    final avgSy = (leftS.y + rightS.y) / 2;
    final vertSpread = (avgSy - avgY).abs();
    final spread = (horiz * 80 + vertSpread * 50).clamp(0.0, 100.0);
    final conf = (leftW.likelihood + rightW.likelihood + leftS.likelihood + rightS.likelihood) / 4;
    return _AngleResult(
      angle: spread,
      confidence: conf,
      isValid: conf > _minConfidence,
      feedback: 'OK',
    );
  }
  
  /// Быстрый расчет угла в плече
  _AngleResult _fastShoulderAngle(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    if (leftWrist != null && rightWrist != null && leftShoulder != null && rightShoulder != null) {
      final wristDistance = math.sqrt(
        math.pow(leftWrist.x - rightWrist.x, 2) + math.pow(leftWrist.y - rightWrist.y, 2)
      );
      
      final pseudoAngle = wristDistance * 100;
      final conf = (leftWrist.likelihood + rightWrist.likelihood + 
                   leftShoulder.likelihood + rightShoulder.likelihood) / 4;
      
      return _AngleResult(
        angle: pseudoAngle,
        confidence: conf,
        isValid: conf > _minConfidence,
        feedback: 'OK',
      );
    }
    
    return _AngleResult(angle: 0, confidence: 0, isValid: false, feedback: 'Руки не видны');
  }
  /// Быстрый расчет угла между тремя точками
  double _quickAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    final dx1 = p1.x - p2.x;
    final dy1 = p1.y - p2.y;
    final dx2 = p3.x - p2.x;
    final dy2 = p3.y - p2.y;
    
    final dot = dx1 * dx2 + dy1 * dy2;
    final mag1 = math.sqrt(dx1 * dx1 + dy1 * dy1);
    final mag2 = math.sqrt(dx2 * dx2 + dy2 * dy2);
    
    if (mag1 == 0 || mag2 == 0) return 0;
    
    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final angle = math.acos(cosAngle) * 180 / math.pi;
    
    return angle.isNaN ? 0 : angle;
  }
  
  /// Умное сглаживание
  double _addToSmartHistory(String key, double value) {
    if (!_smartHistory.containsKey(key)) {
      _smartHistory[key] = [];
    }
    
    _smartHistory[key]!.add(value);
    if (_smartHistory[key]!.length > _historySize) {
      _smartHistory[key]!.removeAt(0);
    }
    
    final history = _smartHistory[key]!;
    if (history.isEmpty) return value;
    
    double weightedSum = 0;
    double totalWeight = 0;
    
    for (int i = 0; i < history.length; i++) {
      final weight = (i + 1).toDouble();
      weightedSum += history[i] * weight;
      totalWeight += weight;
    }
    
    return weightedSum / totalWeight;
  }
  
  /// Быстрая проверка движения
  double _quickMovementCheck(Pose pose, OptimizedExerciseConfig config) {
    double totalMovement = 0;
    int validPoints = 0;
    
    for (final pointType in config.criticalPoints) {
      final point = pose.landmarks[pointType];
      if (point != null) {
        final historyKey = 'movement_${pointType.name}';
        final currentY = point.y;
        
        if (!_smartHistory.containsKey(historyKey)) {
          _smartHistory[historyKey] = [currentY];
        } else {
          _smartHistory[historyKey]!.add(currentY);
          if (_smartHistory[historyKey]!.length > 3) {
            _smartHistory[historyKey]!.removeAt(0);
          }
          
          final history = _smartHistory[historyKey]!;
          if (history.length >= 2) {
            final range = history.reduce(math.max) - history.reduce(math.min);
            totalMovement += range;
            validPoints++;
          }
        }
      }
    }
    
    if (validPoints == 0) return 0;
    
    final avgMovement = totalMovement / validPoints;
    return (avgMovement / config.minMovementAmplitude).clamp(0.0, 2.0);
  }
  
  /// Мотивационная обратная связь
  String _getMotivationalFeedback(int repCount) {
    final messages = [
      'Отлично! Повторение $repCount! 🔥',
      'Супер! $repCount выполнено! 💪',
      'Великолепно! $repCount! Продолжайте! ⚡',
      'Потрясающе! $repCount повторение! 🚀',
      'Браво! $repCount! Вы молодец! ⭐',
    ];
    return messages[repCount % messages.length];
  }
  
  /// Позиционная обратная связь
  String _getPositionalFeedback(JointType joint, bool isInDown) {
    switch (joint) {
      case JointType.knee:
        return isInDown ? 'Поднимайтесь! 🔺' : 'Приседайте глубже! 🔻';
      case JointType.elbow:
        return isInDown ? 'Отжимайтесь вверх! 🔺' : 'Опускайтесь ниже! 🔻';
      case JointType.shoulder:
        return isInDown ? 'Поднимайте руки! 🙌' : 'Разводите руки шире! 👐';
      case JointType.hip:
        return isInDown ? 'Поднимайтесь! 🔺' : 'Опускайтесь ниже! 🔻';
    }
  }
  
  /// Быстрый fallback анализ
  RepCountResult _quickFallbackAnalysis(Pose pose) {
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    
    if (leftKnee == null || rightKnee == null) {
      return RepCountResult(
        repCount: _repCount,
        isInDownPosition: _isInDownPosition,
        feedback: 'Встаньте в кадр',
        confidence: 0.0,
      );
    }
    
    final avgY = (leftKnee.y + rightKnee.y) / 2;
    final smoothedY = _addToSmartHistory('fallback', avgY);
    
    final isDown = smoothedY > 0.6;
    final isUp = smoothedY < 0.4;
    
    if (_isInDownPosition && isUp) {
      _repCount++;
      _lastRepTime = DateTime.now();
      _isInDownPosition = false;
      return RepCountResult(
        repCount: _repCount,
        isInDownPosition: false,
        feedback: 'Повторение $_repCount! 💪',
        confidence: 0.7,
      );
    } else if (isDown && !_isInDownPosition) {
      _isInDownPosition = true;
    }
    
    return RepCountResult(
      repCount: _repCount,
      isInDownPosition: _isInDownPosition,
      feedback: 'Продолжайте!',
      confidence: 0.6,
    );
  }
}
/// Оптимизированная конфигурация упражнения
class OptimizedExerciseConfig {
  final JointType primaryJoint;
  final double primaryDownAngle;
  final double primaryUpAngle;
  final List<PoseLandmarkType> criticalPoints;
  final double minMovementAmplitude;
  final double confidenceBoost;
  final ExerciseType exerciseType;
  
  const OptimizedExerciseConfig({
    required this.primaryJoint,
    required this.primaryDownAngle,
    required this.primaryUpAngle,
    required this.criticalPoints,
    required this.minMovementAmplitude,
    required this.confidenceBoost,
    required this.exerciseType,
  });
}

/// Результат проверки критических точек
class CriticalPointsResult {
  final bool isValid;
  final double confidence;
  final String feedback;
  
  const CriticalPointsResult({
    required this.isValid,
    required this.confidence,
    required this.feedback,
  });
}

/// Тип упражнения
enum ExerciseType {
  dynamic,  // Динамические упражнения (приседания, отжимания)
  static,   // Статические упражнения (планка, статические позы)
}

/// Тип сустава для анализа
enum JointType {
  knee,
  elbow,
  shoulder,
  hip,
}

/// Результат вычисления угла
class _AngleResult {
  final double angle;
  final double confidence;
  final bool isValid;
  final String feedback;
  
  const _AngleResult({
    required this.angle,
    required this.confidence,
    required this.isValid,
    required this.feedback,
  });
}

/// Результат подсчета повторений
class RepCountResult {
  final int repCount;
  final bool isInDownPosition;
  final String feedback;
  final double confidence;
  final double? currentAngle;
  
  const RepCountResult({
    required this.repCount,
    required this.isInDownPosition,
    required this.feedback,
    required this.confidence,
    this.currentAngle,
  });
}