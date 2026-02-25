# 🔌 Примеры работы с DeepSeek API

## Базовый запрос

### HTTP Request

```http
POST https://api.deepseek.com/v1/chat/completions
Content-Type: application/json
Authorization: Bearer sk-696fc79d42b24a2ea01ccdcda814eca5

{
  "model": "deepseek-chat",
  "messages": [
    {
      "role": "system",
      "content": "Ты - персональный фитнес-ассистент..."
    },
    {
      "role": "user",
      "content": "Как накачать бицепс?"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 1000
}
```

### HTTP Response (Success)

```json
{
  "id": "chatcmpl-123456",
  "object": "chat.completion",
  "created": 1709035200,
  "model": "deepseek-chat",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "💪 Тренировка бицепса:\n\nНовички (0-5 подтягиваний):\n• Австралийские подтягивания: 4x10\n• Негативные подтягивания: 3x5\n\nСредний (5-15):\n• Подтягивания: 4x8-10\n• Подтягивания узким хватом: 3x8\n\nПродвинутый (15+):\n• Подтягивания с весом: 4x8\n• Подтягивания на одной руке (негативы): 3x3\n\nСколько вы делаете подтягиваний? 🎯"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 150,
    "completion_tokens": 200,
    "total_tokens": 350
  }
}
```

## Примеры запросов

### 1. Вопрос о тренировках

**User Message:**
```
Могу сделать 15 подтягиваний, что дальше?
```

**System Prompt:**
```
Ты - персональный фитнес-ассистент в приложении FitMonster. 
Твоя задача - помогать пользователям с тренировками, питанием и мотивацией.

ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ:
- Имя: Иван
- Уровень: 8
- Противопоказания: нет
- Аллергии: нет

ПРАВИЛА:
1. Отвечай кратко и по делу (максимум 200 слов)
2. Используй эмодзи для наглядности
3. Давай конкретные программы тренировок с подходами и повторениями
4. ОБЯЗАТЕЛЬНО учитывай противопоказания и аллергии пользователя
5. Если пользователь указывает количество повторений, дай персонализированную программу
...
```

**AI Response:**
```
💪 Отлично! 15 подтягиваний - хороший средний уровень.

Программа для роста:
• Подтягивания: 4x10-12
• Подтягивания узким хватом: 3x10
• Негативные подтягивания: 3x5 (медленно)
• Статика в верхней точке: 3x15 сек

Цель - 20+ подтягиваний через месяц! ⚡

Тренируйся 3 раза в неделю, отдых между подходами 90 секунд.
```

### 2. Вопрос о питании

**User Message:**
```
Что есть после тренировки?
```

**AI Response:**
```
🍎 Питание после тренировки:

⏰ В течение 30-60 минут:
• Белок: 20-30г (курица, рыба, яйца, творог)
• Углеводы: 30-50г (рис, банан, овсянка)

Примеры:
• Курица + рис + овощи
• Омлет + овсянка + фрукты
• Протеиновый коктейль + банан
• Рыба + гречка + салат

Вода: 500-700мл 💧

Это поможет восстановить мышцы и энергию!
```

### 3. Вопрос с учетом противопоказаний

**User Message:**
```
Какие упражнения мне подходят?
```

**System Prompt (с противопоказаниями):**
```
ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ:
- Имя: Мария
- Уровень: 3
- Противопоказания: Гипертония
- Аллергии: нет
```

**AI Response:**
```
💪 С учетом гипертонии рекомендую:

• Избегайте упражнений с задержкой дыхания
• Планка, легкие приседания, ходьба
• Контролируйте пульс (не выше 120-130)
• Больше отдыхайте между подходами

Программа:
• Ходьба: 20-30 минут
• Планка: 3x30 секунд
• Приседания: 3x10 (медленно)
• Растяжка: 10 минут

Ваш уровень 3 - отличный прогресс! 🎯

Всегда консультируйтесь с врачом перед началом тренировок.
```

### 4. Контекстный диалог

**Message 1 (User):**
```
Как накачать бицепс?
```

**Response 1 (AI):**
```
💪 Тренировка бицепса:

Новички (0-5 подтягиваний):
• Австралийские подтягивания: 4x10
• Негативные подтягивания: 3x5

Средний (5-15):
• Подтягивания: 4x8-10
• Подтягивания узким хватом: 3x8

Продвинутый (15+):
• Подтягивания с весом: 4x8
• Подтягивания на одной руке (негативы): 3x3

Сколько вы делаете подтягиваний? 🎯
```

**Message 2 (User):**
```
10
```

**Response 2 (AI) - с контекстом:**
```
💪 Хороший результат! 10 подтягиваний - средний уровень.

Программа для роста:
• Подтягивания: 4x8-10
• Австралийские подтягивания: 3x15
• Негативные подтягивания: 3x5
• Планка: 3x60 сек

Цель - 15-20 подтягиваний! ⚡

Тренируйся 3 раза в неделю. Через месяц увидишь прогресс!
```

## Обработка ошибок

### Error Response (401 Unauthorized)

```json
{
  "error": {
    "message": "Invalid API key",
    "type": "invalid_request_error",
    "code": "invalid_api_key"
  }
}
```

**Fallback Response:**
```
💪 Для тренировок рекомендую:

• Начните с базовых упражнений
• Приседания: 3x15
• Отжимания: 3x10
• Планка: 3x30 сек

Тренируйтесь 3-4 раза в неделю! 🔥
```

### Error Response (429 Rate Limit)

