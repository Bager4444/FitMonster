import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:fitmonster/core/models/user_account.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';

class UserAccountService {
  static final UserAccountService _instance = UserAccountService._internal();
  factory UserAccountService() => _instance;
  UserAccountService._internal();

  static const String _migratedPrefix = 'user_account_migrated_';

  /// Ключ записи в [HiveService.usersBox] (используется и Firestore-синком).
  static String storageKeyFor(String userId) => 'user_account_$userId';

  String _key(String userId) => storageKeyFor(userId);

  /// Push в Firestore после сохранения в Hive (регистрируется в [main]).
  Future<void> Function(UserAccount account)? _firestorePush;

  void attachFirestorePush(Future<void> Function(UserAccount account) fn) {
    _firestorePush = fn;
  }

  String hashPassword(String rawPassword) {
    return sha256.convert(utf8.encode(rawPassword)).toString();
  }

  Future<UserAccount> getOrCreateUser(String userId, {String? email}) async {
    final existing = await getByUserId(userId);
    if (existing != null) return existing;

    final created = UserAccount.create(id: userId, email: email);
    await _save(created);
    await migrateLegacyData(userId);
    await registerDeviceForUser(userId);
    return created;
  }

  Future<UserAccount?> getByUserId(String userId) async {
    final raw = HiveService.get(box: HiveService.usersBox, key: _key(userId));
    if (raw is Map<String, dynamic>) {
      return UserAccount.fromMap(raw);
    }
    if (raw is Map) {
      return UserAccount.fromMap(raw.map((k, v) => MapEntry(k.toString(), v)));
    }
    return null;
  }

