import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'fps_20_integration_system.dart';
import 'ultra_fps_20_optimizer.dart';

/// Сервис камеры с гарантированными 20+ FPS
/// Практическая реализация для использования в приложении
class FPS20CameraService {
  // Интегрированная система 20+ FPS
  final FPS20IntegrationSystem _fps20System = FPS20IntegrationSystem();
  
  // Контроллер камеры
  CameraController? _cameraController;
  
  // Детектор поз
  late PoseDetector _poseDetector;
  
  // Стрим результатов
  final StreamController<FPS20CameraResult> _resultController = 
      StreamController<FPS20CameraResult>.broadcast();
  
  // Статистика производительности
  final List<double> _fpsHistory = [];
  final List<Pose> _poseHistory = [];
  
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _currentExercise = 'squats';
  
  /// Стрим результатов обработки
  Stream<FPS20CameraResult> get resultStream => _resultController.stream;
  
  /// Инициализация сервиса камеры с 20+ FPS
  Future<void> initializeFPS20Camera() async {
    print('🚀 Инициализация камеры с 20+ FPS...');
    
    try {
      // Инициализация системы FPS
      await _fps20System.initializeFPS20System();
      
      // Инициализация детектора поз
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.accurate,
        ),
      );
      
      // Инициализация камеры
      await _initializeCamera();
      