```json
{
  "error": {
    "message": "Rate limit exceeded",
    "type": "rate_limit_error",
    "code": "rate_limit_exceeded"
  }
}
```

**Fallback Response:**
```
👋 Привет! Я ваш фитнес-ассистент.

Могу помочь с:
• Тренировками 💪
• Питанием 🥗
• Мотивацией 🔥

Задайте вопрос!
```

### Error Response (Timeout)

```
TimeoutException after 30 seconds
```

**Fallback Response:**
```
🤔 Интересный вопрос!

Я могу помочь с:
• Тренировками (бицепс, пресс, ноги, спина, грудь) 💪
• Питанием и диетой 🥗
• Похудением и набором массы 🔥
• Восстановлением и отдыхом 😌
• Мотивацией и поддержкой ⚡

Задайте конкретный вопрос!
```

## Параметры API

### Temperature

Контролирует креативность ответов:

- `0.0` - Детерминированные, предсказуемые ответы
- `0.7` - **Используется** - Баланс между креативностью и точностью
- `1.0` - Максимальная креативность

### Max Tokens

Ограничивает длину ответа:

- `500` - Короткие ответы
- `1000` - **Используется** - Развернутые ответы
- `2000` - Очень длинные ответы

### Model

Используемая модель:

- `deepseek-chat` - **Используется** - Основная модель для чата
- `deepseek-coder` - Для программирования (не используется)

## Dart код

### Отправка запроса

```dart
Future<AiMessage> _generateAiResponse(
  String userMessage,
  List<AiMessage> history,
) async {
  try {
    final profile = await _profileService.getAppProfile();
    final xp = await _profileService.getExperience();
    final level = ProfileService.levelFromXp(xp);

    // Системный промпт
    final systemPrompt = _buildSystemPrompt(profile, level);

    // История для API
    final apiMessages = _buildApiMessages(history, systemPrompt);

    // HTTP запрос
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': apiMessages,
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    ).timeout(const Duration(seconds: 30));

    // Обработка ответа
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final aiContent = data['choices'][0]['message']['content'];
      
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiContent,
        isUser: false,
        timestamp: DateTime.now(),
        type: _detectMessageType(aiContent),
      );
    } else {
      return _getFallbackResponse(userMessage);
    }
  } catch (e) {
    return _getFallbackResponse(userMessage);
  }
}
```

### Формирование сообщений

```dart
List<Map<String, String>> _buildApiMessages(
  List<AiMessage> history,
  String systemPrompt,
) {
  final messages = <Map<String, String>>[];
  
  // Системный промпт
  messages.add({
    'role': 'system',
    'content': systemPrompt,
  });

  // Последние 10 сообщений
  final recentHistory = history.length > 10
      ? history.sublist(history.length - 10)
      : history;

  for (final msg in recentHistory) {
    messages.add({
      'role': msg.isUser ? 'user' : 'assistant',
      'content': msg.content,
    });
  }

  return messages;
}
```

## Тестирование API

### cURL команда

```bash
curl -X POST https://api.deepseek.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-696fc79d42b24a2ea01ccdcda814eca5" \
  -d '{
    "model": "deepseek-chat",
    "messages": [
      {
        "role": "system",
        "content": "Ты - персональный фитнес-ассистент."
      },
      {
        "role": "user",
        "content": "Как накачать бицепс?"
      }
    ],
    "temperature": 0.7,
    "max_tokens": 1000
  }'
```

### Postman Collection

```json
{
  "info": {
    "name": "DeepSeek AI API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Chat Completion",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{api_key}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"model\": \"deepseek-chat\",\n  \"messages\": [\n    {\n      \"role\": \"system\",\n      \"content\": \"Ты - персональный фитнес-ассистент.\"\n    },\n    {\n      \"role\": \"user\",\n      \"content\": \"Как накачать бицепс?\"\n    }\n  ],\n  \"temperature\": 0.7,\n  \"max_tokens\": 1000\n}"
        },
        "url": {
          "raw": "https://api.deepseek.com/v1/chat/completions",
          "protocol": "https",
          "host": ["api", "deepseek", "com"],
          "path": ["v1", "chat", "completions"]
        }
      }
    }
  ]
}
```

## Лимиты и квоты

### Rate Limits (зависят от тарифа)

- **Free Tier**: 20 запросов/минуту
- **Pro Tier**: 100 запросов/минуту
- **Enterprise**: Custom

### Token Limits

- **Max Input**: 4096 токенов
- **Max Output**: 4096 токенов
- **Рекомендуемый Output**: 1000 токенов

### Стоимость (примерная)

- **Input**: $0.0014 / 1K токенов
- **Output**: $0.0028 / 1K токенов

**Пример расчета:**
- Запрос: 150 токенов (промпт + история)
- Ответ: 200 токенов
- Стоимость: (150 * 0.0014 + 200 * 0.0028) / 1000 = $0.00077

## Рекомендации

### Оптимизация токенов

1. **Сократите системный промпт** - только необходимая информация
2. **Ограничьте историю** - 10 последних сообщений достаточно
3. **Используйте max_tokens** - ограничьте длину ответа

### Обработка ошибок

1. **Всегда используйте timeout** - 30 секунд достаточно
2. **Реализуйте fallback** - базовые ответы при ошибках
3. **Логируйте ошибки** - для мониторинга

### Безопасность

1. **Не храните API ключ в коде** - используйте переменные окружения
2. **Используйте backend proxy** - скрывайте ключ от клиента
3. **Ограничьте rate limiting** - защита от злоупотреблений

---

**Версия**: 2.0.0  
**Последнее обновление**: 25 февраля 2026
