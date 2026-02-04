import 'package:flutter/material.dart';

/// Глобальный ключ навигатора для закрытия экранов вне контекста (обход _debugLocked).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'AppNavigator');
