# 📚 AI Ассистент - Навигация по документации

## 🚀 Начало работы

### Для пользователей
- **[QUICKSTART.md](QUICKSTART.md)** - Быстрый старт за 5 минут
  - Как запустить
  - Примеры вопросов
  - Советы по использованию

### Для разработчиков
- **[README.md](README.md)** - Полная документация модуля
  - Описание возможностей
  - Технические детали
  - Безопасность
  - Будущие улучшения

## 📖 Документация

### Архитектура
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Архитектура модуля
  - Диаграммы потоков данных
  - Описание компонентов
  - Интеграция с API
  - Персонализация
  - Обработка ошибок

### База знаний
- **[KNOWLEDGE_BASE.md](KNOWLEDGE_BASE.md)** - База знаний AI
  - Тренировки (все группы мышц)
  - Питание (макронутриенты, режимы)
  - Мотивация
  - Восстановление

### API
- **[API_EXAMPLES.md](API_EXAMPLES.md)** - Примеры работы с API
  - HTTP запросы и ответы
  - Примеры диалогов
  - Обработка ошибок
  - Dart код
  - Тестирование API

### Тестирование
- **[TESTING.md](TESTING.md)** - Инструкции по тестированию
  - Тестовые сценарии
  - Проверка UI
  - Производительность
  - Отладка
  - Чек-лист перед релизом

### История изменений
- **[CHANGELOG.md](CHANGELOG.md)** - История версий
  - Версия 2.0.0 - Интеграция DeepSeek API
  - Версия 1.0.0 - Базовый AI с ключевыми словами

## 🗂️ Структура проекта

```
lib/features/ai/
├── domain/
│   └── models/
│       └── ai_message.dart          # Модель сообщения
├── services/
│   ├── deepseek_ai_service.dart     # Реальный AI (DeepSeek API)
│   └── ai_service.dart              # Старый сервис (fallback)
├── presentation/
│   └── pages/
│       └── ai_chat_page.dart        # UI чата
└── [Документация]
    ├── INDEX.md                     # Этот файл
    ├── QUICKSTART.md                # Быстрый старт
    ├── README.md                    # Основная документация
    ├── ARCHITECTURE.md              # Архитектура
    ├── API_EXAMPLES.md              # Примеры API
    ├── TESTING.md                   # Тестирование
    └── CHANGELOG.md                 # История изменений
```

## 🎯 Навигация по задачам

### Хочу начать использовать AI
→ [QUICKSTART.md](QUICKSTART.md)

### Хочу понять, как работает AI
→ [README.md](README.md) → [ARCHITECTURE.md](ARCHITECTURE.md)

### Хочу интегрировать API
→ [API_EXAMPLES.md](API_EXAMPLES.md)

### Хочу протестировать AI
→ [TESTING.md](TESTING.md)

### Хочу узнать, что изменилось
→ [CHANGELOG.md](CHANGELOG.md)

### Хочу расширить функциональность
→ [ARCHITECTURE.md](ARCHITECTURE.md) (раздел "Расширяемость")

## 📊 Быстрые ссылки

### Код
- [deepseek_ai_service.dart](services/deepseek_ai_service.dart) - Основной сервис
- [ai_chat_page.dart](presentation/pages/ai_chat_page.dart) - UI чата
- [ai_message.dart](domain/models/ai_message.dart) - Модель сообщения

### Тесты
- [deepseek_ai_service_test.dart](../../../test/features/ai/deepseek_ai_service_test.dart) - Unit тесты

### Корневая документация
- [README.md](../../../README.md) - Главный README проекта
- [AI_INTEGRATION_SUMMARY.md](../../../AI_INTEGRATION_SUMMARY.md) - Сводка интеграции
- [AI_CHECKLIST.md](../../../AI_CHECKLIST.md) - Чек-лист задач

## 🔍 Поиск по темам

### Тренировки
- [QUICKSTART.md](QUICKSTART.md) - Примеры вопросов о тренировках
- [API_EXAMPLES.md](API_EXAMPLES.md) - Примеры ответов AI

