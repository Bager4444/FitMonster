import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/pose_painter.dart';

/// Тестовая страница для проверки отрисовки скелета
class PoseTestPage extends StatefulWidget {
  const PoseTestPage({super.key});

  @override
  State<PoseTestPage> createState() => _PoseTestPageState();
}

class _PoseTestPageState extends State<PoseTestPage> {
  List<Pose> _testPoses = [];

  @override
  void initState() {
    super.initState();
    _createTestPose();
  }

  void _createTestPose() {
    // Создаем тестовую позу с фиктивными данными
    final testLandmarks = <PoseLandmarkType, PoseLandmark>{
      PoseLandmarkType.nose: PoseLandmark(
        type: PoseLandmarkType.nose,
        x: 200,
        y: 100,
        z: 0,
        likelihood: 0.9,
      ),
      PoseLandmarkType.leftShoulder: PoseLandmark(
        type: PoseLandmarkType.leftShoulder,
        x: 150,
        y: 200,
        z: 0,
        likelihood: 0.8,
      ),
      PoseLandmarkType.rightShoulder: PoseLandmark(
        type: PoseLandmarkType.rightShoulder,
        x: 250,
        y: 200,
        z: 0,
        likelihood: 0.8,
      ),
      PoseLandmarkType.leftElbow: PoseLandmark(
        type: PoseLandmarkType.leftElbow,
        x: 120,
        y: 280,
        z: 0,
        likelihood: 0.7,
      ),
      PoseLandmarkType.rightElbow: PoseLandmark(
        type: PoseLandmarkType.rightElbow,
        x: 280,
        y: 280,
        z: 0,
        likelihood: 0.7,
      ),
      PoseLandmarkType.leftWrist: PoseLandmark(
        type: PoseLandmarkType.leftWrist,
        x: 100,
        y: 350,
        z: 0,
        likelihood: 0.6,
      ),
      PoseLandmarkType.rightWrist: PoseLandmark(
        type: PoseLandmarkType.rightWrist,
        x: 300,
        y: 350,
        z: 0,
        likelihood: 0.6,
      ),
      PoseLandmarkType.leftHip: PoseLandmark(
        type: PoseLandmarkType.leftHip,
        x: 170,
        y: 400,
        z: 0,
        likelihood: 0.8,
      ),
      PoseLandmarkType.rightHip: PoseLandmark(
        type: PoseLandmarkType.rightHip,
        x: 230,
        y: 400,
        z: 0,
        likelihood: 0.8,
      ),
      PoseLandmarkType.leftKnee: PoseLandmark(
        type: PoseLandmarkType.leftKnee,
        x: 160,
        y: 500,
        z: 0,
        likelihood: 0.7,
      ),
      PoseLandmarkType.rightKnee: PoseLandmark(
        type: PoseLandmarkType.rightKnee,
        x: 240,
        y: 500,
        z: 0,
        likelihood: 0.7,
      ),
      PoseLandmarkType.leftAnkle: PoseLandmark(
        type: PoseLandmarkType.leftAnkle,
        x: 150,
        y: 600,
        z: 0,
        likelihood: 0.6,
      ),
      PoseLandmarkType.rightAnkle: PoseLandmark(
        type: PoseLandmarkType.rightAnkle,
        x: 250,
        y: 600,
        z: 0,
        likelihood: 0.6,
      ),
    };

    // Создаем тестовую позу
    final testPose = Pose(landmarks: testLandmarks);
    
    setState(() {
      _testPoses = [testPose];
    });
    
    print('🧪 Created test pose with ${testLandmarks.length} landmarks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест отрисовки скелета'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Информация
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Text(
              'Тестовая отрисовка скелета\nПоз: ${_testPoses.length}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Область для отрисовки скелета
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: CustomPaint(
                painter: PosePainter(
                  poses: _testPoses,
                  imageSize: const Size(400, 700), // Размер "изображения"
                  rotation: InputImageRotation.rotation0deg,
                ),
                child: Container(), // Пустой контейнер для размера
              ),
            ),
          ),
          
          // Кнопки управления
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _createTestPose,
                  child: const Text('Обновить позу'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _testPoses = [];
                    });
                  },
                  child: const Text('Очистить'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}