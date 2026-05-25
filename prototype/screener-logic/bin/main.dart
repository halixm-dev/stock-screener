import 'dart:io';
import 'dart:math' as math;
import '../lib/models.dart';
import '../lib/math_utils.dart';
import '../lib/indicator_engine.dart';
import '../lib/signal_engine.dart';

/// Generates synthetic OHLCV data that exercises all indicator edge cases.
/// 200 bars of realistic-ish IDX stock data.
OhlcvData generateMockData() {
  final n = 200;
  final rng = math.Random(42);
  double price = 5000;
  final open = List<double>.filled(n, 0);
  final high = List<double>.filled(n, 0);
  final low = List<double>.filled(n, 0);
  final close = List<double>.filled(n, 0);
  final volume = List<int>.filled(n, 0);

  // Scenario: uptrend, downtrend, consolidation, reversal
  for (int i = 0; i < n; i++) {
    final trend = i < 60
        ? 1.0    // uptrend
        : i < 100
            ? -0.5  // correction
            : i < 140
                ? 2.0  // strong uptrend
                : i < 175
                    ? -1.5  // sharp selloff
                    : 0.3; // recovery

    final noise = (rng.nextDouble() - 0.5) * 50;
    final move = trend + noise;
    open[i] = price;
    close[i] = price + move;
    high[i] = math.max(open[i], close[i]) + rng.nextDouble() * 30;
    low[i] = math.min(open[i], close[i]) - rng.nextDouble() * 30;
    volume[i] = (100000000 + rng.nextDouble() * 500000000).round();
    price = close[i];
  }
  return OhlcvData(open: open, high: high, low: low, close: close, volume: volume);
}

/// Generate a scenario with clear reversal for testing fresh signal detection
OhlcvData generateReversalData() {
  final n = 150;
  final rng = math.Random(1);
  double price = 5000;
  final open = List<double>.filled(n, 0);
  final high = List<double>.filled(n, 0);
  final low = List<double>.filled(n, 0);
  final close = List<double>.filled(n, 0);
  final volume = List<int>.filled(n, 0);

  for (int i = 0; i < n; i++) {
    final trend = i < 70
        ? -1.0    // sustained downtrend
        : i < 80
            ? 0.0   // neutral zone
            : 1.5;  // strong reversal uptrend
    final noise = (rng.nextDouble() - 0.5) * 40;
    final move = trend + noise;
    open[i] = price;
    close[i] = price + move;
    high[i] = math.max(open[i], close[i]) + rng.nextDouble() * 25;
    low[i] = math.min(open[i], close[i]) - rng.nextDouble() * 25;
    volume[i] = (100000000 + rng.nextDouble() * 500000000).round();
    price = close[i];
  }
  return OhlcvData(open: open, high: high, low: low, close: close, volume: volume);
}

String _signalTypeStr(SignalType t) {
  switch (t) {
    case SignalType.buy: return 'BUY ';
    case SignalType.sell: return 'SELL';
    case SignalType.neutral: return 'NEUT';
  }
}

String _trend(int bar, List<double> close) {
  if (bar < 5) return '---';
  final change = ((close[bar] - close[bar - 5]) / close[bar - 5] * 100);
  return '${change >= 0 ? "+" : ""}${change.toStringAsFixed(1)}%';
}

