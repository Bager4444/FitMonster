# 🏋️ FitMonster - Документация проекта

## 📋 Содержание

1. [Обзор проекта](#обзор-проекта)
2. [Архитектура](#архитектура)
3. [Основные модули](#основные-модули)
4. [Установка и запуск](#установка-и-запуск)
5. [API документация](#api-документация)
6. [Тестирование](#тестирование)
7. [Развертывание](#развертывание)

## 🎯 Обзор проекта

**FitMonster** - это мобильное приложение для фитнеса с AI-анализом упражнений и системой питания.

### Ключевые возможности:
- 🤖 **AI-анализ упражнений** с использованием ML Kit Pose Detection
- ⏱️ **Точный подсчет повторений** и времени для статических упражнений
- 🍎 **База данных продуктов** с поиском и калорийностью
- 📊 **Система прогресса** с опытом и достижениями
- 🎨 **Современный UI** с темной/светлой темой
- 💾 **Локальное хранение** данных с Hive

### Технологический стек:
- **Frontend**: Flutter 3.x
- **ML/AI**: Google ML Kit Pose Detection
- **База данных**: Hive (локальная NoSQL)
- **Архитектура**: Clean Architecture + Provider
- **Платформы**: Android, iOS, Web

## 🏗️ Архитектура

Проект построен на принципах **Clean Architecture** с разделением на слои:

```
lib/
├── core/                    # Общие компоненты
│   ├── constants/          # Константы приложения
│   ├── services/           # Общие сервисы
│   ├── theme/              # Темы и стили
│   └── widgets/            # Переиспользуемые виджеты
├── features/               # Основные модули
│   ├── auth/               # Аутентификация
│   ├── exercises/          # Упражнения и тренировки
│   ├── diet/               # Питание и продукты
│   ├── profile/            # Профиль пользователя
│   └── home/               # Главная страница
└── main.dart               # Точка входа
```

### Слои архитектуры:
1. **Presentation Layer** - UI компоненты (Pages, Widgets)
2. **Domain Layer** - Бизнес-логика (Models, Services)
3. **Data Layer** - Источники данных (Repositories, DataSources)

## 🧩 Основные модули

### 1. 🏋️ Модуль упражнений (`features/exercises/`)

**Назначение**: Анализ упражнений с помощью камеры и AI

**Ключевые компоненты**:
- `ExerciseCameraPage` - основная страница с камерой
- `ImprovedRepCounter` - счетчик повторений с поддержкой статических упражнений
- `PoseDetector` - анализ позы через ML Kit
- `WorkoutService` - управление тренировками

**Поддерживаемые упражнения**:
- Приседания (динамические)
- Отжимания (динамические) 
- Планка (статическая - подсчет времени)
- Боковая планка (статическая)
- Выпады (динамические)

### 2. 🍎 Модуль питания (`features/diet/`)

**Назначение**: База данных продуктов и подсчет калорий

**Ключевые компоненты**:
- `FoodDatabaseService` - работа с базой продуктов
- `FoodItem` - модель продукта с КБЖУ
- `Recipe` - модель рецепта
- `FoodSearchPage` - поиск продуктов

**Возможности**:
- Поиск по 10000+ продуктов
- Подсчет калорий и КБЖУ
- Избранные продукты
- Рецепты с инструкциями

### 3. 👤 Модуль профиля (`features/profile/`)

**Назначение**: Управление профилем пользователя и статистикой

**Ключевые компоненты**:
- `ProfilePage` - страница профиля
- `ExperienceService` - система опыта
- `StatsService` - статистика тренировок
- `LeaderboardPage` - таблица лидеров

### 4. 🔐 Модуль аутентификации (`features/auth/`)

**Назначение**: Регистрация и вход пользователей

**Ключевые компоненты**:
- `AuthService` - управление аутентификацией
- `LoginPage` / `RegisterPage` - страницы входа/регистрации
- `User` - модель пользователя

## 🚀 Установка и запуск

### Требования:
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Android SDK (для Android)
- Xcode (для iOS)

### Установка:

1. **Клонирование репозитория**:
```bash
git clone https://github.com/Bager4444/FitMonster.git
cd FitMonster
```

2. **Установка зависимостей**:
```bash
flutter pub get
```

3. **Генерация кода**:
```bash
flutter packages pub run build_runner build
```

4. **Запуск приложения**:
```bash
flutter run
```

### Конфигурация:

**Android**: Настройте `android/app/build.gradle` для минимальной версии SDK 21+

**iOS**: Настройте `ios/Runner/Info.plist` для доступа к камере:
```xml
<key>NSCameraUsageDescription</key>
<string>Приложению нужен доступ к камере для анализа упражнений</string>
```

## 📚 API документация

### Core Services

#### HiveService
Управление локальной базой данных:
```dart
// Инициализация
await HiveService.initialize();

// Сохранение данных
await HiveService.put(box: 'user', key: 'profile', value: userProfile);

// Получение данных
final profile = HiveService.get(box: 'user', key: 'profile');
```

#### AuthService
Аутентификация пользователей:
```dart
// Регистрация
final user = await AuthService.register(
  username: 'user123',
  email: 'user@example.com', 
  password: 'password123',
  country: 'RU'
);

// Вход
final user = await AuthService.login('user123', 'password123');

// Текущий пользователь
final currentUser = await AuthService.getCurrentUser();
```

### Exercise Services

#### ImprovedRepCounter
Подсчет повторений и времени:
```dart
final repCounter = ImprovedRepCounter();

// Настройка упражнения
repCounter.setExerciseType('squats'); // или 'plank' для статических

// Анализ позы
final result = repCounter.analyzePose(pose);
print('Повторений: ${result.repCount}');
print('Обратная связь: ${result.feedback}');
```

#### WorkoutService
Управление тренировками:
```dart
final workoutService = WorkoutService();

// Начало тренировки
final session = await workoutService.startWorkout(
  exercise: exercise,
  targetReps: 10
);

// Добавление повторения
await workoutService.addRep(session, formScore: 85.0, isCorrect: true);

// Завершение тренировки
final completedSession = await workoutService.completeWorkout(session);
```

### Diet Services

#### FoodDatabaseService
Работа с продуктами:
```dart
final foodService = FoodDatabaseService();

// Поиск продуктов
final foods = await foodService.searchFoods('яблоко');

// Получение продукта по ID
final food = await foodService.getFoodById('apple_001');

// Добавление в избранное
await foodService.addToFavorites('apple_001');
```

## 🧪 Тестирование

### Запуск тестов:
```bash
# Все тесты
flutter test

# Конкретный тест
flutter test test/services/rep_counter_test.dart

# Тесты производительности
flutter test test/performance/
```

### Типы тестов:
- **Unit тесты** - тестирование отдельных функций
- **Widget тесты** - тестирование UI компонентов  
- **Integration тесты** - тестирование пользовательских сценариев
- **Performance тесты** - тестирование производительности ML

## 📱 Развертывание

### Android:
```bash
# Сборка APK
flutter build apk --release

# Сборка App Bundle
flutter build appbundle --release
```

### iOS:
```bash
# Сборка для iOS
flutter build ios --release
```

### Web:
```bash
# Сборка для Web
flutter build web --release
```

## 🔧 Конфигурация

### Основные настройки в `lib/core/constants/app_constants.dart`:
```dart
class AppConstants {
  static const String appName = 'FitMonster';
  static const String version = '1.0.0';
  static const int targetFPS = 8; // Для ML анализа
  static const int targetReps = 5; // По умолчанию
}
```

### Настройки ML Kit:
- **Режим**: Stream (для реального времени)
- **Модель**: Base (для скорости)
- **FPS**: 8 (оптимизировано для производительности)

## 📊 Мониторинг и аналитика

### Логирование:
Приложение использует встроенное логирование Flutter:
```dart
print('✅ Успешная операция');
print('❌ Ошибка: $error');
print('⚠️ Предупреждение');
```

### Метрики производительности:
- FPS анализа ML Kit
- Время отклика UI
- Использование памяти
- Точность распознавания упражнений

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для новой функции
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

## 📄 Лицензия

MIT License - см. файл LICENSE для деталей.

## 📞 Поддержка

- **GitHub Issues**: [Создать issue](https://github.com/Bager4444/FitMonster/issues)
- **Email**: support@fitmonster.app
- **Документация**: [docs/](./docs/)

---

*Последнее обновление: Февраль 2026*