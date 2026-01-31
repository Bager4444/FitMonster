import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import 'registration_page.dart';
import '../../../home/presentation/pages/home_page.dart';

/// Страница входа в систему
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    
                    // Логотип и приветствие
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.red],
                              ),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Text(
                            'Добро пожаловать!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textColor,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Войдите в свой аккаунт FitMonster',
                            style: TextStyle(
                              fontSize: 16,
                              color: themeProvider.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Поля ввода
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email или имя пользователя',
                      hint: 'Введите email или имя пользователя',
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmailOrUsername,
                      themeProvider: themeProvider,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Пароль',
                      hint: 'Введите пароль',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      themeProvider: themeProvider,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Запомнить меня и забыли пароль
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) => setState(() => _rememberMe = value ?? false),
                              activeColor: Colors.orange,
                            ),
                            Text(
                              'Запомнить меня',
                              style: TextStyle(
                                color: themeProvider.secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showForgotPasswordDialog,
                          child: Text(
                            'Забыли пароль?',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Кнопка входа
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Войти',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Разделитель
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: themeProvider.cardBorderColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'или',
                            style: TextStyle(
                              color: themeProvider.secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: themeProvider.cardBorderColor),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Быстрый вход (демо)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _quickLogin,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: themeProvider.cardBorderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flash_on,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Быстрый вход (демо)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Ссылка на регистрацию
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const RegistrationPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'Нет аккаунта? ',
                            style: TextStyle(
                              color: themeProvider.secondaryTextColor,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Зарегистрироваться',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeProvider themeProvider,
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(color: themeProvider.textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
            prefixIcon: Icon(icon, color: themeProvider.secondaryTextColor),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: themeProvider.cardColor,
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
  
  String? _validateEmailOrUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email или имя пользователя';
    }
    return null;
  }
  
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    return null;
  }
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final result = await AuthService.login(
        emailOrUsername: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (result.success) {
        // Показываем успешное сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
        
        // Переходим на главную страницу
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Показываем ошибку
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Произошла ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _quickLogin() async {
    // Быстрый вход для демонстрации
    setState(() => _isLoading = true);
    
    try {
      // Создаем демо-пользователя если его нет
      await AuthService.register(
        email: 'demo@fitmonster.com',
        username: 'demo_user',
        password: 'demo123',
        firstName: 'Демо',
        lastName: 'Пользователь',
      );
      
      // Входим под демо-пользователем
      final result = await AuthService.login(
        emailOrUsername: 'demo@fitmonster.com',
        password: 'demo123',
      );
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Быстрый вход выполнен успешно!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      // Игнорируем ошибки для демо
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановление пароля'),
        content: const Text(
          'Функция восстановления пароля будет доступна в следующих версиях приложения.\n\n'
          'Для демонстрации используйте "Быстрый вход".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}