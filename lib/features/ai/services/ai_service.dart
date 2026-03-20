import 'package:fitmonster/features/ai/domain/models/ai_message.dart';
import 'package:fitmonster/features/profile/services/profile_service.dart';
import 'package:fitmonster/features/profile/domain/models/app_profile.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// AI сервис для персонального фитнес-ассистента
class AiService {
  static const String _messagesBox = HiveService.userBox;
  static const String _messagesKey = 'ai_messages';

  final ProfileService _profileService = ProfileService();

  /// Получить историю сообщений
  Future<List<AiMessage>> getMessages() async {
    final data = HiveService.get(box: _messagesBox, key: _messagesKey);
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
    await HiveService.put(box: _messagesBox, key: _messagesKey, value: data);
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

    // Генерируем ответ AI
    final aiResponse = await _generateAiResponse(userMessage, messages);
    messages.add(aiResponse);

    await _saveMessages(messages);
    return aiResponse;
  }

  /// Генерация ответа AI на основе контекста
  Future<AiMessage> _generateAiResponse(
    String userMessage,
    List<AiMessage> history,
  ) async {
    final profile = await _profileService.getAppProfile();
    final xp = await _profileService.getExperience();
    final level = ProfileService.levelFromXp(xp);

    // Анализируем сообщение пользователя
    final lowerMessage = userMessage.toLowerCase();
    String response;
    AiMessageType type = AiMessageType.text;

    // Проверяем контекст предыдущего сообщения
    String? previousContext;
    if (history.length >= 2) {
      final lastAiMessage = history[history.length - 2];
      if (!lastAiMessage.isUser) {
        previousContext = lastAiMessage.content.toLowerCase();
      }
    }

    // Если пользователь ответил числом на вопрос о количестве повторений
    final isNumberOnly = RegExp(r'^\d+$').hasMatch(userMessage.trim());
    if (isNumberOnly && previousContext != null) {
      final repsCount = int.tryParse(userMessage.trim());
      
      if (previousContext.contains('подтягиван') || previousContext.contains('бицепс')) {
        return AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _getBicepsAdviceByReps(repsCount!, profile, level),
          isUser: false,
          timestamp: DateTime.now(),
          type: AiMessageType.workout,
        );
      }
      
      if (previousContext.contains('отжиман') || previousContext.contains('трицепс')) {
        return AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _getTricepsAdviceByReps(repsCount!, profile, level),
          isUser: false,
          timestamp: DateTime.now(),
          type: AiMessageType.workout,
        );
      }
      
