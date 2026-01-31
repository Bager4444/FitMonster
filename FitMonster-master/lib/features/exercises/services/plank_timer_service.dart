import 'dart:async';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// 🕐 СЕРВИС ТАЙМЕРА ДЛЯ ПЛАНКИ
/// 
/// Специализированный сервис для точного подсчёта времени
/// удержания планки с улучшенной обратной связью
class PlankTimerService {
  // === СОСТОЯНИЕ ТАЙМЕРА ===
  Timer? _timer;
  DateTime? _startTime;
  Duration _totalTime = Duration.zero;
  Duration _currentHoldTime = Duration.zero;
  bool _isHolding = false;
  bool _isActive = false;
  
  // === НАСТРОЙКИ АНАЛИЗА ===
  static const double _minBodyLineAngle = 160.0; // Минимальный угол тела
  static const double _maxBodyLineAngle = 200.0; // Максимальный угол тела
  static const double _minConfidence = 0.6; // Минимальная уверенность
  static const double _maxMovement = 0.3; // Максимальное движение
  
  // === СТАТИСТИКА ===
  int _totalHolds = 0;
  Duration _longestHold = Duration.zero;
  List<Duration> _holdHistory = [];
  
  // === CALLBACKS ===
  Function(Duration)? onTimeUpdate;
  Function(String)? onFeedbackUpdate;
  Function(PlankStats)? onStatsUpdate;
  
