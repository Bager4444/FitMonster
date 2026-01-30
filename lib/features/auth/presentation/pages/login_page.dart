import 'package:flutter/material.dart';
import 'package:fitmonster/core/services/auth_service.dart';

/// Простая страница входа
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'FitMonster',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () async {
                  // Простая авторизация - создаем нового пользователя
                  final userId = await AuthService().createUser();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/home');
                  }
                },
                child: const Text('Войти как гость'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}