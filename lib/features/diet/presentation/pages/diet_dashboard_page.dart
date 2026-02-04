import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/widgets/glass_card.dart';
import 'package:fitmonster/features/diet/domain/models/food_log.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';
import 'package:fitmonster/features/diet/domain/services/calorie_calculator.dart';
import 'package:fitmonster/features/diet/presentation/pages/food_log_page.dart';

/// Dashboard с графиками и статистикой питания (Deep Blue glass)
class DietDashboardPage extends StatefulWidget {
  const DietDashboardPage({super.key, this.targetMacros});

  final Macros? targetMacros;

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

    final target = widget.targetMacros;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Статистика питания',
                style: GlassTheme.titleStyle.copyWith(fontSize: 20),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today, color: GlassTheme.textPrimary),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: GlassTheme.glowCyan,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() => _selectedDate = picked);
                    _loadWeekData();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (target != null) _buildMacrosSummaryCard(todaySummary, target),
          if (target != null) const SizedBox(height: 16),
          _buildCaloriesChart(weekSummaries),
          const SizedBox(height: 16),
          _buildWeekStats(weekSummaries),
        ],
      ),
    );
  }

  Widget _buildMacrosSummaryCard(DailySummary summary, Macros target) {
    final calProgress = target.calories > 0 ? (summary.totalCalories / target.calories).clamp(0.0, 1.0) : 0.0;
    final pProgress = target.protein > 0 ? (summary.totalProtein / target.protein).clamp(0.0, 1.0) : 0.0;
    final fProgress = target.fat > 0 ? (summary.totalFat / target.fat).clamp(0.0, 1.0) : 0.0;
    final cProgress = target.carbs > 0 ? (summary.totalCarbs / target.carbs).clamp(0.0, 1.0) : 0.0;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Макросы сегодня', style: GlassTheme.titleStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMacroColumn('Ккал', '${summary.totalCalories}', target.calories.toString(), calProgress)),
              Expanded(child: _buildMacroColumn('Б', '${summary.totalProtein.round()}', '${target.protein}', pProgress)),
              Expanded(child: _buildMacroColumn('Ж', '${summary.totalFat.round()}', '${target.fat}', fProgress)),
              Expanded(child: _buildMacroColumn('У', '${summary.totalCarbs.round()}', '${target.carbs}', cProgress)),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressRow('Ккал', calProgress),
          const SizedBox(height: 6),
          _buildProgressRow('Белки', pProgress),
          const SizedBox(height: 6),
          _buildProgressRow('Жиры', fProgress),
          const SizedBox(height: 6),
          _buildProgressRow('Углеводы', cProgress),
        ],
      ),
    );
  }

  Widget _buildMacroColumn(String label, String value, String target, double progress) {
    return Column(
      children: [
        Text(value, style: GlassTheme.titleStyle.copyWith(fontSize: 18)),
        Text(label, style: GlassTheme.bodyStyle.copyWith(fontSize: 11)),
        Text('/ $target', style: GlassTheme.bodyStyle.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildProgressRow(String label, double progress) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label, style: GlassTheme.bodyStyle.copyWith(fontSize: 12))),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(GlassTheme.glowCyan),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayCard(DailySummary summary) {
    final target = widget.targetMacros ?? const Macros(calories: 2000, protein: 150, fat: 65, carbs: 250);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сегодня', style: GlassTheme.titleStyle.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Калории', '${summary.totalCalories}', GlassTheme.textPrimary),
              _buildStatItem('Белки', '${summary.totalProtein.round()}г', GlassTheme.textPrimary),
              _buildStatItem('Жиры', '${summary.totalFat.round()}г', GlassTheme.textPrimary),
              _buildStatItem('Углеводы', '${summary.totalCarbs.round()}г', GlassTheme.textPrimary),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodLogPage(
                      date: _selectedDate,
                      targetMacros: target,
                    ),
                  ),
                );
              },
              child: const Text('Открыть дневник', style: TextStyle(color: GlassTheme.glowCyan, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: GlassTheme.bodyStyle.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildCaloriesChart(Map<DateTime, DailySummary> summaries) {
    final maxCalories = summaries.values
        .map((s) => s.totalCalories)
        .fold(0, (a, b) => a > b ? a : b);
    final chartMax = maxCalories > 0 ? (maxCalories * 1.2).round() : 2000;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Калории за неделю', style: GlassTheme.titleStyle.copyWith(fontSize: 16)),
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
                        return Text(dayNames[dayIndex], style: const TextStyle(fontSize: 12, color: GlassTheme.textSecondary));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 12, color: GlassTheme.textSecondary)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final date = _selectedDate.subtract(Duration(days: 6 - index));
                  final dateOnly = DateTime(date.year, date.month, date.day);
                  final summary = summaries[dateOnly] ?? DailySummary(date: dateOnly, totalCalories: 0, totalProtein: 0, totalFat: 0, totalCarbs: 0, logs: const []);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: summary.totalCalories.toDouble(),
                        color: GlassTheme.glowCyan,
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
    if (total == 0) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Распределение БЖУ', style: GlassTheme.titleStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: summary.totalProtein, title: '', color: GlassTheme.glowCyan, radius: 40),
                      PieChartSectionData(value: summary.totalFat, title: '', color: GlassTheme.glowCyan.withOpacity(0.7), radius: 40),
                      PieChartSectionData(value: summary.totalCarbs, title: '', color: GlassTheme.glowCyan.withOpacity(0.5), radius: 40),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroLegend('Белки', summary.totalProtein),
                    const SizedBox(height: 8),
                    _buildMacroLegend('Жиры', summary.totalFat),
                    const SizedBox(height: 8),
                    _buildMacroLegend('Углеводы', summary.totalCarbs),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroLegend(String label, double value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: const BoxDecoration(color: GlassTheme.glowCyan, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GlassTheme.bodyStyle.copyWith(fontSize: 13))),
        Text('${value.toStringAsFixed(1)}г', style: GlassTheme.titleStyle.copyWith(fontSize: 13)),
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

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Средние показатели за неделю', style: GlassTheme.titleStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Калории', '$avgCalories', GlassTheme.textPrimary),
              _buildStatItem('Белки', '${avgProtein.toStringAsFixed(1)}г', GlassTheme.textPrimary),
              _buildStatItem('Жиры', '${avgFat.toStringAsFixed(1)}г', GlassTheme.textPrimary),
              _buildStatItem('Углеводы', '${avgCarbs.toStringAsFixed(1)}г', GlassTheme.textPrimary),
            ],
          ),
        ],
      ),
    );
  }
}
