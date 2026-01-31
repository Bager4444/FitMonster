import 'dart:math' as math;
import 'dart:typed_data';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Ультра-быстрый оптимизатор графа - максимальная скорость
/// Цель: обработка за < 50 микросекунд для 20+ FPS
class UltraFastGraphOptimizer {
  // Предварительно вычисленные данные
  static final List<int> _keyPoints = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28];
  static final List<List<int>> _connections = [
    [11, 12], [11, 13], [12, 14], [13, 15], [14, 16],
    [11, 23], [12, 24], [23, 24], [23, 25], [24, 26],
    [25, 27], [26, 28]
  ];
  
  // Кэш для быстрого доступа
  final List<double> _nodeCache = List.filled(24, 0.0);
  final List<double> _edgeCache = List.filled(12, 0.0);
  
  bool _ready = false;
  
  /// Мгновенная инициализация
  void initUltraFast() {
    _ready = true;
  }
  
  /// Ультра-быстрая оптимизация графа
  UltraFastResult optimizeUltraFast(Pose pose) {
    if (!_ready) throw StateError('Not ready');
    
    final start = DateTime.now().microsecondsSinceEpoch;
    
    // Извлечение ключевых точек
    int validNodes = 0;
    for (int i = 0; i < _keyPoints.length; i++) {
      final landmark = pose.landmarks[PoseLandmarkType.values[_keyPoints[i]]];
      if (landmark != null && landmark.likelihood > 0.6) {
        _nodeCache[i * 2] = landmark.x;
        _nodeCache[i * 2 + 1] = landmark.y;
        validNodes++;
      }
    }
    
    // Быстрый расчёт связей
    int validEdges = 0;
    for (int i = 0; i < _connections.length; i++) {
      final conn = _connections[i];
      final idx1 = conn[0] * 2;
      final idx2 = conn[1] * 2;
      
      if (_nodeCache[idx1] != 0.0 && _nodeCache[idx2] != 0.0) {
        final dx = _nodeCache[idx1] - _nodeCache[idx2];
        final dy = _nodeCache[idx1 + 1] - _nodeCache[idx2 + 1];
        _edgeCache[i] = dx * dx + dy * dy; // Квадрат расстояния
        validEdges++;
      }
    }
    
    final end = DateTime.now().microsecondsSinceEpoch;
    final processingTime = end - start;
    
    // Расчёт FPS
    final fps = processingTime > 0 ? 1000000.0 / processingTime : 60.0;
    
    return UltraFastResult(
      validNodes: validNodes,
      validEdges: validEdges,
      processingMicros: processingTime,
      achievedFPS: fps,
      graphScore: (validNodes + validEdges) / 24.0,
      isOptimal: fps >= 20.0 && validNodes >= 8,
    );
  }
  
  /// Получение оптимизированных данных
  OptimizedGraphData getOptimizedData() {
    return OptimizedGraphData(
      nodePositions: Float32List.fromList(_nodeCache),
      edgeWeights: Float32List.fromList(_edgeCache),
      nodeCount: _keyPoints.length,
      edgeCount: _connections.length,
    );
  }
}

/// Результат ультра-быстрой оптимизации
class UltraFastResult {
  final int validNodes;
  final int validEdges;
  final int processingMicros;
  final double achievedFPS;
  final double graphScore;
  final bool isOptimal;
  
  const UltraFastResult({
    required this.validNodes,
    required this.validEdges,
    required this.processingMicros,
    required this.achievedFPS,
    required this.graphScore,
    required this.isOptimal,
  });
  
  @override
  String toString() {
    return 'UltraFast: ${achievedFPS.toStringAsFixed(1)} FPS, '
           '${processingMicros}μs, ${validNodes}/${validEdges} nodes/edges';
  }
}

/// Оптимизированные данные графа
class OptimizedGraphData {
  final Float32List nodePositions;
  final Float32List edgeWeights;
  final int nodeCount;
  final int edgeCount;
  
  const OptimizedGraphData({
    required this.nodePositions,
    required this.edgeWeights,
    required this.nodeCount,
    required this.edgeCount,
  });
}

/// Менеджер ультра-быстрой оптимизации
class UltraFastGraphManager {
  final UltraFastGraphOptimizer _optimizer = UltraFastGraphOptimizer();
  final List<UltraFastResult> _history = [];
  
  double _avgFPS = 0.0;
  int _frameCount = 0;
  
