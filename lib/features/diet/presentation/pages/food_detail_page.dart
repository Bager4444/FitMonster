import 'package:flutter/material.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/data/services/food_database_service.dart';
import 'package:fitmonster/core/theme/app_theme.dart';

/// Страница деталей продукта
class FoodDetailPage extends StatefulWidget {
  final String foodId;
  final FoodItem? food;

  const FoodDetailPage({
    super.key,
    required this.foodId,
    this.food,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  final _dbService = FoodDatabaseService();
  FoodItem? _food;
  bool _isLoading = true;
  bool _isFavorite = false;

  static const String _userId = 'local_user';

  @override
  void initState() {
    super.initState();
    _loadFoodDetails();
  }

  Future<void> _loadFoodDetails() async {
    try {
      FoodItem? food = widget.food;
      
      if (food == null) {
        food = await _dbService.getFoodDetails(widget.foodId);
      }

      if (food != null) {
        final favorite = await _dbService.isFavorite(_userId, food.id);
        setState(() {
          _food = food;
          _isFavorite = favorite;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Продукт не найден')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_food == null) return;

    if (_isFavorite) {
      await _dbService.removeFromFavorites(_userId, _food!.id);
    } else {
      await _dbService.addToFavorites(_userId, _food!.id);
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Детали продукта')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_food == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Детали продукта')),
        body: const Center(child: Text('Продукт не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_food!.nameRu),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            color: _isFavorite ? Colors.amber : null,
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Удалить из избранного' : 'Добавить в избранное',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.1),
                    AppTheme.primaryGreen.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _food!.nameRu,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_food!.name != _food!.nameRu) ...[
                    const SizedBox(height: 4),
                    Text(
                      _food!.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildMacrosRow(),
                ],
              ),
            ),

            // Категория
            if (_food!.category != FoodCategory.other) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.category, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Категория: ${_food!.category.nameRu}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // Порции
            if (_food!.servings.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Доступные порции',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ..._food!.servings.map((serving) => _buildServingTile(serving)),
              const Divider(height: 1),
            ],

            // Аллергены
            if (_food!.allergens.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, size: 20, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Аллергены',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _food!.allergens.map((allergen) {
                        return Chip(
                          label: Text(allergen),
                          backgroundColor: Colors.orange[50],
                          side: BorderSide(color: Colors.orange[200]!),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // Вегетарианство/Веганство
            if (_food!.isVegetarian || _food!.isVegan) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_food!.isVegan)
                      Chip(
                        label: const Text('🌱 Веган'),
                        backgroundColor: Colors.green[50],
                        side: BorderSide(color: Colors.green[200]!),
                      ),
                    if (_food!.isVegan && _food!.isVegetarian)
                      const SizedBox(width: 8),
                    if (_food!.isVegetarian)
                      Chip(
                        label: const Text('🥗 Вегетарианское'),
                        backgroundColor: Colors.green[50],
                        side: BorderSide(color: Colors.green[200]!),
                      ),
                  ],
                ),
              ),
            ],

            // Штрих-код
            if (_food!.barcode != null && _food!.barcode!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.qr_code, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Штрих-код: ${_food!.barcode}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMacrosRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMacroItem(
          'Калории',
          '${_food!.calories.round()}',
          'ккал',
          AppTheme.primaryGreen,
        ),
        _buildMacroItem(
          'Белки',
          '${_food!.protein.toStringAsFixed(1)}',
          'г',
          Colors.blue,
        ),
        _buildMacroItem(
          'Жиры',
          '${_food!.fat.toStringAsFixed(1)}',
          'г',
          Colors.orange,
        ),
        _buildMacroItem(
          'Углеводы',
          '${_food!.carbs.toStringAsFixed(1)}',
          'г',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildServingTile(FoodServing serving) {
    // Рассчитать макросы для этой порции
    final ratio = serving.grams / 100.0; // Базовые значения на 100г
    final calories = (_food!.calories * ratio).round();
    final protein = _food!.protein * ratio;
    final fat = _food!.fat * ratio;
    final carbs = _food!.carbs * ratio;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.restaurant,
          color: AppTheme.primaryGreen,
          size: 20,
        ),
      ),
      title: Text(serving.nameRu),
      subtitle: Text(
        '${serving.quantity ?? 1} ${serving.nameRu} (${serving.grams.round()}г)',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$calories ккал',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
          ),
          Text(
            'Б: ${protein.toStringAsFixed(1)}г Ж: ${fat.toStringAsFixed(1)}г У: ${carbs.toStringAsFixed(1)}г',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
