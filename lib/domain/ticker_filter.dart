import 'ohlcv_data.dart';

class TickerFilterResult {
  final int removedReasonCount;
  final int keptCount;

  const TickerFilterResult({
    required this.removedReasonCount,
    required this.keptCount,
  });
}

enum RemoveReason {
  zeroVolume,
  insufficientHistory,
  staleData,
  priceBelowMinimum,
}

class TickerFilter {
  final int minBars;
  final int maxStaleDays;
  final double minPrice;

  const TickerFilter({
    this.minBars = 150,
    this.maxStaleDays = 7,
    this.minPrice = 50,
  });

  bool shouldKeep({
    required OhlcvData data,
    required DateTime? lastTradeDate,
  }) {
    if (data.length < minBars) return false;
    if (data.volume.last == 0) return false;
    if (data.close.last < minPrice) return false;
    if (lastTradeDate != null) {
      final age = DateTime.now().difference(lastTradeDate).inDays;
      if (age > maxStaleDays) return false;
    }
    return true;
  }
}
