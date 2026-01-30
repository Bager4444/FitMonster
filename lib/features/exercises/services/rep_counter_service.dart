import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pose_detection_service.dart';

/// Сервис для автоматического подсчета повторений упражнений
/// Анализирует фазы движения и определяет завершенные повторения
class RepCounterService {
  static const double _movementThreshold = 0.15;
  static const int _minFramesBetweenReps = 10; // Минимум кадров между повторениями
  
  // Состояние для отслеживания фаз движения
  final Map<String, _ExerciseState> _exerciseStates = {};
  
  /// Анализирует кадр и обновляет счетчик повторений
  RepCountResult analyzeFrame(List<BodyKeypoint> keypoints, String exerciseType) {
    if (keypoints.isEmpty) {
      return RepCountResult(
        repCount: _getRepCount(exerciseType),
        currentPhase: ExercisePhase.unknown,
        feedback: 'Встаньте в кадр',
      );
    }

    // Получаем или создаем состояние упражнения
    final state = _exerciseStates.putIfAbsent(
      exerciseType, 
      () => _ExerciseState(),
    );

    // Анализируем фазу движения в зависимости от типа упражнения
    final phaseResult = _analyzeExercisePhase(keypoints, exerciseType, state);
    
    // Обновляем состояние
    state.updatePhase(phaseResult.phase, phaseResult.keyMetric);
    
    // Проверяем завершение повторения
    if (state.isRepCompleted()) {
      state.incrementRep();
    }

    return RepCountResult(
      repCount: state.repCount,
      currentPhase: state.currentPhase,
      feedback: phaseResult.feedback,
      keyMetric: phaseResult.keyMetric,
    );
  }

  /// Анализирует фазу упражнения
  _PhaseAnalysisResult _analyzeExercisePhase(
    List<BodyKeypoint> keypoints, 
    String exerciseType, 
    _ExerciseState state,
  ) {
    switch (exerciseType) {
      case 'squats':
      case 'jump_squats':
      case 'sumo_squats':
        return _analyzeSquatPhase(keypoints, state);
      case 'pushups':
      case 'knee_pushups':
      case 'burpees':
      case 'burpee_pushup':
        return _analyzePushupPhase(keypoints, state);
      case 'lunges':
      case 'reverse_lunges':
        return _analyzeLungePhase(keypoints, state);
      case 'plank':
      case 'side_plank':
      case 'plank_leg_lifts':
        return _analyzePlankPhase(keypoints, state);
      case 'jumping_jacks':
      case 'high_knees':
      case 'running_in_place':
        return _analyzeCardioPhase(keypoints, state);
      case 'mountain_climbers':
        return _analyzeMountainClimberPhase(keypoints, state);
      case 'leg_raises':
      case 'reverse_crunches':
        return _analyzeLegRaisePhase(keypoints, state);
      case 'crunches':
      case 'bicycle_crunches':
        return _analyzeCrunchPhase(keypoints, state);
      case 'calf_raises':
        return _analyzeCalfRaisePhase(keypoints, state);
      case 'superman':
        return _analyzeSupermanPhase(keypoints, state);
      case 'glute_bridge':
        return _analyzeGluteBridgePhase(keypoints, state);
      case 'jump_rope':
        return _analyzeJumpRopePhase(keypoints, state);
      case 'downward_dog':
        return _analyzeYogaPhase(keypoints, state);
      default:
        return _PhaseAnalysisResult(
          phase: ExercisePhase.unknown,
          feedback: 'Упражнение не поддерживается',
          keyMetric: 0.0,
        );
    }
  }

  /// Анализ фазы приседаний
  _PhaseAnalysisResult _analyzeSquatPhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    // Находим ключевые точки для приседаний
    final leftHip = keypoints.where((k) => k.type == KeypointType.leftHip).firstOrNull;
    final leftKnee = keypoints.where((k) => k.type == KeypointType.leftKnee).firstOrNull;
    final leftAnkle = keypoints.where((k) => k.type == KeypointType.leftAnkle).firstOrNull;

