import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Улучшенный анализатор упражнений с продвинутыми алгоритмами распознавания
class EnhancedExerciseAnalyzer {
  // Кэш для оптимизации вычислений
  final Map<String, double> _angleCache = {};
  final Map<String, List<double>> _movementHistory = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Параметры оптимизации
  static const int _historySize = 8;
  static const int _cacheValidityMs = 50;
  static const double _minConfidenceThreshold = 0.4;
  
  // Счетчики для статистики
  int _frameCount = 0;
  DateTime _lastAnalysisTime = DateTime.now();
  
  /// Анализирует позу с улучшенными алгоритмами
  ExerciseAnalysisResult analyzeExercise(Pose pose, String exerciseType) {
    _frameCount++;
    
    // Быстрая проверка качества позы
    final poseQuality = _assessPoseQuality(pose);
    if (poseQuality.confidence < _minConfidenceThreshold) {
      return ExerciseAnalysisResult(
        isValidPose: false,
        confidence: poseQuality.confidence,
        feedback: poseQuality.feedback,
        technicalScore: 0.0,
        movementPhase: MovementPhase.unknown,
        keyAngles: {},
      );
    }
    
    // Анализ конкретного упражнения
    switch (exerciseType.toLowerCase()) {
      case 'squats':
        return _analyzeSquats(pose);
      case 'pushups':
        return _analyzePushups(pose);
      case 'lunges':
        return _analyzeLunges(pose);
      case 'jumping_jacks':
        return _analyzeJumpingJacks(pose);
      case 'plank':
        return _analyzePlank(pose);
      case 'burpees':
        return _analyzeBurpees(pose);
      default:
        return _analyzeGenericExercise(pose);
    }
  }
  
  /// Оценка качества позы
  PoseQualityResult _assessPoseQuality(Pose pose) {
    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    
    double totalConfidence = 0;
    int visibleLandmarks = 0;
    
    for (final landmarkType in keyLandmarks) {
      final landmark = pose.landmarks[landmarkType];
      if (landmark != null && landmark.likelihood > 0.3) {
        totalConfidence += landmark.likelihood;
        visibleLandmarks++;
      }
    }
    
    if (visibleLandmarks < keyLandmarks.length * 0.6) {
      return PoseQualityResult(
        confidence: 0.0,
        feedback: 'Встаньте так, чтобы было видно все тело',
        visibleLandmarks: visibleLandmarks,
      );
    }
    
    final avgConfidence = totalConfidence / visibleLandmarks;
    
    if (avgConfidence < 0.4) {
      return PoseQualityResult(
        confidence: avgConfidence,
        feedback: 'Улучшите освещение или подойдите ближе',
        visibleLandmarks: visibleLandmarks,
      );
    }
    
    return PoseQualityResult(
      confidence: avgConfidence,
      feedback: 'Поза определена четко',
      visibleLandmarks: visibleLandmarks,
    );
  }
  
  /// Анализ приседаний с улучшенными алгоритмами
  ExerciseAnalysisResult _analyzeSquats(Pose pose) {
    final keyAngles = <String, double>{};
    
    // Углы в коленях (основной показатель)
    final leftKneeAngle = _calculateKneeAngle(pose, isLeft: true);
    final rightKneeAngle = _calculateKneeAngle(pose, isLeft: false);
    
    if (leftKneeAngle == null || rightKneeAngle == null) {
      return ExerciseAnalysisResult(
        isValidPose: false,
        confidence: 0.0,
        feedback: 'Ноги не видны в кадре',
        technicalScore: 0.0,
        movementPhase: MovementPhase.unknown,
        keyAngles: {},
      );
    }
    
    // Сглаживание углов
    final smoothedLeftKnee = _addToHistory('left_knee', leftKneeAngle);
    final smoothedRightKnee = _addToHistory('right_knee', rightKneeAngle);
    final avgKneeAngle = (smoothedLeftKnee + smoothedRightKnee) / 2;
    
    keyAngles['left_knee'] = smoothedLeftKnee;
    keyAngles['right_knee'] = smoothedRightKnee;
    keyAngles['avg_knee'] = avgKneeAngle;
    
    // Угол спины (для оценки техники)
    final backAngle = _calculateBackAngle(pose);
    if (backAngle != null) {
      keyAngles['back'] = _addToHistory('back', backAngle);
    }
    
    // Определение фазы движения
    MovementPhase phase;
    if (avgKneeAngle < 120) {
      phase = MovementPhase.bottom;
    } else if (avgKneeAngle > 160) {
      phase = MovementPhase.top;
    } else {
      phase = MovementPhase.transition;
    }
    
    // Оценка техники
    double technicalScore = _evaluateSquatTechnique(pose, keyAngles);
    
    // Обратная связь
    String feedback = _generateSquatFeedback(avgKneeAngle, technicalScore, phase);
    
    return ExerciseAnalysisResult(
      isValidPose: true,
      confidence: 0.85,
      feedback: feedback,
      technicalScore: technicalScore,
      movementPhase: phase,
      keyAngles: keyAngles,
    );
  }
  
