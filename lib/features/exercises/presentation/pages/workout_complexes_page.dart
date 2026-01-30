import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/features/exercises/data/workout_complexes_database.dart';
import 'package:fitmonster/features/exercises/data/exercises_database.dart';
import 'package:fitmonster/features/exercises/domain/models/workout_complex.dart';
import 'package:fitmonster/features/exercises/utils/exercise_colors.dart';
import 'package:fitmonster/features/exercises/presentation/pages/complex_workout_page.dart';
import 'package:fitmonster/features/exercises/presentation/pages/fitness_assessment_page.dart';

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
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
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                top: true,
                bottom: true,
                child: _buildContent(themeProvider),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(ThemeProvider themeProvider) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: _buildHeader(themeProvider),
        ),
        
        // Filters
        SliverToBoxAdapter(
          child: _buildFilters(themeProvider),
        ),
        
        // Кнопка фитнес-теста
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FitnessAssessmentPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Пройти фитнес-тест',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Complexes Grid
        SliverToBoxAdapter(
          child: _buildComplexesGrid(themeProvider),
        ),
        
        // Bottom Spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
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

  Widget _buildComplexesGrid(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildComplexesList(),
        ],
      ),
    );
  }

  Widget _buildComplexesList() {
    final complexes = WorkoutComplexesDatabase.getAllComplexes();
    
    // Фильтрация
    final filteredComplexes = complexes.where((complex) {
      final categoryMatch = _selectedCategory == 'Все' || 
          complex.categoryName == _selectedCategory;
      final difficultyMatch = _selectedDifficulty == 'Все' || 
          complex.difficultyName == _selectedDifficulty;
      
      return categoryMatch && difficultyMatch;
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredComplexes.length,
      itemBuilder: (context, index) {
        final complex = filteredComplexes[index];
        return _buildComplexCard(complex, index);
      },
    );
  }

  Widget _buildComplexCard(WorkoutComplex complex, int index) {
    // Получаем цвета в зависимости от типа комплекса
    final colorPair = ExerciseColors.getColorsForComplexType(complex.exerciseIds);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorPair,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorPair[0].withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // Уменьшаем отступы
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji
                Container(
                  width: 50, // Уменьшаем размер
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      complex.imageUrl,
                      style: const TextStyle(fontSize: 28), // Уменьшаем размер
                    ),
                  ),
                ),
                
                const SizedBox(width: 12), // Уменьшаем отступ
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complex.name,
                        style: const TextStyle(
                          fontSize: 16, // Уменьшаем размер
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2), // Уменьшаем отступ
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Уменьшаем отступы
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              complex.categoryName,
                              style: const TextStyle(
                                fontSize: 10, // Уменьшаем размер
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6), // Уменьшаем отступ
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ExerciseColors.getComplexType(complex.exerciseIds),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Уменьшаем отступы
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              complex.difficultyName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12), // Уменьшаем отступ
            
            Text(
              complex.description,
              style: TextStyle(
                fontSize: 12, // Уменьшаем размер
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.3, // Уменьшаем межстрочный интервал
              ),
            ),
            
            const SizedBox(height: 12), // Уменьшаем отступ
            
            // Список упражнений
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...complex.exerciseIds.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exerciseId = entry.value;
                    final exercise = ExercisesDatabase.getExerciseById(exerciseId);
                    
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
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exercise?.nameRu ?? exerciseId,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
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
                Icon(
                  Icons.timer,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${complex.estimatedDuration} мин',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.fitness_center,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${complex.exerciseIds.length} упражнений',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Кнопка начать комплекс
            GestureDetector(
              onTap: () => _showWorkoutSettingsDialog(complex),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: colorPair[0],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Начать комплекс',
                      style: TextStyle(
                        color: colorPair[0],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Показать диалог настроек тренировки
  void _showWorkoutSettingsDialog(WorkoutComplex complex) {
    int selectedRestTime = 30; // По умолчанию 30 секунд
    
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor: themeProvider.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Настройки тренировки',
              style: TextStyle(
                color: themeProvider.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Информация о комплексе
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.buttonColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complex.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 16,
                                color: themeProvider.secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${complex.exerciseIds.length} упражнений',
                                style: TextStyle(
                                  color: themeProvider.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.timer,
                                size: 16,
                                color: themeProvider.secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '~${complex.estimatedDuration} мин',
                                style: TextStyle(
                                  color: themeProvider.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Выбор времени перерыва
                    Text(
                      'Время перерыва между упражнениями:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textColor,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Варианты времени перерыва
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
                                  ? themeProvider.buttonColor
                                  : themeProvider.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? themeProvider.buttonColor
                                    : themeProvider.cardBorderColor,
                              ),
                            ),
                            child: Text(
                              '${seconds}с',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : themeProvider.textColor,
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
                    
                    // Подсказка
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeProvider.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: themeProvider.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Вы сможете изменить время перерыва во время тренировки',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Отмена',
                  style: TextStyle(color: themeProvider.secondaryTextColor),
                ),
              ),
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
                  backgroundColor: themeProvider.buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Начать тренировку'),
              ),
            ],
          );
        },
      ),
    );
  }
}