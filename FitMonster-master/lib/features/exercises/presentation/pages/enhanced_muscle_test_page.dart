import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../domain/models/exercise.dart';
import '../../services/improved_rep_counter.dart';
import '../../services/graph_cleanup_service.dart';
import '../widgets/pose_painter.dart';
import 'dart:async';
import 'dart:typed_data';

/// Улучшенная страница теста мышц с полноценной камерой и таймером
class EnhancedMuscleTestPage extends StatefulWidget {
  final Exercise exercise;
  final String muscleGroup;
  final Color groupColor;
  
  const EnhancedMuscleTestPage({
    super.key,
    required this.exercise,
    required this.muscleGroup,
    required this.groupColor,
  });

  @override
  State<EnhancedMuscleTestPage> createState() => _EnhancedMuscleTestPageState();
}

class _EnhancedMuscleTestPageState extends State<EnhancedMuscleTestPage> {
  // Камера и ML Kit
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isInitialized = false;
  
  // Состояние теста
  bool _isTestActive = false;
  bool _isCountdownActive = false;
  int _repCount = 0;
  double _formScore = 0.0;
  String _feedback = 'Встаньте в кадр для начала теста';
  List<Pose> _poses = [];
  
  // Таймер теста (1 минута)
  static const int _testDurationSeconds = 60;
  int _remainingSeconds = _testDurationSeconds;
  Timer? _testTimer;
  Timer? _countdownTimer;
  
  // Счетчик повторений и очистка
  final ImprovedRepCounter _repCounter = ImprovedRepCounter();
  final GraphCleanupService _cleanupService = GraphCleanupService();
  
