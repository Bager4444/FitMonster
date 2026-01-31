import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Оптимизированный рисовальщик поз с выделением ключевых точек
class OptimizedPosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final List<PoseLandmarkType> keyPoints;
  final double confidence;
  final double? exerciseQuality;
  
  OptimizedPosePainter({
    required this.pose,
    required this.imageSize,
    required this.keyPoints,
    required this.confidence,
    this.exerciseQuality,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Вычисляем масштаб для адаптации к размеру виджета
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    
    // Рисуем все соединения (скелет) тонкими линиями
    _drawAllConnections(canvas, size, scaleX, scaleY);
    
    // Рисуем все точки
    _drawAllLandmarks(canvas, size, scaleX, scaleY);
    
    // Выделяем ключевые точки
    _drawKeyLandmarks(canvas, size, scaleX, scaleY);
    
    // Рисуем индикатор качества
    _drawQualityIndicator(canvas, size);
    
    // Рисуем легенду
    _drawLegend(canvas, size);
  }

  /// Рисует все соединения скелета
  void _drawAllConnections(Canvas canvas, Size size, double scaleX, double scaleY) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Определяем все соединения скелета
    final connections = [
      // Лицо
      [PoseLandmarkType.leftEar, PoseLandmarkType.leftEyeOuter],
      [PoseLandmarkType.leftEyeOuter, PoseLandmarkType.leftEye],
      [PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeInner],
      [PoseLandmarkType.leftEyeInner, PoseLandmarkType.nose],
      [PoseLandmarkType.nose, PoseLandmarkType.rightEyeInner],
      [PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye],
      [PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeOuter],
      [PoseLandmarkType.rightEyeOuter, PoseLandmarkType.rightEar],
      [PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth],
      
      // Торс
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      
      // Левая рука
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb],
      
      // Правая рука
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb],
      
      // Левая нога
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel],
      [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex],
      
      // Правая нога
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel],
      [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex],
    ];

    for (final connection in connections) {
      final point1 = pose.landmarks[connection[0]];
      final point2 = pose.landmarks[connection[1]];
      
      if (point1 != null && point2 != null && 
          point1.likelihood > 0.3 && point2.likelihood > 0.3) {
        canvas.drawLine(
          Offset(point1.x * scaleX, point1.y * scaleY),
          Offset(point2.x * scaleX, point2.y * scaleY),
          paint,
        );
      }
    }
  }

  /// Рисует все точки позы
  void _drawAllLandmarks(Canvas canvas, Size size, double scaleX, double scaleY) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (final landmark in pose.landmarks.values) {
      if (landmark.likelihood > 0.3) {
        canvas.drawCircle(
          Offset(landmark.x * scaleX, landmark.y * scaleY),
          3.0,
          paint,
        );
      }
    }
  }

  /// Рисует ключевые точки с выделением
  void _drawKeyLandmarks(Canvas canvas, Size size, double scaleX, double scaleY) {
    // Цвет ключевых точек зависит от качества выполнения
    Color keyPointColor = Colors.green;
    if (exerciseQuality != null) {
      if (exerciseQuality! > 0.8) {
        keyPointColor = Colors.green;
      } else if (exerciseQuality! > 0.6) {
        keyPointColor = Colors.orange;
      } else {
        keyPointColor = Colors.red;
      }
    }

    final keyPaint = Paint()
      ..color = keyPointColor
      ..style = PaintingStyle.fill;
      
    final keyBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final keyPointType in keyPoints) {
      final landmark = pose.landmarks[keyPointType];
      if (landmark != null && landmark.likelihood > 0.5) {
        final center = Offset(landmark.x * scaleX, landmark.y * scaleY);
        
        // Рисуем большую ключевую точку
        canvas.drawCircle(center, 8.0, keyBorderPaint);
        canvas.drawCircle(center, 6.0, keyPaint);
        
        // Добавляем пульсирующий эффект для высокого качества
        if (exerciseQuality != null && exerciseQuality! > 0.8) {
          final pulsePaint = Paint()
            ..color = keyPointColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(center, 12.0, pulsePaint);
        }
      }
    }
  }

  /// Рисует индикатор качества выполнения
  void _drawQualityIndicator(Canvas canvas, Size size) {
    if (exerciseQuality == null) return;
    
    const indicatorWidth = 100.0;
    const indicatorHeight = 8.0;
    const margin = 16.0;
    
    final rect = Rect.fromLTWH(
      size.width - indicatorWidth - margin,
      margin,
      indicatorWidth,
      indicatorHeight,
    );
    
    // Фон индикатора
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      backgroundPaint,
    );
    
    // Заполнение индикатора
    Color qualityColor = Colors.red;
    if (exerciseQuality! > 0.8) {
      qualityColor = Colors.green;
    } else if (exerciseQuality! > 0.6) {
      qualityColor = Colors.orange;
    }
    
    final fillRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width * exerciseQuality!,
      rect.height,
    );
    
    final fillPaint = Paint()
      ..color = qualityColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(4)),
      fillPaint,
    );
    
    // Текст качества
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Качество: ${(exerciseQuality! * 100).round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width - indicatorWidth - margin,
        margin + indicatorHeight + 4,
      ),
    );
  }

  /// Рисует легенду
  void _drawLegend(Canvas canvas, Size size) {
    const margin = 16.0;
    const legendHeight = 60.0;
    
    // Фон легенды
    final legendRect = Rect.fromLTWH(
      margin,
      size.height - legendHeight - margin,
      200.0,
      legendHeight,
    );
    
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(legendRect, const Radius.circular(8)),
      backgroundPaint,
    );
    
    // Элементы легенды
    final legendItems = [
      {'color': Colors.white.withValues(alpha: 0.6), 'text': 'Все точки'},
      {'color': Colors.green, 'text': 'Ключевые точки'},
      {'color': Colors.white.withValues(alpha: 0.3), 'text': 'Скелет'},
    ];
    
    double yOffset = legendRect.top + 8;
    
    for (final item in legendItems) {
      // Цветной индикатор
      final indicatorPaint = Paint()
        ..color = item['color'] as Color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(legendRect.left + 12, yOffset + 6),
        4.0,
        indicatorPaint,
      );
      
      // Текст
      final textPainter = TextPainter(
        text: TextSpan(
          text: item['text'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(legendRect.left + 24, yOffset),
      );
      
      yOffset += 16;
    }
    
    // Информация о ключевых точках
    final keyPointsText = TextPainter(
      text: TextSpan(
        text: 'Анализ: ${keyPoints.length}/10 точек',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    keyPointsText.layout();
    keyPointsText.paint(
      canvas,
      Offset(legendRect.left + 8, yOffset),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}