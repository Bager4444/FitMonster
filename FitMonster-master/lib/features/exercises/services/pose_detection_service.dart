import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'optimized_pose_detection_service.dart';

/// Универсальный сервис для распознавания позы
/// Работает на всех платформах включая веб
/// Использует оптимизированный анализ критичных точек
class PoseDetectionService {
  int _frameCount = 0;
  DateTime _lastAnalysis = DateTime.now();

  /// Анализ кадра для определения позы с оптимизированным алгоритмом
  Future<PoseAnalysisResult> analyzeFrame(CameraImage image, {String exerciseType = 'squats'}) async {
    try {
      _frameCount++;
      
      // Ограничиваем частоту анализа (каждые 100ms для 10 FPS)
      final now = DateTime.now();
      if (now.difference(_lastAnalysis).inMilliseconds < 100) {
        return PoseAnalysisResult.empty();
      }
      _lastAnalysis = now;

      // Конвертируем изображение
      final imageData = await _convertCameraImage(image);
      if (imageData == null) {
        return PoseAnalysisResult.empty();
      }

      // Анализируем движение на основе изменений в пикселях
      final keypoints = await _detectKeypoints(imageData, image.width, image.height);
      
      if (keypoints.isEmpty) {
        return PoseAnalysisResult(
          isPersonVisible: false,
          feedback: 'Встан��те в кадр',
          repCount: 0,
          formScore: 0.0,
          keypoints: [],
        );
      }

      // Используем оптимизированный анализ
      final analysis = OptimizedPoseDetectionService.analyzePose(keypoints, exerciseType);
      

      
      return PoseAnalysisResult(
        isPersonVisible: true,
        feedback: analysis.feedback,
        repCount: _calculateReps(keypoints),
        formScore: analysis.accuracy,
        keypoints: keypoints,
        criticalErrors: analysis.criticalErrors,
        warnings: analysis.warnings,
      );
    } catch (e) {
      debugPrint('Ошибка анализа кадра: $e');
      return PoseAnalysisResult.empty();
    }
  }

  /// Конвертация CameraImage в Uint8List
  Future<Uint8List?> _convertCameraImage(CameraImage image) async {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToRGB(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return image.planes[0].bytes;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка конвертации изображения: $e');
      return null;
    }
  }

  /// Конвертация YUV420 в RGB
  Uint8List _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    
    final Uint8List yPlane = image.planes[0].bytes;
    final Uint8List uPlane = image.planes[1].bytes;
    final Uint8List vPlane = image.planes[2].bytes;
    