  /// Запускает таймер планки
  void startTimer() {
    if (_isActive) return;
    
    _isActive = true;
    _startTime = DateTime.now();
    _totalTime = Duration.zero;
    _currentHoldTime = Duration.zero;
    
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _updateTimer();
    });
    
    print('🕐 Таймер планки запущен');
  }
  
  /// Останавливает таймер планки
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    
    if (_isHolding) {
      _finishCurrentHold();
    }
    
    print('⏹️ Таймер планки остановлен');
  }
  
  /// Сбрасывает таймер
  void resetTimer() {
    stopTimer();
    _totalTime = Duration.zero;
    _currentHoldTime = Duration.zero;
    _isHolding = false;
    _totalHolds = 0;
    _longestHold = Duration.zero;
    _holdHistory.clear();
    
    onTimeUpdate?.call(_totalTime);
    onFeedbackUpdate?.call('Готов к началу!');
    onStatsUpdate?.call(_getStats());
    
    print('🔄 Таймер планки сброшен');
  }
  
  /// Анализирует позу и обновляет таймер
  PlankAnalysisResult analyzePose(Pose pose) {
    if (!_isActive) {
      return PlankAnalysisResult(
        isCorrectPosition: false,
        totalTime: _totalTime,
        currentHoldTime: _currentHoldTime,
        feedback: 'Нажмите "Старт" для начала',
        confidence: 0.0,
        bodyLineAngle: 0.0,
      );
    }
    
    // Анализируем позу планки
    final analysis = _analyzePlankPose(pose);
    
    // Обновляем состояние удержания
    _updateHoldingState(analysis.isCorrectPosition);
    
    // Генерируем обратную связь
    final feedback = _generateFeedback(analysis);
    
    // Обновляем callbacks
    onFeedbackUpdate?.call(feedback);
    onStatsUpdate?.call(_getStats());
    
    return PlankAnalysisResult(
      isCorrectPosition: analysis.isCorrectPosition,
      totalTime: _totalTime,
      currentHoldTime: _currentHoldTime,
      feedback: feedback,
      confidence: analysis.confidence,
      bodyLineAngle: analysis.bodyLineAngle,
    );
  }
  
  /// Обновляет таймер каждые 100мс
  void _updateTimer() {
    if (!_isActive || _startTime == null) return;
    
    final now = DateTime.now();
    final elapsed = now.difference(_startTime!);
    
    if (_isHolding) {
      _totalTime = elapsed;
      _currentHoldTime = elapsed;
    }
    
    onTimeUpdate?.call(_totalTime);
  }
  
  /// Анализирует позу планки
  _PlankPoseAnalysis _analyzePlankPose(Pose pose) {
    if (pose.landmarks.isEmpty) {
      return _PlankPoseAnalysis(
        isCorrectPosition: false,
        confidence: 0.0,
        bodyLineAngle: 0.0,
        issues: ['Поза не обнаружена'],
      );
    }
    
    final issues = <String>[];
    
    // Получаем ключевые точки
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    
    // Проверяем наличие ключевых точек
    if (leftShoulder == null || rightShoulder == null || 
        leftHip == null || rightHip == null) {
      return _PlankPoseAnalysis(
        isCorrectPosition: false,
        confidence: 0.0,
        bodyLineAngle: 0.0,
        issues: ['Встаньте в кадр полностью'],
      );
    }
    
    // Рассчитываем уверенность
    final confidence = _calculateConfidence([
      leftShoulder, rightShoulder, leftHip, rightHip,
      leftAnkle, rightAnkle, leftElbow, rightElbow,
    ]);
    
    if (confidence < _minConfidence) {
      return _PlankPoseAnalysis(
        isCorrectPosition: false,
        confidence: confidence,
        bodyLineAngle: 0.0,
        issues: ['Улучшите освещение'],
      );
    }
    
    // Рассчитываем угол линии тела
    final bodyLineAngle = _calculateBodyLineAngle(
      leftShoulder, leftHip, leftAnkle ?? rightAnkle,
    );
    
    // Проверяем правильность позы
    bool isCorrect = true;
    
    // 1. Проверка линии тела
    if (bodyLineAngle < _minBodyLineAngle) {
      issues.add('Поднимите бёдра выше');
      isCorrect = false;
    } else if (bodyLineAngle > _maxBodyLineAngle) {
      issues.add('Опустите бёдра ниже');
      isCorrect = false;
    }
    
    // 2. Проверка положения локтей
    if (leftElbow != null && rightElbow != null) {
      final elbowAngle = _calculateElbowAngle(leftShoulder, leftElbow);
      if (elbowAngle < 80 || elbowAngle > 100) {
        issues.add('Держите локти под плечами');
        isCorrect = false;
      }
    }
    
    // 3. Проверка стабильности
    final movement = _calculateMovement(pose);
    if (movement > _maxMovement) {
      issues.add('Держитесь неподвижно');
      isCorrect = false;
    }
    
    return _PlankPoseAnalysis(
      isCorrectPosition: isCorrect,
      confidence: confidence,
      bodyLineAngle: bodyLineAngle,
      issues: issues,
    );
  }
  
  /// Обновляет состояние удержания
  void _updateHoldingState(bool isCorrectPosition) {
    if (isCorrectPosition && !_isHolding) {
      // Начинаем новое удержание
      _isHolding = true;
      _startTime = DateTime.now();
      _currentHoldTime = Duration.zero;
      print('✅ Начато удержание планки');
    } else if (!isCorrectPosition && _isHolding) {
      // Заканчиваем текущее удержание
      _finishCurrentHold();
    }
  }
  
  /// Завершает текущее удержание
  void _finishCurrentHold() {
    if (!_isHolding) return;
    
    _isHolding = false;
    _totalHolds++;
    
    // Сохраняем в историю
    _holdHistory.add(_currentHoldTime);
    
    // Обновляем рекорд
    if (_currentHoldTime > _longestHold) {
      _longestHold = _currentHoldTime;
    }
    
    print('⏹️ Завершено удержание: ${_currentHoldTime.inSeconds}с');
    _currentHoldTime = Duration.zero;
  }
  
  /// Генерирует обратную связь
  String _generateFeedback(_PlankPoseAnalysis analysis) {
    if (!analysis.isCorrectPosition) {
      if (analysis.issues.isNotEmpty) {
        return analysis.issues.first;
      }
      return 'Примите правильную позу планки';
    }
    
    // Мотивационные сообщения в зависимости от времени
    final seconds = _totalTime.inSeconds;
    
    if (seconds < 5) {
      return 'Отлично! Держите! 💪';
    } else if (seconds < 10) {
      return 'Супер! Продолжайте! 🔥';
    } else if (seconds < 20) {
      return 'Невероятно! Вы молодец! ⭐';
    } else if (seconds < 30) {
      return 'Фантастика! Почти рекорд! 🏆';
    } else if (seconds < 45) {
      return 'ЛЕГЕНДА! Вы невероятны! 👑';
    } else if (seconds < 60) {
      return 'МАСТЕР ПЛАНКИ! Это потрясающе! 🌟';
    } else {
      return 'АБСОЛЮТНЫЙ ЧЕМПИОН! 🥇✨';
    }
  }
  
  /// Рассчитывает уверенность детекции
  double _calculateConfidence(List<PoseLandmark?> landmarks) {
    final validLandmarks = landmarks.where((l) => l != null).toList();
    if (validLandmarks.isEmpty) return 0.0;
    
    final totalConfidence = validLandmarks
        .map((l) => l!.likelihood)
        .reduce((a, b) => a + b);
    
    return totalConfidence / validLandmarks.length;
  }
  
  /// Рассчитывает угол линии тела
  double _calculateBodyLineAngle(
    PoseLandmark shoulder,
    PoseLandmark hip,
    PoseLandmark? ankle,
  ) {
    if (ankle == null) return 180.0;
    
    // Вектор от плеча к бедру
    final shoulderToHip = _Vector2D(
      hip.x - shoulder.x,
      hip.y - shoulder.y,
    );
    
    // Вектор от бедра к лодыжке
    final hipToAnkle = _Vector2D(
      ankle.x - hip.x,
      ankle.y - hip.y,
    );
    
    // Угол между векторами
    final dotProduct = shoulderToHip.x * hipToAnkle.x + shoulderToHip.y * hipToAnkle.y;
    final magnitude1 = shoulderToHip.magnitude;
    final magnitude2 = hipToAnkle.magnitude;
    
    if (magnitude1 == 0 || magnitude2 == 0) return 180.0;
    
    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final angleRad = math.acos(cosAngle.clamp(-1.0, 1.0));
    final angleDeg = angleRad * 180 / math.pi;
    
    return 180 - angleDeg; // Инвертируем для правильного отображения
  }
  
  /// Рассчитывает угол локтя
  double _calculateElbowAngle(PoseLandmark shoulder, PoseLandmark elbow) {
    // Упрощённый расчёт - угол между плечом и локтем относительно вертикали
    final deltaY = (shoulder.y - elbow.y).abs();
    final deltaX = (shoulder.x - elbow.x).abs();
    
    if (deltaX == 0) return 90.0;
    
    final angleRad = math.atan(deltaY / deltaX);
    return angleRad * 180 / math.pi;
  }
  
  /// Рассчитывает движение (стабильность)
  double _calculateMovement(Pose pose) {
    // Упрощённый расчёт движения на основе изменения позиций
    // В реальной реализации здесь был бы анализ предыдущих кадров
    return 0.1; // Заглушка
  }
  
  /// Получает текущую статистику
  PlankStats _getStats() {
    return PlankStats(
      totalTime: _totalTime,
      currentHoldTime: _currentHoldTime,
      totalHolds: _totalHolds,
      longestHold: _longestHold,
      averageHold: _calculateAverageHold(),
      isHolding: _isHolding,
    );
  }
  
  /// Рассчитывает среднее время удержания
  Duration _calculateAverageHold() {
    if (_holdHistory.isEmpty) return Duration.zero;
    
    final totalMs = _holdHistory
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return Duration(milliseconds: totalMs ~/ _holdHistory.length);
  }
  
  /// Получает текущее время
  Duration get currentTime => _totalTime;
  
  /// Проверяет, активен ли таймер
  bool get isActive => _isActive;
  
  /// Проверяет, удерживается ли планка
  bool get isHolding => _isHolding;
  
  /// Освобождает ресурсы
  void dispose() {
    stopTimer();
  }
}

