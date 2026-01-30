import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';
import 'package:fitmonster/features/diet/domain/services/calorie_calculator.dart';
import 'package:fitmonster/features/diet/presentation/pages/food_log_page.dart';
import 'package:fitmonster/core/theme/app_theme.dart';

/// Dashboard с графиками и статистикой питания
class DietDashboardPage extends StatefulWidget {
  const DietDashboardPage({super.key});

  @override
  State<DietDashboardPage> createState() => _DietDashboardPageState();
}

class _DietDashboardPageState extends State<DietDashboardPage> {
  DateTime _selectedDate = DateTime.now();
  List<FoodLog> _weekLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    setState(() {
      _isLoading = true;
    });

    final startDate = _selectedDate.subtract(const Duration(days: 6));
    final endDate = _selectedDate;

    final logs = await DietService.getFoodLogsForPeriod(startDate, endDate);
    
    setState(() {
      _weekLogs = logs;
      _isLoading = false;
    });
  }

  Map<DateTime, DailySummary> _getWeekSummaries() {
    final summaries = <DateTime, DailySummary>{};
    final startDate = _selectedDate.subtract(const Duration(days: 6));

    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final dayLogs = _weekLogs.where((log) {
        final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        return logDate == dateOnly;
      }).toList();
      summaries[dateOnly] = DailySummary.fromLogs(dateOnly, dayLogs);
    }

    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final weekSummaries = _getWeekSummaries();
    final todaySummary = weekSummaries[DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)] 
        ?? DailySummary(
            date: _selectedDate,
            totalCalories: 0,
            totalProtein: 0,
            totalFat: 0,
            totalCarbs: 0,
            logs: const [],
          );

    return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Кнопка выбора даты
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Статистика питания',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                        _loadWeekData();
                      }
                    },
                  ),
                ],
              ),
            ),
            // Карточка сегодня
            _buildTodayCard(todaySummary),
            
            // График калорий за неделю
            _buildCaloriesChart(weekSummaries),
            
            // Круговая диаграмма БЖУ
            _buildMacrosPieChart(todaySummary),
            
            // Статистика за неделю
            _buildWeekStats(weekSummaries),
          ],
        ),
    );
  }

  Widget _buildTodayCard(DailySummary summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сегодня',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Калории', '${summary.totalCalories}', Colors.white),
              _buildStatItem('Белки', '${summary.totalProtein.round()}г', Colors.white),
              _buildStatItem('Жиры', '${summary.totalFat.round()}г', Colors.white),
              _buildStatItem('Углеводы', '${summary.totalCarbs.round()}г', Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodLogPage(
                    date: _selectedDate,
                    targetMacros: Macros(calories: 2000, protein: 150, fat: 65, carbs: 250),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Открыть дневник'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesChart(Map<DateTime, DailySummary> summaries) {
    final maxCalories = summaries.values
        .map((s) => s.totalCalories)
        .fold(0, (a, b) => a > b ? a : b);
    final chartMax = maxCalories > 0 ? (maxCalories * 1.2).round() : 2000;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Калории за неделю',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax.toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= 7) return const SizedBox();
                        final date = _selectedDate.subtract(Duration(days: 6 - index));
                        final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
                        final dayIndex = (date.weekday - 1) % 7;
                        return Text(
                          dayNames[dayIndex],
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final date = _selectedDate.subtract(Duration(days: 6 - index));
                  final dateOnly = DateTime(date.year, date.month, date.day);
                  final summary = summaries[dateOnly] ?? DailySummary(
                    date: dateOnly,
                    totalCalories: 0,
                    totalProtein: 0,
                    totalFat: 0,
                    totalCarbs: 0,
                    logs: const [],
                  );
                  final isToday = dateOnly.year == _selectedDate.year &&
                      dateOnly.month == _selectedDate.month &&
                      dateOnly.day == _selectedDate.day;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: summary.totalCalories.toDouble(),
                        color: isToday
                            ? AppTheme.primaryGreen
                            : AppTheme.primaryGreen.withOpacity(0.6),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosPieChart(DailySummary summary) {
    final total = summary.totalProtein + summary.totalFat + summary.totalCarbs;
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Распределение БЖУ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: summary.totalProtein,
                        title: '${((summary.totalProtein / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.blue,
                        radius: 50,
                      ),
                      PieChartSectionData(
                        value: summary.totalFat,
                        title: '${((summary.totalFat / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.orange,
                        radius: 50,
                      ),
                      PieChartSectionData(
                        value: summary.totalCarbs,
                        title: '${((summary.totalCarbs / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.purple,
                        radius: 50,
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroLegend('Белки', summary.totalProtein, Colors.blue),
                    const SizedBox(height: 12),
                    _buildMacroLegend('Жиры', summary.totalFat, Colors.orange),
                    const SizedBox(height: 12),
                    _buildMacroLegend('Углеводы', summary.totalCarbs, Colors.purple),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroLegend(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)}г',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildWeekStats(Map<DateTime, DailySummary> summaries) {
    final avgCalories = summaries.values
        .map((s) => s.totalCalories)
        .fold(0, (a, b) => a + b) ~/
        (summaries.isEmpty ? 1 : summaries.length);
    final avgProtein = summaries.values
        .map((s) => s.totalProtein)
        .fold(0.0, (a, b) => a + b) /
        (summaries.isEmpty ? 1 : summaries.length);
    final avgFat = summaries.values
        .map((s) => s.totalFat)
        .fold(0.0, (a, b) => a + b) /
        (summaries.isEmpty ? 1 : summaries.length);
    final avgCarbs = summaries.values
        .map((s) => s.totalCarbs)
        .fold(0.0, (a, b) => a + b) /
        (summaries.isEmpty ? 1 : summaries.length);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Средние показатели за неделю',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Калории', '$avgCalories', Colors.grey[800]!),
              _buildStatItem('Белки', '${avgProtein.toStringAsFixed(1)}г', Colors.grey[800]!),
              _buildStatItem('Жиры', '${avgFat.toStringAsFixed(1)}г', Colors.grey[800]!),
              _buildStatItem('Углеводы', '${avgCarbs.toStringAsFixed(1)}г', Colors.grey[800]!),
            ],
          ),
        ],
      ),
    );
  }
}
