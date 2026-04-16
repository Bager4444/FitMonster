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

  @override
  void paint(Canvas canvas, Size size) {
    // Контуры: сначала тёмная «обводка», поверх яркая линия (лучше видно на тёмном UI).
    final lineOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xD9000000);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.95);

    final jointOutline = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xE6000000);

    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF60A5FA);

    for (final pose in poses) {
      final landmarks = pose.landmarks;
      
      // Рисуем соединения (линии скелета) используя типы landmarks
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, lineOutline, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, lineOutline, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, lineOutline, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, lineOutline, linePaint, size);
      
      // Левая рука
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, lineOutline, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, lineOutline, linePaint, size);
      
      // Правая рука
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, lineOutline, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, lineOutline, linePaint, size);
      
      // Левая нога
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, lineOutline, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, lineOutline, linePaint, size);
      
      // Правая нога
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, lineOutline, linePaint, size);
      _drawConnection(canvas, landmarks, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, lineOutline, linePaint, size);
      
      // Суставы: кольцо-контур + заливка
      for (final landmark in landmarks.values) {
        if (landmark.likelihood > 0.5) {
          final point = _translatePoint(landmark.x, landmark.y, size);
          canvas.drawCircle(point, 12, jointOutline);
          canvas.drawCircle(point, 9, pointPaint);
        }
      }
    }
  }

  void _drawConnection(
    Canvas canvas,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    PoseLandmarkType start,
    PoseLandmarkType end,
    Paint outlinePaint,
    Paint foregroundPaint,
    Size size,
  ) {
    final startLandmark = landmarks[start];
    final endLandmark = landmarks[end];
    
    if (startLandmark != null && endLandmark != null && 
        startLandmark.likelihood > 0.5 && endLandmark.likelihood > 0.5) {
      final startPoint = _translatePoint(startLandmark.x, startLandmark.y, size);
      final endPoint = _translatePoint(endLandmark.x, endLandmark.y, size);
      
      canvas.drawLine(startPoint, endPoint, outlinePaint);
      canvas.drawLine(startPoint, endPoint, foregroundPaint);
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
