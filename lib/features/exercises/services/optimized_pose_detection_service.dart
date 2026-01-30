import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pose_detection_service.dart';

/// Оптимизированный сервис детекции поз
/// Использует только критичные точки для максимальной точности оценки упражнений
class OptimizedPoseDetectionService {
  static const double _confidenceThreshold = 0.7;
  static const double _angleToleranceDegrees = 15.0;
  
  // Критичные точки для разных типов упражнений
  static const Map<String, List<KeypointType>> _criticalPointsMap = {
    'squats': [
      KeypointType.leftHip,
      KeypointType.rightHip,
      KeypointType.leftKnee,
      KeypointType.rightKnee,
      KeypointType.leftAnkle,
      KeypointType.rightAnkle,
      KeypointType.leftShoulder,
      KeypointType.rightShoulder,
    ],
    'pushups': [
      KeypointType.leftShoulder,
      KeypointType.rightShoulder,
      KeypointType.leftElbow,
      KeypointType.rightElbow,
      KeypointType.leftWrist,
      KeypointType.rightWrist,
      KeypointType.leftHip,
      KeypointType.rightHip,
    ],
    'lunges': [
      KeypointType.leftHip,
      KeypointType.rightHip,
      KeypointType.leftKnee,
      KeypointType.rightKnee,
      KeypointType.leftAnkle,
      KeypointType.rightAnkle,
    ],
    'plank': [
      KeypointType.leftShoulder,
      KeypointType.rightShoulder,
      KeypointType.leftElbow,
      KeypointType.rightElbow,
      KeypointType.leftHip,
      KeypointType.rightHip,
      KeypointType.leftAnkle,
      KeypointType.rightAnkle,
    ],
  };

  // Идеальные углы для упражнений (в градусах)
  static const Map<String, Map<String, double>> _idealAngles = {
    'squats': {
      'knee_angle_down': 90.0,
      'knee_angle_up': 170.0,
      'hip_angle_down': 90.0,
      'back_angle': 15.0, // отклонение от вертикали
    },
    'pushups': {
      'elbow_angle_down': 90.0,
      'elbow_angle_up': 170.0,
      'body_line': 180.0, // прямая линия тела
    },
    'lunges': {
      'front_knee_angle': 90.0,
      'back_knee_angle': 90.0,
      'hip_angle': 90.0,
    },
    'plank': {
      'body_line': 180.0,
      'elbow_angle': 90.0,
    },
  };

  /// Анализирует позу для конкретного упражнения
  static ExerciseAnalysis analyzePose(List<BodyKeypoint> keypoints, String exerciseType) {
    final criticalPoints = _criticalPointsMap[exerciseType];
    if (criticalPoints == null) {
      return ExerciseAnalysis(
        isCorrect: false,
        accuracy: 0.0,
        feedback: 'Неизвестный тип упражнения',
        criticalErrors: ['Упражнение не поддерживается'],
      );
    }

    // Проверяем наличие всех критичных точек с достаточной уверенностью
    final validPoints = <KeypointType, BodyKeypoint>{};
    final missingPoints = <KeypointType>[];

    for (final pointType in criticalPoints) {
      final keypoint = keypoints.where((k) => k.type == pointType).firstOrNull;
      if (keypoint != null && keypoint.confidence >= _confidenceThreshold) {
        validPoints[pointType] = keypoint;
      } else {
        missingPoints.add(pointType);
      }
    }

    // Если слишком много точек отсутствует, возвращаем низкую оценку
    if (missingPoints.length > criticalPoints.length * 0.3) {
      return ExerciseAnalysis(
        isCorrect: false,
        accuracy: 0.0,
        feedback: 'Недостаточно видимых ключевых точек',
        criticalErrors: ['Встаньте полностью в кадр'],
      );
    }

    // Анализируем упражнение на основе типа
    switch (exerciseType) {
      case 'squats':
        return _analyzeSquats(validPoints);
      case 'pushups':
        return _analyzePushups(validPoints);
      case 'lunges':
        return _analyzeLunges(validPoints);
      case 'plank':
        return _analyzePlank(validPoints);
      default:
        return ExerciseAnalysis(
          isCorrect: false,
          accuracy: 0.0,
          feedback: 'Упражнение не поддерживается',
          criticalErrors: ['Неизвестный тип упражнения'],
        );
    }
  }

