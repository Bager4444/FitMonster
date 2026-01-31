import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Виджет для отображения информации о ключевых точках
class KeyPointsInfoWidget extends StatelessWidget {
  final List<PoseLandmarkType> keyPoints;
  final double confidence;
  final double? exerciseQuality;
  final List<String>? formCorrections;
  final String exerciseType;

  const KeyPointsInfoWidget({
    super.key,
    required this.keyPoints,
    required this.confidence,
    required this.exerciseType,
    this.exerciseQuality,
    this.formCorrections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getQualityColor().withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: _getQualityColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Анализ движения',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getQualityColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getExerciseDisplayName(exerciseType),
                  style: TextStyle(
                    color: _getQualityColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Статистика
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Точность детекции',
                  '${(confidence * 100).round()}%',
                  Icons.visibility,
                  confidence > 0.8 ? Colors.green : 
                  confidence > 0.6 ? Colors.orange : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Качество формы',
                  exerciseQuality != null ? '${(exerciseQuality! * 100).round()}%' : 'N/A',
                  Icons.fitness_center,
                  _getQualityColor(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Ключевые точки',
                  '${keyPoints.length}/10',
                  Icons.scatter_plot,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          // Ключевые точки для текущего упражнения
          const SizedBox(height: 12),
          Text(
            'Анализируемые точки:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: keyPoints.map((point) => _buildKeyPointChip(point)).toList(),
          ),
          
          // Рекомендации по форме
          if (formCorrections != null && formCorrections!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Рекомендации:',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...formCorrections!.map((correction) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            correction,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPointChip(PoseLandmarkType point) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getPointDisplayName(point),
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getQualityColor() {
    if (exerciseQuality == null) return Colors.grey;
    if (exerciseQuality! > 0.8) return Colors.green;
    if (exerciseQuality! > 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getExerciseDisplayName(String exerciseType) {
    switch (exerciseType) {
      case 'squats': return 'Приседания';
      case 'pushups': return 'Отжимания';
      case 'lunges': return 'Выпады';
      case 'crunches': return 'Скручивания';
      case 'plank': return 'Планка';
      case 'jumping_jacks': return 'Джампинг Джекс';
      case 'mountain_climbers': return 'Горные альпинисты';
      case 'high_knees': return 'Высокие колени';
      case 'burpees': return 'Бурпи';
      case 'jump_squats': return 'Приседания с прыжком';
      case 'reverse_lunges': return 'Обратные выпады';
      case 'knee_pushups': return 'Отжимания с колен';
      case 'side_plank': return 'Боковая планка';
      case 'calf_raises': return 'Подъемы на носки';
      case 'superman': return 'Супермен';
      case 'glute_bridge': return 'Ягодичный мостик';
      case 'bicycle_crunches': return 'Велосипед';
      case 'sumo_squats': return 'Приседания сумо';
      case 'plank_leg_lifts': return 'Планка с подъемом ног';
      case 'reverse_crunches': return 'Обратные скручивания';
      case 'burpee_pushup': return 'Бурпи с отжиманием';
      case 'lateral_lunges': return 'Выпады в сторону';
      case 'russian_twists': return 'Русские скручивания';
      case 'single_leg_deadlift': return 'Мертвая тяга на одной ноге';
      case 'jump_in_place': return 'Прыжки на месте';
      case 'sit_ups': return 'Подъемы корпуса';
      case 'leg_raises': return 'Подъем ног';
      case 'jump_rope': return 'Прыжки со скакалкой';
      case 'running_in_place': return 'Бег на месте';
      case 'downward_dog': return 'Собака мордой вниз';
      default: return exerciseType.toUpperCase();
    }
  }

  String _getPointDisplayName(PoseLandmarkType point) {
    switch (point) {
      case PoseLandmarkType.nose: return 'Нос';
      case PoseLandmarkType.leftShoulder: return 'Л.Плечо';
      case PoseLandmarkType.rightShoulder: return 'П.Плечо';
      case PoseLandmarkType.leftElbow: return 'Л.Локоть';
      case PoseLandmarkType.rightElbow: return 'П.Локоть';
      case PoseLandmarkType.leftWrist: return 'Л.Запястье';
      case PoseLandmarkType.rightWrist: return 'П.Запястье';
      case PoseLandmarkType.leftHip: return 'Л.Бедро';
      case PoseLandmarkType.rightHip: return 'П.Бедро';
      case PoseLandmarkType.leftKnee: return 'Л.Колено';
      case PoseLandmarkType.rightKnee: return 'П.Колено';
      case PoseLandmarkType.leftAnkle: return 'Л.Лодыжка';
      case PoseLandmarkType.rightAnkle: return 'П.Лодыжка';
      case PoseLandmarkType.leftHeel: return 'Л.Пятка';
      case PoseLandmarkType.rightHeel: return 'П.Пятка';
      case PoseLandmarkType.leftFootIndex: return 'Л.Палец';
      case PoseLandmarkType.rightFootIndex: return 'П.Палец';
      case PoseLandmarkType.leftPinky: return 'Л.Мизинец';
      case PoseLandmarkType.rightPinky: return 'П.Мизинец';
      case PoseLandmarkType.leftIndex: return 'Л.Указат.';
      case PoseLandmarkType.rightIndex: return 'П.Указат.';
      case PoseLandmarkType.leftThumb: return 'Л.Большой';
      case PoseLandmarkType.rightThumb: return 'П.Большой';
      default: return point.name;
    }
  }
}