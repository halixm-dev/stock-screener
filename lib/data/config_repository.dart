import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/screen_signal_config.dart';

class ConfigRepository {
  static const String _configKey = 'screen_signal_config';
  final SharedPreferences _prefs;

  ConfigRepository(this._prefs);

  Future<ScreenSignalConfig> getConfig() async {
    final String? jsonStr = _prefs.getString(_configKey);
    if (jsonStr == null) {
      return const ScreenSignalConfig();
    }
    try {
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ScreenSignalConfig.fromJson(jsonMap);
    } catch (e) {
      // If parsing fails (e.g. schema changes), return default
      return const ScreenSignalConfig();
    }
  }

  Future<void> saveConfig(ScreenSignalConfig config) async {
    final jsonStr = jsonEncode(config.toJson());
    await _prefs.setString(_configKey, jsonStr);
  }

  bool isBackgroundScanEnabled() {
    return _prefs.getBool('isBackgroundScanEnabled') ?? false;
  }

  Future<void> setBackgroundScanEnabled(bool enabled) async {
    await _prefs.setBool('isBackgroundScanEnabled', enabled);
  }

  int getScanIntervalMinutes() {
    return _prefs.getInt('scanIntervalMinutes') ?? 60;
  }

  Future<void> setScanIntervalMinutes(int minutes) async {
    await _prefs.setInt('scanIntervalMinutes', minutes);
  }
}
