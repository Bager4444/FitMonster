import 'package:flutter/material.dart';
import 'package:fitmonster/core/theme/glass_theme.dart';
import 'package:fitmonster/features/ai/domain/models/ai_message.dart';
import 'package:fitmonster/features/ai/services/openrouter_ai_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final OpenRouterAiService _aiService = OpenRouterAiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<AiMessage> _messages = [];
  bool _isLoading = false;
  /// null — ещё не проверяли; иначе настроен ли ключ OpenRouter (файл, хранилище или dart-define).
  bool? _openRouterConnected;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _refreshOpenRouterStatus();
  }

  Future<void> _refreshOpenRouterStatus() async {
    final ok = await _aiService.isApiKeyConfigured();
    if (mounted) setState(() => _openRouterConnected = ok);
  }

  Future<void> _showOpenRouterKeyDialog() async {
    final hadKey = await _aiService.isApiKeyConfigured();
    final fromPrefs = await _aiService.prefsStoredKeyForDialog();
    final controller = TextEditingController(text: fromPrefs);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.fm.dialogBackground,
        title: Text(
          'Подключение OpenRouter',
          style: context.fm.titleStyle.copyWith(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Сохранённый здесь ключ хранится на устройстве. '
                'Ключ из .dart-файла в поле не показывается — после правки файла нужен новый APK.\n'
                'Создать ключ: https://openrouter.ai/keys',
                style: context.fm.bodyStyle,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                autocorrect: false,
                keyboardType: TextInputType.visiblePassword,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'sk-or-v1-...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.fm.glowCyan),
                  ),
                ),
                style: TextStyle(color: context.fm.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          if (hadKey)
            TextButton(
              onPressed: () async {
                await _aiService.clearStoredApiKey();
                if (ctx.mounted) Navigator.of(ctx).pop();
                await _refreshOpenRouterStatus();
              },
              child: Text('Удалить ключ', style: TextStyle(color: Colors.red.shade200)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Отмена', style: context.fm.bodyStyle.copyWith(color: context.fm.textPrimary)),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await _aiService.saveApiKey(controller.text);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              await _refreshOpenRouterStatus();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Ключ сохранён на этом устройстве'
                        : 'Не удалось записать ключ — открой настройки приложения и проверь память',
                  ),
                  backgroundColor: ok ? context.fm.gradientHeaderTop : Colors.red.shade800,
                ),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _loadMessages() async {
    final messages = await _aiService.getMessages();
    setState(() {
      _messages = messages;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      await _aiService.sendMessage(text);
      await _loadMessages();
      await _refreshOpenRouterStatus();
    } catch (e, st) {
      debugPrint('Error sending message: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось отправить: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: context.fm.scaffoldGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: _buildInputArea(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: context.fm.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.fm.gradientHeaderTop, context.fm.gradientHeaderBottom],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.smart_toy,
              color: context.fm.isDark ? Colors.white : context.fm.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Ассистент',
                  style: context.fm.titleStyle.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                GestureDetector(
                  onTap: _openRouterConnected != true ? _showOpenRouterKeyDialog : null,
                  child: Text(
                    _openRouterConnected == null
                        ? 'Проверка OpenRouter…'
                        : _openRouterConnected!
                            ? 'Онлайн · OpenRouter'
                            : 'Офлайн — нажми сюда или ⋮ → Ключ API',
                    style: context.fm.bodyStyle.copyWith(
                      fontSize: 11,
                      color: _openRouterConnected == true
                          ? context.fm.glowCyan
                          : context.fm.glowCyan.withValues(alpha: 0.85),
                      decoration: _openRouterConnected != true
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: context.fm.textPrimary),
            tooltip: 'Меню',
            color: context.fm.dialogBackground,
            onSelected: (value) async {
              if (value == 'key') {
                await _showOpenRouterKeyDialog();
              } else if (value == 'clear') {
                await _aiService.clearHistory();
                await _loadMessages();
              }
            },
            itemBuilder: (menuContext) => [
              PopupMenuItem(
                value: 'key',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.vpn_key_rounded, color: menuContext.fm.glowCyan),
                  title: Text('Ключ API OpenRouter', style: TextStyle(color: menuContext.fm.textPrimary)),
                  subtitle: Text(
                    'Или в файл openrouter_user_key.dart — openrouter.ai/keys',
                    style: TextStyle(color: menuContext.fm.textSecondary, fontSize: 12),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: menuContext.fm.textSecondary),
                  title: Text('Очистить чат', style: TextStyle(color: menuContext.fm.textPrimary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.fm.gradientHeaderTop, context.fm.gradientHeaderBottom],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.smart_toy, color: context.fm.textPrimary, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Привет! Я ваш AI тренер',
              style: context.fm.titleStyle.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Задайте вопрос о тренировках, питании или мотивации',
              style: context.fm.bodyStyle,
              textAlign: TextAlign.center,
            ),
            if (_openRouterConnected != true) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _showOpenRouterKeyDialog,
                icon: Icon(Icons.vpn_key_rounded, color: context.fm.glowCyan),
                label: Text(
                  'Ввести ключ OpenRouter',
                  style: TextStyle(color: context.fm.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.fm.glowCyan),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Без ключа ответы только офлайн. Ключ — в меню ⋮ справа вверху.',
                style: context.fm.bodyStyle.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickQuestion('Как начать тренироваться?'),
                _buildQuickQuestion('Что есть после тренировки?'),
                _buildQuickQuestion('План на неделю с моим уровнем'),
                _buildQuickQuestion('Мотивируй меня!'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestion(String question) {
    return GestureDetector(
      onTap: () {
        _controller.text = question;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          question,
          style: context.fm.bodyStyle.copyWith(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(AiMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: message.isUser
              ? LinearGradient(
                  colors: [context.fm.gradientHeaderTop, context.fm.gradientHeaderBottom],
                )
              : null,
          color: message.isUser ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.isUser
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) _buildMessageTypeIcon(message.type),
            SelectableText(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.white : context.fm.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTypeIcon(AiMessageType type) {
    IconData icon;
    String label;
    
    switch (type) {
      case AiMessageType.workout:
        icon = Icons.fitness_center;
        label = 'Тренировки';
        break;
      case AiMessageType.nutrition:
        icon = Icons.restaurant;
        label = 'Питание';
        break;
      case AiMessageType.motivation:
        icon = Icons.emoji_events;
        label = 'Мотивация';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.fm.glowCyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.fm.glowCyan,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: context.fm.textPrimary),
              decoration: InputDecoration(
                hintText: 'Задайте вопрос...',
                hintStyle: TextStyle(color: context.fm.textSecondary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isLoading,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.fm.gradientHeaderTop, context.fm.gradientHeaderBottom],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
