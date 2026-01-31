import 'package:flutter/material.dart';
import 'package:fitmonster/features/auth/services/auth_service.dart';
import 'package:fitmonster/features/home/presentation/pages/modern_home_page.dart';
import 'login_page.dart';

/// Современная страница регистрации с пошаговым процессом
class ModernRegistrationPage extends StatefulWidget {
  const ModernRegistrationPage({super.key});

  @override
  State<ModernRegistrationPage> createState() => _ModernRegistrationPageState();
}

class _ModernRegistrationPageState extends State<ModernRegistrationPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Контроллеры для полей ввода
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Ключи форм для каждого шага
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(), // Основная информация
                      _buildStep2(), // Личные данные
                      _buildStep3(), // Подтверждение
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  'Войти',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.person_add,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Создать аккаунт',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _getStepTitle(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildTextField(
              controller: _emailController,
              label: 'Email адрес',
              hint: 'example@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _usernameController,
              label: 'Имя пользователя',
              hint: 'Уникальное имя',
              icon: Icons.person_outline,
              validator: _validateUsername,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildTextField(
              controller: _passwordController,
              label: 'Пароль',
              hint: 'Минимум 6 символов',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Подтвердите пароль',
              hint: 'Повторите пароль',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              validator: _validateConfirmPassword,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step3FormKey,
        child: Column(
          children: [
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _firstNameController,
                    label: 'Имя (необязательно)',
                    hint: 'Ваше имя',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _lastNameController,
                    label: 'Фамилия (необязательно)',
                    hint: 'Ваша фамилия',
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                    activeColor: Colors.orange,
                    checkColor: Colors.white,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                      child: Text(
                        'Я согласен с условиями использования и политикой конфиденциальности FitMonster',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade300),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'После регистрации будет создан нулевой профиль, который вы сможете заполнить позже',
                      style: TextStyle(
                        color: Colors.green.shade100,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Назад'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_getButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Основная информация';
      case 1:
        return 'Создайте пароль';
      case 2:
        return 'Завершение регистрации';
      default:
        return '';
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
      case 1:
        return 'Продолжить';
      case 2:
        return 'Создать аккаунт';
      default:
        return 'Далее';
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _nextStep() async {
    bool isValid = false;
    
    switch (_currentStep) {
      case 0:
        isValid = _step1FormKey.currentState?.validate() ?? false;
        break;
      case 1:
        isValid = _step2FormKey.currentState?.validate() ?? false;
        break;
      case 2:
        isValid = _step3FormKey.currentState?.validate() ?? false && _agreeToTerms;
        break;
    }

    if (!isValid) {
      if (_currentStep == 2 && !_agreeToTerms) {
        _showSnackBar('Необходимо согласиться с условиями использования', Colors.red);
      }
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _register();
    }
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim().isEmpty 
            ? null 
            : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty 
            ? null 
            : _lastNameController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          _showSnackBar(result.message, Colors.green);
          
          // Переходим на главную страницу
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ModernHomePage()),
            (route) => false,
          );
        } else {
          _showSnackBar(result.message, Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Произошла ошибка: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Валидаторы
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Некорректный email адрес';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя пользователя';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value)) {
      return 'Имя должно содержать 3-20 символов (буквы, цифры, _)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Подтвердите пароль';
    }
    if (value != _passwordController.text) {
      return 'Пароли не совпадают';
    }
    return null;
  }
}