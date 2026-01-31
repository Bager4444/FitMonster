import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Простая тестовая страница для проверки детекции позы
class SimplePoseTestPage extends StatefulWidget {
  const SimplePoseTestPage({super.key});

  @override
  State<SimplePoseTestPage> createState() => _SimplePoseTestPageState();
}

class _SimplePoseTestPageState extends State<SimplePoseTestPage> {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base, // Используем базовую модель
    ),
  );
  
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _status = 'Инициализация...';
  int _poseCount = 0;
  
  @override
  void initState() {
    super.initState();
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
        setState(() {
          _status = 'Камера не найдена';
        });
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
        _status = 'Камера готова. Нажмите "Старт" для начала детекции';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка инициализации камеры: $e';
      });
    }
  }

  void _startDetection() {
    if (!_isCameraInitialized || _cameraController == null) return;
    
    setState(() {
      _status = 'Детекция запущена...';
    });
    
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _detectPose(image);
      }
    });
  }

  void _stopDetection() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    setState(() {
      _status = 'Детекция остановлена';
      _isDetecting = false;
    });
  }

  Future<void> _detectPose(CameraImage image) async {
    try {
      // Простая конвертация без сложной логики
      final inputImage = _simpleConvertImage(image);
      
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);
        
        if (mounted) {
          setState(() {
            _poseCount++;
            if (poses.isNotEmpty) {
              final pose = poses.first;
              final landmarkCount = pose.landmarks.length;
              _status = 'Поза найдена! Точек: $landmarkCount (кадр $_poseCount)';
            } else {
              _status = 'Поза не найдена (кадр $_poseCount)';
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _status = 'Ошибка конвертации изображения (кадр $_poseCount)';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Ошибка детекции: $e';
        });
      }
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _simpleConvertImage(CameraImage image) {
    try {
      // Используем только первый plane для простоты
      final bytes = image.planes.first.bytes;
      
      final inputImageMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg, // Без поворота
        format: InputImageFormat.yuv420, // Стандартный формат
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );
    } catch (e) {
      debugPrint('Ошибка простой конвертации: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест детекции позы'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Камера
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _isCameraInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),
          
          // Статус
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _status,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _isCameraInitialized ? _startDetection : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Старт'),
                      ),
                      ElevatedButton(
                        onPressed: _stopDetection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Стоп'),
                      ),
                    ],
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