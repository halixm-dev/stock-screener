import 'package:hive/hive.dart';
import 'package:stock_screener/data/models/screener_result.dart';
import 'package:stock_screener/data/ticker_repository.dart';
import 'package:stock_screener/domain/ohlcv_data.dart';
import 'package:stock_screener/domain/signal_engine.dart';
import 'package:stock_screener/domain/ticker_filter.dart';

import 'package:stock_screener/data/config_repository.dart';

class ScreenerService {
  final TickerRepository repository;
  final TickerFilter filter;
  final ConfigRepository configRepository;
  final Box<ScreenResult> resultsBox;

  ScreenerService({
    required this.repository,
    required this.filter,
    required this.configRepository,
    required this.resultsBox,
  });

  Future<List<ScreenResult>> runScan({required List<String> symbols}) async {
    final results = <ScreenResult>[];

    // Read the latest config
    final config = await configRepository.getConfig();
    final signalEngine = SignalEngine(config: config);

    for (final symbol in symbols) {
      try {
        final data = await _fetchWithCache(symbol);
        if (data == null ||
            !filter.shouldKeep(data: data, lastTradeDate: null)) {
          continue;
        }

        final allSignals = signalEngine.evaluateAll(data: data);
        final signal = allSignals.isNotEmpty
            ? allSignals.last
            : SignalType.neutral;

        if (signal != SignalType.neutral) {
          final freshResult = signalEngine.isFreshSignal(allSignals, signal);
          results.add(
            ScreenResult(
              symbol: symbol,
              signal: signal.toHive(),
              price: data.close.last,
              changePercent: _changePercent(data),
              timestamp: DateTime.now(),
              freshResult: freshResult.toHive(),
            ),
          );
        }
      } catch (e) {
        // Silently drop and continue on fetch failure
        print('Error fetching data for $symbol: $e');
      }
    }

    // Clear old results and save new ones
    await resultsBox.clear();
    await resultsBox.addAll(results);

    return results;
  }

  Future<OhlcvData?> _fetchWithCache(String symbol) async {
    final cached = await repository.getCachedOhlcv(symbol);
    if (cached != null) return cached;
    return repository.fetchOhlcv(symbol);
  }

  double _changePercent(OhlcvData data) {
    if (data.length < 2) return 0;
    return ((data.close.last - data.close[data.length - 2]) /
            data.close[data.length - 2]) *
        100;
  }
}
