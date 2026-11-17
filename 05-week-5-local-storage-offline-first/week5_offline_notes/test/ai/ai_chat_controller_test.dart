import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/ai/ai_cache.dart';
import 'package:week5_offline_notes/ai/ai_client.dart';
import 'package:week5_offline_notes/ai/ai_key_store.dart';
import 'package:week5_offline_notes/ai/ai_providers.dart';
import 'package:week5_offline_notes/ai/ai_quota.dart';
import 'package:week5_offline_notes/ai/chat_message.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/note_providers.dart';

class _FakeAiClient implements AiClient {
  _FakeAiClient({this.error});

  final AiException? error;

  int calls = 0;

  @override
  String get label => 'fake';

  @override
  Stream<String> streamAnswer(AiRequest request) async* {
    calls++;
    // Panggilan pertama gagal (bila [error] diisi), panggilan berikutnya
    // berhasil - supaya tombol "Coba lagi" bisa diuji tanpa mengganti klien.
    if (error != null && calls == 1) throw error!;
    yield 'Ada ';
    yield 'satu ';
    yield 'catatan.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final notes = [
    Note(
      title: 'Tugas Mobile',
      body: 'Kumpulkan Jumat.',
      updatedAt: DateTime(2026, 11, 17),
    ),
  ];

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer buildContainer({
    required _FakeAiClient client,
    int dailyLimit = 30,
  }) {
    final container = ProviderContainer(
      overrides: [
        notesProvider.overrideWith((ref) async => notes),
        aiClientProvider.overrideWith((ref) async => client),
        aiCacheProvider.overrideWithValue(
          AiCache(prefs: prefs, now: () => DateTime(2026, 11, 17)),
        ),
        aiQuotaProvider.overrideWithValue(
          AiQuota(
            prefs: prefs,
            now: () => DateTime(2026, 11, 17),
            dailyLimit: dailyLimit,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('mengirim pertanyaan lalu menampilkan jawaban streaming', () async {
    final client = _FakeAiClient();
    final container = buildContainer(client: client);

    await container.read(aiChatControllerProvider.notifier).send('tugas?');

    final state = container.read(aiChatControllerProvider);
    expect(state.messages, hasLength(2));
    expect(state.messages.first.role, ChatRole.user);
    expect(state.messages.last.text, 'Ada satu catatan.');
    expect(state.messages.last.isStreaming, isFalse);
    expect(state.isSending, isFalse);
    expect(client.calls, 1);
  });

  test(
    'pertanyaan berulang dilayani cache tanpa memanggil klien lagi',
    () async {
      final client = _FakeAiClient();
      final container = buildContainer(client: client);
      final controller = container.read(aiChatControllerProvider.notifier);

      await controller.send('tugas?');
      await controller.send('tugas?');

      final state = container.read(aiChatControllerProvider);
      expect(client.calls, 1);
      expect(state.messages.last.fromCache, isTrue);
      expect(state.messages.last.text, 'Ada satu catatan.');
    },
  );

  test('kuota habis tidak memanggil klien dan memberi pesan jelas', () async {
    final client = _FakeAiClient();
    final container = buildContainer(client: client, dailyLimit: 0);

    await container.read(aiChatControllerProvider.notifier).send('tugas?');

    final state = container.read(aiChatControllerProvider);
    expect(client.calls, 0);
    expect(state.failure, isNotNull);
    expect(state.failure!.message, contains('Kuota harian'));
    expect(state.failure!.retryable, isFalse);
    expect(state.isSending, isFalse);
  });

  test('error klien menyimpan kegagalan dan bisa diulang', () async {
    final client = _FakeAiClient(
      error: const AiException('Layanan AI sedang sibuk (503).'),
    );
    final container = buildContainer(client: client);
    final controller = container.read(aiChatControllerProvider.notifier);

    await controller.send('tugas?');

    var state = container.read(aiChatControllerProvider);
    expect(state.failure!.message, contains('sibuk'));
    expect(state.failure!.retryable, isTrue);
    expect(state.messages.last.isStreaming, isFalse);
    expect(state.messages.where((m) => m.isStreaming), isEmpty);

    await controller.retry();

    state = container.read(aiChatControllerProvider);
    expect(client.calls, 2);
    expect(state.failure, isNull);
  });

  test('mode offline menjawab dari catatan lokal tanpa klien', () async {
    final client = _FakeAiClient(
      error: const AiException('Tidak ada koneksi internet.'),
    );
    final container = buildContainer(client: client);
    final controller = container.read(aiChatControllerProvider.notifier);

    await controller.send('tugas');
    await controller.answerOffline();

    final state = container.read(aiChatControllerProvider);
    expect(client.calls, 1);
    expect(state.failure, isNull);
    expect(state.messages.last.text, startsWith('Mode offline:'));
    expect(state.messages.last.text, contains('Tugas Mobile'));
  });

  test(
    'mode non-demo tanpa key gagal cepat dan menampilkan fallback',
    () async {
      // Regresi: FutureProvider yang melempar error akan di-retry otomatis oleh
      // Riverpod 3 dengan backoff, sehingga layar chat menggantung di keadaan
      // "mengirim" dan banner error tidak pernah muncul.
      SharedPreferences.setMockInitialValues({'ai_demo_mode': false});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          notesProvider.overrideWith((ref) async => notes),
          aiKeyStoreProvider.overrideWithValue(MemoryAiKeyStore()),
          aiCacheProvider.overrideWithValue(AiCache(prefs: prefs)),
          aiQuotaProvider.overrideWithValue(
            AiQuota(prefs: prefs, now: () => DateTime(2026, 11, 17)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(aiChatControllerProvider.notifier)
          .send('tugas?')
          .timeout(const Duration(seconds: 2));

      final state = container.read(aiChatControllerProvider);
      expect(state.isSending, isFalse);
      expect(state.failure, isNotNull);
      expect(state.failure!.message, contains('API key belum diatur'));
      expect(state.failure!.retryable, isFalse);
    },
  );

  test('clear mengosongkan percakapan', () async {
    final container = buildContainer(client: _FakeAiClient());
    final controller = container.read(aiChatControllerProvider.notifier);

    await controller.send('tugas?');
    await controller.clear();

    expect(container.read(aiChatControllerProvider).isEmpty, isTrue);
  });
}
