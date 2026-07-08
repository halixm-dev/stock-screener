import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_screener/data/config_repository.dart';
import 'package:stock_screener/data/models/screen_signal_config.dart';

void main() {
  group('ConfigRepository', () {
    late ConfigRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns default config when no saved config exists', () async {
      final prefs = await SharedPreferences.getInstance();
      repository = ConfigRepository(prefs);

      final config = await repository.getConfig();

      expect(config, const ScreenSignalConfig());
    });

    test('saves and loads config correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      repository = ConfigRepository(prefs);

      final customConfig = const ScreenSignalConfig(
        leadingIndicator: 'MACD',
        confirmations: ['RSI'],
        parameters: {
          'MACD': {'fast': 10},
        },
      );

      await repository.saveConfig(customConfig);

      // Verify it was saved to SharedPreferences
      final savedJsonStr = prefs.getString('screen_signal_config');
      expect(savedJsonStr, isNotNull);
      final decoded = jsonDecode(savedJsonStr!);
      expect(decoded['leadingIndicator'], 'MACD');

      // Verify it loads correctly
      final loadedConfig = await repository.getConfig();
      expect(loadedConfig.leadingIndicator, 'MACD');
      expect(loadedConfig.confirmations, ['RSI']);
      expect(loadedConfig.parameters['MACD']!['fast'], 10);
    });

    test('returns default config if saved JSON is corrupted', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('screen_signal_config', '{ corrupted json');
      repository = ConfigRepository(prefs);

      final config = await repository.getConfig();

      expect(config.leadingIndicator, 'Range Filter'); // Default
    });
  });
}
