/// Satu balon pesan pada layar chat AI.
library;

enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.isStreaming = false,
    this.fromCache = false,
  });

  final ChatRole role;
  final String text;

  /// `true` selama token masih mengalir dari AI API.
  final bool isStreaming;

  /// `true` bila jawaban diambil dari cache lokal, bukan request baru.
  final bool fromCache;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({String? text, bool? isStreaming, bool? fromCache}) {
    return ChatMessage(
      role: role,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}
