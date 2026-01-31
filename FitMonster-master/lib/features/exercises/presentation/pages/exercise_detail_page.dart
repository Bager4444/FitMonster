import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/features/exercises/domain/models/exercise.dart';
import 'package:fitmonster/features/exercises/utils/exercise_colors.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercise_camera_page.dart';

/// Страница детального описания упражнения
class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailPage({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final colors = ExerciseColors.getColorsForExerciseType(exercise.id);
        
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: CustomScrollView(
            slivers: [
              // Красивый заголовок с градиентом
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: colors[0],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    exercise.nameRu,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            exercise.category.emoji,
                            style: const TextStyle(fontSize: 60),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ExerciseColors.getCategoryForExercise(exercise.id),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Основной контент
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Краткая информация
                      _buildInfoCards(themeProvider),
                      
                      const SizedBox(height: 24),
                      
                      // Описание
                      _buildSection(
                        'Описание',
                        exercise.description,
                        Icons.description,
                        themeProvider,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Инструкции
                      _buildInstructionsSection(themeProvider),
                      
                      const SizedBox(height: 24),
                      
                      // Частые ошибки
                      _buildMistakesSection(themeProvider),
                      
                      const SizedBox(height: 24),
                      
                      // Мышечные группы
                      _buildMuscleGroupsSection(themeProvider),
                      
                      const SizedBox(height: 32),
                      
                      // Кнопка начать упражнение
                      _buildStartButton(context, themeProvider, colors),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  /// Карточки с краткой информацией
  Widget _buildInfoCards(ThemeProvider themeProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Сложность',
            exercise.difficulty.nameRu,
            Icons.fitness_center,
            themeProvider,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Калории',
            '${exercise.caloriesPerMinute}/мин',
            Icons.local_fire_department,
            themeProvider,
          ),
        ),
      ],
    );
  }

  /// Отдельная информационная карточка
  Widget _buildInfoCard(String title, String value, IconData icon, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: themeProvider.accentColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Секция с заголовком и контентом
  Widget _buildSection(String title, String content, IconData icon, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: themeProvider.accentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            content,
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Секция с инструкциями
  Widget _buildInstructionsSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.list_alt,
              color: themeProvider.accentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Техника выполнения',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: exercise.instructions.asMap().entries.map((entry) {
              final index = entry.key;
              final instruction = entry.value;
              
              return Padding(
                padding: EdgeInsets.only(bottom: index == exercise.instructions.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeProvider.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction,
                        style: TextStyle(
                          color: themeProvider.textColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  /// Секция с частыми ошибками
  Widget _buildMistakesSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Частые ошибки',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: exercise.commonMistakes.asMap().entries.map((entry) {
              final index = entry.key;
              final mistake = entry.value;
              
              return Padding(
                padding: EdgeInsets.only(bottom: index == exercise.commonMistakes.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mistake,
                        style: TextStyle(
                          color: themeProvider.textColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Секция с мышечными группами
  Widget _buildMuscleGroupsSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.accessibility_new,
              color: themeProvider.accentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Работающие мышцы',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: exercise.muscleGroups.map((muscle) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeProvider.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeProvider.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                muscle,
                style: TextStyle(
                  color: themeProvider.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Кнопка начать упражнение
  Widget _buildStartButton(BuildContext context, ThemeProvider themeProvider, List<Color> colors) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseCameraPage(exercise: exercise),
              ),
            );
          },
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Начать упражнение',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}