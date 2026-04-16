import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/widgets/glass_card.dart';
import 'package:fitmonster/features/exercises/domain/models/exercise.dart';
import 'package:fitmonster/features/exercises/presentation/pages/exercise_camera_page.dart';

/// Страница детального описания упражнения
class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailPage({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.fm.scaffoldGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: context.fm.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            exercise.nameRu,
                            style: context.fm.titleStyle.copyWith(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(context, 'Описание', exercise.description, Icons.description),
                      const SizedBox(height: 24),
                      _buildInstructionsSection(context),
                      const SizedBox(height: 24),
                      _buildMistakesSection(context),
                      const SizedBox(height: 24),
                      _buildMuscleGroupsSection(context),
                      const SizedBox(height: 32),
                      _buildStartButton(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.fm.glowCyan, size: 20),
            const SizedBox(width: 8),
            Text(title, style: context.fm.titleStyle.copyWith(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Text(
            content,
            textAlign: TextAlign.center,
            style: context.fm.bodyStyle.copyWith(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, color: context.fm.glowCyan, size: 20),
            const SizedBox(width: 8),
            Text('Техника выполнения', style: context.fm.titleStyle.copyWith(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A42),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: exercise.instructions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.center,
                          style: context.fm.bodyStyle.copyWith(fontSize: 14, height: 1.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMistakesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, color: context.fm.glowCyan, size: 20),
            const SizedBox(width: 8),
            Text('Частые ошибки', style: context.fm.titleStyle.copyWith(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: exercise.commonMistakes.asMap().entries.map((entry) {
              final mistake = entry.value;
              final isLast = entry.key == exercise.commonMistakes.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.close, color: context.fm.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mistake,
                        textAlign: TextAlign.center,
                        style: context.fm.bodyStyle.copyWith(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleGroupsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.accessibility_new, color: context.fm.glowCyan, size: 20),
            const SizedBox(width: 8),
            Text('Работающие мышцы', style: context.fm.titleStyle.copyWith(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: exercise.muscleGroups.map((muscle) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: context.fm.outlineMuted),
              color: context.fm.surfaceCardMuted,
            ),
            child: Text(muscle, style: context.fm.bodyStyle.copyWith(fontSize: 12)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: context.fm.primaryButtonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.fm.glowCyan.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseCameraPage(exercise: exercise),
              ),
            );
          },
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Начать упражнение',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}