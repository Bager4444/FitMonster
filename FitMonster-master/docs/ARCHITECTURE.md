# 🏗️ Архитектура FitMonster

## 📋 Содержание

1. [Общий обзор](#общий-обзор)
2. [Слои архитектуры](#слои-архитектуры)
3. [Модульная структура](#модульная-структура)
4. [Паттерны проектирования](#паттерны-проектирования)
5. [Управление состоянием](#управление-состоянием)
6. [База данных](#база-данных)
7. [ML/AI компоненты](#mlai-компоненты)

## 🎯 Общий обзор

FitMonster построен на принципах **Clean Architecture** с четким разделением ответственности между слоями и модулями.

### Основные принципы:
- **Разделение ответственности** - каждый модуль отвечает за свою область
- **Инверсия зависимостей** - высокоуровневые модули не зависят от низкоуровневых
- **Тестируемость** - все компоненты легко тестируются
- **Масштабируемость** - легко добавлять новые функции

## 🏛️ Слои архитектуры

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Pages, Widgets, State Management) │
├─────────────────────────────────────┤
│           Domain Layer              │
│    (Models, Services, Use Cases)    │
├─────────────────────────────────────┤
│            Data Layer               │
│  (Repositories, DataSources, APIs)  │
└─────────────────────────────────────┘
```

### 1. Presentation Layer (UI)
**Ответственность**: Отображение данных и обработка пользовательского ввода

**Компоненты**:
- **Pages** - экраны приложения
- **Widgets** - переиспользуемые UI компоненты
- **Providers** - управление состоянием UI

**Пример структуры**:
```
features/exercises/presentation/
├── pages/
│   ├── exercise_camera_page.dart
│   ├── exercise_detail_page.dart
│   └── exercises_page.dart
├── widgets/
│   ├── pose_painter.dart
│   ├── countdown_widget.dart
│   └── workout_results_dialog.dart
└── providers/
    └── exercise_provider.dart
```

### 2. Domain Layer (Бизнес-логика)
**Ответственность**: Основная бизнес-логика приложения

**Компоненты**:
- **Models** - модели данных
- **Services** - бизнес-сервисы
- **Use Cases** - варианты использования

**Пример структуры**:
```
features/exercises/domain/
├── models/
│   ├── exercise.dart
│   ├── workout_session.dart
│   └── workout_complex.dart
└── services/
    ├── workout_service.dart
    └── exercise_analyzer.dart
```

### 3. Data Layer (Данные)
**Ответственность**: Управление данными и их источниками

**Компоненты**:
- **Repositories** - абстракция доступа к данным
- **DataSources** - конкретные источники данных
- **Services** - сервисы для работы с данными

**Пример структуры**:
```
features/diet/data/
├── repositories/
│   └── food_repository.dart
├── datasources/
│   └── local_food_datasource.dart
└── services/
    └── food_database_service.dart
```

## 🧩 Модульная структура

### Core Module (Общие компоненты)
```
core/
├── constants/          # Константы приложения
│   └── app_constants.dart
├── services/           # Общие сервисы
│   ├── hive_service.dart
│   ├── auth_service.dart
│   └── connectivity_service.dart
├── theme/              # Темы и стили
│   ├── app_theme.dart
│   └── theme_provider.dart
├── widgets/            # Переиспользуемые виджеты
│   ├── custom_button.dart
│   └── loading_overlay.dart
└── utils/              # Утилиты
    └── validators.dart
```

### Feature Modules (Функциональные модули)

#### 1. Auth Module (Аутентификация)
```
features/auth/
├── data/
│   └── services/
│       └── auth_service.dart
├── domain/
│   └── models/
│       └── user.dart
└── presentation/
    └── pages/
        ├── login_page.dart
        ├── register_page.dart
        └── welcome_page.dart
```

#### 2. Exercises Module (Упражнения)
```
features/exercises/
├── data/
│   └── exercises_database.dart
├── domain/
│   ├── models/
│   │   ├── exercise.dart
│   │   ├── workout_session.dart
│   │   └── workout_complex.dart
│   └── services/
│       └── workout_service.dart
├── presentation/
│   ├── pages/
│   │   ├── exercise_camera_page.dart
│   │   ├── exercises_page.dart
│   │   └── workout_history_page.dart
│   └── widgets/
│       ├── pose_painter.dart
│       └── countdown_widget.dart
└── services/
    ├── improved_rep_counter.dart
    ├── pose_detection_service.dart
    └── plank_timer_service.dart
```

#### 3. Diet Module (Питание)
```
features/diet/
├── data/
│   ├── services/
│   │   └── food_database_service.dart
│   └── datasources/
│       └── local_food_datasource.dart
├── domain/
│   └── models/
│       ├── food_item.dart
│       ├── recipe.dart
│       └── user_profile.dart
└── presentation/
    └── pages/
        ├── food_search_page.dart
        ├── diet_dashboard_page.dart
        └── profile_setup_page.dart
```

## 🎨 Паттерны проектирования

### 1. Singleton Pattern
Используется для сервисов, которые должны иметь единственный экземпляр:

```dart
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();
  
  // Методы сервиса...
}
```

### 2. Repository Pattern
Абстракция доступа к данным:

```dart
abstract class FoodRepository {
  Future<List<FoodItem>> searchFoods(String query);
  Future<FoodItem?> getFoodById(String id);
}

class FoodRepositoryImpl implements FoodRepository {
  final LocalFoodDatasource _localDatasource;
  
  FoodRepositoryImpl(this._localDatasource);
  
  @override
  Future<List<FoodItem>> searchFoods(String query) {
    return _localDatasource.searchFoods(query);
  }
}
```

### 3. Factory Pattern
Создание объектов на основе типа:

```dart
class ExerciseFactory {
  static Exercise createExercise(String type) {
    switch (type) {
      case 'squats':
        return SquatsExercise();
      case 'plank':
        return PlankExercise();
      default:
        throw ArgumentError('Unknown exercise type: $type');
    }
  }
}
```

### 4. Observer Pattern
Реализован через Provider для управления состоянием:

```dart
class ExerciseProvider extends ChangeNotifier {
  int _repCount = 0;
  
  int get repCount => _repCount;
  
  void incrementReps() {
    _repCount++;
    notifyListeners(); // Уведомляем слушателей об изменении
  }
}
```

## 📊 Управление состоянием

### Provider Pattern
Основной паттерн для управления состоянием:

```dart
// В main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ExerciseProvider()),
  ],
  child: MyApp(),
)

// В виджете
Consumer<ExerciseProvider>(
  builder: (context, exerciseProvider, child) {
    return Text('Повторений: ${exerciseProvider.repCount}');
  },
)
```

### Локальное состояние
Для простых случаев используется StatefulWidget:

```dart
class CountdownWidget extends StatefulWidget {
  @override
  _CountdownWidgetState createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  int _countdown = 3;
  Timer? _timer;
  
  // Логика управления состоянием...
}
```

## 💾 База данных

### Hive (NoSQL локальная БД)
Основная база данных для локального хранения:

```dart
// Модель с аннотациями Hive
@HiveType(typeId: 1)
class FoodItem extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final double calories;
  
  // Конструктор и методы...
}
```

### Структура данных:
```
Hive Boxes:
├── user          # Профили пользователей
├── workouts      # Сессии тренировок
├── foods         # База продуктов (10000+ записей)
├── recipes       # Рецепты
├── favorites     # Избранные продукты
├── settings      # Настройки приложения
└── stats         # Статистика пользователя
```

### Инициализация базы данных:
```dart
class HiveService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Регистрация адаптеров
    Hive.registerAdapter(FoodItemAdapter());
    Hive.registerAdapter(RecipeAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    
    // Открытие боксов
    await Hive.openBox<FoodItem>('foods');
    await Hive.openBox<Recipe>('recipes');
    await Hive.openBox('user');
  }
}
```

## 🤖 ML/AI компоненты

### Google ML Kit Pose Detection
Основа для анализа упражнений:

```dart
class PoseDetectionService {
  late PoseDetector _poseDetector;
  
  void initialize() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,    // Для реального времени
      model: PoseDetectionModel.base,    // Быстрая модель
    );
    _poseDetector = PoseDetector(options: options);
  }
  
  Future<List<Pose>> detectPoses(InputImage image) async {
    return await _poseDetector.processImage(image);
  }
}
```

### Анализ упражнений
Система анализа движений:

```dart
class ImprovedRepCounter {
  // Конфигурации для разных упражнений
  final Map<String, ExerciseConfig> _configs = {
    'squats': ExerciseConfig(
      primaryJoint: JointType.knee,
      downAngle: 130,
      upAngle: 170,
      exerciseType: ExerciseType.dynamic,
    ),
    'plank': ExerciseConfig(
      primaryJoint: JointType.elbow,
      downAngle: 160,
      upAngle: 180,
      exerciseType: ExerciseType.static, // Статическое упражнение
    ),
  };
  