    final Uint8List rgb = Uint8List(width * height * 3);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);
        
        if (yIndex < yPlane.length && uvIndex < uPlane.length && uvIndex < vPlane.length) {
          final int yValue = yPlane[yIndex];
          final int uValue = uPlane[uvIndex];
          final int vValue = vPlane[uvIndex];
          
          // YUV to RGB conversion
          final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          final int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
          final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);
          
          final int rgbIndex = yIndex * 3;
          if (rgbIndex + 2 < rgb.length) {
            rgb[rgbIndex] = r;
            rgb[rgbIndex + 1] = g;
            rgb[rgbIndex + 2] = b;
          }
        }
      }
    }
    
    return rgb;
  }

  /// Детекция ключевых точек тела на основе анализа изображения
  Future<List<BodyKeypoint>> _detectKeypoints(Uint8List imageData, int width, int height) async {
    // Упрощенная детекция на основе анализа контуров и движения
    final keypoints = <BodyKeypoint>[];
    
    // Анализируем изображение по зонам для поиска тела
    final zones = _analyzeBodyZones(imageData, width, height);
    
    // Определяем примерные позиции ключевых точек
    if (zones['head'] != null) {
      keypoints.add(BodyKeypoint(
        type: KeypointType.nose,
        position: zones['head']!,
        confidence: 0.8,
      ));
    }
    
    if (zones['torso'] != null) {
      final torso = zones['torso']!;
      keypoints.addAll([
        BodyKeypoint(
          type: KeypointType.leftShoulder,
          position: Offset(torso.dx - 40, torso.dy - 20),
          confidence: 0.7,
        ),
        BodyKeypoint(
          type: KeypointType.rightShoulder,
          position: Offset(torso.dx + 40, torso.dy - 20),
          confidence: 0.7,
        ),
        BodyKeypoint(
          type: KeypointType.leftElbow,
          position: Offset(torso.dx - 60, torso.dy + 20),
          confidence: 0.6,
        ),
        BodyKeypoint(
          type: KeypointType.rightElbow,
          position: Offset(torso.dx + 60, torso.dy + 20),
          confidence: 0.6,
        ),
        BodyKeypoint(
          type: KeypointType.leftWrist,
          position: Offset(torso.dx - 80, torso.dy + 60),
          confidence: 0.5,
        ),
        BodyKeypoint(
          type: KeypointType.rightWrist,
          position: Offset(torso.dx + 80, torso.dy + 60),
          confidence: 0.5,
        ),
        BodyKeypoint(
          type: KeypointType.leftHip,
          position: Offset(torso.dx - 20, torso.dy + 80),
          confidence: 0.7,
        ),
        BodyKeypoint(
          type: KeypointType.rightHip,
          position: Offset(torso.dx + 20, torso.dy + 80),
          confidence: 0.7,
        ),
        BodyKeypoint(
          type: KeypointType.leftKnee,
          position: Offset(torso.dx - 25, torso.dy + 140),
          confidence: 0.6,
        ),
        BodyKeypoint(
          type: KeypointType.rightKnee,
          position: Offset(torso.dx + 25, torso.dy + 140),
          confidence: 0.6,
        ),
        BodyKeypoint(
          type: KeypointType.leftAnkle,
          position: Offset(torso.dx - 30, torso.dy + 200),
          confidence: 0.5,
        ),
        BodyKeypoint(
          type: KeypointType.rightAnkle,
          position: Offset(torso.dx + 30, torso.dy + 200),
          confidence: 0.5,
        ),
      ]);
    }
    
    return keypoints;
  }

  /// Анализ зон тела на изображении
  Map<String, Offset?> _analyzeBodyZones(Uint8List imageData, int width, int height) {
    final zones = <String, Offset?>{};
    
    // Упрощенный алгоритм поиска тела по яркости и контрастности
    // В реальном приложении здесь был бы более сложный алгоритм
    
    // Ищем голову (верхняя треть изображения)
    final headRegion = _findBrightestRegion(
      imageData, 
      width, 
      height, 
      0, 
      height ~/ 3,
    );
    if (headRegion != null) {
      zones['head'] = headRegion;
    }
    
    // Ищем торс (средняя треть изображения)
    final torsoRegion = _findLargestRegion(
      imageData, 
      width, 
      height, 
      height ~/ 3, 
      (height * 2) ~/ 3,
    );
    if (torsoRegion != null) {
      zones['torso'] = torsoRegion;
    }
    
    return zones;
  }

  /// Поиск самой яркой области (для головы)
  Offset? _findBrightestRegion(Uint8List imageData, int width, int height, int startY, int endY) {
    double maxBrightness = 0;
    Offset? brightestPoint;
    
    for (int y = startY; y < endY && y < height; y += 4) {
      for (int x = 0; x < width; x += 4) {
        final index = (y * width + x) * 3;
        if (index + 2 < imageData.length) {
          final brightness = (imageData[index] + imageData[index + 1] + imageData[index + 2]) / 3;
          if (brightness > maxBrightness) {
            maxBrightness = brightness;
            brightestPoint = Offset(x.toDouble(), y.toDouble());
          }
        }
      }
    }
    
    return brightestPoint;
  }

  /// Поиск самой большой области (для торса)
  Offset? _findLargestRegion(Uint8List imageData, int width, int height, int startY, int endY) {
    // Упрощенный поиск центра масс
    double totalX = 0;
    double totalY = 0;
    int count = 0;
    
    for (int y = startY; y < endY && y < height; y += 2) {
      for (int x = width ~/ 4; x < (width * 3) ~/ 4; x += 2) {
        final index = (y * width + x) * 3;
        if (index + 2 < imageData.length) {
          final brightness = (imageData[index] + imageData[index + 1] + imageData[index + 2]) / 3;
          if (brightness > 100) { // Порог для определения тела
            totalX += x;
            totalY += y;
            count++;
          }
        }
      }
    }
    
    if (count > 0) {
      return Offset(totalX / count, totalY / count);
    }
    
    return null;
  }







  /// Подсчет повторений (упрощенный алгоритм)
  int _calculateReps(List<BodyKeypoint> keypoints) {
    // Здесь должна быть логика подсчета повторений
    // В зависимости от типа упражнения
    // Пока возвращаем статическое значение
    return _frameCount ~/ 100; // Примерно каждые 20 секунд
  }



  /// Очистка ресурсов
  void dispose() {
    // Очистка ресурсов
  }
}

/// Результат анализа позы с расширенной информацией
class PoseAnalysisResult {
  final bool isPersonVisible;
  final String feedback;
  final int repCount;
  final double formScore;
  final List<BodyKeypoint> keypoints;
  final List<String> criticalErrors;
  final List<String> warnings;

  const PoseAnalysisResult({
    required this.isPersonVisible,
    required this.feedback,
    required this.repCount,
    required this.formScore,
    required this.keypoints,
    this.criticalErrors = const [],
    this.warnings = const [],
  });

  factory PoseAnalysisResult.empty() {
    return const PoseAnalysisResult(
      isPersonVisible: false,
      feedback: 'Анализ...',
      repCount: 0,
      formScore: 0.0,
      keypoints: [],
    );
  }
}

/// Ключевая точка тела
class BodyKeypoint {
  final KeypointType type;
  final Offset position;
  final double confidence;

  const BodyKeypoint({
    required this.type,
    required this.position,
    required this.confidence,
  });
}

/// Типы ключевых точек тела
enum KeypointType {
  nose,
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

extension KeypointTypeExtension on KeypointType {
  String get name {
    switch (this) {
      case KeypointType.nose:
        return 'Нос';
      case KeypointType.leftShoulder:
        return 'Левое плечо';
      case KeypointType.rightShoulder:
        return 'Правое плечо';
      case KeypointType.leftElbow:
        return 'Левый локоть';
      case KeypointType.rightElbow:
        return 'Правый локоть';
      case KeypointType.leftWrist:
        return 'Левое запястье';
      case KeypointType.rightWrist:
        return 'Правое запястье';
      case KeypointType.leftHip:
        return 'Левое бедро';
      case KeypointType.rightHip:
        return 'Правое бедро';
      case KeypointType.leftKnee:
        return 'Левое колено';
      case KeypointType.rightKnee:
        return 'Правое колено';
      case KeypointType.leftAnkle:
        return 'Левая лодыжка';
      case KeypointType.rightAnkle:
        return 'Правая лодыжка';
      default:
        return toString();
    }
  }
}