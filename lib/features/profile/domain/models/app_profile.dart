/// Данные профиля приложения (имя, аватар)
class AppProfile {
  final String displayName;
  final String? avatarPath;

  const AppProfile({
    this.displayName = 'Спортсмен',
    this.avatarPath,
  });

  AppProfile copyWith({String? displayName, String? avatarPath}) {
    return AppProfile(
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}
