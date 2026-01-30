import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fitmonster/features/exercises/domain/models/workout_complex.dart';
import 'package:fitmonster/features/exercises/data/exercises_database.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercise_camera_page.dart';

/// Страница выполнения комплекса упражнений
class ComplexWorkoutPage extends StatefulWidget {
  final WorkoutComplex complex;
  final int initialRestTime;

  const ComplexWorkoutPage({
    super.key,
    required this.complex,
    this.initialRestTime = 30,
  });

  @override
  State<ComplexWorkoutPage> createState() => _ComplexWorkoutPageState();
}

class _ComplexWorkoutPageState extends State<ComplexWorkoutPage> {
  int _currentExerciseIndex = 0;
  bool _isResting = false;
  bool _isCompleted = false;
  bool _isCountingDown = false;
  int _countdownValue = 3;
  late int _restTimeSeconds; // Время отдыха из настроек
  int _currentRestTime = 0;
  
  @override
  void initState() {
    super.initState();
    _restTimeSeconds = widget.initialRestTime;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionScreen();
    }
    
    if (_isCountingDown) {
      return _buildCountdownScreen();
    }
    
    if (_isResting) {
      return _buildRestScreen();
    }
    
    return _buildExerciseScreen();
  }

  Widget _buildExerciseScreen() {
    final exerciseId = widget.complex.exerciseIds[_currentExerciseIndex];
    final exercise = ExercisesDatabase.getExerciseById(exerciseId);
    
    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: const Center(child: Text('Упражнение не найдено')),
      );
    }

    return ExerciseCameraPage(
      exercise: exercise,
      complex: widget.complex,
      currentExerciseIndex: _currentExerciseIndex,
      onExerciseComplete: _onExerciseComplete,
    );
  }

  Widget _buildCountdownScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF9800),
              Color(0xFFFF5722),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Готовьтесь к следующему упражнению',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Большой обратный отсчет
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdownValue',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Следующее упражнение
                if (_currentExerciseIndex < widget.complex.exerciseIds.length) ...[
                  Text(
                    'Следующее упражнение:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ExercisesDatabase.getExerciseById(
                      widget.complex.exerciseIds[_currentExerciseIndex]
                    )?.nameRu ?? 'Неизвестно',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Прогресс комплекса
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.complex.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Осталось ${widget.complex.exerciseIds.length - _currentExerciseIndex} из ${widget.complex.exerciseIds.length}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (_currentExerciseIndex + 1) / widget.complex.exerciseIds.length,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Отдых завершен
                const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.white,
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Упражнение завершено!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Отдохните ${_restTimeSeconds} секунд',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Таймер отдыха
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Text(
                      '$_currentRestTime',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Следующее упражнение
                if (_currentExerciseIndex + 1 < widget.complex.exerciseIds.length) ...[
                  Text(
                    'Следующее упражнение:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ExercisesDatabase.getExerciseById(
                      widget.complex.exerciseIds[_currentExerciseIndex + 1]
                    )?.nameRu ?? 'Неизвестно',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // Кнопки управления
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Пропустить отдых
                    ElevatedButton(
                      onPressed: _skipRest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Пропустить',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    // Изменить время отдыха
                    ElevatedButton(
                      onPressed: _showRestTimeDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('${_restTimeSeconds}с'),
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

  Widget _buildCompletionScreen() {
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 100,
                  color: Colors.white,
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Поздравляем!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Комплекс "${widget.complex.name}" завершен!',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Упражнений:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${widget.complex.exerciseIds.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Время:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '~${widget.complex.estimatedDuration} мин',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFFA000),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'Вернуться на главную',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  void _skipRest() {
    setState(() {
      _isResting = false;
      _currentExerciseIndex++;
      
      // Проверяем завершение комплекса
      if (_currentExerciseIndex >= widget.complex.exerciseIds.length) {
        _isCompleted = true;
      }
    });
  }

  void _onExerciseComplete() {
    // Переходим к следующему упражнению или завершаем комплекс
    if (_currentExerciseIndex + 1 >= widget.complex.exerciseIds.length) {
      // Комплекс завершен
      setState(() {
        _isCompleted = true;
      });
    } else {
      // Начинаем обратный отсчет перед следующим упражнением
      setState(() {
        _isCountingDown = true;
        _countdownValue = 3;
      });
      
      // Запускаем обратный отсчет
      _startCountdown();
    }
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isCountingDown) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdownValue--;
      });
      
      if (_countdownValue <= 0) {
        timer.cancel();
        // После обратного отсчета начинаем отдых
        setState(() {
          _isCountingDown = false;
          _isResting = true;
          _currentRestTime = _restTimeSeconds;
        });
        
        // Запускаем таймер отдыха
        _startRestTimer();
      }
    });
  }

  void _startRestTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isResting) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _currentRestTime--;
      });
      
      if (_currentRestTime <= 0) {
        timer.cancel();
        // Автоматически переходим к следующему упражнению
        setState(() {
          _isResting = false;
          _currentExerciseIndex++;
        });
      }
    });
  }

  void _showRestTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Время отдыха'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('15 секунд'),
              onTap: () => _setRestTime(15),
            ),
            ListTile(
              title: const Text('30 секунд'),
              onTap: () => _setRestTime(30),
            ),
            ListTile(
              title: const Text('60 секунд'),
              onTap: () => _setRestTime(60),
            ),
            ListTile(
              title: const Text('90 секунд'),
              onTap: () => _setRestTime(90),
            ),
          ],
        ),
      ),
    );
  }

  void _setRestTime(int seconds) {
    setState(() {
      _restTimeSeconds = seconds;
      _currentRestTime = seconds;
    });
    Navigator.of(context).pop();
  }
}