### Питание
- [QUICKSTART.md](QUICKSTART.md) - Примеры вопросов о питании
- [API_EXAMPLES.md](API_EXAMPLES.md) - Примеры с учетом аллергий

### Персонализация
- [ARCHITECTURE.md](ARCHITECTURE.md) - Раздел "Персонализация"
- [API_EXAMPLES.md](API_EXAMPLES.md) - Примеры с профилем

### Обработка ошибок
- [ARCHITECTURE.md](ARCHITECTURE.md) - Раздел "Обработка ошибок"
- [API_EXAMPLES.md](API_EXAMPLES.md) - Примеры ошибок и fallback

### Безопасность
- [README.md](README.md) - Раздел "Безопасность"
- [ARCHITECTURE.md](ARCHITECTURE.md) - Раздел "Безопасность"

### Производительность
- [ARCHITECTURE.md](ARCHITECTURE.md) - Раздел "Производительность"
- [TESTING.md](TESTING.md) - Раздел "Производительность"

## 📈 Уровни документации

### Уровень 1: Быстрый старт (5 минут)
1. [QUICKSTART.md](QUICKSTART.md)

### Уровень 2: Основы (15 минут)
1. [QUICKSTART.md](QUICKSTART.md)
2. [README.md](README.md)

### Уровень 3: Глубокое понимание (30 минут)
1. [QUICKSTART.md](QUICKSTART.md)
2. [README.md](README.md)
3. [ARCHITECTURE.md](ARCHITECTURE.md)

### Уровень 4: Полное погружение (1 час)
1. [QUICKSTART.md](QUICKSTART.md)
2. [README.md](README.md)
3. [ARCHITECTURE.md](ARCHITECTURE.md)
4. [API_EXAMPLES.md](API_EXAMPLES.md)
5. [TESTING.md](TESTING.md)

### Уровень 5: Эксперт (2+ часа)
Все документы + изучение кода

## 🎓 Обучающие пути

### Путь пользователя
```
QUICKSTART.md
    ↓
Использование AI
    ↓
README.md (раздел "Использование")
    ↓
Продвинутое использование
```

### Путь разработчика
```
README.md
    ↓
ARCHITECTURE.md
    ↓
Изучение кода
    ↓
API_EXAMPLES.md
    ↓
TESTING.md
    ↓
Разработка новых функций
```

### Путь тестировщика
```
QUICKSTART.md
    ↓
TESTING.md
    ↓
Выполнение тестов
    ↓
Отчет о багах
```

## 🛠️ Инструменты

### Для разработки
- Flutter SDK
- Dart
- VS Code / Android Studio
- Git

### Для тестирования
- Flutter Test
- Postman (для API)
- DevTools

### Для документации
- Markdown
- Mermaid (диаграммы)

## 📞 Поддержка

### Нашли баг?
1. Проверьте [TESTING.md](TESTING.md) - раздел "Известные ограничения"
2. Создайте issue в репозитории

### Нужна помощь?
1. Прочитайте [QUICKSTART.md](QUICKSTART.md)
2. Проверьте [TESTING.md](TESTING.md) - раздел "Устранение проблем"
3. Задайте вопрос в issue

### Хотите внести вклад?
1. Изучите [ARCHITECTURE.md](ARCHITECTURE.md)
2. Прочитайте [TESTING.md](TESTING.md)
3. Создайте pull request

## 📝 Обновления документации

### Последнее обновление
- **Дата**: 25 февраля 2026
- **Версия**: 2.0.0
- **Автор**: AI Integration Team

### История обновлений
См. [CHANGELOG.md](CHANGELOG.md)

## ✅ Чек-лист документации

- [x] Быстрый старт
- [x] Основная документация
- [x] Архитектура
- [x] Примеры API
- [x] Инструкции по тестированию
- [x] История изменений
- [x] Навигация (этот файл)

## 🎉 Готово!

Документация AI модуля полностью готова. Выберите нужный документ из списка выше и начните изучение!

---

**Версия документации**: 2.0.0  
**Дата**: 25 февраля 2026  
**Статус**: ✅ Полная документация
