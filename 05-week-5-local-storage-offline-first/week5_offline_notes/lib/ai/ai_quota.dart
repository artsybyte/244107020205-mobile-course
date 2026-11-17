/// Batas jumlah request AI per hari.
///
/// Penghitung disimpan di `shared_preferences` agar bertahan setelah aplikasi
/// ditutup. Tanggal ikut disimpan; saat hari berganti, hitungan otomatis
/// direset sehingga pengguna tidak "terkunci" selamanya.
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'ai_config.dart';

class QuotaStatus {
  const QuotaStatus({required this.used, required this.limit});

  final int used;
  final int limit;

  int get remaining => (limit - used).clamp(0, limit);
  bool get exhausted => remaining == 0;
}

class AiQuota {
  factory AiQuota({
    SharedPreferences? prefs,
    DateTime Function()? now,
    int dailyLimit = AiConfig.dailyRequestLimit,
  }) => AiQuota._(prefs, now ?? DateTime.now, dailyLimit);

  AiQuota._(this._prefs, this._now, this.dailyLimit);

  static const String _dateKey = 'ai_quota_date';
  static const String _usedKey = 'ai_quota_used';

  final int dailyLimit;
  SharedPreferences? _prefs;
  final DateTime Function() _now;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<QuotaStatus> status() async {
    final prefs = await _store;
    final used = _usedToday(prefs);
    return QuotaStatus(used: used, limit: dailyLimit);
  }

  /// Mengambil satu jatah request. `false` berarti kuota hari ini habis dan
  /// pemanggil tidak boleh menyentuh jaringan.
  Future<bool> tryConsume() async {
    final prefs = await _store;
    final used = _usedToday(prefs);
    if (used >= dailyLimit) return false;

    await prefs.setString(_dateKey, _today());
    await prefs.setInt(_usedKey, used + 1);
    return true;
  }

  Future<void> reset() async {
    final prefs = await _store;
    await prefs.remove(_dateKey);
    await prefs.remove(_usedKey);
  }

  int _usedToday(SharedPreferences prefs) {
    final date = prefs.getString(_dateKey);
    if (date != _today()) return 0;
    return prefs.getInt(_usedKey) ?? 0;
  }

  String _today() {
    final now = _now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
