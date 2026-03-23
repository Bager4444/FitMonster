enum SubscriptionStatus { free, premium, expired }

class UserAccount {
  final String id;
  final String name;
  final String? email;
  final String? passwordHash;
  final bool isStreakModeEnabled;
  final int totalExercises;
  final int totalTrainingTimeSec;
  final double averageScorePercent;
  final int scoredSessionsCount;
  final List<String> achievements;
  final List<String> lastDevices;
  final List<String> allergies;
  final List<String> contraindications;
  final SubscriptionStatus subscriptionStatus;
  final int worldRank;
  final int regionRank;
  final String regionCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.isStreakModeEnabled,
    required this.totalExercises,
    required this.totalTrainingTimeSec,
    required this.averageScorePercent,
    required this.scoredSessionsCount,
    required this.achievements,
    required this.lastDevices,
    required this.allergies,
    required this.contraindications,
    required this.subscriptionStatus,
    required this.worldRank,
    required this.regionRank,
    required this.regionCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAccount.create({required String id, String? email}) {
    final now = DateTime.now();
    return UserAccount(
      id: id,
      name: 'Спортсмен',
      email: email,
      passwordHash: null,
      isStreakModeEnabled: true,
      totalExercises: 0,
      totalTrainingTimeSec: 0,
      averageScorePercent: 0,
      scoredSessionsCount: 0,
      achievements: const [],
      lastDevices: const [],
      allergies: const [],
      contraindications: const [],
      subscriptionStatus: SubscriptionStatus.free,
      worldRank: 0,
      regionRank: 0,
      regionCode: 'global',
      createdAt: now,
      updatedAt: now,
    );
  }

  UserAccount copyWith({
    String? name,
    String? email,
    String? passwordHash,
    bool? isStreakModeEnabled,
    int? totalExercises,
    int? totalTrainingTimeSec,
    double? averageScorePercent,
    int? scoredSessionsCount,
    List<String>? achievements,
    List<String>? lastDevices,
    List<String>? allergies,
    List<String>? contraindications,
    SubscriptionStatus? subscriptionStatus,
    int? worldRank,
    int? regionRank,
    String? regionCode,
    DateTime? updatedAt,
  }) {
    return UserAccount(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      isStreakModeEnabled: isStreakModeEnabled ?? this.isStreakModeEnabled,
      totalExercises: totalExercises ?? this.totalExercises,
      totalTrainingTimeSec: totalTrainingTimeSec ?? this.totalTrainingTimeSec,
      averageScorePercent: averageScorePercent ?? this.averageScorePercent,
      scoredSessionsCount: scoredSessionsCount ?? this.scoredSessionsCount,
      achievements: achievements ?? this.achievements,
      lastDevices: lastDevices ?? this.lastDevices,
      allergies: allergies ?? this.allergies,
      contraindications: contraindications ?? this.contraindications,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      worldRank: worldRank ?? this.worldRank,
      regionRank: regionRank ?? this.regionRank,
      regionCode: regionCode ?? this.regionCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'isStreakModeEnabled': isStreakModeEnabled,
      'totalExercises': totalExercises,
      'totalTrainingTimeSec': totalTrainingTimeSec,
      'averageScorePercent': averageScorePercent,
      'scoredSessionsCount': scoredSessionsCount,
      'achievements': achievements,
      'lastDevices': lastDevices,
      'allergies': allergies,
      'contraindications': contraindications,
      'subscriptionStatus': subscriptionStatus.name,
      'worldRank': worldRank,
      'regionRank': regionRank,
      'regionCode': regionCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    final subRaw = (map['subscriptionStatus'] ?? SubscriptionStatus.free.name)
        .toString();
    final status =
        SubscriptionStatus.values.where((s) => s.name == subRaw).isNotEmpty
        ? SubscriptionStatus.values.firstWhere((s) => s.name == subRaw)
        : SubscriptionStatus.free;

    return UserAccount(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'Спортсмен').toString(),
      email: map['email'] as String?,
      passwordHash: map['passwordHash'] as String?,
      isStreakModeEnabled: (map['isStreakModeEnabled'] as bool?) ?? true,
      totalExercises: (map['totalExercises'] as num?)?.toInt() ?? 0,
      totalTrainingTimeSec: (map['totalTrainingTimeSec'] as num?)?.toInt() ?? 0,
      averageScorePercent:
          (map['averageScorePercent'] as num?)?.toDouble() ?? 0,
      scoredSessionsCount: (map['scoredSessionsCount'] as num?)?.toInt() ?? 0,
      achievements: (map['achievements'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      lastDevices: (map['lastDevices'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      allergies: (map['allergies'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      contraindications:
          (map['contraindications'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      subscriptionStatus: status,
      worldRank: (map['worldRank'] as num?)?.toInt() ?? 0,
      regionRank: (map['regionRank'] as num?)?.toInt() ?? 0,
      regionCode: (map['regionCode'] ?? 'global').toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
