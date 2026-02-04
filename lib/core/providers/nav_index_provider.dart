import 'package:flutter/foundation.dart';

/// Индекс текущей вкладки нижней навигации (для плавающей капсулы).
class NavIndexProvider extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void setIndex(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }
}