  /// Анализ приседаний
  static ExerciseAnalysis _analyzeSquats(Map<KeypointType, BodyKeypoint> points) {
    final errors = <String>[];
    final warnings = <String>[];
    double totalAccuracy = 0.0;
    int checks = 0;

    // Проверяем угол в коленях
    if (points.containsKey(KeypointType.leftHip) &&
        points.containsKey(KeypointType.leftKnee) &&
        points.containsKey(KeypointType.leftAnkle)) {
      
      final kneeAngle = _calculateAngle(
        points[KeypointType.leftHip]!.position,
        points[KeypointType.leftKnee]!.position,
        points[KeypointType.leftAnkle]!.position,
      );

      final idealKneeAngle = _idealAngles['squats']!['knee_angle_down']!;
      final kneeAccuracy = _calculateAngleAccuracy(kneeAngle, idealKneeAngle);
      totalAccuracy += kneeAccuracy;
      checks++;

      if (kneeAccuracy < 0.7) {
        if (kneeAngle > idealKneeAngle + _angleToleranceDegrees) {
          errors.add('Приседайте глубже');
        } else if (kneeAngle < idealKneeAngle - _angleToleranceDegrees) {
          warnings.add('Слишком глубокое приседание');
        }
      }
    }

    // Проверяем положение спины
    if (points.containsKey(KeypointType.leftShoulder) &&
        points.containsKey(KeypointType.leftHip)) {
      
      final backAngle = _calculateVerticalAngle(
        points[KeypointType.leftShoulder]!.position,
        points[KeypointType.leftHip]!.position,
      );

      final idealBackAngle = _idealAngles['squats']!['back_angle']!;
      final backAccuracy = _calculateAngleAccuracy(backAngle, idealBackAngle);
      totalAccuracy += backAccuracy;
      checks++;

      if (backAccuracy < 0.7) {
        if (backAngle > idealBackAngle + _angleToleranceDegrees) {
          errors.add('Держите спину прямее');
        }
      }
    }

    // Проверяем симметрию
    final symmetryAccuracy = _checkSymmetry(points, [
      (KeypointType.leftKnee, KeypointType.rightKnee),
      (KeypointType.leftHip, KeypointType.rightHip),
    ]);
    totalAccuracy += symmetryAccuracy;
    checks++;

    if (symmetryAccuracy < 0.8) {
      warnings.add('Следите за симметрией движения');
    }

    final averageAccuracy = checks > 0 ? totalAccuracy / checks : 0.0;
    final isCorrect = averageAccuracy >= 0.8 && errors.isEmpty;

    return ExerciseAnalysis(
      isCorrect: isCorrect,
      accuracy: averageAccuracy,
      feedback: _generateFeedback(averageAccuracy, errors, warnings),
      criticalErrors: errors,
      warnings: warnings,
    );
  }

