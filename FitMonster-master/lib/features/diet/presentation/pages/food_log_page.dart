import 'package:flutter/material.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';
import 'package:fitmonster/features/diet/domain/services/calorie_calculator.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';
import 'package:fitmonster/features/diet/presentation/widgets/add_food_dialog.dart';
import 'package:fitmonster/features/diet/presentation/pages/profile_setup_page.dart';
import 'package:fitmonster/core/theme/app_theme.dart';

/// Экран журнала питания за день
class FoodLogPage extends StatefulWidget {
  final DateTime date;
  final Macros targetMacros;
  final VoidCallback? onProfileUpdated;

  const FoodLogPage({
    super.key,
    required this.date,
    required this.targetMacros,
    this.onProfileUpdated,
  });

  @override
  State<FoodLogPage> createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
  List<FoodLog> _logs = [];
  bool _isLoading = true;

  DailySummary get _summary => DailySummary.fromLogs(widget.date, _logs);

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await DietService.getFoodLogsForDate(widget.date);
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(widget.date)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Изменить профиль',
            onPressed: () async {
              // Открыть настройки профиля
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSetupPage(),
                ),
              );
              
              // Если профиль обновлен, вызвать callback
              if (result == true && mounted) {
                widget.onProfileUpdated?.call();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Выбрать дату',
            onPressed: () {
              // TODO: Выбор даты
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Прогресс калорий
          _buildCalorieProgress(),
          
          // Макронутриенты
          _buildMacrosProgress(),
          
          const Divider(height: 1),
          
          // Список приемов пищи
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? _buildEmptyState()
                    : _buildMealsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMealTypeSelector();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalorieProgress() {
    final progress = _summary.totalCalories / widget.targetMacros.calories;
    final progressClamped = progress.clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Калории',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${_summary.totalCalories} / ${widget.targetMacros.calories}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(progress),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressClamped,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getProgressMessage(progress),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _MacroProgressCard(
              label: 'Белки',
              current: _summary.totalProtein.round(),
              target: widget.targetMacros.protein,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MacroProgressCard(
              label: 'Жиры',
              current: _summary.totalFat.round(),
              target: widget.targetMacros.fat,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MacroProgressCard(
              label: 'Углеводы',
              current: _summary.totalCarbs.round(),
              target: widget.targetMacros.carbs,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет записей за этот день',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите + чтобы добавить продукт',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...MealType.values.map((mealType) {
          final mealLogs = _summary.getLogsByMealType(mealType);
          final mealCalories = _summary.getCaloriesByMealType(mealType);
          
          return _MealSection(
            mealType: mealType,
            logs: mealLogs,
            totalCalories: mealCalories,
            onAddFood: () => _showAddFoodDialog(mealType: mealType),
            onDeleteLog: (log) => _deleteLog(log),
            onUpdate: _loadLogs,
          );
        }),
      ],
    );
  }

  void _showMealTypeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите прием пищи',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...MealType.values.map((mealType) => ListTile(
                  leading: Text(
                    mealType.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(
                    mealType.nameRu,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddFoodDialog(mealType: mealType);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddFoodDialog({MealType? mealType}) {
    showDialog(
      context: context,
      builder: (context) => AddFoodDialog(
        mealType: mealType ?? MealType.breakfast,
        onAdd: (log) async {
          await DietService.addFoodLog(log);
          await _loadLogs();
          
          if (mounted) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              SnackBar(
                content: Text('${log.foodName} добавлен'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteLog(FoodLog log) async {
    await DietService.deleteFoodLog(log.id);
    await _loadLogs();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${log.foodName} удален'),
        ),
      );
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.8) return AppTheme.primaryGreen;
    if (progress < 1.0) return Colors.orange;
    return Colors.red;
  }

  String _getProgressMessage(double progress) {
    if (progress < 0.5) return 'Отличное начало! Продолжайте';
    if (progress < 0.8) return 'Хороший прогресс';
    if (progress < 1.0) return 'Почти достигли цели';
    if (progress < 1.2) return 'Цель достигнута!';
    return 'Превышение нормы';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Сегодня';
    if (dateOnly == yesterday) return 'Вчера';
    
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Карточка прогресса макронутриента
class _MacroProgressCard extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const _MacroProgressCard({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / target).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$current/$target г',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Секция приема пищи
class _MealSection extends StatelessWidget {
  final MealType mealType;
  final List<FoodLog> logs;
  final int totalCalories;
  final VoidCallback onAddFood;
  final Function(FoodLog) onDeleteLog;
  final VoidCallback? onUpdate;

  const _MealSection({
    required this.mealType,
    required this.logs,
    required this.totalCalories,
    required this.onAddFood,
    required this.onDeleteLog,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Text(
              mealType.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              mealType.nameRu,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            trailing: Text(
              '$totalCalories ккал',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextButton.icon(
                onPressed: onAddFood,
                icon: const Icon(Icons.add),
                label: const Text('Добавить продукт'),
              ),
            )
          else
            ...logs.map((log) => _FoodLogTile(
                  log: log,
                  onDelete: () => onDeleteLog(log),
                  onUpdate: onUpdate,
                )),
        ],
      ),
    );
  }
}

/// Плитка записи о еде
class _FoodLogTile extends StatelessWidget {
  final FoodLog log;
  final VoidCallback onDelete;
  final VoidCallback? onUpdate;

  const _FoodLogTile({
    required this.log,
    required this.onDelete,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить продукт?'),
            content: Text('Удалить ${log.foodName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(log.foodName),
        subtitle: Text(
          '${log.grams.round()}г • Б: ${log.protein.round()}г Ж: ${log.fat.round()}г У: ${log.carbs.round()}г',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${log.calories} ккал',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(context, log),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, FoodLog log) {
    final controller = TextEditingController(text: log.grams.round().toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Изменить вес: ${log.foodName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Вес (г)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final newGrams = double.tryParse(controller.text);
              if (newGrams != null && newGrams > 0) {
                // Пересчитать макросы
                final ratio = newGrams / log.grams;
                final updatedLog = FoodLog(
                  id: log.id,
                  userId: log.userId,
                  foodId: log.foodId,
                  foodName: log.foodName,
                  grams: newGrams,
                  calories: (log.calories * ratio).round(),
                  protein: log.protein * ratio,
                  fat: log.fat * ratio,
                  carbs: log.carbs * ratio,
                  mealType: log.mealType,
                  timestamp: log.timestamp,
                );
                
                await DietService.updateFoodLog(updatedLog);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  // Обновить список
                  onUpdate?.call();
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
