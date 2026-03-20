# System Patterns — FitMonster

## Архитектура
Feature-first структура с разделением на слои (domain / data / presentation).

```
lib/
├── main.dart                  # Точка входа, инициализация Firebase + Hive
├── core/                      # Общие компоненты
│   ├── app_navigator.dart     # Навигация (bottom nav)
│   ├── constants/             # Константы приложения
│   ├── models/                # Общие модели (UserStats)
│   ├── providers/             # Провайдеры состояния (nav_index)
│   ├── services/              # Сервисы: auth, hive, connectivity, stats
│   ├── theme/                 # Темы: app_theme, glass_theme, theme_provider
│   └── widgets/               # Переиспользуемые виджеты
└── features/
    ├── ai/                    # AI-ассистент (DeepSeek API)
    ├── auth/                  # Авторизация (Firebase Auth)
    ├── diet/                  # Диета и трекер питания
    ├── exercises/             # Упражнения + ML-анализ
    ├── home/                  # Главный экран
    └── profile/               # Профиль и статистика
```

## Паттерны

### State Management
- **Provider** — основной паттерн управления состоянием
- `ThemeProvider` — переключение тёмной/светлой темы
- `NavIndexProvider` — индекс нижней навигации

### Хранение данных
- **Hive** — локальное хранилище (офлайн, быстро)
- **Firebase Firestore** — облачная синхронизация
- **SharedPreferences** — настройки пользователя

### Навигация
- Bottom Navigation Bar (4 вкладки: Упражнения, Диета, Профиль, AI)
- `app_navigator.dart` — центральный роутер

### ML Pipeline (Упражнения)
```
Camera frame → InputImage → PoseDetector (ML Kit) → Pose landmarks
→ Angle calculation → Rep counting → Technique feedback → UI overlay
```

### Темизация
- `app_theme.dart` — Material 3 тема (светлая + тёмная)
- `glass_theme.dart` — стеклянный эффект для карточек
- Оба варианта темы всегда синхронизированы

## Связи подсистем
- `AuthService` → Firebase Auth → `HiveService` (локальный кэш профиля)
- `StatsService` → Hive → `ProfilePresentation`
- `ExercisesFeature` → Camera → MLKit → `RepCounter` → `StatsService`
- `DietFeature` → Hive (продукты) → `StatsService`
