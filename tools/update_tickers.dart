/// Fetches the complete list of active IDX stock tickers from TradingView's
/// public scanner endpoint and writes them to assets/tickers.json and
/// web/tickers.json.
///
/// Usage:
///   dart run tools/update_tickers.dart
///
/// The TradingView scanner is a publicly accessible POST endpoint that returns
/// structured market data. We query it for all stocks on the IDX exchange,
/// extract their ticker symbols, and format them with the `.JK` suffix needed
/// by Yahoo Finance.
///
/// This script is designed to be run both locally and inside a GitHub Action.
library;

import 'dart:convert';
import 'dart:io';

const _scannerUrl = 'https://scanner.tradingview.com/indonesia/scan';

/// POST body asking TradingView for every stock on IDX.
/// - `type: stock` limits to equities (no bonds/futures).
/// - We request only the `name` column to keep the payload small.
/// - `sort` by market_cap_basic descending so the largest caps come first.
/// - `range: [0, 2000]` is generous enough to cover all ~900 listed stocks.
Map<String, dynamic> _buildRequestBody() => {
  'columns': ['name'],
  'filter': [
    {'left': 'exchange', 'operation': 'equal', 'right': 'IDX'},
    {'left': 'is_primary', 'operation': 'equal', 'right': true},
    {'left': 'active_symbol', 'operation': 'equal', 'right': true},
  ],
  'options': {'lang': 'en'},
  'range': [0, 2000],
  'sort': {'sortBy': 'market_cap_basic', 'sortOrder': 'desc'},
  'symbols': {},
  'filter2': {
    'operator': 'and',
    'operands': [
      {'operation': {'operator': 'or', 'operands': [
        {'expression': {'left': 'type', 'operation': 'equal', 'right': 'stock'}},
      ]}},
    ],
  },
};

Future<List<String>> _fetchFromTradingView() async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(_scannerUrl));
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, 'stock-screener-updater/1.0');
    request.write(jsonEncode(_buildRequestBody()));
    await request.flush();

    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException(
        'TradingView scanner returned HTTP ${response.statusCode}',
      );
    }

    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];

    final tickers = <String>[];
    for (final item in data) {
      // Each item is {"s": "IDX:BBCA", "d": ["BBCA"]}
      final symbol = item['s'] as String?;
      if (symbol == null) continue;

      // Strip the "IDX:" prefix
      final code = symbol.contains(':') ? symbol.split(':').last : symbol;

      // Skip warrants (e.g. BULL-W2), rights issues (BRPT-R), etc.
      if (code.contains('-') || code.contains(' ')) continue;

      tickers.add('$code.JK');
    }

    return tickers;
  } finally {
    client.close();
  }
}

/// Fallback: load the existing file and return its contents unchanged.
Future<List<String>> _loadExisting(String path) async {
  final file = File(path);
  if (!await file.exists()) return [];
  final content = await file.readAsString();
  final list = jsonDecode(content) as List<dynamic>;
  return list.cast<String>();
}

Future<void> main() async {
  stdout.writeln('Fetching active IDX tickers from TradingView scanner...');

  List<String> tickers;
  try {
    tickers = await _fetchFromTradingView();
    stdout.writeln('Fetched ${tickers.length} tickers from TradingView.');
  } catch (e) {
    stderr.writeln('Error fetching from TradingView: $e');
    stderr.writeln('Falling back to existing tickers.json.');
    tickers = await _loadExisting('assets/tickers.json');
    if (tickers.isEmpty) {
      stderr.writeln('No existing tickers.json found. Exiting.');
      exit(1);
    }
    stdout.writeln('Loaded ${tickers.length} tickers from existing file.');
  }

  // Sanity check: if we got fewer than 100 tickers, something went wrong.
  // Don't overwrite a good file with garbage.
  if (tickers.length < 100) {
    final existing = await _loadExisting('assets/tickers.json');
    if (existing.length > tickers.length) {
      stderr.writeln(
        'WARNING: Only got ${tickers.length} tickers (existing has ${existing.length}). '
        'Merging with existing to prevent data loss.',
      );
      final merged = {...existing, ...tickers}.toList();
      tickers = merged;
    }
  }

  // Deduplicate and sort
  tickers = (tickers.toSet().toList()..sort());

  stdout.writeln('Writing ${tickers.length} tickers to assets/tickers.json and web/tickers.json...');

  final encoder = JsonEncoder.withIndent('  ');
  final output = encoder.convert(tickers);

  await File('assets/tickers.json').writeAsString(output);
  await File('web/tickers.json').writeAsString(output);

  stdout.writeln('Done.');
}
