import 'package:flutter/material.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';
import 'package:fitmonster/features/diet/data/food_database.dart';
import 'package:fitmonster/core/widgets/custom_text_field.dart';
import 'package:fitmonster/core/widgets/custom_button.dart';
import 'package:fitmonster/core/theme/app_theme.dart';

/// Диалог добавления продукта
class AddFoodDialog extends StatefulWidget {
  final MealType mealType;
  final Function(FoodLog) onAdd;

  const AddFoodDialog({
    super.key,
    required this.mealType,
    required this.onAdd,
  });

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _searchController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  
  List<FoodItem> _searchResults = [];
  FoodItem? _selectedFood;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchResults = FoodDatabase.getPopularFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _searchResults = FoodDatabase.searchFoods(query);
    });
  }

  void _selectFood(FoodItem food) {
    setState(() {
      _selectedFood = food;
    });
  }

  void _addFood() {
    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите продукт')),
      );
      return;
    }

    final grams = double.tryParse(_gramsController.text);
    if (grams == null || grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректный вес')),
      );
      return;
    }

    // Получить текущего пользователя (локальная реализация)
    const userId = 'local_user';

    final log = FoodLog.fromFood(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      food: _selectedFood!,
      grams: grams,
      mealType: widget.mealType,
      timestamp: DateTime.now(),
    );

    widget.onAdd(log);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.mealType.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Добавить в ${widget.mealType.nameRu.toLowerCase()}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Поиск
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomTextField(
                controller: _searchController,
                label: 'Поиск продукта',
                hint: 'Начните вводить название',
                prefixIcon: const Icon(Icons.search),
                onChanged: _search,
              ),
            ),

            // Список продуктов
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _isSearching
                            ? 'Ничего не найдено'
                            : 'Популярные продукты',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final food = _searchResults[index];
                        final isSelected = _selectedFood?.id == food.id;
                        
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryGreen.withOpacity(0.1),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              color: isSelected ? Colors.white : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          title: Text(food.nameRu),
                          subtitle: Text(
                            '${food.calories.round()} ккал • Б: ${food.protein.round()}г Ж: ${food.fat.round()}г У: ${food.carbs.round()}г',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                              : null,
                          onTap: () => _selectFood(food),
                        );
                      },
                    ),
            ),

            // Выбранный продукт и вес
            if (_selectedFood != null) ...[
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Выбрано: ${_selectedFood!.nameRu}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _gramsController,
                            label: 'Вес (граммы)',
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.scale),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _calculateCalories(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                            ),
                            Text(
                              'калорий',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Добавить',
                      onPressed: _addFood,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _calculateCalories() {
    final grams = double.tryParse(_gramsController.text) ?? 100;
    final macros = _selectedFood!.calculateMacros(grams);
    return '${macros.calories}';
  }
}
