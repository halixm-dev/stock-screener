import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/ohlcv_data.dart';

class TickerInfo {
  final String symbol;
  final String name;

  const TickerInfo({required this.symbol, required this.name});
}

abstract class TickerRepository {
  Future<List<TickerInfo>> fetchUniverse();
  Future<OhlcvData?> fetchOhlcv(String symbol);
  Future<void> cacheOhlcv(String symbol, OhlcvData data);
  Future<OhlcvData?> getCachedOhlcv(String symbol);
  Future<void> cacheUniverse(List<TickerInfo> tickers);
  Future<List<TickerInfo>?> getCachedUniverse();
  Future<DateTime?> getLastCachedDate();
}

class YahooFinanceTickerRepository implements TickerRepository {
  final String apiBase;
  final int batchSize;
  final int throttleMs;
  final http.Client _client;

  Future<void> _throttleQueue = Future.value();

  YahooFinanceTickerRepository({
    this.apiBase = 'https://query1.finance.yahoo.com/v8/finance/chart',
    this.batchSize = 20,
    this.throttleMs = 500,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final next = _throttleQueue.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
      await Future.delayed(Duration(milliseconds: throttleMs));
    });
    _throttleQueue = next.catchError((_) {}).then((_) => null);
    return completer.future;
  }

  @override
  Future<List<TickerInfo>> fetchUniverse() async {
    throw UnimplementedError('fetchUniverse not yet wired to API');
  }

  @override
  Future<OhlcvData?> fetchOhlcv(String symbol) async {
    return _enqueue(() async {
      final url = Uri.parse('$apiBase/$symbol?interval=1d&range=1y');
      final response = await _client.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body);
      final chart = json['chart'];
      if (chart == null || chart['error'] != null) {
        return null;
      }

      final result = chart['result'] as List?;
      if (result == null || result.isEmpty) {
        return null;
      }

      final data = result[0];
      final timestamp = data['timestamp'] as List?;
      final indicators = data['indicators'];
      if (timestamp == null || indicators == null) {
        return null;
      }

      final quote = indicators['quote'] as List?;
      if (quote == null || quote.isEmpty) {
        return null;
      }

      final quoteData = quote[0];
      final rawOpen = quoteData['open'] as List?;
      final rawHigh = quoteData['high'] as List?;
      final rawLow = quoteData['low'] as List?;
      final rawClose = quoteData['close'] as List?;
      final rawVolume = quoteData['volume'] as List?;

      if (rawOpen == null || rawHigh == null || rawLow == null || rawClose == null || rawVolume == null) {
        return null;
      }

      final List<double> open = [];
      final List<double> high = [];
      final List<double> low = [];
      final List<double> close = [];
      final List<int> volume = [];

      for (var i = 0; i < timestamp.length; i++) {
        if (rawOpen[i] == null || rawHigh[i] == null || rawLow[i] == null || rawClose[i] == null || rawVolume[i] == null) {
          continue;
        }

        open.add((rawOpen[i] as num).toDouble());
        high.add((rawHigh[i] as num).toDouble());
        low.add((rawLow[i] as num).toDouble());
        close.add((rawClose[i] as num).toDouble());
        volume.add((rawVolume[i] as num).toInt());
      }

      if (open.isEmpty) return null;

      return OhlcvData(
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
      );
    });
  }

  @override
  Future<void> cacheOhlcv(String symbol, OhlcvData data) async {
    throw UnimplementedError('cacheOhlcv not yet wired to Hive');
  }

  @override
  Future<OhlcvData?> getCachedOhlcv(String symbol) async {
    throw UnimplementedError('getCachedOhlcv not yet wired to Hive');
  }

  @override
  Future<void> cacheUniverse(List<TickerInfo> tickers) async {
    throw UnimplementedError('cacheUniverse not yet wired to Hive');
  }

  @override
  Future<List<TickerInfo>?> getCachedUniverse() async {
    throw UnimplementedError('getCachedUniverse not yet wired to Hive');
  }

  @override
  Future<DateTime?> getLastCachedDate() async {
    throw UnimplementedError('getLastCachedDate not yet wired to Hive');
  }
}