  /// Анализ отжиманий
  ExerciseAnalysisResult _analyzePushups(Pose pose) {
    final keyAngles = <String, double>{};
    
    // Углы в локтях
    final leftElbowAngle = _calculateElbowAngle(pose, isLeft: true);
    final rightElbowAngle = _calculateElbowAngle(pose, isLeft: false);
    
    if (leftElbowAngle == null || rightElbowAngle == null) {
      return ExerciseAnalysisResult(
        isValidPose: false,
        confidence: 0.0,
        feedback: 'Руки не видны в кадре',
        technicalScore: 0.0,
        movementPhase: MovementPhase.unknown,
        keyAngles: {},
      );
    }
    
    final smoothedLeftElbow = _addToHistory('left_elbow', leftElbowAngle);
    final smoothedRightElbow = _addToHistory('right_elbow', rightElbowAngle);
    final avgElbowAngle = (smoothedLeftElbow + smoothedRightElbow) / 2;
    
    keyAngles['left_elbow'] = smoothedLeftElbow;
    keyAngles['right_elbow'] = smoothedRightElbow;
    keyAngles['avg_elbow'] = avgElbowAngle;
    
    // Угол тела (планка)
    final bodyAngle = _calculateBodyLineAngle(pose);
    if (bodyAngle != null) {
      keyAngles['body_line'] = _addToHistory('body_line', bodyAngle);
    }
    
    // Определение фазы
    MovementPhase phase;
    if (avgElbowAngle < 100) {
      phase = MovementPhase.bottom;
    } else if (avgElbowAngle > 160) {
      phase = MovementPhase.top;
    } else {
      phase = MovementPhase.transition;
    }
    
    // Оценка техники
    double technicalScore = _evaluatePushupTechnique(pose, keyAngles);
    
    // Обратная связь
    String feedback = _generatePushupFeedback(avgElbowAngle, technicalScore, phase);
    
    return ExerciseAnalysisResult(
      isValidPose: true,
      confidence: 0.80,
      feedback: feedback,
      technicalScore: technicalScore,
      movementPhase: phase,
      keyAngles: keyAngles,
    );
  }
  
  /// Анализ выпадов
  ExerciseAnalysisResult _analyzeLunges(Pose pose) {
    final keyAngles = <String, double>{};
    
    // Углы в коленях для выпадов
    final frontKneeAngle = _calculateKneeAngle(pose, isLeft: true);
    final backKneeAngle = _calculateKneeAngle(pose, isLeft: false);
    
    if (frontKneeAngle == null || backKneeAngle == null) {
      return ExerciseAnalysisResult(
        isValidPose: false,
        confidence: 0.0,
        feedback: 'Ноги не видны полностью',
        technicalScore: 0.0,
        movementPhase: MovementPhase.unknown,
        keyAngles: {},
      );
    }
    
    final smoothedFrontKnee = _addToHistory('front_knee', frontKneeAngle);
    final smoothedBackKnee = _addToHistory('back_knee', backKneeAngle);
    
    keyAngles['front_knee'] = smoothedFrontKnee;
    keyAngles['back_knee'] = smoothedBackKnee;
    
    // Определение фазы выпада
    MovementPhase phase;
    if (smoothedFrontKnee < 110 && smoothedBackKnee < 120) {
      phase = MovementPhase.bottom;
    } else if (smoothedFrontKnee > 150 && smoothedBackKnee > 150) {
      phase = MovementPhase.top;
    } else {
      phase = MovementPhase.transition;
    }
    
    // Оценка техники выпадов
    double technicalScore = _evaluateLungeTechnique(pose, keyAngles);
    
    String feedback = _generateLungeFeedback(smoothedFrontKnee, smoothedBackKnee, technicalScore, phase);
    
    return ExerciseAnalysisResult(
      isValidPose: true,
      confidence: 0.75,
      feedback: feedback,
      technicalScore: technicalScore,
      movementPhase: phase,
      keyAngles: keyAngles,
    );
  }
  
