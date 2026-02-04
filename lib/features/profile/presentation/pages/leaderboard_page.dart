import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitmonster/core/theme/theme_provider.dart';

/// Страница таблицы лидеров
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Текущий регион пользователя (определяется по местоположению)
  String _currentRegion = 'Россия';
  
  // Список всех регионов
  final List<Map<String, String>> _regions = [
    {'name': 'Россия', 'flag': '🇷🇺'},
    {'name': 'Европа', 'flag': '🇪🇺'},
    {'name': 'Северная Америка', 'flag': '🇺🇸'},
    {'name': 'Южная Америка', 'flag': '🇧🇷'},
    {'name': 'Азия', 'flag': '🇯🇵'},
    {'name': 'Китай', 'flag': '🇨🇳'},
    {'name': 'Африка', 'flag': '🌍'},
  ];
  
  // Данные лидеров по регионам
  final Map<String, List<Map<String, dynamic>>> _regionalLeaders = {
    'Россия': [
      {'rank': 1, 'name': 'Александр К.', 'score': 2450, 'streak': 45, 'city': 'Москва', 'avatar': '👑'},
      {'rank': 2, 'name': 'Мария С.', 'score': 2380, 'streak': 38, 'city': 'СПб', 'avatar': '🥈'},
      {'rank': 3, 'name': 'Дмитрий В.', 'score': 2290, 'streak': 42, 'city': 'Казань', 'avatar': '🥉'},
      {'rank': 4, 'name': 'Анна Л.', 'score': 2150, 'streak': 35, 'city': 'Екатеринбург', 'avatar': '💪'},
      {'rank': 5, 'name': 'Сергей М.', 'score': 2080, 'streak': 28, 'city': 'Н.Новгород', 'avatar': '🔥'},
      {'rank': 6, 'name': 'Елена Р.', 'score': 1950, 'streak': 31, 'city': 'Ростов', 'avatar': '⭐'},
      {'rank': 7, 'name': 'Игорь П.', 'score': 1890, 'streak': 25, 'city': 'Уфа', 'avatar': '🚀'},
      {'rank': 8, 'name': 'Ольга Н.', 'score': 1820, 'streak': 29, 'city': 'Самара', 'avatar': '💯'},
      {'rank': 9, 'name': 'Пользователь', 'score': 1750, 'streak': 7, 'city': 'Москва', 'avatar': '🎯', 'isCurrentUser': true},
      {'rank': 10, 'name': 'Андрей К.', 'score': 1680, 'streak': 22, 'city': 'Воронеж', 'avatar': '⚡'},
    ],
    
    'Европа': [
      {'rank': 1, 'name': 'Emma S.', 'score': 2890, 'streak': 67, 'city': 'London', 'avatar': '👑'},
      {'rank': 2, 'name': 'Marie L.', 'score': 2780, 'streak': 58, 'city': 'Paris', 'avatar': '🥈'},
      {'rank': 3, 'name': 'Anna M.', 'score': 2650, 'streak': 61, 'city': 'Berlin', 'avatar': '🥉'},
      {'rank': 4, 'name': 'Sofia K.', 'score': 2480, 'streak': 52, 'city': 'Rome', 'avatar': '💪'},
      {'rank': 5, 'name': 'Lars N.', 'score': 2350, 'streak': 48, 'city': 'Stockholm', 'avatar': '🔥'},
      {'rank': 6, 'name': 'Pedro G.', 'score': 2280, 'streak': 44, 'city': 'Madrid', 'avatar': '⭐'},
      {'rank': 7, 'name': 'Katja H.', 'score': 2150, 'streak': 39, 'city': 'Vienna', 'avatar': '🚀'},
      {'rank': 8, 'name': 'Marco R.', 'score': 2080, 'streak': 41, 'city': 'Milan', 'avatar': '💯'},
    ],
    
    'Северная Америка': [
      {'rank': 1, 'name': 'John D.', 'score': 3250, 'streak': 78, 'city': 'New York', 'avatar': '👑'},
      {'rank': 2, 'name': 'Sarah M.', 'score': 3180, 'streak': 72, 'city': 'Los Angeles', 'avatar': '🥈'},
      {'rank': 3, 'name': 'Mike J.', 'score': 3050, 'streak': 69, 'city': 'Chicago', 'avatar': '🥉'},
      {'rank': 4, 'name': 'Emily R.', 'score': 2920, 'streak': 64, 'city': 'Toronto', 'avatar': '💪'},
      {'rank': 5, 'name': 'David L.', 'score': 2850, 'streak': 58, 'city': 'Miami', 'avatar': '🔥'},
      {'rank': 6, 'name': 'Jessica W.', 'score': 2780, 'streak': 55, 'city': 'Vancouver', 'avatar': '⭐'},
      {'rank': 7, 'name': 'Ryan B.', 'score': 2650, 'streak': 51, 'city': 'Seattle', 'avatar': '🚀'},
      {'rank': 8, 'name': 'Amanda K.', 'score': 2580, 'streak': 47, 'city': 'Boston', 'avatar': '💯'},
    ],
    
    'Южная Америка': [
      {'rank': 1, 'name': 'Carlos R.', 'score': 2680, 'streak': 56, 'city': 'São Paulo', 'avatar': '👑'},
      {'rank': 2, 'name': 'Isabella M.', 'score': 2590, 'streak': 52, 'city': 'Buenos Aires', 'avatar': '🥈'},
      {'rank': 3, 'name': 'Diego F.', 'score': 2480, 'streak': 48, 'city': 'Rio de Janeiro', 'avatar': '🥉'},
      {'rank': 4, 'name': 'Camila S.', 'score': 2350, 'streak': 44, 'city': 'Santiago', 'avatar': '💪'},
      {'rank': 5, 'name': 'Mateo L.', 'score': 2280, 'streak': 41, 'city': 'Lima', 'avatar': '🔥'},
      {'rank': 6, 'name': 'Valentina G.', 'score': 2150, 'streak': 38, 'city': 'Bogotá', 'avatar': '⭐'},
      {'rank': 7, 'name': 'Lucas P.', 'score': 2080, 'streak': 35, 'city': 'Montevideo', 'avatar': '🚀'},
      {'rank': 8, 'name': 'Sofia C.', 'score': 1950, 'streak': 32, 'city': 'Caracas', 'avatar': '💯'},
    ],
    
    'Азия': [
      {'rank': 1, 'name': 'Hiroshi T.', 'score': 3150, 'streak': 74, 'city': 'Tokyo', 'avatar': '👑'},
      {'rank': 2, 'name': 'Priya S.', 'score': 3080, 'streak': 68, 'city': 'Mumbai', 'avatar': '🥈'},
      {'rank': 3, 'name': 'Kim J.', 'score': 2950, 'streak': 65, 'city': 'Seoul', 'avatar': '🥉'},
      {'rank': 4, 'name': 'Arjun P.', 'score': 2820, 'streak': 59, 'city': 'Delhi', 'avatar': '💪'},
      {'rank': 5, 'name': 'Yuki M.', 'score': 2750, 'streak': 56, 'city': 'Osaka', 'avatar': '🔥'},
      {'rank': 6, 'name': 'Ravi K.', 'score': 2680, 'streak': 52, 'city': 'Bangalore', 'avatar': '⭐'},
      {'rank': 7, 'name': 'Lee H.', 'score': 2580, 'streak': 48, 'city': 'Busan', 'avatar': '🚀'},
      {'rank': 8, 'name': 'Sakura N.', 'score': 2450, 'streak': 45, 'city': 'Kyoto', 'avatar': '💯'},
    ],
    
    'Китай': [
      {'rank': 1, 'name': 'Li Wei', 'score': 3380, 'streak': 82, 'city': 'Beijing', 'avatar': '👑'},
      {'rank': 2, 'name': 'Zhang Min', 'score': 3290, 'streak': 76, 'city': 'Shanghai', 'avatar': '🥈'},
      {'rank': 3, 'name': 'Wang Lei', 'score': 3150, 'streak': 71, 'city': 'Guangzhou', 'avatar': '🥉'},
      {'rank': 4, 'name': 'Liu Mei', 'score': 3050, 'streak': 67, 'city': 'Shenzhen', 'avatar': '💪'},
      {'rank': 5, 'name': 'Chen Hao', 'score': 2920, 'streak': 62, 'city': 'Chengdu', 'avatar': '🔥'},
      {'rank': 6, 'name': 'Yang Xin', 'score': 2850, 'streak': 58, 'city': 'Hangzhou', 'avatar': '⭐'},
      {'rank': 7, 'name': 'Zhou Yu', 'score': 2780, 'streak': 54, 'city': 'Nanjing', 'avatar': '🚀'},
      {'rank': 8, 'name': 'Wu Jing', 'score': 2650, 'streak': 49, 'city': 'Wuhan', 'avatar': '💯'},
    ],
    
    'Африка': [
      {'rank': 1, 'name': 'Amara K.', 'score': 2580, 'streak': 49, 'city': 'Lagos', 'avatar': '👑'},
      {'rank': 2, 'name': 'Kwame A.', 'score': 2480, 'streak': 45, 'city': 'Accra', 'avatar': '🥈'},
      {'rank': 3, 'name': 'Fatima M.', 'score': 2350, 'streak': 41, 'city': 'Cairo', 'avatar': '🥉'},
      {'rank': 4, 'name': 'Thabo S.', 'score': 2280, 'streak': 38, 'city': 'Cape Town', 'avatar': '💪'},
      {'rank': 5, 'name': 'Aisha N.', 'score': 2150, 'streak': 35, 'city': 'Nairobi', 'avatar': '🔥'},
      {'rank': 6, 'name': 'Omar B.', 'score': 2080, 'streak': 32, 'city': 'Casablanca', 'avatar': '⭐'},
      {'rank': 7, 'name': 'Zara H.', 'score': 1950, 'streak': 29, 'city': 'Johannesburg', 'avatar': '🚀'},
      {'rank': 8, 'name': 'Kofi D.', 'score': 1880, 'streak': 26, 'city': 'Addis Ababa', 'avatar': '💯'},
    ],
  };
  
  // Данные лидеров по миру (топ игроки из всех регионов)
  final List<Map<String, dynamic>> _globalLeaders = [
    {'rank': 1, 'name': 'Li Wei', 'score': 3380, 'streak': 82, 'city': 'Beijing', 'avatar': '👑', 'region': 'Китай'},
    {'rank': 2, 'name': 'Zhang Min', 'score': 3290, 'streak': 76, 'city': 'Shanghai', 'avatar': '🥈', 'region': 'Китай'},
    {'rank': 3, 'name': 'John D.', 'score': 3250, 'streak': 78, 'city': 'New York', 'avatar': '🥉', 'region': 'С. Америка'},
    {'rank': 4, 'name': 'Sarah M.', 'score': 3180, 'streak': 72, 'city': 'Los Angeles', 'avatar': '💪', 'region': 'С. Америка'},
    {'rank': 5, 'name': 'Wang Lei', 'score': 3150, 'streak': 71, 'city': 'Guangzhou', 'avatar': '🔥', 'region': 'Китай'},
    {'rank': 6, 'name': 'Hiroshi T.', 'score': 3150, 'streak': 74, 'city': 'Tokyo', 'avatar': '⭐', 'region': 'Азия'},
    {'rank': 7, 'name': 'Priya S.', 'score': 3080, 'streak': 68, 'city': 'Mumbai', 'avatar': '🚀', 'region': 'Азия'},
    {'rank': 8, 'name': 'Liu Mei', 'score': 3050, 'streak': 67, 'city': 'Shenzhen', 'avatar': '💯', 'region': 'Китай'},
    {'rank': 9, 'name': 'Mike J.', 'score': 3050, 'streak': 69, 'city': 'Chicago', 'avatar': '🎖️', 'region': 'С. Америка'},
    {'rank': 10, 'name': 'Kim J.', 'score': 2950, 'streak': 65, 'city': 'Seoul', 'avatar': '🌟', 'region': 'Азия'},
    {'rank': 156, 'name': 'Пользователь', 'score': 1750, 'streak': 7, 'city': 'Moscow', 'avatar': '🎯', 'isCurrentUser': true, 'region': 'Россия'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _detectUserRegion(); // Определяем регион пользователя
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Имитация определения региона по местоположению
  void _detectUserRegion() {
    // В реальном приложении здесь будет определение по GPS/IP
    // Пока оставляем Россию как пример
    setState(() {
      _currentRegion = 'Россия';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.currentGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(themeProvider),
                  
                  // Region selector
                  _buildRegionSelector(themeProvider),
                  
                  // Tabs
                  _buildTabs(themeProvider),
                  
                  const SizedBox(height: 16),
                  
                  // Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLeaderboardList(_regionalLeaders[_currentRegion] ?? [], themeProvider),
                        _buildLeaderboardList(_globalLeaders, themeProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: themeProvider.textColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Таблица лидеров',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
                Text(
                  'Соревнуйтесь с лучшими!',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🏆',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSelector(ThemeProvider themeProvider) {
    final currentRegionData = _regions.firstWhere((r) => r['name'] == _currentRegion);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Text(
            'Ваш регион:',
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.secondaryTextColor,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showRegionSelector(themeProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: themeProvider.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeProvider.cardBorderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentRegionData['flag']!,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentRegion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: themeProvider.textColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegionSelector(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: themeProvider.currentGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Выберите регион',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ),
            ..._regions.map((region) {
              final isSelected = region['name'] == _currentRegion;
              return ListTile(
                leading: Text(
                  region['flag']!,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  region['name']!,
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: themeProvider.buttonColor)
                    : null,
                onTap: () {
                  setState(() {
                    _currentRegion = region['name']!;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(ThemeProvider themeProvider) {
    final currentRegionData = _regions.firstWhere((r) => r['name'] == _currentRegion);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: themeProvider.buttonColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: themeProvider.textColor,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(currentRegionData['flag']!),
                const SizedBox(width: 8),
                Text(_currentRegion),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🌍'),
                SizedBox(width: 8),
                Text('Мир'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<Map<String, dynamic>> leaders, ThemeProvider themeProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: leaders.length,
      itemBuilder: (context, index) {
        final leader = leaders[index];
        final isCurrentUser = leader['isCurrentUser'] == true;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isCurrentUser
                ? LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.3),
                      Colors.purple.withValues(alpha: 0.3),
                    ],
                  )
                : null,
            color: isCurrentUser ? null : themeProvider.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isCurrentUser
                ? Border.all(color: Colors.blue, width: 2)
                : Border.all(color: themeProvider.cardBorderColor),
            boxShadow: isCurrentUser
                ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRankColor(leader['rank']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${leader['rank']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    leader['avatar'],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          leader['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser ? Colors.white : themeProvider.textColor,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ВЫ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      leader['city'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isCurrentUser 
                            ? Colors.white70 
                            : themeProvider.secondaryTextColor,
                      ),
                    ),
                    if (leader['region'] != null) ...[
                      Text(
                        leader['region'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurrentUser 
                              ? Colors.white60 
                              : themeProvider.secondaryTextColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '${leader['score']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? Colors.white : themeProvider.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${leader['streak']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isCurrentUser 
                              ? Colors.white70 
                              : themeProvider.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Золото
      case 2:
        return Colors.grey[400]!; // Серебро
      case 3:
        return Colors.brown; // Бронза
      default:
        return Colors.blue; // Обычный
    }
  }
}