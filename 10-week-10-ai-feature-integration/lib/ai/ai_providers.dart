/// Wiring Riverpod untuk lapisan AI.
///
/// Sama seperti fitur lain di project ini, widget tidak pernah membuat klien
/// sendiri; semuanya diambil dari provider agar bisa di-override pada test.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_cache.dart';
import 'ai_chat_controller.dart';
import 'ai_client.dart';
import 'ai_key_store.dart';
import 'ai_quota.dart';
import 'ai_settings.dart';
import 'demo_client.dart';
import 'gemini_client.dart';

final aiSettingsProvider = Provider<AiSettings>((ref) => AiSettings());

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => SecureAiKeyStore());

final aiCacheProvider = Provider<AiCache>((ref) => AiCache());

final aiQuotaProvider = Provider<AiQuota>((ref) => AiQuota());

class AiDemoModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(aiSettingsProvider).isDemoMode();

  Future<void> set(bool value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(aiSettingsProvider).setDemoMode(value);
      return value;
    });
  }
}

final aiDemoModeProvider = AsyncNotifierProvider<AiDemoModeNotifier, bool>(
  AiDemoModeNotifier.new,
);

/// Status kuota hari ini, dipakai halaman pengaturan.
final aiQuotaStatusProvider = FutureProvider<QuotaStatus>(
  (ref) => ref.watch(aiQuotaProvider).status(),
);

/// Jumlah jawaban yang tersimpan di cache lokal.
final aiCacheCountProvider = FutureProvider<int>(
  (ref) => ref.watch(aiCacheProvider).entryCount(),
);

/// Apakah API key sudah tersimpan di secure storage.
final aiHasKeyProvider = FutureProvider<bool>((ref) async {
  final key = await ref.watch(aiKeyStoreProvider).read();
  return key != null && key.trim().isNotEmpty;
});

/// Klien yang dipakai saat ini.
///
/// Mode demo dipilih lebih dulu; bila dimatikan tetapi key belum ada, provider
/// melempar [AiException] yang pesannya sudah siap ditampilkan.
///
/// `retry: null` penting: tanpa ini Riverpod 3 mengulang provider yang gagal
/// dengan backoff eksponensial, sehingga layar chat menggantung di keadaan
/// "mengirim" alih-alih menampilkan fallback.
final aiClientProvider = FutureProvider<AiClient>((ref) async {
  final demoMode = await ref.watch(aiDemoModeProvider.future);
  if (demoMode) return DemoAiClient();

  final apiKey = await ref.watch(aiKeyStoreProvider).read();
  if (apiKey == null || apiKey.trim().isEmpty) {
    throw const AiException(
      'API key belum diatur. Buka Pengaturan AI untuk mengisinya, '
      'atau aktifkan mode demo.',
      retryable: false,
    );
  }
  return GeminiClient(apiKey: apiKey.trim());
}, retry: (_, _) => null);

final aiChatControllerProvider =
    NotifierProvider<AiChatController, AiChatState>(AiChatController.new);
