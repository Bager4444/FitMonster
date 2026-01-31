import 'package:flutter/material.dart';
import 'package:fitmonster/features/exercises/domain/models/workout_session.dart';
import 'package:fitmonster/features/exercises/domain/services/workout_service.dart';
import 'package:fitmonster/core/services/auth_service.dart';

/// Страница истории тренировок
class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<WorkoutSession> _workouts = [];
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      setState(() => _isLoading = true);
      
      final authService = AuthService();
      final workoutService = WorkoutService();
      final userId = authService.currentUserId;
      
      if (userId != null) {
        final workouts = await workoutService.getUserWorkouts(userId);
        final stats = await workoutService.getWorkoutStats(userId);
        
        setState(() {
          _workouts = workouts;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_workouts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadWorkouts,
      child: Column(
        children: [
          // Статистика
          if (_stats != null) _buildStatsCard(),
          
          // Список тренировок
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _workouts.length,
              itemBuilder: (context, index) {
                final workout = _workouts[index];
                return _buildWorkoutCard(workout);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет тренировок',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Начните первую тренировку!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add),
            label: const Text('Начать тренировку'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _stats!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Общая статистика',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.fitness_center,
                  label: 'Тренировок',
                  value: '${stats['totalWorkouts']}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: 'Повторений',
                  value: '${stats['totalReps'] ?? 0}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.repeat,
                  label: 'Повторений',
                  value: '${stats['totalReps'] ?? 0}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.whatshot,
                  label: 'Минут',
                  value: '${(stats['totalDuration'] as Duration?)?.inMinutes ?? 0} мин',
                ),
              ),
            ],
          ),
          // Убираем любимое упражнение, так как его нет в статистике
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutSession workout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showWorkoutDetails(workout),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: workout.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getExerciseIcon(workout.exerciseName),
                      color: workout.status.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.exerciseName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(workout.startTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: workout.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workout.status.displayName,
                      style: TextStyle(
                        color: workout.status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Статистика тренировки
              Row(
                children: [
                  _buildWorkoutStat(
                    icon: Icons.repeat,
                    label: 'Повторений',
                    value: '${workout.totalReps}/${workout.targetReps}',
                  ),
                  const SizedBox(width: 16),
                  _buildWorkoutStat(
                    icon: Icons.timer,
                    label: 'Время',
                    value: _formatDuration(workout.duration),
                  ),
                  const SizedBox(width: 16),
                  _buildWorkoutStat(
                    icon: Icons.star,
                    label: 'Техника',
                    value: '${(workout.averageFormScore * 100).round()}%',
                  ),
                ],
              ),
              
              // Прогресс-бар
              if (workout.targetReps > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: workout.completionPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    workout.completionPercentage >= 1.0 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showWorkoutDetails(WorkoutSession workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildWorkoutDetailsSheet(workout),
    );
  }

  Widget _buildWorkoutDetailsSheet(WorkoutSession workout) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workout.exerciseName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              Text(
                _formatDate(workout.startTime),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Основная статистика
              _buildDetailStats(workout),
              
              const SizedBox(height: 20),
              
              // История повторений
              if (workout.repsData.isNotEmpty) ...[
                Text(
                  'История повторений',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: workout.repsData.length,
                    itemBuilder: (context, index) {
                      final rep = workout.repsData[index];
                      return _buildRepCard(rep);
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStats(WorkoutSession workout) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailStat(
                  'Повторений',
                  '${workout.totalReps}',
                  '/${workout.targetReps}',
                ),
              ),
              Expanded(
                child: _buildDetailStat(
                  'Длительность',
                  _formatDuration(workout.duration),
                  '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailStat(
                  'Средняя техника',
                  '${(workout.averageFormScore * 100).round()}%',
                  '',
                ),
              ),
              Expanded(
                child: _buildDetailStat(
                  'Калории',
                  '${workout.caloriesBurned.round()}',
                  ' ккал',
                ),
              ),
            ],
          ),
          if (workout.repsData.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailStat(
                    'Лучшая техника',
                    '${(workout.bestFormScore * 100).round()}%',
                    '',
                  ),
                ),
                Expanded(
                  child: _buildDetailStat(
                    'Темп',
                    '${workout.averageRepsPerMinute.round()}',
                    ' в мин',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, String suffix) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: suffix,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepCard(RepData rep) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Номер повторения
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getFormScoreColor(rep.formScore ?? 0.0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${rep.repNumber}',
                  style: TextStyle(
                    color: _getFormScoreColor(rep.formScore ?? 0.0),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Информация о повторении
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Техника: ${((rep.formScore ?? 0.0) * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${rep.timestamp.hour}:${rep.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  // Показываем только статус выполнения
                  if (!rep.isCorrect) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '❌ Неправильная техника',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    switch (exerciseName.toLowerCase()) {
      case 'приседания':
        return Icons.fitness_center;
      case 'отжимания':
        return Icons.accessibility_new;
      case 'планка':
        return Icons.horizontal_rule;
      case 'выпады':
        return Icons.directions_walk;
      default:
        return Icons.sports_gymnastics;
    }
  }

  Color _getFormScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Сегодня, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return '${weekdays[date.weekday - 1]}, ${date.day}.${date.month.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}м ${seconds}с';
    } else {
      return '${seconds}с';
    }
  }
}