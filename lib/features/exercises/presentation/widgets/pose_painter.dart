import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Painter для отрисовки скелета на теле человека
/// Улучшенная версия на основе MediaPipe Pose Landmarker из Camerawork
class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final bool mirror;

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.rotation,
    this.mirror = false,
  });

  // Соединения скелета для ML Kit Pose Detection
  static const List<List<int>> _connections = [
    // Торс (используем правильные индексы ML Kit)
    [5, 6],   // Левое плечо - правое плечо
    [5, 11],  // Левое плечо - левое бедро  
    [6, 12],  // Правое плечо - правое бедро
    [11, 12], // Левое бедро - правое бедро
    
    // Левая рука
    [5, 7],   // Левое плечо - левый локоть
    [7, 9],   // Левый локоть - левое запястье
    
    // Правая рука  
    [6, 8],   // Правое плечо - правый локоть
    [8, 10],  // Правый локоть - правое запястье
    
    // Левая нога
    [11, 13], // Левое бедро - левое колено
    [13, 15], // Левое колено - левая лодыжка
    
    // Правая нога
    [12, 14], // Правое бедро - правое колено  
    [14, 16], // Правое колено - правая лодыжка
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Настройка кистей (как в Camerawork)
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white.withValues(alpha: 0.8); // Белые полупрозрачные линии

    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue; // Синие точки

    for (final pose in poses) {
      final landmarks = pose.landmarks;
      
      // Рисуем соединения (линии скелета) используя типы landmarks
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, linePaint, size);
      
      // Левая рука
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, linePaint, size);
      
      // Правая рука
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, linePaint, size);
      
      // Левая нога
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, linePaint, size);
      
      // Правая нога
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, linePaint, size);
      
      // Рисуем точки суставов поверх линий
      for (final landmark in landmarks.values) {
        if (landmark.likelihood > 0.5) {
          final point = _translatePoint(landmark.x, landmark.y, size);
          canvas.drawCircle(point, 8, pointPaint);
        }
      }
    }
  }

  void _drawConnection(Canvas canvas, Map<PoseLandmarkType, PoseLandmark> landmarks, 
                      PoseLandmarkType start, PoseLandmarkType end, Paint paint, Size size) {
    final startLandmark = landmarks[start];
    final endLandmark = landmarks[end];
    
    if (startLandmark != null && endLandmark != null && 
        startLandmark.likelihood > 0.5 && endLandmark.likelihood > 0.5) {
      final startPoint = _translatePoint(startLandmark.x, startLandmark.y, size);
      final endPoint = _translatePoint(endLandmark.x, endLandmark.y, size);
      
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  Offset _translatePoint(double x, double y, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) {
      return Offset.zero;
    }

    // ML Kit возвращает координаты в пикселях "upright" изображения, с учётом rotation,
    // но при отрисовке важно правильно выбрать ширину/высоту входного кадра.
    // Для rotation 90/270 ширина и высота меняются местами.
    final rotatedImageWidth = (rotation == InputImageRotation.rotation90deg ||
            rotation == InputImageRotation.rotation270deg)
        ? imageSize.height
        : imageSize.width;
    final rotatedImageHeight = (rotation == InputImageRotation.rotation90deg ||
            rotation == InputImageRotation.rotation270deg)
        ? imageSize.width
        : imageSize.height;

    final scaleX = size.width / rotatedImageWidth;
    final scaleY = size.height / rotatedImageHeight;

    double dx = x * scaleX;
    final double dy = y * scaleY;

    if (mirror) {
      dx = size.width - dx;
    }

    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses;
  }
}
