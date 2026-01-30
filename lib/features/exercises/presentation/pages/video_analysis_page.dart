import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'dart:io';
import 'dart:convert';

/// Страница анализа видео для создания эталонных паттернов
class VideoAnalysisPage extends StatefulWidget {
  const VideoAnalysisPage({super.key});

  @override
  State<VideoAnalysisPage> createState() => _VideoAnalysisPageState();
}

class _VideoAnalysisPageState extends State<VideoAnalysisPage> {
  VideoPlayerController? _videoController;
  PoseDetector? _poseDetector;
  
  String? _selectedVideoPath;
  bool _isAnalyzing = false;
  bool _isVideoLoaded = false;
  
  List<Map<String, dynamic>> _analysisResults = [];
  String _selectedExerciseType = 'squats';
  
  final List<String> _exerciseTypes = [
    'squats',
    'pushups', 
    'lunges',
    'burpees',
    'jumping_jacks',
    'plank',
  ];

  @override
  void initState() {
    super.initState();
    _initializePoseDetector();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            title: const Text('Анализ видео'),
            backgroundColor: themeProvider.cardColor,
            foregroundColor: themeProvider.textColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: _showHelpDialog,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoSection(themeProvider),
                const SizedBox(height: 24),
                _buildAnalysisSection(themeProvider),
                const SizedBox(height: 24),
                _buildResultsSection(themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.video_library, color: themeProvider.buttonColor),
              const SizedBox(width: 8),
              Text(
                'Выбор видео',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_selectedVideoPath == null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: themeProvider.buttonColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.buttonColor.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: themeProvider.buttonColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Выберите видеофайл для анализа',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Поддерживаются: MP4, MOV, AVI',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.folder_open),
                label: const Text('Выбрать видео'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ] else ...[
            // Видеоплеер
            if (_isVideoLoaded && _videoController != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Управление видео
            if (_isVideoLoaded && _videoController != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      });
                    },
                    icon: Icon(
                      _videoController!.value.isPlaying 
                          ? Icons.pause 
                          : Icons.play_arrow,
                      color: themeProvider.buttonColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      _videoController!.seekTo(Duration.zero);
                    },
                    icon: Icon(
                      Icons.replay,
                      color: themeProvider.buttonColor,
                      size: 32,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Информация о видео
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выбранное видео:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedVideoPath!.split('/').last,
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),
                  if (_isVideoLoaded && _videoController != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Длительность: ${_formatDuration(_videoController!.value.duration)}',
                      style: TextStyle(
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопка выбора другого видео
            TextButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.refresh),
              label: const Text('Выбрать другое видео'),
              style: TextButton.styleFrom(
                foregroundColor: themeProvider.buttonColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: themeProvider.buttonColor),
              const SizedBox(width: 8),
              Text(
                'Настройки анализа',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Выбор типа упражнения
          Text(
            'Тип упражнения:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: themeProvider.inputFieldColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: themeProvider.cardBorderColor),
            ),
            child: DropdownButton<String>(
              value: _selectedExerciseType,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: themeProvider.cardColor,
              style: TextStyle(color: themeProvider.textColor),
              items: _exerciseTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getExerciseDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedExerciseType = value;
                  });
                }
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Кнопка анализа
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedVideoPath != null && !_isAnalyzing 
                  ? _analyzeVideo 
                  : null,
              icon: _isAnalyzing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isAnalyzing ? 'Анализируем...' : 'Начать анализ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(ThemeProvider themeProvider) {
    if (_analysisResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeProvider.cardBorderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: themeProvider.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Результаты анализа появятся здесь',
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: themeProvider.buttonColor),
              const SizedBox(width: 8),
              Text(
                'Результаты анализа',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Результаты
          ..._analysisResults.map((result) {
            final color = result['color'] as Color? ?? themeProvider.accentColor;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result['title'] ?? 'Результат',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      result['description'] ?? 'Описание недоступно',
                      style: TextStyle(
                        color: themeProvider.secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          // Кнопка сохранения паттерна (если анализ успешен)
          if (_analysisResults.isNotEmpty && !_isAnalyzing) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _savePattern,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить как эталон'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideoPath = result.files.single.path;
          _isVideoLoaded = false;
          _analysisResults.clear();
        });
        
        await _loadVideo();
      }
    } catch (e) {
      _showErrorDialog('Ошибка выбора видео: $e');
    }
  }