  /// Анализ отжиманий
  static ExerciseAnalysis _analyzePushups(Map<KeypointType, BodyKeypoint> points) {
    final errors = <String>[];
    final warnings = <String>[];
    double totalAccuracy = 0.0;
    int checks = 0;

    // Проверяем угол в локтях
    if (points.containsKey(KeypointType.leftShoulder) &&
        points.containsKey(KeypointType.leftElbow) &&
        points.containsKey(KeypointType.leftWrist)) {
      
      final elbowAngle = _calculateAngle(
        points[KeypointType.leftShoulder]!.position,
        points[KeypointType.leftElbow]!.position,
        points[KeypointType.leftWrist]!.position,
      );

      final idealElbowAngle = _idealAngles['pushups']!['elbow_angle_down']!;
      final elbowAccuracy = _calculateAngleAccuracy(elbowAngle, idealElbowAngle);
      totalAccuracy += elbowAccuracy;
      checks++;

      if (elbowAccuracy < 0.7) {
        if (elbowAngle > idealElbowAngle + _angleToleranceDegrees) {
          errors.add('Опускайтесь ниже');
        } else if (elbowAngle < idealElbowAngle - _angleToleranceDegrees) {
          warnings.add('Не опускайтесь слишком низко');
        }
      }
    }

    // Проверяем прямую линию тела
    if (points.containsKey(KeypointType.leftShoulder) &&
        points.containsKey(KeypointType.leftHip) &&
        points.containsKey(KeypointType.leftAnkle)) {
      
      final bodyLineAccuracy = _checkBodyLine([
        points[KeypointType.leftShoulder]!.position,
        points[KeypointType.leftHip]!.position,
        points[KeypointType.leftAnkle]!.position,
      ]);
      
      totalAccuracy += bodyLineAccuracy;
      checks++;

      if (bodyLineAccuracy < 0.8) {
        errors.add('Держите тело прямо');
      }
    }

    final averageAccuracy = checks > 0 ? totalAccuracy / checks : 0.0;
    final isCorrect = averageAccuracy >= 0.8 && errors.isEmpty;

    return ExerciseAnalysis(
      isCorrect: isCorrect,
      accuracy: averageAccuracy,
      feedback: _generateFeedback(averageAccuracy, errors, warnings),
      criticalErrors: errors,
      warnings: warnings,
    );
  }

  /// Анализ выпадов
  static ExerciseAnalysis _analyzeLunges(Map<KeypointType, BodyKeypoint> points) {
    final errors = <String>[];
    final warnings = <String>[];
    double totalAccuracy = 0.0;
    int checks = 0;

    // Проверяем угол переднего колена
    if (points.containsKey(KeypointType.leftHip) &&
        points.containsKey(KeypointType.leftKnee) &&
        points.containsKey(KeypointType.leftAnkle)) {
      
      final frontKneeAngle = _calculateAngle(
        points[KeypointType.leftHip]!.position,
        points[KeypointType.leftKnee]!.position,
        points[KeypointType.leftAnkle]!.position,
      );

      final idealAngle = _idealAngles['lunges']!['front_knee_angle']!;
      final accuracy = _calculateAngleAccuracy(frontKneeAngle, idealAngle);
      totalAccuracy += accuracy;
      checks++;

      if (accuracy < 0.7) {
        if (frontKneeAngle > idealAngle + _angleToleranceDegrees) {
          errors.add('Опускайтесь ниже в выпаде');
        } else if (frontKneeAngle < idealAngle - _angleToleranceDegrees) {
          warnings.add('Не опускайтесь слишком низко');
        }
      }
    }

    final averageAccuracy = checks > 0 ? totalAccuracy / checks : 0.0;
    final isCorrect = averageAccuracy >= 0.8 && errors.isEmpty;

    return ExerciseAnalysis(
      isCorrect: isCorrect,
      accuracy: averageAccuracy,
      feedback: _generateFeedback(averageAccuracy, errors, warnings),
      criticalErrors: errors,
      warnings: warnings,
    );
  }

  /// Анализ планки
  static ExerciseAnalysis _analyzePlank(Map<KeypointType, BodyKeypoint> points) {
    final errors = <String>[];
    final warnings = <String>[];
    double totalAccuracy = 0.0;
    int checks = 0;

    // Проверяем прямую линию тела
    if (points.containsKey(KeypointType.leftShoulder) &&
        points.containsKey(KeypointType.leftHip) &&
        points.containsKey(KeypointType.leftAnkle)) {
      
      final bodyLineAccuracy = _checkBodyLine([
        points[KeypointType.leftShoulder]!.position,
        points[KeypointType.leftHip]!.position,
        points[KeypointType.leftAnkle]!.position,
      ]);
      
      totalAccuracy += bodyLineAccuracy;
      checks++;

      if (bodyLineAccuracy < 0.8) {
        errors.add('Держите тело в прямой линии');
      }
    }

    final averageAccuracy = checks > 0 ? totalAccuracy / checks : 0.0;
    final isCorrect = averageAccuracy >= 0.8 && errors.isEmpty;

    return ExerciseAnalysis(
      isCorrect: isCorrect,
      accuracy: averageAccuracy,
      feedback: _generateFeedback(averageAccuracy, errors, warnings),
      criticalErrors: errors,
      warnings: warnings,
    );
  }

