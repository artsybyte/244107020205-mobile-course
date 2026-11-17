import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_providers.dart';
import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());
final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

/// Pengaturan fitur AI: mode demo, API key, kuota, dan cache.
///
/// Halaman ini satu-satunya tempat API key dimasukkan, sehingga kunci tidak
/// pernah melewati widget lain atau tersimpan di kode sumber.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _keyController = TextEditingController();
  bool _keyVisible = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    await ref.read(aiKeyStoreProvider).write(key);
    if (!mounted) return;

    _keyController.clear();
    ref.invalidate(aiHasKeyProvider);
    ref.invalidate(aiClientProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('API key disimpan di secure storage')),
    );
  }

  Future<void> _clearKey() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(aiKeyStoreProvider).clear();
    if (!mounted) return;
    ref.invalidate(aiHasKeyProvider);
    ref.invalidate(aiClientProvider);
    messenger.showSnackBar(const SnackBar(content: Text('API key dihapus')));
  }

  Future<void> _clearCache() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(aiCacheProvider).clear();
    if (!mounted) return;
    ref.invalidate(aiCacheCountProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Cache AI dibersihkan')),
    );
  }

  Future<void> _resetQuota() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(aiQuotaProvider).reset();
    if (!mounted) return;
    ref.invalidate(aiQuotaStatusProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Kuota harian direset')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final demoMode = ref.watch(aiDemoModeProvider);
    final hasKey = ref.watch(aiHasKeyProvider);
    final quota = ref.watch(aiQuotaStatusProvider);
    final cacheCount = ref.watch(aiCacheCountProvider);
    final darkMode = ref.watch(darkModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Mode AI',
            children: [
              demoMode.when(
                data: (isDemo) => Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mode demo'),
                      subtitle: Text(
                        isDemo
                            ? 'Jawaban dibuat dari catatan lokal, tanpa jaringan'
                            : 'Memakai Gemini API (butuh API key)',
                      ),
                      value: isDemo,
                      onChanged: (value) =>
                          ref.read(aiDemoModeProvider.notifier).set(value),
                    ),
                    if (!isDemo) _buildKeySection(hasKey),
                  ],
                ),
                error: (error, _) => Text('Gagal membaca preferensi: $error'),
                loading: () => const LinearProgressIndicator(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Kuota harian',
            children: [
              quota.when(
                data: (status) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${status.used} dari ${status.limit} request terpakai hari ini',
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: status.limit == 0 ? 0 : status.used / status.limit,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _resetQuota,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset kuota'),
                    ),
                  ],
                ),
                error: (error, _) => Text('Gagal membaca kuota: $error'),
                loading: () => const LinearProgressIndicator(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Cache jawaban',
            children: [
              cacheCount.when(
                data: (count) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$count jawaban tersimpan. Cache mengurangi biaya '
                        'request berulang.',
                      ),
                    ),
                    TextButton(
                      onPressed: count == 0 ? null : _clearCache,
                      child: const Text('Bersihkan'),
                    ),
                  ],
                ),
                error: (error, _) => Text('Gagal membaca cache: $error'),
                loading: () => const LinearProgressIndicator(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Tampilan',
            children: [
              darkMode.when(
                data: (value) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mode gelap'),
                  value: value,
                  onChanged: (_) =>
                      ref.read(darkModeProvider.notifier).toggle(),
                ),
                error: (error, _) => Text('Gagal membaca tema: $error'),
                loading: () => const LinearProgressIndicator(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeySection(AsyncValue<bool> hasKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _keyController,
          obscureText: !_keyVisible,
          decoration: InputDecoration(
            labelText: 'Gemini API key',
            border: const OutlineInputBorder(),
            helperText: 'Disimpan di secure storage, bukan di kode sumber.',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _keyVisible = !_keyVisible),
              icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility),
              tooltip: 'Tampilkan key',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _saveKey,
              icon: const Icon(Icons.save),
              label: const Text('Simpan key'),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: _clearKey, child: const Text('Hapus key')),
          ],
        ),
        const SizedBox(height: 8),
        hasKey.when(
          data: (value) => Text(
            value ? 'Status: key tersimpan' : 'Status: key belum tersedia',
          ),
          error: (error, _) => Text('Gagal membaca key: $error'),
          loading: () => const Text('Status: memeriksa key...'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
