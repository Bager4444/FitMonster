import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../domain/models/exercise.dart';
import '../../data/exercises_database.dart';
import '../pages/enhanced_muscle_test_page.dart';

/// Виджет для запуска тестов мышечных групп
class MuscleTestLauncher extends StatelessWidget {
  const MuscleTestLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тесты по группам мышц',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Руки и грудь
            _buildMuscleGroupTest(
              context,
              'Руки и грудь',
              'Отжимания за 1 минуту',
              '💪',
              Colors.red,
              'pushups',
              themeProvider,
            ),
            
            const SizedBox(height: 12),
            
            // Ноги и ягодицы
            _buildMuscleGroupTest(
              context,
              'Ноги и ягодицы',
              'Приседания за 1 минуту',
              '🦵',
              Colors.green,
              'squats',
              themeProvider,
            ),
            
            const SizedBox(height: 12),
            
            // Пресс и кор
            _buildMuscleGroupTest(
              context,
              'Пресс и кор',
              'Скручивания за 1 минуту',
              '🎯',
              Colors.orange,
              'crunches',
              themeProvider,
            ),
            
            const SizedBox(height: 12),
            
            // Кардио выносливость
            _buildMuscleGroupTest(
              context,
              'Кардио выносливость',
              'Джампинг джекс за 1 минуту',
              '❤️',
              Colors.purple,
              'jumping_jacks',
              themeProvider,
            ),
          ],
        );
      },
    );
  }  

  Widget _buildMuscleGroupTest(
    BuildContext context,
    String groupName,
    String description,
    String emoji,
    Color color,
    String exerciseId,
    ThemeProvider themeProvider,
  ) {
    return GestureDetector(
      onTap: () => _launchMuscleTest(context, groupName, exerciseId, color),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Эмодзи
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '⏱️ 1 минута',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Стрелка
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  void _launchMuscleTest(
    BuildContext context,
    String groupName,
    String exerciseId,
    Color color,
  ) async {
    // Получаем упражнение из базы данных
    final exercise = ExercisesDatabase.getExerciseById(exerciseId);
    
    if (exercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Упражнение не найдено'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Показываем диалог подготовки
    final shouldStart = await _showPreparationDialog(context, groupName, exercise, color);
    
    if (shouldStart == true) {
      // Запускаем тест
      final result = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedMuscleTestPage(
            exercise: exercise,
            muscleGroup: groupName,
            groupColor: color,
          ),
        ),
      );
      
      // Показываем результат если тест был завершён
      if (result != null) {
        _showTestCompletedSnackBar(context, groupName, result);
      }
    }
  }
  
  Future<bool?> _showPreparationDialog(
    BuildContext context,
    String groupName,
    Exercise exercise,
    Color color,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.fitness_center,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Тест: $groupName',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Упражнение: ${exercise.nameRu}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              exercise.description,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Правила теста:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('⏱️ Время: 1 минута', style: TextStyle(fontSize: 12)),
                  Text('🎯 Цель: максимум повторений', style: TextStyle(fontSize: 12)),
                  Text('📱 Камера: следит за техникой', style: TextStyle(fontSize: 12)),
                  Text('🏆 Результат: сохраняется в профиле', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Готовы начать тест?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Начать тест'),
          ),
        ],
      ),
    );
  }
  
  void _showTestCompletedSnackBar(BuildContext context, String groupName, int result) {
    String message;
    Color backgroundColor;
    
    if (result >= 30) {
      message = '🏆 Отличный результат! $result повторений в тесте "$groupName"';
      backgroundColor = Colors.green;
    } else if (result >= 20) {
      message = '👍 Хороший результат! $result повторений в тесте "$groupName"';
      backgroundColor = Colors.blue;
    } else if (result >= 10) {
      message = '💪 Неплохо! $result повторений в тесте "$groupName"';
      backgroundColor = Colors.orange;
    } else {
      message = '🌱 Начало положено! $result повторений в тесте "$groupName"';
      backgroundColor = Colors.purple;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Повторить',
          textColor: Colors.white,
          onPressed: () {
            // Можно добавить логику повторного запуска теста
          },
        ),
      ),
    );
  }
}