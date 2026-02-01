# 👨‍💻 Руководство для разработчиков FitMonster

## 📋 Содержание

1. [Настройка среды разработки](#настройка-среды-разработки)
2. [Структура проекта](#структура-проекта)
3. [Стандарты кодирования](#стандарты-кодирования)
4. [Тестирование](#тестирование)
5. [Отладка](#отладка)
6. [Добавление новых функций](#добавление-новых-функций)

## 🛠️ Настройка среды разработки

### Требования:
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Git

### Установка:
```bash
git clone https://github.com/Bager4444/FitMonster.git
cd FitMonster
flutter pub get
flutter packages pub run build_runner build
```

## 📁 Структура проекта

```
lib/
├── core/                    # Общие компоненты
├── features/               # Основные модули
│   ├── auth/               # Аутентификация
│   ├── exercises/          # Упражнения
│   ├── diet/               # Питание
│   └── profile/            # Профиль
└── main.dart               # Точка входа
```

## 📝 Стандарты кодирования

### Именование:
- **Классы**: PascalCase (`ExerciseCameraPage`)
- **Методы**: camelCase (`analyzePose`)
- **Переменные**: camelCase (`repCount`)
- **Константы**: UPPER_SNAKE_CASE (`TARGET_FPS`)

### Комментарии:
```dart
/// Анализирует позу и возвращает результат подсчета повторений
/// 
/// [pose] - объект позы из ML Kit
/// Возвращает [RepCountResult] с данными анализа
RepCountResult analyzePose(Pose pose) {
  // Реализация...
}
```

## 🧪 Тестирование

### Запуск тестов:
```bash
flutter test                    # Unit тесты
flutter test integration_test/  # Integration тесты
```

### Пример теста:
```dart
void main() {
  group('RepCounter Tests', () {
    test('should count squats correctly', () {
      final counter = ImprovedRepCounter();
      counter.setExerciseType('squats');
      
      expect(counter.repCount, 0);
    });
  });
}
```

## 🐛 Отладка

### Логирование:
```dart
print('✅ Успешная операция');
print('❌ Ошибка: $error');
print('⚠️ Предупреждение');
```

### Flutter Inspector:
- Используйте для анализа виджетов
- Проверяйте производительность
- Отслеживайте перестроения

## ➕ Добавление новых функций

### 1. Новое упражнение:
```dart
// В exercises_database.dart
Exercise(
  id: 'new_exercise',
  nameRu: 'Новое упражнение',
  // ... другие поля
),

// В ImprovedRepCounter
'new_exercise': ExerciseConfig(
  primaryJoint: JointType.knee,
  downAngle: 120,
  upAngle: 170,
  exerciseType: ExerciseType.dynamic,
),
```

### 2. Новая страница:
```dart
class NewFeaturePage extends StatefulWidget {
  @override
  _NewFeaturePageState createState() => _NewFeaturePageState();
}

class _NewFeaturePageState extends State<NewFeaturePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Новая функция')),
      body: Container(
        // UI реализация
      ),
    );
  }
}
```

---

*Следуйте этим рекомендациям для эффективной разработки FitMonster.*