  /// Вычисляет угол между тремя точками
  static double _calculateAngle(Offset a, Offset b, Offset c) {
    final vector1 = Offset(a.dx - b.dx, a.dy - b.dy);
    final vector2 = Offset(c.dx - b.dx, c.dy - b.dy);
    
    final dot = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final mag1 = math.sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy);
    final mag2 = math.sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy);
    
    if (mag1 == 0 || mag2 == 0) return 0;
    
    final cosAngle = dot / (mag1 * mag2);
    final clampedCos = cosAngle.clamp(-1.0, 1.0);
    return math.acos(clampedCos) * 180 / math.pi;
  }

  /// Вычисляет угол относительно вертикали
  static double _calculateVerticalAngle(Offset upper, Offset lower) {
    final dx = upper.dx - lower.dx;
    final dy = upper.dy - lower.dy;
    return math.atan2(dx.abs(), dy.abs()) * 180 / math.pi;
  }

  /// Вычисляет точность угла
  static double _calculateAngleAccuracy(double actualAngle, double idealAngle) {
    final difference = (actualAngle - idealAngle).abs();
    if (difference <= _angleToleranceDegrees) {
      return 1.0;
    } else if (difference <= _angleToleranceDegrees * 2) {
      return 1.0 - (difference - _angleToleranceDegrees) / _angleToleranceDegrees;
    } else {
      return 0.0;
    }
  }

  /// Проверяет симметрию между парами точек
  static double _checkSymmetry(
    Map<KeypointType, BodyKeypoint> points,
    List<(KeypointType, KeypointType)> pairs,
  ) {
    double totalSymmetry = 0.0;
    int validPairs = 0;

    for (final (left, right) in pairs) {
      if (points.containsKey(left) && points.containsKey(right)) {
        final leftPoint = points[left]!.position;
        final rightPoint = points[right]!.position;
        
        // Проверяем симметрию по высоте
        final heightDifference = (leftPoint.dy - rightPoint.dy).abs();
        final symmetryScore = math.max(0.0, 1.0 - heightDifference / 100);
        
        totalSymmetry += symmetryScore;
        validPairs++;
      }
    }

    return validPairs > 0 ? totalSymmetry / validPairs : 0.0;
  }

  /// Проверяет прямую линию тела
  static double _checkBodyLine(List<Offset> points) {
    if (points.length < 3) return 0.0;

    double totalDeviation = 0.0;
    
    // Вычисляем отклонение от прямой линии
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      
      // Вычисляем ожидаемую позицию точки на прямой линии
      const t = 0.5; // средняя точка
      final expectedX = prev.dx + t * (next.dx - prev.dx);
      final expectedY = prev.dy + t * (next.dy - prev.dy);
      
      // Вычисляем отклонение
      final deviation = math.sqrt(
        math.pow(current.dx - expectedX, 2) + math.pow(current.dy - expectedY, 2)
      );
      
      totalDeviation += deviation;
    }
    
    // Нормализуем отклонение (чем меньше, тем лучше)
    final averageDeviation = totalDeviation / (points.length - 2);
    return math.max(0.0, 1.0 - averageDeviation / 50);
  }

  /// Генерирует обратную связь
  static String _generateFeedback(
    double accuracy,
    List<String> errors,
    List<String> warnings,
  ) {
    if (errors.isNotEmpty) {
      return errors.first;
    }
    
    if (warnings.isNotEmpty) {
      return warnings.first;
    }
    
    if (accuracy >= 0.9) {
      return 'Отличная техника!';
    } else if (accuracy >= 0.8) {
      return 'Хорошая техника';
    } else if (accuracy >= 0.6) {
      return 'Техника требует улучшения';
    } else {
      return 'Проверьте технику выполнения';
    }
  }
}

/// Результат анализа упражнения
class ExerciseAnalysis {
  final bool isCorrect;
  final double accuracy;
  final String feedback;
  final List<String> criticalErrors;
  final List<String> warnings;

  const ExerciseAnalysis({
    required this.isCorrect,
    required this.accuracy,
    required this.feedback,
    this.criticalErrors = const [],
    this.warnings = const [],
  });
}