  /// Анализ jumping jacks
  ExerciseAnalysisResult _analyzeJumpingJacks(Pose pose) {
    final keyAngles = <String, double>{};
    
    // Расстояние между руками и ногами
    final armSpread = _calculateArmSpread(pose);
    final legSpread = _calculateLegSpread(pose);
    
    if (armSpread == null || legSpread == null) {
      return ExerciseAnalysisResult(
        isValidPose: false,
        confidence: 0.0,
        feedback: 'Руки и ноги не видны полностью',
        technicalScore: 0.0,
        movementPhase: MovementPhase.unknown,
        keyAngles: {},
      );
    }
    
    final smoothedArmSpread = _addToHistory('arm_spread', armSpread);
    final smoothedLegSpread = _addToHistory('leg_spread', legSpread);
    
    keyAngles['arm_spread'] = smoothedArmSpread;
    keyAngles['leg_spread'] = smoothedLegSpread;
    
    // Определение фазы jumping jacks
    MovementPhase phase;
    if (smoothedArmSpread > 0.6 && smoothedLegSpread > 0.3) {
      phase = MovementPhase.top; // Руки вверх, ноги врозь
    } else if (smoothedArmSpread < 0.2 && smoothedLegSpread < 0.1) {
      phase = MovementPhase.bottom; // Руки вниз, ноги вместе
    } else {
      phase = MovementPhase.transition;
    }
    
    double technicalScore = _evaluateJumpingJacksTechnique(pose, keyAngles);
    
    String feedback = _generateJumpingJacksFeedback(smoothedArmSpread, smoothedLegSpread, phase);
    
    return ExerciseAnalysisResult(
      isValidPose: true,
      confidence: 0.70,
      feedback: feedback,
      technicalScore: technicalScore,
      movementPhase: phase,
      keyAngles: keyAngles,
    );
  }
  
  /// Анализ планки
  ExerciseAnalysisResult _analyzePlank(Pose pose) {
    final keyAngles = <String, double>{};
    
    // Угол тела в планке
    final bodyLineAngle = _calculateBodyLineAngle(pose);
    final hipAngle = _calculateHipAngle(pose);
    
    if (bodyLineAngle == null) {
      return ExerciseAnalysisResult(
        isValidPose: false,
        confidence: 0.0,
        feedback: 'Тело не видно полностью',
        technicalScore: 0.0,
        movementPhase: MovementPhase.unknown,
        keyAngles: {},
      );
    }
    
    final smoothedBodyLine = _addToHistory('body_line', bodyLineAngle);
    keyAngles['body_line'] = smoothedBodyLine;
    
    if (hipAngle != null) {
      keyAngles['hip_angle'] = _addToHistory('hip_angle', hipAngle);
    }
    
    // Для планки всегда статическая фаза
    MovementPhase phase = MovementPhase.static;
    
    // Оценка техники планки
    double technicalScore = _evaluatePlankTechnique(pose, keyAngles);
    
    String feedback = _generatePlankFeedback(smoothedBodyLine, technicalScore);
    
    return ExerciseAnalysisResult(
      isValidPose: true,
      confidence: 0.85,
      feedback: feedback,
      technicalScore: technicalScore,
      movementPhase: phase,
      keyAngles: keyAngles,
    );
  }
  
