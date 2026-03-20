/// Достижение
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji или имя иконки
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.icon = '🏆',
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;
}