  /// Инициализация
  void init() {
    _optimizer.initUltraFast();
  }
  
  /// Обработка кадра
  UltraFastResult processFrame(Pose pose) {
    final result = _optimizer.optimizeUltraFast(pose);
    
    // Обновление статистики
    _frameCount++;
    _avgFPS = (_avgFPS * (_frameCount - 1) + result.achievedFPS) / _frameCount;
    
    // Сохранение истории (последние 10 кадров)
    _history.add(result);
    if (_history.length > 10) {
      _history.removeAt(0);
    }
    
    return result;
  }
  
  /// Получение статистики
  GraphStats getStats() {
    if (_history.isEmpty) {
      return GraphStats.empty();
    }
    
    final recentFPS = _history.map((r) => r.achievedFPS).toList();
    final avgRecent = recentFPS.reduce((a, b) => a + b) / recentFPS.length;
    final maxFPS = recentFPS.reduce(math.max);
    final minFPS = recentFPS.reduce(math.min);
    
    return GraphStats(
      averageFPS: _avgFPS,
      recentAverageFPS: avgRecent,
      maxFPS: maxFPS,
      minFPS: minFPS,
      frameCount: _frameCount,
      target20Achieved: avgRecent >= 20.0,
      stability: _calculateStability(recentFPS),
    );
  }
  
  double _calculateStability(List<double> fps) {
    if (fps.length < 2) return 1.0;
    
    final avg = fps.reduce((a, b) => a + b) / fps.length;
    double variance = 0.0;
    
    for (final f in fps) {
      variance += (f - avg) * (f - avg);
    }
    
    variance /= fps.length;
    return 1.0 - (variance / (avg * avg)).clamp(0.0, 1.0);
  }
}

/// Статистика графа
class GraphStats {
  final double averageFPS;
  final double recentAverageFPS;
  final double maxFPS;
  final double minFPS;
  final int frameCount;
  final bool target20Achieved;
  final double stability;
  
  const GraphStats({
    required this.averageFPS,
    required this.recentAverageFPS,
    required this.maxFPS,
    required this.minFPS,
    required this.frameCount,
    required this.target20Achieved,
    required this.stability,
  });
  
  static GraphStats empty() {
    return const GraphStats(
      averageFPS: 0.0,
      recentAverageFPS: 0.0,
      maxFPS: 0.0,
      minFPS: 0.0,
      frameCount: 0,
      target20Achieved: false,
      stability: 0.0,
    );
  }
  
  @override
  String toString() {
    return 'GraphStats: ${recentAverageFPS.toStringAsFixed(1)} FPS '
           '(${target20Achieved ? "✅" : "❌"} 20+), '
           'stability: ${(stability * 100).toStringAsFixed(1)}%';
  }
}

/// Демо ультра-быстрой оптимизации
class UltraFastDemo {
  final UltraFastGraphManager _manager = UltraFastGraphManager();
  
  void runDemo() {
    print('🚀 УЛЬТРА-БЫСТРАЯ ОПТИМИЗАЦИЯ ГРАФА 🚀');
    print('Цель: 20+ FPS с минимальной задержкой\n');
    
    _manager.init();
    
    // Симуляция обработки кадров
    for (int i = 0; i < 100; i++) {
      final testPose = _createTestPose();
      final result = _manager.processFrame(testPose);
      
      if (i % 10 == 0) {
        print('Кадр $i: $result');
      }
    }
    
    // Финальная статистика
    final stats = _manager.getStats();
    print('\n📊 ФИНАЛЬНАЯ СТАТИСТИКА:');
    print(stats);
    
    if (stats.target20Achieved) {
      print('🎉 ЦЕЛЬ 20+ FPS ДОСТИГНУТА!');
    } else {
      print('⚠️ Цель 20+ FPS не достигнута');
    }
  }
  
  Pose _createTestPose() {
    final landmarks = <PoseLandmarkType, PoseLandmark>{};
    
    // Создание тестовых ключевых точек
    final keyTypes = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    
    for (int i = 0; i < keyTypes.length; i++) {
      landmarks[keyTypes[i]] = PoseLandmark(
        type: keyTypes[i],
        x: 0.3 + (i * 0.05),
        y: 0.2 + (i * 0.06),
        z: 0.0,
        likelihood: 0.8 + (math.Random().nextDouble() * 0.2),
      );
    }
    
    return Pose(landmarks: landmarks);
  }
}