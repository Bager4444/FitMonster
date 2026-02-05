import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/features/exercises/domain/models/exercise.dart';
import 'package:fitmonster/features/exercises/domain/models/workout_complex.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/pose_painter.dart';
import 'package:fitmonster/features/exercises/domain/services/workout_service.dart';
import 'package:fitmonster/features/exercises/domain/models/workout_session.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/workout_results_dialog.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/rest_timer_dialog.dart';
import 'package:fitmonster/features/exercises/services/improved_rep_counter.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/countdown_widget.dart';
import 'package:fitmonster/features/profile/services/experience_service.dart';
import 'package:fitmonster/features/profile/presentation/widgets/experience_notification.dart';
import 'dart:async';
import 'dart:typed_data';

class ExerciseCameraPage extends StatefulWidget {
  final Exercise exercise;
  final WorkoutComplex? complex;
  final int? currentExerciseIndex;
  final VoidCallback? onExerciseComplete;

  const ExerciseCameraPage({
    super.key,
    required this.exercise,
    this.complex,
    this.currentExerciseIndex,
    this.onExerciseComplete,
  });

  @override
  State<ExerciseCameraPage> createState() => _ExerciseCameraPageState();
}

class _ExerciseCameraPageState extends State<ExerciseCameraPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  int _repCount = 0;
  static const int _targetReps = 5; // Целевое количество повторений
  double _formScore = 0.0;
  String _feedback = 'Встаньте в кадр';
  Timer? _feedbackTimer;
  
  // Параметры входного изображения для корректной отрисовки позы
  InputImageRotation _inputImageRotation = InputImageRotation.rotation0deg;
  Size _inputImageSize = Size.zero;
  
  // Дополнительные поля для улучшенного UI
  DateTime? _workoutStartTime;
  Duration _workoutDuration = Duration.zero;
  Timer? _durationTimer;
  
  // Интеграция с сервисом тренировок
  final WorkoutService _workoutService = WorkoutService();
  WorkoutSession? _currentSession;
  
  // ML Kit
  PoseDetector? _poseDetector;
  List<Pose> _poses = [];
  
  // FPS мониторинг
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  double _currentFps = 0.0;
  
  // Улучшенный счетчик повторений
  final ImprovedRepCounter _repCounter = ImprovedRepCounter();
  
  // Флаг обработки кадра
  bool _isProcessingFrame = false;
  DateTime _lastFrameTime = DateTime.now();
  static const int _targetFps = 10; // Баланс: отзывчивость + умеренная нагрузка на CPU
  int _frameSkipCounter = 0;
  static const int _frameSkipRate = 2; // Обрабатываем каждый 2-й кадр
  
  // Система опыта
  int _lastRepCountForExp = 0; // Последний подсчитанный репкаунт для опыта
  int _lastTimeForExp = 0; // Последнее время для опыта (для планки)
  
  DateTime _lastPoseLog = DateTime.fromMillisecondsSinceEpoch(0);
  
  // Состояние для обратного отсчёта
  bool _isCountdownActive = false;
  bool _isWorkoutStarted = false;

  @override
  void initState() {
    super.initState();
    // Быстрая инициализация без задержек
    _initializePoseDetector();
    _initializeCamera();
  }

  void _initializePoseDetector() {
    // Быстрая инициализация ML Kit Pose Detection
    try {
      if (!mounted) return;
      
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      );
      _poseDetector = PoseDetector(options: options);
      print('✅ ML Kit PoseDetector initialized (stream mode, accurate model)');
    } catch (e) {
      print('❌ Error initializing ML Kit: $e');
      if (mounted) {
        setState(() {
          _feedback = 'Ошибка инициализации ML анализа';
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _feedback = 'Камера не найдена';
        });
        return;
      }

      // Используем фронтальную камеру
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
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
        
        debugPrint('✅ Камера инициализирована быстро, _isInitialized = true');
      }
      
      print('✅ Camera initialized: ${frontCamera.lensDirection}, resolution: medium');
    } catch (e) {
      print('❌ Camera initialization error: $e');
      setState(() {
        _feedback = 'Ошибка инициализации камеры: $e';
      });
    }
  }

  /// Запускает обратный отсчёт перед началом тренировки
  void _startCountdown() {
    debugPrint('🔍 _startCountdown вызван (обычный режим). _isInitialized: $_isInitialized');
    if (!_isInitialized) {
      debugPrint('❌ Камера не инициализирована, отсчёт не запускается (обычный режим)');
      return;
    }
    
    debugPrint('🚀 Запуск обратного отсчёта (обычный режим)');
    setState(() {
      _isCountdownActive = true;
    });
    debugPrint('✅ _isCountdownActive установлен в true (обычный режим)');
  }

  /// Завершает обратный отсчёт и запускает тренировку
  void _onCountdownComplete() {
    debugPrint('✅ Обратный отсчёт завершён, запуск тренировки (обычный режим)');
    setState(() {
      _isCountdownActive = false;
      _isWorkoutStarted = true;
    });
    
    _startExercise();
  }

  void _startExercise() async {
    // Защита от повторного запуска
    if (_isRecording) {
      print('⚠️ Exercise already running');
      return;
    }
    
    try {
      setState(() {
        _feedback = 'Подготовка...';
      });
      
      // Создаем новую сессию тренировки (работает и без авторизации)
      try {
        _currentSession = await _workoutService.startWorkout(
          exercise: widget.exercise,
          targetReps: 5,
        );
      } catch (e) {
        print('Тренировка без сохранения: $e');
      }
      
      // Настраиваем счетчик для текущего упражнения
      _repCounter.setExerciseType(widget.exercise.id);
      _repCounter.reset();
      _repCounter.setExerciseType(widget.exercise.id);
      
      setState(() {
        _isRecording = true;
        _repCount = 0;
        _formScore = 0.0;
        _feedback = 'Начинайте упражнение!';
        _workoutStartTime = DateTime.now();
        _workoutDuration = Duration.zero;
        _isProcessingFrame = false;
        _frameSkipCounter = 0;
        // Сбрасываем счетчики опыта
        _lastRepCountForExp = 0;
        _lastTimeForExp = 0;
      });
      
      // Запускаем таймер для отслеживания времени тренировки
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_isRecording) {
          timer.cancel();
          return;
        }
        
        setState(() {
          _workoutDuration = DateTime.now().difference(_workoutStartTime!);
        });
      });
      
      // Запускаем обработку кадров
      _startImageStream();
      
      print('✅ Exercise started: ${widget.exercise.nameRu}');
    } catch (e) {
      print('❌ Error starting exercise: $e');
      setState(() {
        _feedback = 'Ошибка запуска тренировки: $e';
        _isRecording = false;
      });
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    print('📷 Starting camera image stream (target $_targetFps FPS, skip every $_frameSkipRate frame)');
    
    _cameraController!.startImageStream((CameraImage image) {
      // Пропускаем кадр если предыдущий еще обрабатывается
      if (!_isRecording || _isProcessingFrame) return;
      
      // Пропускаем каждый N-й кадр для дополнительного снижения нагрузки
      _frameSkipCounter++;
      if (_frameSkipCounter % _frameSkipRate != 0) {
        return;
      }
      
      // Ограничиваем FPS для снижения нагрузки
      final now = DateTime.now();
      final timeSinceLastFrame = now.difference(_lastFrameTime).inMilliseconds;
      final minFrameInterval = 1000 ~/ _targetFps; // ~200ms для 5 FPS
      
      if (timeSinceLastFrame < minFrameInterval) {
        return; // Пропускаем кадр
      }
      
      _lastFrameTime = now;
      _isProcessingFrame = true;
      
      _processImage(image).then((_) {
        _isProcessingFrame = false;
      }).catchError((e) {
        _isProcessingFrame = false;
        print('❌ Error in image processing: $e');
      });
      
      _frameCount++;
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_poseDetector == null) {
      print('❌ PoseDetector is null');
      return;
    }

    try {
      _updateFpsCounter();
      
      final inputImage = _createInputImageFromCameraImage(image);
      if (inputImage == null) {
        print('❌ Failed to create InputImage');
        return;
      }
      
      // Обрабатываем изображение с ML Kit
      final poses = await _poseDetector!.processImage(inputImage);
      final now = DateTime.now();
      if (now.difference(_lastPoseLog).inMilliseconds >= 1000) {
        final landmarksCount = poses.isNotEmpty ? poses.first.landmarks.length : 0;
        print(
          '🧍 poses=${poses.length} landmarks=$landmarksCount rotation=$_inputImageRotation size=$_inputImageSize fps=${_currentFps.toStringAsFixed(1)}',
        );
        _lastPoseLog = now;
      }
      
      if (mounted) {
        setState(() {
          _poses = poses;
          
          if (poses.isEmpty) {
            _feedback = 'Встаньте в кадр полностью';
          } else {
            final pose = poses.first;
            final confidence = _calculatePoseConfidence(pose);
            
            print('🔍 Pose confidence: $confidence%');
            
            if (confidence < 50) {
              _feedback = 'Улучшите освещение и встаньте ближе';
            } else {
              _feedback = 'Отличная техника! (${_currentFps.toStringAsFixed(0)} FPS)';
              _analyzeExercise(poses);
            }
          }
        });
      }
    } catch (e) {
      print('❌ Error processing image: $e');
    }
  }

  InputImage? _createInputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    try {
      final rotation = _getInputImageRotation();
      final size = Size(image.width.toDouble(), image.height.toDouble());

      // Сохраняем для отрисовки оверлея
      if (_inputImageSize != size || _inputImageRotation != rotation) {
        _inputImageSize = size;
        _inputImageRotation = rotation;
      }

      final formatGroup = image.format.group;

      // Самый частый кейс на Android/эмуляторе: YUV420 -> NV21
      if (formatGroup == ImageFormatGroup.yuv420) {
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

      // Часто на iOS: BGRA8888
      if (formatGroup == ImageFormatGroup.bgra8888) {
        final plane = image.planes.first;
        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: size,
            rotation: rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      }

      print('❌ Unsupported image format group: $formatGroup');
      return null;
    } catch (e) {
      print('❌ Error creating InputImage: $e');
      return null;
    }
  }

  InputImageRotation _getInputImageRotation() {
    final sensorOrientation = _cameraController?.description.sensorOrientation ?? 0;
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;

    final uRowStride = uPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;

    final vRowStride = vPlane.bytesPerRow;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    final out = Uint8List(width * height + (width * height ~/ 2));

    // Y
    int outIndex = 0;
    for (int y = 0; y < height; y++) {
      int yRow = yRowStride * y;
      for (int x = 0; x < width; x++) {
        out[outIndex++] = yBytes[yRow + x * yPixelStride];
      }
    }

    // VU (NV21)
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final uIndex = (uRowStride * y) + x * uPixelStride;
        final vIndex = (vRowStride * y) + x * vPixelStride;
        // NV21 = V then U
        out[outIndex++] = vBytes[vIndex];
        out[outIndex++] = uBytes[uIndex];
      }
    }

    return out;
  }

  double _calculatePoseConfidence(Pose pose) {
    if (pose.landmarks.isEmpty) return 0.0;
    
    double totalConfidence = 0;
    int landmarkCount = 0;
    
    for (final landmark in pose.landmarks.values) {
      totalConfidence += landmark.likelihood;
      landmarkCount++;
    }
    
    return landmarkCount > 0 ? (totalConfidence / landmarkCount) * 100 : 0.0;
  }
  
  void _analyzeExercise(List<Pose> poses) {
    if (poses.isEmpty) return;
    
    final pose = poses.first;
    
    // Подсчитываем уверенность детекции
    double totalConfidence = 0;
    int landmarkCount = 0;
    
    for (final landmark in pose.landmarks.values) {
      totalConfidence += landmark.likelihood;
      landmarkCount++;
    }
    
    if (landmarkCount > 0) {
      double averageConfidence = totalConfidence / landmarkCount;
      _formScore = (averageConfidence * 100).clamp(0, 100);
      
      // Используем улучшенный счетчик повторений
      final result = _repCounter.analyzePose(pose);
      
      // Обновляем состояние
      if (result.repCount > _repCount) {
        // Новое повторение!
        _repCount = result.repCount;
        
        // Начисляем опыт за новые повторения/время
        _awardExperience();
        
        // Проверяем завершение упражнения (только для комплексов)
        if (widget.complex != null) {
          bool shouldComplete = false;
          
          if (_isStaticExercise()) {
            // Для планки завершаем через 30 секунд
            shouldComplete = _repCount >= 30;
          } else {
            // Для обычных упражнений завершаем по количеству повторений
            shouldComplete = _repCount >= _targetReps;
          }
          
          if (shouldComplete) {
            _completeExercise();
            return;
          }
        }
        
        // Сохраняем повторение в сессию
        if (_currentSession != null) {
          _workoutService.addRep(
            _currentSession!,
            formScore: _formScore,
            isCorrect: _formScore > 60,
          ).then((session) {
            _currentSession = session;
          }).catchError((e) {
            print('❌ Error saving rep: $e');
          });
        }
      }
      
      // Обновляем обратную связь
      if (result.confidence > 0.5) {
        _feedback = result.feedback;
      }
    }
  }
  
  /// Определяет, является ли упражнение статическим (планка)
  bool _isStaticExercise() {
    const staticIds = ['plank', 'side_plank', 'downward_dog', 'superman', 'plank_leg_lifts'];
    return staticIds.contains(widget.exercise.id);
  }
  
  /// Возвращает текст для отображения в большом счетчике
  String _getDisplayText() {
    if (_isStaticExercise()) {
      // Для планки показываем время в секундах с целью
      if (widget.complex != null) {
        return '${_repCount}с/30с';
      } else {
        return '${_repCount}с';
      }
    } else {
      // Для обычных упражнений показываем повторения
      if (widget.complex != null) {
        return '$_repCount/$_targetReps';
      } else {
        return '$_repCount';
      }
    }
  }
  
  /// Возвращает метку для статистической карточки
  String _getStatLabel() {
    return _isStaticExercise() ? 'Время' : 'Повторения';
  }
  
  /// Возвращает значение для статистической карточки
  String _getStatValue() {
    if (_isStaticExercise()) {
      if (widget.complex != null) {
        return '${_repCount}с/30с';
      } else {
        return '${_repCount}с';
      }
    } else {
      if (widget.complex != null) {
        return '$_repCount/$_targetReps';
      } else {
        return '$_repCount';
      }
    }
  }
  
  /// Возвращает иконку для статистической карточки
  IconData _getStatIcon() {
    return _isStaticExercise() ? Icons.timer : Icons.repeat;
  }

  /// Начисляет опыт за выполненные повторения или время
  void _awardExperience() async {
    if (!mounted) return;
    
    int experienceToAward = 0;
    
    if (_isStaticExercise()) {
      // Для планки: 1 опыт за каждые 15 секунд (как изначально планировалось)
      final currentTime = _repCount; // _repCount содержит секунды для планки
      final timeIntervals = currentTime ~/ 15; // Количество интервалов по 15 секунд
      final lastTimeIntervals = _lastTimeForExp ~/ 15;
      
      if (timeIntervals > lastTimeIntervals) {
        experienceToAward = timeIntervals - lastTimeIntervals; // 1 опыт за интервал
        _lastTimeForExp = currentTime;
      }
    } else {
      // Для обычных упражнений: 1 опыт за каждое повторение
      if (_repCount > _lastRepCountForExp) {
        experienceToAward = _repCount - _lastRepCountForExp; // 1 опыт за повторение
        _lastRepCountForExp = _repCount;
      }
    }
    
    if (experienceToAward > 0) {
      try {
        final result = await ExperienceService.addExperience(experienceToAward);
        
        if (mounted) {
          showExperienceNotification(context, result);
        }
      } catch (e) {
        print('Ошибка при начислении опыта: $e');
      }
    }
  }

  void _completeExercise() async {
    // Показываем экран завершения упражнения
    setState(() {
      _feedback = 'Упражнение завершено! Отличная работа! 🎉';
    });
    
    // Останавливаем камеру
    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      print('⚠️ Error stopping camera: $e');
    }
    
    // Если это часть комплекса, вызываем callback (НЕ делаем pop — камера встроена в ComplexWorkoutPage)
    if (widget.complex != null && widget.onExerciseComplete != null) {
      widget.onExerciseComplete!();
      return;
    }
    
    // Показываем экран выбора перерыва для отдельных упражнений
    if (mounted) {
      _showRestDialog();
    }
  }

  void _showRestDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Упражнение завершено!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Отличная работа! Вы выполнили $_targetReps повторений.'),
            const SizedBox(height: 16),
            const Text('Выберите время отдыха:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildRestButton('30 сек', 30),
                _buildRestButton('1 мин', 60),
                _buildRestButton('2 мин', 120),
                _buildRestButton('3 мин', 180),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Возврат к списку упражнений
            },
            child: const Text('Завершить'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Перезапускаем упражнение без отдыха
              _restartExercise();
            },
            child: const Text('Еще раз'),
          ),
        ],
      ),
    );
  }

  Widget _buildRestButton(String label, int seconds) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
        _startRestTimer(seconds);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: GlassTheme.gradientTop,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  void _startRestTimer(int seconds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RestTimerDialog(
        restSeconds: seconds,
        onRestComplete: () {
          Navigator.of(context).pop();
          _restartExercise();
        },
        onSkipRest: () {
          Navigator.of(context).pop();
          _restartExercise();
        },
      ),
    );
  }

  void _restartExercise() {
    // Перезапускаем упражнение
    _repCounter.reset();
    setState(() {
      _repCount = 0;
      _feedback = 'Готовы к следующему подходу!';
    });
    _startExercise();
  }

  void _stopExercise() async {
    setState(() {
      _isRecording = false;
    });
    
    _feedbackTimer?.cancel();
    _durationTimer?.cancel();
    
    // Останавливаем поток изображений
    try {
      // Останавливаем поток
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
        print('✅ Camera stream stopped');
      }
    } catch (e) {
      print('⚠️ Error stopping camera stream: $e');
    }
    
    // Завершаем сессию тренировки
    if (_currentSession != null) {
      try {
        final completedSession = await _workoutService.completeWorkout(_currentSession!);
        
        if (mounted) {
          setState(() {
            _feedback = 'Тренировка сохранена! Повторений: $_repCount';
          });
          
          // Показываем диалог с результатами
          final shouldRestart = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => WorkoutResultsDialog(
              session: completedSession,
              repsCompleted: _repCount,
              averageFormScore: _formScore,
              workoutDuration: _workoutDuration,
            ),
          );
          
          if (shouldRestart == true) {
            // Перезапускаем тренировку
            _startExercise();
          }
        }
      } catch (e) {
        print('❌ Error completing workout: $e');
        if (mounted) {
          setState(() {
            _feedback = 'Тренировка завершена! (ошибка сохранения)';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _feedback = 'Тренировка завершена!';
        });
      }
    }
  }

  void _updateFpsCounter() {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastFpsUpdate).inMilliseconds;
    
    if (timeDiff >= 1000) { // Обновляем FPS каждую секунду
      _currentFps = _frameCount * 1000.0 / timeDiff;
      _frameCount = 0;
      _lastFpsUpdate = now;
    }
  }

  @override
  void dispose() {
    // Останавливаем все таймеры
    _feedbackTimer?.cancel();
    _durationTimer?.cancel();
    
    // Останавливаем запись если активна
    _isRecording = false;
    
    // Освобождаем ресурсы камеры
    _cameraController?.dispose();
    
    // Закрываем ML Kit детектор
    _poseDetector?.close();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: GlassTheme.scaffoldGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Шапка в общем блоке: назад + название по центру
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: GlassTheme.textPrimary),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.exercise.nameRu,
                                        style: GlassTheme.titleStyle.copyWith(fontSize: 18),
                                      ),
                                      if (widget.complex != null && widget.currentExerciseIndex != null)
                                        Text(
                                          '${widget.currentExerciseIndex! + 1} из ${widget.complex!.exerciseIds.length} • ${widget.complex!.name}',
                                          style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _isInitialized
                              ? _buildMainInterface(themeProvider)
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(color: GlassTheme.glowCyan),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Инициализация камеры...',
                                        style: GlassTheme.titleStyle.copyWith(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainInterface(ThemeProvider themeProvider) {
    return Column(
      children: [
        // Камера
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
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
                      child: Builder(
                        builder: (context) {
                          final preview = FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize!.height,
                              height: _cameraController!.value.previewSize!.width,
                              child: CameraPreview(_cameraController!),
                            ),
                          );
                          // Камера в исходном состоянии: НЕ зеркалим превью.
                          return preview;
                        },
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  
                  // Overlay с позами (RepaintBoundary изолирует перерисовку)
                  if (_poses.isNotEmpty)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: PosePainter(
                            poses: _poses,
                            imageSize: _inputImageSize == Size.zero
                                ? Size(
                                    _cameraController?.value.previewSize?.width ?? 480,
                                    _cameraController?.value.previewSize?.height ?? 640,
                                  )
                                : _inputImageSize,
                            rotation: _inputImageRotation,
                            // Зеркалим только отрисовку "скелета"
                            mirror: _cameraController?.description.lensDirection ==
                                CameraLensDirection.front,
                          ),
                        ),
                      ),
                    ),
                  
                  // Индикатор записи
                  if (_isRecording)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record, 
                                 color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('REC', 
                                 style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  
                  // Счетчик повторений (большой)
                  if (_isRecording)
                    Positioned(
                      top: 16,
                      left: 16,
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
                              _getDisplayText(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.complex != null && widget.currentExerciseIndex != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${widget.currentExerciseIndex! + 1}/${widget.complex!.exerciseIds.length}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Builder(
                                builder: (context) {
                                  final remaining = widget.complex!.exerciseIds.length - widget.currentExerciseIndex! - 1;
                                  if (remaining == 0) {
                                    return const Text(
                                      'Последнее упражнение!',
                                      style: TextStyle(
                                        color: GlassTheme.gradientTop,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      'До перерыва: $remaining',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  
                  // Кнопка переключения камеры (в углу камеры)
                  if (!_isRecording)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _switchCamera,
                            child: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // FPS и время тренировки
                  if (_isRecording)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'FPS: ${_currentFps.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(_workoutDuration),
                              style: const TextStyle(
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
                ],
              ),
            ),
          ),
        ),
        
        // Статистика и управление (фон градиента просвечивает)
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Статистика
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      _getStatLabel(), 
                      _getStatValue(), 
                      _getStatIcon(), 
                      themeProvider
                    ),
                    _buildStatCard('Техника', '${_formScore.toInt()}%', Icons.star, themeProvider),
                    _buildStatCard('Время', _formatDuration(_workoutDuration), Icons.timer, themeProvider),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Обратная связь
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? GlassTheme.gradientTop.withValues(alpha: 0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isRecording
                          ? GlassTheme.gradientTop
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    _feedback,
                    style: GlassTheme.bodyStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Кнопки управления
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Кнопка "Начать"
                      _buildControlButton(
                        onPressed: _isRecording ? null : _startExercise,
                        icon: Icons.play_arrow,
                        label: 'Начать',
                        color: GlassTheme.gradientTop,
                        isEnabled: !_isRecording,
                        themeProvider: themeProvider,
                      ),
                      
                      // Кнопка "Остановить"
                      _buildControlButton(
                        onPressed: _isRecording ? _stopExercise : null,
                        icon: Icons.stop,
                        label: 'Стоп',
                        color: Colors.red,
                        isEnabled: _isRecording,
                        themeProvider: themeProvider,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isEnabled,
    required ThemeProvider themeProvider,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isEnabled ? color : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(28),
            boxShadow: isEnabled ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onPressed,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 100),
                scale: isEnabled ? 1.0 : 0.9,
                child: Icon(
                  icon,
                  color: isEnabled ? Colors.white : GlassTheme.textSecondary,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isEnabled ? color : GlassTheme.textSecondary,
          ),
          child: Text(label),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: GlassTheme.glowCyan, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GlassTheme.titleStyle.copyWith(fontSize: 16),
          ),
          Text(
            title,
            style: GlassTheme.bodyStyle.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentCamera = _cameraController!.description;
    final newCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection != currentCamera.lensDirection,
      orElse: () => currentCamera,
    );

    await _cameraController?.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.low, // Используем низкое разрешение для лучшей совместимости
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // Используем YUV420 формат
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {});
    }
  }
}
