import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/features/diet/domain/models/food_item.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';
import 'package:fitmonster/features/diet/domain/models/food_search_result.dart';
import 'package:fitmonster/features/diet/data/services/food_database_service.dart';
import 'package:fitmonster/features/diet/data/services/database_init_service.dart';
import 'package:fitmonster/features/diet/data/repositories/food_repository.dart';
import 'package:fitmonster/features/diet/presentation/pages/food_detail_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/barcode_scanner_page.dart';
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
  final _searchFocusNode = FocusNode();
  final _dbService = FoodDatabaseService(); // Для избранных/недавних
  late final FoodRepository _foodRepo;
  
  List<FoodItem> _searchResults = [];
  List<FoodItem> _favoriteFoods = [];
  List<FoodItem> _recentFoods = [];
  FoodItem? _selectedFood;
  FoodServing? _selectedServing;
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isOffline = false; // Индикатор офлайн-режима
  Timer? _searchDebounce;

  static const String _userId = 'local_user';

  @override
  void initState() {
    super.initState();
    // Автофокус на поле поиска после загрузки с небольшой задержкой
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _searchFocusNode.canRequestFocus) {
          _searchFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Инициализируем FoodRepository через Provider
    _foodRepo = context.read<FoodRepository>();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Проверить количество продуктов в базе
      final foodsCount = _foodRepo.localCount;
      print('📊 Количество продуктов в базе: $foodsCount');
      
      if (foodsCount == 0) {
        // База пуста - попробовать инициализировать
        print('⚠️ База данных пуста, проверяю инициализацию...');
        final initService = DatabaseInitService();
        final isInitialized = await initService.isInitialized();
        print('📋 База инициализирована: $isInitialized');
        
        if (!isInitialized) {
          print('🔄 Запускаю инициализацию базы данных...');
          await initService.initializeDatabase(
            onProgress: (msg) => print('📊 $msg'),
            onError: (err) => print('❌ $err'),
          );
          // Перезагрузить данные после инициализации
          final newCount = _foodRepo.localCount;
          print('✅ После инициализации продуктов: $newCount');
        }
      }
      
      // Загрузить популярные продукты через репозиторий
      final popular = _foodRepo.getPopularFoods(maxResults: 10);
      print('📦 Загружено популярных продуктов: ${popular.length}');
      
      // Загрузить избранные и недавние (через старый сервис - локальные данные)
      final favorites = await _dbService.getFavoriteFoods(_userId);
      final recent = await _dbService.getRecentFoods(_userId, maxResults: 5);
      print('⭐ Избранных: ${favorites.length}, Недавних: ${recent.length}');
      
      // Проверить состояние сети
      final isOffline = _foodRepo.isOffline;

      setState(() {
        _searchResults = popular;
        _favoriteFoods = favorites;
        _recentFoods = recent;
        _isOffline = isOffline;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Ошибка загрузки данных: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  void _search(String query) {
    // Отменить предыдущий таймер
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _isOffline = _foodRepo.isOffline;
        _searchResults = _foodRepo.getPopularFoods(maxResults: 10);
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    // Debounce поиска (500ms)
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Используем гибридный поиск через FoodRepository
        final result = await _foodRepo.searchFoods(query: query);

        if (mounted) {
          setState(() {
            _searchResults = result.items;
            _isOffline = result.isOffline;
            _isLoading = false;
          });
          
          // Показать уведомление об ошибке API (если есть)
          if (result.hasError) {
            print('⚠️ Ошибка API: ${result.error}');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка поиска: $e')),
          );
        }
      }
    });
  }

  void _selectFood(FoodItem food) async {
    setState(() {
      _selectedFood = food;
      _selectedServing = null;
      // Установить вес по умолчанию
      if (food.servings.isNotEmpty) {
        _gramsController.text = food.servings.first.grams.toStringAsFixed(0);
      } else {
        _gramsController.text = '100';
      }
    });
    
    // Добавить в недавние
    await _dbService.addToRecent(_userId, food.id);
    
    // Обновить список недавних
    final recent = await _dbService.getRecentFoods(_userId, maxResults: 5);
    setState(() {
      _recentFoods = recent;
    });
  }

  void _selectServing(FoodServing serving) {
    setState(() {
      _selectedServing = serving;
      _gramsController.text = serving.grams.toStringAsFixed(0);
    });
  }

  void _openFoodDetails() {
    if (_selectedFood != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodDetailPage(
            foodId: _selectedFood!.id,
            food: _selectedFood,
          ),
        ),
      ).then((result) {
        // Если продукт был выбран из деталей, обновить состояние
        if (result is FoodItem) {
          _selectFood(result);
        }
      });
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerPage(),
      ),
    );

    // Если продукт был найден и выбран, добавить его
    if (result is FoodItem && mounted) {
      _selectFood(result);
    }
  }

  Future<void> _toggleFavorite(FoodItem food) async {
    final isFavorite = await _dbService.isFavorite(_userId, food.id);
    
    if (isFavorite) {
      await _dbService.removeFromFavorites(_userId, food.id);
    } else {
      await _dbService.addToFavorites(_userId, food.id);
    }
    
    // Обновить список избранных
    final favorites = await _dbService.getFavoriteFoods(_userId);
    setState(() {
      _favoriteFoods = favorites;
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

            // Индикатор офлайн-режима
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange[100],
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 16, color: Colors.orange[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Офлайн-режим. Показаны только сохранённые продукты.',
                        style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),

            // Поиск
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Поиск продукта',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    enabled: true,
                    textInputAction: TextInputAction.search,
                    textCapitalization: TextCapitalization.none,
                    enableSuggestions: true,
                    autocorrect: false,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Начните вводить название',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _search('');
                                    _searchFocusNode.requestFocus();
                                  },
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      print('🔍 Ввод текста: "$value" (длина: ${value.length})');
                      _search(value);
                    },
                    onTap: () {
                      // Убедиться, что поле получает фокус при нажатии
                      print('👆 Нажатие на поле поиска');
                      if (_searchFocusNode.canRequestFocus) {
                        _searchFocusNode.requestFocus();
                        print('✅ Фокус запрошен');
                      } else {
                        print('⚠️ Не могу запросить фокус');
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Сканировать штрих-код'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),

            // Список продуктов
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildFoodList(),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Выбрано: ${_selectedFood!.nameRu}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: _openFoodDetails,
                          tooltip: 'Детали продукта',
                        ),
                      ],
                    ),
                    // Предупреждение об аллергенах
                    if (_selectedFood!.allergens.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, size: 20, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Содержит: ${_selectedFood!.allergens.join(", ")}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange[900],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Выбор порции
                    if (_selectedFood!.servings.isNotEmpty) ...[
                      Text(
                        'Выберите порцию:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedFood!.servings.map((serving) {
                          final isSelected = _selectedServing?.name == serving.name;
                          return ChoiceChip(
                            label: Text('${serving.nameRu} (${serving.grams.round()}г)'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) _selectServing(serving);
                            },
                            selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                            checkmarkColor: AppTheme.primaryGreen,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _gramsController,
                            label: 'Вес (граммы)',
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.scale),
                            onChanged: (value) {
                              setState(() {
                                _selectedServing = null; // Сбросить выбор порции при ручном вводе
                              });
                            },
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

  Widget _buildFoodList() {
    if (!_isSearching && _searchController.text.isEmpty) {
      // Проверить, есть ли продукты вообще
      if (_searchResults.isEmpty && _favoriteFoods.isEmpty && _recentFoods.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'База данных продуктов пуста',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Идет инициализация базы данных...\nПопробуйте обновить через несколько секунд',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadInitialData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),
        );
      }
      
      // Показать избранные, недавние и популярные
      return ListView(
        children: [
          if (_favoriteFoods.isNotEmpty) ...[
            _buildSectionHeader('⭐ Избранное'),
            ..._favoriteFoods.map((food) => _buildFoodTile(food)),
            const Divider(height: 1),
          ],
          if (_recentFoods.isNotEmpty) ...[
            _buildSectionHeader('🕐 Недавние'),
            ..._recentFoods.map((food) => _buildFoodTile(food)),
            const Divider(height: 1),
          ],
          if (_searchResults.isNotEmpty) ...[
            _buildSectionHeader('🔥 Популярные'),
            ..._searchResults.map((food) => _buildFoodTile(food)),
          ],
        ],
      );
    }

    // Результаты поиска
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте другой запрос',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildFoodTile(_searchResults[index]),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
      ),
    );
  }

  Widget _buildFoodTile(FoodItem food) {
    final isSelected = _selectedFood?.id == food.id;
    
    return FutureBuilder<bool>(
      future: _dbService.isFavorite(_userId, food.id),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        
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
          title: Text(
            food.nameRu,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Бренд (если есть)
              if (food.brand != null && food.brand!.isNotEmpty)
                Text(
                  food.brand!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              // Нутриенты
              Text(
                '${food.calories.round()} ккал • Б: ${food.protein.toStringAsFixed(1)}г Ж: ${food.fat.toStringAsFixed(1)}г У: ${food.carbs.toStringAsFixed(1)}г',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          isThreeLine: food.brand != null && food.brand!.isNotEmpty,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.grey,
                ),
                onPressed: () => _toggleFavorite(food),
                tooltip: isFavorite ? 'Удалить из избранного' : 'Добавить в избранное',
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
            ],
          ),
          onTap: () => _selectFood(food),
        );
      },
    );
  }
}
