import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class SimpleCameraTestPage extends StatefulWidget {
  const SimpleCameraTestPage({super.key});

  @override
  State<SimpleCameraTestPage> createState() => _SimpleCameraTestPageState();
}

class _SimpleCameraTestPageState extends State<SimpleCameraTestPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String _status = 'Инициализация...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _status = 'Поиск камер...';
      });

      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _status = 'Камеры не найдены';
        });
        return;
      }

      setState(() {
        _status = 'Найдено камер: ${_cameras!.length}';
      });

      // Используем первую доступную камеру
      final camera = _cameras!.first;
      
      setState(() {
        _status = 'Инициализация камеры: ${camera.name}';
      });

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _status = 'Камера готова!';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Ошибка: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    try {
      setState(() {
        _status = 'Переключение камеры...';
        _isInitialized = false;
      });

      await _controller?.dispose();

      // Находим следующую камеру
      final currentIndex = _cameras!.indexOf(_controller!.description);
      final nextIndex = (currentIndex + 1) % _cameras!.length;
      final nextCamera = _cameras![nextIndex];

      _controller = CameraController(
        nextCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _status = 'Камера: ${nextCamera.name}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Ошибка переключения: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест камеры'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: Column(
        children: [
          // Превью камеры
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _isInitialized && _controller != null
                    ? CameraPreview(_controller!)
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          
          // Информация
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Статус
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Информация о камерах
                  if (_cameras != null)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Доступные камеры (${_cameras!.length}):',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _cameras!.length,
                                itemBuilder: (context, index) {
                                  final camera = _cameras![index];
                                  final isCurrent = _controller?.description == camera;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: isCurrent 
                                          ? Colors.blue.shade100 
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          camera.lensDirection == CameraLensDirection.front
                                              ? Icons.camera_front
                                              : Icons.camera_rear,
                                          size: 16,
                                          color: isCurrent 
                                              ? Colors.blue 
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${camera.name} (${camera.lensDirection.name})',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isCurrent 
                                                  ? Colors.blue.shade800 
                                                  : Colors.black87,
                                              fontWeight: isCurrent 
                                                  ? FontWeight.bold 
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (isCurrent)
                                          const Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
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