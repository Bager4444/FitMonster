import 'package:flutter/material.dart';
import 'package:fitmonster/features/exercises/data/exercises_database.dart';

/// Страница тестирования отдельной группы мышц
class MuscleGroupTestPage extends StatefulWidget {
  final String groupName;
  final List<String> exercises;
  final Color color;

  const MuscleGroupTestPage({
    super.key,
    required this.groupName,
    required this.exercises,
    required this.color,
  });

  @override
  State<MuscleGroupTestPage> createState() => _MuscleGroupTestPageState();
}

class _MuscleGroupTestPageState extends State<MuscleGroupTestPage> {
  int _currentExerciseIndex = 0;
  final List<int> _testResults = [];
  bool _isTestCompleted = false;

  @override
  Widget build(BuildContext context) {
    if (_isTestCompleted) {
      return _buildResultsPage();
    }
    
    if (_currentExerciseIndex >= widget.exercises.length) {
      return _buildCompletionPage();
    }
    
    return _buildTestPage();
  }

  Widget _buildTestPage() {
    final exerciseId = widget.exercises[_currentExerciseIndex];
    final exercise = ExercisesDatabase.getExerciseById(exerciseId);
    
    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: const Center(child: Text('Упражнение не найдено')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.color,
              widget.color.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Заголовок и прогресс
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Тест: ${widget.groupName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Упражнение ${_currentExerciseIndex + 1} из ${widget.exercises.length}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (_currentExerciseIndex + 1) / widget.exercises.length,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Название упражнения
                Text(
                  exercise.nameRu,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Описание теста
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Выполните максимальное количество повторений',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        exercise.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '⏱️ Без ограничения по времени\n🎯 Делайте до отказа\n📊 Результат сохранится в профиле',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Иконка упражнения
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      _getExerciseEmoji(exerciseId),
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Кнопки
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _startExerciseTest(exercise),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: widget.color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Начать тест',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextButton(
                      onPressed: _skipExercise,
                      child: const Text(
                        'Пропустить упражнение',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionPage() {
    final averageResult = _testResults.isNotEmpty 
        ? _testResults.reduce((a, b) => a + b) / _testResults.length 
        : 0.0;
    
    String level;
    String description;
    
    if (averageResult > 15) {
      level = 'Отличный';
      description = 'Превосходная форма в группе "${widget.groupName}"!';
    } else if (averageResult >= 8) {
      level = 'Хороший';
      description = 'Хорошие результаты в группе "${widget.groupName}".';
    } else {
      level = 'Начальный';
      description = 'Есть потенциал для роста в группе "${widget.groupName}".';
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFD700),
              widget.color,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                const Text(
                  '🏆 Тест завершен!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Результаты
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ваши результаты:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._testResults.asMap().entries.map((entry) {
                        final index = entry.key;
                        final result = entry.value;
                        final exerciseId = widget.exercises[index];
                        final exercise = ExercisesDatabase.getExerciseById(exerciseId);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                exercise?.nameRu ?? 'Упражнение',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '$result повторений',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Оценка
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Уровень: $level',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Средний результат: ${averageResult.toStringAsFixed(1)} повторений',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Кнопки
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentExerciseIndex = 0;
                            _testResults.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: widget.color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Повторить тест',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Вернуться в профиль',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsPage() {
    return Container(); // Заглушка, не используется
  }

  void _startExerciseTest(exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MuscleTestCameraPage(
          exercise: exercise,
          onTestComplete: (reps) {
            _testResults.add(reps);
            setState(() {
              _currentExerciseIndex++;
            });
          },
        ),
      ),
    );
  }

  void _skipExercise() {
    _testResults.add(0); // Добавляем 0 при пропуске
    setState(() {
      _currentExerciseIndex++;
    });
  }

  String _getExerciseEmoji(String exerciseId) {
    switch (exerciseId) {
      case 'pushups':
      case 'knee_pushups':
        return '💪';
      case 'squats':
      case 'jump_squats':
      case 'sumo_squats':
        return '🦵';
      case 'plank':
      case 'side_plank':
        return '🏋️';
      case 'lunges':
      case 'reverse_lunges':
      case 'lateral_lunges':
        return '🚶';
      case 'crunches':
      case 'bicycle_crunches':
      case 'russian_twists':
        return '🎯';
      case 'leg_raises':
      case 'reverse_crunches':
        return '📐';
      case 'running_in_place':
      case 'high_knees':
        return '🏃';
      case 'jumping_jacks':
      case 'jump_in_place':
        return '❤️';
      default:
        return '💪';
    }
  }
}

/// Упрощенная страница камеры для тестирования мышечной группы
class MuscleTestCameraPage extends StatefulWidget {
  final exercise;
  final Function(int) onTestComplete;

  const MuscleTestCameraPage({
    super.key,
    required this.exercise,
    required this.onTestComplete,
  });

  @override
  State<MuscleTestCameraPage> createState() => _MuscleTestCameraPageState();
}

class _MuscleTestCameraPageState extends State<MuscleTestCameraPage> {
  int _reps = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Тест: ${widget.exercise.nameRu}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Заглушка камеры
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Тест мышечной группы\n(упрощенная версия)',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Счетчик повторений
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_reps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'повторений',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Инструкция
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Выполняйте упражнение до отказа.\nНажимайте "+1" за каждое повторение.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Кнопки управления
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _reps++),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      '+1 повторение',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _reps > 0 ? () => setState(() => _reps--) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      '-1',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _completeTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Завершить',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeTest() {
    widget.onTestComplete(_reps);
    Navigator.of(context).pop();
  }
}