/// Penyimpanan API key.
///
/// Kunci tidak pernah ditulis ke kode sumber maupun `shared_preferences`.
/// `flutter_secure_storage` memakai Keystore/Keychain; di web ia butuh konteks
/// aman (HTTPS atau localhost), jadi kegagalan platform ditangani dengan
/// mengembalikan `null` alih-alih membuat aplikasi crash.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AiKeyStore {
  Future<String?> read();
  Future<void> write(String apiKey);
  Future<void> clear();
}

class SecureAiKeyStore implements AiKeyStore {
  SecureAiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'ai_api_key';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on Object {
      // Web tanpa HTTPS, atau platform tanpa plugin: anggap belum ada key.
      return null;
    }
  }

  @override
  Future<void> write(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return;
    try {
      await _storage.write(key: _key, value: trimmed);
    } on Object {
      // Sengaja tidak diteruskan: UI akan menampilkan status "key belum
      // tersimpan" saat membaca ulang.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Object {
      // Tidak ada yang bisa dilakukan bila platform menolak; abaikan.
    }
  }
}

/// Penyimpanan di memori untuk test dan fallback saat secure storage tidak
/// tersedia. Tidak dipakai di build produksi.
class MemoryAiKeyStore implements AiKeyStore {
  MemoryAiKeyStore([this._value]);

  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String apiKey) async => _value = apiKey.trim();

  @override
  Future<void> clear() async => _value = null;
}