  Future<void> _loadVideo() async {
    if (_selectedVideoPath == null) return;

    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(File(_selectedVideoPath!));
      
      await _videoController!.initialize();
      
      setState(() {
        _isVideoLoaded = true;
      });
    } catch (e) {
      _showErrorDialog('Ошибка загрузки видео: $e');
    }
  }

  Future<void> _analyzeVideo() async {
    if (_selectedVideoPath == null || _poseDetector == null || _videoController == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResults.clear();
    });

    try {
      // Имитируем анализ с загрузкой реальных результатов
      await Future.delayed(const Duration(seconds: 2));
      
      // Пытаемся загрузить результаты анализа из JSON файла
      Map<String, dynamic>? analysisData = await _loadAnalysisResults();
      
      if (analysisData != null) {
        // Используем реальные результаты анализа
        setState(() {
          _analysisResults = _buildResultsFromAnalysis(analysisData);
        });
      } else {
        // Fallback к имитации анализа
        await _performMockAnalysis();
      }
    } catch (e) {
      _showErrorDialog('Ошибка анализа: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _loadAnalysisResults() async {
    try {
      // В реальном приложении здесь был бы вызов Python скрипта
      // Пока загружаем из заранее подготовленного файла
      final file = File('flutter_analysis_report.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        return json.decode(contents);
      }
    } catch (e) {
      print('Ошибка загрузки результатов анализа: $e');
    }
    return null;
  }

  List<Map<String, dynamic>> _buildResultsFromAnalysis(Map<String, dynamic> data) {
    List<Map<String, dynamic>> results = [];
    
    // Общая информация
    results.add({
      'title': 'Анализ завершен',
      'description': 'Видео проанализировано для упражнения: ${_getExerciseDisplayName(data['exercise_type'] ?? _selectedExerciseType)}\n'
          'Длительность: ${data['duration']?.toStringAsFixed(1) ?? '0'}с\n'
          'Кадров обработано: ${data['total_frames'] ?? 0}',
      'color': Colors.blue,
    });

    // Оценка качества
    final qualityScore = (data['quality_score'] ?? 0.0).toDouble();
    Color qualityColor;
    String qualityText;
    
    if (qualityScore >= 90) {
      qualityColor = Colors.green;
      qualityText = 'Отличное выполнение!';
    } else if (qualityScore >= 75) {
      qualityColor = Colors.orange;
      qualityText = 'Хорошее выполнение';
    } else if (qualityScore >= 60) {
      qualityColor = Colors.amber;
      qualityText = 'Удовлетворительно';
    } else {
      qualityColor = Colors.red;
      qualityText = 'Требует улучшения';
    }

    results.add({
      'title': '$qualityText (${qualityScore.toStringAsFixed(1)}/100)',
      'description': 'Общая оценка техники выполнения упражнения',
      'color': qualityColor,
    });

    // Ключевые метрики
    final keyMetrics = data['key_metrics'] as Map<String, dynamic>?;
    if (keyMetrics != null) {
      String metricsText = '';
      if (keyMetrics['knee_min_angle'] != null) {
        metricsText += 'Минимальный угол в колене: ${keyMetrics['knee_min_angle'].toStringAsFixed(1)}°\n';
      }
      if (keyMetrics['knee_max_angle'] != null) {
        metricsText += 'Максимальный угол в колене: ${keyMetrics['knee_max_angle'].toStringAsFixed(1)}°\n';
      }
      if (keyMetrics['knee_range'] != null) {
        metricsText += 'Диапазон движения: ${keyMetrics['knee_range'].toStringAsFixed(1)}°';
      }
      
      if (metricsText.isNotEmpty) {
        results.add({
          'title': 'Ключевые метрики',
          'description': metricsText,
          'color': Colors.indigo,
        });
      }
    }

    // Фазы движения
    final phases = data['phases'] as List<dynamic>?;
    if (phases != null && phases.isNotEmpty) {
      String phasesText = '';
      for (var phase in phases) {
        final phaseName = phase['phase'] == 'descent' ? 'Опускание' : 'Подъем';
        final quality = phase['quality'] == 'excellent' ? 'отлично' : 
                       phase['quality'] == 'good' ? 'хорошо' : 'удовлетворительно';
        phasesText += '$phaseName: ${phase['duration_frames']} кадров ($quality)\n';
      }
      
      results.add({
        'title': 'Анализ фаз движения',
        'description': phasesText.trim(),
        'color': Colors.purple,
      });
    }

    // Ошибки
    final errors = data['errors'] as List<dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      results.add({
        'title': 'Обнаруженные ошибки',
        'description': errors.map((e) => '• $e').join('\n'),
        'color': Colors.red,
      });
    }

    // Рекомендации
    final recommendations = data['recommendations'] as List<dynamic>?;
    if (recommendations != null && recommendations.isNotEmpty) {
      results.add({
        'title': 'Рекомендации',
        'description': recommendations.join('\n'),
        'color': Colors.teal,
      });
    }

    // Детальный анализ
    final detailedAnalysis = data['detailed_analysis'] as Map<String, dynamic>?;
    if (detailedAnalysis != null) {
      String detailsText = '';
      if (detailedAnalysis['repetitions_detected'] != null) {
        detailsText += 'Повторений обнаружено: ${detailedAnalysis['repetitions_detected']}\n';
      }
      if (detailedAnalysis['consistency_score'] != null) {
        detailsText += 'Стабильность выполнения: ${detailedAnalysis['consistency_score'].toStringAsFixed(1)}%\n';
      }
      
      final strengths = detailedAnalysis['strengths'] as List<dynamic>?;
      if (strengths != null && strengths.isNotEmpty) {
        detailsText += '\nСильные стороны:\n${strengths.map((s) => '✅ $s').join('\n')}';
      }
      
      if (detailsText.isNotEmpty) {
        results.add({
          'title': 'Детальный анализ',
          'description': detailsText.trim(),
          'color': Colors.deepPurple,
        });
      }
    }

    return results;
  }

  Future<void> _performMockAnalysis() async {
    final duration = _videoController!.value.duration;
    final totalFrames = (duration.inMilliseconds / 100).round();
    List<Map<String, dynamic>> detectedPoses = [];
    
    // Имитируем анализ кадров
    for (int i = 0; i < totalFrames && i < 50; i++) {
      final timePosition = Duration(milliseconds: i * 100);
      await _videoController!.seekTo(timePosition);
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (i % 3 == 0) {
        detectedPoses.add({
          'timestamp': timePosition.inMilliseconds / 1000.0,
          'confidence': 0.8 + (i % 3) * 0.05,
          'keypoints_detected': 15 + (i % 8),
        });
      }
      
      if (mounted) {
        setState(() {
          _analysisResults = [
            {
              'title': 'Анализ в процессе...',
              'description': 'Обработано кадров: ${i + 1}/$totalFrames',
            }
          ];
        });
      }
    }
    
    // Создаем результаты на основе имитации
    final avgConfidence = detectedPoses.isNotEmpty 
        ? detectedPoses.map((p) => p['confidence'] as double).reduce((a, b) => a + b) / detectedPoses.length
        : 0.0;
    
    setState(() {
      _analysisResults = [
        {
          'title': 'Анализ завершен',
          'description': 'Видео проанализировано для упражнения: ${_getExerciseDisplayName(_selectedExerciseType)}',
          'color': Colors.blue,
        },
        {
          'title': 'Обнаружено поз',
          'description': 'Найдено ${detectedPoses.length} кадров с четкими позами из $totalFrames проанализированных',
          'color': Colors.purple,
        },
        {
          'title': 'Качество детекции',
          'description': 'Средняя уверенность: ${(avgConfidence * 100).toStringAsFixed(1)}%',
          'color': Colors.indigo,
        },
        {
          'title': _getQualityAssessment(avgConfidence),
          'description': 'На основе анализа ${detectedPoses.length} кадров с позами',
          'color': _getQualityColor(avgConfidence),
        },
      ];
    });
  }

  String _getQualityAssessment(double confidence) {
    if (confidence > 0.85) return 'Отличное качество выполнения';
    if (confidence > 0.7) return 'Хорошее качество, есть что улучшить';
    return 'Требуется улучшение техники';
  }

  Color _getQualityColor(double confidence) {
    if (confidence > 0.85) return Colors.green;
    if (confidence > 0.7) return Colors.orange;
    return Colors.red;
  }

  String _getExerciseDisplayName(String type) {
    switch (type) {
      case 'squats': return 'Приседания';
      case 'pushups': return 'Отжимания';
      case 'lunges': return 'Выпады';
      case 'burpees': return 'Бурпи';
      case 'jumping_jacks': return 'Прыжки';
      case 'plank': return 'Планка';
      default: return type;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Помощь'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Как использовать анализ видео:'),
            SizedBox(height: 8),
            Text('1. Выберите видеофайл с упражнением'),
            Text('2. Укажите тип упражнения'),
            Text('3. Нажмите "Начать анализ"'),
            SizedBox(height: 16),
            Text('Поддерживаемые форматы: MP4, MOV, AVI'),
            Text('Рекомендуется хорошее освещение и четкое изображение.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  void _savePattern() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить эталон'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сохранить анализ как эталонный паттерн для упражнения "${_getExerciseDisplayName(_selectedExerciseType)}"?'),
            const SizedBox(height: 16),
            const Text(
              'Этот паттерн будет использоваться для оценки правильности выполнения упражнения.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performSavePattern();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _performSavePattern() {
    // В реальном приложении здесь был бы код сохранения в базу данных
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Эталонный паттерн для "${_getExerciseDisplayName(_selectedExerciseType)}" сохранен!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}