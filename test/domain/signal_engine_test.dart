import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_screener/domain/ohlcv_data.dart';
import 'package:stock_screener/domain/signal_engine.dart';

OhlcvData generateMockOhlcvData({bool rising = true, int bars = 200}) {
  final close = List<double>.generate(bars, (i) {
    if (rising) return 100.0 + (i / (bars - 1)) * 100.0;
    return 200.0 - (i / (bars - 1)) * 100.0;
  });
  final open = List<double>.generate(bars, (i) {
    if (i == 0) return close[0];
    return close[i - 1] + (close[i] - close[i - 1]) * 0.3;
  });
  final high = List<double>.generate(
      bars, (i) => math.max(open[i], close[i]) * 1.005);
  final low = List<double>.generate(
      bars, (i) => math.min(open[i], close[i]) * 0.995);
  final volume = List.filled(bars, 1000000);
  return OhlcvData(
      open: open, high: high, low: low, close: close, volume: volume);
}

void main() {
  group('SignalEngine config defaults', () {
    test('uses Range Filter as default leading indicator', () {
      final engine = SignalEngine();
      expect(engine.config.leadingIndicator, 'Range Filter');
    });

    test('signalExpiry defaults to 3', () {
      final engine = SignalEngine();
      expect(engine.config.signalExpiry, 3);
    });

    test('alternateSignal defaults to true', () {
      final engine = SignalEngine();
      expect(engine.config.alternateSignal, isTrue);
    });

    test('accepts custom ScreenSignalConfig', () {
      final config = ScreenSignalConfig(
        leadingIndicator: 'Supertrend',
        signalExpiry: 5,
        alternateSignal: false,
      );
      final engine = SignalEngine(config: config);
      expect(engine.config.leadingIndicator, 'Supertrend');
      expect(engine.config.signalExpiry, 5);
      expect(engine.config.alternateSignal, isFalse);
    });
  });

  group('SignalEngine.evaluate', () {
    test('returns neutral when barIndex < 2', () {
      final engine = SignalEngine();
      final data = generateMockOhlcvData();
      expect(engine.evaluate(data: data, barIndex: 0), SignalType.neutral);
      expect(engine.evaluate(data: data, barIndex: 1), SignalType.neutral);
    });

    test('returns buy for rising prices with 3 EMA Cross', () {
      final engine = SignalEngine(
        config: ScreenSignalConfig(leadingIndicator: '3 EMA Cross'),
      );
      final data = generateMockOhlcvData(rising: true);
      final result = engine.evaluate(data: data, barIndex: 199);
      expect(result, SignalType.buy);
    });

    test('returns sell for falling prices with 3 EMA Cross', () {
      final engine = SignalEngine(
        config: ScreenSignalConfig(leadingIndicator: '3 EMA Cross'),
      );
      final data = generateMockOhlcvData(rising: false);
      final result = engine.evaluate(data: data, barIndex: 199);
      expect(result, SignalType.sell);
    });

    test('returns neutral when leading indicator name is unknown', () {
      final engine = SignalEngine(
        config: ScreenSignalConfig(leadingIndicator: 'Nonexistent Indicator'),
      );
      final data = generateMockOhlcvData(rising: true);
      final result = engine.evaluate(data: data, barIndex: 199);
      expect(result, SignalType.neutral);
    });

    test('returns a valid SignalType without crashing for Range Filter default',
        () {
      final engine = SignalEngine();
      final data = generateMockOhlcvData(rising: true);
      expect(
        () => engine.evaluate(data: data, barIndex: 199),
        returnsNormally,
      );
    });

    test('evaluate produces different results for rising vs falling data', () {
      final risingData = generateMockOhlcvData(rising: true);
      final fallingData = generateMockOhlcvData(rising: false);
      final engine = SignalEngine(
        config: ScreenSignalConfig(leadingIndicator: '3 EMA Cross'),
      );
      final risingResult = engine.evaluate(data: risingData, barIndex: 199);
      final fallingResult = engine.evaluate(data: fallingData, barIndex: 199);
      expect(risingResult, isNot(fallingResult));
    });

    test('Supertrend indicator runs without error', () {
      final engine = SignalEngine(
        config: ScreenSignalConfig(leadingIndicator: 'Supertrend'),
      );
      final data = generateMockOhlcvData(rising: true);
      expect(
        () => engine.evaluate(data: data, barIndex: 199),
        returnsNormally,
      );
    });

    test('RSI indicator runs without error', () {
      final engine = SignalEngine(
        config: ScreenSignalConfig(leadingIndicator: 'RSI'),
      );
      final data = generateMockOhlcvData(rising: true);
      expect(
        () => engine.evaluate(data: data, barIndex: 199),
        returnsNormally,
      );
    });

    test('MACD indicator runs without error', () {
      final engine = SignalEngine(
        config: ScreenSignalConfig(leadingIndicator: 'MACD'),
      );
      final data = generateMockOhlcvData(rising: true);
      expect(
        () => engine.evaluate(data: data, barIndex: 199),
        returnsNormally,
      );
    });
  });

  group('SignalEngine.isFreshSignal', () {
    test('returns true on reversal from sell to buy', () {
      final engine = SignalEngine();
      final history = [
        SignalType.sell,
        SignalType.sell,
        SignalType.buy,
        SignalType.buy,
        SignalType.sell,
      ];
      expect(engine.isFreshSignal(history, SignalType.sell), isTrue);
    });

    test('returns true on reversal from buy to sell', () {
      final engine = SignalEngine();
      final history = [
        SignalType.buy,
        SignalType.buy,
        SignalType.buy,
        SignalType.sell,
        SignalType.sell,
      ];
      expect(engine.isFreshSignal(history, SignalType.sell), isTrue);
    });

    test('returns false for neutral current signal', () {
      final engine = SignalEngine();
      final history = [SignalType.buy, SignalType.buy, SignalType.buy];
      expect(engine.isFreshSignal(history, SignalType.neutral), isFalse);
    });

    test('returns false when history is empty', () {
      final engine = SignalEngine();
      expect(engine.isFreshSignal([], SignalType.buy), isFalse);
    });

    test('returns false when history has single element', () {
      final engine = SignalEngine();
      expect(engine.isFreshSignal([SignalType.buy], SignalType.buy), isFalse);
      expect(
          engine.isFreshSignal([SignalType.sell], SignalType.sell), isFalse);
    });

    test('returns false when all history matches current with no reversal', () {
      final engine = SignalEngine();
      final history = [
        SignalType.buy,
        SignalType.buy,
        SignalType.buy,
        SignalType.buy,
      ];
      expect(engine.isFreshSignal(history, SignalType.buy), isFalse);
    });

    test(
        'returns true with neutral bars between opposing signal and current run',
        () {
      final engine = SignalEngine();
      final history = [
        SignalType.sell,
        SignalType.sell,
        SignalType.neutral,
        SignalType.neutral,
        SignalType.buy,
        SignalType.buy,
      ];
      expect(engine.isFreshSignal(history, SignalType.buy), isTrue);
    });

    test('returns false when too many neutrals before opposing signal (> 30)',
        () {
      final engine = SignalEngine();
      final history = [
        SignalType.sell,
        ...List.filled(31, SignalType.neutral),
        SignalType.buy,
        SignalType.buy,
      ];
      expect(engine.isFreshSignal(history, SignalType.buy), isFalse);
    });

    test('returns true with exactly 30 neutrals before opposing signal', () {
      final engine = SignalEngine();
      final history = [
        SignalType.sell,
        ...List.filled(30, SignalType.neutral),
        SignalType.buy,
        SignalType.buy,
      ];
      expect(engine.isFreshSignal(history, SignalType.buy), isTrue);
    });

    test('returns false when entire history is neutral', () {
      final engine = SignalEngine();
      final history = [
        SignalType.neutral,
        SignalType.neutral,
        SignalType.neutral,
        SignalType.neutral,
      ];
      expect(engine.isFreshSignal(history, SignalType.neutral), isFalse);
    });

    test('returns true for first reversal in alternating history', () {
      final engine = SignalEngine();
      final history = [
        SignalType.buy,
        SignalType.buy,
        SignalType.sell,
        SignalType.buy,
      ];
      // current=buy, last=3
      // Loop: i=2, sell != buy → signalStart=3, break
      // signalStart=3 != last+1=4
      // Second: i=2, sell != buy → true
      expect(engine.isFreshSignal(history, SignalType.buy), isTrue);
    });

    test(
        'returns false when current signal has no opposing signal in scan range',
        () {
      final engine = SignalEngine();
      final history = [
        SignalType.neutral,
        SignalType.neutral,
        SignalType.buy,
        SignalType.buy,
      ];
      expect(engine.isFreshSignal(history, SignalType.buy), isFalse);
    });
  });
}
