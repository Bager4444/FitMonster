import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/features/exercises/data/workout_complexes_database.dart';
import 'package:fitmonster/features/exercises/data/exercises_database.dart';
import 'package:fitmonster/features/exercises/domain/models/workout_complex.dart';
import 'package:fitmonster/features/exercises/utils/exercise_colors.dart';
import 'package:fitmonster/features/exercises/presentation/pages/complex_workout_page.dart';

/// Страница комплексов упражнений
class WorkoutComplexesPage extends StatefulWidget {
  const WorkoutComplexesPage({super.key});

  @override
  State<WorkoutComplexesPage> createState() => _WorkoutComplexesPageState();
}

class _WorkoutComplexesPageState extends State<WorkoutComplexesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _animationDone = false;

  final Map<String, String> _exerciseNameCache = {};

  String _selectedCategory = 'Все';
  String _selectedDifficulty = 'Все';

  final List<String> _categories = [
    'Все',
    'Силовые',
    'Кардио',
    'Растяжка',
    'Всё тело',
  ];
  
  final List<String> _difficulties = [
    'Все',
    'Начинающий',
    'Средний',
    'Продвинутый',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _animationDone = true);
      }
    });
    _animationController.forward();
  }

  List<WorkoutComplex> _getFilteredComplexes() {
    final complexes = WorkoutComplexesDatabase.getAllComplexes();
    return complexes.where((complex) {
      final categoryMatch = _selectedCategory == 'Все' || complex.categoryName == _selectedCategory;
      final difficultyMatch = _selectedDifficulty == 'Все' || complex.difficultyName == _selectedDifficulty;
      return categoryMatch && difficultyMatch;
    }).toList();
  }

  String _getExerciseName(String exerciseId) {
    return _exerciseNameCache.putIfAbsent(
      exerciseId,
      () => ExercisesDatabase.getExerciseById(exerciseId)?.nameRu ?? exerciseId,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final filtered = _getFilteredComplexes();
        final content = SafeArea(
          top: true,
          bottom: true,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(themeProvider)),
              SliverToBoxAdapter(child: _buildFilters(themeProvider)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildComplexCard(filtered[index], index),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
        if (_animationDone) return content;
        return FadeTransition(opacity: _fadeAnimation, child: content);
      },
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Комплексы',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Готовые программы тренировок',
            style: TextStyle(
              fontSize: 15,
              color: themeProvider.secondaryTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Filter
          const Text(
            'Категория',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white 
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected 
                              ? const Color(0xFF667eea) 
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Difficulty Filter
          const Text(
            'Сложность',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _difficulties.length,
              itemBuilder: (context, index) {
                final difficulty = _difficulties[index];
                final isSelected = difficulty == _selectedDifficulty;
                
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDifficulty = difficulty;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white 
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        difficulty,
                        style: TextStyle(
                          color: isSelected 
                              ? const Color(0xFF667eea) 
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplexCard(WorkoutComplex complex, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showWorkoutSettingsDialog(complex),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      complex.imageUrl,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complex.name,
                        style: GlassTheme.titleStyle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              complex.categoryName,
                              style: GlassTheme.bodyStyle.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ExerciseColors.getComplexType(complex.exerciseIds),
                              style: GlassTheme.bodyStyle.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              complex.difficultyName,
                              style: GlassTheme.bodyStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complex.description,
              style: GlassTheme.bodyStyle.copyWith(fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Упражнения:',
                    style: GlassTheme.titleStyle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...complex.exerciseIds.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final exerciseId = entry.value;
                    final name = _getExerciseName(exerciseId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: GlassTheme.titleStyle.copyWith(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: GlassTheme.bodyStyle.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.timer, color: GlassTheme.textSecondary, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${complex.estimatedDuration} мин',
                  style: GlassTheme.bodyStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.fitness_center, color: GlassTheme.textSecondary, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${complex.exerciseIds.length} упражнений',
                  style: GlassTheme.bodyStyle.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Начать комплекс',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  /// Показать диалог настроек тренировки (стиль Deep Blue Glassmorphism)
  void _showWorkoutSettingsDialog(WorkoutComplex complex) {
    int selectedRestTime = 30; // По умолчанию 30 секунд

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2979FF),
                Color(0xFF0D1B2A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Настройки тренировки',
                        style: GlassTheme.titleStyle.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 20),
                      // Информация о комплексе (стеклянная карточка)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complex.name,
                              style: GlassTheme.titleStyle.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 16,
                                  color: GlassTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${complex.exerciseIds.length} упражнений',
                                  style: GlassTheme.bodyStyle,
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: GlassTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '~${complex.estimatedDuration} мин',
                                  style: GlassTheme.bodyStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Время перерыва между упражнениями:',
                        style: GlassTheme.titleStyle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [15, 30, 45, 60, 90, 120].map((seconds) {
                          final isSelected = selectedRestTime == seconds;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedRestTime = seconds;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? GlassTheme.glowCyan
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? GlassTheme.glowCyan
                                      : Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                '${seconds}с',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : GlassTheme.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Подсказка: иконка info чёрная по запросу (светлый фон для читаемости)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Вы сможете изменить время перерыва во время тренировки',
                                style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Отмена',
                              style: TextStyle(color: GlassTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ComplexWorkoutPage(
                                    complex: complex,
                                    initialRestTime: selectedRestTime,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlassTheme.glowCyan,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Начать тренировку'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}