import 'package:flutter/material.dart';

/// Ежедневный стрик по неделям: каждая неделя — строка из 7 дней (Пн–Вс).
class StreakCalendarWidget extends StatelessWidget {
  final int currentStreak;
  final Set<DateTime> workoutDates;
  final int weeksToShow;
  final bool isDark;

  const StreakCalendarWidget({
    super.key,
    required this.currentStreak,
    required this.workoutDates,
    this.weeksToShow = 1,
    this.isDark = false,
  });

  /// Начало недели (понедельник)
  static DateTime _weekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = _weekStart(today);

    // Список недель: от самой старой к текущей
    final weekStarts = List.generate(weeksToShow, (i) {
      return thisWeekStart.subtract(Duration(days: 7 * (weeksToShow - 1 - i)));
    });

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white70 : Colors.grey[600]!;
    final activeColor = const Color(0xFFFF9600);
    final inactiveColor = isDark ? Colors.white24 : Colors.grey[300]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department, color: activeColor, size: 28),
            const SizedBox(width: 8),
            Text(
              '$currentStreak',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              currentStreak == 1 ? 'день подряд' : 'дней подряд',
              style: TextStyle(fontSize: 14, color: subColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const daysPerWeek = 7;
            final cellWidth = (constraints.maxWidth / daysPerWeek).clamp(28.0, 48.0);
            final size = (cellWidth * 0.75).clamp(22.0, 36.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weekStarts.map((weekStart) {
                final weekEnd = weekStart.add(const Duration(days: 6));
                final isCurrentWeek = weekStart == thisWeekStart;
                final weekLabel = _weekLabel(weekStart, weekEnd, isCurrentWeek);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          weekLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(daysPerWeek, (i) {
                          final date = weekStart.add(Duration(days: i));
                          final hasWorkout = workoutDates.contains(date);
                          final isToday = date == today;
                          final weekday = _weekdayShort(date.weekday);
                          return SizedBox(
                            width: cellWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  weekday,
                                  style: TextStyle(fontSize: 10, color: subColor),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasWorkout ? activeColor : inactiveColor,
                                    border: isToday
                                        ? Border.all(color: activeColor, width: 2)
                                        : null,
                                    boxShadow: hasWorkout
                                        ? [
                                            BoxShadow(
                                              color: activeColor.withValues(alpha: 0.4),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: hasWorkout
                                      ? Icon(Icons.check, size: size * 0.5, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _weekLabel(DateTime start, DateTime end, bool isCurrentWeek) {
    const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    final startStr = '${start.day} ${months[start.month - 1]}';
    final endStr = '${end.day} ${months[end.month - 1]}';
    if (start.month == end.month) {
      return isCurrentWeek ? 'Эта неделя ($startStr – $endStr)' : '$startStr – $endStr';
    }
    return isCurrentWeek ? 'Эта неделя ($startStr – $endStr)' : '$startStr – $endStr';
  }

  String _weekdayShort(int weekday) {
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return names[weekday - 1];
  }
}
