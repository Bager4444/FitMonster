import 'package:flutter/material.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/widgets/glass_card.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/core/services/stats_service.dart';
import 'package:fitmonster/core/services/user_account_service.dart';
import 'package:fitmonster/core/models/user_stats.dart';
import 'package:fitmonster/core/models/user_account.dart';
import 'package:fitmonster/features/auth/presentation/pages/auth_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/profile_setup_page.dart';
import 'package:fitmonster/features/profile/domain/models/achievement.dart';
import 'package:fitmonster/features/profile/services/profile_service.dart';

/// Экран профиля: streak за неделю (Пн–Вс) и сетка статистики (привязаны к аккаунту).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.isCurrentTab = false});

  final bool isCurrentTab;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _loadedUserId;
  UserStats? _userStats;
  UserAccount? _userAccount;
  String? _nickname;
  List<int> _weekActiveDays = [];
  List<Achievement> _previewAchievements = [];
  final TextEditingController _promoController = TextEditingController();
  bool _promoLoading = false;
  List<UserAccount> _leaderboardTop = [];
  int? _myRank;
  int _leaderboardTotal = 0;
  int _myRatingScore = 0;
  bool _rankRefreshing = false;

  /// Промокод → бонусный XP (один раз на пользователя).
  static const Map<String, int> _promoXpBonus = {
    'FITMONSTER': 100,
    'START2025': 50,
  };

  @override
  void initState() {
    super.initState();
    _loadDataForCurrentUser();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab && !oldWidget.isCurrentTab) {
      _loadDataForCurrentUser(force: true);
    }
  }

  Future<void> _loadDataForCurrentUser({bool force = false}) async {
    final userId = AuthService().currentUserId ?? '';
    if (!force && userId == _loadedUserId) return;
    _loadedUserId = userId;
    final stats = await StatsService().getUserStats(userId);
    final account = await UserAccountService().getByUserId(userId);
    final nickname =
        HiveService.get(box: HiveService.settingsBox, key: 'nickname_$userId')
            as String?;
    final achievements = await ProfileService().getAchievements();
    final accountsSvc = UserAccountService();
    final sorted = accountsSvc.sortedAccountsByRating();
    final top = sorted.take(12).toList();
    int? myRank;
    if (userId.isNotEmpty) {
      final i = sorted.indexWhere((u) => u.id == userId);
      myRank = i >= 0 ? i + 1 : null;
    }
    final myScore =
        account != null ? UserAccountService.ratingScore(account) : 0;
    if (mounted) {
      final weekActive = StatsService.getWeekActiveDays(userId);
      setState(() {
        _userStats = stats;
        _userAccount = account;
        _nickname = nickname != null && nickname.isNotEmpty ? nickname : null;
        _weekActiveDays = weekActive;
        _previewAchievements = achievements.take(8).toList();
        _leaderboardTop = top;
        _myRank = myRank;
        _leaderboardTotal = sorted.length;
        _myRatingScore = myScore;
      });
    }
  }

  Future<void> _refreshLeaderboardRanks() async {
    setState(() => _rankRefreshing = true);
    try {
      await UserAccountService().refreshRanks();
      if (mounted) {
        await _loadDataForCurrentUser(force: true);
      }
    } finally {
      if (mounted) {
        setState(() => _rankRefreshing = false);
      }
    }
  }

  String _leaderboardDisplayName(UserAccount u) {
    final n = u.name.trim();
    if (n.isNotEmpty) {
      return n;
    }
    final em = u.email;
    if (em != null && em.contains('@')) {
      return em.split('@').first;
    }
    return 'Игрок';
  }

  String _medalForRank(int rank) {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };
  }

  Future<void> _applyPromoCode() async {
    final raw = _promoController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите промокод'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final code = raw.toUpperCase();
    final bonus = _promoXpBonus[code];
    if (bonus == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Промокод не найден'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }
    final userId = AuthService().currentUserId ?? '';
    final key = 'promos_redeemed_$userId';
    final rawList =
        HiveService.get(box: HiveService.settingsBox, key: key) as List?;
    final used = rawList?.map((e) => e.toString()).toList() ?? <String>[];
    if (used.contains(code)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Этот промокод уже использован'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => _promoLoading = true);
    used.add(code);
    await HiveService.put(box: HiveService.settingsBox, key: key, value: used);
    await ProfileService().addExperience(bonus);
    if (mounted) {
      setState(() => _promoLoading = false);
      _promoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Промокод принят! +$bonus XP'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      await _loadDataForCurrentUser(force: true);
    }
  }

  static const List<String> _dayLabels = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  String _getDisplayName(AuthService auth) {
    if (_userAccount != null && _userAccount!.name.trim().isNotEmpty) {
      return _userAccount!.name.trim();
    }
    if (_nickname != null && _nickname!.trim().isNotEmpty) {
      return _nickname!.trim();
    }
    return auth.currentUserEmail?.split('@').first ?? 'Гость';
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final isLoggedIn = auth.isEmailUser;
    final userId = auth.currentUserId ?? '';
    if (userId != _loadedUserId) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadDataForCurrentUser(),
      );
    }
    final displayName = _getDisplayName(auth);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Профиль', style: context.fm.titleStyle.copyWith(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            'Недельная активность и статистика',
            style: context.fm.bodyStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildProfileHeader(context, displayName, isLoggedIn),
          const SizedBox(height: 24),
          _buildStreakCard(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildRatingSection(userId),
          const SizedBox(height: 24),
          _buildPromoSection(),
          const SizedBox(height: 24),
          _buildAchievementsPreview(),
          const SizedBox(height: 24),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String displayName,
    bool isLoggedIn,
  ) {
    return GlassCard(
      onTap: () => _showEditNicknameDialog(context, displayName),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: context.fm.glowCyan.withOpacity(0.3),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: context.fm.titleStyle.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: context.fm.titleStyle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoggedIn
                      ? 'Вы вошли в аккаунт'
                      : 'Войдите или зарегистрируйтесь',
                  style: context.fm.bodyStyle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Нажмите, чтобы изменить никнейм',
                  style: context.fm.bodyStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.edit, color: context.fm.textSecondary, size: 20),
        ],
      ),
    );
  }

  Future<void> _showEditNicknameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: _nickname ?? currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.fm.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Никнейм',
          style: context.fm.titleStyle.copyWith(fontSize: 20),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Введите никнейм',
            hintStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black26),
            ),
          ),
          autofocus: true,
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Отмена',
              style: TextStyle(color: context.fm.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: context.fm.gradientHeaderTop,
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      final userId = AuthService().currentUserId ?? '';
      if (userId.isNotEmpty) {
        if (result.isEmpty) {
          await HiveService.delete(
            box: HiveService.settingsBox,
            key: 'nickname_$userId',
          );
        } else {
          await HiveService.put(
            box: HiveService.settingsBox,
            key: 'nickname_$userId',
            value: result,
          );
        }
      }
      setState(() {
        _nickname = result.isEmpty ? null : result;
        if (result.isNotEmpty) {
          _userAccount = _userAccount?.copyWith(name: result);
        }
      });
      if (result.isNotEmpty && userId.isNotEmpty) {
        await UserAccountService().updateProfile(userId: userId, name: result);
      }
    }
  }

  Widget _buildStreakCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Неделя', style: context.fm.titleStyle.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final weekday = i + 1; // Пн=1 … Вс=7
              final active = _weekActiveDays.contains(weekday);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dayLabels[i],
                    style: context.fm.bodyStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  active
                      ? CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.cyanAccent,
                          child: Icon(
                            Icons.check,
                            color: context.fm.gradientHeaderBottom,
                            size: 22,
                          ),
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalWorkouts = _userStats?.totalWorkouts ?? 0;
    final streak = _userStats?.workoutStreak ?? 0;
    final totalExercises = _userAccount?.totalExercises ?? 0;
    final totalMinutes = ((_userAccount?.totalTrainingTimeSec ?? 0) / 60)
        .round();
    final avgScore = (_userAccount?.averageScorePercent ?? 0).toStringAsFixed(
      1,
    );
    final worldRank = _userAccount?.worldRank ?? 0;
    final regionRank = _userAccount?.regionRank ?? 0;
    final stats = [
      _StatItem(Icons.fitness_center, 'Тренировки', '$totalWorkouts'),
      _StatItem(Icons.local_fire_department, 'Серия дней', '$streak'),
      _StatItem(Icons.repeat, 'Упражнений', '$totalExercises'),
      _StatItem(Icons.timer, 'Минут в выполнении', '$totalMinutes'),
      _StatItem(Icons.percent, 'Средний процент', '$avgScore%'),
      _StatItem(
        Icons.public,
        'Рейтинг: мир/регион',
        '$worldRank / $regionRank',
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: stats.map((s) => _buildStatCard(s)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return GlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: context.fm.glowCyan, size: 28),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: context.fm.bodyStyle.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(item.value, style: context.fm.titleStyle.copyWith(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildRatingSection(String currentUserId) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: context.fm.glowCyan, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Рейтинг',
                  style: context.fm.titleStyle.copyWith(fontSize: 18),
                ),
              ),
              IconButton(
                onPressed: _rankRefreshing ? null : _refreshLeaderboardRanks,
                icon: _rankRefreshing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh, color: context.fm.textSecondary),
                tooltip: 'Обновить позиции',
              ),
            ],
          ),
          Text(
            'Локально: все аккаунты на этом устройстве. Балл = упражнения, время, техника, ачивки.',
            style: context.fm.bodyStyle.copyWith(fontSize: 11),
          ),
          if (_myRank != null || _leaderboardTotal > 0) ...[
            const SizedBox(height: 10),
            Text(
              _myRank != null
                  ? 'Ваше место: $_myRank из $_leaderboardTotal · балл $_myRatingScore'
                  : 'Игроков в таблице: $_leaderboardTotal',
              style: TextStyle(
                color: context.fm.glowCyan,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_leaderboardTop.isEmpty)
            Text(
              'Пока нет данных для рейтинга',
              style: context.fm.bodyStyle.copyWith(fontSize: 13),
            )
          else
            ...List.generate(_leaderboardTop.length, (index) {
              final rank = index + 1;
              final u = _leaderboardTop[index];
              final isMe = u.id == currentUserId;
              final score = UserAccountService.ratingScore(u);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? context.fm.glowCyan.withOpacity(0.12)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMe
                          ? context.fm.glowCyan.withOpacity(0.5)
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          _medalForRank(rank),
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _leaderboardDisplayName(u),
                              style: context.fm.titleStyle.copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isMe)
                              Text(
                                'Вы',
                                style: TextStyle(
                                  color: context.fm.glowCyan,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '$score',
                        style: context.fm.titleStyle.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPromoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: context.fm.glowCyan, size: 22),
              const SizedBox(width: 8),
              Text(
                'Промокод',
                style: context.fm.titleStyle.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  style: TextStyle(color: context.fm.textPrimary),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Введите код',
                    hintStyle: TextStyle(
                      color: context.fm.textSecondary.withOpacity(0.8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: context.fm.glowCyan),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_promoLoading) _applyPromoCode();
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _promoLoading ? null : _applyPromoCode,
                style: FilledButton.styleFrom(
                  backgroundColor: context.fm.gradientHeaderTop,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _promoLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('OK'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsPreview() {
    if (_previewAchievements.isEmpty) {
      return const SizedBox.shrink();
    }
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: context.fm.glowCyan, size: 22),
              const SizedBox(width: 8),
              Text(
                'Достижения',
                style: context.fm.titleStyle.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._previewAchievements.map(_buildAchievementTile),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(Achievement a) {
    final unlocked = a.isUnlocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: context.fm.titleStyle.copyWith(
                    fontSize: 15,
                    color: unlocked
                        ? context.fm.textPrimary
                        : context.fm.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.description,
                  style: context.fm.bodyStyle.copyWith(fontSize: 12),
                ),
                if (unlocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Получено',
                      style: TextStyle(
                        color: context.fm.glowCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            color: unlocked ? context.fm.glowCyan : context.fm.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final auth = AuthService();
    return Column(
      children: [
        _buildGlassButton(
          label: 'Настроить профиль питания',
          icon: Icons.settings,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        if (!auth.isEmailUser)
          _buildGlassButton(
            label: 'Войти',
            icon: Icons.login,
            onTap: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
              );
              if (context.mounted) setState(() {});
            },
          )
        else
          _buildGlassButton(
            label: 'Выйти',
            icon: Icons.logout,
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) setState(() {});
            },
          ),
      ],
    );
  }

  Widget _buildGlassButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: context.fm.textPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: context.fm.titleStyle.copyWith(fontSize: 16),
            ),
          ),
          Icon(Icons.chevron_right, color: context.fm.textSecondary, size: 22),
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  _StatItem(this.icon, this.label, this.value);
}
