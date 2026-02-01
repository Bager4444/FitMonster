import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitmonster/features/exercises/domain/models/exercise.dart';
import 'dart:typed_data';
import 'package:fitmonster/features/exercises/services/smart_exercise_engine.dart';
import 'package:fitmonster/features/exercises/services/enhanced_exercise_analyzer.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/pose_painter.dart';

/// Пример интеграции улучшенной системы распознавания упражнений
/// 
/// Этот файл показывает, как интегрировать SmartExerciseEngine
/// в существующую страницу камеры для улучшенного анализа упражнений
class EnhancedCameraPageExample extends StatefulWidget {
  final Exercise exercise;

  const EnhancedCameraPageExample({
    super.key,
    required this.exercise,
  });

  @override
  State<EnhancedCameraPageExample> createState() => _EnhancedCameraPageExampleState();
}

class _EnhancedCameraPageExampleState extends State<EnhancedCameraPageExample> {
  // Камера и ML Kit
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isInitialized = false;
  
  // Новая улучшенная система анализа
  final SmartExerciseEngine _smartEngine = SmartExerciseEngine();
  
  // Состояние упражнения
  bool _isRecording = false;
  int _repCount = 0;
  double _technicalScore = 0.0;
  String _feedback = 'Встаньте в кадр';
  MovementPhase _currentPhase = MovementPhase.unknown;
  Map<String, double> _keyAngles = {};
  
  // Метрики производительности
  double _currentFps = 0.0;
  String _performanceMode = 'high';
  
