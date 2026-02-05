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
import 'package:fitmonster/core/widgets/custom_text_field.dart';
import 'package:fitmonster/core/widgets/custom_button.dart';
import 'package:fitmonster/core/theme/app_theme.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';

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

  String get _userId => DietService.currentUserId;

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

    final userId = _userId;
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
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          gradient: GlassTheme.scaffoldGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
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
                      style: GlassTheme.titleStyle.copyWith(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: GlassTheme.textPrimary),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GlassTheme.glowCyan.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 16, color: GlassTheme.glowCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Офлайн-режим. Показаны только сохранённые продукты.',
                        style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
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
                    style: GlassTheme.titleStyle.copyWith(fontSize: 16),
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
                    style: const TextStyle(fontSize: 16, color: GlassTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Начните вводить название',
                      hintStyle: GlassTheme.bodyStyle,
                      prefixIcon: const Icon(Icons.search, color: GlassTheme.glowCyan),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: GlassTheme.glowCyan),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: GlassTheme.textPrimary),
                                  onPressed: () {
                                    _searchController.clear();
                                    _search('');
                                    _searchFocusNode.requestFocus();
                                  },
                                )
                              : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: GlassTheme.glowCyan, width: 2),
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
                      if (_searchFocusNode.canRequestFocus) {
                        _searchFocusNode.requestFocus();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Список продуктов
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: GlassTheme.glowCyan))
                  : _buildFoodList(),
            ),

            // Выбранный продукт и вес
            if (_selectedFood != null) ...[
              Divider(height: 1, color: Colors.white.withOpacity(0.2)),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Выбрано: ${_selectedFood!.nameRu}',
                            style: GlassTheme.titleStyle.copyWith(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: GlassTheme.glowCyan),
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
                          color: GlassTheme.glowCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: GlassTheme.glowCyan.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, size: 20, color: GlassTheme.glowCyan),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Содержит: ${_selectedFood!.allergens.join(", ")}',
                                style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
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
                        style: GlassTheme.bodyStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedFood!.servings.map((serving) {
                          final isSelected = _selectedServing?.name == serving.name;
                          return ChoiceChip(
                            label: Text(
                              '${serving.nameRu} (${serving.grams.round()}г)',
                              style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) _selectServing(serving);
                            },
                            selectedColor: GlassTheme.glowCyan.withOpacity(0.3),
                            checkmarkColor: GlassTheme.textPrimary,
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
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
                            prefixIcon: const Icon(Icons.scale, color: GlassTheme.glowCyan),
                            onChanged: (value) {
                              setState(() {
                                _selectedServing = null;
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
                              style: GlassTheme.titleStyle.copyWith(
                                fontSize: 20,
                                color: GlassTheme.glowCyan,
                              ),
                            ),
                            Text(
                              'калорий',
                              style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Добавить',
                      onPressed: _addFood,
                      backgroundColor: GlassTheme.gradientTop,
                      textColor: Colors.white,
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
                Icon(Icons.restaurant_menu, size: 64, color: GlassTheme.glowCyan.withOpacity(0.7)),
                const SizedBox(height: 16),
                Text(
                  'База данных продуктов пуста',
                  style: GlassTheme.titleStyle.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Идет инициализация базы данных...\nПопробуйте обновить через несколько секунд',
                  textAlign: TextAlign.center,
                  style: GlassTheme.bodyStyle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadInitialData,
                  icon: const Icon(Icons.refresh, color: GlassTheme.textPrimary),
                  label: Text('Обновить', style: GlassTheme.titleStyle.copyWith(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.gradientTop,
                    foregroundColor: Colors.white,
                  ),
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
            Icon(Icons.search_off, size: 64, color: GlassTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: GlassTheme.titleStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте другой запрос',
              style: GlassTheme.bodyStyle,
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
        style: GlassTheme.titleStyle.copyWith(
          fontSize: 14,
          color: GlassTheme.glowCyan,
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
          selectedTileColor: GlassTheme.glowCyan.withOpacity(0.15),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? GlassTheme.glowCyan
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? GlassTheme.glowCyan : Colors.white24,
              ),
            ),
            child: Icon(
              Icons.restaurant,
              color: isSelected ? GlassTheme.gradientBottom : GlassTheme.textSecondary,
              size: 20,
            ),
          ),
          title: Text(
            food.nameRu,
            style: GlassTheme.titleStyle.copyWith(fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (food.brand != null && food.brand!.isNotEmpty)
                Text(
                  food.brand!,
                  style: GlassTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                '${food.calories.round()} ккал • Б: ${food.protein.toStringAsFixed(1)}г Ж: ${food.fat.toStringAsFixed(1)}г У: ${food.carbs.toStringAsFixed(1)}г',
                style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
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
                  color: isFavorite ? GlassTheme.glowCyan : GlassTheme.textSecondary,
                ),
                onPressed: () => _toggleFavorite(food),
                tooltip: isFavorite ? 'Удалить из избранного' : 'Добавить в избранное',
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: GlassTheme.glowCyan),
            ],
          ),
          onTap: () => _selectFood(food),
        );
      },
    );
  }
}
