import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitmonster/core/config/openrouter_user_key.dart';
import 'package:fitmonster/core/models/user_account.dart';
import 'package:fitmonster/core/services/auth_service.dart';
import 'package:fitmonster/features/ai/domain/models/ai_message.dart';
import 'package:fitmonster/core/services/user_account_service.dart';
import 'package:fitmonster/features/profile/services/profile_service.dart';
import 'package:fitmonster/features/profile/domain/models/app_profile.dart';
import 'package:fitmonster/core/services/hive_service.dart';

/// AI-сервис через OpenRouter (OpenAI-совместимый chat completions).
class OpenRouterAiService {
  static const String _messagesBox = HiveService.userBox;
  static const String _messagesKeyPrefix = 'ai_messages_';

  static const String _apiUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _prefsApiKey = 'openrouter_api_key';
  static const String _apiKeyFromCompile = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );
  static const String _model = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: 'google/gemma-3n-e4b-it:free',
  );
  /// Для лидерборда OpenRouter (опционально); пусто — заголовок не шлём.
  static const String _httpReferer = String.fromEnvironment(
    'OPENROUTER_HTTP_REFERER',
    defaultValue: '',
  );

  /// Облачный прокси (Firebase Callable): после `firebase deploy` включи
  /// `--dart-define=AI_USE_CLOUD_PROXY=true`, иначе будет NOT_FOUND.
  static const bool _useCloudProxy = bool.fromEnvironment(
    'AI_USE_CLOUD_PROXY',
    defaultValue: false,
  );

  /// Регион должен совпадать с `region` в `functions/index.js`.
  static const String _functionsRegion = String.fromEnvironment(
    'FIREBASE_FUNCTIONS_REGION',
    defaultValue: 'europe-west1',
  );

  bool _firebaseReady() => Firebase.apps.isNotEmpty;

  bool _canUseCloudProxy() =>
      _useCloudProxy &&
      _firebaseReady() &&
      FirebaseAuth.instance.currentUser != null;

  /// Ключ: файл [kOpenRouterUserApiKey], затем SharedPreferences, затем `--dart-define=OPENROUTER_API_KEY=...`.
  Future<String> resolveApiKey() async {
    final fromFile = kOpenRouterUserApiKey.trim();
    if (fromFile.isNotEmpty) return fromFile;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsApiKey)?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return _apiKeyFromCompile.trim();
  }

  Future<bool> isApiKeyConfigured() async {
    if (_canUseCloudProxy()) return true;
    final k = await resolveApiKey();
    return k.isNotEmpty;
  }

  Future<bool> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final t = key.trim();
    if (t.isEmpty) {
      await prefs.remove(_prefsApiKey);
      await prefs.reload();
      return prefs.getString(_prefsApiKey) == null;
    }
    final written = await prefs.setString(_prefsApiKey, t);
    await prefs.reload();
    final read = prefs.getString(_prefsApiKey);
    return written && read == t;
  }

  Future<void> clearStoredApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsApiKey);
  }

  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final UserAccountService _userAccountService = UserAccountService();

  String _messagesKey() {
    final userId = _authService.currentUserId ?? 'guest';
    return '$_messagesKeyPrefix$userId';
  }

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

  Future<void> _saveMessages(List<AiMessage> messages) async {
    final data = messages.map((m) => m.toJson()).toList();
    await HiveService.put(box: _messagesBox, key: _messagesKey(), value: data);
  }

  Future<AiMessage> sendMessage(String userMessage) async {
    final messages = await getMessages();

    final userMsg = AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMsg);
    await _saveMessages(messages);

    final aiResponse = await _generateAiResponse(userMessage, messages);
    messages.add(aiResponse);

    await _saveMessages(messages);
    return aiResponse;
  }

  Map<String, String> _requestHeaders(String apiKey) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'X-OpenRouter-Title': 'FitMonster',
    };
    final ref = _httpReferer.trim();
    if (ref.isNotEmpty) {
      h['HTTP-Referer'] = ref;
    }
    return h;
  }

  Future<AiMessage?> _generateViaCloud(List<Map<String, String>> apiMessages) async {
    final callable = FirebaseFunctions.instanceFor(region: _functionsRegion).httpsCallable(
      'openrouterChat',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
    );
    final payload = <String, dynamic>{
      'messages': apiMessages
          .map((m) => <String, dynamic>{'role': m['role']!, 'content': m['content']!})
          .toList(),
      'model': _model,
    };
    final result = await callable.call(payload);
    final raw = result.data;
    if (raw is! Map) return null;
    final text = raw['content'];
    if (text is! String || text.trim().isEmpty) return null;
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: false,
      timestamp: DateTime.now(),
      type: _detectMessageType(text),
    );
  }

  Future<AiMessage> _generateAiResponse(
    String userMessage,
    List<AiMessage> history,
  ) async {
    try {
      final profile = await _profileService.getAppProfile();
      final xp = await _profileService.getExperience();
      final level = ProfileService.levelFromXp(xp);
      final userId = _authService.currentUserId;
      final account = userId == null
          ? null
          : await _userAccountService.getByUserId(userId);

      final systemPrompt = _buildSystemPrompt(profile, level, account);
      final apiMessages = _buildOpenRouterMessages(history, systemPrompt);

      if (_canUseCloudProxy()) {
        try {
          final cloud = await _generateViaCloud(apiMessages);
          if (cloud != null) return cloud;
        } on FirebaseFunctionsException catch (e, st) {
          if (kDebugMode) {
            debugPrint('OpenRouter cloud: ${e.code} ${e.message}\n$st');
          }
          final apiKey = await resolveApiKey();
          if (apiKey.isEmpty) {
            return _getFallbackResponse(
              userMessage,
              prefix: _prefixForCloudFailure(e),
            );
          }
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('OpenRouter cloud: $e\n$st');
          }
          final apiKey = await resolveApiKey();
          if (apiKey.isEmpty) {
            return _getFallbackResponse(
              userMessage,
              prefix:
                  'Облачный ИИ временно недоступен.\n'
                  'Войди по почте и проверь деплой функции openrouterChat, либо укажи свой ключ OpenRouter.\n\n'
                  'Офлайн-подсказка:',
            );
          }
        }
      }

      final apiKey = await resolveApiKey();
      if (apiKey.isEmpty) {
        return _getNoApiKeyResponse();
      }

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: _requestHeaders(apiKey),
            body: jsonEncode({
              'model': _model,
              'messages': apiMessages,
              'temperature': 0.7,
              'max_tokens': 1800,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final aiContent = _parseOpenRouterAssistantText(data);
        if (aiContent != null && aiContent.isNotEmpty) {
          return AiMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: aiContent.trim(),
            isUser: false,
            timestamp: DateTime.now(),
            type: _detectMessageType(aiContent),
          );
        }
        return _getFallbackResponse(
          userMessage,
          prefix: 'Пустой ответ модели. Офлайн-подсказка:',
        );
      }

      final errDetail = _parseOpenRouterErrorBody(response.bodyBytes);
      final code = response.statusCode;
      if (code == 429) {
        return _getFallbackResponse(
          userMessage,
          prefix:
              'Превышен лимит OpenRouter (429). Подожди или проверь квоту на https://openrouter.ai/docs/faq\n\n'
              'Офлайн-подсказка:',
        );
      }
      if (code == 401 || code == 402) {
        return _getFallbackResponse(
          userMessage,
          prefix:
              'Ключ OpenRouter отклонён или нет кредитов (код $code)${errDetail != null ? ': $errDetail' : ''}.\n'
              'Проверь https://openrouter.ai/credits и ключ на https://openrouter.ai/keys\n\n'
              'Офлайн-подсказка:',
        );
      }
      return _getFallbackResponse(
        userMessage,
        prefix:
            'Не удалось получить ответ ИИ (код $code)${errDetail != null ? ': $errDetail' : ''}.\n'
            'Проверь ключ на https://openrouter.ai/keys , модель $_model (список: https://openrouter.ai/models ) и интернет.\n'
            'Офлайн-подсказка:',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('OpenRouterAiService: $e\n$st');
      }
      return _getFallbackResponse(
        userMessage,
        prefix:
            'Ошибка сети или таймаут.\n'
            'Повтори запрос позже.\n'
            'Офлайн-подсказка:',
      );
    }
  }

  String _prefixForCloudFailure(FirebaseFunctionsException e) {
    final code = e.code;
    final msg = (e.message ?? '').trim();
    final msgUp = msg.toUpperCase();
    if (code == 'unauthenticated') {
      return 'Нужен вход по почте в приложении (Firebase), чтобы использовать общий ИИ без своего ключа.\n\n'
          'Офлайн-подсказка:';
    }
    if (code == 'failed-precondition') {
      return 'На сервере не задан секрет OPENROUTER_API_KEY (см. functions/README.md).\n\nОфлайн-подсказка:';
    }
    // Частая причина: функция не задеплоена или регион в приложении ≠ регион деплоя.
    if (code == 'not-found' ||
        code == 'functions/not-found' ||
        msgUp.contains('NOT_FOUND')) {
      return 'Облачная функция openrouterChat не найдена в Firebase (NOT_FOUND).\n\n'
          'Что сделать:\n'
          '• В каталоге проекта: firebase deploy --only functions\n'
          '• Задать секрет: firebase functions:secrets:set OPENROUTER_API_KEY\n'
          '• Регион в приложении сейчас: $_functionsRegion — должен совпадать с region в functions/index.js\n'
          '• Проект Firebase в google-services.json = тот же, куда деплоишь\n\n'
          'Пока без сервера: сборка с --dart-define=AI_USE_CLOUD_PROXY=false и свой ключ OpenRouter (файл или меню ⋮).\n\n'
          'Офлайн-подсказка:';
    }
    return 'Облачный ИИ: $code${msg.isNotEmpty ? ' $msg' : ''}\n\nОфлайн-подсказка:';
  }

  List<Map<String, String>> _buildOpenRouterMessages(
    List<AiMessage> history,
    String systemPrompt,
  ) {
    const maxTurns = 12;
    const maxCharsPerMessage = 3200;
    final slice = history.length > maxTurns
        ? history.sublist(history.length - maxTurns)
        : history;

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];
    for (final msg in slice) {
      var text = msg.content;
      if (text.length > maxCharsPerMessage) {
        text = '${text.substring(0, maxCharsPerMessage)}…';
      }
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': text,
      });
    }
    return messages;
  }

  String? _parseOpenRouterAssistantText(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices[0];
    if (first is! Map<String, dynamic>) return null;
    final message = first['message'];
    if (message is! Map<String, dynamic>) return null;
    final raw = message['content'];
    if (raw is String) {
      final s = raw.trim();
      return s.isEmpty ? null : s;
    }
    return null;
  }

  String? _parseOpenRouterErrorBody(List<int> bodyBytes) {
    try {
      final data = jsonDecode(utf8.decode(bodyBytes));
      if (data is! Map<String, dynamic>) return null;
      final err = data['error'];
      if (err is Map<String, dynamic> && err['message'] is String) {
        return err['message'] as String;
      }
    } catch (_) {}
    return null;
  }

  AiMessage _getNoApiKeyResponse() {
    final cloudHint = _useCloudProxy && _firebaseReady()
        ? 'Если задеплоена функция openrouterChat: войди по почте в приложении — '
            'общий ИИ работает без ключа на устройстве (см. functions/README.md).\n\n'
        : '';
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content:
          '⚙️ Нет доступа к OpenRouter.\n\n'
          '$cloudHint'
          'Свой ключ: файл lib/core/config/openrouter_user_key.dart '
          '(kOpenRouterUserApiKey) — https://openrouter.ai/keys\n\n'
          'Или меню ⋮ → «Ключ API OpenRouter», '
          'либо сборка: --dart-define=OPENROUTER_API_KEY=...\n\n'
          'Пока отвечаю офлайн по встроенной базе знаний 💪',
      isUser: false,
      timestamp: DateTime.now(),
      type: AiMessageType.text,
    );
  }

  AiMessage _getFallbackResponse(String userMessage, {String? prefix}) {
    final lower = userMessage.toLowerCase();
    String content;
    AiMessageType type = AiMessageType.text;

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
    } else if (lower.contains('после тренировки') ||
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
    } else if (lower.contains('мотивац') ||
        lower.contains('устал') ||
        lower.contains('лень') ||
        lower.contains('не хочу')) {
      content = _getMotivation();
      type = AiMessageType.motivation;
    } else if (lower.contains('трениров') ||
        lower.contains('упражн') ||
        lower.contains('начать')) {
      content = _getGeneralWorkout();
      type = AiMessageType.workout;
    } else if (lower.contains('восстановление') ||
        lower.contains('отдых') ||
        lower.contains('болят')) {
      content = _getRecoveryInfo();
      type = AiMessageType.text;
    } else if (lower.contains('привет') ||
        lower.contains('здравствуй') ||
        lower.contains('hello')) {
      content = _getGreeting();
      type = AiMessageType.text;
    } else {
      content = _getDefaultResponse();
      type = AiMessageType.text;
    }

    final fullContent =
        prefix != null && prefix.trim().isNotEmpty
            ? '${prefix.trim()}\n\n$content'
            : content;
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: fullContent,
      isUser: false,
      timestamp: DateTime.now(),
      type: type,
    );
  }

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

МЕДИЦИНСКИЙ ДИСКЛЕЙМЕР:
- Ты не врач и не заменяешь консультацию специалиста.
- При острой боли, головокружении, одышке в покое, подозрении на травму — советуй обратиться к врачу и не давай нагрузку «на свой страх и риск».

ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ:
- Имя: ${profile.displayName}
- Уровень: $level
- Подписка: $subscription
- Рейтинг (мир/регион): $worldRank / $regionRank
- Средний процент техники: $avgScore%
- Упражнений в учёте (всего): ${account?.totalExercises ?? 0}
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

  Future<void> clearHistory() async {
    await HiveService.delete(box: _messagesBox, key: _messagesKey());
  }
}