  // Обработка кадров
  bool _isProcessingFrame = false;
  int _frameSkipCounter = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }
  
  Future<void> _initializeSystem() async {
    await _initializePoseDetector();
    await _initializeCamera();
    _repCounter.setExerciseType(widget.exercise.id);
  }
  
  Future<void> _initializePoseDetector() async {
    try {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      );
      _poseDetector = PoseDetector(options: options);
      print('✅ PoseDetector для теста мышц инициализирован');
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
        print('✅ Камера для теста мышц готова');
      }
    } catch (e) {
      print('❌ Ошибка инициализации камеры: $e');
      setState(() => _feedback = 'Ошибка камеры: $e');
    }
  } 
 
  /// Запуск обратного отсчёта перед тестом
  void _startCountdown() {
    if (!_isInitialized) return;
    
    setState(() {
      _isCountdownActive = true;
      _feedback = 'Приготовьтесь! Тест начнется через...';
    });
    
    int countdown = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() => _feedback = 'Начинаем через $countdown...');
        countdown--;
      } else {
        timer.cancel();
        _startTest();
      }
    });
  }
  
  /// Запуск теста на 1 минуту
  void _startTest() {
    setState(() {
      _isCountdownActive = false;
      _isTestActive = true;
      _repCount = 0;
      _formScore = 0.0;
      _remainingSeconds = _testDurationSeconds;
      _feedback = 'ТЕСТ НАЧАЛСЯ! Делайте максимум повторений!';
    });
    
    _repCounter.reset();
    _startImageStream();
    _startTestTimer();
    
    print('🚀 Тест мышц запущен на $_testDurationSeconds секунд');
  }
  
  /// Запуск таймера теста с обратным отсчётом
  void _startTestTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        
        if (_remainingSeconds <= 0) {
          _completeTest();
          timer.cancel();
        } else if (_remainingSeconds <= 10) {
          _feedback = 'Осталось $_remainingSeconds сек! Финальный рывок!';
        } else if (_remainingSeconds <= 30) {
          _feedback = 'Половина времени прошла! Не сдавайтесь!';
        }
      });
    });
  }
  
  /// Запуск потока камеры
  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isTestActive || _isProcessingFrame) return;
      
      // Пропускаем каждый второй кадр для производительности
      _frameSkipCounter++;
      if (_frameSkipCounter % 2 != 0) return;
      
      _processFrame(image);
    });
  }
  
  /// Обработка кадра с ML Kit
  Future<void> _processFrame(CameraImage image) async {
    if (_poseDetector == null) return;
    
    _isProcessingFrame = true;
    
    try {
      final inputImage = _createInputImage(image);
      if (inputImage == null) return;
      
      final poses = await _poseDetector!.processImage(inputImage);
      
      if (mounted && _isTestActive) {
        setState(() {
          _poses = poses;
          
          if (poses.isEmpty) {
            _feedback = 'Встаньте в кадр полностью! Осталось: ${_formatTime(_remainingSeconds)}';
          } else {
            _analyzePose(poses.first);
          }
        });
      }
    } catch (e) {
      print('❌ Ошибка обработки кадра: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }
  
  /// Анализ позы и подсчёт повторений
  void _analyzePose(Pose pose) {
    final confidence = _calculatePoseConfidence(pose);
    _formScore = confidence;
    
    // Используем улучшенный счетчик повторений
    final result = _repCounter.analyzePose(pose);
    
    if (result.repCount > _repCount) {
      _repCount = result.repCount;
      
      // Регистрируем данные для очистки
      _cleanupService.registerPose(pose);
    }
    
    // Обновляем обратную связь с учётом времени
    if (confidence > 70) {
      _feedback = '${result.feedback} | Осталось: ${_formatTime(_remainingSeconds)} | Повторений: $_repCount';
    } else {
      _feedback = 'Улучшите технику! Осталось: ${_formatTime(_remainingSeconds)}';
    }
  }
  
  /// Создание InputImage из CameraImage
  InputImage? _createInputImage(CameraImage image) {
    try {
      final rotation = InputImageRotation.rotation0deg;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      
      if (image.format.group == ImageFormatGroup.yuv420) {
        final bytes = _yuv420ToNv21(image);
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: size,
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      }
      
      return null;
    } catch (e) {
      print('❌ Ошибка создания InputImage: $e');
      return null;
    }
  }
  
  /// Конвертация YUV420 в NV21
  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    
    final out = Uint8List(width * height + (width * height ~/ 2));
    
    // Y плоскость
    int outIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        out[outIndex++] = yPlane.bytes[y * yPlane.bytesPerRow + x];
      }
    }
    
    // UV плоскости (NV21 = V затем U)
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final uIndex = y * uPlane.bytesPerRow + x;
        final vIndex = y * vPlane.bytesPerRow + x;
        out[outIndex++] = vPlane.bytes[vIndex];
        out[outIndex++] = uPlane.bytes[uIndex];
      }
    }
    
    return out;
  }
  
  /// Расчёт уверенности позы
  double _calculatePoseConfidence(Pose pose) {
    if (pose.landmarks.isEmpty) return 0.0;
    
    double totalConfidence = 0;
    int count = 0;
    
    for (final landmark in pose.landmarks.values) {
      totalConfidence += landmark.likelihood;
      count++;
    }
    
    return count > 0 ? (totalConfidence / count) * 100 : 0.0;
  }
  
  /// Форматирование времени
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  /// Завершение теста
  void _completeTest() async {
    setState(() {
      _isTestActive = false;
      _feedback = 'ТЕСТ ЗАВЕРШЁН! Отличная работа!';
    });
    
    // Останавливаем поток камеры
    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      print('⚠️ Ошибка остановки камеры: $e');
    }
    
    // Очищаем граф
    _cleanupService.clearAllGraphData();
    
    // Показываем результаты
    _showTestResults();
  }
  
  /// Остановка теста вручную
  void _stopTest() async {
    _testTimer?.cancel();
    _countdownTimer?.cancel();
    
    setState(() {
      _isTestActive = false;
      _isCountdownActive = false;
      _feedback = 'Тест остановлен';
    });
    
    // Останавливаем камеру и очищаем граф
    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      print('⚠️ Ошибка остановки камеры: $e');
    }
    
    _cleanupService.clearAllGraphData();
  }
  
  /// Показ результатов теста
  void _showTestResults() {
    String level;
    String description;
    Color levelColor;
    
    if (_repCount >= 30) {
      level = 'ОТЛИЧНЫЙ';
      description = 'Превосходный результат! Вы в отличной форме!';
      levelColor = Colors.green;
    } else if (_repCount >= 20) {
      level = 'ХОРОШИЙ';
      description = 'Хороший результат! Продолжайте тренировки!';
      levelColor = Colors.blue;
    } else if (_repCount >= 10) {
      level = 'СРЕДНИЙ';
      description = 'Неплохо! Есть потенциал для улучшения.';
      levelColor = Colors.orange;
    } else {
      level = 'НАЧАЛЬНЫЙ';
      description = 'Начните с регулярных тренировок для улучшения.';
      levelColor = Colors.red;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          '🏆 Результат теста',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: widget.groupColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.muscleGroup,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Результат
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: levelColor),
              ),
              child: Column(
                children: [
                  Text(
                    '$_repCount',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: levelColor,
                    ),
                  ),
                  const Text(
                    'повторений за 1 минуту',
                    style: TextStyle(fontSize: 14),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Уровень: $level',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: levelColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Дополнительная статистика
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Средняя техника:'),
                      Text('${_formScore.toStringAsFixed(1)}%'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Темп:'),
                      Text('${(_repCount / 60).toStringAsFixed(1)} повт/сек'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, _repCount);
            },
            child: const Text('Завершить'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartTest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.groupColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
  
  /// Перезапуск теста
  void _restartTest() {
    setState(() {
      _repCount = 0;
      _formScore = 0.0;
      _remainingSeconds = _testDurationSeconds;
      _feedback = 'Готовы к повторному тесту?';
    });
    
    _repCounter.reset();
    _cleanupService.quickCleanup();
  }
  
  @override
  void dispose() {
    print('🧹 Освобождение ресурсов теста мышц...');
    
    _testTimer?.cancel();
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    _poseDetector?.close();
    _cleanupService.clearAllGraphData();
    
    super.dispose();
    print('✅ Ресурсы теста мышц освобождены');
  }  
  
@override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Превью камеры
                _buildCameraPreview(),
                
                // Верхняя панель
                _buildTopPanel(themeProvider),
                
                // Таймер (большой, по центру)
                if (_isTestActive) _buildTimer(),
                
                // Счётчик повторений
                if (_isTestActive) _buildRepCounter(),
                
                // Обратная связь
                _buildFeedback(themeProvider),
                
                // Кнопки управления
                _buildControlButtons(themeProvider),
                
                // Обратный отсчёт
                if (_isCountdownActive) _buildCountdownOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCameraPreview() {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Инициализация камеры...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        // Превью камеры
        SizedBox.expand(
          child: CameraPreview(_cameraController!),
        ),
        
        // Оверлей с позами
        if (_poses.isNotEmpty)
          CustomPaint(
            painter: PosePainter(
              poses: _poses,
              imageSize: Size(
                _cameraController!.value.previewSize!.height,
                _cameraController!.value.previewSize!.width,
              ),
              rotation: InputImageRotation.rotation0deg,
            ),
            size: Size.infinite,
          ),
      ],
    );
  }
  
  Widget _buildTopPanel(ThemeProvider themeProvider) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Тест: ${widget.muscleGroup}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.exercise.nameRu,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimer() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _remainingSeconds <= 10 ? Colors.red : Colors.orange,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            _formatTime(_remainingSeconds),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRepCounter() {
    return Positioned(
      top: 180,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$_repCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'повторений',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeedback(ThemeProvider themeProvider) {
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _feedback,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  Widget _buildControlButtons(ThemeProvider themeProvider) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Кнопка старт/стоп
          if (!_isTestActive && !_isCountdownActive)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startCountdown,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.groupColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'НАЧАТЬ ТЕСТ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Кнопка остановки во время теста
          if (_isTestActive || _isCountdownActive)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _stopTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.stop),
                label: const Text(
                  'ОСТАНОВИТЬ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 6,
            ),
            SizedBox(height: 24),
            Text(
              'Подготовка к тесту...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Встаньте в кадр и приготовьтесь\nк выполнению упражнения',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}