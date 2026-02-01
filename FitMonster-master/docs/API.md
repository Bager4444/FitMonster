# 📡 API Документация FitMonster

## 📋 Содержание

1. [Обзор API](#обзор-api)
2. [Core Services](#core-services)
3. [Auth Services](#auth-services)
4. [Exercise Services](#exercise-services)
5. [Diet Services](#diet-services)
6. [Profile Services](#profile-services)
7. [Модели данных](#модели-данных)
8. [Примеры использования](#примеры-использования)

## 🎯 Обзор API

FitMonster использует внутренние API сервисы для управления данными и бизнес-логикой. Все API построены на принципах асинхронности и обработки ошибок.

### Общие принципы:
- **Асинхронность**: Все методы возвращают `Future<T>`
- **Обработка ошибок**: Использование try-catch блоков
- **Типизация**: Строгая типизация всех параметров и возвращаемых значений
- **Null Safety**: Поддержка Dart Null Safety

## 🔧 Core Services

### HiveService
Сервис для работы с локальной базой данных Hive.

#### Методы:

##### `initialize()`
Инициализация Hive и регистрация адаптеров.
```dart
static Future<void> initialize()
```

**Пример**:
```dart
await HiveService.initialize();
```

##### `put()`
Сохранение данных в указанный бокс.
```dart
static Future<void> put({
  required String box,
  required String key,
  required dynamic value,
})
```

**Параметры**:
- `box` - название бокса
- `key` - ключ для сохранения
- `value` - значение для сохранения

**Пример**:
```dart
await HiveService.put(
  box: 'user',
  key: 'profile_123',
  value: userProfile,
);
```

##### `get()`
Получение данных из бокса.
```dart
static T? get<T>({
  required String box,
  required String key,
  T? defaultValue,
})
```

**Параметры**:
- `box` - название бокса
- `key` - ключ для получения
- `defaultValue` - значение по умолчанию

**Возвращает**: Значение типа `T` или `null`

**Пример**:
```dart
final profile = HiveService.get<UserProfile>(
  box: 'user',
  key: 'profile_123',
  defaultValue: UserProfile.empty(),
);
```

## 🔐 Auth Services

### AuthService
Сервис аутентификации пользователей.

#### Методы:

##### `register()`
Регистрация нового пользователя.
```dart
static Future<User?> register({
  required String username,
  required String email,
  required String password,
  required String country,
})
```

**Параметры**:
- `username` - имя пользователя (уникальное)
- `email` - email адрес (уникальный)
- `password` - пароль (минимум 6 символов)
- `country` - код страны

**Возвращает**: `User?` - объект пользователя или `null` при ошибке

**Пример**:
```dart
final user = await AuthService.register(
  username: 'john_doe',
  email: 'john@example.com',
  password: 'securePassword123',
  country: 'RU',
);

if (user != null) {
  print('Пользователь зарегистрирован: ${user.username}');
} else {
  print('Ошибка регистрации');
}
```

##### `login()`
Вход пользователя в систему.
```dart
static Future<User?> login(String usernameOrEmail, String password)
```

**Параметры**:
- `usernameOrEmail` - имя пользователя или email
- `password` - пароль

**Возвращает**: `User?` - объект пользователя или `null` при неверных данных

**Пример**:
```dart
final user = await AuthService.login('john_doe', 'securePassword123');
if (user != null) {
  print('Добро пожаловать, ${user.username}!');
}
```

##### `getCurrentUser()`
Получение текущего авторизованного пользователя.
```dart
static Future<User?> getCurrentUser()
```

**Возвращает**: `User?` - текущий пользователь или `null`

##### `logout()`
Выход из системы.
```dart
static Future<void> logout()
```

##### `isLoggedIn()`
Проверка авторизации.
```dart
static Future<bool> isLoggedIn()
```

**Возвращает**: `bool` - статус авторизации

## 🏋️ Exercise Services

### WorkoutService
Сервис управления тренировками.

#### Методы:

##### `startWorkout()`
Начало новой тренировки.
```dart
Future<WorkoutSession> startWorkout({
  required Exercise exercise,
  required int targetReps,
})
```

**Параметры**:
- `exercise` - объект упражнения
- `targetReps` - целевое количество повторений

**Возвращает**: `WorkoutSession` - сессия тренировки

**Пример**:
```dart
final workoutService = WorkoutService();
final exercise = Exercise(id: 'squats', nameRu: 'Приседания');

final session = await workoutService.startWorkout(
  exercise: exercise,
  targetReps: 10,
);
```

##### `addRep()`
Добавление повторения в тренировку.
```dart
Future<WorkoutSession> addRep(
  WorkoutSession session, {
  required double formScore,
  required bool isCorrect,
})
```

**Параметры**:
- `session` - текущая сессия
- `formScore` - оценка техники (0-100)
- `isCorrect` - правильность выполнения

**Возвращает**: Обновленная `WorkoutSession`

##### `completeWorkout()`
Завершение тренировки.
```dart
Future<WorkoutSession> completeWorkout(WorkoutSession session)
```

### ImprovedRepCounter
Сервис подсчета повторений с AI анализом.

#### Методы:

##### `setExerciseType()`
Установка типа упражнения.
```dart
void setExerciseType(String exerciseId)
```

**Параметры**:
- `exerciseId` - идентификатор упражнения ('squats', 'plank', 'pushups')

##### `analyzePose()`
Анализ позы и подсчет повторений.
```dart
RepCountResult analyzePose(Pose pose)
```

**Параметры**:
- `pose` - объект позы из ML Kit

**Возвращает**: `RepCountResult` с данными анализа

**Пример**:
```dart
final repCounter = ImprovedRepCounter();
repCounter.setExerciseType('squats');

final result = repCounter.analyzePose(pose);
print('Повторений: ${result.repCount}');
print('Обратная связь: ${result.feedback}');
print('Уверенность: ${result.confidence}');
```

##### `reset()`
Сброс счетчика.
```dart
void reset()
```

## 🍎 Diet Services

### FoodDatabaseService
Сервис работы с базой данных продуктов.

#### Методы:

##### `searchFoods()`
Поиск продуктов по названию.
```dart
Future<List<FoodItem>> searchFoods(String query)
```

**Параметры**:
- `query` - поисковый запрос

**Возвращает**: `List<FoodItem>` - список найденных продуктов (максимум 20)

**Пример**:
```dart
final foodService = FoodDatabaseService();
final foods = await foodService.searchFoods('яблоко');

for (final food in foods) {
  print('${food.name}: ${food.calories} ккал/100г');
}
```

##### `getFoodById()`
Получение продукта по ID.
```dart
Future<FoodItem?> getFoodById(String id)
```

**Параметры**:
- `id` - уникальный идентификатор продукта

**Возвращает**: `FoodItem?` - продукт или `null`

##### `addToFavorites()`
Добавление продукта в избранное.
```dart
Future<void> addToFavorites(String foodId)
```

##### `getFavorites()`
Получение избранных продуктов.
```dart
Future<List<FoodItem>> getFavorites()
```

**Возвращает**: `List<FoodItem>` - список избранных продуктов

## 👤 Profile Services

### ExperienceService
Сервис системы опыта и достижений.

#### Методы:

##### `addExperience()`
Добавление опыта пользователю.
```dart
static Future<ExperienceResult> addExperience(int amount)
```

**Параметры**:
- `amount` - количество опыта для добавления

**Возвращает**: `ExperienceResult` с информацией о повышении уровня

**Пример**:
```dart
final result = await ExperienceService.addExperience(10);
if (result.leveledUp) {
  print('Поздравляем! Новый уровень: ${result.newLevel}');
}
```

##### `getCurrentLevel()`
Получение текущего уровня пользователя.
```dart
static Future<int> getCurrentLevel()
```

##### `getExperienceToNextLevel()`
Получение опыта до следующего уровня.
```dart
static Future<int> getExperienceToNextLevel()
```

## 📊 Модели данных

### User
Модель пользователя.
```dart
class User {
  final String username;
  final String email;
  final String country;
  final DateTime createdAt;
  
  User({
    required this.username,
    required this.email,
    required this.country,
    required this.createdAt,
  });
}
```

### Exercise
Модель упражнения.
```dart
class Exercise {
  final String id;
  final String nameRu;
  final String nameEn;
  final String description;
  final String muscleGroup;
  final String difficulty;
  final String imageUrl;
  final List<String> instructions;
  
  Exercise({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.description,
    required this.muscleGroup,
    required this.difficulty,
    required this.imageUrl,
    required this.instructions,
  });
}
```

### FoodItem
Модель продукта питания.
```dart
@HiveType(typeId: 1)
class FoodItem extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final double calories; // на 100г
  
  @HiveField(3)
  final double protein; // на 100г
  
  @HiveField(4)
  final double carbs; // на 100г
  
  @HiveField(5)
  final double fat; // на 100г
  
  @HiveField(6)
  final double fiber; // на 100г
  
  @HiveField(7)
  final String? barcode;
  
  @HiveField(8)
  final String? brand;
  
  @HiveField(9)
  final String? category;
}
```

### RepCountResult
Результат анализа упражнения.
```dart
class RepCountResult {
  final int repCount;
  final bool isInDownPosition;
  final String feedback;
  final double confidence;
  final double? currentAngle;
  
  RepCountResult({
    required this.repCount,
    required this.isInDownPosition,
    required this.feedback,
    required this.confidence,
    this.currentAngle,
  });
}
```

### WorkoutSession
Сессия тренировки.
```dart
@HiveType(typeId: 10)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String exerciseId;
  
  @HiveField(3)
  final DateTime startTime;
  
  @HiveField(4)
  DateTime? endTime;
  
  @HiveField(5)
  final List<WorkoutRep> reps;
  
  @HiveField(6)
  final int targetReps;
  
  @HiveField(7)
  bool isCompleted;
}
```

## 💡 Примеры использования

### Полный цикл тренировки:
```dart
// 1. Инициализация сервисов
final workoutService = WorkoutService();
final repCounter = ImprovedRepCounter();

// 2. Начало тренировки
final exercise = Exercise(id: 'squats', nameRu: 'Приседания');
final session = await workoutService.startWorkout(
  exercise: exercise,
  targetReps: 10,
);

// 3. Настройка счетчика
repCounter.setExerciseType('squats');

// 4. Анализ в цикле (в реальном времени)
while (session.reps.length < session.targetReps) {
  final pose = await poseDetector.processImage(cameraImage);
  if (pose.isNotEmpty) {
    final result = repCounter.analyzePose(pose.first);
    
    if (result.repCount > previousRepCount) {
      await workoutService.addRep(
        session,
        formScore: result.confidence * 100,
        isCorrect: result.confidence > 0.6,
      );
      
      // Добавление опыта
      await ExperienceService.addExperience(1);
    }
  }
}

// 5. Завершение тренировки
final completedSession = await workoutService.completeWorkout(session);
print('Тренировка завершена! Повторений: ${completedSession.reps.length}');
```

### Поиск и добавление продукта:
```dart
// 1. Поиск продуктов
final foodService = FoodDatabaseService();
final foods = await foodService.searchFoods('яблоко');

// 2. Выбор продукта
final selectedFood = foods.first;
print('Выбран: ${selectedFood.name}');
print('Калории: ${selectedFood.calories} ккал/100г');

// 3. Добавление в избранное
await foodService.addToFavorites(selectedFood.id);

// 4. Расчет калорий для порции
final portionSize = 150; // грамм
final totalCalories = (selectedFood.calories * portionSize) / 100;
print('Калории в порции ${portionSize}г: ${totalCalories.toInt()} ккал');
```

### Работа с профилем:
```dart
// 1. Получение текущего пользователя
final user = await AuthService.getCurrentUser();
if (user != null) {
  print('Пользователь: ${user.username}');
  
  // 2. Получение уровня и опыта
  final level = await ExperienceService.getCurrentLevel();
  final expToNext = await ExperienceService.getExperienceToNextLevel();
  
  print('Уровень: $level');
  print('До следующего уровня: $expToNext опыта');
  
  // 3. Добавление опыта за активность
  final result = await ExperienceService.addExperience(5);
  if (result.leveledUp) {
    print('🎉 Новый уровень: ${result.newLevel}!');
  }
}
```

## ⚠️ Обработка ошибок

Все API методы должны использоваться с обработкой ошибок:

```dart
try {
  final foods = await foodService.searchFoods('яблоко');
  // Обработка успешного результата
} catch (e) {
  print('Ошибка поиска продуктов: $e');
  // Показать пользователю сообщение об ошибке
}
```

## 📈 Производительность

### Рекомендации по оптимизации:
- Используйте `await` только когда необходимо дождаться результата
- Кэшируйте часто используемые данные
- Ограничивайте количество одновременных запросов к ML Kit
- Используйте пагинацию для больших списков данных

---

*Эта документация покрывает все основные API FitMonster для разработки и интеграции.*