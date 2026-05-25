import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/ticker_repository.dart';
import '../domain/ohlcv_data.dart';
import '../domain/indicator_engine.dart';
import '../domain/signal_engine.dart';
import '../domain/ticker_filter.dart';

part 'screener_state.dart';

class ScreenerCubit extends Cubit<ScreenerState> {
  final TickerRepository repository;
  final TickerFilter filter;
  final SignalEngine signalEngine;

  ScreenerCubit({
    required this.repository,
    required this.filter,
    required this.signalEngine,
  }) : super(const ScreenerInitial());

  Future<void> runScan({
    required List<String> symbols,
    required String leadingIndicator,
  }) async {
    emit(const ScreenerScanning());
    final results = <ScreenResult>[];
    int processed = 0;
    int skipped = 0;

    for (final symbol in symbols) {
      final data = await _fetchWithCache(symbol);
      if (data == null || !filter.shouldKeep(data: data, lastTradeDate: null)) {
        skipped++;
        continue;
      }

      final signal = signalEngine.evaluate(data: data, barIndex: data.length - 1);
      results.add(ScreenResult(
        symbol: symbol,
        signal: signal,
        price: data.close.last,
        changePercent: _changePercent(data),
        timestamp: DateTime.now(),
      ));
      processed++;
    }

    emit(ScreenerComplete(
      results: results,
      totalProcessed: processed,
      totalSkipped: skipped,
    ));
  }

  Future<OhlcvData?> _fetchWithCache(String symbol) async {
    final cached = await repository.getCachedOhlcv(symbol);
    if (cached != null) return cached;
    return repository.fetchOhlcv(symbol);
  }

  double _changePercent(OhlcvData data) {
    if (data.length < 2) return 0;
    return ((data.close.last - data.close[data.length - 2]) / data.close[data.length - 2]) * 100;
  }
}

class ScreenResult extends Equatable {
  final String symbol;
  final SignalType signal;
  final double price;
  final double changePercent;
  final DateTime timestamp;

  const ScreenResult({
    required this.symbol,
    required this.signal,
    required this.price,
    required this.changePercent,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [symbol, signal, price, changePercent, timestamp];
}

class ScreenSummary extends Equatable {
  final int totalSignals;
  final int buyCount;
  final int sellCount;
  final DateTime scanTime;

  const ScreenSummary({
    required this.totalSignals,
    required this.buyCount,
    required this.sellCount,
    required this.scanTime,
  });

  @override
  List<Object?> get props => [totalSignals, buyCount, sellCount, scanTime];
}
