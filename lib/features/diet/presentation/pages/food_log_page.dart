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
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
    _loadLogs();
  }

  DailySummary get _summary => DailySummary.fromLogs(_selectedDate, _logs);

  Future<void> _loadLogs() async {
    final logs = await DietService.getFoodLogsForDate(_selectedDate);
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      await _loadLogs();
    }
  }

  void _navigateDate(int days) {
    final newDate = _selectedDate.add(Duration(days: days));
    if (newDate.isAfter(DateTime.now().add(const Duration(days: 365)))) return;
    
    setState(() {
      _selectedDate = newDate;
      _isLoading = true;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _navigateDate(-1),
              tooltip: 'Предыдущий день',
            ),
            Text(_formatDate(_selectedDate)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _selectedDate.isBefore(DateTime.now().add(const Duration(days: 364)))
                  ? () => _navigateDate(1)
                  : null,
              tooltip: 'Следующий день',
            ),
          ],
        ),
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
            onPressed: () => _selectDate(),
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
          
          // Список приемов пищи (всегда показываем все приёмы)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMealsList(),
          ),
        ],
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${_summary.totalCalories} / ${widget.targetMacros.calories}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(progress),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressClamped,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _MacroProgressCard(
              label: 'Белки',
              current: _summary.totalProtein.round(),
              target: widget.targetMacros.protein,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MacroProgressCard(
              label: 'Жиры',
              current: _summary.totalFat.round(),
              target: widget.targetMacros.fat,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MacroProgressCard(
              label: 'Углеводы',
              current: _summary.totalCarbs.round(),
              target: widget.targetMacros.carbs,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    return ListView(
      children: [
        ...MealType.values.map((mealType) {
          final mealLogs = _summary.getLogsByMealType(mealType);
          final mealCalories = _summary.getCaloriesByMealType(mealType);
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              leading: Text(
                mealType.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(
                mealType.nameRu,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('$mealCalories ккал'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddFoodDialog(mealType: mealType),
              ),
              children: mealLogs.map((log) => _buildFoodLogTile(log)).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFoodLogTile(FoodLog log) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppTheme.primaryGreen,
        child: Icon(Icons.restaurant, color: Colors.white),
      ),
      title: Text(log.foodName),
      subtitle: Text(
        '${log.grams.toStringAsFixed(0)}г • ${log.calories} ккал',
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Удалить'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'delete') {
            _deleteLog(log);
          }
        },
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
    final progress = current / target;
    final progressClamped = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  '$current / $target г',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontSize: 10,
                      ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progressClamped,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ),
    );
  }
}