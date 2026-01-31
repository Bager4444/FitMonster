import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import 'login_page.dart';

/// Страница регистрации
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  
  @override
  void dispose() {
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
                    // Кнопка назад
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: themeProvider.textColor,
                      ),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Заголовок
                    Text(
                      'Создать аккаунт',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Присоединяйтесь к FitMonster и начните свой путь к здоровью!',
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Поля ввода
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'example@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      themeProvider: themeProvider,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Имя пользователя',
                      hint: 'Уникальное имя',
                      icon: Icons.person_outline,
                      validator: _validateUsername,
                      themeProvider: themeProvider,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _firstNameController,
                            label: 'Имя',
                            hint: 'Ваше имя',
                            icon: Icons.badge_outlined,
                            themeProvider: themeProvider,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _lastNameController,
                            label: 'Фамилия',
                            hint: 'Ваша фамилия',
                            icon: Icons.badge_outlined,
                            themeProvider: themeProvider,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Пароль',
                      hint: 'Минимум 6 символов',
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
                    
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Подтвердите пароль',
                      hint: 'Повторите пароль',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                      themeProvider: themeProvider,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Согласие с условиями
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                          activeColor: Colors.orange,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                            child: Text(
                              'Я согласен с условиями использования и политикой конфиденциальности',
                              style: TextStyle(
                                color: themeProvider.secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Кнопка регистрации
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || !_agreeToTerms ? null : _register,
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
                                'Создать аккаунт',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Ссылка на вход
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'Уже есть аккаунт? ',
                            style: TextStyle(
                              color: themeProvider.secondaryTextColor,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Войти',
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
  
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
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
      
      if (result.success) {
        // Показываем успешное сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
        
        // Переходим на страницу входа
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
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
}