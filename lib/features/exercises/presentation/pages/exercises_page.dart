import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/features/exercises/data/exercises_database.dart';
import 'package:fitmonster/features/exercises/domain/models/exercise.dart';
import 'package:fitmonster/features/exercises/utils/exercise_colors.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercise_camera_page.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercise_detail_page.dart';

/// Современная страница упражнений с красивым дизайном
/// Готова для конвертации через DhiWise
class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedCategory = 'Все';
  final List<String> _categories = [
    'Все',
    'Кардио',
    'Силовые',
    'Растяжка',
    'Функциональные',
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
                top: false,
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
        
        // Categories
        SliverToBoxAdapter(
          child: _buildCategories(themeProvider),
        ),
        
        // Search Bar
        SliverToBoxAdapter(
          child: _buildSearchBar(themeProvider),
        ),
        
        // Quick Start Section
        SliverToBoxAdapter(
          child: _buildQuickStart(themeProvider),
        ),
        
        // Exercises Grid
        SliverToBoxAdapter(
          child: _buildExercisesGrid(themeProvider),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: themeProvider.textColor,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () {
                  // Фильтры
                },
                icon: Icon(
                  Icons.tune,
                  color: themeProvider.textColor,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Упражнения',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Выберите упражнение для тренировки',
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

  Widget _buildCategories(ThemeProvider themeProvider) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Container(
            margin: EdgeInsets.only(right: index < _categories.length - 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? themeProvider.cardColor 
                      : themeProvider.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected 
                        ? themeProvider.buttonColor.withValues(alpha: 0.3)
                        : themeProvider.cardBorderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: themeProvider.buttonColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected 
                          ? themeProvider.buttonColor 
                          : themeProvider.textColor,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.inputFieldColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: themeProvider.cardBorderColor.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          style: TextStyle(
            color: themeProvider.inputTextColor,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Поиск упражнений...',
            hintStyle: TextStyle(
              color: themeProvider.inputHintColor,
              fontSize: 15,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.search,
                color: themeProvider.inputHintColor,
                size: 22,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStart(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрый старт',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildQuickStartCard(
                  title: 'Случайное упражнение',
                  emoji: '🎲',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  ),
                  onTap: () {
                    _startRandomExercise();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickStartCard(
                  title: 'Последнее упражнение',
                  emoji: '⏮️',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                  onTap: () {
                    _startLastExercise();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartCard({
    required String title,
    required String emoji,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Декоративные элементы
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                // Контент
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExercisesGrid(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Все упражнения',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 0),
          FutureBuilder<List<Exercise>>(
            future: Future.value(ExercisesDatabase.getAllExercises()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: themeProvider.accentColor),
                );
              }

              final exercises = snapshot.data ?? [];
              final filteredExercises = _selectedCategory == 'Все'
                  ? exercises
                  : exercises.where((e) => ExerciseColors.getCategoryForExercise(e.id) == _selectedCategory).toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = filteredExercises[index];
                  return _buildExerciseCard(exercise, index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    // Получаем цвета в зависимости от типа упражнения
    final colorPair = ExerciseColors.getColorsForExerciseType(exercise.id);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailPage(exercise: exercise),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colorPair,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorPair[0].withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Декоративный элемент
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Контент
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji иконка
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _getEmojiForExercise(exercise.id),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  Text(
                    exercise.nameRu,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Category и Difficulty
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ExerciseColors.getCategoryForExercise(exercise.id),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Difficulty
                  Row(
                    children: [
                      ...List.generate(3, (i) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: i < _getDifficultyForExercise(exercise.id)
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getDifficultyText(_getDifficultyForExercise(exercise.id)),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Кнопка начать
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseCameraPage(exercise: exercise),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: colorPair[0],
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Начать',
                            style: TextStyle(
                              color: colorPair[0],
                              fontSize: 13,
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
          ],
        ),
      ),
    );
  }

  String _getEmojiForExercise(String exerciseId) {
    switch (exerciseId) {
      case 'squats':
        return '🏋️'; // Приседания
      case 'pushups':
        return '💪'; // Отжимания
      case 'plank':
        return '🧘'; // Планка
      case 'lunges':
        return '🚶'; // Выпады
      case 'jumping_jacks':
        return '🤸'; // Прыжки
      case 'burpees':
        return '🔥'; // Бурпи
      case 'mountain_climbers':
        return '🏔️'; // Альпинист
      case 'high_knees':
        return '🏃'; // Высокие колени
      case 'crunches':
        return '💯'; // Скручивания
      case 'leg_raises':
        return '🦵'; // Подъем ног
      case 'sit_ups':
        return '⬆️'; // Подъемы туловища
      case 'bicycle_crunches':
        return '🚴'; // Велосипед
      case 'russian_twists':
        return '🌪️'; // Русские скручивания
      case 'wall_sit':
        return '🧱'; // Приседания у стены
      case 'tricep_dips':
        return '💺'; // Отжимания на трицепс
      case 'superman':
        return '🦸'; // Супермен
      case 'dead_bug':
        return '🐛'; // Мертвый жук
      case 'glute_bridges':
        return '🌉'; // Ягодичный мостик
      case 'side_plank':
        return '📐'; // Боковая планка
      case 'bear_crawl':
        return '🐻'; // Медвежья походка
      default:
        return '💪'; // По умолчанию
    }
  }

  int _getDifficultyForExercise(String exerciseId) {
    switch (exerciseId) {
      // Легкие упражнения
      case 'squats':
      case 'plank':
      case 'crunches':
      case 'jumping_jacks':
      case 'jump_rope':
      case 'running_in_place':
      case 'knee_pushups':
      case 'calf_raises':
      case 'superman':
      case 'glute_bridge':
      case 'sumo_squats':
      case 'downward_dog':
      case 'jump_in_place':
      case 'sit_ups':
        return 1; // Легкий
      
      // Средние упражнения
      case 'pushups':
      case 'lunges':
      case 'leg_raises':
      case 'mountain_climbers':
      case 'high_knees':
      case 'jump_squats':
      case 'reverse_lunges':
      case 'side_plank':
      case 'bicycle_crunches':
      case 'reverse_crunches':
      case 'lateral_lunges':
      case 'russian_twists':
        return 2; // Средний
      
      // Сложные упражнения
      case 'burpees':
      case 'plank_leg_lifts':
      case 'burpee_pushup':
      case 'single_leg_deadlift':
        return 3; // Сложный
      
      default:
        return 1;
    }
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Легкий';
      case 2:
        return 'Средний';
      case 3:
        return 'Сложный';
      default:
        return 'Легкий';
    }
  }

  void _startRandomExercise() {
    final exercises = ExercisesDatabase.getAllExercises();
    if (exercises.isNotEmpty) {
      final randomExercise = exercises[DateTime.now().millisecond % exercises.length];
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseCameraPage(exercise: randomExercise),
          ),
        );
      }
    }
  }

  void _startLastExercise() {
    // Здесь можно добавить логику для получения последнего упражнения
    // Пока что запускаем первое упражнение
    final exercises = ExercisesDatabase.getAllExercises();
    if (exercises.isNotEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseCameraPage(exercise: exercises.first),
          ),
        );
      }
    }
  }
}