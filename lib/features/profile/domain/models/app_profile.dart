/// Данные профиля приложения (имя, аватар)
class AppProfile {
  final String displayName;
  final String? avatarPath;
  final List<String> allergies;
  final List<String> contraindications;

  const AppProfile({
    this.displayName = 'Спортсмен',
    this.avatarPath,
    this.allergies = const [],
    this.contraindications = const [],
  });

  AppProfile copyWith({
    String? displayName,
    String? avatarPath,
    List<String>? allergies,
    List<String>? contraindications,
  }) {
    return AppProfile(
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      allergies: allergies ?? this.allergies,
      contraindications: contraindications ?? this.contraindications,
    );
  }
}