    if (leftHip == null || leftKnee == null || leftAnkle == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Встаньте боком к камере',
        keyMetric: 0.0,
      );
    }

    // Вычисляем угол в колене
    final kneeAngle = _calculateAngle(leftHip.position, leftKnee.position, leftAnkle.position);
    
    // Определяем фазу на основе угла колена
    ExercisePhase phase;
    String feedback;

    if (kneeAngle > 150) {
      phase = ExercisePhase.starting;
      feedback = 'Начальная позиция';
    } else if (kneeAngle > 120) {
      phase = ExercisePhase.descending;
      feedback = 'Опускайтесь';
    } else if (kneeAngle >= 80 && kneeAngle <= 120) {
      phase = ExercisePhase.bottom;
      feedback = 'Нижняя точка';
    } else if (kneeAngle > 120) {
      phase = ExercisePhase.ascending;
      feedback = 'Поднимайтесь';
    } else {
      phase = ExercisePhase.unknown;
      feedback = 'Проверьте технику';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: kneeAngle,
    );
  }

  /// Анализ фазы отжиманий
  _PhaseAnalysisResult _analyzePushupPhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    // Находим ключевые точки для отжиманий
    final leftShoulder = keypoints.where((k) => k.type == KeypointType.leftShoulder).firstOrNull;
    final leftElbow = keypoints.where((k) => k.type == KeypointType.leftElbow).firstOrNull;
    final leftWrist = keypoints.where((k) => k.type == KeypointType.leftWrist).firstOrNull;

    if (leftShoulder == null || leftElbow == null || leftWrist == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Встаньте боком к камере',
        keyMetric: 0.0,
      );
    }

    // Вычисляем угол в локте
    final elbowAngle = _calculateAngle(leftShoulder.position, leftElbow.position, leftWrist.position);
    
    // Определяем фазу на основе угла локтя
    ExercisePhase phase;
    String feedback;

    if (elbowAngle > 150) {
      phase = ExercisePhase.starting;
      feedback = 'Исходная позиция';
    } else if (elbowAngle > 120) {
      phase = ExercisePhase.descending;
      feedback = 'Опускайтесь';
    } else if (elbowAngle >= 80 && elbowAngle <= 120) {
      phase = ExercisePhase.bottom;
      feedback = 'Нижняя точка';
    } else if (elbowAngle > 120) {
      phase = ExercisePhase.ascending;
      feedback = 'Поднимайтесь';
    } else {
      phase = ExercisePhase.unknown;
      feedback = 'Проверьте технику';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: elbowAngle,
    );
  }

  /// Анализ фазы выпадов
  _PhaseAnalysisResult _analyzeLungePhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    // Находим ключевые точки для выпадов
    final leftHip = keypoints.where((k) => k.type == KeypointType.leftHip).firstOrNull;
    final leftKnee = keypoints.where((k) => k.type == KeypointType.leftKnee).firstOrNull;
    final leftAnkle = keypoints.where((k) => k.type == KeypointType.leftAnkle).firstOrNull;

    if (leftHip == null || leftKnee == null || leftAnkle == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Встаньте боком к камере',
        keyMetric: 0.0,
      );
    }

    // Вычисляем высоту бедра (Y координата)
    final hipHeight = leftHip.position.dy;
    
    // Определяем фазу на основе высоты бедра
    ExercisePhase phase;
    String feedback;

    // Используем относительную высоту (нормализованную)
    if (hipHeight < 0.4) {
      phase = ExercisePhase.starting;
      feedback = 'Исходная позиция';
    } else if (hipHeight < 0.6) {
      phase = ExercisePhase.descending;
      feedback = 'Опускайтесь в выпад';
    } else if (hipHeight >= 0.6 && hipHeight <= 0.8) {
      phase = ExercisePhase.bottom;
      feedback = 'Нижняя точка выпада';
    } else if (hipHeight < 0.6) {
      phase = ExercisePhase.ascending;
      feedback = 'Возвращайтесь';
    } else {
      phase = ExercisePhase.unknown;
      feedback = 'Проверьте технику';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: hipHeight,
    );
  }

  /// Анализ планки (статическое упражнение)
  _PhaseAnalysisResult _analyzePlankPhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    // Для планки считаем время удержания, а не повторения
    final leftShoulder = keypoints.where((k) => k.type == KeypointType.leftShoulder).firstOrNull;
    final leftHip = keypoints.where((k) => k.type == KeypointType.leftHip).firstOrNull;
    final leftAnkle = keypoints.where((k) => k.type == KeypointType.leftAnkle).firstOrNull;

    if (leftShoulder == null || leftHip == null || leftAnkle == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Встаньте боком к камере',
        keyMetric: 0.0,
      );
    }

    // Проверяем прямую линию тела
    final bodyLineAccuracy = _checkBodyLine([
      leftShoulder.position,
      leftHip.position,
      leftAnkle.position,
    ]);

    ExercisePhase phase;
    String feedback;

    if (bodyLineAccuracy > 0.8) {
      phase = ExercisePhase.holding;
      feedback = 'Отлично! Держите позицию';
    } else if (bodyLineAccuracy > 0.6) {
      phase = ExercisePhase.holding;
      feedback = 'Выпрямите тело';
    } else {
      phase = ExercisePhase.unknown;
      feedback = 'Проверьте технику планки';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: bodyLineAccuracy,
    );
  }

  /// Анализ кардио упражнений (джампинг джекс, высокие колени, бег на месте)
  _PhaseAnalysisResult _analyzeCardioPhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    final leftKnee = keypoints.where((k) => k.type == KeypointType.leftKnee).firstOrNull;
    final rightKnee = keypoints.where((k) => k.type == KeypointType.rightKnee).firstOrNull;
    final leftHip = keypoints.where((k) => k.type == KeypointType.leftHip).firstOrNull;

    if (leftKnee == null || rightKnee == null || leftHip == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Встаньте лицом к камере',
        keyMetric: 0.0,
      );
    }

    // Определяем активность по движению коленей
    final leftKneeHeight = leftHip.position.dy - leftKnee.position.dy;
    final rightKneeHeight = leftHip.position.dy - rightKnee.position.dy;
    final maxKneeHeight = math.max(leftKneeHeight, rightKneeHeight);

    ExercisePhase phase;
    String feedback;

    if (maxKneeHeight > 0.15) {
      phase = ExercisePhase.ascending;
      feedback = 'Отлично! Поднимайте колени выше';
    } else if (maxKneeHeight > 0.1) {
      phase = ExercisePhase.descending;
      feedback = 'Поднимайте колени выше';
    } else {
      phase = ExercisePhase.starting;
      feedback = 'Начните движение';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: maxKneeHeight,
    );
  }

  /// Анализ горных альпинистов
  _PhaseAnalysisResult _analyzeMountainClimberPhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    final leftKnee = keypoints.where((k) => k.type == KeypointType.leftKnee).firstOrNull;
    final rightKnee = keypoints.where((k) => k.type == KeypointType.rightKnee).firstOrNull;
    final leftShoulder = keypoints.where((k) => k.type == KeypointType.leftShoulder).firstOrNull;

    if (leftKnee == null || rightKnee == null || leftShoulder == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Встаньте боком к камере',
        keyMetric: 0.0,
      );
    }

    // Проверяем подтягивание коленей к груди
    final leftKneeDistance = (leftKnee.position - leftShoulder.position).distance;
    final rightKneeDistance = (rightKnee.position - leftShoulder.position).distance;
    final minDistance = math.min(leftKneeDistance, rightKneeDistance);

    ExercisePhase phase;
    String feedback;

    if (minDistance < 0.3) {
      phase = ExercisePhase.bottom;
      feedback = 'Отлично! Подтягивайте колени';
    } else if (minDistance < 0.5) {
      phase = ExercisePhase.descending;
      feedback = 'Подтягивайте колени ближе';
    } else {
      phase = ExercisePhase.starting;
      feedback = 'Начните подтягивать колени';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: minDistance,
    );
  }

  /// Анализ подъемов ног
  _PhaseAnalysisResult _analyzeLegRaisePhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    final leftAnkle = keypoints.where((k) => k.type == KeypointType.leftAnkle).firstOrNull;
    final leftHip = keypoints.where((k) => k.type == KeypointType.leftHip).firstOrNull;

    if (leftAnkle == null || leftHip == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Лягте на спину лицом к камере',
        keyMetric: 0.0,
      );
    }

    // Определяем высоту ног относительно бедер
    final legHeight = leftHip.position.dy - leftAnkle.position.dy;

    ExercisePhase phase;
    String feedback;

    if (legHeight > 0.4) {
      phase = ExercisePhase.bottom;
      feedback = 'Отлично! Ноги подняты';
    } else if (legHeight > 0.2) {
      phase = ExercisePhase.ascending;
      feedback = 'Поднимайте ноги выше';
    } else {
      phase = ExercisePhase.starting;
      feedback = 'Поднимите ноги';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: legHeight,
    );
  }

  /// Анализ скручиваний
  _PhaseAnalysisResult _analyzeCrunchPhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    final leftShoulder = keypoints.where((k) => k.type == KeypointType.leftShoulder).firstOrNull;
    final leftHip = keypoints.where((k) => k.type == KeypointType.leftHip).firstOrNull;

    if (leftShoulder == null || leftHip == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Лягте на спину боком к камере',
        keyMetric: 0.0,
      );
    }

    // Определяем подъем корпуса
    final torsoAngle = math.atan2(
      leftShoulder.position.dy - leftHip.position.dy,
      leftShoulder.position.dx - leftHip.position.dx,
    ) * 180 / math.pi;

    ExercisePhase phase;
    String feedback;

    if (torsoAngle > 30) {
      phase = ExercisePhase.bottom;
      feedback = 'Отлично! Корпус поднят';
    } else if (torsoAngle > 15) {
      phase = ExercisePhase.ascending;
      feedback = 'Поднимайте корпус';
    } else {
      phase = ExercisePhase.starting;
      feedback = 'Начните скручивание';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: torsoAngle,
    );
  }

  /// Анализ подъемов на носки
  _PhaseAnalysisResult _analyzeCalfRaisePhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    final leftAnkle = keypoints.where((k) => k.type == KeypointType.leftAnkle).firstOrNull;
    final leftKnee = keypoints.where((k) => k.type == KeypointType.leftKnee).firstOrNull;

    if (leftAnkle == null || leftKnee == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Встаньте боком к камере',
        keyMetric: 0.0,
      );
    }

    // Определяем подъем на носки по изменению высоты
    final ankleHeight = leftKnee.position.dy - leftAnkle.position.dy;

    ExercisePhase phase;
    String feedback;

    if (ankleHeight > 0.35) {
      phase = ExercisePhase.bottom;
      feedback = 'Отлично! На носках';
    } else if (ankleHeight > 0.3) {
      phase = ExercisePhase.ascending;
      feedback = 'Поднимайтесь выше';
    } else {
      phase = ExercisePhase.starting;
      feedback = 'Поднимитесь на носки';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: ankleHeight,
    );
  }

  /// Анализ упражнения "Супермен"
  _PhaseAnalysisResult _analyzeSupermanPhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    final leftShoulder = keypoints.where((k) => k.type == KeypointType.leftShoulder).firstOrNull;
    final leftHip = keypoints.where((k) => k.type == KeypointType.leftHip).firstOrNull;
    final leftAnkle = keypoints.where((k) => k.type == KeypointType.leftAnkle).firstOrNull;

    if (leftShoulder == null || leftHip == null || leftAnkle == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Лягте на живот боком к камере',
        keyMetric: 0.0,
      );
    }

    // Проверяем подъем корпуса и ног
    final bodyArch = _calculateBodyArch([
      leftShoulder.position,
      leftHip.position,
      leftAnkle.position,
    ]);

    ExercisePhase phase;
    String feedback;

    if (bodyArch > 0.15) {
      phase = ExercisePhase.holding;
      feedback = 'Отлично! Держите позицию';
    } else if (bodyArch > 0.1) {
      phase = ExercisePhase.ascending;
      feedback = 'Поднимайте выше';
    } else {
      phase = ExercisePhase.starting;
      feedback = 'Поднимите корпус и ноги';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: bodyArch,
    );
  }

  /// Анализ ягодичного мостика
  _PhaseAnalysisResult _analyzeGluteBridgePhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    final leftShoulder = keypoints.where((k) => k.type == KeypointType.leftShoulder).firstOrNull;
    final leftHip = keypoints.where((k) => k.type == KeypointType.leftHip).firstOrNull;
    final leftKnee = keypoints.where((k) => k.type == KeypointType.leftKnee).firstOrNull;

    if (leftShoulder == null || leftHip == null || leftKnee == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Лягте на спину боком к камере',
        keyMetric: 0.0,
      );
    }

    // Определяем подъем таза
    final hipHeight = leftShoulder.position.dy - leftHip.position.dy;

    ExercisePhase phase;
    String feedback;

    if (hipHeight < -0.1) {
      phase = ExercisePhase.bottom;
      feedback = 'Отлично! Таз поднят';
    } else if (hipHeight < 0) {
      phase = ExercisePhase.ascending;
      feedback = 'Поднимайте таз выше';
    } else {
      phase = ExercisePhase.starting;
      feedback = 'Поднимите таз';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: hipHeight.abs(),
    );
  }

  /// Анализ прыжков со скакалкой
  _PhaseAnalysisResult _analyzeJumpRopePhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    final leftAnkle = keypoints.where((k) => k.type == KeypointType.leftAnkle).firstOrNull;
    final rightAnkle = keypoints.where((k) => k.type == KeypointType.rightAnkle).firstOrNull;

    if (leftAnkle == null || rightAnkle == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Встаньте лицом к камере',
        keyMetric: 0.0,
      );
    }

    // Определяем прыжки по движению стоп
    final avgAnkleHeight = (leftAnkle.position.dy + rightAnkle.position.dy) / 2;

    ExercisePhase phase;
    String feedback;

    if (avgAnkleHeight < 0.7) {
      phase = ExercisePhase.ascending;
      feedback = 'Отлично! Продолжайте прыжки';
    } else if (avgAnkleHeight < 0.8) {
      phase = ExercisePhase.descending;
      feedback = 'Прыгайте активнее';
    } else {
      phase = ExercisePhase.starting;
      feedback = 'Начните прыжки';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: avgAnkleHeight,
    );
  }

  /// Анализ йога-поз
  _PhaseAnalysisResult _analyzeYogaPhase(List<BodyKeypoint> keypoints, _ExerciseState state) {
    final leftShoulder = keypoints.where((k) => k.type == KeypointType.leftShoulder).firstOrNull;
    final leftHip = keypoints.where((k) => k.type == KeypointType.leftHip).firstOrNull;
    final leftAnkle = keypoints.where((k) => k.type == KeypointType.leftAnkle).firstOrNull;

    if (leftShoulder == null || leftHip == null || leftAnkle == null) {
      return _PhaseAnalysisResult(
        phase: ExercisePhase.unknown,
        feedback: 'Встаньте боком к камере',
        keyMetric: 0.0,
      );
    }

    // Проверяем треугольную позу
    final triangleAccuracy = _checkTrianglePose([
      leftShoulder.position,
      leftHip.position,
      leftAnkle.position,
    ]);

    ExercisePhase phase;
    String feedback;

    if (triangleAccuracy > 0.8) {
      phase = ExercisePhase.holding;
      feedback = 'Отлично! Держите позу';
    } else if (triangleAccuracy > 0.6) {
      phase = ExercisePhase.holding;
      feedback = 'Выровняйте позицию';
    } else {
      phase = ExercisePhase.unknown;
      feedback = 'Проверьте технику позы';
    }

    return _PhaseAnalysisResult(
      phase: phase,
      feedback: feedback,
      keyMetric: triangleAccuracy,
    );
  }

  /// Вычисляет угол между тремя точками
  double _calculateAngle(Offset a, Offset b, Offset c) {
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

  /// Проверяет прямую линию тела
  double _checkBodyLine(List<Offset> points) {
    if (points.length < 3) return 0.0;

    double totalDeviation = 0.0;
    
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      
      const t = 0.5;
      final expectedX = prev.dx + t * (next.dx - prev.dx);
      final expectedY = prev.dy + t * (next.dy - prev.dy);
      
      final deviation = math.sqrt(
        math.pow(current.dx - expectedX, 2) + math.pow(current.dy - expectedY, 2)
      );
      
      totalDeviation += deviation;
    }
    
    final averageDeviation = totalDeviation / (points.length - 2);
    return math.max(0.0, 1.0 - averageDeviation / 50);
  }

  /// Рассчитывает изгиб тела для упражнения "Супермен"
  double _calculateBodyArch(List<Offset> points) {
    if (points.length < 3) return 0.0;
    
    final shoulder = points[0];
    final hip = points[1];
    final ankle = points[2];
    
    // Рассчитываем отклонение бедра от прямой линии плечо-лодыжка
    final lineLength = (ankle - shoulder).distance;
    if (lineLength == 0) return 0.0;
    
    final t = (hip - shoulder).distance / lineLength;
    final expectedHip = Offset(
      shoulder.dx + t * (ankle.dx - shoulder.dx),
      shoulder.dy + t * (ankle.dy - shoulder.dy),
    );
    
    final deviation = (hip - expectedHip).distance;
    return deviation / 100; // Нормализуем
  }

  /// Проверяет треугольную позу для йоги
  double _checkTrianglePose(List<Offset> points) {
    if (points.length < 3) return 0.0;
    
    final shoulder = points[0];
    final hip = points[1];
    final ankle = points[2];
    
    // Проверяем углы треугольника
    final angle1 = _calculateAngle(hip, shoulder, ankle);
    final angle2 = _calculateAngle(shoulder, hip, ankle);
    final angle3 = _calculateAngle(shoulder, ankle, hip);
    
    // Идеальный треугольник для собаки мордой вниз
    final idealAngle1 = 60.0; // Примерный угол
    final idealAngle2 = 90.0;
    final idealAngle3 = 30.0;
    
    final deviation1 = (angle1 - idealAngle1).abs() / idealAngle1;
    final deviation2 = (angle2 - idealAngle2).abs() / idealAngle2;
    final deviation3 = (angle3 - idealAngle3).abs() / idealAngle3;
    
    final avgDeviation = (deviation1 + deviation2 + deviation3) / 3;
    return math.max(0.0, 1.0 - avgDeviation);
  }

  /// Получает текущий счетчик повторений
  int _getRepCount(String exerciseType) {
    return _exerciseStates[exerciseType]?.repCount ?? 0;
  }

  /// Сбрасывает счетчик для упражнения
  void resetCounter(String exerciseType) {
    _exerciseStates[exerciseType]?.reset();
  }

  /// Очищает все счетчики
  void clearAll() {
    _exerciseStates.clear();
  }
}