  /// Анализ берпи
  ExerciseAnalysisResult _analyzeBurpees(Pose pose) {
    final keyAngles = <String, double>{};
    
    // Комбинированный анализ для берпи
    final bodyHeight = _calculateBodyHeight(pose);
    final armPosition = _calculateArmPosition(pose);
    
    if (bodyHeight == null) {
      return ExerciseAnalysisResult(
        isValidPose: false,
        confidence: 0.0,
        feedback: 'Тело не видно полностью',
        technicalScore: 0.0,
        movementPhase: MovementPhase.unknown,
        keyAngles: {},
      );
    }
    
    final smoothedHeight = _addToHistory('body_height', bodyHeight);
    keyAngles['body_height'] = smoothedHeight;
    
    if (armPosition != null) {
      keyAngles['arm_position'] = _addToHistory('arm_position', armPosition);
    }
    
    // Определение фазы берпи
    MovementPhase phase;
    if (smoothedHeight < 0.3) {
      phase = MovementPhase.bottom; // Лежа/планка
    } else if (smoothedHeight > 0.8) {
      phase = MovementPhase.top; // Прыжок вверх
    } else {
      phase = MovementPhase.transition; // Переход
    }
    
    double technicalScore = _evaluateBurpeeTechnique(pose, keyAngles);
    
    String feedback = _generateBurpeeFeedback(smoothedHeight, phase);
    
    return ExerciseAnalysisResult(
      isValidPose: true,
      confidence: 0.65,
      feedback: feedback,
      technicalScore: technicalScore,
      movementPhase: phase,
      keyAngles: keyAngles,
    );
  }
  
  /// Общий анализ для неизвестных упражнений
  ExerciseAnalysisResult _analyzeGenericExercise(Pose pose) {
    final keyAngles = <String, double>{};
    
    // Базовые углы
    final leftKneeAngle = _calculateKneeAngle(pose, isLeft: true);
    final rightKneeAngle = _calculateKneeAngle(pose, isLeft: false);
    
    if (leftKneeAngle != null && rightKneeAngle != null) {
      keyAngles['left_knee'] = leftKneeAngle;
      keyAngles['right_knee'] = rightKneeAngle;
      keyAngles['avg_knee'] = (leftKneeAngle + rightKneeAngle) / 2;
    }
    
    return ExerciseAnalysisResult(
      isValidPose: true,
      confidence: 0.50,
      feedback: 'Продолжайте упражнение!',
      technicalScore: 0.70,
      movementPhase: MovementPhase.unknown,
      keyAngles: keyAngles,
    );
  }
  
  // ========== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ РАСЧЕТА УГЛОВ ==========
  
