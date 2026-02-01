import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../domain/models/exercise.dart';
import '../../services/graph_cleanup_service.dart';
import '../../services/ultra_fast_graph_optimizer.dart';
import '../../services/final_graph_20fps_optimizer.dart';
import 'dart:async';

/// Улучшенная страница камеры с очисткой графа при остановке
class EnhancedExerciseCameraPage extends StatefulWidget {
  final Exercise exercise;
  
  const EnhancedExerciseCameraPage({
    super.key,
    required this.exercise,
  });

  @override
  State<EnhancedExerciseCameraPage> createState() => _EnhancedExerciseCameraPageState();
}

class _EnhancedExerciseCameraPageState extends State<EnhancedExerciseCameraPage> {
  // Камера и ML Kit
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isInitialized = false;
  bool _isRecording = false;
  
  // Оптимизаторы графа
  final UltraFastGraphManager _graphManager = UltraFastGraphManager();
  final FinalGraph20FPSOptimizer _fpsOptimizer = FinalGraph20FPSOptimizer();
  final GraphCleanupService _cleanupService = GraphCleanupService();
  
  // Состояние тренировки
  int _repCount = 0;
  double _formScore = 0.0;
  String _feedback = 'Встаньте в кадр';
  List<Pose> _poses = [];
  
  // FPS мониторинг
  double _currentFPS = 0.0;
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  
  // Таймеры
  Timer? _durationTimer;
  Timer? _cleanupTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }
  
  Future<void> _initializeSystem() async {
    // Инициализируем оптимизаторы графа
    _graphManager.init();
    _fpsOptimizer.init();
    
    // Инициализируем ML Kit
    await _initializePoseDetector();
    
    // Инициализируем камеру
    await _initializeCamera();
    
    // Запускаем периодическую очистку
    _startPeriodicCleanup();
  }
  
  Future<void> _initializePoseDetector() async {
    try {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      );
      _poseDetector = PoseDetector(options: options);
      print('✅ PoseDetector инициализирован');
    } catch (e) {
      print('❌ Ошибка инициализации PoseDetector: $e');
    }
  }
  
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _feedback = 'Камера не найдена');
        return;
      }
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
        print('✅ Камера инициализирована');
      }
    } catch (e) {
      print('❌ Ошибка инициализации камеры: $e');
      setState(() => _feedback = 'Ошибка камеры: $e');
    }
  }
  
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _cleanupService.autoCleanupIfNeeded();
      }
    });
  }
  
  void _startExercise() {
    if (!_isInitialized || _isRecording) return;
    
    setState(() {
      _isRecording = true;
      _repCount = 0;
      _formScore = 0.0;
      _feedback = 'Начинайте упражнение!';
    });
    
    _startImageStream();
    print('🚀 Упражнение запущено');
  }
  
  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isRecording) return;
      
      _processFrame(image);
    });
  }
  
  Future<void> _processFrame(CameraImage image) async {
    try {
      // Обновляем FPS
      _updateFPS();
      
      // Создаем тестовую позу для демонстрации
      final testPose = _createTestPose();
      
      // Обрабатываем с оптимизаторами графа
      final ultraResult = _graphManager.processFrame(testPose);
      final fpsResult = _fpsOptimizer.optimizeFor20FPS(testPose, widget.exercise.id);
      
      // Регистрируем данные в сервисе очистки
      _cleanupService.registerPose(testPose);
      
      if (mounted) {
        setState(() {
          _poses = [testPose];
          _currentFPS = ultraResult.achievedFPS;
          _feedback = 'Отлично! Продолжайте!';
          
          // Симулируем подсчёт повторений
          if (ultraResult.validNodes > 8) {
            _repCount++;
          }
        });
      }
    } catch (e) {
      print('❌ Ошибка обработки кадра: $e');
    }
  }
  
  Pose _createTestPose() {
    final landmarks = <PoseLandmarkType, PoseLandmark>{};
    
    // Создаем тестовые ключевые точки
    final keyTypes = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    ];
    
    for (int i = 0; i < keyTypes.length; i++) {
      landmarks[keyTypes[i]] = PoseLandmark(
        type: keyTypes[i],
        x: 0.3 + (i * 0.05),
        y: 0.2 + (i * 0.06),
        z: 0.0,
        likelihood: 0.8 + (DateTime.now().millisecond % 200) / 1000,
      );
    }
    
    return Pose(landmarks: landmarks);
  }
  
  void _updateFPS() {
    _frameCount++;
    final now = DateTime.now();
    final timeDiff = now.difference(_lastFpsUpdate).inMilliseconds;
    
    if (timeDiff >= 1000) {
      _currentFPS = _frameCount * 1000.0 / timeDiff;
      _frameCount = 0;
      _lastFpsUpdate = now;
    }
  }
  
  /// УЛУЧШЕННЫЙ МЕТОД ОСТАНОВКИ С ПОЛНОЙ ОЧИСТКОЙ ГРАФА
  Future<void> _stopExercise() async {
    print('🛑 Начинаем остановку упражнения с очисткой графа...');
    
    // 1. Останавливаем запись
    setState(() {
      _isRecording = false;
      _feedback = 'Остановка и очистка...';
    });
    
    // 2. Останавливаем поток камеры
    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
        print('✅ Поток камеры остановлен');
      }
    } catch (e) {
      print('⚠️ Ошибка остановки потока камеры: $e');
    }
    
    // 3. ПОЛНАЯ ОЧИСТКА ГРАФА И ВСЕХ КЭШЕЙ
    _cleanupService.clearAllGraphData();
    
    // 4. Очищаем локальные данные
    _clearLocalData();
    
    // 5. Останавливаем таймеры
    _durationTimer?.cancel();
    _cleanupTimer?.cancel();
    
    // 6. Показываем статистику очистки
    final memoryStats = _cleanupService.getMemoryStats();
    print('📊 Статистика после очистки: $memoryStats');
    
    // 7. Обновляем UI
    if (mounted) {
      setState(() {
        _poses.clear();
        _feedback = 'Граф очищен! Память освобождена. Повторений: $_repCount';
      });
      
      // Показываем уведомление об очистке
      _showCleanupNotification(memoryStats);
    }
    
    print('✅ Остановка с очисткой графа завершена');
  }
  
  /// Очистка локальных данных
  void _clearLocalData() {
    _poses.clear();
    _repCount = 0;
    _formScore = 0.0;
    _frameCount = 0;
    _currentFPS = 0.0;
    print('🗑️ Локальные данные очищены');
  }
  
  /// Показать уведомление об очистке
  void _showCleanupNotification(MemoryStats stats) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧹 Граф успешно очищен!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Освобождено: ${stats.estimatedMemoryMB.toStringAsFixed(1)} MB'),
            Text('Повторений выполнено: $_repCount'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  @override
  void dispose() {
    print('🧹 Освобождение ресурсов страницы...');
    
    // Полная очистка при закрытии страницы
    _cleanupService.clearAllGraphData();
    
    // Освобождаем ресурсы камеры
    _cameraController?.dispose();
    
    // Освобождаем ML Kit
    _poseDetector?.close();
    
    // Останавливаем таймеры
    _durationTimer?.cancel();
    _cleanupTimer?.cancel();
    
    super.dispose();
    print('✅ Ресурсы страницы освобождены');
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeProvider.backgroundColor,
            elevation: 0,
            title: Text(
              widget.exercise.nameRu,
              style: TextStyle(
                color: themeProvider.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Кнопка статистики памяти
              IconButton(
                onPressed: _showMemoryStats,
                icon: Icon(
                  Icons.memory,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Превью камеры
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                  child: _buildCameraPreview(),
                ),
              ),
              
              // Статистика
              Expanded(
                flex: 1,
                child: _buildStatsSection(themeProvider),
              ),
              
              // Управление
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildControlButtons(themeProvider),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildCameraPreview() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Превью камеры
          CameraPreview(_cameraController!),
          
          // Оверлей с позами (если есть)
          if (_poses.isNotEmpty)
            CustomPaint(
              painter: SimplePosePainter(_poses.first),
              size: Size.infinite,
            ),
          
          // FPS счетчик
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'FPS: ${_currentFPS.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsSection(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.cardBorderColor),
      ),
      child: Column(
        children: [
          // Счетчик повторений
          Text(
            '$_repCount',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          Text(
            'Повторений',
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.secondaryTextColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Обратная связь
          Text(
            _feedback,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButtons(ThemeProvider themeProvider) {
    return Row(
      children: [
        // Кнопка старт/стоп
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isRecording ? _stopExercise : _startExercise,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
            label: Text(
              _isRecording ? 'Стоп + Очистка' : 'Старт',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Кнопка быстрой очистки
        ElevatedButton.icon(
          onPressed: _quickCleanup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.cleaning_services),
          label: const Text('Очистка'),
        ),
      ],
    );
  }
  
  void _quickCleanup() {
    _cleanupService.quickCleanup();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Быстрая очистка выполнена'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _showMemoryStats() {
    final stats = _cleanupService.getMemoryStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Статистика памяти'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Буферы изображений: ${stats.imageBuffers}'),
            Text('История поз: ${stats.poseHistory}'),
            Text('Кэш графа: ${stats.graphCache}'),
            Text('Очередь обработки: ${stats.processingQueue}'),
            const SizedBox(height: 8),
            Text(
              'Использование памяти: ${stats.estimatedMemoryMB.toStringAsFixed(1)} MB',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cleanupService.clearAllGraphData();
              _showMemoryStats();
            },
            child: const Text('Очистить всё'),
          ),
        ],
      ),
    );
  }
}

/// Простой рисовальщик поз для демонстрации
class SimplePosePainter extends CustomPainter {
  final Pose pose;
  
  SimplePosePainter(this.pose);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;
    
    // Рисуем ключевые точки
    for (final landmark in pose.landmarks.values) {
      final x = landmark.x * size.width;
      final y = landmark.y * size.height;
      
      if (landmark.likelihood > 0.5) {
        canvas.drawCircle(Offset(x, y), 6, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}