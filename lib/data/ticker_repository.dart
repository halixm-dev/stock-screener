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

  YahooFinanceTickerRepository({
    this.apiBase = 'https://query1.finance.yahoo.com/v8/finance/chart',
    this.batchSize = 20,
    this.throttleMs = 500,
  });

  @override
  Future<List<TickerInfo>> fetchUniverse() async {
    throw UnimplementedError('fetchUniverse not yet wired to API');
  }

  @override
  Future<OhlcvData?> fetchOhlcv(String symbol) async {
    throw UnimplementedError('fetchOhlcv not yet wired to API');
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
