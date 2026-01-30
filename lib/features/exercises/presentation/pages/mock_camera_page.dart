import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitmonster/features/exercises/services/optimized_rep_counter.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/optimized_pose_painter.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/countdown_widget.dart';
import 'package:fitmonster/features/exercises/domain/models/exercise.dart';

/// Страница камеры с имитацией детекции позы для эмулятора
class MockCameraPage extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback? onWorkoutComplete;
  final bool showComplexProgress;
  final int currentExercise;
  final int totalExercises;
  final String complexName;

  const MockCameraPage({
    super.key,
    required this.exercise,
    this.onWorkoutComplete,
    this.showComplexProgress = false,
    this.currentExercise = 1,
    this.totalExercises = 1,
    this.complexName = '',
  });

  @override
  State<MockCameraPage> createState() => _MockCameraPageState();
}

class _MockCameraPageState extends State<MockCameraPage> {
  CameraController? _cameraController;
  final OptimizedRepCounter _repCounter = OptimizedRepCounter();
  
  bool _isCameraInitialized = false;
  Pose? _currentPose;
  OptimizedRepCountResult? _currentResult;
  Size _imageSize = const Size(640, 480);
  bool _showInfo = true;
  
  // Состояние для обратного отсчёта
  bool _isCountdownActive = false;
  bool _isWorkoutStarted = false;
  
  // Настройки тренировки
  int _targetReps = 15;
  bool _showBigNumbers = false;
  
  // Имитация данных
  Timer? _mockTimer;
  double _mockAngle = 180.0; // Угол колена для имитации
  bool _isGoingDown = true;
  int _mockFrameCount = 0;

  @override
  void initState() {
    super.initState();
    _repCounter.setExerciseType(widget.exercise.id);
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _mockTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('Камера не найдена');
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
      );

      await _cameraController!.initialize();
      
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      _showError('Ошибка инициализации камеры: $e');
    }
  }

  void _startMockDetection() {
    debugPrint('🎭 Запуск имитации детекции позы...');
    
    _mockTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isWorkoutStarted) return;
      
      _mockFrameCount++;
      
      // Имитируем движение приседания
      if (_isGoingDown) {
        _mockAngle -= 3.0; // Опускаемся
        if (_mockAngle <= 120) {
          _isGoingDown = false;
        }
      } else {
        _mockAngle += 3.0; // Поднимаемся
        if (_mockAngle >= 180) {
          _isGoingDown = true;
        }
      }
      
      // Создаем фиктивную позу
      final mockPose = _createMockPose(_mockAngle);
      final result = _repCounter.analyzePose(mockPose);
      
      // Проверяем, нужно ли показать большие цифры
      final remaining = _targetReps - result.repCount;
      final shouldShowBig = remaining <= 3 && remaining > 0;
      
      setState(() {
        _currentPose = mockPose;
        _currentResult = result;
        _showBigNumbers = shouldShowBig;
      });
      
      // Проверяем завершение упражнения
      if (result.repCount >= _targetReps) {
        _onWorkoutComplete();
      }
    });
  }

  Pose _createMockPose(double kneeAngle) {
    // Создаем фиктивные координаты для ключевых точек
    final landmarks = <PoseLandmarkType, PoseLandmark>{};
    
    // Базовые координаты (центр экрана)
    const centerX = 320.0;
    const centerY = 240.0;
    
    // Плечи
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: centerX - 50,
      y: centerY - 100,
      z: 0,
      likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: centerX + 50,
      y: centerY - 100,
      z: 0,
      likelihood: 0.9,
    );
    
    // Бедра
    landmarks[PoseLandmarkType.leftHip] = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: centerX - 30,
      y: centerY,
      z: 0,
      likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightHip] = PoseLandmark(
      type: PoseLandmarkType.rightHip,
      x: centerX + 30,
      y: centerY,
      z: 0,
      likelihood: 0.9,
    );
    
    // Колени (зависят от угла приседания)
    final kneeOffset = (180 - kneeAngle) * 0.5; // Чем меньше угол, тем ниже колени
    landmarks[PoseLandmarkType.leftKnee] = PoseLandmark(
      type: PoseLandmarkType.leftKnee,
      x: centerX - 35,
      y: centerY + 80 + kneeOffset,
      z: 0,
      likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightKnee] = PoseLandmark(
      type: PoseLandmarkType.rightKnee,
      x: centerX + 35,
      y: centerY + 80 + kneeOffset,
      z: 0,
      likelihood: 0.9,
    );
    
    // Лодыжки
    landmarks[PoseLandmarkType.leftAnkle] = PoseLandmark(
      type: PoseLandmarkType.leftAnkle,
      x: centerX - 40,
      y: centerY + 160 + kneeOffset,
      z: 0,
      likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightAnkle] = PoseLandmark(
      type: PoseLandmarkType.rightAnkle,
      x: centerX + 40,
      y: centerY + 160 + kneeOffset,
      z: 0,
      likelihood: 0.9,
    );
    
    // Пятки
    landmarks[PoseLandmarkType.leftHeel] = PoseLandmark(
      type: PoseLandmarkType.leftHeel,
      x: centerX - 45,
      y: centerY + 170 + kneeOffset,
      z: 0,
      likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightHeel] = PoseLandmark(
      type: PoseLandmarkType.rightHeel,
      x: centerX + 45,
      y: centerY + 170 + kneeOffset,
      z: 0,
      likelihood: 0.9,
    );
    
    return Pose(landmarks: landmarks);
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

  void _startCountdown() {
    debugPrint('🔍 _startCountdown вызван (MOCK версия)');
    if (!_isCameraInitialized) {
      debugPrint('❌ Камера не инициализирована, отсчёт не запускается');
      return;
    }
    
    debugPrint('🚀 Запуск обратного отсчёта (MOCK)');
    setState(() {
      _isCountdownActive = true;
    });
  }

  void _onCountdownComplete() {
    debugPrint('✅ Обратный отсчёт завершён, запуск имитации тренировки');
    setState(() {
      _isCountdownActive = false;
      _isWorkoutStarted = true;
    });
    
    _startMockDetection();
  }

  void _stopWorkout() {
    _mockTimer?.cancel();
    
    setState(() {
      _isWorkoutStarted = false;
      _isCountdownActive = false;
      _currentPose = null;
      _currentResult = null;
    });
    
    _repCounter.reset();
  }

  void _onWorkoutComplete() {
    _stopWorkout();
    
    if (widget.onWorkoutComplete != null) {
      widget.onWorkoutComplete!();
    } else {
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
                : '${widget.exercise.nameRu} (DEMO)',
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
        ],
      ),
      body: Stack(
        children: [
          // Камера
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Инициализация камеры...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          
          // Наложение с позой (DEMO версия)
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
          
          // DEMO метка
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          
          // Счетчик повторений
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_targetReps - (_currentResult?.repCount ?? 0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
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
          
          // Feedback
          if (_currentResult != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentResult!.feedback,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
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
                    ),
                    child: Center(
                      child: Text(
                        '${_targetReps - _currentResult!.repCount}',
                        style: const TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
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
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎭 DEMO РЕЖИМ',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Имитация детекции позы для эмулятора.\nНажмите ▶️ для начала тренировки.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}