  /// Расчет угла в колене
  double? _calculateKneeAngle(Pose pose, {required bool isLeft}) {
    final hip = pose.landmarks[isLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = pose.landmarks[isLeft ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final ankle = pose.landmarks[isLeft ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];
    
    if (hip == null || knee == null || ankle == null) return null;
    
    return _calculateAngle(hip, knee, ankle);
  }
  
  /// Расчет угла в локте
  double? _calculateElbowAngle(Pose pose, {required bool isLeft}) {
    final shoulder = pose.landmarks[isLeft ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[isLeft ? PoseLandmarkType.leftElbow : PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[isLeft ? PoseLandmarkType.leftWrist : PoseLandmarkType.rightWrist];
    
    if (shoulder == null || elbow == null || wrist == null) return null;
    
    return _calculateAngle(shoulder, elbow, wrist);
  }
  
  /// Расчет угла спины
  double? _calculateBackAngle(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    
    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) return null;
    
    // Средние точки плеч и бедер
    final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipMidX = (leftHip.x + rightHip.x) / 2;
    final hipMidY = (leftHip.y + rightHip.y) / 2;
    
    // Угол наклона спины относительно вертикали
    final deltaX = shoulderMidX - hipMidX;
    final deltaY = shoulderMidY - hipMidY;
    
    final angle = math.atan2(deltaX.abs(), deltaY.abs()) * 180 / math.pi;
    return angle;
  }
  
  /// Расчет угла линии тела (для планки/отжиманий)
  double? _calculateBodyLineAngle(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (leftShoulder == null || rightShoulder == null || 
        leftHip == null || rightHip == null ||
        leftAnkle == null || rightAnkle == null) return null;
    
    // Средние точки
    final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final ankleMidX = (leftAnkle.x + rightAnkle.x) / 2;
    final ankleMidY = (leftAnkle.y + rightAnkle.y) / 2;
    
    // Угол линии плечи-лодыжки
    final deltaX = ankleMidX - shoulderMidX;
    final deltaY = ankleMidY - shoulderMidY;
    
    final angle = math.atan2(deltaY.abs(), deltaX.abs()) * 180 / math.pi;
    return 180 - angle; // Инвертируем для удобства (180° = прямая линия)
  }
  
  /// Расчет угла в бедре
  double? _calculateHipAngle(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    
    if (leftShoulder == null || leftHip == null || leftKnee == null) return null;
    
    return _calculateAngle(leftShoulder, leftHip, leftKnee);
  }
  
  /// Расчет расстояния между руками
  double? _calculateArmSpread(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    
    if (leftWrist == null || rightWrist == null) return null;
    
    final distance = math.sqrt(
      math.pow(leftWrist.x - rightWrist.x, 2) + 
      math.pow(leftWrist.y - rightWrist.y, 2)
    );
    
    return distance;
  }
  
  /// Расчет расстояния между ногами
  double? _calculateLegSpread(Pose pose) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (leftAnkle == null || rightAnkle == null) return null;
    
    final distance = math.sqrt(
      math.pow(leftAnkle.x - rightAnkle.x, 2) + 
      math.pow(leftAnkle.y - rightAnkle.y, 2)
    );
    
    return distance;
  }
  
  /// Расчет высоты тела
  double? _calculateBodyHeight(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (nose == null || leftAnkle == null || rightAnkle == null) return null;
    
    final ankleMidY = (leftAnkle.y + rightAnkle.y) / 2;
    return (ankleMidY - nose.y).abs();
  }
  
  /// Расчет позиции рук
  double? _calculateArmPosition(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    if (leftWrist == null || rightWrist == null || 
        leftShoulder == null || rightShoulder == null) return null;
    
    final wristMidY = (leftWrist.y + rightWrist.y) / 2;
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    
    return (wristMidY - shoulderMidY); // Положительное = руки ниже плеч
  }
  
  /// Базовый расчет угла между тремя точками
  double _calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
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
  
  // ========== МЕТОДЫ ОЦЕНКИ ТЕХНИКИ ==========
  
  /// Оценка техники приседаний
  double _evaluateSquatTechnique(Pose pose, Map<String, double> keyAngles) {
    double score = 100.0;
    
    // Проверка симметрии коленей
    final leftKnee = keyAngles['left_knee'] ?? 0;
    final rightKnee = keyAngles['right_knee'] ?? 0;
    final kneeDifference = (leftKnee - rightKnee).abs();
    
    if (kneeDifference > 15) {
      score -= 20; // Штраф за асимметрию
    } else if (kneeDifference > 8) {
      score -= 10;
    }
    
    // Проверка угла спины
    final backAngle = keyAngles['back'];
    if (backAngle != null) {
      if (backAngle > 45) {
        score -= 25; // Слишком сильный наклон
      } else if (backAngle > 30) {
        score -= 15;
      }
    }
    
    // Проверка глубины приседания
    final avgKnee = keyAngles['avg_knee'] ?? 180;
    if (avgKnee > 140) {
      score -= 15; // Недостаточная глубина
    }
    
    return (score / 100).clamp(0.0, 1.0);
  }
  
  /// Оценка техники отжиманий
  double _evaluatePushupTechnique(Pose pose, Map<String, double> keyAngles) {
    double score = 100.0;
    
    // Проверка симметрии локтей
    final leftElbow = keyAngles['left_elbow'] ?? 0;
    final rightElbow = keyAngles['right_elbow'] ?? 0;
    final elbowDifference = (leftElbow - rightElbow).abs();
    
    if (elbowDifference > 20) {
      score -= 25;
    } else if (elbowDifference > 10) {
      score -= 15;
    }
    
    // Проверка линии тела
    final bodyLine = keyAngles['body_line'];
    if (bodyLine != null) {
      if (bodyLine < 160) {
        score -= 30; // Провисание тела
      } else if (bodyLine < 170) {
        score -= 15;
      }
    }
    
    return (score / 100).clamp(0.0, 1.0);
  }
  
  /// Оценка техники выпадов
  double _evaluateLungeTechnique(Pose pose, Map<String, double> keyAngles) {
    double score = 100.0;
    
    final frontKnee = keyAngles['front_knee'] ?? 180;
    final backKnee = keyAngles['back_knee'] ?? 180;
    
    // Проверка переднего колена
    if (frontKnee > 130) {
      score -= 20; // Недостаточная глубина
    }
    
    // Проверка заднего колена
    if (backKnee > 140) {
      score -= 15; // Недостаточное опускание
    }
    
    return (score / 100).clamp(0.0, 1.0);
  }
  
  /// Оценка техники jumping jacks
  double _evaluateJumpingJacksTechnique(Pose pose, Map<String, double> keyAngles) {
    double score = 100.0;
    
    final armSpread = keyAngles['arm_spread'] ?? 0;
    final legSpread = keyAngles['leg_spread'] ?? 0;
    
    // Проверка координации рук и ног
    final coordination = (armSpread * legSpread);
    if (coordination < 0.1) {
      score -= 20; // Плохая координация
    }
    
    return (score / 100).clamp(0.0, 1.0);
  }
  
  /// Оценка техники планки
  double _evaluatePlankTechnique(Pose pose, Map<String, double> keyAngles) {
    double score = 100.0;
    
    final bodyLine = keyAngles['body_line'] ?? 0;
    
    // Проверка прямой линии тела
    if (bodyLine < 160) {
      score -= 40; // Сильное провисание
    } else if (bodyLine < 170) {
      score -= 20;
    }
    
    // Проверка угла в бедрах
    final hipAngle = keyAngles['hip_angle'];
    if (hipAngle != null) {
      if (hipAngle < 160 || hipAngle > 200) {
        score -= 20; // Неправильное положение бедер
      }
    }
    
    return (score / 100).clamp(0.0, 1.0);
  }
  
  /// Оценка техники берпи
  double _evaluateBurpeeTechnique(Pose pose, Map<String, double> keyAngles) {
    double score = 100.0;
    
    // Базовая оценка для сложного упражнения
    final bodyHeight = keyAngles['body_height'] ?? 0.5;
    
    // Проверка полноты движения
    if (bodyHeight > 0.2 && bodyHeight < 0.8) {
      score -= 10; // Неполное движение
    }
    
    return (score / 100).clamp(0.0, 1.0);
  }
  
  // ========== МЕТОДЫ ГЕНЕРАЦИИ ОБРАТНОЙ СВЯЗИ ==========
  
  /// Генерация обратной связи для приседаний
  String _generateSquatFeedback(double avgKneeAngle, double technicalScore, MovementPhase phase) {
    if (technicalScore < 0.5) {
      return 'Следите за техникой! Держите спину прямо 📐';
    }
    
    switch (phase) {
      case MovementPhase.top:
        return 'Отлично! Теперь приседайте глубже 🔻';
      case MovementPhase.bottom:
        return 'Супер! Поднимайтесь вверх 🔺';
      case MovementPhase.transition:
        return 'Продолжайте движение! 💪';
      default:
        return 'Выполняйте приседания! 🏋️‍♀️';
    }
  }
  
  /// Генерация обратной связи для отжиманий
  String _generatePushupFeedback(double avgElbowAngle, double technicalScore, MovementPhase phase) {
    if (technicalScore < 0.5) {
      return 'Держите тело прямо! 📏';
    }
    
    switch (phase) {
      case MovementPhase.top:
        return 'Отлично! Опускайтесь вниз 🔻';
      case MovementPhase.bottom:
        return 'Супер! Отжимайтесь вверх 🔺';
      case MovementPhase.transition:
        return 'Продолжайте! 💪';
      default:
        return 'Выполняйте отжимания! 🤸‍♀️';
    }
  }
  
  /// Генерация обратной связи для выпадов
  String _generateLungeFeedback(double frontKnee, double backKnee, double technicalScore, MovementPhase phase) {
    if (technicalScore < 0.5) {
      return 'Следите за техникой выпадов! ⚖️';
    }
    
    switch (phase) {
      case MovementPhase.top:
        return 'Отлично! Делайте выпад глубже 🔻';
      case MovementPhase.bottom:
        return 'Супер! Поднимайтесь вверх 🔺';
      case MovementPhase.transition:
        return 'Продолжайте выпады! 💪';
      default:
        return 'Выполняйте выпады! 🦵';
    }
  }
  
  /// Генерация обратной связи для jumping jacks
  String _generateJumpingJacksFeedback(double armSpread, double legSpread, MovementPhase phase) {
    switch (phase) {
      case MovementPhase.top:
        return 'Отлично! Руки вверх, ноги врозь! 🙌';
      case MovementPhase.bottom:
        return 'Супер! Руки вниз, ноги вместе! 👏';
      case MovementPhase.transition:
        return 'Продолжайте прыжки! 🦘';
      default:
        return 'Выполняйте jumping jacks! 🤸‍♂️';
    }
  }
  
  /// Генерация обратной связи для планки
  String _generatePlankFeedback(double bodyLineAngle, double technicalScore) {
    if (technicalScore > 0.8) {
      return 'Отличная планка! Держите! 🔥';
    } else if (technicalScore > 0.6) {
      return 'Хорошо! Держите тело прямо 📏';
    } else {
      return 'Выпрямите тело в линию! 📐';
    }
  }
  
  /// Генерация обратной связи для берпи
  String _generateBurpeeFeedback(double bodyHeight, MovementPhase phase) {
    switch (phase) {
      case MovementPhase.top:
        return 'Отлично! Прыжок вверх! 🚀';
      case MovementPhase.bottom:
        return 'Супер! Планка! 🏋️‍♀️';
      case MovementPhase.transition:
        return 'Продолжайте берпи! 💪';
      default:
        return 'Выполняйте берпи! 🤸‍♀️';
    }
  }
  
  // ========== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ==========
  
  /// Добавление значения в историю с сглаживанием
  double _addToHistory(String key, double value) {
    if (!_movementHistory.containsKey(key)) {
      _movementHistory[key] = [];
    }
    
    _movementHistory[key]!.add(value);
    if (_movementHistory[key]!.length > _historySize) {
      _movementHistory[key]!.removeAt(0);
    }
    
    // Взвешенное среднее (последние значения важнее)
    final history = _movementHistory[key]!;
    double weightedSum = 0;
    double totalWeight = 0;
    
    for (int i = 0; i < history.length; i++) {
      final weight = (i + 1).toDouble();
      weightedSum += history[i] * weight;
      totalWeight += weight;
    }
    
    return weightedSum / totalWeight;
  }
  
  /// Очистка кэшей и истории
  void clearCache() {
    _angleCache.clear();
    _movementHistory.clear();
    _cacheTimestamps.clear();
    _frameCount = 0;
  }
  
  /// Получение статистики производительности
  Map<String, dynamic> getPerformanceStats() {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastAnalysisTime).inMilliseconds;
    final fps = timeDiff > 0 ? 1000.0 / timeDiff : 0.0;
    
    _lastAnalysisTime = now;
    
    return {
      'fps': fps,
      'frame_count': _frameCount,
      'cache_size': _angleCache.length,
      'history_size': _movementHistory.length,
    };
  }
}

// ========== КЛАССЫ РЕЗУЛЬТАТОВ ==========

/// Результат анализа упражнения
class ExerciseAnalysisResult {
  final bool isValidPose;
  final double confidence;
  final String feedback;
  final double technicalScore;
  final MovementPhase movementPhase;
  final Map<String, double> keyAngles;
  
  const ExerciseAnalysisResult({
    required this.isValidPose,
    required this.confidence,
    required this.feedback,
    required this.technicalScore,
    required this.movementPhase,
    required this.keyAngles,
  });
}

/// Результат оценки качества позы
class PoseQualityResult {
  final double confidence;
  final String feedback;
  final int visibleLandmarks;
  
  const PoseQualityResult({
    required this.confidence,
    required this.feedback,
    required this.visibleLandmarks,
  });
}

/// Фазы движения
enum MovementPhase {
  top,        // Верхняя позиция
  bottom,     // Нижняя позиция
  transition, // Переходная фаза
  static,     // Статическая позиция
  unknown,    // Неизвестная фаза
}