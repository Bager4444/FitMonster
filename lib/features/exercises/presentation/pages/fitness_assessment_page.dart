import 'package:flutter/material.dart';
import 'package:fitmonster/features/exercises/data/exercises_database.dart';
import 'package:fitmonster/features/exercises/data/workout_complexes_database.dart';
import 'package:fitmonster/features/exercises/domain/models/fitness_test.dart';

/// Страница фитнес-оценки для определения подходящего комплекса
class FitnessAssessmentPage extends StatefulWidget {
  const FitnessAssessmentPage({super.key});

  @override
  State<FitnessAssessmentPage> createState() => _FitnessAssessmentPageState();
}

class _FitnessAssessmentPageState extends State<FitnessAssessmentPage> {
  int _currentTestIndex = 0;
  final List<FitnessTestResult> _testResults = [];
  
  // Тестовые упражнения
  final List<String> _testExercises = [
    'pushups',  // Отжимания - тест верха тела
    'squats',   // Приседания - тест низа тела
  ];
  
  final List<String> _testNames = [
    'Тест отжиманий',
    'Тест приседаний',
  ];
  
  final List<String> _testDescriptions = [
    'Выполните максимальное количество отжиманий за 1 минуту',
    'Выполните максимальное количество приседаний за 1 минуту',
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentTestIndex >= _testExercises.length) {
      return _buildResultsPage();
    }
    
    return _buildTestPage();
  }

  Widget _buildTestPage() {
    final exercise = ExercisesDatabase.getExerciseById(_testExercises[_currentTestIndex]);
    
    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: const Center(child: Text('Упражнение не найдено')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Прогресс
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
                            'Фитнес-тест ${_currentTestIndex + 1} из ${_testExercises.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (_currentTestIndex + 1) / _testExercises.length,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Название теста
                Text(
                  _testNames[_currentTestIndex],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Описание
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _testDescriptions[_currentTestIndex],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '⏱️ Время: 1 минута\n🎯 Цель: Максимальное количество повторений\n📊 Результат поможет подобрать комплекс',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Изображение упражнения (эмодзи)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      _currentTestIndex == 0 ? '💪' : '🦵',
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Кнопка начать тест
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _startTest(exercise),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF667eea),
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
                
                const SizedBox(height: 16),
                
                // Кнопка пропустить
                TextButton(
                  onPressed: _skipTest,
                  child: const Text(
                    'Пропустить тест',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsPage() {
    final recommendation = _calculateRecommendation();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFFA000),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Заголовок
                const Text(
                  '🎉 Тест завершен!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Результаты тестов
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _testNames[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${result.reps} повторений',
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
                
                // Рекомендация
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Рекомендуемый уровень: ${recommendation['level']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFA000),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        recommendation['description'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Кнопки действий
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showRecommendedComplexes(recommendation['difficulty']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFFA000),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Посмотреть рекомендуемые комплексы',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text(
                        'Вернуться на главную',
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

  void _startTest(exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FitnessTestCameraPage(
          exercise: exercise,
          onTestComplete: (reps) {
            _testResults.add(FitnessTestResult(
              exerciseId: exercise.id,
              exerciseName: exercise.nameRu,
              reps: reps,
              testDate: DateTime.now(),
            ));
            
            setState(() {
              _currentTestIndex++;
            });
          },
        ),
      ),
    );
  }

  void _skipTest() {
    // Добавляем средний результат при пропуске
    _testResults.add(FitnessTestResult(
      exerciseId: _testExercises[_currentTestIndex],
      exerciseName: _testNames[_currentTestIndex],
      reps: 8, // Средний результат для среднего уровня
      testDate: DateTime.now(),
    ));
    
    setState(() {
      _currentTestIndex++;
    });
  }

  Map<String, dynamic> _calculateRecommendation() {
    if (_testResults.isEmpty) {
      return {
        'level': 'Начинающий',
        'difficulty': 'beginner',
        'description': 'Начните с базовых упражнений и постепенно увеличивайте нагрузку.',
      };
    }
    
    // Вычисляем средний результат
    final averageReps = _testResults.map((r) => r.reps).reduce((a, b) => a + b) / _testResults.length;
    
    if (averageReps > 15) {
      return {
        'level': 'Продвинутый',
        'difficulty': 'advanced',
        'description': 'Отличная физическая форма! Вам подойдут интенсивные комплексы с высокой нагрузкой.',
      };
    } else if (averageReps >= 6) {
      return {
        'level': 'Средний',
        'difficulty': 'intermediate',
        'description': 'Хорошая базовая подготовка. Можете выполнять комплексы средней сложности.',
      };
    } else {
      return {
        'level': 'Начинающий',
        'difficulty': 'beginner',
        'description': 'Начните с простых комплексов и постепенно повышайте нагрузку.',
      };
    }
  }

  void _showRecommendedComplexes(String difficulty) {
    final complexes = WorkoutComplexesDatabase.getComplexesByDifficulty(difficulty);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Рекомендуемые комплексы',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: complexes.length,
                itemBuilder: (context, index) {
                  final complex = complexes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Text(
                        complex.imageUrl,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(complex.name),
                      subtitle: Text('${complex.exerciseIds.length} упражнений • ${complex.estimatedDuration} мин'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        // Здесь можно добавить переход к конкретному комплексу
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Специальная страница камеры для фитнес-теста с таймером на 1 минуту
class FitnessTestCameraPage extends StatefulWidget {
  final exercise;
  final Function(int) onTestComplete;

  const FitnessTestCameraPage({
    super.key,
    required this.exercise,
    required this.onTestComplete,
  });

  @override
  State<FitnessTestCameraPage> createState() => _FitnessTestCameraPageState();
}

class _FitnessTestCameraPageState extends State<FitnessTestCameraPage> {
  int _timeLeft = 60; // 1 минута
  int _reps = 0;
  bool _isActive = false;
  
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
            // Здесь будет камера (упрощенная версия)
            const Center(
              child: Text(
                'Камера для теста\n(упрощенная версия)',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Таймер
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⏱️ $_timeLeft сек',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Счетчик повторений
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_reps повторений',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Кнопки управления
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isActive ? null : _startTest,
                    child: const Text('Старт'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _reps++),
                    child: const Text('+1 повторение'),
                  ),
                  ElevatedButton(
                    onPressed: _completeTest,
                    child: const Text('Завершить'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTest() {
    setState(() {
      _isActive = true;
    });
    
    // Запускаем таймер на 1 минуту
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isActive) return false;
      
      setState(() {
        _timeLeft--;
      });
      
      if (_timeLeft <= 0) {
        _completeTest();
        return false;
      }
      
      return true;
    });
  }

  void _completeTest() {
    widget.onTestComplete(_reps);
    Navigator.of(context).pop();
  }
}