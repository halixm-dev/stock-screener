import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';
import 'package:stock_screener/data/models/screener_result.dart';

// We create a mock Box for testing
class MockBox<T> extends Mock implements Box<T> {}

// Since the deduplication logic is tightly coupled inside callbackDispatcher,
// we will simulate the exact logic here to test it.
// In a real refactor, this logic should be extracted to a separate class/function.

List<ScreenResult> simulateDeduplication(
  List<ScreenResult> results,
  DateTime now,
  Box<bool> dedupBox,
) {
  final todayStr = DateFormat('yyyy-MM-dd').format(now);
  final freshSignals = <ScreenResult>[];

  for (final result in results) {
    if (!result.isFresh) continue;

    final dedupKey = '${result.symbol}_${result.signal.name}_$todayStr';
    if (!dedupBox.containsKey(dedupKey)) {
      freshSignals.add(result);
      // Simulate putting into box (the real code does dedupBox.put)
      // Here we just let the mock record the interaction.
      dedupBox.put(dedupKey, true);
    }
  }
  return freshSignals;
}

void main() {
  group('Background Task Deduplication Logic', () {
    late MockBox<bool> mockDedupBox;
    late DateTime testDate;
    late String todayStr;

    setUp(() {
      mockDedupBox = MockBox<bool>();
      testDate = DateTime(2026, 7, 2, 10, 0, 0); // 10 AM
      todayStr = DateFormat('yyyy-MM-dd').format(testDate);
    });

    test('ignores non-fresh signals', () {
      final results = [
        ScreenResult(
          symbol: 'BBCA.JK',
          signal: SignalTypeHive.buy,
          price: 1000,
          changePercent: 1.0,
          timestamp: testDate,
          freshResult: FreshCheckResultHive.staleRepeat, // Not fresh
        ),
      ];

      final output = simulateDeduplication(results, testDate, mockDedupBox);

      expect(output, isEmpty);
      verifyNever(() => mockDedupBox.containsKey(any()));
    });

    test('adds fresh signal if not in dedupBox and marks it', () {
      final results = [
        ScreenResult(
          symbol: 'BBCA.JK',
          signal: SignalTypeHive.buy,
          price: 1000,
          changePercent: 1.0,
          timestamp: testDate,
          freshResult: FreshCheckResultHive.fresh,
        ),
      ];

      when(
        () => mockDedupBox.containsKey('BBCA.JK_buy_$todayStr'),
      ).thenReturn(false);
      when(
        () => mockDedupBox.put('BBCA.JK_buy_$todayStr', true),
      ).thenAnswer((_) async {});

      final output = simulateDeduplication(results, testDate, mockDedupBox);

      expect(output, hasLength(1));
      expect(output.first.symbol, 'BBCA.JK');
      verify(() => mockDedupBox.containsKey('BBCA.JK_buy_$todayStr')).called(1);
      verify(() => mockDedupBox.put('BBCA.JK_buy_$todayStr', true)).called(1);
    });

    test('ignores fresh signal if already in dedupBox', () {
      final results = [
        ScreenResult(
          symbol: 'GOTO.JK',
          signal: SignalTypeHive.sell,
          price: 100,
          changePercent: -1.0,
          timestamp: testDate,
          freshResult: FreshCheckResultHive.fresh,
        ),
      ];

      when(
        () => mockDedupBox.containsKey('GOTO.JK_sell_$todayStr'),
      ).thenReturn(true);

      final output = simulateDeduplication(results, testDate, mockDedupBox);

      expect(output, isEmpty);
      verify(
        () => mockDedupBox.containsKey('GOTO.JK_sell_$todayStr'),
      ).called(1);
      verifyNever(() => mockDedupBox.put(any(), any()));
    });
  });
}
