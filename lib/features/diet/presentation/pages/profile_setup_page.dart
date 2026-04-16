import 'package:flutter/material.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';
import 'package:fitmonster/features/diet/domain/services/calorie_calculator.dart';
import 'package:fitmonster/features/diet/domain/services/diet_service.dart';
import 'package:fitmonster/core/services/user_account_service.dart';
import 'package:fitmonster/core/widgets/custom_text_field.dart';
import 'package:fitmonster/core/widgets/custom_button.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/widgets/glass_card.dart';
import 'package:fitmonster/core/services/auth_service.dart';

/// Экран настройки профиля для расчета калорий
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  Goal _goal = Goal.maintain;
  bool _isLoading = true;

  List<String> _selectedAllergies = [];
  List<String> _selectedContraindications = [];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final userId = AuthService().currentUserId;
    final profile = await DietService.getUserProfile();
    final account =
        userId != null ? await UserAccountService().getByUserId(userId) : null;

    if (profile != null && mounted) {
      var allergies = List<String>.from(profile.allergies);
      if (allergies.isEmpty &&
          account != null &&
          account.allergies.isNotEmpty) {
        allergies = List<String>.from(account.allergies);
      }
      var contraindications = List<String>.from(profile.contraindications);
      if (contraindications.isEmpty &&
          account != null &&
          account.contraindications.isNotEmpty) {
        contraindications = List<String>.from(account.contraindications);
      }
      setState(() {
        _ageController.text = profile.age.toString();
        _heightController.text = profile.height.toString();
        _weightController.text = profile.weight.toString();
        _gender = profile.gender;
        _activityLevel = profile.activityLevel;
        _goal = profile.goal;
        _selectedAllergies = allergies;
        _selectedContraindications = contraindications;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          if (account != null && account.allergies.isNotEmpty) {
            _selectedAllergies = List<String>.from(account.allergies);
          }
          if (account != null && account.contraindications.isNotEmpty) {
            _selectedContraindications = List<String>.from(account.contraindications);
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _calculateAndShowResults() async {
    if (!_formKey.currentState!.validate()) return;

    // Получить текущий профиль для проверки изменений
    final existingProfile = await DietService.getUserProfile();
    final userId = AuthService().currentUserId ?? 'local_user';

    final profile = UserProfile(
      userId: userId,
      age: int.parse(_ageController.text),
      height: double.parse(_heightController.text),
      weight: double.parse(_weightController.text),
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
      createdAt: existingProfile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      allergies: _selectedAllergies,
      contraindications: _selectedContraindications,
    );

    final bmr = CalorieCalculator.calculateBMR(profile);
    final tdee = CalorieCalculator.calculateTDEE(profile);
    final targetCalories = CalorieCalculator.calculateTargetCalories(profile);
    final macros = CalorieCalculator.calculateMacros(profile);
    final bmi = CalorieCalculator.calculateBMI(profile.weight, profile.height);
    final bmiCategory = CalorieCalculator.getBMICategory(bmi);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: context.fm.scaffoldGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: context.fm.textPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Ваши результаты',
                            style: context.fm.titleStyle.copyWith(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // BMI
                _ResultCard(
                  title: 'Индекс массы тела (BMI)',
                  value: bmi.toStringAsFixed(1),
                  subtitle: bmiCategory.description,
                  description:
                      'Показатель соотношения веса и роста. Норма: 18.5-25',
                  icon: Icons.monitor_weight,
                  color: _getBMIColor(bmiCategory),
                ),
                const SizedBox(height: 16),

                // Калории
                _ResultCard(
                  title: 'Базовый метаболизм (BMR)',
                  value: '${bmr.round()} ккал',
                  subtitle: 'Калории в покое',
                  description:
                      'Минимум калорий для поддержания жизни в состоянии полного покоя',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),

                _ResultCard(
                  title: 'Общий расход (TDEE)',
                  value: '${tdee.round()} ккал',
                  subtitle: 'С учетом активности',
                  description:
                      'Сколько калорий вы тратите за день с учетом физической активности',
                  icon: Icons.directions_run,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),

                _ResultCard(
                  title: 'Целевые калории',
                  value: '$targetCalories ккал',
                  subtitle: _goal.description,
                  description:
                      'Рекомендуемое количество калорий в день для достижения вашей цели',
                  icon: Icons.flag,
                  color: context.fm.glowCyan,
                ),
                const SizedBox(height: 24),

                // Макронутриенты
                Text(
                  'Макронутриенты',
                  style: context.fm.titleStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Рекомендуемое распределение: 30% белки, 30% жиры, 40% углеводы',
                  style: context.fm.bodyStyle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _MacroCard(
                        label: 'Белки',
                        value: '${macros.protein}г',
                        percentage: '30%',
                        description: 'Строительный материал для мышц',
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MacroCard(
                        label: 'Жиры',
                        value: '${macros.fat}г',
                        percentage: '30%',
                        description: 'Энергия и гормоны',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MacroCard(
                        label: 'Углеводы',
                        value: '${macros.carbs}г',
                        percentage: '40%',
                        description: 'Основной источник энергии',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Сохранить профиль',
                  backgroundColor: context.fm.gradientHeaderTop,
                  textColor: Colors.white,
                  onPressed: () async {
                    // Проверить, изменились ли параметры
                    final hasChanges =
                        existingProfile == null ||
                        existingProfile.age != profile.age ||
                        existingProfile.height != profile.height ||
                        existingProfile.weight != profile.weight ||
                        existingProfile.gender != profile.gender ||
                        existingProfile.activityLevel !=
                            profile.activityLevel ||
                        existingProfile.goal != profile.goal;

                    if (hasChanges && existingProfile != null) {
                      // Спросить об очистке продуктов
                      final shouldClear = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Очистить записи?'),
                          content: const Text(
                            'Вы изменили параметры профиля. Хотите очистить записи о продуктах за сегодня?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Оставить'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Очистить'),
                            ),
                          ],
                        ),
                      );

                      if (shouldClear == true) {
                        await DietService.clearFoodLogsForDate(DateTime.now());
                      }
                    }

                    // Сохранить в Hive
                    await DietService.saveUserProfile(profile);
                    await UserAccountService().syncFromDietProfile(profile);

                    // TODO: Синхронизировать с Firestore

                    if (context.mounted) {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      navigator.pop(true); // Возвращаем true
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Профиль сохранен!'),
                          backgroundColor: context.fm.glowCyan,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBMIColor(BMICategory category) {
    switch (category) {
      case BMICategory.underweight:
        return Colors.blue;
      case BMICategory.normal:
        return context.fm.glowCyan;
      case BMICategory.overweight:
        return Colors.orange;
      case BMICategory.obese:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: context.fm.scaffoldGradient,
          ),
          child: Center(
            child: CircularProgressIndicator(color: context.fm.glowCyan),
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: context.fm.glowCyan,
          surface: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: context.fm.textPrimary),
          hintStyle: TextStyle(color: context.fm.textSecondary),
          floatingLabelStyle: TextStyle(color: context.fm.glowCyan),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: context.fm.glowCyan),
          ),
        ),
        textTheme: Theme.of(context).textTheme.copyWith(
          titleMedium: context.fm.titleStyle.copyWith(fontSize: 16),
          bodyMedium: context.fm.bodyStyle,
          bodyLarge: context.fm.bodyStyle,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Настройка профиля',
            style: context.fm.titleStyle.copyWith(fontSize: 20),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: context.fm.textPrimary),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: context.fm.scaffoldGradient,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Расскажите о себе',
                    style: context.fm.titleStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Эти данные помогут рассчитать вашу норму калорий',
                    style: context.fm.bodyStyle,
                  ),
                  const SizedBox(height: 16),
                  // Информационная подсказка
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: context.fm.glowCyan,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Мы используем научно обоснованную формулу Mifflin-St Jeor для точного расчета калорий',
                            style: context.fm.bodyStyle.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Возраст
                  CustomTextField(
                    label: 'Возраст',
                    hint: 'Введите ваш возраст',
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.cake),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите возраст';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 10 || age > 120) {
                        return 'Введите корректный возраст (10-120)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Рост
                  CustomTextField(
                    label: 'Рост (см)',
                    hint: 'Введите ваш рост',
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.height),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите рост';
                      }
                      final height = double.tryParse(value);
                      if (height == null || height < 100 || height > 250) {
                        return 'Введите корректный рост (100-250 см)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Вес
                  CustomTextField(
                    label: 'Вес (кг)',
                    hint: 'Введите ваш вес',
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.monitor_weight),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите вес';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight < 30 || weight > 300) {
                        return 'Введите корректный вес (30-300 кг)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Пол
                  Text(
                    'Пол',
                    style: context.fm.titleStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Gender>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: context.fm.textPrimary,
                      selectedBackgroundColor: context.fm.gradientHeaderTop,
                      selectedForegroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: Gender.male,
                        label: Text('Мужской'),
                        icon: Icon(Icons.male),
                      ),
                      ButtonSegment(
                        value: Gender.female,
                        label: Text('Женский'),
                        icon: Icon(Icons.female),
                      ),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (Set<Gender> newSelection) {
                      setState(() {
                        _gender = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Уровень активности
                  Text(
                    'Уровень активности',
                    style: context.fm.titleStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...ActivityLevel.values.map(
                    (level) => RadioListTile<ActivityLevel>(
                      activeColor: context.fm.gradientHeaderTop,
                      title: Text(
                        level.description,
                        style: context.fm.bodyStyle,
                      ),
                      value: level,
                      groupValue: _activityLevel,
                      onChanged: (value) {
                        setState(() {
                          _activityLevel = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Цель
                  Text(
                    'Ваша цель',
                    style: context.fm.titleStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Goal>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: context.fm.textPrimary,
                      selectedBackgroundColor: context.fm.gradientHeaderTop,
                      selectedForegroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: Goal.lose,
                        label: Text('Похудеть'),
                        icon: Icon(Icons.trending_down),
                      ),
                      ButtonSegment(
                        value: Goal.maintain,
                        label: Text('Поддержать'),
                        icon: Icon(Icons.trending_flat),
                      ),
                      ButtonSegment(
                        value: Goal.gain,
                        label: Text('Набрать'),
                        icon: Icon(Icons.trending_up),
                      ),
                    ],
                    selected: {_goal},
                    onSelectionChanged: (Set<Goal> newSelection) {
                      setState(() {
                        _goal = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Рассчитать',
                    onPressed: _calculateAndShowResults,
                    backgroundColor: context.fm.gradientHeaderTop,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ), // Scaffold
    ); // Theme
  }
}

/// Карточка результата в стиле приложения (GlassTheme)
class _ResultCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const _ResultCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.fm.bodyStyle.copyWith(
                        fontSize: 13,
                        color: context.fm.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: context.fm.titleStyle.copyWith(
                        fontSize: 20,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.fm.bodyStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: context.fm.glowCyan,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    description,
                    style: context.fm.bodyStyle.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка макронутриента в стиле приложения (GlassTheme)
class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final String percentage;
  final String description;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.percentage,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            label,
            style: context.fm.bodyStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.fm.titleStyle.copyWith(fontSize: 18, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            percentage,
            style: context.fm.bodyStyle.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: context.fm.bodyStyle.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