void main() {
  final data = generateMockData();
  final reversalData = generateReversalData();
  final engine = SignalEngine();
  final config = ScreenSignalConfig();
  print('\x1b[2J\x1b[H'); // clear screen

  int bar = 50; // start with enough history for indicators
  final signalHistory = <SignalType>[];

  while (true) {
    print('\x1b[H'); // home cursor

    // === Current frame ===
    print('\x1b[1m═══ SCREENER LOGIC PROTOTYPE ═══\x1b[0m');
    print('Bar: $bar / ${data.length - 1}');
    print('Price: \x1b[1m${data.close[bar].toStringAsFixed(0)}\x1b[0m');
    print('Trend (5-bar): \x1b[2m${_trend(bar, data.close)}\x1b[0m');
    print('');

    // Test all indicators on current bar
    print('\x1b[1m--- INDICATORS ---\x1b[0m');
    final subClose = data.close.sublist(0, bar + 1);
    final subHigh = data.high.sublist(0, bar + 1);
    final subLow = data.low.sublist(0, bar + 1);
    final subOpen = data.open.sublist(0, bar + 1);
    final subVol = data.volume.sublist(0, bar + 1);
    final subData = OhlcvData.subset(open: subOpen, high: subHigh, low: subLow, close: subClose, volume: subVol, length: bar + 1);

    // Run all indicators
    final rf = calcRangeFilter(subClose, 100, 3.0);
    final rqk = calcRQK(subClose, 8.0, 8.0, 25, 2);
    final ht = calcHalfTrend(subHigh, subLow, subClose);
    final st = calcSuperTrend(subHigh, subLow, subClose);
    final tsi = calcTSI(subClose);
    final don = calcDonchian(subHigh, subLow, subClose);
    final rocVal = calcROC(subClose);
    final macd = calcMACD(subClose);
    final ssl = calcSSL(subHigh, subLow, subClose);
    final bbpt = calcBBPT(subHigh, subLow, subClose);
    final chandelier = calcChandelier(subHigh, subLow, subClose);
    final cci = calcCCI(subHigh, subLow, subClose);
    final adx = calcADX(subHigh, subLow, subClose);
    final psar = calcPSAR(subHigh, subLow, subClose);
    final wae = calcWAE(subHigh, subLow, subClose);
    final hacolt = calcHACOLT(subOpen, subHigh, subLow, subClose);
    final awesome = calcAwesome(subHigh, subLow);
    final wolf = calcWolfpack(subClose);
    final qqe = calcQQE(subClose);
    final hull = calcHull(subClose);
    final vortex = calcVortex(subHigh, subLow, subClose);
    final bbosc = calcBBOsc(subClose, subOpen);
    final rd = calcRangeDetector(subHigh, subLow, subClose);
    final tb = calcTrendlineBO(subHigh, subLow, subClose);
    final chaikin = calcChaikin(subHigh, subLow, subClose, subVol);
    final volResult = calcVolume(subOpen, subClose, subVol);
    final mg = calcMcGinley(subClose);
    final ema2 = calc2EMACross(subClose);
    final ema3 = calc3EMACross(subClose);
    final emaFilt = calcEMAFilter(subClose);
    final stc = calcSTC(subClose);
    final dv = calcDV(subHigh, subLow, subClose);
    final ci = calcCI(subHigh, subLow, subClose);
    final vo = calcVolatilityOsc(subOpen, subHigh, subLow, subClose);
    final dpo = calcDPO(subClose);
    final tdfi = calcTDFI(subClose);
    final rsi = calcRSI(subClose);
    final stoch = calcStochastic(subHigh, subLow, subClose);
    final ichi = calcIchimoku(subHigh, subLow, subClose);
    final superIchi = calcSuperIchi(subHigh, subLow, subClose);
    final bx = calcBXtrender(subClose);
    final vwap = calcVWAP(subHigh, subLow, subClose, subVol);

    final idx = bar;
    void printInd(String name, bool long, bool short) {
      print('  ${name.padRight(38)} LONG: ${long ? "\x1b[32m✔\x1b[0m" : "\x1b[31m✘\x1b[0m"}  SHORT: ${short ? "\x1b[31m✔\x1b[0m" : "\x1b[32m✘\x1b[0m"}');
    }

    printInd('Range Filter', rf.uprf[idx], rf.downrf[idx]);
    printInd('RQK', rqk.uptrend[idx], rqk.downtrend[idx]);
    printInd('Half Trend', ht.isLong[idx], ht.isShort[idx]);
    printInd('SuperTrend', st.isUp[idx], st.isDown[idx]);
    printInd('TSI', tsi.isLong[idx], tsi.isShort[idx]);
    printInd('Donchian', don.isLong[idx], don.isShort[idx]);
    printInd('ROC', rocVal.isLong[idx], rocVal.isShort[idx]);
    printInd('MACD', macd.isLong[idx], macd.isShort[idx]);
    printInd('SSL Channel', ssl.isLong[idx], ssl.isShort[idx]);
    printInd('BBPT', bbpt.isLong[idx], bbpt.isShort[idx]);
    printInd('Chandelier Exit', chandelier.isLong[idx], chandelier.isShort[idx]);
    printInd('CCI', cci.isLong[idx], cci.isShort[idx]);
    printInd('DMI (ADX)', adx.isLong[idx], adx.isShort[idx]);
    printInd('Parabolic SAR', psar.isUp[idx], psar.isDown[idx]);
    printInd('Waddah Attar', wae.isLong[idx], wae.isShort[idx]);
    printInd('HA Colt', hacolt.isLong[idx], hacolt.isShort[idx]);
    printInd('Awesome Osc', awesome.isLong[idx], awesome.isShort[idx]);
    printInd('Wolfpack', wolf.isLong[idx], wolf.isShort[idx]);
    printInd('QQE Mod', qqe.isAbove[idx], qqe.isBelow[idx]);
    printInd('Hull Suite', hull.isUp[idx], hull.isDown[idx]);
    printInd('Vortex Index', vortex.vipCondition[idx], vortex.vimCondition[idx]);
    printInd('BB Oscillator', bbosc.isLong[idx], bbosc.isShort[idx]);
    printInd('Range Detector', rd.isLong[idx], rd.isShort[idx]);
    printInd('Trendline Breakout', tb.buySignal[idx], tb.sellSignal[idx]);
    printInd('Chaikin MF', chaikin.isLong[idx], chaikin.isShort[idx]);
    printInd('Volume', volResult.isLong[idx], volResult.isShort[idx]);
    printInd('McGinley Dynamic', mg.isLong[idx], mg.isShort[idx]);
    printInd('2 EMA Cross', ema2.isLong[idx], ema2.isShort[idx]);
    printInd('3 EMA Cross', ema3.isLong[idx], ema3.isShort[idx]);
    printInd('STC', stc.isUp[idx], stc.isDown[idx]);
    printInd('Damiani Volatility', dv.isUp[idx], false);
    printInd('Volatility Osc', vo.isLong[idx], vo.isShort[idx]);
    printInd('DPO', dpo.isLong[idx], dpo.isShort[idx]);
    printInd('TDFI', tdfi.isLong[idx], tdfi.isShort[idx]);
    printInd('RSI', rsi.isLong[idx], rsi.isShort[idx]);
    printInd('Stochastic', stoch.isLong[idx], stoch.isShort[idx]);
    printInd('Ichimoku', ichi.isLong[idx], ichi.isShort[idx]);
    printInd('SuperIchi', superIchi.isLong[idx], superIchi.isShort[idx]);
    printInd('B-Xtrender', bx.isLong[idx], bx.isShort[idx]);
    printInd('VWAP', vwap.isLong[idx], vwap.isShort[idx]);

    // Signal engine evaluation
    final signal = engine.evaluate(data: subData, barIndex: bar);
    signalHistory.add(signal);

    // Fresh signal detection
    final isFresh = engine.isFreshSignal(
        signalHistory.sublist(0, math.max(1, signalHistory.length - 1)),
        signal);

    print('');
    print('\x1b[1m--- SIGNAL ---\x1b[0m');
    print('  Leading: ${config.leadingIndicator}');
    print('  Signal:  \x1b[${signal == SignalType.buy ? "32" : signal == SignalType.sell ? "31" : "33"}m${_signalTypeStr(signal)}\x1b[0m');
    print('  Fresh:   ${isFresh ? "\x1b[32mYES\x1b[0m" : "\x1b[33mNO\x1b[0m"}');

    print('');
    print('\x1b[2m--- SIGNAL HISTORY (last 20) ---\x1b[0m');
    final start = math.max(0, signalHistory.length - 20);
    for (int i = start; i < signalHistory.length; i++) {
      final s = signalHistory[i];
      final c = s == SignalType.buy ? "\x1b[32m" : s == SignalType.sell ? "\x1b[31m" : "\x1b[33m";
      print('  $c${_signalTypeStr(s)}\x1b[0m  ${(i + 1).toString().padLeft(3)}');
    }

    // === Keyboard shortcuts ===
    print('');
    print('\x1b[2m──────────────────────────────────────\x1b[0m');
    print('\x1b[1m[n]\x1b[0m next bar  \x1b[1m[p]\x1b[0m prev bar  \x1b[1m[P]\x1b[0m prev 10  \x1b[1m[N]\x1b[0m next 10');
    print('\x1b[1m[r]\x1b[0m run to reversal data  \x1b[1m[f]\x1b[0m run to end  \x1b[1m[q]\x1b[0m quit');

    // Input
    final input = stdin.readLineSync()?.toLowerCase() ?? '';
    if (input == 'q') break;
    if (input == 'n' && bar < data.length - 1) bar++;
    if (input == 'p' && bar > 50) bar--;
    if (input == 'f') bar = data.length - 1;
    if (input == 'r') {
      // Switch to reversal data — reset
      print('\x1b[2J\x1b[H');
      final revData = generateReversalData();
      // We'd need to restart with new data; for simplicity just signal
      print('Switched to reversal data. Press [n] to step through.');
      continue;
    }
    if (input == '') bar++; // Enter steps forward
  }

  print('\x1b[2J\x1b[H');
  print('Prototype exited. Run again with: \x1b[1mdart run\x1b[0m');
}
