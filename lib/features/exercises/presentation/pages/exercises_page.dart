import 'package:flutter/material.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/widgets/glass_card.dart';
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
  String _searchQuery = '';
  final _searchController = TextEditingController();
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: _buildContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroSection(),
        const SizedBox(height: 16),
        _buildCategories(context),
        const SizedBox(height: 12),
        _buildSearchBar(context),
        const SizedBox(height: 16),
        _buildQuickStart(context),
        const SizedBox(height: 16),
        _buildExercisesGrid(context),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Упражнения',
              style: GlassTheme.titleStyle.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 4),
            Text(
              'Выберите упражнение для тренировки',
              style: GlassTheme.bodyStyle.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: EdgeInsets.only(right: index < _categories.length - 1 ? 10 : 0),
            child: GlassContainer(
              onTap: () => setState(() => _selectedCategory = category),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              borderRadius: 24,
              blurSigma: 8,
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? GlassTheme.glowCyan : GlassTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: GlassTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Поиск упражнений...',
          hintStyle: const TextStyle(color: GlassTheme.textSecondary, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: GlassTheme.textSecondary, size: 22),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: GlassTheme.glowCyan),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildQuickStart(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрый старт',
            style: GlassTheme.titleStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  onTap: _startRandomExercise,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.casino, color: GlassTheme.glowCyan, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Случайное',
                        style: GlassTheme.titleStyle.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  onTap: _startLastExercise,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.replay, color: GlassTheme.glowCyan, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Последнее',
                        style: GlassTheme.titleStyle.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesGrid(BuildContext context) {
    final exercises = _searchQuery.trim().isEmpty
        ? ExercisesDatabase.getAllExercises()
        : ExercisesDatabase.searchExercises(_searchQuery.trim());
    final filteredExercises = _selectedCategory == 'Все'
        ? exercises
        : exercises.where((e) => ExerciseColors.getCategoryForExercise(e.id) == _selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Все упражнения',
            style: GlassTheme.titleStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = 2;
              final spacing = 12.0;
              final width = (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(filteredExercises.length, (index) {
                  return SizedBox(
                    width: width,
                    child: _buildExerciseCard(filteredExercises[index], index),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 150, maxHeight: 190),
      child: GlassCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseDetailPage(exercise: exercise),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: GlassTheme.glowCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getEmojiForExercise(exercise.id),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exercise.nameRu,
                        style: GlassTheme.titleStyle.copyWith(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ExerciseColors.getCategoryForExercise(exercise.id),
                        style: GlassTheme.bodyStyle.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                _getDifficultyText(_getDifficultyForExercise(exercise.id)),
                style: GlassTheme.bodyStyle.copyWith(fontSize: 11),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseCameraPage(exercise: exercise),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, color: GlassTheme.glowCyan, size: 18),
                label: const Text('Начать', style: TextStyle(color: GlassTheme.glowCyan, fontWeight: FontWeight.bold, fontSize: 13)),
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