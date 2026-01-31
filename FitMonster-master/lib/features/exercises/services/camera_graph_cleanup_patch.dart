import 'dart:typed_data';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'graph_cleanup_service.dart';

/// Патч для добавления очистки графа в существующую страницу камеры
/// Используйте этот код для модификации _stopExercise() метода
class CameraGraphCleanupPatch {
  static final GraphCleanupService _cleanupService = GraphCleanupService();
  
  /// Улучшенный метод остановки упражнения с полной очисткой графа
  /// Замените существующий _stopExercise() этим кодом
  static Future<void> enhancedStopExercise({
    required Function() setRecordingFalse,
    required Function() cancelTimers,
    required Function() stopCameraStream,
    required Function() completeWorkout,
    required Function(String) setFeedback,
    required Function() showResults,
    required int repCount,
    required List<Pose> poses,
    required Map<String, Uint8List>? imageBufferCache,
  }) async {
    print('🛑 Начинаем остановку упражнения с очисткой графа...');
    
    // 1. Останавливаем запись
    setRecordingFalse();
    setFeedback('Остановка и очистка графа...');
    
    // 2. Останавливаем таймеры
    cancelTimers();
    
    // 3. Останавливаем поток камеры
    try {
      await stopCameraStream();
      print('✅ Поток камеры остановлен');
    } catch (e) {
      print('⚠️ Ошибка остановки потока камеры: $e');
    }
    
    // 4. ПОЛНАЯ ОЧИСТКА ГРАФА И ВСЕХ КЭШЕЙ
    _cleanupService.clearAllGraphData();
    
    // 5. Очищаем переданные данные
    poses.clear();
    imageBufferCache?.clear();
    
    // 6. Показываем статистику очистки
    final memoryStats = _cleanupService.getMemoryStats();
    print('📊 Статистика после очистки: $memoryStats');
    
    // 7. Обновляем обратную связь
    setFeedback('Граф очищен! Память освобождена. Повторений: $repCount');
    
    // 8. Завершаем тренировку
    try {
      await completeWorkout();
      showResults();
    } catch (e) {
      print('❌ Ошибка завершения тренировки: $e');
      setFeedback('Тренировка завершена! (ошибка сохранения)');
    }
    
    print('✅ Остановка с очисткой графа завершена');
  }
  
  /// Быстрая очистка для использования во время работы
  static void quickCleanupDuringWorkout() {
    _cleanupService.quickCleanup();
    print('⚡ Быстрая очистка выполнена во время тренировки');
  }
  
  /// Автоматическая очистка при превышении лимитов
  static void autoCleanupIfNeeded() {
    _cleanupService.autoCleanupIfNeeded();
  }
  
  /// Регистрация данных для отслеживания
  static void registerFrameData({
    Pose? pose,
    String? imageBufferKey,
    Uint8List? imageBuffer,
    dynamic graphData,
  }) {
    if (pose != null) {
      _cleanupService.registerPose(pose);
    }
    
    if (imageBufferKey != null && imageBuffer != null) {
      _cleanupService.registerImageBuffer(imageBufferKey, imageBuffer);
    }
    
    if (graphData != null) {
      _cleanupService.registerGraphCache(
        'frame_${DateTime.now().millisecondsSinceEpoch}',
        graphData,
      );
    }
  }
  
  /// Получение статистики памяти
  static MemoryStats getMemoryStats() {
    return _cleanupService.getMemoryStats();
  }
}

