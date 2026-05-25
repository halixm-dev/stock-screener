import 'package:flutter_test/flutter_test.dart';
import 'package:stock_screener/domain/ohlcv_data.dart';
import 'package:stock_screener/domain/ticker_filter.dart';

OhlcvData _validData({int bars = 150, double closePrice = 100, int lastVolume = 1000}) {
  return OhlcvData(
    open: List.generate(bars, (_) => 99.0),
    high: List.generate(bars, (_) => 101.0),
    low: List.generate(bars, (_) => 98.0),
    close: List.generate(bars, (_) => closePrice),
    volume: [...List.generate(bars - 1, (_) => 1000), lastVolume],
  );
}

void main() {
  group('TickerFilter defaults', () {
    test('minBars defaults to 150', () {
      const filter = TickerFilter();
      expect(filter.minBars, 150);
    });

    test('maxStaleDays defaults to 7', () {
      const filter = TickerFilter();
      expect(filter.maxStaleDays, 7);
    });

    test('minPrice defaults to 50', () {
      const filter = TickerFilter();
      expect(filter.minPrice, 50.0);
    });
  });

  group('TickerFilter.shouldKeep', () {
    test('returns true for valid data', () {
      const filter = TickerFilter();
      final data = _validData();
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now(),
      );
      expect(result, isTrue);
    });

    test('returns true when lastTradeDate is null', () {
      const filter = TickerFilter();
      final data = _validData();
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: null,
      );
      expect(result, isTrue);
    });

    test('returns false when last volume is 0', () {
      const filter = TickerFilter();
      final data = _validData(lastVolume: 0);
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now(),
      );
      expect(result, isFalse);
    });

    test('returns false when insufficient bars', () {
      const filter = TickerFilter(minBars: 150);
      final data = _validData(bars: 149);
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now(),
      );
      expect(result, isFalse);
    });

    test('returns false when price below minimum', () {
      const filter = TickerFilter(minPrice: 50);
      final data = _validData(closePrice: 49.99);
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now(),
      );
      expect(result, isFalse);
    });

    test('returns false when price equals minPrice', () {
      const filter = TickerFilter(minPrice: 50);
      final data = _validData(closePrice: 50);
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now(),
      );
      expect(result, isTrue);
    });

    test('returns false when data is stale', () {
      const filter = TickerFilter(maxStaleDays: 7);
      final data = _validData();
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(result, isFalse);
    });

    test('returns true when lastTradeDate exactly at maxStaleDays boundary', () {
      const filter = TickerFilter(maxStaleDays: 7);
      final data = _validData();
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now().subtract(const Duration(days: 7)),
      );
      expect(result, isTrue);
    });

    test('returns false when lastTradeDate one day past maxStaleDays', () {
      const filter = TickerFilter(maxStaleDays: 7);
      final data = _validData();
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(result, isFalse);
    });
  });

  group('TickerFilter custom parameters', () {
    test('custom minBars filters correctly', () {
      const filter = TickerFilter(minBars: 200);
      expect(filter.minBars, 200);
      final data = _validData(bars: 199);
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now(),
      );
      expect(result, isFalse);
    });

    test('custom maxStaleDays filters correctly', () {
      const filter = TickerFilter(maxStaleDays: 30);
      expect(filter.maxStaleDays, 30);
      final data = _validData();
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now().subtract(const Duration(days: 31)),
      );
      expect(result, isFalse);
    });

    test('custom minPrice filters correctly', () {
      const filter = TickerFilter(minPrice: 100);
      expect(filter.minPrice, 100.0);
      final data = _validData(closePrice: 99);
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now(),
      );
      expect(result, isFalse);
    });

    test('all custom parameters work together', () {
      const filter = TickerFilter(minBars: 100, maxStaleDays: 14, minPrice: 25);
      expect(filter.minBars, 100);
      expect(filter.maxStaleDays, 14);
      expect(filter.minPrice, 25.0);
      final data = _validData(bars: 100, closePrice: 30, lastVolume: 500);
      final result = filter.shouldKeep(
        data: data,
        lastTradeDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(result, isTrue);
    });
  });

  group('TickerFilterResult', () {
    test('records removedReasonCount and keptCount', () {
      const result = TickerFilterResult(removedReasonCount: 5, keptCount: 3);
      expect(result.removedReasonCount, 5);
      expect(result.keptCount, 3);
    });

    test('immutable fields', () {
      const result = TickerFilterResult(removedReasonCount: 0, keptCount: 10);
      expect(result.removedReasonCount, 0);
      expect(result.keptCount, 10);
    });
  });

  group('RemoveReason enum', () {
    test('has all expected values', () {
      expect(RemoveReason.values, hasLength(4));
      expect(RemoveReason.values, contains(RemoveReason.zeroVolume));
      expect(RemoveReason.values, contains(RemoveReason.insufficientHistory));
      expect(RemoveReason.values, contains(RemoveReason.staleData));
      expect(RemoveReason.values, contains(RemoveReason.priceBelowMinimum));
    });
  });
}
