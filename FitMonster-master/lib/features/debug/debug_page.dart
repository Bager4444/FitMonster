import 'package:flutter/material.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// Отладочная страница для очистки данных
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отладка'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Отладочные функции',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Очистка данных',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Это действие удалит все данные приложения и создаст чистое состояние для тестирования новых функций.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isClearing ? null : _clearAllData,
                        icon: _isClearing 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever),
                        label: Text(_isClearing ? 'Очистка...' : 'Очистить все данные'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Информация',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'После очистки данных приложение перезапустится с чистым состоянием. Вы увидите новую систему регистрации и нулевые профили.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    setState(() => _isClearing = true);

    try {
      // Очищаем все данные Hive
      await HiveService.clearAll();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Все данные очищены! Перезапустите приложение.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Возвращаемся на главную страницу
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка очистки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }
}