/// Состояние упражнения для отслеживания фаз
class _ExerciseState {
  ExercisePhase currentPhase = ExercisePhase.unknown;
  ExercisePhase previousPhase = ExercisePhase.unknown;
  int repCount = 0;
  int framesSinceLastRep = 0;
  double lastKeyMetric = 0.0;
  List<ExercisePhase> phaseHistory = [];

  void updatePhase(ExercisePhase newPhase, double keyMetric) {
    framesSinceLastRep++;
    
    if (newPhase != currentPhase) {
      previousPhase = currentPhase;
      currentPhase = newPhase;
      
      // Добавляем в историю фаз
      phaseHistory.add(newPhase);
      
      // Ограничиваем размер истории
      if (phaseHistory.length > 10) {
        phaseHistory.removeAt(0);
      }
    }
    
    lastKeyMetric = keyMetric;
  }

  bool isRepCompleted() {
    // Проверяем, что прошло достаточно кадров с последнего повторения
    if (framesSinceLastRep < RepCounterService._minFramesBetweenReps) {
      return false;
    }

    // Проверяем последовательность фаз для завершенного повторения
    if (phaseHistory.length >= 4) {
      final recentPhases = phaseHistory.sublist(phaseHistory.length - 4);
      
      // Ищем паттерн: starting -> descending -> bottom -> ascending
      return recentPhases.contains(ExercisePhase.starting) &&
             recentPhases.contains(ExercisePhase.descending) &&
             recentPhases.contains(ExercisePhase.bottom) &&
             recentPhases.contains(ExercisePhase.ascending);
    }
    
    return false;
  }

