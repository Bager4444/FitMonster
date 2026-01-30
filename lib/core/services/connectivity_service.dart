import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Сервис проверки интернет-соединения
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isOnline = true;
  bool _isInitialized = false;
  
  /// Текущее состояние подключения
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isInitialized => _isInitialized;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      _isInitialized = true;
      
      _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    } catch (e) {
      print('⚠️ ConnectivityService init error: $e');
      _isOnline = true; // Предполагаем онлайн при ошибке
      _isInitialized = true;
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    
    _isOnline = results.any((r) => 
      r == ConnectivityResult.wifi || 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet
    );
    
    if (wasOnline != _isOnline) {
      print('🌐 Connectivity changed: ${_isOnline ? "online" : "offline"}');
      notifyListeners();
    }
  }

  /// Проверить соединение прямо сейчас
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return _isOnline;
    } catch (e) {
      print('⚠️ ConnectivityService check error: $e');
      return _isOnline; // Вернуть последнее известное состояние
    }
  }

  /// Дождаться инициализации
  Future<void> waitForInit() async {
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
