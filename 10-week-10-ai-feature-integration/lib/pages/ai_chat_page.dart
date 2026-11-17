import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ai/ai_chat_controller.dart';
import '../ai/ai_providers.dart';
import '../widgets/chat_bubble.dart';

/// Pertanyaan contoh agar pengguna baru tidak melihat layar kosong tanpa arah.
const List<String> _suggestions = [
  'Catatan apa saja yang saya punya?',
  'Catatan tentang tugas?',
  'Ringkas catatan terbaru saya',
];

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(aiChatControllerProvider.notifier).send(text);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatControllerProvider);
    ref.listen(aiChatControllerProvider, (_, _) => _scrollToEnd());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanya Catatan'),
        actions: [
          IconButton(
            onPressed: state.isEmpty
                ? null
                : () => ref.read(aiChatControllerProvider.notifier).clear(),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus percakapan',
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan AI',
          ),
        ],
      ),
      body: Column(
        children: [
          const _PrivacyNote(),
          Expanded(
            child: state.isEmpty
                ? _EmptyState(onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) =>
                        ChatBubble(message: state.messages[index]),
                  ),
          ),
          if (state.failure != null) _FailureBanner(failure: state.failure!),
          _Composer(
            controller: _input,
            isSending: state.isSending,
            onSend: _send,
            onStop: () => ref.read(aiChatControllerProvider.notifier).stop(),
          ),
        ],
      ),
    );
  }
}

/// Pengingat tetap bahwa isi catatan disamarkan sebelum dikirim.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.secondaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'NIK, nomor telepon, dan email disamarkan sebelum dikirim ke AI.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.auto_awesome, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Tanya apa saja tentang catatan Anda',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Jawaban diambil dari catatan yang tersimpan di perangkat ini.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in _suggestions)
              ActionChip(
                label: Text(suggestion),
                onPressed: () => onPick(suggestion),
              ),
          ],
        ),
      ],
    );
  }
}

/// Pengganti dialog "Layanan AI Sibuk" pada codelab.
///
/// Banner dipilih karena tetap terlihat selama pengguna memutuskan, tidak
/// menutupi jawaban terakhir, dan kedua aksi pemulihan ada di satu tempat.
class _FailureBanner extends ConsumerWidget {
  const _FailureBanner({required this.failure});

  final AiFailure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(aiChatControllerProvider.notifier);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_off,
                size: 18,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  failure.retryable
                      ? 'Layanan AI Sibuk'
                      : 'Fitur AI belum siap',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            failure.message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              if (failure.retryable)
                TextButton.icon(
                  onPressed: controller.retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              TextButton.icon(
                onPressed: controller.answerOffline,
                icon: const Icon(Icons.offline_bolt),
                label: const Text('Mode offline'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final bool isSending;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: isSending ? null : onSend,
                decoration: const InputDecoration(
                  hintText: 'Tulis pertanyaan...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? onStop : () => onSend(controller.text),
              icon: Icon(isSending ? Icons.stop : Icons.send),
              tooltip: isSending ? 'Hentikan' : 'Kirim',
            ),
          ],
        ),
      ),
    );
  }
}
