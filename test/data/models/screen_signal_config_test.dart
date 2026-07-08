import 'package:flutter_test/flutter_test.dart';
import 'package:stock_screener/data/models/screen_signal_config.dart';

void main() {
  group('ScreenSignalConfig JSON Serialization', () {
    test('serializes default config correctly', () {
      const config = ScreenSignalConfig();
      final json = config.toJson();

      expect(json['leadingIndicator'], 'Range Filter');
      expect(json['confirmations'], []);
      expect(json['parameters'], {});
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'leadingIndicator': 'MACD',
        'confirmations': ['RSI', 'Supertrend'],
        'parameters': {
          'Range Filter': {'period': 50, 'multiplier': 2.0},
        },
      };

      final config = ScreenSignalConfig.fromJson(json);

      expect(config.leadingIndicator, 'MACD');
      expect(config.confirmations, ['RSI', 'Supertrend']);
      expect(config.parameters['Range Filter']!['period'], 50);
      expect(config.parameters['Range Filter']!['multiplier'], 2.0);
    });
  });
}
