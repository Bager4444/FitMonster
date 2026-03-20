/// Сообщение в AI чате
class AiMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final AiMessageType type;

  const AiMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = AiMessageType.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      type: AiMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AiMessageType.text,
      ),
    );
  }
}

enum AiMessageType {
  text,
  workout,
  nutrition,
  motivation,
}
