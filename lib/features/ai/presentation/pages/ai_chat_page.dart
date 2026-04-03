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
    final controller = TextEditingController();
    final hadKey = await _aiService.isApiKeyConfigured();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        title: Text(
          'Подключение OpenRouter',
          style: GlassTheme.titleStyle.copyWith(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ключ проще вставить в файл lib/core/config/openrouter_user_key.dart '
                '(kOpenRouterUserApiKey). Сюда — только на этом устройстве: '
                'создай ключ на https://openrouter.ai/keys',
                style: GlassTheme.bodyStyle,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'sk-or-v1-...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: GlassTheme.glowCyan),
                  ),
                ),
                style: const TextStyle(color: GlassTheme.textPrimary),
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
            child: Text('Отмена', style: GlassTheme.bodyStyle.copyWith(color: GlassTheme.textPrimary)),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await _aiService.saveApiKey(controller.text);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              await _refreshOpenRouterStatus();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Ключ сохранён на этом устройстве'
                        : 'Не удалось записать ключ — открой настройки приложения и проверь память',
                  ),
                  backgroundColor: ok ? GlassTheme.gradientTop : Colors.red.shade800,
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
        decoration: const BoxDecoration(
          gradient: GlassTheme.scaffoldGradient,
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
            icon: const Icon(Icons.arrow_back, color: GlassTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [GlassTheme.gradientTop, GlassTheme.gradientBottom],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Ассистент',
                  style: GlassTheme.titleStyle.copyWith(fontSize: 18),
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
                    style: GlassTheme.bodyStyle.copyWith(
                      fontSize: 11,
                      color: _openRouterConnected == true
                          ? GlassTheme.glowCyan
                          : GlassTheme.glowCyan.withValues(alpha: 0.85),
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
            icon: const Icon(Icons.more_vert, color: GlassTheme.textPrimary),
            tooltip: 'Меню',
            color: const Color(0xFF0D1B2A),
            onSelected: (value) async {
              if (value == 'key') {
                await _showOpenRouterKeyDialog();
              } else if (value == 'clear') {
                await _aiService.clearHistory();
                await _loadMessages();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'key',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.vpn_key_rounded, color: GlassTheme.glowCyan),
                  title: Text('Ключ API OpenRouter', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Или в файл openrouter_user_key.dart — openrouter.ai/keys',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: Colors.white70),
                  title: Text('Очистить чат', style: TextStyle(color: Colors.white)),
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
                gradient: const LinearGradient(
                  colors: [GlassTheme.gradientTop, GlassTheme.gradientBottom],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Привет! Я ваш AI тренер',
              style: GlassTheme.titleStyle.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Задайте вопрос о тренировках, питании или мотивации',
              style: GlassTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            if (_openRouterConnected != true) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _showOpenRouterKeyDialog,
                icon: const Icon(Icons.vpn_key_rounded, color: GlassTheme.glowCyan),
                label: const Text(
                  'Ввести ключ OpenRouter',
                  style: TextStyle(color: GlassTheme.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GlassTheme.glowCyan),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Без ключа ответы только офлайн. Ключ — в меню ⋮ справа вверху.',
                style: GlassTheme.bodyStyle.copyWith(fontSize: 11),
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
          style: GlassTheme.bodyStyle.copyWith(fontSize: 12),
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
              ? const LinearGradient(
                  colors: [GlassTheme.gradientTop, GlassTheme.gradientBottom],
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
                color: message.isUser ? Colors.white : GlassTheme.textPrimary,
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
          Icon(icon, size: 16, color: GlassTheme.glowCyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: GlassTheme.glowCyan,
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
              style: const TextStyle(color: GlassTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Задайте вопрос...',
                hintStyle: TextStyle(color: GlassTheme.textSecondary),
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
              gradient: const LinearGradient(
                colors: [GlassTheme.gradientTop, GlassTheme.gradientBottom],
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
