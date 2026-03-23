import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitmonster/core/models/user_account.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/features/ai/domain/models/ai_message.dart';
import 'package:fitmonster/core/services/user_account_service.dart';
import 'package:fitmonster/features/profile/services/profile_service.dart';
import 'package:fitmonster/features/profile/domain/models/app_profile.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// AI сервис с интеграцией DeepSeek API
class DeepSeekAiService {
  static const String _messagesBox = HiveService.userBox;
  static const String _messagesKeyPrefix = 'ai_messages_';

  // DeepSeek API настройки
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const String _apiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: '',
  );
  static const String _model = String.fromEnvironment(
    'DEEPSEEK_MODEL',
    defaultValue: 'deepseek-chat',
  );

  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final UserAccountService _userAccountService = UserAccountService();

  String _messagesKey() {
    final userId = _authService.currentUserId ?? 'guest';
    return '$_messagesKeyPrefix$userId';
  }

  /// Получить историю сообщений
  Future<List<AiMessage>> getMessages() async {
    final data = HiveService.get(box: _messagesBox, key: _messagesKey());
    if (data == null) return [];

    if (data is List) {
      return data
          .map((e) => AiMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// Сохранить сообщения
  Future<void> _saveMessages(List<AiMessage> messages) async {
    final data = messages.map((m) => m.toJson()).toList();
    await HiveService.put(box: _messagesBox, key: _messagesKey(), value: data);
  }

  /// Отправить сообщение пользователя и получить ответ AI
  Future<AiMessage> sendMessage(String userMessage) async {
    final messages = await getMessages();

    // Добавляем сообщение пользователя
    final userMsg = AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMsg);

    // Генерируем ответ через DeepSeek API
    final aiResponse = await _generateAiResponse(userMessage, messages);
    messages.add(aiResponse);

    await _saveMessages(messages);
    return aiResponse;
  }

  /// Генерация ответа через DeepSeek API
  Future<AiMessage> _generateAiResponse(
    String userMessage,
    List<AiMessage> history,
  ) async {
    try {
      if (_apiKey.isEmpty) {
        return _getNoApiKeyResponse();
      }
      final profile = await _profileService.getAppProfile();
      final xp = await _profileService.getExperience();
      final level = ProfileService.levelFromXp(xp);
      final userId = _authService.currentUserId;
      final account = userId == null
          ? null
          : await _userAccountService.getByUserId(userId);

      // Создаем системный промпт с контекстом пользователя
      final systemPrompt = _buildSystemPrompt(profile, level, account);

      // Формируем историю для API
      final apiMessages = _buildApiMessages(history, systemPrompt);

      // Отправляем запрос к DeepSeek API
      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 30));

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
        // Fallback на простой ответ при ошибке API
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      // Fallback на простой ответ при любой ошибке
      return _getFallbackResponse(userMessage);
    }
  }

  AiMessage _getNoApiKeyResponse() {
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content:
          '⚙️ DeepSeek API ключ не настроен.\n\n'
          'Чтобы включить онлайн-ИИ, запусти приложение с параметром:\n'
          '--dart-define=DEEPSEEK_API_KEY=your_key\n\n'
          'Пока отвечаю в офлайн-режиме по встроенной базе знаний 💪',
      isUser: false,
      timestamp: DateTime.now(),
      type: AiMessageType.text,
    );
  }

  /// Fallback ответ при ошибке API с расширенной базой знаний
  AiMessage _getFallbackResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    String content;
    AiMessageType type = AiMessageType.text;

    // Конкретные группы мышц
    if (lower.contains('бицепс') || lower.contains('руки')) {
      content = _getBicepsWorkout();
      type = AiMessageType.workout;
    } else if (lower.contains('трицепс')) {
      content = _getTricepsWorkout();
      type = AiMessageType.workout;
    } else if (lower.contains('пресс') || lower.contains('живот')) {
      content = _getAbsWorkout();
      type = AiMessageType.workout;
    } else if (lower.contains('спина') || lower.contains('спину')) {
      content = _getBackWorkout();
      type = AiMessageType.workout;
    } else if (lower.contains('грудь') || lower.contains('грудные')) {
      content = _getChestWorkout();
      type = AiMessageType.workout;
    } else if (lower.contains('ноги') ||
        lower.contains('ног') ||
        lower.contains('бедра')) {
      content = _getLegsWorkout();
      type = AiMessageType.workout;
    } else if (lower.contains('плечи') || lower.contains('дельты')) {
      content = _getShouldersWorkout();
      type = AiMessageType.workout;
    }
    // Питание
    else if (lower.contains('после тренировки') ||
        lower.contains('после тренировок')) {
      content = _getPostWorkoutNutrition();
      type = AiMessageType.nutrition;
    } else if (lower.contains('до тренировки') ||
        lower.contains('перед тренировкой')) {
      content = _getPreWorkoutNutrition();
      type = AiMessageType.nutrition;
    } else if (lower.contains('похудеть') ||
        lower.contains('похудение') ||
        lower.contains('жир')) {
      content = _getWeightLossNutrition();
      type = AiMessageType.nutrition;
    } else if (lower.contains('набрать') || lower.contains('масс')) {
      content = _getMassGainNutrition();
      type = AiMessageType.nutrition;
    } else if (lower.contains('белок')) {
      content = _getProteinInfo();
      type = AiMessageType.nutrition;
    } else if (lower.contains('питан') ||
        lower.contains('еда') ||
        lower.contains('есть')) {
      content = _getGeneralNutrition();
      type = AiMessageType.nutrition;
    }
    // Мотивация
    else if (lower.contains('мотивац') ||
        lower.contains('устал') ||
        lower.contains('лень') ||
        lower.contains('не хочу')) {
      content = _getMotivation();
      type = AiMessageType.motivation;
    }
    // Общие тренировки
    else if (lower.contains('трениров') ||
        lower.contains('упражн') ||
        lower.contains('начать')) {
      content = _getGeneralWorkout();
      type = AiMessageType.workout;
    }
    // Восстановление
    else if (lower.contains('восстановление') ||
        lower.contains('отдых') ||
        lower.contains('болят')) {
      content = _getRecoveryInfo();
      type = AiMessageType.text;
    }
    // Приветствие
    else if (lower.contains('привет') ||
        lower.contains('здравствуй') ||
        lower.contains('hello')) {
      content = _getGreeting();
      type = AiMessageType.text;
    }
    // Дефолтный ответ
    else {
      content = _getDefaultResponse();
      type = AiMessageType.text;
    }

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      type: type,
    );
  }

  // === ТРЕНИРОВКИ ===

  String _getBicepsWorkout() {
    return '💪 Тренировка бицепса:\n\n'
        '🔰 Новички (0-5 подтягиваний):\n'
        '• Австралийские подтягивания: 4x10\n'
        '• Негативные подтягивания: 3x5\n'
        '• Вис на турнике: 3x30 сек\n\n'
        '⚡ Средний уровень (5-15):\n'
        '• Подтягивания: 4x8-10\n'
        '• Подтягивания узким хватом: 3x8\n'
        '• Отжимания узким хватом: 3x12\n\n'
        '🔥 Продвинутый (15+):\n'
        '• Подтягивания с весом: 4x8\n'
        '• Подтягивания на одной руке: 3x3\n\n'
        'Отдых между подходами: 60-90 сек';
  }

  String _getTricepsWorkout() {
    return '💪 Тренировка трицепса:\n\n'
        '🔰 Новички:\n'
        '• Отжимания с колен: 4x15\n'
        '• Обратные отжимания: 3x10\n'
        '• Планка: 3x30 сек\n\n'
        '⚡ Средний уровень:\n'
        '• Отжимания узким хватом: 4x15\n'
        '• Отжимания на брусьях: 3x10\n'
        '• Алмазные отжимания: 3x12\n\n'
        '🔥 Продвинутый:\n'
        '• Отжимания на брусьях: 4x15\n'
        '• Отжимания с хлопком: 3x10\n'
        '• Отжимания на одной руке: 3x5\n\n'
        'Трицепс = 2/3 объема руки! 🔥';
  }

  String _getAbsWorkout() {
    return '🔥 Тренировка пресса:\n\n'
        '🔰 Новички:\n'
        '• Скручивания: 3x15\n'
        '• Планка: 3x30 сек\n'
        '• Велосипед: 3x20\n\n'
        '⚡ Средний уровень:\n'
        '• Скручивания: 4x20\n'
        '• Планка: 3x60 сек\n'
        '• Подъем ног: 3x15\n'
        '• Русский твист: 3x30\n\n'
        '🔥 Продвинутый:\n'
        '• Скручивания с весом: 4x20\n'
        '• Планка: 3x90 сек\n'
        '• Подъем ног в висе: 3x15\n'
        '• Дракон: 3x10\n\n'
        'Тренируй пресс 3-4 раза в неделю! 💪';
  }

  String _getBackWorkout() {
    return '💪 Тренировка спины:\n\n'
        '🔰 Новички:\n'
        '• Супермен: 3x15\n'
        '• Планка: 3x30 сек\n'
        '• Австралийские подтягивания: 3x10\n\n'
        '⚡ Средний уровень:\n'
        '• Подтягивания: 4x8-10\n'
        '• Супермен: 3x20\n'
        '• Гиперэкстензия: 3x15\n'
        '• Планка: 3x60 сек\n\n'
        '🔥 Продвинутый:\n'
        '• Подтягивания широким хватом: 4x12\n'
        '• Подтягивания за голову: 3x10\n'
        '• Австралийские подтягивания: 3x20\n\n'
        'Здоровая спина = здоровое тело! ⚡';
  }

  String _getChestWorkout() {
    return '💪 Тренировка груди:\n\n'
        '🔰 Новички:\n'
        '• Отжимания с колен: 4x15\n'
        '• Отжимания от стены: 3x20\n'
        '• Планка: 3x30 сек\n\n'
        '⚡ Средний уровень:\n'
        '• Отжимания: 4x15\n'
        '• Отжимания широким хватом: 3x12\n'
        '• Отжимания с наклоном: 3x10\n\n'
        '🔥 Продвинутый:\n'
        '• Отжимания: 4x20\n'
        '• Отжимания с хлопком: 3x12\n'
        '• Отжимания на одной руке: 3x5\n'
        '• Отжимания на брусьях: 4x15\n\n'
        'Мощная грудь - основа силы! 🔥';
  }

  String _getLegsWorkout() {
    return '🦵 Тренировка ног:\n\n'
        '🔰 Новички:\n'
        '• Приседания: 4x15\n'
        '• Выпады: 3x10 на ногу\n'
        '• Подъем на носки: 3x20\n\n'
        '⚡ Средний уровень:\n'
        '• Приседания: 4x20\n'
        '• Выпады с прыжком: 3x12\n'
        '• Болгарские выпады: 3x12\n'
        '• Ягодичный мостик: 3x15\n\n'
        '🔥 Продвинутый:\n'
        '• Пистолет-приседания: 4x8\n'
        '• Прыжковые приседания: 4x20\n'
        '• Прыжки на ящик: 3x12\n'
        '• Выпады с прыжком: 3x15\n\n'
        'Ноги - основа силы! 💪';
  }

  String _getShouldersWorkout() {
    return '💪 Тренировка плеч:\n\n'
        '🔰 Новички:\n'
        '• Отжимания щучкой: 3x10\n'
        '• Планка: 3x30 сек\n'
        '• Подъемы рук в стороны: 3x15\n\n'
        '⚡ Средний уровень:\n'
        '• Отжимания щучкой: 4x15\n'
        '• Отжимания в стойке (у стены): 3x5\n'
        '• Планка с касанием плеч: 3x20\n\n'
        '🔥 Продвинутый:\n'
        '• Отжимания в стойке: 4x10\n'
        '• Ходьба на руках: 3x20 метров\n'
        '• Отжимания щучкой: 4x20\n\n'
        'Плечи = сила и красота! 🔥';
  }

  String _getGeneralWorkout() {
    return '💪 Программа тренировок:\n\n'
        '🔰 Новички (3 раза в неделю):\n'
        '• Приседания: 3x15\n'
        '• Отжимания: 3x10\n'
        '• Планка: 3x30 сек\n'
        '• Скручивания: 3x15\n\n'
        '⚡ Средний уровень (4 раза):\n'
        '• Приседания: 4x20\n'
        '• Отжимания: 4x15\n'
        '• Подтягивания: 3x8\n'
        '• Планка: 3x60 сек\n'
        '• Берпи: 3x10\n\n'
        '🔥 Продвинутый (5 раз):\n'
        '• Пистолет-приседания: 4x8\n'
        '• Отжимания с хлопком: 4x12\n'
        '• Подтягивания: 4x12\n'
        '• Планка: 3x90 сек\n'
        '• Берпи: 4x15\n\n'
        'Главное - регулярность! 🎯';
  }

  // === ПИТАНИЕ ===

  String _getPostWorkoutNutrition() {
    return '🍎 Питание после тренировки:\n\n'
        '⏰ В течение 30-60 минут:\n'
        '• Белок: 20-30г\n'
        '• Углеводы: 30-50г\n\n'
        '📋 Примеры блюд:\n'
        '• Курица (150г) + рис (100г) + овощи\n'
        '• Омлет (3 яйца) + овсянка (50г) + банан\n'
        '• Рыба (150г) + гречка (100г) + салат\n'
        '• Творог (200г) + фрукты + мёд\n'
        '• Протеиновый коктейль + банан\n\n'
        '💧 Вода: 500-700мл\n\n'
        'Это поможет восстановить мышцы! 💪';
  }

  String _getPreWorkoutNutrition() {
    return '🍎 Питание до тренировки:\n\n'
        '⏰ За 1.5-2 часа:\n'
        '• Углеводы: 40-60г\n'
        '• Белок: 15-20г\n'
        '• Минимум жиров\n\n'
        '📋 Примеры блюд:\n'
        '• Овсянка (50г) + банан + мёд\n'
        '• Рис (80г) + куриная грудка (100г)\n'
        '• Паста (80г) + овощи\n'
        '• Гречка (80г) + яйца (2 шт)\n\n'
        '⏰ За 30 минут:\n'
        '• Банан или яблоко\n'
        '• Энергетический батончик\n\n'
        '💧 Вода: 300-500мл\n\n'
        'Энергия для мощной тренировки! 🔥';
  }

  String _getWeightLossNutrition() {
    return '🔥 Питание для похудения:\n\n'
        '📊 Основы:\n'
        '• Дефицит калорий: -300-500 ккал\n'
        '• Белок: 1.8-2г на кг веса\n'
        '• Углеводы: 2-3г на кг\n'
        '• Жиры: 0.8-1г на кг\n\n'
        '🥗 Что есть:\n'
        '• Белок: курица, рыба, яйца, творог\n'
        '• Углеводы: гречка, рис, овощи\n'
        '• Жиры: орехи, авокадо, оливковое масло\n\n'
        '❌ Избегать:\n'
        '• Сладости и выпечка\n'
        '• Фастфуд\n'
        '• Газировка\n\n'
        '💧 Вода: 2-3 литра в день\n\n'
        'Терпение и постоянство! 💪';
  }

  String _getMassGainNutrition() {
    return '💪 Питание для набора массы:\n\n'
        '📊 Основы:\n'
        '• Профицит калорий: +300-500 ккал\n'
        '• Белок: 2-2.5г на кг веса\n'
        '• Углеводы: 4-6г на кг\n'
        '• Жиры: 1-1.5г на кг\n\n'
        '🍗 Что есть:\n'
        '• Белок: курица, говядина, рыба, яйца\n'
        '• Углеводы: рис, паста, картофель, овсянка\n'
        '• Жиры: орехи, авокадо, масла\n\n'
        '📋 Примерный рацион:\n'
        '• 5-6 приемов пищи в день\n'
        '• Каждый прием: белок + углеводы\n'
        '• Перед сном: творог или казеин\n\n'
        '💧 Вода: 3-4 литра в день\n\n'
        'Рост требует времени! 🚀';
  }

  String _getProteinInfo() {
    return '🥩 Всё о белке:\n\n'
        '📊 Норма:\n'
        '• Обычный человек: 0.8-1г на кг\n'
        '• Тренировки: 1.5-2г на кг\n'
        '• Набор массы: 2-2.5г на кг\n\n'
        '🍗 Источники белка:\n'
        '• Курица: 25г на 100г\n'
        '• Говядина: 26г на 100г\n'
        '• Рыба: 20-25г на 100г\n'
        '• Яйца: 6г на 1 шт\n'
        '• Творог: 16г на 100г\n'
        '• Протеин: 20-25г на порцию\n\n'
        '⏰ Когда есть:\n'
        '• Равномерно в течение дня\n'
        '• Обязательно после тренировки\n'
        '• Перед сном (медленный белок)\n\n'
        'Белок = строительный материал! 💪';
  }

  String _getGeneralNutrition() {
    return '🍎 Основы правильного питания:\n\n'
        '📊 Макронутриенты:\n'
        '• Белки: 1.5-2г на кг веса\n'
        '• Углеводы: 3-5г на кг\n'
        '• Жиры: 0.8-1.5г на кг\n\n'
        '🥗 Что есть:\n'
        '• Белок: курица, рыба, яйца, творог\n'
        '• Углеводы: гречка, рис, овощи, фрукты\n'
        '• Жиры: орехи, авокадо, оливковое масло\n\n'
        '⏰ Режим:\n'
        '• 4-5 приемов пищи в день\n'
        '• Завтрак обязателен\n'
        '• Последний прием за 2-3 часа до сна\n\n'
        '💧 Вода: 2-3 литра в день\n\n'
        'Питание = 70% успеха! 🎯';
  }

  // === МОТИВАЦИЯ ===

  String _getMotivation() {
    final motivations = [
      '💪 Каждая тренировка делает тебя сильнее!\n\n'
          'Помни:\n'
          '• Трудно = растешь\n'
          '• Легко = стоишь на месте\n\n'
          'Не сдавайся, результаты уже близко! 🔥',

      '🌟 Чемпионы не рождаются, они создаются!\n\n'
          'Твой путь:\n'
          '• Сегодня лучше, чем вчера\n'
          '• Завтра лучше, чем сегодня\n\n'
          'Продолжай тренироваться! ⚡',

      '🚀 Ты уже на правильном пути!\n\n'
          'Каждое повторение приближает к цели.\n'
          'Каждая тренировка - это победа.\n\n'
          'Не останавливайся! 💪',

      '🏆 Успех = постоянство + время\n\n'
          'Не важно, как медленно ты идешь,\n'
          'главное - не останавливаться!\n\n'
          'Ты молодец! Продолжай! 🔥',

      '⚡ Боль временна, гордость вечна!\n\n'
          'Через месяц ты не узнаешь себя.\n'
          'Через год ты будешь другим человеком.\n\n'
          'Вперед к цели! 💪',
    ];

    return motivations[DateTime.now().second % motivations.length];
  }

  // === ВОССТАНОВЛЕНИЕ ===

  String _getRecoveryInfo() {
    return '😌 Восстановление:\n\n'
        '💤 Сон:\n'
        '• 7-9 часов обязательно\n'
        '• Ложиться в одно время\n'
        '• Темная прохладная комната\n\n'
        '🧘 Растяжка:\n'
        '• После каждой тренировки 10-15 мин\n'
        '• Отдельная сессия 1-2 раза в неделю\n'
        '• Йога или пилатес\n\n'
        '💆 Массаж:\n'
        '• Самомассаж роллером\n'
        '• Профессиональный массаж 1-2 раза в месяц\n\n'
        '⏰ Отдых:\n'
        '• Между тренировками 48 часов\n'
        '• Активное восстановление (ходьба, плавание)\n\n'
        'Мышцы растут во время отдыха! 💤';
  }

  // === ОБЩИЕ ОТВЕТЫ ===

  String _getGreeting() {
    return '👋 Привет! Я твой персональный фитнес-ассистент.\n\n'
        'Могу помочь с:\n'
        '• Тренировками 💪 (бицепс, пресс, ноги, спина)\n'
        '• Питанием 🥗 (до/после тренировки, похудение)\n'
        '• Мотивацией 🔥 (поддержка и вдохновение)\n'
        '• Восстановлением 😌 (сон, растяжка)\n\n'
        'Задай вопрос, и я дам конкретные рекомендации! 🎯';
  }

  String _getDefaultResponse() {
    return '🤔 Интересный вопрос!\n\n'
        'Я специализируюсь на:\n'
        '• Тренировках 💪\n'
        '  (бицепс, трицепс, пресс, спина, грудь, ноги, плечи)\n'
        '• Питании 🥗\n'
        '  (до/после тренировки, похудение, набор массы)\n'
        '• Мотивации 🔥\n'
        '  (поддержка и вдохновение)\n'
        '• Восстановлении 😌\n'
        '  (сон, растяжка, отдых)\n\n'
        'Задай конкретный вопрос, например:\n'
        '• "Как накачать бицепс?"\n'
        '• "Что есть после тренировки?"\n'
        '• "Мотивируй меня!"';
  }

  /// Создаем системный промпт с контекстом пользователя
  String _buildSystemPrompt(
    AppProfile profile,
    int level,
    UserAccount? account,
  ) {
    final contraindications = profile.contraindications.isNotEmpty
        ? profile.contraindications.join(', ')
        : 'нет';
    final allergies = profile.allergies.isNotEmpty
        ? profile.allergies.join(', ')
        : 'нет';
    final worldRank = account?.worldRank ?? 0;
    final regionRank = account?.regionRank ?? 0;
    final avgScore = (account?.averageScorePercent ?? 0).toStringAsFixed(1);
    final subscription = account?.subscriptionStatus.name ?? 'free';

    return '''Ты - персональный фитнес-ассистент в приложении FitMonster. 
Твоя задача - помогать пользователям с тренировками, питанием и мотивацией.

ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ:
- Имя: ${profile.displayName}
- Уровень: $level
- Подписка: $subscription
- Рейтинг (мир/регион): $worldRank / $regionRank
- Средний процент техники: $avgScore%
- Противопоказания: $contraindications
- Аллергии: $allergies

ПРАВИЛА ОТВЕТОВ:
1. Отвечай кратко и по делу (максимум 250 слов)
2. Используй эмодзи для наглядности (💪🔥⚡🎯🥗💧)
3. Давай конкретные программы с подходами и повторениями
4. ОБЯЗАТЕЛЬНО учитывай противопоказания и аллергии
5. Если пользователь указывает количество повторений - дай персонализированную программу
6. Для питания давай конкретные блюда и граммовки
7. Будь мотивирующим и поддерживающим
8. Отвечай на русском языке

БАЗА ЗНАНИЙ О ТРЕНИРОВКАХ:

Группы мышц и упражнения:
• Бицепс: подтягивания, австралийские подтягивания, негативные подтягивания
• Трицепс: отжимания узким хватом, отжимания на брусьях, алмазные отжимания
• Пресс: скручивания, планка, подъем ног, велосипед, русский твист
• Спина: подтягивания широким хватом, супермен, гиперэкстензия
• Грудь: отжимания, отжимания широким хватом, отжимания на брусьях
• Ноги: приседания, выпады, пистолет-приседания, ягодичный мостик
• Плечи: отжимания щучкой, отжимания в стойке, планка с касанием плеч

Уровни сложности:
• Новички (уровень 1-5): базовые упражнения, 3 подхода, 10-15 повторений
• Средний (уровень 6-15): усложненные варианты, 4 подхода, 12-20 повторений
• Продвинутый (уровень 16+): сложные упражнения, 4-5 подходов, взрывные движения

Частота тренировок:
• Новички: 3 раза в неделю, 20-30 минут
• Средний: 4 раза в неделю, 30-45 минут
• Продвинутый: 5-6 раз в неделю, 45-60 минут

БАЗА ЗНАНИЙ О ПИТАНИИ:

Макронутриенты:
• Белок: 1.5-2г на кг веса (тренировки), 2-2.5г (набор массы)
• Углеводы: 3-5г на кг (поддержка), 2-3г (похудение), 4-6г (набор массы)
• Жиры: 0.8-1.5г на кг веса

Источники белка (на 100г):
• Курица: 25г, Говядина: 26г, Рыба: 20-25г
• Яйца: 13г, Творог: 16г, Протеин: 70-80г

Питание до тренировки (за 1.5-2 часа):
• Углеводы: 40-60г (овсянка, рис, паста)
• Белок: 15-20г (курица, яйца)
• Минимум жиров

Питание после тренировки (30-60 минут):
• Белок: 20-30г (курица, рыба, протеин)
• Углеводы: 30-50г (рис, банан, овсянка)

Похудение:
• Дефицит калорий: -300-500 ккал
• Больше белка, меньше углеводов
• Избегать: сладости, фастфуд, газировка

Набор массы:
• Профицит калорий: +300-500 ккал
• Высокий белок и углеводы
• 5-6 приемов пищи в день

СПЕЦИАЛИЗАЦИЯ:
- Тренировки: все группы мышц, программы для разных уровней
- Питание: до/после тренировки, похудение, набор массы, белок
- Мотивация: поддержка и вдохновение
- Восстановление: отдых, сон, растяжка

ВАЖНО:
- Всегда учитывай уровень пользователя ($level)
- При противопоказаниях давай безопасные упражнения
- При аллергиях предлагай альтернативные продукты
- Мотивируй и поддерживай пользователя''';
  }

  /// Формируем сообщения для API
  List<Map<String, String>> _buildApiMessages(
    List<AiMessage> history,
    String systemPrompt,
  ) {
    final messages = <Map<String, String>>[];

    // Добавляем системный промпт
    messages.add({'role': 'system', 'content': systemPrompt});

    // Добавляем последние 10 сообщений из истории для контекста
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

  /// Определяем тип сообщения по содержимому
  AiMessageType _detectMessageType(String content) {
    final lower = content.toLowerCase();

    if (lower.contains('тренир') ||
        lower.contains('упражн') ||
        lower.contains('подход') ||
        lower.contains('повторен')) {
      return AiMessageType.workout;
    }

    if (lower.contains('питан') ||
        lower.contains('еда') ||
        lower.contains('белок') ||
        lower.contains('калори')) {
      return AiMessageType.nutrition;
    }

    if (lower.contains('мотивац') ||
        lower.contains('молодец') ||
        lower.contains('продолжа')) {
      return AiMessageType.motivation;
    }

    return AiMessageType.text;
  }

  /// Очистить историю
  Future<void> clearHistory() async {
    await HiveService.delete(box: _messagesBox, key: _messagesKey());
  }
}
