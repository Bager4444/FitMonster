import 'package:flutter/material.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/widgets/empty_state.dart';
import 'package:fitmonster/features/diet/presentation/pages/profile_setup_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/food_log_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/diet_dashboard_page.dart';
import 'package:fitmonster/features/diet/domain/services/calorie_calculator.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';

/// Страница диеты и трекера питания
class DietPage extends StatefulWidget {
  const DietPage({super.key, this.isCurrentTab = false});

  final bool isCurrentTab;

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  bool _hasProfile = false;
  Macros? _targetMacros;
  int _profileVersion = 0; // Для принудительного пересоздания виджета
  int _dataKey = 0; // Пересоздание дашборда/дневника при заходе на вкладку или смене аккаунта
  bool _isInitialized = false;
  bool _wasOnDietTab = false;

  @override
  void initState() {
    super.initState();
    _loadProfile(isInitial: true);
  }

  @override
  void didUpdateWidget(covariant DietPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab && !_wasOnDietTab) {
      _wasOnDietTab = true;
      _loadProfile(isInitial: false);
      setState(() => _dataKey++);
    } else if (!widget.isCurrentTab) {
      _wasOnDietTab = false;
    }
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
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 40),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Диета',
                style: TextStyle(
                  color: context.fm.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              automaticallyImplyLeading: false,
              toolbarHeight: kToolbarHeight,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: TabBar(
                  labelColor: context.fm.glowCyan,
                  unselectedLabelColor: context.fm.textSecondary,
                  indicatorColor: context.fm.glowCyan,
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard, size: 20), text: 'Статистика'),
                    Tab(icon: Icon(Icons.restaurant_menu, size: 20), text: 'Дневник'),
                  ],
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              DietDashboardPage(
                key: ValueKey('dash_$_dataKey'),
                targetMacros: _targetMacros,
              ),
              FoodLogPage(
                key: ValueKey('log_$_dataKey'),
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
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Диета',
              style: context.fm.titleStyle.copyWith(fontSize: 24),
            ),
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.restaurant,
              title: 'Журнал питания пуст',
              message: 'Сначала настройте профиль для расчета калорий',
              actionText: 'Настроить профиль',
              actionButtonColor: context.fm.glowCyan,
              actionButtonTextColor: Colors.black,
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
        ],
      ),
    );
  }
}