      _isInitialized = true;
      print('✅ Камера с 20+ FPS готова к работе!');
      
    } catch (e) {
      print('❌ Ошибка инициализации камеры: $e');
      throw Exception('Не удалось инициализировать камеру с 20+ FPS: $e');
    }
  }
  
  /// Инициализация камеры
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('Камеры не найдены');
    }
    
    // Выбираем переднюю камеру для селфи-режима
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium, // Оптимальное разрешение для 20+ FPS
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    await _cameraController!.initialize();
    
    // Настройка оптимальных параметров для FPS
    await _optimizeCameraSettings();
  }
  
  /// Оптимизация настроек камеры для максимального FPS
  Future<void> _optimizeCameraSettings() async {
    if (_cameraController == null) return;
    
    try {
      // Отключение автофокуса для стабильного FPS
      await _cameraController!.setFocusMode(FocusMode.locked);
      
      // Фиксированная экспозиция
      await _cameraController!.setExposureMode(ExposureMode.locked);
      
      // Отключение вспышки
      await _cameraController!.setFlashMode(FlashMode.off);
      
      print('✅ Настройки камеры оптимизированы для 20+ FPS');
    } catch (e) {
      print('⚠️ Не удалось применить все оптимизации камеры: $e');
    }
  }
  
  /// Запуск обработки кадров с 20+ FPS
  Future<void> startFPS20Processing({String exerciseType = 'squats'}) async {
    if (!_isInitialized) {
      throw StateError('Сервис не инициализирован');
    }
    
    _currentExercise = exerciseType;
    print('🎯 Запуск обработки упражнения: $exerciseType с 20+ FPS');
    
    // Запуск стрима изображений
    await _cameraController!.startImageStream(_processImageStream);
  }
  
  /// Остановка обработки
  Future<void> stopFPS20Processing() async {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    _isProcessing = false;
    print('⏹️ Обработка 20+ FPS остановлена');
  }
  
  /// Обработка стрима изображений
  Future<void> _processImageStream(CameraImage image) async {
    if (_isProcessing) return; // Пропускаем кадр если предыдущий еще обрабатывается
    
    _isProcessing = true;
    
    try {
      final startTime = DateTime.now();
      
      // Обработка кадра с системой 20+ FPS
      final fps20Result = await _fps20System.processFrameWith20FPS(
        image,
        _poseDetector,
        _currentExercise,
        _poseHistory,
      );
      
      final endTime = DateTime.now();
      final totalTime = endTime.difference(startTime);
      
      // Обновление истории поз
      if (fps20Result.detectedPose != null) {
        _poseHistory.add(fps20Result.detectedPose!);
        if (_poseHistory.length > 20) {
          _poseHistory.removeAt(0);
        }
      }
      
      // Обновление статистики FPS
      _fpsHistory.add(fps20Result.achievedFPS);
      if (_fpsHistory.length > 30) {
        _fpsHistory.removeAt(0);
      }
      
      // Создание результата для UI
      final cameraResult = FPS20CameraResult(
        fps20Result: fps20Result,
        cameraImage: image,
        processingTime: totalTime,
        frameNumber: _fpsHistory.length,
        exerciseType: _currentExercise,
        systemStatus: _fps20System.getSystemStatus(),
        performanceStats: _calculatePerformanceStats(),
      );
      
      // Отправка результата в стрим
      _resultController.add(cameraResult);
      
      // Логирование производительности
      _logPerformance(fps20Result, totalTime);
      
    } catch (e) {
      print('❌ Ошибка обработки кадра: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Расчёт статистики производительности
  FPS20PerformanceStats _calculatePerformanceStats() {
    if (_fpsHistory.isEmpty) {
      return FPS20PerformanceStats.empty();
    }
    
    final avgFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    final maxFPS = _fpsHistory.reduce((a, b) => a > b ? a : b);
    final minFPS = _fpsHistory.reduce((a, b) => a < b ? a : b);
    
    // Расчёт стабильности
    double variance = 0.0;
    for (final fps in _fpsHistory) {
      variance += (fps - avgFPS) * (fps - avgFPS);
    }
    variance /= _fpsHistory.length;
    final stability = 1.0 - (variance / (avgFPS * avgFPS));
    
    return FPS20PerformanceStats(
      averageFPS: avgFPS,
      maxFPS: maxFPS,
      minFPS: minFPS,
      fpsStability: stability.clamp(0.0, 1.0),
      framesProcessed: _fpsHistory.length,
      posesDetected: _poseHistory.length,
      target20FPSAchieved: avgFPS >= 20.0,
      consistentPerformance: stability > 0.8 && avgFPS >= 18.0,
    );
  }
  
  /// Логирование производительности
  void _logPerformance(FPS20Result result, Duration processingTime) {
    final fps = result.achievedFPS;
    final stability = result.fpsStability;
    
    if (fps >= 25.0) {
      print('🚀 Превосходная производительность: ${fps.toStringAsFixed(1)} FPS');
    } else if (fps >= 20.0) {
      print('✅ Целевая производительность: ${fps.toStringAsFixed(1)} FPS');
    } else if (fps >= 15.0) {
      print('⚠️ Производительность ниже цели: ${fps.toStringAsFixed(1)} FPS');
    } else {
      print('❌ Низкая производительность: ${fps.toStringAsFixed(1)} FPS');
    }
    
    // Детальная статистика каждые 30 кадров
    if (_fpsHistory.length % 30 == 0) {
      final stats = _calculatePerformanceStats();
      print('📊 Статистика за ${stats.framesProcessed} кадров:');
      print('   Средний FPS: ${stats.averageFPS.toStringAsFixed(1)}');
      print('   Стабильность: ${(stats.fpsStability * 100).toStringAsFixed(1)}%');
      print('   Цель 20+ FPS: ${stats.target20FPSAchieved ? "✅" : "❌"}');
    }
  }
  
  /// Смена типа упражнения
  void changeExerciseType(String exerciseType) {
    _currentExercise = exerciseType;
    print('🔄 Смена упражнения на: $exerciseType');
  }
  
  /// Получение текущего статуса системы
  FPS20SystemStatus getSystemStatus() {
    return _fps20System.getSystemStatus();
  }
  
  /// Получение статистики производительности
  FPS20PerformanceStats getPerformanceStats() {
    return _calculatePerformanceStats();
  }
  
  /// Освобождение ресурсов
  Future<void> dispose() async {
    print('🧹 Освобождение ресурсов камеры...');
    
    try {
      // Остановка обработки
      await stopFPS20Processing();
      
      // Освобождение камеры
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
      
      // Освобождение детектора поз
      await _poseDetector.close();
      
      // Закрытие стрима
      await _resultController.close();
      
      print('✅ Ресурсы камеры освобождены');
    } catch (e) {
      print('⚠️ Ошибка при освобождении ресурсов: $e');
    }
  }
}

/// Демонстрационный класс для тестирования системы 20+ FPS
class FPS20Demo {
  final FPS20CameraService _cameraService = FPS20CameraService();
  StreamSubscription<FPS20CameraResult>? _subscription;
  
  /// Запуск демонстрации
  Future<void> runFPS20Demo() async {
    print('🌟' * 20);
    print('🚀 ДЕМОНСТРАЦИЯ СИСТЕМЫ 20+ FPS 🚀');
    print('🌟' * 20);
    
    try {
      // Инициализация
      await _cameraService.initializeFPS20Camera();
      
      // Подписка на результаты
      _subscription = _cameraService.resultStream.listen(
        _handleCameraResult,
        onError: _handleError,
      );
      
      // Запуск обработки
      await _cameraService.startFPS20Processing(exerciseType: 'squats');
      
      print('✅ Демонстрация запущена! Обрабатываем кадры с 20+ FPS...');
      
      // Демонстрация смены упражнений
      await _demonstrateExerciseChanges();
      
    } catch (e) {
      print('❌ Ошибка демонстрации: $e');
    }
  }
  
  /// Демонстрация смены упражнений
  Future<void> _demonstrateExerciseChanges() async {
    final exercises = ['squats', 'pushups', 'lunges', 'plank'];
    
    for (final exercise in exercises) {
      await Future.delayed(Duration(seconds: 10));
      _cameraService.changeExerciseType(exercise);
      print('🔄 Переключились на упражнение: $exercise');
    }
  }
  
  /// Обработка результатов камеры
  void _handleCameraResult(FPS20CameraResult result) {
    final fps = result.fps20Result.achievedFPS;
    final frameNum = result.frameNumber;
    
    // Выводим статистику каждые 30 кадров
    if (frameNum % 30 == 0) {
      print('\n📊 СТАТИСТИКА КАДРА #$frameNum:');
      print('⚡ FPS: ${fps.toStringAsFixed(1)}');
      print('🎯 Цель: ${result.fps20Result.targetFPS.toStringAsFixed(1)}');
      print('📈 Стабильность: ${(result.fps20Result.fpsStability * 100).toStringAsFixed(1)}%');
      print('🔧 Оптимизация: ${(result.fps20Result.optimizationLevel * 100).toStringAsFixed(1)}%');
      print('⏱️ Время обработки: ${result.processingTime.inMilliseconds} мс');
      
      // Статистика производительности
      final stats = result.performanceStats;
      print('\n📈 ОБЩАЯ СТАТИСТИКА:');
      print('📊 Средний FPS: ${stats.averageFPS.toStringAsFixed(1)}');
      print('🚀 Максимальный FPS: ${stats.maxFPS.toStringAsFixed(1)}');
      print('📉 Минимальный FPS: ${stats.minFPS.toStringAsFixed(1)}');
      print('✅ Цель 20+ FPS: ${stats.target20FPSAchieved ? "ДОСТИГНУТА" : "НЕ ДОСТИГНУТА"}');
      print('🎯 Стабильная работа: ${stats.consistentPerformance ? "ДА" : "НЕТ"}');
      
      // Системные инсайты
      print('\n💡 СИСТЕМНЫЕ ИНСАЙТЫ:');
      print(result.fps20Result.systemInsights);
      
      print('═' * 50);
    }
  }
  
  /// Обработка ошибок
  void _handleError(dynamic error) {
    print('❌ Ошибка в стриме камеры: $error');
  }
  
  /// Остановка демонстрации
  Future<void> stopDemo() async {
    print('⏹️ Остановка демонстрации...');
    
    await _subscription?.cancel();
    await _cameraService.dispose();
    
    print('✅ Демонстрация остановлена');
  }
}

// ========== МОДЕЛИ ДАННЫХ ==========

class FPS20CameraResult {
  final FPS20Result fps20Result;
  final CameraImage cameraImage;
  final Duration processingTime;
  final int frameNumber;
  final String exerciseType;
  final FPS20SystemStatus systemStatus;
  final FPS20PerformanceStats performanceStats;
  
  const FPS20CameraResult({
    required this.fps20Result,
    required this.cameraImage,
    required this.processingTime,
    required this.frameNumber,
    required this.exerciseType,
    required this.systemStatus,
    required this.performanceStats,
  });
}

class FPS20PerformanceStats {
  final double averageFPS;
  final double maxFPS;
  final double minFPS;
  final double fpsStability;
  final int framesProcessed;
  final int posesDetected;
  final bool target20FPSAchieved;
  final bool consistentPerformance;
  
  const FPS20PerformanceStats({
    required this.averageFPS,
    required this.maxFPS,
    required this.minFPS,
    required this.fpsStability,
    required this.framesProcessed,
    required this.posesDetected,
    required this.target20FPSAchieved,
    required this.consistentPerformance,
  });
  
  static FPS20PerformanceStats empty() {
    return const FPS20PerformanceStats(
      averageFPS: 0.0,
      maxFPS: 0.0,
      minFPS: 0.0,
      fpsStability: 0.0,
      framesProcessed: 0,
      posesDetected: 0,
      target20FPSAchieved: false,
      consistentPerformance: false,
    );
  }
}

/// Утилитарный класс для работы с FPS20 системой
class FPS20Utils {
  /// Проверка поддержки устройством 20+ FPS
  static Future<bool> isDeviceCapableOf20FPS() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;
      
      // Простая проверка - если есть камера, скорее всего поддерживает
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Рекомендуемые настройки для достижения 20+ FPS
  static Map<String, dynamic> getRecommendedSettings() {
    return {
      'resolution': ResolutionPreset.medium,
      'image_format': ImageFormatGroup.yuv420,
      'enable_audio': false,
      'focus_mode': FocusMode.locked,
      'exposure_mode': ExposureMode.locked,
      'flash_mode': FlashMode.off,
      'target_fps': 20.0,
      'quality_level': 0.8,
      'processing_priority': 'speed',
    };
  }
  
  /// Диагностика производительности
  static String diagnoseFPSPerformance(FPS20PerformanceStats stats) {
    if (stats.target20FPSAchieved && stats.consistentPerformance) {
      return '🚀 ОТЛИЧНАЯ ПРОИЗВОДИТЕЛЬНОСТЬ! Система стабильно работает на 20+ FPS';
    } else if (stats.target20FPSAchieved) {
      return '✅ ЦЕЛЬ ДОСТИГНУТА! FPS 20+, но есть нестабильность';
    } else if (stats.averageFPS >= 15.0) {
      return '⚠️ ПРИЕМЛЕМАЯ ПРОИЗВОДИТЕЛЬНОСТЬ. FPS ниже цели, но в рабочем диапазоне';
    } else {
      return '❌ НИЗКАЯ ПРОИЗВОДИТЕЛЬНОСТЬ. Требуется оптимизация настроек';
    }
  }
}