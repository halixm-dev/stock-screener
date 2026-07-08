import 'package:flutter_test/flutter_test.dart';
import 'package:stock_screener/domain/ohlcv_data.dart';
import 'package:stock_screener/domain/signal_engine.dart';

void main() {
  group('SignalEngine isFreshSignal', () {
    late SignalEngine engine;

    setUp(() {
      engine = SignalEngine();
    });

    test('returns insufficientHistory when history is too short', () {
      final history = [SignalType.buy];
      final result = engine.isFreshSignal(history, SignalType.buy);
      expect(result, equals(FreshCheckResult.insufficientHistory));
    });

    test('returns insufficientHistory when current signal is neutral', () {
      final history = [SignalType.sell, SignalType.neutral];
      final result = engine.isFreshSignal(history, SignalType.neutral);
      expect(result, equals(FreshCheckResult.insufficientHistory));
    });

    test('returns fresh when signal reverses from opposite', () {
      final history = [SignalType.sell, SignalType.sell, SignalType.buy];
      final result = engine.isFreshSignal(history, SignalType.buy);
      expect(result, equals(FreshCheckResult.fresh));
    });

    test('returns fresh when signal reverses with a neutral gap', () {
      final history = [
        SignalType.sell,
        SignalType.sell,
        SignalType.neutral,
        SignalType.neutral,
        SignalType.buy,
      ];
      final result = engine.isFreshSignal(history, SignalType.buy);
      expect(result, equals(FreshCheckResult.fresh));
    });

    test('returns staleRepeat when signal is same as previous', () {
      final history = [SignalType.sell, SignalType.buy, SignalType.buy];
      final result = engine.isFreshSignal(history, SignalType.buy);
      expect(result, equals(FreshCheckResult.staleRepeat));
    });

    test('returns staleRepeat when signal repeats after short neutral gap', () {
      final history = [
        SignalType.buy,
        SignalType.buy,
        SignalType.neutral,
        SignalType.buy,
      ];
      final result = engine.isFreshSignal(history, SignalType.buy);
      expect(result, equals(FreshCheckResult.staleRepeat));
    });

    test('returns insufficientHistory when gap is too long (> 30)', () {
      final history = [
        SignalType.sell,
        ...List.filled(31, SignalType.neutral),
        SignalType.buy,
      ];
      final result = engine.isFreshSignal(history, SignalType.buy);
      expect(result, equals(FreshCheckResult.insufficientHistory));
    });
  });
}
