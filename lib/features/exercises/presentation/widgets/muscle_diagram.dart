import 'package:flutter/material.dart';

/// Виджет для отображения диаграммы мышц
class MuscleDiagram extends StatefulWidget {
  final List<String> activeMuscles;

  const MuscleDiagram({
    super.key,
    required this.activeMuscles,
  });

  @override
  State<MuscleDiagram> createState() => _MuscleDiagramState();
}

class _MuscleDiagramState extends State<MuscleDiagram> {
  String? _selectedMuscle;
  bool _isMale = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Переключатель пола
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('👨 Мужчина'),
                selected: _isMale,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _isMale = true;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('👩 Женщина'),
                selected: !_isMale,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _isMale = false;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Диаграмма тела
          Expanded(
            child: Row(
              children: [
                // Вид спереди
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Спереди',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CustomPaint(
                          painter: BodyPainter(
                            activeMuscles: widget.activeMuscles,
                            selectedMuscle: _selectedMuscle,
                            isFront: true,
                            isMale: _isMale,
                          ),
                          child: GestureDetector(
                            onTapDown: (details) {
                              _handleTap(details.localPosition, true);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Вид сзади
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Сзади',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CustomPaint(
                          painter: BodyPainter(
                            activeMuscles: widget.activeMuscles,
                            selectedMuscle: _selectedMuscle,
                            isFront: false,
                            isMale: _isMale,
                          ),
                          child: GestureDetector(
                            onTapDown: (details) {
                              _handleTap(details.localPosition, false);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Легенда
          if (_selectedMuscle != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Выбрано: $_selectedMuscle',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedMuscle = null;
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleTap(Offset position, bool isFront) {
    final muscle = _getMuscleAtPosition(position, isFront);
    if (muscle != null && widget.activeMuscles.contains(muscle)) {
      setState(() {
        _selectedMuscle = muscle;
      });
    }
  }

  String? _getMuscleAtPosition(Offset position, bool isFront) {
    return null;
  }
}

/// Painter для рисования тела с мышцами
class BodyPainter extends CustomPainter {
  final List<String> activeMuscles;
  final String? selectedMuscle;
  final bool isFront;
  final bool isMale;

  BodyPainter({
    required this.activeMuscles,
    required this.selectedMuscle,
    required this.isFront,
    required this.isMale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final headRadius = size.width * 0.08;
    final shoulderWidth = isMale ? size.width * 0.35 : size.width * 0.32;
    final bodyHeight = size.height * 0.28;
    final legHeight = size.height * 0.32;

    // Белый цвет для тела
    final bodyPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Голова
    final headY = headRadius + 8;
    canvas.drawCircle(Offset(centerX, headY), headRadius, bodyPaint);
    canvas.drawCircle(Offset(centerX, headY), headRadius, outlinePaint);

    // Шея
    final neckTop = headRadius * 2 + 8;
    final neckHeight = size.height * 0.06;
    final neckWidth = headRadius * 0.5;
    
    final neckPath = Path()
      ..moveTo(centerX - neckWidth, neckTop)
      ..lineTo(centerX + neckWidth, neckTop)
      ..lineTo(centerX + neckWidth * 1.2, neckTop + neckHeight)
      ..lineTo(centerX - neckWidth * 1.2, neckTop + neckHeight)
      ..close();
    
    canvas.drawPath(neckPath, bodyPaint);
    canvas.drawPath(neckPath, outlinePaint);

    // Торс
    final torsoTop = neckTop + neckHeight;
    final waistWidth = isMale ? shoulderWidth * 0.7 : shoulderWidth * 0.65;
    
    final torsoPath = Path()
      ..moveTo(centerX - shoulderWidth / 2, torsoTop)
      ..lineTo(centerX + shoulderWidth / 2, torsoTop)
      ..quadraticBezierTo(
        centerX + shoulderWidth / 2.2, torsoTop + bodyHeight * 0.3,
        centerX + waistWidth / 2, torsoTop + bodyHeight * 0.6,
      )
      ..lineTo(centerX + waistWidth / 2.2, torsoTop + bodyHeight)
      ..lineTo(centerX - waistWidth / 2.2, torsoTop + bodyHeight)
      ..lineTo(centerX - waistWidth / 2, torsoTop + bodyHeight * 0.6)
      ..quadraticBezierTo(
        centerX - shoulderWidth / 2.2, torsoTop + bodyHeight * 0.3,
        centerX - shoulderWidth / 2, torsoTop,
      )
      ..close();

    canvas.drawPath(torsoPath, bodyPaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // Рисуем мышцы
    if (isFront) {
      _drawFrontMuscles(canvas, size, centerX, torsoTop, shoulderWidth, bodyHeight, waistWidth);
    } else {
      _drawBackMuscles(canvas, size, centerX, torsoTop, shoulderWidth, bodyHeight, waistWidth);
    }

    // Руки (тонкие)
    _drawArms(canvas, size, centerX, torsoTop, shoulderWidth, bodyHeight, bodyPaint, outlinePaint);

    // Ноги
    _drawLegs(canvas, size, centerX, torsoTop + bodyHeight, waistWidth, legHeight, bodyPaint, outlinePaint);
  }

  void _drawFrontMuscles(Canvas canvas, Size size, double centerX, double torsoTop, double shoulderWidth, double bodyHeight, double waistWidth) {
    // Грудные мышцы
    if (_shouldHighlight('Грудь') || _shouldHighlight('Грудные')) {
      final chestColor = _getColor('Грудь');
      
      final chestPaint = Paint()
        ..color = chestColor
        ..style = PaintingStyle.fill;

      // Левая грудная
      final leftChestPath = Path()
        ..moveTo(centerX - shoulderWidth * 0.05, torsoTop + bodyHeight * 0.08)
        ..lineTo(centerX - shoulderWidth * 0.38, torsoTop + bodyHeight * 0.12)
        ..quadraticBezierTo(
          centerX - shoulderWidth * 0.35, torsoTop + bodyHeight * 0.28,
          centerX - shoulderWidth * 0.12, torsoTop + bodyHeight * 0.42,
        )
        ..lineTo(centerX - shoulderWidth * 0.05, torsoTop + bodyHeight * 0.35)
        ..close();
      
      canvas.drawPath(leftChestPath, chestPaint);

      // Правая грудная
      final rightChestPath = Path()
        ..moveTo(centerX + shoulderWidth * 0.05, torsoTop + bodyHeight * 0.08)
        ..lineTo(centerX + shoulderWidth * 0.38, torsoTop + bodyHeight * 0.12)
        ..quadraticBezierTo(
          centerX + shoulderWidth * 0.35, torsoTop + bodyHeight * 0.28,
          centerX + shoulderWidth * 0.12, torsoTop + bodyHeight * 0.42,
        )
        ..lineTo(centerX + shoulderWidth * 0.05, torsoTop + bodyHeight * 0.35)
        ..close();
      
      canvas.drawPath(rightChestPath, chestPaint);
    }

    // Пресс (8 кубиков)
    if (_shouldHighlight('Пресс') || _shouldHighlight('Живот')) {
      final absColor = _getColor('Пресс');
      
      final absWidth = waistWidth * 0.55;
      final absHeight = bodyHeight * 0.5;
      final absTop = torsoTop + bodyHeight * 0.38;

      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 2; col++) {
          final cubeWidth = absWidth * 0.38;
          final cubeHeight = absHeight * 0.22;
          
          final x = centerX - absWidth / 2 + (col * absWidth / 2) + absWidth * 0.06;
          final y = absTop + (row * absHeight / 4) + absHeight * 0.02;

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, cubeWidth, cubeHeight),
              const Radius.circular(6),
            ),
            Paint()..color = absColor..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  void _drawBackMuscles(Canvas canvas, Size size, double centerX, double torsoTop, double shoulderWidth, double bodyHeight, double waistWidth) {
    // Спина
    if (_shouldHighlight('Спина') || _shouldHighlight('Широчайшие')) {
      final backColor = _getColor('Спина');
      
      final backPath = Path()
        ..moveTo(centerX - shoulderWidth * 0.4, torsoTop + bodyHeight * 0.1)
        ..lineTo(centerX + shoulderWidth * 0.4, torsoTop + bodyHeight * 0.1)
        ..lineTo(centerX + waistWidth * 0.35, torsoTop + bodyHeight * 0.75)
        ..lineTo(centerX - waistWidth * 0.35, torsoTop + bodyHeight * 0.75)
        ..close();

      canvas.drawPath(backPath, Paint()..color = backColor..style = PaintingStyle.fill);
    }

    // Ягодицы
    if (_shouldHighlight('Ягодицы')) {
      final glutesColor = _getColor('Ягодицы');
      
      canvas.drawOval(
        Rect.fromLTWH(
          centerX - waistWidth * 0.35,
          torsoTop + bodyHeight * 0.78,
          waistWidth * 0.32,
          bodyHeight * 0.28,
        ),
        Paint()..color = glutesColor..style = PaintingStyle.fill,
      );

      canvas.drawOval(
        Rect.fromLTWH(
          centerX + waistWidth * 0.03,
          torsoTop + bodyHeight * 0.78,
          waistWidth * 0.32,
          bodyHeight * 0.28,
        ),
        Paint()..color = glutesColor..style = PaintingStyle.fill,
      );
    }
  }

  void _drawArms(Canvas canvas, Size size, double centerX, double torsoTop, double shoulderWidth, double bodyHeight, Paint bodyPaint, Paint outlinePaint) {
    final upperArmWidth = size.width * 0.05; // Тонкие руки
    final forearmWidth = size.width * 0.04; // Тонкие предплечья
    final armLength = bodyHeight * 1.4; // Длинные руки до колен
    final elbowY = torsoTop + armLength * 0.45;

    final isArmHighlighted = _shouldHighlight('Бицепсы') || _shouldHighlight('Трицепсы') || _shouldHighlight('Руки');
    final armColor = isArmHighlighted ? _getColor('Руки') : bodyPaint.color;
    
    final armPaint = Paint()
      ..color = armColor
      ..style = PaintingStyle.fill;

    // Левая рука (плечо)
    final leftUpperArmPath = Path()
      ..moveTo(centerX - shoulderWidth / 2 - upperArmWidth * 0.2, torsoTop)
      ..lineTo(centerX - shoulderWidth / 2 - upperArmWidth, torsoTop)
      ..quadraticBezierTo(
        centerX - shoulderWidth / 2 - upperArmWidth * 1.1, torsoTop + armLength * 0.25,
        centerX - shoulderWidth / 2 - upperArmWidth * 0.9, elbowY,
      )
      ..lineTo(centerX - shoulderWidth / 2 - upperArmWidth * 0.3, elbowY)
      ..quadraticBezierTo(
        centerX - shoulderWidth / 2 - upperArmWidth * 0.15, torsoTop + armLength * 0.25,
        centerX - shoulderWidth / 2 - upperArmWidth * 0.2, torsoTop,
      )
      ..close();
    
    canvas.drawPath(leftUpperArmPath, armPaint);
    canvas.drawPath(leftUpperArmPath, outlinePaint);

    // Левое предплечье
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - shoulderWidth / 2 - forearmWidth - upperArmWidth * 0.15,
          elbowY,
          forearmWidth,
          armLength * 0.55,
        ),
        const Radius.circular(6),
      ),
      armPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - shoulderWidth / 2 - forearmWidth - upperArmWidth * 0.15,
          elbowY,
          forearmWidth,
          armLength * 0.55,
        ),
        const Radius.circular(6),
      ),
      outlinePaint,
    );

    // Правая рука (плечо)
    final rightUpperArmPath = Path()
      ..moveTo(centerX + shoulderWidth / 2 + upperArmWidth * 0.2, torsoTop)
      ..lineTo(centerX + shoulderWidth / 2 + upperArmWidth, torsoTop)
      ..quadraticBezierTo(
        centerX + shoulderWidth / 2 + upperArmWidth * 1.1, torsoTop + armLength * 0.25,
        centerX + shoulderWidth / 2 + upperArmWidth * 0.9, elbowY,
      )
      ..lineTo(centerX + shoulderWidth / 2 + upperArmWidth * 0.3, elbowY)
      ..quadraticBezierTo(
        centerX + shoulderWidth / 2 + upperArmWidth * 0.15, torsoTop + armLength * 0.25,
        centerX + shoulderWidth / 2 + upperArmWidth * 0.2, torsoTop,
      )
      ..close();
    
    canvas.drawPath(rightUpperArmPath, armPaint);
    canvas.drawPath(rightUpperArmPath, outlinePaint);

    // Правое предплечье
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + shoulderWidth / 2 + upperArmWidth * 0.15,
          elbowY,
          forearmWidth,
          armLength * 0.55,
        ),
        const Radius.circular(6),
      ),
      armPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + shoulderWidth / 2 + upperArmWidth * 0.15,
          elbowY,
          forearmWidth,
          armLength * 0.55,
        ),
        const Radius.circular(6),
      ),
      outlinePaint,
    );
  }

