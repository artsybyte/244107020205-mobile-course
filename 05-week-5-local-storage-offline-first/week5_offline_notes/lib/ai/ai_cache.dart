/// Cache jawaban AI di `shared_preferences`.
///
/// Tujuan utamanya biaya: pertanyaan yang sama tidak perlu dibayar dua kali.
/// Kunci cache adalah hash dari pertanyaan **dan** sidik jari catatan, sehingga
/// begitu catatan berubah, jawaban lama otomatis tidak dipakai lagi.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AiCache {
  factory AiCache({SharedPreferences? prefs, DateTime Function()? now}) =>
      AiCache._(prefs, now ?? DateTime.now);

  AiCache._(this._prefs, this._now);

  static const String _prefix = 'ai_cache_';
  static const int maxEntries = 20;

  SharedPreferences? _prefs;
  final DateTime Function() _now;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Kunci cache yang deterministik. Fungsi murni supaya bisa diuji tanpa
  /// menyentuh penyimpanan.
  static String cacheKeyFor(String question, String fingerprint) {
    final input = '${_normalize(question)}|$fingerprint';
    return '$_prefix${_fnv1a(input)}';
  }

  Future<String?> read(String question, String fingerprint) async {
    final prefs = await _store;
    final raw = prefs.getString(cacheKeyFor(question, fingerprint));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['answer'] is String) {
        final answer = decoded['answer'] as String;
        return answer.isEmpty ? null : answer;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<void> write(String question, String fingerprint, String answer) async {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return;

    final prefs = await _store;
    final key = cacheKeyFor(question, fingerprint);
    await prefs.setString(
      key,
      jsonEncode({'answer': trimmed, 'saved_at': _now().toIso8601String()}),
    );
    await _prune(prefs, keepKey: key);
  }

  Future<void> clear() async {
    final prefs = await _store;
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys.toList(growable: false)) {
      await prefs.remove(key);
    }
  }

  Future<int> entryCount() async {
    final prefs = await _store;
    return prefs.getKeys().where((key) => key.startsWith(_prefix)).length;
  }

  /// Menyisakan [maxEntries] entri terbaru agar penyimpanan tidak tumbuh terus.
  Future<void> _prune(
    SharedPreferences prefs, {
    required String keepKey,
  }) async {
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(_prefix))
        .toList(growable: false);
    if (keys.length <= maxEntries) return;

    final dated = <({String key, String savedAt})>[];
    for (final key in keys) {
      if (key == keepKey) continue;
      final raw = prefs.getString(key);
      var savedAt = '';
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map && decoded['saved_at'] is String) {
            savedAt = decoded['saved_at'] as String;
          }
        } on FormatException {
          savedAt = '';
        }
      }
      dated.add((key: key, savedAt: savedAt));
    }

    dated.sort((a, b) => a.savedAt.compareTo(b.savedAt));
    final excess = keys.length - maxEntries;
    for (var i = 0; i < excess && i < dated.length; i++) {
      await prefs.remove(dated[i].key);
    }
  }

  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// FNV-1a 32-bit: cukup untuk kunci cache, tanpa menambah dependensi crypto.
  static String _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

/// Sidik jari isi catatan: jumlah + waktu update terbaru.
///
/// Kalau salah satu catatan berubah, sidik jari berubah dan cache lama tidak
/// dipakai. Ini mencegah jawaban basi setelah pengguna mengedit catatan.
String notesFingerprint(Iterable<DateTime> updatedAt) {
  final list = updatedAt.toList(growable: false);
  if (list.isEmpty) return '0';
  final latest = list.reduce((a, b) => a.isAfter(b) ? a : b);
  return '${list.length}@${latest.toIso8601String()}';
}