  void incrementRep() {
    repCount++;
    framesSinceLastRep = 0;
    phaseHistory.clear(); // Очищаем историю после засчитанного повторения
  }

  void reset() {
    currentPhase = ExercisePhase.unknown;
    previousPhase = ExercisePhase.unknown;
    repCount = 0;
    framesSinceLastRep = 0;
    lastKeyMetric = 0.0;
    phaseHistory.clear();
  }
}

/// Результат анализа фазы упражнения
class _PhaseAnalysisResult {
  final ExercisePhase phase;
  final String feedback;
  final double keyMetric;

  const _PhaseAnalysisResult({
    required this.phase,
    required this.feedback,
    required this.keyMetric,
  });
}

/// Результат подсчета повторений
class RepCountResult {
  final int repCount;
  final ExercisePhase currentPhase;
  final String feedback;
  final double? keyMetric;

  const RepCountResult({
    required this.repCount,
    required this.currentPhase,
    required this.feedback,
    this.keyMetric,
  });
}

/// Фазы выполнения упражнения
enum ExercisePhase {
  unknown,
  starting,      // Исходная позиция
  descending,    // Опускание
  bottom,        // Нижняя точка
  ascending,     // Подъем
  holding,       // Удержание (для планки)
}

extension ExercisePhaseExtension on ExercisePhase {
  String get displayName {
    switch (this) {
      case ExercisePhase.unknown:
        return 'Неизвестно';
      case ExercisePhase.starting:
        return 'Исходная позиция';
      case ExercisePhase.descending:
        return 'Опускание';
      case ExercisePhase.bottom:
        return 'Нижняя точка';
      case ExercisePhase.ascending:
        return 'Подъем';
      case ExercisePhase.holding:
        return 'Удержание';
    }
  }

  Color get color {
    switch (this) {
      case ExercisePhase.unknown:
        return Colors.grey;
      case ExercisePhase.starting:
        return Colors.blue;
      case ExercisePhase.descending:
        return Colors.orange;
      case ExercisePhase.bottom:
        return Colors.red;
      case ExercisePhase.ascending:
        return Colors.green;
      case ExercisePhase.holding:
        return Colors.purple;
    }
  }
}