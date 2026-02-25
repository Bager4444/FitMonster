# 🏗️ Архитектура AI модуля

## Обзор

AI модуль построен по принципу Clean Architecture с разделением на слои:

```
lib/features/ai/
├── domain/          # Бизнес-логика и модели
├── services/        # Сервисы (API, хранилище)
└── presentation/    # UI компоненты
```

## Диаграмма потока данных

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│                    (ai_chat_page.dart)                       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Ввод текста  │  │   История    │  │   Кнопки     │      │
│  │              │  │  сообщений   │  │  действий    │      │
│  └──────┬───────┘  └──────▲───────┘  └──────────────┘      │
│         │                 │                                  │
└─────────┼─────────────────┼──────────────────────────────────┘
          │                 │
          ▼                 │
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│                 (deepseek_ai_service.dart)                   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              sendMessage(userMessage)                 │  │
│  │                                                       │  │
│  │  1. Добавить сообщение пользователя                  │  │
│  │  2. Сформировать системный промпт                    │  │
│  │  3. Подготовить контекст (10 последних сообщений)    │  │
│  │  4. Отправить запрос к DeepSeek API                  │  │
│  │  5. Обработать ответ                                 │  │
│  │  6. Определить тип сообщения                         │  │
│  │  7. Сохранить в историю                              │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│         ┌─────────────┐              ┌─────────────┐        │
│         │  API Call   │              │  Fallback   │        │
│         │  (Success)  │              │  (Error)    │        │
│         └──────┬──────┘              └──────┬──────┘        │
└────────────────┼─────────────────────────────┼──────────────┘
                 │                             │
                 ▼                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
│                                                              │
│  ┌──────────────────────┐      ┌──────────────────────┐    │
│  │   DeepSeek API       │      │   Local Storage      │    │
│  │                      │      │   (Hive)             │    │
│  │  POST /chat/         │      │                      │    │
│  │  completions         │      │  - История           │    │
│  │                      │      │  - Профиль           │    │
│  │  Model: deepseek-    │      │  - Настройки         │    │
│  │  chat                │      │                      │    │
│  └──────────────────────┘      └──────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Компоненты

### 1. Domain Layer

#### AiMessage (domain/models/ai_message.dart)
```dart
class AiMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final AiMessageType type;
}

enum AiMessageType {
  text,      // Общие вопросы
  workout,   // Тренировки
  nutrition, // Питание
  motivation // Мотивация
}
```

**Ответственность:**
- Представление сообщения в чате
- Сериализация/десериализация для хранения
- Типизация сообщений для UI

### 2. Service Layer

#### DeepSeekAiService (services/deepseek_ai_service.dart)

**Основные методы:**

```dart
// Получить историю сообщений
Future<List<AiMessage>> getMessages()

// Отправить сообщение и получить ответ
Future<AiMessage> sendMessage(String userMessage)

// Очистить историю
Future<void> clearHistory()
```

**Внутренние методы:**

```dart
// Генерация ответа через API
Future<AiMessage> _generateAiResponse(
  String userMessage,
  List<AiMessage> history,
)

// Создание системного промпта
String _buildSystemPrompt(AppProfile profile, int level)

// Формирование сообщений для API
List<Map<String, String>> _buildApiMessages(
  List<AiMessage> history,
  String systemPrompt,
)

// Определение типа сообщения
AiMessageType _detectMessageType(String content)

// Fallback при ошибках
AiMessage _getFallbackResponse(String userMessage)
```

**Зависимости:**
- `http` - HTTP запросы к API
- `HiveService` - локальное хранилище
- `ProfileService` - данные профиля пользователя

### 3. Presentation Layer

#### AiChatPage (presentation/pages/ai_chat_page.dart)

**Состояние:**
```dart
List<AiMessage> _messages;      // История сообщений
bool _isLoading;                 // Индикатор загрузки
TextEditingController _controller;
ScrollController _scrollController;
```

**Основные виджеты:**
- `_buildHeader()` - Шапка с информацией об AI
- `_buildEmptyState()` - Начальный экран с быстрыми вопросами
- `_buildMessageList()` - Список сообщений
- `_buildMessageBubble()` - Отдельное сообщение
- `_buildInputArea()` - Поле ввода и кнопка отправки

## Поток данных

### Отправка сообщения

```
1. Пользователь вводит текст
   ↓
2. UI вызывает _sendMessage()
   ↓
3. Текст передается в DeepSeekAiService.sendMessage()
   ↓
4. Сервис создает AiMessage для пользователя
   ↓
5. Сервис формирует системный промпт с профилем
   ↓
6. Сервис подготавливает контекст (10 последних сообщений)
   ↓
7. Сервис отправляет HTTP POST к DeepSeek API
   ↓
8. API возвращает ответ (или ошибку)
   ↓
9. При успехе: парсинг ответа
   При ошибке: fallback ответ
   ↓
10. Создание AiMessage для ответа AI
    ↓
11. Определение типа сообщения (workout/nutrition/motivation)
    ↓
12. Сохранение обоих сообщений в Hive
    ↓
13. UI обновляется через setState()
    ↓
14. Автоскролл к новому сообщению
```

### Загрузка истории

