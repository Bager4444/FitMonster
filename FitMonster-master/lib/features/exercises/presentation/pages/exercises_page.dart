import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';
import 'package:fitmonster/features/exercises/domain/models/exercise.dart';
import 'package:fitmonster/features/exercises/data/exercises_database.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercise_camera_page.dart';
import 'package:fitmonster/features/exercises/presentation/pages/demo_camera_page.dart';
import 'package:fitmonster/features/exercises/presentation/pages/simple_pose_test_page.dart';
import 'package:fitmonster/features/exercises/presentation/widgets/muscle_diagram.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercise_detail_page.dart';
import 'package:fitmonster/features/exercises/utils/exercise_colors.dart';
import 'package:fitmonster/core/theme/app_theme.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final _searchController = TextEditingController();
  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  ExerciseCategory? _selectedCategory;
  ExerciseDifficulty? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadExercises() {
    setState(() {
      _exercises = ExercisesDatabase.getAllExercises();
      _filteredExercises = _exercises;
    });
  }

  void _filterExercises() {
    List<Exercise> filtered = _exercises;

    // Фильтр по категории
    if (_selectedCategory != null) {
      filtered = filtered
          .where((e) => e.category == _selectedCategory)
          .toList();
    }

    // Фильтр по сложности
    if (_selectedDifficulty != null) {
      filtered = filtered
          .where((e) => e.difficulty == _selectedDifficulty)
          .toList();
    }

    // Поиск
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((e) => e.nameRu.toLowerCase().contains(query) ||
              e.description.toLowerCase().contains(query))
          .where((e) => filtered.contains(e))
          .toList();
    }

    setState(() {
      _filteredExercises = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            title: const Text('Упражнения'),
            backgroundColor: themeProvider.backgroundColor,
            foregroundColor: themeProvider.textColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
          body: Column(
            children: [
              // Поиск
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterExercises(),
                  decoration: InputDecoration(
                    hintText: 'Поиск упражнений...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: themeProvider.cardColor,
                  ),
                ),
              ),
              
              // Список упражнений
              Expanded(
                child: _filteredExercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: themeProvider.secondaryTextColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Упражнения не найдены',
                              style: TextStyle(
                                fontSize: 18,
                                color: themeProvider.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          return _ExerciseCard(
                            exercise: exercise,
                            themeProvider: themeProvider,
                            onTap: () => _showExerciseDetails(exercise),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Категория
            DropdownButtonFormField<ExerciseCategory?>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Все')),
                ...ExerciseCategory.values.map((category) =>
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.nameRu),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Сложность
            DropdownButtonFormField<ExerciseDifficulty?>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(labelText: 'Сложность'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Все')),
                ...ExerciseDifficulty.values.map((difficulty) =>
                    DropdownMenuItem(
                      value: difficulty,
                      child: Text(difficulty.nameRu),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedDifficulty = null;
              });
              _filterExercises();
              Navigator.pop(context);
            },
            child: const Text('Сбросить'),
          ),
          ElevatedButton(
            onPressed: () {
              _filterExercises();
              Navigator.pop(context);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetails(Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailPage(exercise: exercise),
      ),
    );
  }
}
/// Карточка упражнения
class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final ThemeProvider themeProvider;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.themeProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ExerciseColors.getColorsForExerciseType(exercise.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: themeProvider.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Иконка с градиентом
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    exercise.category.emoji,
                    style: const TextStyle(fontSize: 32),
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
                      exercise.nameRu,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ExerciseColors.getCategoryForExercise(exercise.id),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors[0],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          exercise.difficulty.nameRu,
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.muscleGroups.join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Стрелка
              Icon(Icons.chevron_right, color: themeProvider.textColor),
            ],
          ),
        ),
      ),
    );
  }
}