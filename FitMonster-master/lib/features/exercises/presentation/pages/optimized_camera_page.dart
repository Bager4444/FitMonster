import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitmonster/features/exercises/services/optimized_rep_counter.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/optimized_pose_painter.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/key_points_info_widget.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/countdown_widget.dart';
import 'package:fitmonster/features/exercises/domain/models/exercise.dart';

/// Оптимизированная страница камеры с анализом ключевых точек
class OptimizedCameraPage extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback? onWorkoutComplete;
  final bool showComplexProgress;
  final int currentExercise;
  final int totalExercises;
  final String complexName;

  const OptimizedCameraPage({
    super.key,
    required this.exercise,
    this.onWorkoutComplete,
    this.showComplexProgress = false,
    this.currentExercise = 1,
    this.totalExercises = 1,
    this.complexName = '',
  });

  @override
  State<OptimizedCameraPage> createState() => _OptimizedCameraPageState();
}

class _OptimizedCameraPageState extends State<OptimizedCameraPage> {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );
  final OptimizedRepCounter _repCounter = OptimizedRepCounter();
  
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  Pose? _currentPose;
  OptimizedRepCountResult? _currentResult;
  Size _imageSize = const Size(640, 480);
  bool _showInfo = true;
  bool _isProcessing = false;
  
  // Состояние для обратного отсчёта
  bool _isCountdownActive = false;
  bool _isWorkoutStarted = false;
  
  // Настройки тренировки
  int _targetReps = 15; // Целевое количество повторений
  bool _showBigNumbers = false; // Показывать большие цифры на последних 3

  @override
  void initState() {
    super.initState();
    _repCounter.setExerciseType(widget.exercise.id);
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('Камера не найдена');
        return;
      }

      // Используем фронтальную камеру если доступна
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _imageSize = Size(
            _cameraController!.value.previewSize!.height,
            _cameraController!.value.previewSize!.width,
          );
        });
        
        debugPrint('✅ Камера инициализирована, _isCameraInitialized = true');
        // НЕ запускаем отсчёт автоматически
        // Пользователь должен нажать кнопку "Начать"
      }
    } catch (e) {
      _showError('Ошибка инициализации камеры: $e');
    }
  }

  void _startPoseDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('❌ Камера не инициализирована для детекции');
      return;
    }

    debugPrint('🎥 Запуск детекции поз...');
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isDetecting && !_isProcessing) {
        _isDetecting = true;
        _detectPose(image);
      }
    });
  }

  Future<void> _detectPose(CameraImage image) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);
        
        debugPrint('🔍 Детекция: найдено ${poses.length} поз');
        
        if (poses.isNotEmpty && mounted) {
          final pose = poses.first;
          debugPrint('✅ Поза найдена, точек: ${pose.landmarks.length}');
          
          final result = _repCounter.analyzePose(pose);
          
          // Проверяем, нужно ли показать большие цифры (последние 3 повторения)
          final remaining = _targetReps - result.repCount;
          final shouldShowBig = remaining <= 3 && remaining > 0;
          
          setState(() {
            _currentPose = pose;
            _currentResult = result;
            _showBigNumbers = shouldShowBig;
          });
          
          // Проверяем завершение упражнения
          if (result.repCount >= _targetReps) {
            _onWorkoutComplete();
          }
        } else {
          debugPrint('❌ Позы не найдены');
        }
      } else {
        debugPrint('❌ Не удалось конвертировать изображение');
      }
    } catch (e) {
      debugPrint('Ошибка детекции позы: $e');
    } finally {
      setState(() {
        _isDetecting = false;
        _isProcessing = false;
      });
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Для эмулятора используем упрощенную конвертацию
      final bytes = <int>[];
      
      // Собираем все байты из всех плоскостей
      for (final plane in image.planes) {
        bytes.addAll(plane.bytes);
      }
      
      final inputImageMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg, // Упрощаем - без поворота
        format: InputImageFormat.yuv420, // Стандартный формат
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: Uint8List.fromList(bytes),
        metadata: inputImageMetadata,
      );
    } catch (e) {
      debugPrint('Ошибка конвертации изображения: $e');
      
      // Альтернативный способ - используем только первую плоскость
      try {
        final inputImageMetadata = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes.first.bytesPerRow,
        );

        return InputImage.fromBytes(
          bytes: image.planes.first.bytes,
          metadata: inputImageMetadata,
        );
      } catch (e2) {
        debugPrint('Альтернативная конвертация тоже не сработала: $e2');
        return null;
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Запускает обратный отсчёт перед началом тренировки
  void _startCountdown() {
    debugPrint('🔍 _startCountdown вызван. _isCameraInitialized: $_isCameraInitialized');
    if (!_isCameraInitialized) {
      debugPrint('❌ Камера не инициализирована, отсчёт не запускается');
      return;
    }
    
    debugPrint('🚀 Запуск обратного отсчёта');
    setState(() {
      _isCountdownActive = true;
    });
    debugPrint('✅ _isCountdownActive установлен в true');
  }

  /// Завершает обратный отсчёт и запускает тренировку
  void _onCountdownComplete() {
    debugPrint('✅ Обратный отсчёт завершён, запуск тренировки');
    setState(() {
      _isCountdownActive = false;
      _isWorkoutStarted = true;
    });
    
    _startPoseDetection();
  }

  /// Останавливает тренировку и сбрасывает состояние
  void _stopWorkout() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    
    setState(() {
      _isWorkoutStarted = false;
      _isCountdownActive = false;
      _isDetecting = false;
      _isProcessing = false;
      _currentPose = null;
      _currentResult = null;
    });
    
    _repCounter.reset();
  }

  /// Завершает упражнение
  void _onWorkoutComplete() {
    _stopWorkout();
    
    if (widget.onWorkoutComplete != null) {
      // Если это часть комплекса, вызываем колбэк
      widget.onWorkoutComplete!();
    } else {
      // Если это отдельное упражнение, показываем сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Упражнение "${widget.exercise.nameRu}" завершено!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.showComplexProgress 
                ? widget.complexName
                : '${widget.exercise.nameRu} (Оптимизированный)',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (widget.showComplexProgress)
              Text(
                '${widget.exercise.nameRu} (${widget.currentExercise}/${widget.totalExercises})',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Кнопка начать/остановить тренировку
          if (!_isWorkoutStarted && !_isCountdownActive)
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green, size: 32),
              onPressed: _startCountdown,
              tooltip: 'Начать тренировку',
            ),
          if (_isWorkoutStarted)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red, size: 32),
              onPressed: _stopWorkout,
              tooltip: 'Остановить тренировку',
            ),
          IconButton(
            icon: Icon(_showInfo ? Icons.info : Icons.info_outline),
            onPressed: () {
              setState(() {
                _showInfo = !_showInfo;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _repCounter.reset();
              setState(() {
                _currentResult = null;
              });
            },
          ),
        ],
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                // Превью камеры
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                
                // Наложение с позой
                if (_currentPose != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: OptimizedPosePainter(
                        pose: _currentPose!,
                        imageSize: _imageSize,
                        keyPoints: _currentResult?.keyPointsUsed ?? [],
                        confidence: _currentResult?.confidence ?? 0.0,
                        exerciseQuality: _currentResult?.exerciseQuality,
                      ),
                    ),
                  ),
                
                // Счетчик повторений
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_targetReps - (_currentResult?.repCount ?? 0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'осталось из $_targetReps',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Обратная связь
                if (_currentResult != null)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentResult!.feedback,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                
                // Информационная панель
                if (_showInfo && _currentResult != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: KeyPointsInfoWidget(
                      keyPoints: _currentResult!.keyPointsUsed,
                      confidence: _currentResult!.confidence,
                      exerciseQuality: _currentResult!.exerciseQuality,
                      formCorrections: _currentResult!.formCorrection,
                      exerciseType: widget.exercise.id,
                    ),
                  ),
                
                // Индикатор обработки
                if (_isProcessing)
                  Positioned(
                    top: 100,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Анализ...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Обратный отсчёт
                if (_isCountdownActive)
                  Positioned.fill(
                    child: CountdownWidget(
                      onCountdownComplete: _onCountdownComplete,
                    ),
                  ),
                
                // Большие цифры для последних 3 повторений
                if (_showBigNumbers && _currentResult != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.withValues(alpha: 0.2),
                            border: Border.all(
                              color: Colors.orange,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${_targetReps - _currentResult!.repCount}',
                              style: const TextStyle(
                                fontSize: 120,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Инструкция для начала тренировки
                if (!_isWorkoutStarted && !_isCountdownActive)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_circle_outline,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите кнопку ▶ чтобы начать тренировку',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Будет 3-секундный обратный отсчёт',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Инициализация камеры...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
    );
  }
}