import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../domain/ohlcv_data.dart';
import 'cache_entry.dart';

abstract class TickerRepository {
  Future<List<String>> fetchUniverse();
  Future<OhlcvData?> fetchOhlcv(String symbol);
  Future<void> cacheOhlcv(String symbol, OhlcvData data);
  Future<OhlcvData?> getCachedOhlcv(String symbol);
  Future<void> cacheUniverse(List<String> tickers);
  Future<List<String>?> getCachedUniverse({bool ignoreTtl = false});
  Future<DateTime?> getLastCachedDate();
}

class YahooFinanceTickerRepository implements TickerRepository {
  final String apiBase;
  final int batchSize;
  final int throttleMs;
  final http.Client _client;
  final Box? universeBox;

  YahooFinanceTickerRepository({
    this.apiBase = 'https://query1.finance.yahoo.com/v8/finance/chart',
    this.batchSize = 20,
    this.throttleMs = 500,
    http.Client? client,
    this.universeBox,
  }) : _client = client ?? http.Client();

  @override
  Future<List<String>> fetchUniverse() async {
    // 1. Check cache first
    final cached = await getCachedUniverse();
    if (cached != null) {
      return cached;
    }

    // 2. Cache miss or expired, fetch from network
    try {
      final url = Uri.parse(
        'https://halixm-dev.github.io/stock-screener/tickers.json',
      );
      final response = await _client.get(url);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch universe: HTTP ${response.statusCode}',
        );
      }

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      final tickers = jsonList.cast<String>();

      // 3. Cache the new data
      await cacheUniverse(tickers);
      return tickers;
    } catch (e) {
      // 4. Network error, attempt fallback to stale cache
      final stale = await getCachedUniverse(ignoreTtl: true);
      if (stale != null) {
        print(
          'Warning: Network fetch failed, falling back to stale universe cache. Error: $e',
        );
        return stale;
      }
      // If no stale cache exists, rethrow
      rethrow;
    }
  }

  @override
  Future<OhlcvData?> fetchOhlcv(String symbol) async {
    try {
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

      if (rawOpen == null ||
          rawHigh == null ||
          rawLow == null ||
          rawClose == null ||
          rawVolume == null) {
        return null;
      }

      final List<double> open = [];
      final List<double> high = [];
      final List<double> low = [];
      final List<double> close = [];
      final List<int> volume = [];

      for (var i = 0; i < timestamp.length; i++) {
        if (rawOpen[i] == null ||
            rawHigh[i] == null ||
            rawLow[i] == null ||
            rawClose[i] == null ||
            rawVolume[i] == null) {
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
    } catch (e) {
      return null;
    }
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
  Future<void> cacheUniverse(List<String> tickers) async {
    if (universeBox == null) return;

    final entry = CacheEntry<List<String>>(
      data: tickers,
      createdAt: DateTime.now(),
    );
    await universeBox!.put('tickers', entry.toMap());
  }

  @override
  Future<List<String>?> getCachedUniverse({bool ignoreTtl = false}) async {
    if (universeBox == null) return null;

    final map = universeBox!.get('tickers');
    if (map == null) return null;

    try {
      final Map<dynamic, dynamic> dynamicMap = map is Map
          ? map
          : Map<dynamic, dynamic>.from(map as Map);

      final entry = CacheEntry<List<String>>.fromMap(
        dynamicMap,
        (data) => (data as List).cast<String>(),
      );

      if (!ignoreTtl && entry.isExpired(const Duration(days: 7))) {
        await universeBox!.delete('tickers');
        return null;
      }

      return entry.data;
    } catch (e) {
      // In case of migration issues or corrupted cache
      print('Warning: Failed to parse cached universe. Error: $e');
      return null;
    }
  }

  @override
  Future<DateTime?> getLastCachedDate() async {
    if (universeBox == null) return null;

    final map = universeBox!.get('tickers');
    if (map == null) return null;

    try {
      final dynamicMap = map is Map
          ? map
          : Map<dynamic, dynamic>.from(map as Map);
      final entry = CacheEntry<List<String>>.fromMap(
        dynamicMap,
        (data) => [], // We only care about the date here
      );
      return entry.createdAt;
    } catch (e) {
      return null;
    }
  }
}
