import 'package:flutter/material.dart';

/// Виджет обратного отсчёта для начала тренировки
class CountdownWidget extends StatefulWidget {
  final VoidCallback onCountdownComplete;
  final int startValue;

  const CountdownWidget({
    super.key,
    required this.onCountdownComplete,
    this.startValue = 3,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  int _currentValue = 3;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 CountdownWidget initState вызван');
    _currentValue = widget.startValue;
    
    // Анимация масштабирования для цифр
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Анимация пульсации для круга
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _startCountdown();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startCountdown() async {
    debugPrint('⏰ CountdownWidget: Начинаем отсчёт от ${widget.startValue}');
    // Запускаем пульсацию
    _pulseController.repeat(reverse: true);
    
    // Обратный отсчёт
    for (int i = widget.startValue; i >= 1; i--) {
      if (!mounted) return;
      
      debugPrint('⏰ CountdownWidget: Показываем цифру $i');
      setState(() {
        _currentValue = i;
      });
      
      // Анимация появления цифры
      _scaleController.reset();
      _scaleController.forward();
      
      // Быстрый переход к следующей цифре
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Показываем "НАЧАЛИ!"
    if (mounted) {
      debugPrint('⏰ CountdownWidget: Показываем НАЧАЛИ!');
      setState(() {
        _currentValue = 0; // 0 означает "НАЧАЛИ!"
        _isComplete = true;
      });
      
      _scaleController.reset();
      _scaleController.forward();
      
      await Future.delayed(const Duration(milliseconds: 400));
      
      debugPrint('⏰ CountdownWidget: Вызываем onCountdownComplete');
      // Вызываем callback
      widget.onCountdownComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleController, _pulseController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * _pulseAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isComplete 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  border: Border.all(
                    color: _isComplete ? Colors.green : Colors.blue,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isComplete ? Colors.green : Colors.blue)
                          .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: _currentValue > 0
                      ? Text(
                          '$_currentValue',
                          style: const TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        )
                      : const Text(
                          'НАЧАЛИ!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}