  RepCountResult analyzePose(Pose pose) {
    final config = _configs[_currentExerciseType];
    
    if (config.exerciseType == ExerciseType.static) {
      return _analyzeStaticExercise(pose, config);
    } else {
      return _analyzeDynamicExercise(pose, config);
    }
  }
}
```

### Оптимизация производительности
- **FPS ограничение**: 8 FPS для ML анализа
- **Пропуск кадров**: Обработка каждого 2-го кадра
- **Кэширование**: Кэширование вычислений углов
- **Умное сглаживание**: Фильтрация шумных данных

## 🔄 Жизненный цикл данных

### Поток данных в упражнениях:
```
Camera → ML Kit → Pose Detection → Rep Counter → UI Update
   ↓
Workout Service → Hive Database → Statistics
```

### Поток данных в питании:
```
User Input → Food Search → Database Query → Results Display
     ↓
Food Selection → Calorie Calculation → Profile Update
```

## 🧪 Тестируемость

### Архитектура способствует тестированию:
- **Инъекция зависимостей** через конструкторы
- **Мокирование** сервисов и репозиториев
- **Изоляция** бизнес-логики от UI

### Пример теста:
```dart
class MockWorkoutService extends Mock implements WorkoutService {}

void main() {
  group('ExerciseProvider Tests', () {
    late ExerciseProvider provider;
    late MockWorkoutService mockService;
    
    setUp(() {
      mockService = MockWorkoutService();
      provider = ExerciseProvider(mockService);
    });
    
    test('should increment rep count', () {
      // Arrange
      expect(provider.repCount, 0);
      
      // Act
      provider.incrementReps();
      
      // Assert
      expect(provider.repCount, 1);
    });
  });
}
```

## 📈 Масштабируемость

### Горизонтальное масштабирование:
- Добавление новых упражнений через конфигурацию
- Новые модули питания (планы питания, рецепты)
- Интеграция с внешними API

### Вертикальное масштабирование:
- Оптимизация ML алгоритмов
- Улучшение точности распознавания
- Кэширование и предзагрузка данных

---

*Эта архитектура обеспечивает надежность, производительность и возможность развития FitMonster.*