  Future<void> upsertFromAuth({
    required String userId,
    String? email,
    String? plainPassword,
  }) async {
    final current =
        await getByUserId(userId) ??
        UserAccount.create(id: userId, email: email);
    final next = current.copyWith(
      email: email ?? current.email,
      passwordHash: plainPassword != null && plainPassword.isNotEmpty
          ? hashPassword(plainPassword)
          : current.passwordHash,
    );
    await _save(next);
    await migrateLegacyData(userId);
    await registerDeviceForUser(userId);
    await refreshRanks();
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? regionCode,
    bool? isStreakModeEnabled,
  }) async {
    final current = await getByUserId(userId) ?? UserAccount.create(id: userId);
    await _save(
      current.copyWith(
        name: name,
        regionCode: regionCode,
        isStreakModeEnabled: isStreakModeEnabled,
      ),
    );
    await refreshRanks();
  }

  Future<void> updateMedicalInfo({
    required String userId,
    List<String>? allergies,
    List<String>? contraindications,
  }) async {
    final current = await getByUserId(userId) ?? UserAccount.create(id: userId);
    await _save(
      current.copyWith(
        allergies: allergies ?? current.allergies,
        contraindications: contraindications ?? current.contraindications,
      ),
    );
  }

  Future<void> updateSubscription({
    required String userId,
    required SubscriptionStatus status,
  }) async {
    final current = await getByUserId(userId) ?? UserAccount.create(id: userId);
    await _save(current.copyWith(subscriptionStatus: status));
    await refreshRanks();
  }

  Future<void> updateAchievements({
    required String userId,
    required List<String> achievementIds,
  }) async {
    final current = await getByUserId(userId) ?? UserAccount.create(id: userId);
    await _save(
      current.copyWith(achievements: achievementIds.toSet().toList()),
    );
    await refreshRanks();
  }

  Future<void> updateWorkoutMetrics({
    required String userId,
    required int exerciseCount,
    required int durationSec,
    double? sessionPercent,
  }) async {
    final current = await getByUserId(userId) ?? UserAccount.create(id: userId);

    final nextCount =
        (current.scoredSessionsCount + (sessionPercent != null ? 1 : 0));
    final nextAverage = sessionPercent == null
        ? current.averageScorePercent
        : ((current.averageScorePercent * current.scoredSessionsCount) +
                  sessionPercent) /
              nextCount;

    await _save(
      current.copyWith(
        totalExercises: current.totalExercises + exerciseCount,
        totalTrainingTimeSec: current.totalTrainingTimeSec + durationSec,
        averageScorePercent: nextAverage.clamp(0, 100),
        scoredSessionsCount: nextCount,
      ),
    );
    await refreshRanks();
  }

  Future<void> registerDeviceForUser(
    String userId, [
    String? rawDeviceId,
  ]) async {
    if (userId.isEmpty) return;
    final current = await getByUserId(userId) ?? UserAccount.create(id: userId);

    final deviceId = (rawDeviceId == null || rawDeviceId.trim().isEmpty)
        ? _defaultDeviceLabel()
        : rawDeviceId.trim();
    final next = <String>[
      deviceId,
      ...current.lastDevices.where((d) => d != deviceId),
    ];
    await _save(current.copyWith(lastDevices: next.take(3).toList()));
  }

  Future<void> migrateLegacyData(String userId) async {
    final marker =
        HiveService.get(
              box: HiveService.settingsBox,
              key: '$_migratedPrefix$userId',
              defaultValue: false,
            )
            as bool;
    if (marker) return;

    var current = await getByUserId(userId) ?? UserAccount.create(id: userId);

    final nickname =
        HiveService.get(box: HiveService.settingsBox, key: 'nickname_$userId')
            as String?;
    if (nickname != null && nickname.trim().isNotEmpty) {
      current = current.copyWith(name: nickname.trim());
    }

    final statsRaw = HiveService.get(
      box: HiveService.userBox,
      key: 'stats_$userId',
    );
    if (statsRaw is Map) {
      final totalWorkouts = (statsRaw['totalWorkouts'] as num?)?.toInt() ?? 0;
      if (totalWorkouts > current.totalExercises) {
        current = current.copyWith(totalExercises: totalWorkouts);
      }
    }

    final profile = await DietService.getUserProfile();
    if (profile != null && profile.userId == userId) {
      current = current.copyWith(
        name: (profile.name != null && profile.name!.trim().isNotEmpty)
            ? profile.name!.trim()
            : current.name,
        allergies: profile.allergies,
        contraindications: profile.contraindications,
      );
    }

    await _save(current);
    await HiveService.put(
      box: HiveService.settingsBox,
      key: '$_migratedPrefix$userId',
      value: true,
    );
    await refreshRanks();
  }

  /// Балл для таблицы лидеров (тот же, что внутри [refreshRanks]).
  static int ratingScore(UserAccount account) {
    final base = account.totalExercises * 10;
    final duration = account.totalTrainingTimeSec ~/ 60;
    final quality = account.averageScorePercent.round() * 50;
    final achievements = account.achievements.length * 100;
    return base + duration + quality + achievements;
  }

  /// Все аккаунты из Hive по убыванию рейтинга (без записи в облако).
  List<UserAccount> sortedAccountsByRating() {
    final box = HiveService.getBox(HiveService.usersBox);
    final users = box.values
        .whereType<Map>()
        .map(
          (raw) =>
              UserAccount.fromMap(raw.map((k, v) => MapEntry(k.toString(), v))),
        )
        .toList();
    users.sort((a, b) => ratingScore(b).compareTo(ratingScore(a)));
    return users;
  }

  Future<void> refreshRanks() async {
    final users = sortedAccountsByRating();
    if (users.isEmpty) return;

    for (var i = 0; i < users.length; i++) {
      final user = users[i];
      final sameRegion =
          users.where((u) => u.regionCode == user.regionCode).toList()
            ..sort(
              (a, b) => ratingScore(b).compareTo(ratingScore(a)),
            );
      final regionRank = sameRegion.indexWhere((u) => u.id == user.id) + 1;
      await _save(user.copyWith(worldRank: i + 1, regionRank: regionRank));
    }
  }

  int _score(UserAccount account) => ratingScore(account);

  String _defaultDeviceLabel() {
    if (kIsWeb) return 'web';
    return 'platform_${defaultTargetPlatform.name}';
  }

  Future<void> _save(UserAccount account) async {
    await HiveService.put(
      box: HiveService.usersBox,
      key: _key(account.id),
      value: account.toMap(),
    );
    final push = _firestorePush;
    if (account.id.startsWith('firebase_')) {
      if (push == null) {
        if (kDebugMode) {
          debugPrint(
            'UserAccountService: пропуск Firestore — не вызван attachFirestorePush '
            '(часто Firebase.initializeApp не выполнился).',
          );
        }
      } else {
        try {
          await push(account);
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('UserAccountService Firestore push: $e\n$st');
          }
        }
      }
    }
  }

  Future<void> syncFromDietProfile(UserProfile profile) async {
    await updateMedicalInfo(
      userId: profile.userId,
      allergies: profile.allergies,
      contraindications: profile.contraindications,
    );
    if (profile.name != null && profile.name!.trim().isNotEmpty) {
      await updateProfile(userId: profile.userId, name: profile.name!.trim());
    }
  }
}