      if (previousContext.contains('приседан') || previousContext.contains('ноги')) {
        return AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _getLegsAdviceByReps(repsCount!, profile, level),
          isUser: false,
          timestamp: DateTime.now(),
          type: AiMessageType.workout,
        );
      }
    }

    // СНАЧАЛА проверяем конкретные группы мышц (приоритет)
    if (_containsAny(lowerMessage, ['бицепс', 'biceps', 'бицухи', 'bicep', 'bitsep']) ||
        _containsAny(lowerMessage, ['трицепс', 'triceps', 'трицухи']) ||
        _containsAny(lowerMessage, ['плечи', 'shoulders', 'дельты', 'delts']) ||
        _containsAny(lowerMessage, ['предплечья', 'forearms', 'хват', 'grip']) ||
        _containsAny(lowerMessage, ['квадрицепс', 'quadriceps', 'квадры']) ||
        _containsAny(lowerMessage, ['бицепс бедра', 'hamstrings', 'задняя поверхность']) ||
        _containsAny(lowerMessage, ['ягодицы', 'glutes', 'попа']) ||
        _containsAny(lowerMessage, ['икры', 'calves', 'голени'])) {
      response = _getWorkoutAdvice(profile, level, lowerMessage);
      type = AiMessageType.workout;
    }
    // Питание (проверяем ПЕРЕД общими тренировками)
    else if (_containsAny(lowerMessage, [
      'питан',
      'еда',
      'диета',
      'калори',
      'белок',
      'nutrition',
      'diet',
      'food',
      'есть',
      'кушать',
      'что есть',
      'рацион',
      'eat',
      'meal',
      'protein',
      'carbs',
      'calories',
      'what to eat',
      'eating',
      'после тренировки',
      'до тренировки',
      'перед тренировкой',
      'after workout',
      'before workout',
    ])) {
      response = _getNutritionAdvice(profile, lowerMessage);
      type = AiMessageType.nutrition;
    }
    // Тренировки (общие)
    else if (_containsAny(lowerMessage, [
      'тренир',
      'тренировк',
      'упражнен',
      'workout',
      'exercise',
      'качать',
      'накачать',
      'трениров',
      'как начать',
      'начать тренир',
      'программа',
      'план тренир',
      'training',
      'gym',
      'fitness',
      'how to start',
      'start training',
      'program',
      'routine',
      'work out',
    ])) {
      response = _getWorkoutAdvice(profile, level, lowerMessage);
      type = AiMessageType.workout;
    }
    // Мотивация
    else if (_containsAny(lowerMessage, [
      'мотивац',
      'устал',
      'лень',
      'не хочу',
      'motivation',
      'tired',
      'мотивир',
      'поддерж',
      'сил нет',
      'motivate',
      'inspire',
      'lazy',
      'dont want',
      'no energy',
      'support',
    ])) {
      response = _getMotivation(profile, level);
      type = AiMessageType.motivation;
    }
    // Общие вопросы
    else {
      response = _getGeneralResponse(profile, level, lowerMessage);
    }

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      isUser: false,
      timestamp: DateTime.now(),
      type: type,
    );
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  String _getWorkoutAdvice(
    AppProfile profile,
    int level,
    String message,
  ) {
    final contraindications = profile.contraindications;
    
    // Учитываем противопоказания
    if (contraindications.isNotEmpty) {
      if (contraindications.any((c) => c.contains('Гипертония'))) {
        return '💪 С учетом гипертонии рекомендую:\n\n'
            '• Избегайте упражнений с задержкой дыхания\n'
            '• Планка, легкие приседания, ходьба\n'
            '• Контролируйте пульс (не выше 120-130)\n'
            '• Больше отдыхайте между подходами\n\n'
            'Ваш уровень $level - отличный прогресс! 🎯';
      }
      
      if (contraindications.any((c) => c.contains('Проблемы с коленями'))) {
        return '🦵 С учетом проблем с коленями:\n\n'
            '• Избегайте прыжков и глубоких приседаний\n'
            '• Планка, отжимания, упражнения на пресс\n'
            '• Плавание - идеальный вариант\n'
            '• Укрепляйте мышцы вокруг колена\n\n'
            'Уровень $level - продолжайте в том же духе! 💪';
      }
    }

    // Анализ опыта по ключевым словам
    final hasNumbers = RegExp(r'\d+').hasMatch(message);
    int? repsCount;
    if (hasNumbers) {
      final match = RegExp(r'(\d+)').firstMatch(message);
      if (match != null) {
        repsCount = int.tryParse(match.group(1)!);
      }
    }

    // Конкретные группы мышц с учетом опыта
    if (_containsAny(message, ['бицепс', 'biceps', 'бицухи', 'bicep', 'bitsep'])) {
      if (repsCount != null) {
        if (repsCount >= 20) {
          return '💪 Отлично! $repsCount подтягиваний - продвинутый уровень!\n\n'
              'Программа для вас:\n'
              '• Подтягивания с весом: 4x8-10\n'
              '• Подтягивания узким хватом: 3x12\n'
              '• Негативные подтягивания: 3x5 (медленно)\n'
              '• Статика в верхней точке: 3x20 сек\n\n'
              'Работайте над силой! 🔥';
        } else if (repsCount >= 10) {
          return '💪 Хороший результат! $repsCount подтягиваний - средний уровень.\n\n'
              'Программа для роста:\n'
              '• Подтягивания: 4x8-10\n'
              '• Австралийские подтягивания: 3x15\n'
              '• Негативные подтягивания: 3x5\n'
              '• Планка: 3x60 сек\n\n'
              'Цель - 15-20 подтягиваний! ⚡';
        } else {
          return '💪 $repsCount подтягиваний - отличное начало!\n\n'
              'Программа для новичков:\n'
              '• Австралийские подтягивания: 4x10\n'
              '• Негативные подтягивания: 3x5 (медленно вниз)\n'
              '• Вис на турнике: 3x30 сек\n'
              '• Отжимания узким хватом: 3x12\n\n'
              'Через месяц будет 10+ подтягиваний! 🚀';
        }
      }
      return '💪 Тренировка бицепса:\n\n'
          'Новички (0-5 подтягиваний):\n'
          '• Австралийские подтягивания: 4x10\n'
          '• Негативные подтягивания: 3x5\n\n'
          'Средний (5-15):\n'
          '• Подтягивания: 4x8-10\n'
          '• Подтягивания узким хватом: 3x8\n\n'
          'Продвинутый (15+):\n'
          '• Подтягивания с весом: 4x8\n'
          '• Подтягивания на одной руке (негативы): 3x3\n\n'
          'Сколько вы делаете подтягиваний? 🎯';
    }

    if (_containsAny(message, ['трицепс', 'triceps', 'трицухи'])) {
      if (repsCount != null) {
        if (repsCount >= 30) {
          return '💪 Мощно! $repsCount отжиманий - вы атлет!\n\n'
              'Программа для продвинутых:\n'
              '• Отжимания на брусьях: 4x15\n'
              '• Алмазные отжимания: 4x20\n'
              '• Отжимания с хлопком: 3x10\n'
              '• Отжимания на одной руке: 3x5\n\n'
              'Работайте над взрывной силой! 🔥';
        } else if (repsCount >= 15) {
          return '💪 Хорошо! $repsCount отжиманий - средний уровень.\n\n'
              'Программа для роста:\n'
              '• Отжимания узким хватом: 4x15\n'
              '• Отжимания на брусьях: 3x10\n'
              '• Алмазные отжимания: 3x12\n'
              '• Планка: 3x60 сек\n\n'
              'Цель - 30+ отжиманий! ⚡';
        } else {
          return '💪 $repsCount отжиманий - хорошее начало!\n\n'
              'Программа для новичков:\n'
              '• Отжимания с колен: 4x15\n'
              '• Отжимания от стены: 3x20\n'
              '• Планка: 3x30 сек\n'
              '• Обратные отжимания: 3x10\n\n'
              'Через месяц будет 20+ отжиманий! 🚀';
        }
      }
      return '💪 Тренировка трицепса:\n\n'
          'Новички (0-10 отжиманий):\n'
          '• Отжимания с колен: 4x15\n'
          '• Обратные отжимания: 3x10\n\n'
          'Средний (10-25):\n'
          '• Отжимания узким хватом: 4x15\n'
          '• Отжимания на брусьях: 3x10\n\n'
          'Продвинутый (25+):\n'
          '• Алмазные отжимания: 4x20\n'
          '• Отжимания с хлопком: 3x10\n\n'
          'Сколько отжиманий делаете? 🎯';
    }

    if (_containsAny(message, ['плечи', 'shoulders', 'дельты', 'delts'])) {
      return '💪 Тренировка плеч:\n\n'
          'Новички:\n'
          '• Отжимания щучкой: 3x10\n'
          '• Планка: 3x45 сек\n'
          '• Подъемы рук в стороны: 3x15\n\n'
          'Средний:\n'
          '• Отжимания в стойке на руках (у стены): 3x5\n'
          '• Отжимания щучкой: 4x15\n'
          '• Планка с касанием плеч: 3x20\n\n'
          'Продвинутый:\n'
          '• Отжимания в стойке: 4x10\n'
          '• Ходьба на руках: 3x20 метров\n\n'
          'Плечи = сила и красота! 🔥';
    }

    if (_containsAny(message, ['предплечья', 'forearms', 'хват', 'grip'])) {
      return '💪 Тренировка предплечий:\n\n'
          'Все уровни:\n'
          '• Вис на турнике: 3x максимум\n'
          '• Сжимание кулаков: 3x50\n'
          '• Вращения кистями: 3x20\n'
          '• Планка на кулаках: 3x45 сек\n\n'
          'Для продвинутых:\n'
          '• Вис на одной руке: 3x20 сек\n'
          '• Подтягивания на полотенце: 3x8\n\n'
          'Сильный хват = сильное тело! ⚡';
    }

    if (_containsAny(message, ['квадрицепс', 'quadriceps', 'квадры'])) {
      return '🦵 Тренировка квадрицепсов:\n\n'
          'Новички:\n'
          '• Приседания: 4x15\n'
          '• Выпады: 3x10 на ногу\n'
          '• Приседания у стены: 3x30 сек\n\n'
          'Средний:\n'
          '• Приседания на одной ноге (с опорой): 3x8\n'
          '• Прыжковые приседания: 3x15\n'
          '• Выпады с прыжком: 3x12\n\n'
          'Продвинутый:\n'
          '• Пистолет-приседания: 4x8\n'
          '• Прыжки на ящик: 3x12\n\n'
          'Ноги - основа силы! 🔥';
    }

    if (_containsAny(message, ['бицепс бедра', 'hamstrings', 'задняя поверхность'])) {
      return '🦵 Тренировка бицепса бедра:\n\n'
          'Все уровни:\n'
          '• Румынская тяга на одной ноге: 3x12\n'
          '• Ягодичный мостик: 4x15\n'
          '• Гиперэкстензия: 3x15\n'
          '• Супермен: 3x20\n\n'
          'Продвинутый:\n'
          '• Скандинавские сгибания: 3x8\n'
          '• Прыжки в длину: 3x10\n\n'
          'Баланс передней и задней! ⚡';
    }

    if (_containsAny(message, ['ягодицы', 'glutes', 'попа'])) {
      return '🍑 Тренировка ягодиц:\n\n'
          'Новички:\n'
          '• Ягодичный мостик: 4x20\n'
          '• Приседания: 3x15\n'
          '• Выпады назад: 3x12\n\n'
          'Средний:\n'
          '• Ягодичный мостик на одной ноге: 3x15\n'
          '• Болгарские выпады: 3x12\n'
          '• Прыжковые приседания: 3x15\n\n'
          'Продвинутый:\n'
          '• Ягодичный мостик с весом: 4x20\n'
          '• Пистолет-приседания: 3x8\n\n'
          'Сильные ягодицы = здоровая спина! 💪';
    }

    if (_containsAny(message, ['икры', 'calves', 'голени'])) {
      return '🦵 Тренировка икр:\n\n'
          'Все уровни:\n'
          '• Подъем на носки: 4x25\n'
          '• Подъем на носки на одной ноге: 3x15\n'
          '• Прыжки на носках: 3x30\n'
          '• Ходьба на носках: 3x1 минута\n\n'
          'Продвинутый:\n'
          '• Прыжки на скакалке: 5x100\n'
          '• Прыжки на одной ноге: 3x20\n\n'
          'Икры - упрямые мышцы, нужна частота! 🔥';
    }

    // Рекомендации по уровню
    if (level < 5) {
      return '🌟 Для начинающих (уровень $level):\n\n'
          '• Начните с базовых упражнений\n'
          '• Приседания, отжимания, планка\n'
          '• 3 тренировки в неделю по 20-30 минут\n'
          '• Постепенно увеличивайте нагрузку\n\n'
          'Главное - регулярность! 🔥';
    } else if (level < 10) {
      return '💪 Для продолжающих (уровень $level):\n\n'
          '• Добавьте сложные упражнения\n'
          '• Берпи, выпады с прыжком, планка с подъемом ног\n'
          '• 4-5 тренировок в неделю\n'
          '• Работайте над техникой\n\n'
          'Вы на правильном пути! ⚡';
    } else {
      return '🏆 Для продвинутых (уровень $level):\n\n'
          '• Интенсивные комплексы\n'
          '• Отжимания с хлопком, пистолет-приседания\n'
          '• 5-6 тренировок в неделю\n'
          '• Экспериментируйте с нагрузкой\n\n'
          'Вы - настоящий атлет! 🚀';
    }
  }

  String _getNutritionAdvice(AppProfile profile, String message) {
    final allergies = profile.allergies;
    
    // Специфические вопросы о питании
    if (_containsAny(message, ['после тренировки', 'after workout', 'после тренировок'])) {
      if (allergies.isNotEmpty) {
        final allergyList = allergies.take(2).join(', ');
        return '🍎 Питание после тренировки (с учетом аллергий: $allergyList):\n\n'
            '⏰ В течение 30-60 минут:\n'
            '• Белок: 20-30г (курица, рыба, яйца)\n'
            '• Углеводы: 30-50г (рис, банан, овсянка)\n\n'
            'Примеры:\n'
            '• Курица + рис + овощи\n'
            '• Омлет + овсянка + фрукты\n'
            '• Рыба + гречка + салат\n\n'
            'Избегайте: $allergyList\n'
            'Вода: 500-700мл 💧';
      }
      return '🍎 Питание после тренировки:\n\n'
          '⏰ В течение 30-60 минут:\n'
          '• Белок: 20-30г (курица, рыба, яйца, творог)\n'
          '• Углеводы: 30-50г (рис, банан, овсянка)\n\n'
          'Примеры:\n'
          '• Курица + рис + овощи\n'
          '• Омлет + овсянка + фрукты\n'
          '• Протеиновый коктейль + банан\n'
          '• Рыба + гречка + салат\n\n'
          'Вода: 500-700мл 💧';
    }
    
    if (_containsAny(message, ['до тренировки', 'перед тренировкой', 'before workout'])) {
      return '🍎 Питание до тренировки:\n\n'
          '⏰ За 1.5-2 часа:\n'
          '• Углеводы: 40-60г (овсянка, рис, паста)\n'
          '• Белок: 15-20г (курица, яйца)\n'
          '• Минимум жиров\n\n'
          'Примеры:\n'
          '• Овсянка + банан + мёд\n'
          '• Рис + куриная грудка\n'
          '• Паста + овощи\n\n'
          '⏰ За 30 минут:\n'
          '• Банан или яблоко\n'
          '• Энергетический батончик\n\n'
          'Вода: 300-500мл 💧';
    }
    
    if (allergies.isNotEmpty) {
      final allergyList = allergies.take(3).join(', ');
      return '🥗 С учетом ваших аллергий ($allergyList):\n\n'
          '• Избегайте этих продуктов\n'
          '• Читайте состав на упаковках\n'
          '• Ищите альтернативы (например, растительное молоко)\n'
          '• Белок: курица, рыба, бобовые\n'
          '• Углеводы: рис, гречка, овощи\n\n'
          'Здоровое питание - основа успеха! 💚';
    }

    return '🍎 Основы правильного питания:\n\n'
        '• Белки: 1.5-2г на кг веса (курица, рыба, яйца)\n'
        '• Углеводы: гречка, рис, овощи\n'
        '• Жиры: орехи, авокадо, оливковое масло\n'
        '• Пейте 2-3 литра воды в день\n'
        '• 4-5 приемов пищи небольшими порциями\n\n'
        'Питание = 70% успеха! 🎯';
  }

  String _getMotivation(AppProfile profile, int level) {
    final motivations = [
      '💪 ${profile.displayName}, вы уже на уровне $level! Это огромный прогресс!\n\n'
          'Помните: каждая тренировка делает вас сильнее. '
          'Не сдавайтесь, результаты уже близко! 🔥',
      '🌟 Трудно? Значит растете!\n\n'
          'Уровень $level - это результат вашего труда. '
          'Продолжайте, и через месяц вы не узнаете себя! 💪',
      '🚀 ${profile.displayName}, вы молодец!\n\n'
          'Каждое повторение приближает к цели. '
          'Не останавливайтесь на достигнутом! ⚡',
      '🏆 Чемпионы не рождаются, они создаются!\n\n'
          'Ваш уровень $level - доказательство силы воли. '
          'Продолжайте тренироваться! 🔥',
    ];
    
    return motivations[DateTime.now().second % motivations.length];
  }

  String _getGeneralResponse(AppProfile profile, int level, String message) {
    if (_containsAny(message, ['привет', 'здравствуй', 'hello', 'hi'])) {
      return '👋 Привет, ${profile.displayName}!\n\n'
          'Я ваш персональный фитнес-ассистент. '
          'Готов помочь с тренировками, питанием и мотивацией!\n\n'
          'Ваш уровень: $level 🎯\n\n'
          'Чем могу помочь?';
    }

    if (_containsAny(message, ['спасибо', 'thanks', 'thank'])) {
      return '😊 Всегда пожалуйста!\n\n'
          'Продолжайте тренироваться и достигать целей! 💪';
    }

    // Конкретные группы мышц
    if (_containsAny(message, ['бицепс', 'biceps', 'руки', 'arms'])) {
      return '💪 Тренировка бицепса:\n\n'
          '• Отжимания узким хватом\n'
          '• Подтягивания обратным хватом\n'
          '• Сгибания с весом тела\n'
          '• 3-4 подхода по 10-15 повторений\n\n'
          'Отдых между подходами: 60-90 секунд 🔥';
    }

    if (_containsAny(message, ['пресс', 'abs', 'живот', 'belly'])) {
      return '🔥 Тренировка пресса:\n\n'
          '• Скручивания: 3x20\n'
          '• Планка: 3x60 секунд\n'
          '• Велосипед: 3x30\n'
          '• Подъем ног: 3x15\n\n'
          'Тренируйте пресс 3-4 раза в неделю! 💪';
    }

    if (_containsAny(message, ['ноги', 'legs', 'бедра', 'thighs'])) {
      return '🦵 Тренировка ног:\n\n'
          '• Приседания: 4x15\n'
          '• Выпады: 3x12 на каждую ногу\n'
          '• Подъем на носки: 3x20\n'
          '• Ягодичный мостик: 3x15\n\n'
          'Ноги - основа силы! 🔥';
    }

    if (_containsAny(message, ['спина', 'back', 'позвоночник'])) {
      return '💪 Тренировка спины:\n\n'
          '• Подтягивания: 3x8-10\n'
          '• Супермен: 3x15\n'
          '• Планка: 3x60 секунд\n'
          '• Гиперэкстензия: 3x12\n\n'
          'Здоровая спина = здоровое тело! ⚡';
    }

    if (_containsAny(message, ['грудь', 'chest', 'грудные'])) {
      return '💪 Тренировка груди:\n\n'
          '• Отжимания: 4x15\n'
          '• Отжимания широким хватом: 3x12\n'
          '• Отжимания с наклоном: 3x10\n'
          '• Планка: 3x45 секунд\n\n'
          'Мощная грудь - основа силы! 🔥';
    }

    // Похудение и набор массы
    if (_containsAny(message, ['похудеть', 'lose weight', 'сбросить вес', 'жир'])) {
      return '🔥 Как похудеть:\n\n'
          '• Дефицит калорий: -300-500 ккал от нормы\n'
          '• Кардио 3-4 раза в неделю (30-45 мин)\n'
          '• Силовые тренировки 3 раза в неделю\n'
          '• Больше белка (1.5-2г на кг веса)\n'
          '• Пейте 2-3 литра воды\n\n'
          'Терпение и постоянство! 💪';
    }

    if (_containsAny(message, ['набрать массу', 'gain weight', 'мышцы', 'muscle'])) {
      return '💪 Как набрать массу:\n\n'
          '• Профицит калорий: +300-500 ккал\n'
          '• Белок: 2-2.5г на кг веса\n'
          '• Силовые тренировки 4-5 раз в неделю\n'
          '• Прогрессивная нагрузка\n'
          '• Сон 8-9 часов\n\n'
          'Рост требует времени! 🚀';
    }

    // Восстановление
    if (_containsAny(message, ['восстановление', 'recovery', 'отдых', 'rest', 'болят мышцы'])) {
      return '😌 Восстановление:\n\n'
          '• Сон 7-9 часов обязательно\n'
          '• Растяжка после тренировок\n'
          '• Массаж или самомассаж\n'
          '• Достаточно белка и воды\n'
          '• Отдых между тренировками 48 часов\n\n'
          'Мышцы растут во время отдыха! 💤';
    }

    // Время тренировок
    if (_containsAny(message, ['когда тренироваться', 'when to train', 'время', 'time'])) {
      return '⏰ Лучшее время для тренировок:\n\n'
          '• Утро (6-9): бодрость на весь день\n'
          '• День (12-15): пик физической активности\n'
          '• Вечер (17-20): максимальная сила\n\n'
          'Главное - регулярность, а не время! 🎯';
    }

    // Вода
    if (_containsAny(message, ['вода', 'water', 'пить', 'drink'])) {
      return '💧 Питьевой режим:\n\n'
          '• Минимум 2-3 литра в день\n'
          '• Во время тренировки: 150-200мл каждые 15 мин\n'
          '• После тренировки: 500-700мл\n'
          '• Утром натощак: 1-2 стакана\n\n'
          'Вода = жизнь! 💙';
    }

    return '🤔 Интересный вопрос!\n\n'
        'Я могу помочь с:\n'
        '• Тренировками (бицепс, пресс, ноги, спина, грудь) 💪\n'
        '• Питанием и диетой 🥗\n'
        '• Похудением и набором массы 🔥\n'
        '• Восстановлением и отдыхом 😌\n'
        '• Мотивацией и поддержкой ⚡\n\n'
        'Задайте конкретный вопрос!';
  }

  /// Очистить историю
  Future<void> clearHistory() async {
    await HiveService.delete(box: _messagesBox, key: _messagesKey);
  }

  // Вспомогательные методы для ответов по количеству повторений
  String _getBicepsAdviceByReps(int reps, AppProfile profile, int level) {
    if (reps >= 20) {
      return '💪 Отлично! $reps подтягиваний - продвинутый уровень!\n\n'
          'Программа для вас:\n'
          '• Подтягивания с весом: 4x8-10\n'
          '• Подтягивания узким хватом: 3x12\n'
          '• Негативные подтягивания: 3x5 (медленно)\n'
          '• Статика в верхней точке: 3x20 сек\n\n'
          'Работайте над силой! 🔥';
    } else if (reps >= 10) {
      return '💪 Хороший результат! $reps подтягиваний - средний уровень.\n\n'
          'Программа для роста:\n'
          '• Подтягивания: 4x8-10\n'
          '• Австралийские подтягивания: 3x15\n'
          '• Негативные подтягивания: 3x5\n'
          '• Планка: 3x60 сек\n\n'
          'Цель - 15-20 подтягиваний! ⚡';
    } else {
      return '💪 $reps подтягиваний - отличное начало!\n\n'
          'Программа для новичков:\n'
          '• Австралийские подтягивания: 4x10\n'
          '• Негативные подтягивания: 3x5 (медленно вниз)\n'
          '• Вис на турнике: 3x30 сек\n'
          '• Отжимания узким хватом: 3x12\n\n'
          'Через месяц будет 10+ подтягиваний! 🚀';
    }
  }

  String _getTricepsAdviceByReps(int reps, AppProfile profile, int level) {
    if (reps >= 30) {
      return '💪 Мощно! $reps отжиманий - вы атлет!\n\n'
          'Программа для продвинутых:\n'
          '• Отжимания на брусьях: 4x15\n'
          '• Алмазные отжимания: 4x20\n'
          '• Отжимания с хлопком: 3x10\n'
          '• Отжимания на одной руке: 3x5\n\n'
          'Работайте над взрывной силой! 🔥';
    } else if (reps >= 15) {
      return '💪 Хорошо! $reps отжиманий - средний уровень.\n\n'
          'Программа для роста:\n'
          '• Отжимания узким хватом: 4x15\n'
          '• Отжимания на брусьях: 3x10\n'
          '• Алмазные отжимания: 3x12\n'
          '• Планка: 3x60 сек\n\n'
          'Цель - 30+ отжиманий! ⚡';
    } else {
      return '💪 $reps отжиманий - хорошее начало!\n\n'
          'Программа для новичков:\n'
          '• Отжимания с колен: 4x15\n'
          '• Отжимания от стены: 3x20\n'
          '• Планка: 3x30 сек\n'
          '• Обратные отжимания: 3x10\n\n'
          'Через месяц будет 20+ отжиманий! 🚀';
    }
  }

  String _getLegsAdviceByReps(int reps, AppProfile profile, int level) {
    if (reps >= 50) {
      return '🦵 Невероятно! $reps приседаний - вы машина!\n\n'
          'Программа для продвинутых:\n'
          '• Пистолет-приседания: 4x8\n'
          '• Прыжковые приседания: 4x20\n'
          '• Выпады с прыжком: 3x15\n'
          '• Прыжки на ящик: 3x12\n\n'
          'Работайте над взрывной силой! 🔥';
    } else if (reps >= 25) {
      return '🦵 Отлично! $reps приседаний - хороший уровень.\n\n'
          'Программа для роста:\n'
          '• Приседания на одной ноге (с опорой): 3x8\n'
          '• Прыжковые приседания: 3x15\n'
          '• Выпады с прыжком: 3x12\n'
          '• Болгарские выпады: 3x10\n\n'
          'Цель - 50+ приседаний! ⚡';
    } else {
      return '🦵 $reps приседаний - хорошее начало!\n\n'
          'Программа для новичков:\n'
          '• Приседания: 4x20\n'
          '• Выпады: 3x12 на ногу\n'
          '• Приседания у стены: 3x30 сек\n'
          '• Подъем на носки: 3x20\n\n'
          'Через месяц будет 30+ приседаний! 🚀';
    }
  }
}
