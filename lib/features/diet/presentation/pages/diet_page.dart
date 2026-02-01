import 'package:flutter/material.dart';
import 'package:fitmonster/core/widgets/empty_state.dart';
import 'package:fitmonster/features/diet/presentation/pages/profile_setup_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/food_log_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/diet_dashboard_page.dart';
import 'package:fitmonster/features/diet/domain/services/calorie_calculator.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';

/// Страница диеты и трекера питания
class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  bool _hasProfile = false;
  Macros? _targetMacros;
  int _profileVersion = 0; // Для принудительного пересоздания виджета
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadProfile(isInitial: true);
  }

  Future<void> _loadProfile({bool isInitial = false}) async {
    try {
      final profile = await DietService.getUserProfile();
      
      if (profile != null) {
        final macros = CalorieCalculator.calculateMacros(profile);
        final oldMacros = _targetMacros;
        
        setState(() {
          _hasProfile = true;
          _targetMacros = macros;
          
          // Увеличиваем версию только если профиль изменился (не при первой загрузке)
          if (!isInitial && _isInitialized && oldMacros != null) {
            if (oldMacros.calories != macros.calories ||
                oldMacros.protein != macros.protein ||
                oldMacros.fat != macros.fat ||
                oldMacros.carbs != macros.carbs) {
              _profileVersion++;
            }
          }
          _isInitialized = true;
        });
        
        print('Profile loaded successfully: ${profile.age} лет, ${profile.weight} кг');
        print('Target macros: ${macros.calories} ккал, ${macros.protein}г белка');
      } else {
        print('Profile not found, showing setup page');
        setState(() {
          _hasProfile = false;
          _targetMacros = null;
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Если Hive не инициализирован (например, в тестах), просто показываем пустое состояние
      setState(() {
        _hasProfile = false;
        _targetMacros = null;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasProfile && _targetMacros != null) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 40), // Уменьшена высота TabBar
            child: AppBar(
              title: const Text('Диета'),
              automaticallyImplyLeading: false, // Убрать кнопку назад
              toolbarHeight: kToolbarHeight, // Стандартная высота AppBar
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(40), // Уменьшена высота TabBar
                child: TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.dashboard, size: 20), text: 'Статистика'),
                    Tab(icon: Icon(Icons.restaurant_menu, size: 20), text: 'Дневник'),
                  ],
                  labelStyle: TextStyle(fontSize: 12),
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              const DietDashboardPage(),
              FoodLogPage(
                key: ValueKey(_profileVersion),
                date: DateTime.now(),
                targetMacros: _targetMacros!,
                onProfileUpdated: _loadProfile,
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // AppBar содержимое
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Диета',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: 'Настроить профиль',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileSetupPage(),
                      ),
                    );
                    _loadProfile();
                  },
                ),
              ],
            ),
          ),
          
          // Основное содержимое
          Expanded(
            child: EmptyState(
              icon: Icons.restaurant,
              title: 'Журнал питания пуст',
              message: 'Сначала настройте профиль для расчета калорий',
              actionText: 'Настроить профиль',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSetupPage(),
                  ),
                );
                _loadProfile();
              },
            ),
          ),
          
          // FloatingActionButton содержимое
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSetupPage(),
                  ),
                );
                _loadProfile();
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Рассчитать калории'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