/// Инструкции по интеграции в существующий код
class IntegrationInstructions {
  static const String stopExerciseReplacement = '''
  
  // ЗАМЕНИТЕ СУЩЕСТВУЮЩИЙ _stopExercise() ЭТИМ КОДОМ:
  
  void _stopExercise() async {
    await CameraGraphCleanupPatch.enhancedStopExercise(
      setRecordingFalse: () => setState(() => _isRecording = false),
      cancelTimers: () {
        _feedbackTimer?.cancel();
        _durationTimer?.cancel();
      },
      stopCameraStream: () async {
        if (_cameraController != null && _cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
      },
      completeWorkout: () async {
        if (_currentSession != null) {
          final completedSession = await _workoutService.completeWorkout(_currentSession!);
          _currentSession = completedSession;
        }
      },
      setFeedback: (feedback) => setState(() => _feedback = feedback),
      showResults: () {
        // Ваш код показа результатов
        if (mounted && _currentSession != null) {
          showDialog(
            context: context,
            builder: (context) => WorkoutResultsDialog(
              session: _currentSession!,
              repsCompleted: _repCount,
              averageFormScore: _formScore,
              workoutDuration: _workoutDuration,
            ),
          );
        }
      },
      repCount: _repCount,
      poses: _poses,
      imageBufferCache: _imageBufferCache, // если есть
    );
  }
  ''';
  
  static const String frameProcessingAddition = '''
  
  // ДОБАВЬТЕ В МЕТОД ОБРАБОТКИ КАДРОВ:
  
  Future<void> _processImageUltraFast(CameraImage image) async {
    // ... существующий код ...
    
    // ДОБАВЬТЕ ЭТО В КОНЕЦ МЕТОДА:
    
    // Регистрируем данные для отслеживания памяти
    if (poses.isNotEmpty) {
      CameraGraphCleanupPatch.registerFrameData(
        pose: poses.first,
        imageBufferKey: 'frame_\${DateTime.now().millisecondsSinceEpoch}',
        imageBuffer: imageBuffer, // если есть
      );
    }
    
    // Автоматическая очистка при необходимости
    CameraGraphCleanupPatch.autoCleanupIfNeeded();
  }
  ''';
  
  static const String initAddition = '''
  
  // ДОБАВЬТЕ В initState():
  
  @override
  void initState() {
    super.initState();
    
    // ... существующий код ...
    
    // Периодическая автоочистка каждые 30 секунд
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        CameraGraphCleanupPatch.autoCleanupIfNeeded();
      } else {
        timer.cancel();
      }
    });
  }
  ''';
  
  static const String disposeAddition = '''
  
  // ДОБАВЬТЕ В dispose():
  
  @override
  void dispose() {
    // Полная очистка при закрытии страницы
    CameraGraphCleanupPatch.enhancedStopExercise(
      setRecordingFalse: () {},
      cancelTimers: () {},
      stopCameraStream: () async {},
      completeWorkout: () async {},
      setFeedback: (feedback) {},
      showResults: () {},
      repCount: _repCount,
      poses: _poses,
      imageBufferCache: _imageBufferCache,
    );
    
    // ... существующий код dispose ...
    
    super.dispose();
  }
  ''';
}

/// Утилиты для мониторинга производительности
class PerformanceMonitor {
  static DateTime _lastMemoryCheck = DateTime.now();
  static double _lastMemoryUsage = 0.0;
  
  /// Проверка производительности и вывод в лог
  static void checkPerformance() {
    final now = DateTime.now();
    if (now.difference(_lastMemoryCheck).inSeconds >= 5) {
      final stats = CameraGraphCleanupPatch.getMemoryStats();
      final currentMemory = stats.estimatedMemoryMB;
      
      print('📊 Производительность:');
      print('   Память: ${currentMemory.toStringAsFixed(1)} MB');
      print('   Изменение: ${(currentMemory - _lastMemoryUsage).toStringAsFixed(1)} MB');
      print('   Буферы: ${stats.imageBuffers}');
      print('   Позы: ${stats.poseHistory}');
      
      _lastMemoryUsage = currentMemory;
      _lastMemoryCheck = now;
      
      // Предупреждение при высоком использовании памяти
      if (currentMemory > 100.0) {
        print('⚠️ ВНИМАНИЕ: Высокое использование памяти! Рекомендуется очистка.');
      }
    }
  }
}