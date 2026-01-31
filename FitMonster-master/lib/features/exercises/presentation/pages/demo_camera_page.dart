import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Демо-страница для тестирования функций камеры без реальной камеры
class DemoCameraPage extends StatefulWidget {
  final String exerciseName;
  
  const DemoCameraPage({
    super.key,
    required this.exerciseName,
  });

  @override
  State<DemoCameraPage> createState() => _DemoCameraPageState();
}

class _DemoCameraPageState extends State<DemoCameraPage> {
  bool _isRecording = false;
  int _repCount = 0;
  double _formScore = 0.0;
  String _feedback = 'Готов к началу';
  Timer? _demoTimer;
  final Random _random = Random();

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }

  void _startDemo() {
    setState(() {
      _isRecording = true;
      _repCount = 0;
      _formScore = 0.0;
      _feedback = 'Анализирую движения...';
    });

    // Симулируем анализ движений
    _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      
      setState(() {
        _repCount++;
        _formScore = 70 + _random.nextDouble() * 30; // 70-100%
        
        // Случайная обратная связь
        final feedbacks = [
          'Отличная техника!',
          'Держите спину прямо',
          'Контролируйте движение',
          'Хорошая амплитуда',
          'Следите за дыханием',
        ];
        _feedback = feedbacks[_random.nextInt(feedbacks.length)];
      });

      // Останавливаем после 10 повторений
      if (_repCount >= 10) {
        _stopDemo();
      }
    });
  }

  void _stopDemo() {
    _demoTimer?.cancel();
    setState(() {
      _isRecording = false;
      _feedback = 'Тренировка завершена!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DEMO: ${widget.exerciseName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Симуляция камеры
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
              child: Stack(
                children: [
                  // Фон камеры
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isRecording ? Icons.videocam : Icons.videocam_off,
                          size: 80,
                          color: _isRecording ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isRecording ? 'ДЕМО РЕЖИМ' : 'Камера не активна',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isRecording) ...[
                          const SizedBox(height: 20),
                          // Симуляция скелета человека
                          Container(
                            width: 100,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '🏃‍♂️',
                                style: TextStyle(fontSize: 60),
                              ),
                            ),
                          ),
                        ],
                      ],
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
                ],
              ),
            ),
          ),
          
          // Статистика
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Счетчики
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Повторения', '$_repCount', Icons.repeat),
                      _buildStatCard('Техника', '${_formScore.toInt()}%', Icons.star),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Обратная связь
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.feedback, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          _feedback,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Кнопки управления
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRecording ? null : _startDemo,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Начать ДЕМО'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isRecording ? _stopDemo : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Остановить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}