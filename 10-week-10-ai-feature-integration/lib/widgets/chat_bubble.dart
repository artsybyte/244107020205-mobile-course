import 'package:flutter/material.dart';

import '../ai/chat_message.dart';

/// Satu balon pesan pada layar chat.
///
/// Widget ini murni presentasi: tidak memanggil provider dan tidak mengubah
/// state, sehingga mudah dipakai ulang di test maupun preview.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final background = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.text.isEmpty && message.isStreaming)
              Text(
                'Mengetik...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Text(
                message.isStreaming ? '${message.text}▌' : message.text,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            if (message.fromCache)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_pin, size: 12, color: foreground),
                    const SizedBox(width: 4),
                    Text(
                      'dari cache lokal',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
