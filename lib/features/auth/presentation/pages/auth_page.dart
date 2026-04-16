import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitmonster/core/constants/common_allergies.dart';
import 'package:fitmonster/core/constants/common_contraindications.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/core/app_navigator.dart';

/// Экран входа и регистрации: Deep Blue фон, glass-поля, кнопка с градиентом.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _allergiesOtherController = TextEditingController();
  final _contraindicationsOtherController = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  /// Отмечено «нет аллергий» — остальное игнорируем при регистрации.
  bool _noFoodAllergies = false;
  final Set<String> _selectedAllergies = {};
  bool _noContraindications = false;
  final Set<String> _selectedContraindications = {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _allergiesOtherController.dispose();
    _contraindicationsOtherController.dispose();
    super.dispose();
  }

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите почту';
    if (!_emailRegex.hasMatch(value.trim())) return 'Некорректный адрес почты';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 6) return 'Пароль не короче 6 символов';
    return null;
  }

  String? _validateConfirm(String? value) {
    final p = _validatePassword(value);
    if (p != null) return p;
    if (value != _passwordController.text) return 'Пароли не совпадают';
    return null;
  }

  List<String> _collectAllergiesForRegister() {
    if (_noFoodAllergies) return [];
    final out = <String>{..._selectedAllergies};
    final raw = _allergiesOtherController.text;
    for (final part in raw.split(',')) {
      final t = part.trim();
      if (t.isNotEmpty) out.add(t);
    }
    return out.toList();
  }

  List<String> _collectContraindicationsForRegister() {
    if (_noContraindications) return [];
    final out = <String>{..._selectedContraindications};
    final raw = _contraindicationsOtherController.text;
    for (final part in raw.split(',')) {
      final t = part.trim();
      if (t.isNotEmpty) out.add(t);
    }
    return out.toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    AuthResult result;
    if (_isRegister) {
      result = await _auth.registerWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        allergies: _collectAllergiesForRegister(),
        contraindications: _collectContraindicationsForRegister(),
      );
    } else {
      result = await _auth.signInWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
    setState(() => _loading = false);
    if (!mounted) return;
    if (result.success) {
      if (_isRegister && result.emailVerificationSent) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Подтвердите почту'),
            content: Text(
              'На ${_emailController.text.trim()} отправлено письмо со ссылкой для подтверждения.\n\n'
              'Перейдите по ссылке в письме — после этого в профиле статус сменится на «Почта подтверждена».\n\n'
              'Не пришло? Проверьте папку «Спам». В профиле можно нажать «Отправить письмо снова» (не чаще раза в 2 минуты).',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Понятно'),
              ),
            ],
          ),
        );
      }
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          appNavigatorKey.currentState?.pop<bool>(true);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Ошибка'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      body: Stack(
        children: [
          GlassTheme.buildScaffoldBackground(context),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isRegister ? 'Регистрация' : 'Вход',
                        style: context.fm.titleStyle.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegister
                            ? 'Создайте аккаунт. На почту придёт ссылка для подтверждения.'
                            : 'Войдите по почте и паролю',
                        style: context.fm.bodyStyle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      _buildGlassField(
                        controller: _emailController,
                        label: 'Почта',
                        hint: 'example@mail.ru',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      _buildGlassField(
                        controller: _passwordController,
                        label: 'Пароль',
                        hint: 'Не короче 6 символов',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: context.fm.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: _validatePassword,
                      ),
                      if (_isRegister) ...[
                        const SizedBox(height: 16),
                        _buildGlassField(
                          controller: _confirmPasswordController,
                          label: 'Повторите пароль',
                          hint: 'Повторите пароль',
                          obscureText: _obscureConfirm,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              color: context.fm.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: _validateConfirm,
                        ),
                        const SizedBox(height: 24),
                        _buildAllergiesBlock(),
                        const SizedBox(height: 28),
                        _buildContraindicationsBlock(),
                      ],
                      const SizedBox(height: 24),
                      _buildGradientButton(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                  _isRegister = !_isRegister;
                                  if (!_isRegister) {
                                    _noFoodAllergies = false;
                                    _selectedAllergies.clear();
                                    _allergiesOtherController.clear();
                                    _noContraindications = false;
                                    _selectedContraindications.clear();
                                    _contraindicationsOtherController.clear();
                                  }
                                }),
                        child: Text(
                          _isRegister ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Зарегистрироваться',
                          style: TextStyle(color: context.fm.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  appNavigatorKey.currentState?.pop<bool>(false);
                                });
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.fm.textPrimary,
                          side: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: const Text('Продолжить как гость'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  /// Стили чипов без FilterChipThemeData (совместимость со старым Flutter SDK).
  Widget _authFilterChip({
    required Widget label,
    required bool selected,
    required ValueChanged<bool>? onSelected,
  }) {
    return FilterChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      selectedColor: context.fm.gradientHeaderTop.withValues(alpha: 0.55),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: context.fm.textPrimary, fontSize: 13),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
    );
  }

  Widget _buildAllergiesBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              color: context.fm.glowCyan.withValues(alpha: 0.95),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Пищевые аллергии',
                style: context.fm.titleStyle.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Укажите, если есть — это попадёт в профиль и в советы ИИ. Можно пропустить.',
          style: context.fm.bodyStyle.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 12),
        _authFilterChip(
          label: const Text('Нет пищевых аллергий'),
          selected: _noFoodAllergies,
          onSelected: (v) {
            setState(() {
              _noFoodAllergies = v;
              if (v) {
                _selectedAllergies.clear();
                _allergiesOtherController.clear();
              }
            });
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CommonAllergies.labels.map((label) {
            final selected = !_noFoodAllergies && _selectedAllergies.contains(label);
            return _authFilterChip(
              label: Text(label),
              selected: selected,
              onSelected: _noFoodAllergies
                  ? null
                  : (v) {
                      setState(() {
                        if (v) {
                          _selectedAllergies.add(label);
                        } else {
                          _selectedAllergies.remove(label);
                        }
                      });
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _allergiesOtherController,
          enabled: !_noFoodAllergies,
          maxLines: 2,
          onChanged: (_) {
            if (_noFoodAllergies) {
              setState(() => _noFoodAllergies = false);
            }
          },
          style: TextStyle(color: context.fm.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Другое (через запятую)',
            hintText: 'Например: клубника, мёд',
            labelStyle: TextStyle(color: context.fm.textSecondary),
            hintStyle: TextStyle(color: context.fm.textSecondary.withValues(alpha: 0.7)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: context.fm.glowCyan, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildContraindicationsBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.medical_information_outlined,
              color: context.fm.glowCyan.withValues(alpha: 0.95),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Противопоказания к нагрузкам',
                style: context.fm.titleStyle.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Отметьте, если есть ограничения по здоровью. ИИ и рекомендации будут осторожнее. Можно пропустить.',
          style: context.fm.bodyStyle.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 12),
        _authFilterChip(
          label: const Text('Нет известных противопоказаний'),
          selected: _noContraindications,
          onSelected: (v) {
            setState(() {
              _noContraindications = v;
              if (v) {
                _selectedContraindications.clear();
                _contraindicationsOtherController.clear();
              }
            });
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CommonContraindications.labels.map((label) {
            final selected =
                !_noContraindications && _selectedContraindications.contains(label);
            return _authFilterChip(
              label: Text(label),
              selected: selected,
              onSelected: _noContraindications
                  ? null
                  : (v) {
                      setState(() {
                        if (v) {
                          _selectedContraindications.add(label);
                        } else {
                          _selectedContraindications.remove(label);
                        }
                      });
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contraindicationsOtherController,
          enabled: !_noContraindications,
          maxLines: 2,
          onChanged: (_) {
            if (_noContraindications) {
              setState(() => _noContraindications = false);
            }
          },
          style: TextStyle(color: context.fm.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Другое (через запятую)',
            hintText: 'Например: грыжа поясницы',
            labelStyle: TextStyle(color: context.fm.textSecondary),
            hintStyle: TextStyle(color: context.fm.textSecondary.withValues(alpha: 0.7)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: context.fm.glowCyan, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autocorrect: false,
      obscureText: obscureText,
      style: TextStyle(color: context.fm.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: context.fm.textSecondary),
        hintStyle: TextStyle(color: context.fm.textSecondary),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: context.fm.textSecondary, size: 22) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: context.fm.glowCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildGradientButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: context.fm.primaryButtonGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.fm.glowCyan.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _submit,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: _loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isRegister ? 'Зарегистрироваться' : 'Войти',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
