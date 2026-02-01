import 'package:flutter/material.dart';
import 'package:fitmonster/features/diet/data/services/food_database_service.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';

class FoodSearchPage extends StatefulWidget {
  const FoodSearchPage({super.key});

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FoodDatabaseService _foodService = FoodDatabaseService();
  List<FoodItem> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialFoods();
  }

  Future<void> _loadInitialFoods() async {
    setState(() => _isLoading = true);
    try {
      final foods = await _foodService.searchFoods('');
      setState(() {
        _searchResults = foods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _searchFoods(String query) async {
    setState(() => _isLoading = true);
    try {
      final foods = await _foodService.searchFoods(query);
      setState(() {
        _searchResults = foods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка поиска: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск продуктов'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Введите название продукта...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.length > 2 || value.isEmpty) {
                  _searchFoods(value);
                }
              },
            ),
          ),
          
          // Результаты
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'Продукты не найдены',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final food = _searchResults[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              title: Text(food.name),
                              subtitle: Text(
                                '${food.calories.toInt()} ккал/100г • '
                                'Б: ${food.protein.toInt()}г • '
                                'Ж: ${food.fat.toInt()}г • '
                                'У: ${food.carbs.toInt()}г',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.favorite_border),
                                onPressed: () async {
                                  await _foodService.addToFavorites(food.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Добавлено в избранное'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              onTap: () {
                                // Показать детали продукта
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(food.name),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Калории: ${food.calories.toInt()} ккал/100г'),
                                        Text('Белки: ${food.protein.toInt()}г'),
                                        Text('Жиры: ${food.fat.toInt()}г'),
                                        Text('Углеводы: ${food.carbs.toInt()}г'),
                                        if (food.fiber > 0)
                                          Text('Клетчатка: ${food.fiber.toInt()}г'),
                                        if (food.brand != null)
                                          Text('Бренд: ${food.brand}'),
                                        if (food.category != null)
                                          Text('Категория: ${food.category}'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Закрыть'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}