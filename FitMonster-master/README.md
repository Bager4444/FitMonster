# 🏋️ FitMonster

**AI-powered fitness app with intelligent exercise recognition and nutrition tracking**

[![Flutter](https://img.shields.io/badge/Flutter-3.16.0-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0.0-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey.svg)](https://flutter.dev/)

## 🎯 Особенности

- 🤖 **AI-анализ упражнений** с использованием Google ML Kit
- ⏱️ **Точный подсчет повторений** и времени для статических упражнений
- 🍎 **База данных продуктов** с 10000+ наименований
- 📊 **Система прогресса** с опытом и достижениями
- 🎨 **Современный UI** с поддержкой темной темы
- 💾 **Локальное хранение** без необходимости интернета

## 🚀 Быстрый старт

### Требования
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code

### Установка
```bash
git clone https://github.com/Bager4444/FitMonster.git
cd FitMonster
flutter pub get
flutter run
```

## 📱 Поддерживаемые упражнения

### Динамические (подсчет повторений):
- 🏃 Приседания
- 💪 Отжимания
- 🦵 Выпады
- 🤸 Jumping Jacks

### Статические (подсчет времени):
- 🧘 Планка
- 🔄 Боковая планка

## 🍎 Система питания

- Поиск по базе продуктов
- Подсчет калорий и КБЖУ
- Избранные продукты
- Рецепты с инструкциями

## 🏗️ Архитектура

Проект построен на принципах **Clean Architecture**:

```
├── core/           # Общие компоненты
├── features/       # Основные модули
│   ├── auth/       # Аутентификация
│   ├── exercises/  # Упражнения и тренировки
│   ├── diet/       # Питание и продукты
│   └── profile/    # Профиль пользователя
└── main.dart       # Точка входа
```

## 🧪 Тестирование

```bash
flutter test                    # Unit тесты
flutter test integration_test/  # Integration тесты
```

## 📚 Документация

- [📖 Полная документация](docs/README.md)
- [🏗️ Архитектура](docs/ARCHITECTURE.md)
- [📡 API](docs/API.md)
- [🚀 Развертывание](docs/DEPLOYMENT.md)
- [👨‍💻 Разработка](docs/DEVELOPMENT.md)

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для новой функции
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

## 📄 Лицензия

MIT License - см. [LICENSE](LICENSE) для деталей.

## 📞 Поддержка

- **Issues**: [GitHub Issues](https://github.com/Bager4444/FitMonster/issues)
- **Email**: support@fitmonster.app

---

**Сделано с ❤️ для здорового образа жизни**