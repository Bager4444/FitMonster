import 'dart:async';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

/// Ультра-оптимизированный сервис камеры для достижения 7+ FPS
/// Использует изоляты, кэширование и умную обработку кадров
class UltraOptimizedCameraService {
  static const int TARGET_FPS = 8; // Целевой FPS
  static const int FRAME_SKIP_RATIO = 2; // Обрабатываем каждый 2-й кадр
  static const int ML_PROCESS_INTERVAL = 3; // ML Kit каждый 3-й обработанный кадр
  
  // Изолят для обработки изображений
  Isolate? _processingIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _isolateReceivePort;
  
  // Кэш для оптимизации
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const int CACHE_VALIDITY_MS = 150;
  
  // Счетчики для оптимизации
  int _frameCounter = 0;
  int _mlProcessCounter = 0;
  DateTime _lastFrameTime = DateTime.now();
  
  // Статистика производительности
  int _processedFrames = 0;
  DateTime _statsStartTime = DateTime.now();
  double _currentFPS = 0.0;
  
  // Callback для результатов
  Function(List<Pose>, double)? onPoseDetected;
  Function(String)? onError;
  
  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      await _initializeIsolate();
      print('✅ UltraOptimizedCameraService initialized');
    } catch (e) {
      print('❌ Error initializing camera service: $e');
      onError?.call('Ошибка инициализации: $e');
    }
  }
  
  /// Инициализация изолята для обработки
  Future<void> _initializeIsolate() async {
    _isolateReceivePort = ReceivePort();
    
    _processingIsolate = await Isolate.spawn(
      _isolateEntryPoint,
      _isolateReceivePort!.sendPort,
    );
    
    // Получаем SendPort от изолята
    final completer = Completer<SendPort>();
    _isolateReceivePort!.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else if (message is Map<String, dynamic>) {
        _handleIsolateResult(message);
      }
    });
    
    _isolateSendPort = await completer.future;
  }
  
  /// Точка входа для изолята
  static void _isolateEntryPoint(SendPort mainSendPort) async {
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);
    
    // Инициализируем ML Kit в изоляте
    PoseDetector? poseDetector;
    
    try {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base, // Используем базовую модель для скорости
      );
      poseDetector = PoseDetector(options: options);
    } catch (e) {
      mainSendPort.send({
        'type': 'error',
        'message': 'ML Kit initialization failed: $e'
      });
      return;
    }
    
    isolateReceivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        try {
          await _processImageInIsolate(message, poseDetector!, mainSendPort);
        } catch (e) {
          mainSendPort.send({
            'type': 'error',
            'message': 'Processing error: $e'
          });
        }
      }
    });
  }
  
  /// Обработка изображения в изоляте
  static Future<void> _processImageInIsolate(
    Map<String, dynamic> data,
    PoseDetector poseDetector,
    SendPort mainSendPort,
  ) async {
    try {
      final bytes = data['bytes'] as Uint8List;
      final width = data['width'] as int;
      final height = data['height'] as int;
      final rotation = data['rotation'] as int;
      final shouldProcessML = data['processML'] as bool;
      
      if (!shouldProcessML) {
        // Быстрый ответ без ML обработки
        mainSendPort.send({
          'type': 'frame_processed',
          'poses': <Map<String, dynamic>>[],
          'fps': data['fps'],
          'skipped_ml': true,
        });
        return;
      }
      
      // Создаем InputImage
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: _intToInputImageRotation(rotation),
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );
      
      // Обрабатываем с ML Kit
      final poses = await poseDetector.processImage(inputImage);
      
      // Сериализуем результат
      final serializedPoses = poses.map((pose) => _serializePose(pose)).toList();
      
      mainSendPort.send({
        'type': 'poses_detected',
        'poses': serializedPoses,
        'fps': data['fps'],
        'skipped_ml': false,
      });
    } catch (e) {
      mainSendPort.send({
        'type': 'error',
        'message': 'Isolate processing error: $e'
      });
    }
  }
  
  /// Сериализация позы для передачи между изолятами
  static Map<String, dynamic> _serializePose(Pose pose) {
    final landmarks = <String, Map<String, dynamic>>{};
    
    for (final entry in pose.landmarks.entries) {
      landmarks[entry.key.name] = {
        'x': entry.value.x,
        'y': entry.value.y,
        'z': entry.value.z,
        'likelihood': entry.value.likelihood,
      };
    }
    
    return {
      'landmarks': landmarks,
    };
  }
  
  /// Десериализация позы
  List<Pose> _deserializePoses(List<dynamic> serializedPoses) {
    return serializedPoses.map((poseData) {
      final landmarks = <PoseLandmarkType, PoseLandmark>{};
      
      final landmarksData = poseData['landmarks'] as Map<String, dynamic>;
      for (final entry in landmarksData.entries) {
        final landmarkType = _stringToPoseLandmarkType(entry.key);
        if (landmarkType != null) {
          final data = entry.value as Map<String, dynamic>;
          landmarks[landmarkType] = PoseLandmark(
            type: landmarkType,
            x: data['x'] as double,
            y: data['y'] as double,
            z: data['z'] as double,
            likelihood: data['likelihood'] as double,
          );
        }
      }
      
      return Pose(landmarks: landmarks);
    }).toList();
  }
  
  /// Обработка кадра камеры с ультра-оптимизацией
  Future<void> processFrame(CameraImage image) async {
    _frameCounter++;
    
    // Пропускаем кадры для достижения целевого FPS
    if (_frameCounter % FRAME_SKIP_RATIO != 0) {
      return;
    }
    
    final now = DateTime.now();
    final timeSinceLastFrame = now.difference(_lastFrameTime).inMilliseconds;
    final minFrameInterval = 1000 ~/ TARGET_FPS;
    
    if (timeSinceLastFrame < minFrameInterval) {
      return; // Слишком рано для следующего кадра
    }
    
    _lastFrameTime = now;
    
    try {
      // Определяем, нужно ли обрабатывать ML Kit
      _mlProcessCounter++;
      final shouldProcessML = _mlProcessCounter % ML_PROCESS_INTERVAL == 0;
      
      // Быстрая конвертация изображения
      final bytes = await _ultraFastYuvToNv21(image);
      if (bytes == null) {
        onError?.call('Ошибка конвертации изображения');
        return;
      }
      
      // Вычисляем текущий FPS
      _updateFPSStats();
      
      // Отправляем в изолят для обработки
      if (_isolateSendPort != null) {
        _isolateSendPort!.send({
          'bytes': bytes,
          'width': image.width,
          'height': image.height,
          'rotation': _getRotationValue(),
          'processML': shouldProcessML,
          'fps': _currentFPS,
        });
      }
    } catch (e) {
      print('❌ Error processing frame: $e');
      onError?.call('Ошибка обработки кадра: $e');
    }
  }
  
  /// Ультра-быстрая конвертация YUV420 в NV21
  Future<Uint8List?> _ultraFastYuvToNv21(CameraImage image) async {
    try {
      // Проверяем кэш
      final cacheKey = '${image.width}x${image.height}';
      final now = DateTime.now();
      
      if (_imageCache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
        final cacheTime = _cacheTimestamps[cacheKey]!;
        if (now.difference(cacheTime).inMilliseconds < CACHE_VALIDITY_MS) {
          // Используем кэшированный буфер (только структуру)
          final cachedBuffer = _imageCache[cacheKey]!;
          return _fastCopyYuvData(image, cachedBuffer);
        }
      }
      
      // Создаем новый буфер
      final width = image.width;
      final height = image.height;
      final buffer = Uint8List(width * height + (width * height ~/ 2));
      
      // Кэшируем структуру буфера
      _imageCache[cacheKey] = buffer;
      _cacheTimestamps[cacheKey] = now;
      
      return _fastCopyYuvData(image, buffer);
    } catch (e) {
      print('❌ YUV conversion error: $e');
      return null;
    }
  }
  
  /// Быстрое копирование YUV данных
  Uint8List _fastCopyYuvData(CameraImage image, Uint8List buffer) {
    final width = image.width;
    final height = image.height;
    
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    
    // Копируем Y плоскость (самая большая часть)
    int bufferIndex = 0;
    final yBytes = yPlane.bytes;
    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    
    if (yPixelStride == 1 && yRowStride == width) {
      // Оптимизированное копирование для непрерывных данных
      buffer.setRange(0, width * height, yBytes);
      bufferIndex = width * height;
    } else {
      // Построчное копирование
      for (int y = 0; y < height; y++) {
        final rowStart = y * yRowStride;
        for (int x = 0; x < width; x++) {
          buffer[bufferIndex++] = yBytes[rowStart + x * yPixelStride];
        }
      }
    }
    
    // Копируем UV плоскости (NV21 формат: VUVUVU...)
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final uIndex = (uRowStride * y) + x * uPixelStride;
        final vIndex = (vRowStride * y) + x * vPixelStride;
        
        // NV21: V затем U
        buffer[bufferIndex++] = vBytes[vIndex];
        buffer[bufferIndex++] = uBytes[uIndex];
      }
    }
    
    return buffer;
  }
  
  /// Обработка результата из изолята
  void _handleIsolateResult(Map<String, dynamic> result) {
    try {
      final type = result['type'] as String;
      
      switch (type) {
        case 'poses_detected':
          final serializedPoses = result['poses'] as List<dynamic>;
          final poses = _deserializePoses(serializedPoses);
          final fps = result['fps'] as double;
          onPoseDetected?.call(poses, fps);
          break;
          
        case 'frame_processed':
          final fps = result['fps'] as double;
          onPoseDetected?.call([], fps);
          break;
          
        case 'error':
          final message = result['message'] as String;
          onError?.call(message);
          break;
      }
    } catch (e) {
      print('❌ Error handling isolate result: $e');
      onError?.call('Ошибка обработки результата: $e');
    }
  }
  
  /// Обновление статистики FPS
  void _updateFPSStats() {
    _processedFrames++;
    final now = DateTime.now();
    final elapsed = now.difference(_statsStartTime).inMilliseconds;
    
    if (elapsed >= 1000) {
      _currentFPS = _processedFrames * 1000.0 / elapsed;
      _processedFrames = 0;
      _statsStartTime = now;
    }
  }
  
  /// Получение значения поворота
  int _getRotationValue() {
    // Возвращаем 0 для упрощения, можно расширить при необходимости
    return 0;
  }
  
  /// Конвертация int в InputImageRotation
  static InputImageRotation _intToInputImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
  
  /// Конвертация строки в PoseLandmarkType
  PoseLandmarkType? _stringToPoseLandmarkType(String name) {
    try {
      return PoseLandmarkType.values.firstWhere((type) => type.name == name);
    } catch (e) {
      return null;
    }
  }
  
  /// Очистка ресурсов
  Future<void> dispose() async {
    try {
      _processingIsolate?.kill();
      _isolateReceivePort?.close();
      _imageCache.clear();
      _cacheTimestamps.clear();
      print('✅ UltraOptimizedCameraService disposed');
    } catch (e) {
      print('❌ Error disposing camera service: $e');
    }
  }
  
  /// Получение текущего FPS
  double get currentFPS => _currentFPS;
  
  /// Получение статистики
  Map<String, dynamic> getStats() {
    return {
      'fps': _currentFPS,
      'processed_frames': _processedFrames,
      'cache_size': _imageCache.length,
      'target_fps': TARGET_FPS,
    };
  }
}