import 'package:flutter/material.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/widgets/glass_card.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/core/services/hive_service.dart';
import 'package:fitmonster/core/services/stats_service.dart';
import 'package:fitmonster/core/models/user_stats.dart';
import 'package:fitmonster/features/auth/presentation/pages/auth_page.dart';
import 'package:fitmonster/features/diet/presentation/pages/profile_setup_page.dart';

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
  String? _nickname;
  List<int> _weekActiveDays = [];

  @override
  void initState() {
    super.initState();
    _loadDataForCurrentUser();
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
    final nickname = HiveService.get(
      box: HiveService.settingsBox,
      key: 'nickname_$userId',
    ) as String?;
    if (mounted) {
      final weekActive = StatsService.getWeekActiveDays(userId);
      setState(() {
        _userStats = stats;
        _nickname = nickname != null && nickname.isNotEmpty ? nickname : null;
        _weekActiveDays = weekActive;
      });
    }
  }

  static const List<String> _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  String _getDisplayName(AuthService auth) {
    if (_nickname != null && _nickname!.trim().isNotEmpty) return _nickname!.trim();
    return auth.currentUserEmail?.split('@').first ?? 'Гость';
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final isLoggedIn = auth.isEmailUser;
    final userId = auth.currentUserId ?? '';
    if (userId != _loadedUserId) WidgetsBinding.instance.addPostFrameCallback((_) => _loadDataForCurrentUser());
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
          Text(
            'Профиль',
            style: GlassTheme.titleStyle.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Недельная активность и статистика',
            style: GlassTheme.bodyStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildProfileHeader(context, displayName, isLoggedIn),
          const SizedBox(height: 24),
          _buildStreakCard(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String displayName, bool isLoggedIn) {
    return GlassCard(
      onTap: () => _showEditNicknameDialog(context, displayName),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: GlassTheme.glowCyan.withOpacity(0.3),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: GlassTheme.titleStyle.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GlassTheme.titleStyle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoggedIn ? 'Вы вошли в аккаунт' : 'Войдите или зарегистрируйтесь',
                  style: GlassTheme.bodyStyle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Нажмите, чтобы изменить никнейм',
                  style: GlassTheme.bodyStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.edit, color: GlassTheme.textSecondary, size: 20),
        ],
      ),
    );
  }

  Future<void> _showEditNicknameDialog(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: _nickname ?? currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Никнейм', style: GlassTheme.titleStyle.copyWith(fontSize: 20)),
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
            child: Text('Отмена', style: TextStyle(color: GlassTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: GlassTheme.gradientTop),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      final userId = AuthService().currentUserId ?? '';
      if (userId.isNotEmpty) {
        if (result.isEmpty) {
          await HiveService.delete(box: HiveService.settingsBox, key: 'nickname_$userId');
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
      });
    }
  }

  Widget _buildStreakCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Неделя',
                style: GlassTheme.titleStyle.copyWith(fontSize: 18),
              ),
              Text(
                'Серия: ${_userStats?.workoutStreak ?? 0}',
                style: GlassTheme.bodyStyle.copyWith(fontSize: 14),
              ),
            ],
          ),
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
                    style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  active
                      ? CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.cyanAccent,
                          child: Icon(
                            Icons.check,
                            color: GlassTheme.gradientBottom,
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
    final stats = [
      _StatItem(Icons.fitness_center, 'Тренировки', '$totalWorkouts'),
      _StatItem(Icons.local_fire_department, 'Серия дней', '$streak'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: stats.map((s) => _buildStatCard(s)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return GlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: GlassTheme.glowCyan, size: 28),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: GlassTheme.titleStyle.copyWith(fontSize: 18),
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
              MaterialPageRoute(
                builder: (context) => const ProfileSetupPage(),
              ),
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
                MaterialPageRoute(
                  builder: (context) => const AuthPage(),
                ),
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
          Icon(icon, color: GlassTheme.textPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GlassTheme.titleStyle.copyWith(fontSize: 16),
            ),
          ),
          Icon(Icons.chevron_right, color: GlassTheme.textSecondary, size: 22),
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