```
1. initState() вызывает _loadMessages()
   ↓
2. DeepSeekAiService.getMessages()
   ↓
3. HiveService.get() читает из локального хранилища
   ↓
4. Десериализация JSON → List<AiMessage>
   ↓
5. setState() обновляет UI
   ↓
6. Автоскролл к последнему сообщению
```

## Интеграция с DeepSeek API

### Конфигурация

```dart
static const String _apiUrl = 
  'https://api.deepseek.com/v1/chat/completions';
static const String _model = 'deepseek-chat';
```

### Параметры запроса

```json
{
  "model": "deepseek-chat",
  "messages": [
    {
      "role": "system",
      "content": "Системный промпт с контекстом пользователя..."
    },
    {
      "role": "user",
      "content": "Вопрос пользователя"
    },
    {
      "role": "assistant",
      "content": "Предыдущий ответ AI"
    }
    // ... до 10 последних сообщений
  ],
  "temperature": 0.7,
  "max_tokens": 1000
}
```

### Обработка ответа

```dart
if (response.statusCode == 200) {
  final data = jsonDecode(utf8.decode(response.bodyBytes));
  final aiContent = data['choices'][0]['message']['content'];
  // Создание AiMessage с ответом
} else {
  // Fallback на базовые ответы
}
```

## Персонализация

### Системный промпт

Включает:
1. **Роль**: Персональный фитнес-ассистент
2. **Контекст пользователя**:
   - Имя
   - Уровень (из опыта)
   - Противопоказания
   - Аллергии
3. **Правила ответов**:
   - Краткость (до 200 слов)
   - Использование эмодзи
   - Конкретные программы
   - Учет ограничений
4. **Специализация**:
   - Тренировки
   - Питание
   - Мотивация
   - Восстановление

### Определение типа сообщения

```dart
AiMessageType _detectMessageType(String content) {
  if (content.contains('тренир') || content.contains('упражн'))
    return AiMessageType.workout;
  
  if (content.contains('питан') || content.contains('еда'))
    return AiMessageType.nutrition;
  
  if (content.contains('мотивац') || content.contains('молодец'))
    return AiMessageType.motivation;
  
  return AiMessageType.text;
}
```

## Обработка ошибок

### Стратегия Fallback

```
API Error
  ↓
Catch Exception
  ↓
_getFallbackResponse()
  ↓
Анализ ключевых слов
  ↓
Базовый ответ по теме
```

### Типы ошибок

1. **Сетевые ошибки** (timeout, no connection)
   - Fallback с базовыми ответами
   
2. **API ошибки** (4xx, 5xx)
   - Fallback с базовыми ответами
   
3. **Ошибки парсинга**
   - Fallback с базовыми ответами

## Хранилище данных

### Hive Box Structure

```
userBox:
  'ai_messages': [
    {
      'id': '1234567890',
      'content': 'Как накачать бицепс?',
      'isUser': true,
      'timestamp': '2026-02-25T10:00:00.000Z',
      'type': 'text'
    },
    {
      'id': '1234567891',
      'content': 'Программа для бицепса...',
      'isUser': false,
      'timestamp': '2026-02-25T10:00:05.000Z',
      'type': 'workout'
    }
  ]
```

## Производительность

### Оптимизации

1. **Контекст**: Только 10 последних сообщений
2. **Timeout**: 30 секунд для API запросов
3. **Кэширование**: История в локальном хранилище
4. **Lazy Loading**: Сообщения загружаются при открытии

### Метрики

- Время ответа API: 2-5 секунд
- Размер истории: до 1000 сообщений
- Размер контекста: 10 сообщений
- Размер промпта: ~500 токенов
- Размер ответа: до 1000 токенов

## Безопасность

### Текущее состояние
- ⚠️ API ключ в коде (временно)

### Рекомендации для продакшена
1. Переменные окружения
2. Backend proxy
3. Rate limiting
4. Мониторинг использования
5. Шифрование локальных данных

## Расширяемость

### Добавление новых типов сообщений

```dart
// 1. Добавить в enum
enum AiMessageType {
  text,
  workout,
  nutrition,
  motivation,
  recovery,  // Новый тип
}

// 2. Обновить _detectMessageType()
if (content.contains('восстановление'))
  return AiMessageType.recovery;

// 3. Добавить иконку в UI
case AiMessageType.recovery:
  icon = Icons.spa;
  label = 'Восстановление';
```

### Добавление новых AI провайдеров

```dart
// Создать интерфейс
abstract class AiService {
  Future<AiMessage> sendMessage(String message);
  Future<List<AiMessage>> getMessages();
}

// Реализовать для разных провайдеров
class DeepSeekAiService implements AiService { ... }
class OpenAiService implements AiService { ... }
class GeminiAiService implements AiService { ... }
```

## Тестирование

### Unit тесты
- Тестирование моделей (AiMessage)
- Тестирование сервисов (с mock'ами)

### Integration тесты
- Полный поток отправки сообщения
- Сохранение и загрузка истории

### E2E тесты
- Взаимодействие с UI
- Реальные API запросы (в тестовой среде)

---

**Версия**: 2.0.0  
**Последнее обновление**: 25 февраля 2026