  void _drawLegs(Canvas canvas, Size size, double centerX, double legsTop, double waistWidth, double legHeight, Paint bodyPaint, Paint outlinePaint) {
    final thighWidth = waistWidth * 0.35;
    final calfWidth = waistWidth * 0.28;
    final kneeY = legsTop + legHeight * 0.5;

    final legPaint = _shouldHighlight('Квадрицепсы') || _shouldHighlight('Бедра') || _shouldHighlight('Ноги')
        ? (Paint()
          ..color = _getColor('Ноги')
          ..style = PaintingStyle.fill)
        : bodyPaint;

    // Левое бедро
    final leftThighPath = Path()
      ..moveTo(centerX - waistWidth * 0.35, legsTop)
      ..lineTo(centerX - waistWidth * 0.05, legsTop)
      ..lineTo(centerX - waistWidth * 0.1, kneeY)
      ..lineTo(centerX - waistWidth * 0.32, kneeY)
      ..close();
    
    canvas.drawPath(leftThighPath, legPaint);
    canvas.drawPath(leftThighPath, outlinePaint);

    // Левая голень
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - waistWidth * 0.3,
          kneeY,
          calfWidth,
          legHeight * 0.5,
        ),
        const Radius.circular(6),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - waistWidth * 0.3,
          kneeY,
          calfWidth,
          legHeight * 0.5,
        ),
        const Radius.circular(6),
      ),
      outlinePaint,
    );

    // Правое бедро
    final rightThighPath = Path()
      ..moveTo(centerX + waistWidth * 0.35, legsTop)
      ..lineTo(centerX + waistWidth * 0.05, legsTop)
      ..lineTo(centerX + waistWidth * 0.1, kneeY)
      ..lineTo(centerX + waistWidth * 0.32, kneeY)
      ..close();
    
    canvas.drawPath(rightThighPath, legPaint);
    canvas.drawPath(rightThighPath, outlinePaint);

    // Правая голень
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + waistWidth * 0.02,
          kneeY,
          calfWidth,
          legHeight * 0.5,
        ),
        const Radius.circular(6),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + waistWidth * 0.02,
          kneeY,
          calfWidth,
          legHeight * 0.5,
        ),
        const Radius.circular(6),
      ),
      outlinePaint,
    );
  }

  bool _shouldHighlight(String muscle) {
    if (selectedMuscle != null) {
      return selectedMuscle == muscle;
    }
    return activeMuscles.any((m) => m.contains(muscle) || muscle.contains(m));
  }

  Color _getColor(String muscle) {
    if (selectedMuscle == muscle || (selectedMuscle != null && muscle.contains(selectedMuscle!))) {
      return Colors.red.withOpacity(0.8);
    }
    return Colors.green.withOpacity(0.6);
  }

  @override
  bool shouldRepaint(covariant BodyPainter oldDelegate) {
    return oldDelegate.activeMuscles != activeMuscles ||
        oldDelegate.selectedMuscle != selectedMuscle;
  }
}