/// Результат анализа планки
class PlankAnalysisResult {
  final bool isCorrectPosition;
  final Duration totalTime;
  final Duration currentHoldTime;
  final String feedback;
  final double confidence;
  final double bodyLineAngle;
  
  const PlankAnalysisResult({
    required this.isCorrectPosition,
    required this.totalTime,
    required this.currentHoldTime,
    required this.feedback,
    required this.confidence,
    required this.bodyLineAngle,
  });
}

/// Статистика планки
class PlankStats {
  final Duration totalTime;
  final Duration currentHoldTime;
  final int totalHolds;
  final Duration longestHold;
  final Duration averageHold;
  final bool isHolding;
  
  const PlankStats({
    required this.totalTime,
    required this.currentHoldTime,
    required this.totalHolds,
    required this.longestHold,
    required this.averageHold,
    required this.isHolding,
  });
}

/// Внутренний анализ позы планки
class _PlankPoseAnalysis {
  final bool isCorrectPosition;
  final double confidence;
  final double bodyLineAngle;
  final List<String> issues;
  
  const _PlankPoseAnalysis({
    required this.isCorrectPosition,
    required this.confidence,
    required this.bodyLineAngle,
    required this.issues,
  });
}

/// Вспомогательный класс для векторных вычислений
class _Vector2D {
  final double x;
  final double y;
  
  const _Vector2D(this.x, this.y);
  
  double get magnitude => math.sqrt(x * x + y * y);
}

// Импорт для математических функций
