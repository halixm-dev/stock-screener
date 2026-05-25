class OhlcvBar {
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  const OhlcvBar({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class OhlcvData {
  final List<double> open;
  final List<double> high;
  final List<double> low;
  final List<double> close;
  final List<int> volume;
  final int length;

  OhlcvData({
    List<double>? open,
    List<double>? high,
    List<double>? low,
    List<double>? close,
    List<int>? volume,
  })  : open = open ?? [],
        high = high ?? [],
        low = low ?? [],
        close = close ?? [],
        volume = volume ?? [],
        length = (open ?? []).length;

  const OhlcvData.subset({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.length,
  });

  double get hl2 => (high.last + low.last) / 2;
  double get hlc3 => (high.last + low.last + close.last) / 3;
  double get ohlc4 => (open.last + high.last + low.last + close.last) / 4;

  List<double> get hl2Series =>
      List.generate(length, (i) => (high[i] + low[i]) / 2);
  List<double> get hlc3Series =>
      List.generate(length, (i) => (high[i] + low[i] + close[i]) / 3);
  List<double> get ohlc4Series =>
      List.generate(length, (i) => (open[i] + high[i] + low[i] + close[i]) / 4);
}

enum SignalType { buy, sell, neutral }

class IndicatorResult {
  final bool isLong;
  final bool isShort;
  final double? value;

  const IndicatorResult({required this.isLong, required this.isShort, this.value});
}

class ScreenSignalConfig {
  String leadingIndicator;
  int signalExpiry;
  bool alternateSignal;

  ScreenSignalConfig({
    this.leadingIndicator = 'Range Filter',
    this.signalExpiry = 3,
    this.alternateSignal = true,
  });
}
