/// Orkestrasi percakapan AI: cache -> kuota -> streaming -> fallback.
///
/// Semua keputusan yang mempengaruhi biaya, privasi, dan pemulihan error
/// dikumpulkan di sini supaya widget chat tetap tipis dan bisa diuji tanpa
/// widget tree.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/note_providers.dart';
import 'ai_cache.dart';
import 'ai_client.dart';
import 'ai_providers.dart';
import 'chat_message.dart';
import 'local_answer.dart';
import 'prompt_builder.dart';

/// Kegagalan yang perlu ditampilkan beserta aksi pemulihannya.
class AiFailure {
  const AiFailure({
    required this.question,
    required this.message,
    required this.retryable,
  });

  final String question;
  final String message;
  final bool retryable;
}

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.failure,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final AiFailure? failure;

  bool get isEmpty => messages.isEmpty;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    AiFailure? failure,
    bool clearFailure = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class AiChatController extends Notifier<AiChatState> {
  StreamSubscription<String>? _subscription;

  @override
  AiChatState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const AiChatState();
  }

  /// Mengirim [rawQuestion] ke AI.
  ///
  /// Urutan langkahnya sengaja tetap: cache lebih dulu (gratis), baru kuota
  /// (murah), baru jaringan (mahal). Dengan begitu pertanyaan berulang tidak
  /// pernah memotong kuota maupun biaya.
  Future<void> send(String rawQuestion) async {
    final question = rawQuestion.trim();
    if (question.isEmpty || state.isSending) return;

    await _subscription?.cancel();
    _subscription = null;

    final notes = await _loadNotes();
    final fingerprint = notesFingerprint(notes.map((note) => note.updatedAt));
    final cache = ref.read(aiCacheProvider);

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.user, text: question),
      ],
      isSending: true,
      clearFailure: true,
    );

    final cached = await cache.read(question, fingerprint);
    if (cached != null) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(role: ChatRole.assistant, text: cached, fromCache: true),
        ],
        isSending: false,
      );
      return;
    }

    final allowed = await ref.read(aiQuotaProvider).tryConsume();
    if (!allowed) {
      _fail(
        question,
        'Kuota harian untuk fitur AI sudah habis. Pakai mode offline atau '
        'coba lagi besok.',
        retryable: false,
      );
      return;
    }

    final AiClient client;
    try {
      client = await ref.read(aiClientProvider.future);
    } on AiException catch (error) {
      _fail(question, error.message, retryable: error.retryable);
      return;
    }

    final request = AiRequest(
      question: question,
      systemPrompt: PromptBuilder.systemPrompt,
      userPrompt: PromptBuilder.buildUserPrompt(
        question: question,
        notes: notes,
      ),
      notes: notes,
    );

    state = state.copyWith(
      messages: [
        ...state.messages,
        const ChatMessage(
          role: ChatRole.assistant,
          text: '',
          isStreaming: true,
        ),
      ],
    );

    final completer = Completer<void>();
    _subscription = client
        .streamAnswer(request)
        .listen(
          _appendDelta,
          onError: (Object error) {
            if (!completer.isCompleted) completer.completeError(error);
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );

    try {
      await completer.future;
    } on AiException catch (error) {
      _fail(question, error.message, retryable: error.retryable);
      return;
    } on Object {
      _fail(
        question,
        'Gagal memanggil AI API. Coba lagi nanti.',
        retryable: true,
      );
      return;
    }

    _finishStreaming();

    final answer = state.messages.isEmpty ? '' : state.messages.last.text;
    if (answer.trim().isEmpty) {
      _fail(
        question,
        'AI tidak mengembalikan jawaban. Coba pertanyaan lain atau mode offline.',
        retryable: true,
      );
      return;
    }
    await cache.write(question, fingerprint, answer);
  }

  /// Menghentikan streaming dan mempertahankan teks yang sudah masuk.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _finishStreaming();
    if (state.isSending) state = state.copyWith(isSending: false);
  }

  /// Menjawab dari data lokal tanpa menyentuh jaringan.
  ///
  /// Ini fallback yang dijanjikan tabel risiko: saat AI API error, pengguna
  /// tetap mendapat jawaban dari catatan sendiri.
  Future<void> answerOffline() async {
    final failure = state.failure;
    final question = failure?.question ?? _lastUserQuestion();
    if (question == null) return;

    await stop();
    final notes = await _loadNotes();
    final answer = buildLocalAnswer(question: question, notes: notes);
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          role: ChatRole.assistant,
          text: 'Mode offline: $answer',
          fromCache: true,
        ),
      ],
      isSending: false,
      clearFailure: true,
    );
  }

  Future<void> retry() async {
    final question = state.failure?.question;
    if (question == null) return;
    state = state.copyWith(clearFailure: true);
    await send(question);
  }

  Future<void> clear() async {
    await stop();
    state = const AiChatState();
  }

  void _appendDelta(String delta) {
    if (delta.isEmpty || state.messages.isEmpty) return;
    final messages = [...state.messages];
    final last = messages.removeLast();
    messages.add(last.copyWith(text: '${last.text}$delta'));
    state = state.copyWith(messages: messages);
  }

  void _finishStreaming() {
    if (state.messages.isEmpty) return;
    final messages = [...state.messages];
    final last = messages.removeLast();
    messages.add(last.copyWith(isStreaming: false));
    state = state.copyWith(messages: messages, isSending: false);
  }

  void _fail(String question, String message, {required bool retryable}) {
    final messages = [...state.messages];
    if (messages.isNotEmpty && messages.last.isStreaming) messages.removeLast();
    state = AiChatState(
      messages: messages,
      isSending: false,
      failure: AiFailure(
        question: question,
        message: message,
        retryable: retryable,
      ),
    );
  }

  Future<List<Note>> _loadNotes() async {
    try {
      return await ref.read(notesProvider.future);
    } on Object {
      // AI tetap boleh menjawab tanpa konteks; lebih baik daripada layar error.
      return const [];
    }
  }

  String? _lastUserQuestion() {
    for (final message in state.messages.reversed) {
      if (message.isUser) return message.text;
    }
    return null;
  }
}
