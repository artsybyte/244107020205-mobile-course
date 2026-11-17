/// Preferensi fitur AI yang disimpan di `shared_preferences`.
///
/// Mode demo default **aktif** karena aplikasi tidak boleh bergantung pada API
/// key pribadi untuk bisa dijalankan dan didemokan.
library;

import 'package:shared_preferences/shared_preferences.dart';

class AiSettings {
  static const String _demoModeKey = 'ai_demo_mode';

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoModeKey) ?? true;
  }

  Future<void> setDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoModeKey, value);
  }
}