  // Визуализация позы
  List<Pose> _poses = [];
  Size _inputImageSize = Size.zero;
  InputImageRotation _inputImageRotation = InputImageRotation.rotation0deg;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  Future<void> _initializeComponents() async {
    // Инициализация ML Kit
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
    
    // Настройка умного движка
    _smartEngine.setExercise(widget.exercise.id);
    
    // Инициализация камеры
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

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
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _startExercise() {
    if (!_isInitialized || _isRecording) return;

    setState(() {
      _isRecording = true;
      _feedback = 'Начинайте упражнение!';
    });

    // Сброс состояния
    _smartEngine.reset();
    
    // Запуск анализа кадров
    _startImageStream();
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) {
      if (!_isRecording) return;
      
      _processImageWithSmartEngine(image);
    });
  }

  Future<void> _processImageWithSmartEngine(CameraImage image) async {
    if (_poseDetector == null) return;

    try {
      // Создание InputImage
      final inputImage = _createInputImage(image);
      if (inputImage == null) return;

      // Детекция позы с ML Kit
      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty) {
        // Анализ с помощью умного движка
        final result = _smartEngine.analyzePose(poses.first);
        
        // Получение статистики производительности
        final stats = _smartEngine.getPerformanceStats();
        
        if (mounted) {
          setState(() {
            // Обновление основных показателей
            _repCount = result.repCount;
            _technicalScore = result.technicalScore;
            _feedback = result.feedback;
            _currentPhase = result.movementPhase;
            _keyAngles = result.keyAngles;
            
            // Обновление метрик производительности
            _currentFps = result.avgFps;
            _performanceMode = result.performanceMode;
            
            // Обновление визуализации
            _poses = poses;
          });
        }
        
        // Логирование для отладки
        _logAnalysisResults(result, stats);
      }
    } catch (e) {
      print('❌ Ошибка анализа с умным движком: $e');
    }
  }

  void _logAnalysisResults(SmartExerciseResult result, Map<String, dynamic> stats) {
    // Периодическое логирование для мониторинга
    if (_repCount % 5 == 0 && _repCount > 0) {
      print('🧠 Умный анализ:');
      print('   Повторения: ${result.repCount}');
      print('   Техника: ${(result.technicalScore * 100).toInt()}%');
      print('   Фаза: ${result.movementPhase}');
      print('   Режим: ${result.performanceMode}');
      print('   Углы: ${result.keyAngles}');
    }
  }

  InputImage? _createInputImage(CameraImage image) {
    // Упрощенная версия создания InputImage
    // В реальном коде используйте полную реализацию из ExerciseCameraPage
    
    final rotation = _getInputImageRotation();
    final size = Size(image.width.toDouble(), image.height.toDouble());
    
    _inputImageSize = size;
    _inputImageRotation = rotation;
    
    if (image.format.group == ImageFormatGroup.yuv420) {
      final bytes = _convertYuv420ToNv21(image);
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
  }

  InputImageRotation _getInputImageRotation() {
    final sensorOrientation = _cameraController?.description.sensorOrientation ?? 0;
    switch (sensorOrientation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  Uint8List _convertYuv420ToNv21(CameraImage image) {
    // Упрощенная конвертация - используйте полную реализацию из ExerciseCameraPage
    final width = image.width;
    final height = image.height;
    final out = Uint8List(width * height + (width * height ~/ 2));
    
    // Здесь должна быть полная реализация конвертации YUV420 -> NV21
    // Для примера возвращаем пустой массив
    return out;
  }

  void _stopExercise() {
    setState(() {
      _isRecording = false;
    });
    
    _cameraController?.stopImageStream();
    
    // Показ результатов
    _showResults();
  }

  void _showResults() {
    final stats = _smartEngine.getPerformanceStats();
    final recommendations = _smartEngine.getOptimizationRecommendations();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Результаты тренировки'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Повторения: $_repCount'),
              Text('Техника: ${(_technicalScore * 100).toInt()}%'),
              Text('Режим: $_performanceMode'),
              const SizedBox(height: 16),
              const Text('Ключевые углы:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._keyAngles.entries.map((entry) => 
                Text('${entry.key}: ${entry.value.toStringAsFixed(1)}°')),
              const SizedBox(height: 16),
              if (recommendations.isNotEmpty) ...[
                const Text('Рекомендации:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...recommendations.map((rec) => Text('• $rec')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartExercise();
            },
            child: const Text('Еще раз'),
          ),
        ],
      ),
    );
  }

  void _restartExercise() {
    _smartEngine.reset();
    setState(() {
      _repCount = 0;
      _technicalScore = 0.0;
      _feedback = 'Готовы к следующему подходу!';
      _currentPhase = MovementPhase.unknown;
      _keyAngles = {};
    });
    _startExercise();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    _smartEngine.clearAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exercise.nameRu} (Улучшенный)'),
        actions: [
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
            onPressed: _isRecording ? _stopExercise : _startExercise,
          ),
        ],
      ),
      body: _isInitialized ? _buildMainInterface() : _buildLoadingInterface(),
    );
  }

  Widget _buildLoadingInterface() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Инициализация умного анализа...'),
        ],
      ),
    );
  }

  Widget _buildMainInterface() {
    return Column(
      children: [
        // Камера с оверлеем
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isRecording ? Colors.red : Colors.grey,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                children: [
                  // Превью камеры
                  if (_cameraController != null && _cameraController!.value.isInitialized)
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize!.height,
                          height: _cameraController!.value.previewSize!.width,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  
                  // Оверлей с позами
                  if (_poses.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PosePainter(
                          poses: _poses,
                          imageSize: _inputImageSize,
                          rotation: _inputImageRotation,
                          mirror: _cameraController?.description.lensDirection == 
                                 CameraLensDirection.front,
                        ),
                      ),
                    ),
                  
                  // Счетчик повторений
                  if (_isRecording)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildRepCounter(),
                    ),
                  
                  // Метрики производительности
                  if (_isRecording)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildPerformanceMetrics(),
                    ),
                  
                  // Индикатор фазы движения
                  if (_isRecording && _currentPhase != MovementPhase.unknown)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: _buildPhaseIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // Панель управления и статистики
        Expanded(
          flex: 2,
          child: _buildControlPanel(),
        ),
      ],
    );
  }

  Widget _buildRepCounter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_repCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Техника: ${(_technicalScore * 100).toInt()}%',
            style: TextStyle(
              color: _technicalScore > 0.8 ? Colors.green : 
                     _technicalScore > 0.6 ? Colors.orange : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'FPS: ${_currentFps.toStringAsFixed(1)}',
            style: TextStyle(
              color: _currentFps > 7 ? Colors.green : 
                     _currentFps > 5 ? Colors.orange : Colors.red,
              fontSize: 12,
            ),
          ),
          Text(
            _performanceMode.toUpperCase(),
            style: TextStyle(
              color: _performanceMode == 'high' ? Colors.green : Colors.orange,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    String phaseText;
    Color phaseColor;
    
    switch (_currentPhase) {
      case MovementPhase.top:
        phaseText = 'ВЕРХ';
        phaseColor = Colors.green;
        break;
      case MovementPhase.bottom:
        phaseText = 'НИЗ';
        phaseColor = Colors.blue;
        break;
      case MovementPhase.transition:
        phaseText = 'ПЕРЕХОД';
        phaseColor = Colors.orange;
        break;
      case MovementPhase.static:
        phaseText = 'СТАТИКА';
        phaseColor = Colors.purple;
        break;
      default:
        phaseText = 'АНАЛИЗ';
        phaseColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: phaseColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        phaseText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Обратная связь
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isRecording ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isRecording ? Colors.green : Colors.blue,
              ),
            ),
            child: Text(
              _feedback,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Детальная статистика углов
          if (_keyAngles.isNotEmpty) ...[
            const Text('Ключевые углы:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _keyAngles.entries.map((entry) => Chip(
                label: Text('${entry.key}: ${entry.value.toStringAsFixed(0)}°'),
                backgroundColor: Colors.grey.shade200,
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Кнопки управления
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isRecording ? null : _startExercise,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Начать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isRecording ? _stopExercise : null,
                icon: const Icon(Icons.stop),
                label: const Text('Стоп'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Импорт для Uint8List
