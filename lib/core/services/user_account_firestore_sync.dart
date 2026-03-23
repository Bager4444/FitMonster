import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fitmonster/core/models/user_account.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/core/services/stats_service.dart';
import 'package:fitmonster/core/services/user_account_service.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';
import 'package:fitmonster/features/profile/services/profile_service.dart';

/// Синхронизация [UserAccount] с Firestore для пользователей `firebase_<uid>`.
/// Правила: `users/{userId}/...` — только при `request.auth.uid == userId`.
/// Документы: `users/{uid}/sync/account`, `sync/metrics`, `sync/diet_profile`.
class UserAccountFirestoreSync {
  UserAccountFirestoreSync._();
  static final UserAccountFirestoreSync instance = UserAccountFirestoreSync._();

  static const String _syncCollection = 'sync';
  static const String _accountDocId = 'account';
  static const String _metricsDocId = 'metrics';
  static const String _dietProfileDocId = 'diet_profile';

  static String? firebaseUidFromAppUserId(String? userId) {
    if (userId == null || !userId.startsWith('firebase_')) return null;
    return userId.substring('firebase_'.length);
  }

  CollectionReference<Map<String, dynamic>> _syncCol(String firebaseUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUid)
        .collection(_syncCollection);
  }

  DocumentReference<Map<String, dynamic>> _accountRef(String firebaseUid) {
    return _syncCol(firebaseUid).doc(_accountDocId);
  }

  /// Поля для облака: как [UserAccount.toMap], но без [UserAccount.passwordHash].
  Map<String, dynamic> _toCloudMap(UserAccount account) {
    final m = account.toMap();
    m.remove('passwordHash');
    return m;
  }

  Map<String, dynamic> _normalizeSnapshot(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is Timestamp) {
        out[e.key] = v.toDate().toIso8601String();
      } else {
        out[e.key] = v;
      }
    }
    return out;
  }

  /// Доп. показатели: ударный режим, стрик, XP, веса, профиль питания (без паролей).
  Future<void> _pushMetricsAndDiet(String firebaseUid, UserAccount account) async {
    final appUserId = account.id;
    final stats = await StatsService().getUserStats(appUserId);
    final profile = ProfileService();
    final xp = await profile.getExperience();
    final level = ProfileService.levelFromXp(xp);
    final appProf = await profile.getAppProfile();

    final metrics = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
      'isStreakModeEnabled': account.isStreakModeEnabled,
      'workoutStreakDays': stats.workoutStreak,
      'totalWorkouts': stats.totalWorkouts,
      'totalCaloriesWeek': stats.totalCalories,
      'currentWeight': stats.currentWeight,
      'targetWeight': stats.targetWeight,
      'lastWorkoutDate': stats.lastWorkoutDate.toIso8601String(),
      'xp': xp,
      'level': level,
      'displayName': appProf.displayName,
      'achievementIds': account.achievements,
    };
    if (stats.lastDietLogDate != null) {
      metrics['lastDietLogDate'] = stats.lastDietLogDate!.toIso8601String();
    }

    await _syncCol(firebaseUid).doc(_metricsDocId).set(
          metrics,
          SetOptions(merge: true),
        );

    final diet = await DietService.getUserProfile();
    if (diet != null && diet.userId == appUserId) {
      await _syncCol(firebaseUid).doc(_dietProfileDocId).set(
            diet.toMap(),
            SetOptions(merge: true),
          );
    }

    if (kDebugMode) {
      debugPrint(
        'UserAccountFirestoreSync: metrics+diet OK users/$firebaseUid/sync/$_metricsDocId',
      );
    }
  }

  /// Вызов после сохранения только статистики (стрик/тренировки), без смены аккаунта.
  Future<void> onLocalStatsMaybeChanged(String userId) async {
    final uid = firebaseUidFromAppUserId(userId);
    if (uid == null) return;
    final acc = await UserAccountService().getByUserId(userId);
    if (acc == null) return;
    try {
      await _pushMetricsAndDiet(uid, acc);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('UserAccountFirestoreSync.metrics: $e\n$st');
      }
    }
  }

  /// Записать локальный аккаунт в Firestore (merge).
  Future<void> pushAfterLocalSave(UserAccount account) async {
    final uid = firebaseUidFromAppUserId(account.id);
    if (uid == null) return;
    try {
      await _accountRef(uid).set(_toCloudMap(account), SetOptions(merge: true));
      await _pushMetricsAndDiet(uid, account);
      if (kDebugMode) {
        debugPrint(
          'UserAccountFirestoreSync: запись OK users/$uid/sync/$_accountDocId',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('UserAccountFirestoreSync.push ОШИБКА: $e\n$st');
      }
    }
  }

  /// Подтянуть облако и слить в Hive, если [remote.updatedAt] новее локального.
  Future<void> pullMergeIfRemoteNewer(String appUserId) async {
    final uid = firebaseUidFromAppUserId(appUserId);
    if (uid == null) return;

    final svc = UserAccountService();
    try {
      final snap = await _accountRef(uid).get();
      if (!snap.exists || snap.data() == null) return;

      final remote = UserAccount.fromMap(_normalizeSnapshot(snap.data()!));
      final local = await svc.getByUserId(appUserId);

      UserAccount merged;
      if (local == null) {
        merged = remote.copyWith(id: appUserId, passwordHash: null);
      } else {
        if (!remote.updatedAt.isAfter(local.updatedAt)) return;
        merged = remote.copyWith(id: appUserId, passwordHash: local.passwordHash);
      }

      await HiveService.put(
        box: HiveService.usersBox,
        key: UserAccountService.storageKeyFor(appUserId),
        value: merged.toMap(),
      );
      await svc.refreshRanks();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('UserAccountFirestoreSync.pull: $e\n$st');
      }
    }
  }
}
