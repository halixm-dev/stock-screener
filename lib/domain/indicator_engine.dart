import 'dart:math' as math;
import 'math_utils.dart';

// ═══════════════════════════════════════════════════════════════════
// RANGE FILTER (Pine: lines 966-1094)
// ═══════════════════════════════════════════════════════════════════

class RangeFilterResult {
  final List<double> filt;
  final List<double> upward;
  final List<double> downward;
  final List<bool> uprf, downrf;

  const RangeFilterResult({
    required this.filt,
    required this.upward,
    required this.downward,
    required this.uprf,
    required this.downrf,
  });
}

RangeFilterResult calcRangeFilter(
    List<double> src, int period, double multiplier) {
  final n = src.length;
  final wper = period * 2 - 1;
  final absDiff = List<double>.generate(
      n, (i) => i == 0 ? 0.0 : (src[i] - src[i - 1]).abs());
  final avrng = ema(absDiff, period);
  final smrng = sma(avrng, wper).map((v) => v * multiplier).toList();

  final filt = List<double>.filled(n, src[0]);
  for (int i = 1; i < n; i++) {
    final p = filt[i - 1], r = smrng[i];
    filt[i] = src[i] > p
        ? (src[i] - r < p ? p : src[i] - r)
        : (src[i] + r > p ? p : src[i] + r);
  }

  final upward = List<double>.filled(n, 0);
  final downward = List<double>.filled(n, 0);
  for (int i = 1; i < n; i++) {
    if (filt[i] > filt[i - 1]) {
      upward[i] = upward[i - 1] + 1;
      downward[i] = 0;
    } else if (filt[i] < filt[i - 1]) {
      downward[i] = downward[i - 1] + 1;
      upward[i] = 0;
    } else {
      upward[i] = upward[i - 1];
      downward[i] = downward[i - 1];
    }
  }

  final uprf = List<bool>.filled(n, false);
  final downrf = List<bool>.filled(n, false);
  for (int i = 1; i < n; i++) {
    uprf[i] =
        (src[i] > filt[i] && src[i] > src[i - 1] && upward[i] > 0) ||
        (src[i] > filt[i] && src[i] < src[i - 1] && upward[i] > 0);
    downrf[i] =
        (src[i] < filt[i] && src[i] < src[i - 1] && downward[i] > 0) ||
        (src[i] < filt[i] && src[i] > src[i - 1] && downward[i] > 0);
  }

  return RangeFilterResult(
      filt: filt, upward: upward, downward: downward, uprf: uprf, downrf: downrf);
}

// ═══════════════════════════════════════════════════════════════════
// RQK — Rational Quadratic Kernel (Pine: lines 1097-1148)
// ═══════════════════════════════════════════════════════════════════

class RQKResult {
  final List<double> yhat1, yhat2;
  final List<bool> uptrend, downtrend;
  final List<bool> bullishCross, bearishCross;

  const RQKResult({
    required this.yhat1,
    required this.yhat2,
    required this.uptrend,
    required this.downtrend,
    required this.bullishCross,
    required this.bearishCross,
  });
}

RQKResult calcRQK(
    List<double> src, double h2, double r, int x0, int lagVal) {
  final n = src.length;
  final yhat1 = List<double>.filled(n, double.nan);
  final yhat2 = List<double>.filled(n, double.nan);
  final eff = 1 + x0;

  double kernel(int bi, double h) {
    double ws = 0, vs = 0;
    final ml = math.min(eff, bi + 1);
    for (int i = 0; i < ml; i++) {
      final y = src[bi - i];
      final w = math.pow(1 + (i * i) / (h * h * 2 * r), -r).toDouble();
      vs += y * w;
      ws += w;
    }
    return ws > 0 ? vs / ws : double.nan;
  }

  for (int i = x0; i < n; i++) {
    yhat1[i] = kernel(i, h2);
    yhat2[i] = kernel(i, h2 - lagVal);
  }

  final uptrend = List<bool>.filled(n, false);
  final downtrend = List<bool>.filled(n, false);
  final bullishCross = List<bool>.filled(n, false);
  final bearishCross = List<bool>.filled(n, false);

  for (int i = x0 + 1; i < n; i++) {
    if (!yhat1[i - 1].isNaN && !yhat1[i].isNaN) {
      uptrend[i] = yhat1[i - 1] < yhat1[i];
      downtrend[i] = yhat1[i - 1] > yhat1[i];
    }
    if (!yhat1[i].isNaN && !yhat2[i].isNaN && i > 1) {
      bullishCross[i] = yhat2[i - 1] <= yhat1[i - 1] && yhat2[i] > yhat1[i];
      bearishCross[i] = yhat2[i - 1] >= yhat1[i - 1] && yhat2[i] < yhat1[i];
    }
  }

  return RQKResult(
      yhat1: yhat1,
      yhat2: yhat2,
      uptrend: uptrend,
      downtrend: downtrend,
      bullishCross: bullishCross,
      bearishCross: bearishCross);
}

// ═══════════════════════════════════════════════════════════════════
// HALF TREND (Pine: lines 1239-1323)
// ═══════════════════════════════════════════════════════════════════

class HalfTrendResult {
  final List<int> trend; // 0=long, 1=short
  final List<double> htLine;
  final List<bool> isLong, isShort;

  const HalfTrendResult({
    required this.trend,
    required this.htLine,
    required this.isLong,
    required this.isShort,
  });
}

HalfTrendResult calcHalfTrend(
    List<double> high, List<double> low, List<double> close,
    {int amplitude = 2, int channelDeviation = 2}) {
  final n = close.length;
  final atrVals = atr(high, low, close, 100);
  final dev = atrVals.map((a) => channelDeviation * a / 2).toList();

  List<double> highPrice(List<double> h, int amp) {
    final r = List<double>.filled(n, h[0]);
    for (int i = amp - 1; i < n; i++) {
      double mx = h[i];
      for (int j = 0; j < amp; j++) mx = math.max(mx, h[i - j]);
      r[i] = mx;
    }
    return r;
  }

  List<double> lowPrice(List<double> l, int amp) {
    final r = List<double>.filled(n, l[0]);
    for (int i = amp - 1; i < n; i++) {
      double mn = l[i];
      for (int j = 0; j < amp; j++) mn = math.min(mn, l[i - j]);
      r[i] = mn;
    }
    return r;
  }

  final hp = highPrice(high, amplitude);
  final lp = lowPrice(low, amplitude);
  final highma = sma(high, amplitude);
  final lowma = sma(low, amplitude);

  final trend = List<int>.filled(n, 0);
  final htUp = List<double>.filled(n, 0.0);
  final htDown = List<double>.filled(n, 0.0);
  final ht = List<double>.filled(n, 0.0);
  int nextTrend = 0;
  double maxLowPrice = low[0];
  double minHighPrice = high[0];

  for (int i = 1; i < n; i++) {
    if (nextTrend == 1) {
      maxLowPrice = math.max(lp[i], maxLowPrice);
      if (highma[i] < maxLowPrice && close[i] < low[i - 1]) {
        trend[i] = 1;
        nextTrend = 0;
        minHighPrice = hp[i];
      } else {
        trend[i] = trend[i - 1];
      }
    } else {
      minHighPrice = math.min(hp[i], minHighPrice);
      if (lowma[i] > minHighPrice && close[i] > high[i - 1]) {
        trend[i] = 0;
        nextTrend = 1;
        maxLowPrice = lp[i];
      } else {
        trend[i] = trend[i - 1];
      }
    }

    if (trend[i] == 0) {
      htUp[i] = (i > 0 && trend[i - 1] != 0)
          ? htDown[i - 1]
          : math.max(maxLowPrice, (i > 0 ? htUp[i - 1] : maxLowPrice));
      ht[i] = htUp[i];
    } else {
      htDown[i] = (i > 0 && trend[i - 1] != 1)
          ? htUp[i - 1]
          : math.min(minHighPrice, (i > 0 ? htDown[i - 1] : minHighPrice));
      ht[i] = htDown[i];
    }
  }

  return HalfTrendResult(
    trend: trend,
    htLine: ht,
    isLong: trend.map((t) => t == 0).toList(),
    isShort: trend.map((t) => t == 1).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════
// SUPERTREND (Pine: lines 1191-1225)
// ═══════════════════════════════════════════════════════════════════

class SuperTrendResult {
  final List<int> trend; // 1=up, -1=down
  final List<double> upper, lower;
  final List<bool> isUp, isDown;

  const SuperTrendResult({
    required this.trend,
    required this.upper,
    required this.lower,
    required this.isUp,
    required this.isDown,
  });
}

SuperTrendResult calcSuperTrend(List<double> high, List<double> low,
    List<double> close, {int period = 10, double multiplier = 3.0}) {
  final n = close.length;
  final hl2 = List.generate(n, (i) => (high[i] + low[i]) / 2);
  final atrVals = atr(high, low, close, period);
  final up = List<double>.filled(n, 0.0);
  final dn = List<double>.filled(n, 0.0);
  final trend = List<int>.filled(n, 1);

  for (int i = 0; i < n; i++) {
    up[i] = hl2[i] - multiplier * atrVals[i];
    dn[i] = hl2[i] + multiplier * atrVals[i];
  }

  for (int i = 1; i < n; i++) {
    if (close[i - 1] > up[i - 1]) up[i] = math.max(up[i], up[i - 1]);
    if (close[i - 1] < dn[i - 1]) dn[i] = math.min(dn[i], dn[i - 1]);
  }

  for (int i = 1; i < n; i++) {
    if (trend[i - 1] == -1 && close[i] > dn[i - 1]) {
      trend[i] = 1;
    } else if (trend[i - 1] == 1 && close[i] < up[i - 1]) {
      trend[i] = -1;
    } else {
      trend[i] = trend[i - 1];
    }
  }

  return SuperTrendResult(
    trend: trend,
    upper: up,
    lower: dn,
    isUp: trend.map((t) => t == 1).toList(),
    isDown: trend.map((t) => t == -1).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════
// TSI — True Strength Indicator (Pine: lines 1157-1184)
// ═══════════════════════════════════════════════════════════════════

class TSIResult {
  final List<double> value, signal;
  final List<bool> isLong, isShort;

  const TSIResult(
      {required this.value,
      required this.signal,
      required this.isLong,
      required this.isShort});
}

TSIResult calcTSI(List<double> close,
    {int longLen = 25, int shortLen = 13, int signalLen = 13}) {
  final pc = change(close);
  final absPc = pc.map((v) => v.abs()).toList();
  final dspc = ema(ema(pc, longLen), shortLen);
  final dsabs = ema(ema(absPc, longLen), shortLen);
  final value = List<double>.generate(
      close.length, (i) => dsabs[i] != 0 ? 100 * dspc[i] / dsabs[i] : 0);
  final sig = ema(value, signalLen);
  final isLong = List.generate(close.length, (i) => value[i] > sig[i]);
  final isShort = List.generate(close.length, (i) => value[i] < sig[i]);
  return TSIResult(value: value, signal: sig, isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// TDFI — Trend Direction Force Index (Pine: lines 1588-1628)
// ═══════════════════════════════════════════════════════════════════

class TDFIResult {
  final List<double> signal;
  final List<bool> isLong, isShort;

  const TDFIResult(
      {required this.signal, required this.isLong, required this.isShort});
}

TDFIResult calcTDFI(List<double> close,
    {int lookback = 13,
    int mmaLen = 13,
    int smmaLen = 13,
    int nLen = 3,
    double filterHigh = 0.05,
    double filterLow = -0.05}) {
  final n = close.length;
  final price = close.map((v) => v * 1000).toList();
  final mma = ema(price, mmaLen);
  final smma2 = ema(mma, smmaLen);
  final impetmma = change(mma);
  final impetsmma = change(smma2);
  final signal = List<double>.filled(n, 0);
  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);

  for (int i = nLen; i < n; i++) {
    final divma = (mma[i] - smma2[i]).abs();
    final avgi = (impetmma[i] + impetsmma[i]) / 2;
    final tdf = math.pow(divma, 1) * math.pow(avgi.abs(), nLen);
    // Simple normalization
    signal[i] = tdf.toDouble();
    isLong[i] = signal[i] > filterHigh;
    isShort[i] = signal[i] < filterLow;
  }

  return TDFIResult(signal: signal, isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// DONCHIAN TREND RIBBON (Pine: lines 1487-1511)
// ═══════════════════════════════════════════════════════════════════

class DonchianResult {
  final List<int> trend;
  final List<bool> isLong, isShort;

  const DonchianResult(
      {required this.trend, required this.isLong, required this.isShort});
}

DonchianResult calcDonchian(List<double> high, List<double> low,
    List<double> close, {int period = 15}) {
  final n = close.length;
  final hh = highest(high, period);
  final ll = lowest(low, period);
  final trend = List<int>.filled(n, 0);
  trend[0] = 1;
  for (int i = 1; i < n; i++) {
    trend[i] = close[i] > hh[i - 1]
        ? 1
        : close[i] < ll[i - 1]
            ? -1
            : trend[i - 1];
  }
  return DonchianResult(
    trend: trend,
    isLong: trend.map((t) => t == 1).toList(),
    isShort: trend.map((t) => t == -1).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════
// ROC — Rate of Change (Pine: lines 1868-1875)
// ═══════════════════════════════════════════════════════════════════

class ROCResult {
  final List<double> roc;
  final List<bool> isLong, isShort;

  const ROCResult(
      {required this.roc, required this.isLong, required this.isShort});
}

ROCResult calcROC(List<double> close, {int length = 9}) {
  final n = close.length;
  final roc = List<double>.filled(n, 0);
  for (int i = length; i < n; i++) {
    roc[i] = close[i - length] != 0
        ? 100 * (close[i] - close[i - length]) / close[i - length]
        : 0;
  }
  return ROCResult(
    roc: roc,
    isLong: roc.map((v) => v > 0).toList(),
    isShort: roc.map((v) => v < 0).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════
// ICHIMOKU CLOUD (Pine: lines 1399-1437)
// ═══════════════════════════════════════════════════════════════════

class IchimokuResult {
  final List<bool> isLong, isShort;

  const IchimokuResult({required this.isLong, required this.isShort});
}

IchimokuResult calcIchimoku(List<double> high, List<double> low,
    List<double> close, {int conversion = 9, int base = 26, int spanB = 52, int displace = 26}) {
  final n = close.length;
  final conv = List<double>.filled(n, 0);
  final baseL = List<double>.filled(n, 0);
  final lead1 = List<double>.filled(n, 0);
  final lead2 = List<double>.filled(n, 0);

  for (int i = 0; i < n; i++) {
    conv[i] = (highest(high, conversion)[i] + lowest(low, conversion)[i]) / 2;
    baseL[i] = (highest(high, base)[i] + lowest(low, base)[i]) / 2;
    lead1[i] = (conv[i] + baseL[i]) / 2;
    lead2[i] = (highest(high, spanB)[i] + lowest(low, spanB)[i]) / 2;
  }

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = displace; i < n; i++) {
    final d = displace - 1;
    final l1 = i - d >= 0 ? lead1[i - d] : lead1[0];
    final l2 = i - d >= 0 ? lead2[i - d] : lead2[0];
    final chunk = i - 50 >= 0 ? close[i - 50] : close[0];
    isLong[i] = conv[i] > baseL[i] && lead1[i] > lead2[i] &&
        close[i] > l1 && close[i] > l2 && chunk > lead1[i - 50 >= 0 ? i - 50 : 0] && chunk > lead2[i - 50 >= 0 ? i - 50 : 0];
    isShort[i] = conv[i] < baseL[i] && lead1[i] < lead2[i] &&
        close[i] < l1 && close[i] < l2 && chunk < lead2[i - 50 >= 0 ? i - 50 : 0] && chunk < lead1[i - 50 >= 0 ? i - 50 : 0];
  }
  return IchimokuResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// SUPER ICHI (Pine: lines 1442-1482)
// ═══════════════════════════════════════════════════════════════════

class SuperIchiResult {
  final List<bool> isLong, isShort;

  const SuperIchiResult({required this.isLong, required this.isShort});
}

SuperIchiResult calcSuperIchi(List<double> high, List<double> low,
    List<double> close, {int tenkanLen = 9, double tenkanMult = 2,
    int kijunLen = 26, double kijunMult = 4, int spanBLen = 52,
    double spanBMult = 6, int displace = 26}) {
  final n = close.length;
  final atrV = atr(high, low, close, kijunLen);

  double avgPrice(List<double> src, int len, double mult, int i) {
    final a = atrV[i] * mult;
    final up = (high[i] + low[i]) / 2 + a;
    final dn = (high[i] + low[i]) / 2 - a;
    return (up + dn) / 2; // simplified
  }

  final tenkan = List<double>.filled(n, 0);
  final kijun = List<double>.filled(n, 0);
  final sB = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    tenkan[i] = avgPrice(close, tenkanLen, tenkanMult, i);
    kijun[i] = avgPrice(close, kijunLen, kijunMult, i);
    sB[i] = avgPrice(close, spanBLen, spanBMult, i);
  }

  final sA = List.generate(n, (i) => (kijun[i] + tenkan[i]) / 2);
  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = displace; i < n; i++) {
    final sA1 = sA[i - displace + 1], sB1 = sB[i - displace + 1];
    final c50 = i - 50 >= 0 ? close[i - 50] : close[0];
    final sA50 = i - 50 >= 0 ? sA[i - 50] : sA[0];
    final sB50 = i - 50 >= 0 ? sB[i - 50] : sB[0];
    isLong[i] = tenkan[i] > kijun[i] && sA[i] > sB[i] &&
        close[i] > sA1 && close[i] > sB1 && c50 > sA50 && c50 > sB50;
    isShort[i] = tenkan[i] < kijun[i] && sA[i] < sB[i] &&
        close[i] < sA1 && close[i] < sB1 && c50 < sB50 && c50 < sA50;
  }
  return SuperIchiResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// STOCHASTIC (Pine: lines 2763-2790)
// ═══════════════════════════════════════════════════════════════════

class StochResult {
  final List<double> k, d;
  final List<bool> isLong, isShort;

  const StochResult(
      {required this.k, required this.d, required this.isLong, required this.isShort});
}

StochResult calcStochastic(List<double> high, List<double> low,
    List<double> close, {int length = 14, int smoothK = 3, int smoothD = 3,
    int ob = 80, int os = 20, String type = 'CrossOver'}) {
  final n = close.length;
  final rawK = List<double>.filled(n, 50);
  for (int i = length - 1; i < n; i++) {
    final ll = lowest(low, length)[i];
    final hh = highest(high, length)[i];
    rawK[i] = hh != ll ? 100 * (close[i] - ll) / (hh - ll) : 50;
  }
  final k = sma(rawK, smoothK);
  final d = sma(k, smoothD);

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = 1; i < n; i++) {
    if (type == 'CrossOver') {
      isLong[i] = k[i - 1] < d[i - 1] && k[i] > d[i];
      isShort[i] = k[i - 1] > d[i - 1] && k[i] < d[i];
    } else if (type == 'CrossOver in OB & OS levels') {
      isLong[i] = k[i - 1] < d[i - 1] && k[i - 1] < os && k[i] > d[i] && k[i] > os;
      isShort[i] = k[i - 1] > d[i - 1] && k[i - 1] > ob && k[i] < d[i] && k[i] < ob;
    } else {
      isLong[i] = k[i] > d[i];
      isShort[i] = k[i] < d[i];
    }
  }
  return StochResult(k: k, d: d, isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// RSI (Pine: lines 2795-2842)
// ═══════════════════════════════════════════════════════════════════

class RSIResult {
  final List<double> rsi, rsiMA;
  final List<bool> isLong, isShort, maUp, maDown;
  final List<bool> maLimitLong, maLimitShort, limitLong, limitShort;

  const RSIResult({
    required this.rsi,
    required this.rsiMA,
    required this.isLong,
    required this.isShort,
    required this.maUp,
    required this.maDown,
    required this.maLimitLong,
    required this.maLimitShort,
    required this.limitLong,
    required this.limitShort,
  });
}

RSIResult calcRSI(List<double> close,
    {int length = 14, String maType = 'SMA', int maLen = 14,
    int ob = 80, int os = 20, int level = 50,
    String rsiType = 'RSI MA Cross',
    int limitUp = 40, int limitDown = 60,
    int maLimitUp = 40, int maLimitDown = 60}) {
  final n = close.length;
  final up = rma(List.generate(n, (i) => i > 0 ? math.max(close[i] - close[i - 1], 0) : 0), length);
  final down = rma(List.generate(n, (i) => i > 0 ? math.max(close[i - 1] - close[i], 0) : 0), length);
  final rsi = List<double>.filled(n, 50);
  for (int i = 0; i < n; i++) {
    rsi[i] = down[i] == 0 ? 100 : up[i] == 0 ? 0 : 100 - 100 / (1 + up[i] / down[i]);
  }
  final rsiMA = movingAverage(rsi, maLen, maType);

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = 0; i < n; i++) {
    if (rsiType == 'RSI MA Cross') {
      isLong[i] = rsi[i] > rsiMA[i];
      isShort[i] = rsi[i] < rsiMA[i];
    } else if (rsiType == 'RSI Exits OB/OS zones') {
      isLong[i] = rsi[i] > os && i > 0 && rsi[i - 1] < os;
      isShort[i] = rsi[i] < ob && i > 0 && rsi[i - 1] > ob;
    } else {
      isLong[i] = rsi[i] > level;
      isShort[i] = rsi[i] < level;
    }
  }

  final maUp = List.generate(n, (i) => i > 0 ? rsiMA[i] >= rsiMA[i - 1] : true);
  final maDown = List.generate(n, (i) => i > 0 ? rsiMA[i] <= rsiMA[i - 1] : true);
  final maLimitLong = rsiMA.map((v) => v >= maLimitUp).toList();
  final maLimitShort = rsiMA.map((v) => v <= maLimitDown).toList();
  final limitLong = rsi.map((v) => v >= limitUp).toList();
  final limitShort = rsi.map((v) => v <= limitDown).toList();

  return RSIResult(
    rsi: rsi, rsiMA: rsiMA, isLong: isLong, isShort: isShort,
    maUp: maUp, maDown: maDown, maLimitLong: maLimitLong,
    maLimitShort: maLimitShort, limitLong: limitLong, limitShort: limitShort,
  );
}

// ═══════════════════════════════════════════════════════════════════
// MACD (Pine: lines 2248-2272)
// ═══════════════════════════════════════════════════════════════════

class MACDResult {
  final List<double> macd, signal, hist;
  final List<bool> isLong, isShort;

  const MACDResult({
    required this.macd, required this.signal, required this.hist,
    required this.isLong, required this.isShort,
  });
}

MACDResult calcMACD(List<double> close,
    {int fast = 12, int slow = 26, int signalLen = 9,
    String macdType = 'MACD Crossover'}) {
  final fastMA = ema(close, fast);
  final slowMA = ema(close, slow);
  final macd = List.generate(close.length, (i) => fastMA[i] - slowMA[i]);
  final sig = ema(macd, signalLen);
  final isLong = List<bool>.filled(close.length, false);
  final isShort = List<bool>.filled(close.length, false);
  for (int i = 0; i < close.length; i++) {
    if (macdType == 'MACD Crossover') {
      isLong[i] = macd[i] > sig[i];
      isShort[i] = macd[i] < sig[i];
    } else {
      isLong[i] = macd[i] > sig[i] && macd[i] > 0;
      isShort[i] = macd[i] < sig[i] && macd[i] < 0;
    }
  }
  return MACDResult(
    macd: macd, signal: sig,
    hist: List.generate(close.length, (i) => macd[i] - sig[i]),
    isLong: isLong, isShort: isShort,
  );
}

// ═══════════════════════════════════════════════════════════════════
// SSL CHANNEL (Pine: lines 1884-1895)
// ═══════════════════════════════════════════════════════════════════

class SSLResult {
  final List<bool> isLong, isShort;

  const SSLResult({required this.isLong, required this.isShort});
}

SSLResult calcSSL(List<double> high, List<double> low, List<double> close,
    {int period = 10}) {
  final smaH = sma(high, period);
  final smaL = sma(low, period);
  final isLong = List<bool>.filled(close.length, false);
  final isShort = List<bool>.filled(close.length, false);
  int hlv = 0;
  for (int i = 0; i < close.length; i++) {
    hlv = close[i] > smaH[i] ? 1 : close[i] < smaL[i] ? -1 : hlv;
    final sslDown = hlv < 0 ? smaH[i] : smaL[i];
    final sslUp = hlv < 0 ? smaL[i] : smaH[i];
    isLong[i] = sslUp > sslDown;
    isShort[i] = sslUp < sslDown;
  }
  return SSLResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// B-XTRENDER (Pine: lines 1684-1722)
// ═══════════════════════════════════════════════════════════════════

class BXtrenderResult {
  final List<bool> isLong, isShort;

  const BXtrenderResult({required this.isLong, required this.isShort});
}

BXtrenderResult calcBXtrender(List<double> close,
    {int shortL1 = 5, int shortL2 = 20, int shortL3 = 15,
    int longL1 = 5, int longL2 = 10, String bxType = 'Short and Long term trend'}) {
  final n = close.length;
  final emaShort1 = ema(close, shortL1);
  final emaShort2 = ema(close, shortL2);

  List<double> t3(List<double> src, int len) {
    final e1 = ema(src, len);
    final e2 = ema(e1, len);
    final e3 = ema(e2, len);
    final e4 = ema(e3, len);
    final e5 = ema(e4, len);
    final e6 = ema(e5, len);
    final b = 0.7;
    final c1 = -b * b * b;
    final c2 = 3 * b * b + 3 * b * b * b;
    final c3 = -6 * b * b - 3 * b - 3 * b * b * b;
    final c4 = 1 + 3 * b + b * b * b + 3 * b * b;
    return List.generate(n,
        (i) => c1 * e6[i] + c2 * e5[i] + c3 * e4[i] + c4 * e3[i]);
  }

  // short term xtrender: RSI(EMA(close, L1) - EMA(close, L2), L3) - 50
  final diff = List.generate(n, (i) => emaShort1[i] - emaShort2[i]);
  final upDiff = rma(List.generate(n, (i) => diff[i] > 0 ? diff[i] : 0), shortL3);
  final downDiff = rma(List.generate(n, (i) => diff[i] < 0 ? -diff[i] : 0), shortL3);
  final shortXR = List.generate(n,
      (i) => (upDiff[i] + downDiff[i]) != 0 ? 100 - 100 / (1 + upDiff[i] / (downDiff[i] != 0 ? downDiff[i] : 0.001)) - 50 : 0);
  final maShort = t3(shortXR.cast<double>(), 5);

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);

  if (bxType == 'Short Term trend') {
    for (int i = 1; i < n; i++) {
      isLong[i] = maShort[i] > maShort[i - 1];
      isShort[i] = maShort[i] < maShort[i - 1];
    }
  } else {
    final emaL1 = ema(close, longL1);
    final upL = rma(List.generate(n, (i) => i > 0 && close[i] - close[i - 1] > 0 ? close[i] - close[i - 1] : 0), longL2);
    final downL = rma(List.generate(n, (i) => i > 0 && close[i - 1] - close[i] > 0 ? close[i - 1] - close[i] : 0), longL2);
    final longXR = List.generate(n,
        (i) => (upL[i] + downL[i]) != 0 ? 100 - 100 / (1 + upL[i] / (downL[i] != 0 ? downL[i] : 0.001)) - 50 : 0);
    for (int i = 1; i < n; i++) {
      isLong[i] = maShort[i] > maShort[i - 1] && longXR[i] > 0 && longXR[i] > longXR[i - 1] && shortXR[i] > shortXR[i - 1] && shortXR[i] > 0;
      isShort[i] = maShort[i] < maShort[i - 1] && longXR[i] < 0 && longXR[i] < longXR[i - 1] && shortXR[i] < shortXR[i - 1] && shortXR[i] < 0;
    }
  }
  return BXtrenderResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// BBPT — Bull Bear Power Trend (Pine: lines 1726-1755)
// ═══════════════════════════════════════════════════════════════════

class BBPTResult {
  final List<bool> isLong, isShort;

  const BBPTResult({required this.isLong, required this.isShort});
}

BBPTResult calcBBPT(List<double> high, List<double> low, List<double> close,
    {String type = 'Follow Trend'}) {
  final n = close.length;
  final atr5 = atr(high, low, close, 5);
  final ll50 = lowest(low, 50);
  final hh50 = highest(high, 50);
  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);

  for (int i = 0; i < n; i++) {
    final bullT = (close[i] - ll50[i]) / atr5[i];
    final bearT = (hh50[i] - close[i]) / atr5[i];
    final trend = bullT - bearT;
    final bearT2 = -bearT;
    final bearHist = bearT2 > -2 ? bearT2 + 2 : 0.0;
    final bullHist = bullT < 2 ? bullT - 2 : 0.0;

    if (type == 'Follow Trend') {
      isLong[i] = bearHist > 0 && trend >= 2;
      isShort[i] = bullHist < 0 && trend <= -2;
    } else {
      isLong[i] = bearHist > 0;
      isShort[i] = bullHist < 0;
    }
  }
  return BBPTResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// VWAP (Pine: lines 1758-1820)
// ═══════════════════════════════════════════════════════════════════

class VWAPResult {
  final List<double> vwap;
  final List<bool> isLong, isShort;

  const VWAPResult(
      {required this.vwap, required this.isLong, required this.isShort});
}

VWAPResult calcVWAP(List<double> high, List<double> low,
    List<double> close, List<int> volume) {
  final n = close.length;
  final vwap = List<double>.filled(n, 0);
  double cumPV = 0, cumVol = 0;
  for (int i = 0; i < n; i++) {
    final tp = (high[i] + low[i] + close[i]) / 3;
    cumPV += tp * volume[i];
    cumVol += volume[i];
    vwap[i] = cumVol > 0 ? cumPV / cumVol : tp;
  }
  return VWAPResult(
    vwap: vwap,
    isLong: List.generate(n, (i) => close[i] > vwap[i]),
    isShort: List.generate(n, (i) => close[i] < vwap[i]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// CHANDELIER EXIT (Pine: lines 1830-1855)
// ═══════════════════════════════════════════════════════════════════

class ChandelierResult {
  final List<int> dir;
  final List<bool> isLong, isShort;

  const ChandelierResult(
      {required this.dir, required this.isLong, required this.isShort});
}

ChandelierResult calcChandelier(List<double> high, List<double> low,
    List<double> close, {int length = 22, double mult = 3.0, bool useClose = true}) {
  final n = close.length;
  final atrV = atr(high, low, close, length);
  final hh = useClose ? highest(close, length) : highest(high, length);
  final ll = useClose ? lowest(close, length) : lowest(low, length);
  final longStop = List<double>.filled(n, 0);
  final shortStop = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    longStop[i] = hh[i] - mult * atrV[i];
    shortStop[i] = ll[i] + mult * atrV[i];
  }
  final dir = List<int>.filled(n, 1);
  for (int i = 1; i < n; i++) {
    if (close[i] > shortStop[i - 1]) dir[i] = 1;
    else if (close[i] < longStop[i - 1]) dir[i] = -1;
    else dir[i] = dir[i - 1];
  }
  return ChandelierResult(
    dir: dir,
    isLong: dir.map((d) => d == 1).toList(),
    isShort: dir.map((d) => d == -1).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════
// CCI (Pine: lines 1654-1675)
// ═══════════════════════════════════════════════════════════════════

class CCIResult {
  final List<double> cci, smoothed;
  final List<bool> isLong, isShort;

  const CCIResult({
    required this.cci, required this.smoothed,
    required this.isLong, required this.isShort,
  });
}

CCIResult calcCCI(List<double> high, List<double> low, List<double> close,
    {int length = 20, int upper = 100, int lower = -100,
    String maType = 'SMA', int smoothLen = 5}) {
  final n = close.length;
  final src = List.generate(n, (i) => (high[i] + low[i] + close[i]) / 3);
  final ma = sma(src, length);
  final cci = List<double>.filled(n, 0);
  for (int i = length - 1; i < n; i++) {
    double dev = 0;
    for (int j = 0; j < length; j++) dev += (src[i - j] - ma[i]).abs();
    dev /= length;
    cci[i] = dev != 0 ? (src[i] - ma[i]) / (0.015 * dev) : 0;
  }
  final smoothed = movingAverage(cci, smoothLen, maType);
  return CCIResult(
    cci: cci, smoothed: smoothed,
    isLong: cci.map((v) => v > upper).toList(),
    isShort: cci.map((v) => v < lower).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════
// ADX/DMI (Pine: lines 1518-1561)
// ═══════════════════════════════════════════════════════════════════

class ADXResult {
  final List<double> adx, diPlus, diMinus;
  final List<bool> isLong, isShort;

  const ADXResult({
    required this.adx, required this.diPlus, required this.diMinus,
    required this.isLong, required this.isShort,
  });
}

ADXResult calcADX(List<double> high, List<double> low, List<double> close,
    {int adxLen = 5, int diLen = 10, int keyLevel = 20,
    String adxType = 'Adx & +Di -Di'}) {
  final n = close.length;
  final trRma = rma(trueRange(high, low, close), diLen);
  final up = change(high).map((v) => v > 0 ? v : 0.0).toList();
  final down = change(low).map((v) => v > 0 ? v : 0.0).toList();
  final plusDM = rma(List.generate(n, (i) => up[i] > down[i] ? up[i] : 0), diLen);
  final minusDM = rma(List.generate(n, (i) => down[i] > up[i] ? down[i] : 0), diLen);
  final diPlus = fixnan(List.generate(n, (i) => trRma[i] != 0 ? 100 * plusDM[i] / trRma[i] : 0));
  final diMinus = fixnan(List.generate(n, (i) => trRma[i] != 0 ? 100 * minusDM[i] / trRma[i] : 0));
  final sum = List.generate(n, (i) => diPlus[i] + diMinus[i]);
  final adx = rma(List.generate(n, (i) => sum[i] != 0 ? 100 * (diPlus[i] - diMinus[i]).abs() / sum[i] : 0), adxLen);

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = 0; i < n; i++) {
    if (adxType == 'Adx Only') {
      isLong[i] = adx[i] > keyLevel;
      isShort[i] = adx[i] > keyLevel;
    } else if (adxType == 'Adx & +Di -Di') {
      isLong[i] = diPlus[i] > diMinus[i] && adx[i] >= keyLevel;
      isShort[i] = diPlus[i] < diMinus[i] && adx[i] >= keyLevel;
    } else {
      isLong[i] = diPlus[i] > diMinus[i] && adx[i] >= keyLevel && (diPlus[i] - diMinus[i]) > 1;
      isShort[i] = diPlus[i] < diMinus[i] && adx[i] >= keyLevel && (diMinus[i] - diPlus[i]) > 1;
    }
  }
  return ADXResult(adx: adx, diPlus: diPlus, diMinus: diMinus, isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// PARABOLIC SAR (Pine: lines 1567-1583)
// ═══════════════════════════════════════════════════════════════════

class PSARResult {
  final List<double> sar;
  final List<bool> isUp, isDown;

  const PSARResult(
      {required this.sar, required this.isUp, required this.isDown});
}

PSARResult calcPSAR(List<double> high, List<double> low, List<double> close,
    {double start = 0.02, double increment = 0.02, double max = 0.2}) {
  final n = close.length;
  final sar = List<double>.filled(n, 0);
  final af = List<double>.filled(n, start);
  bool isUp = true;
  double ep = low[0];
  sar[0] = high[0]; // initial guess
  final isUpList = List<bool>.filled(n, false);
  final isDownList = List<bool>.filled(n, false);

  for (int i = 1; i < n; i++) {
    if (isUp) {
      sar[i] = sar[i - 1] + af[i - 1] * (ep - sar[i - 1]);
      if (low[i] < sar[i]) {
        isUp = false;
        sar[i] = ep;
        ep = low[i];
        af[i] = start;
      } else {
        if (high[i] > ep) {
          ep = high[i];
          af[i] = (af[i - 1] + increment).clamp(0, max);
        } else {
          af[i] = af[i - 1];
        }
      }
    } else {
      sar[i] = sar[i - 1] + af[i - 1] * (ep - sar[i - 1]);
      if (high[i] > sar[i]) {
        isUp = true;
        sar[i] = ep;
        ep = high[i];
        af[i] = start;
      } else {
        if (low[i] < ep) {
          ep = low[i];
          af[i] = (af[i - 1] + increment).clamp(0, max);
        } else {
          af[i] = af[i - 1];
        }
      }
    }
    isUpList[i] = isUp;
    isDownList[i] = !isUp;
  }
  return PSARResult(sar: sar, isUp: isUpList, isDown: isDownList);
}

// ═══════════════════════════════════════════════════════════════════
// WADDAH ATTAR EXPLOSION (Pine: lines 1943-1981)
// ═══════════════════════════════════════════════════════════════════

class WAEResult {
  final List<bool> isLong, isShort;

  const WAEResult({required this.isLong, required this.isShort});
}

WAEResult calcWAE(List<double> high, List<double> low, List<double> close,
    {int sensitivity = 150, int fastLen = 20, int slowLen = 40,
    int channelLen = 20, double mult = 2.0}) {
  final n = close.length;
  final fastMA = ema(close, fastLen);
  final slowMA = ema(close, slowLen);
  final macd = List.generate(n, (i) => fastMA[i] - slowMA[i]);
  final macdPrev = [0.0, ...macd.sublist(0, n - 1)];
  final t1 = List.generate(n, (i) => (macd[i] - macdPrev[i]) * sensitivity);
  final basis = sma(close, channelLen);
  final dev = List.generate(n, (i) => mult * stdev(close, channelLen)[i]);
  final bbUpper = List.generate(n, (i) => basis[i] + dev[i]);
  final bbLower = List.generate(n, (i) => basis[i] - dev[i]);
  final e1 = List.generate(n, (i) => (bbUpper[i] - bbLower[i]).abs());
  final trV = trueRange(high, low, close);
  final deadzone = rma(trV, 100).map((v) => v * 3.7).toList();

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = 0; i < n; i++) {
    final trendUp = t1[i] >= 0 ? t1[i] : 0.0;
    final trendDown = t1[i] < 0 ? -t1[i] : 0.0;
    isLong[i] = trendUp > e1[i] && e1[i] > deadzone[i] && trendUp > deadzone[i];
    isShort[i] = trendDown > e1[i] && e1[i] > deadzone[i] && trendDown > deadzone[i];
  }
  return WAEResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// VOLATILITY OSCILLATOR (Pine: lines 2097-2110)
// ═══════════════════════════════════════════════════════════════════

class VolatilityOscResult {
  final List<bool> isLong, isShort;

  const VolatilityOscResult({required this.isLong, required this.isShort});
}

VolatilityOscResult calcVolatilityOsc(
    List<double> open, List<double> high, List<double> low, List<double> close,
    {int length = 100}) {
  final n = close.length;
  final spike = List.generate(n, (i) => close[i] - open[i]);
  final stdV = stdev(spike, length);
  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = 0; i < n; i++) {
    isLong[i] = spike[i] > stdV[i];
    isShort[i] = spike[i] < -stdV[i];
  }
  return VolatilityOscResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// DPO — Detrended Price Oscillator (Pine: lines 2116-2129)
// ═══════════════════════════════════════════════════════════════════

class DPOResult {
  final List<bool> isLong, isShort;

  const DPOResult({required this.isLong, required this.isShort});
}

DPOResult calcDPO(List<double> close, {int period = 10, bool centered = false}) {
  final n = close.length;
  final ma = sma(close, period);
  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  final barsBack = period ~/ 2 + 1;
  for (int i = period - 1; i < n; i++) {
    final dpo = centered
        ? close[i - barsBack] - ma[i]
        : close[i] - ma[i - barsBack >= 0 ? i - barsBack : 0];
    isLong[i] = dpo > 0;
    isShort[i] = dpo < 0;
  }
  return DPOResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// HACOLT — Heiken-Ashi Candlestick Oscillator (Pine: lines 2131-2178)
// ═══════════════════════════════════════════════════════════════════

class HACOLTResult {
  final List<bool> isLong, isShort;

  const HACOLTResult({required this.isLong, required this.isShort});
}

HACOLTResult calcHACOLT(List<double> open, List<double> high,
    List<double> low, List<double> close,
    {int temaPeriod = 55, int emaPeriod = 60, double candleFactor = 1.1}) {
  final n = close.length;
  final haOpen = List<double>.filled(n, 0);
  final hl2 = List.generate(n, (i) => (high[i] + low[i]) / 2);
  haOpen[0] = (open[0] + close[0]) / 2;
  for (int i = 1; i < n; i++) {
    haOpen[i] = (haOpen[i - 1] + hl2[i - 1]) / 2;
  }
  final haClose = List.generate(n,
      (i) => (haOpen[i] + [high[i], haOpen[i]].reduce(math.max) + [low[i], haOpen[i]].reduce(math.min) + hl2[i]) / 4);
  final thaClose = tema(haClose, temaPeriod);
  final thl2 = tema(hl2, temaPeriod);
  final haCloseSmooth = List.generate(n, (i) => 2 * thaClose[i] - tema(thaClose, temaPeriod)[i]);
  final hl2Smooth = List.generate(n, (i) => 2 * thl2[i] - tema(thl2, temaPeriod)[i]);
  final emaClose = ema(close, emaPeriod);

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  var hacoltUp = false, hacoltDn = false;
  var hacoltUpWithOffset = false;

  for (int i = 1; i < n; i++) {
    final shortCandle = (close[i] - open[i]).abs() < ((high[i] - low[i]) * candleFactor);
    final keepN1 = ((haClose[i] >= haOpen[i]) && (haClose[i - 1] >= haOpen[i - 1])) ||
        (close[i] >= haClose[i]) || (high[i] > high[i - 1]) || (low[i] > low[i - 1]) ||
        (hl2Smooth[i] >= haCloseSmooth[i]);
    final keepAll1 = keepN1 || (i > 1 && keepN1 && ((close[i] >= open[i]) || (close[i] >= close[i - 1])));
    final keep13 = shortCandle && (high[i] >= low[i - 1]);
    final utr = keepAll1 || (i > 1 && keepAll1 && keep13);
    final keepN2 = (haClose[i] < haOpen[i]) && (haClose[i - 1] < haOpen[i - 1]) ||
        (hl2Smooth[i] < haCloseSmooth[i]);
    final keep23 = shortCandle && (low[i] <= high[i - 1]);
    final keepAll2 = keepN2 || (i > 1 && keepN2 && ((close[i] < open[i]) || (close[i] < close[i - 1])));
    final dtr = keepAll2 || (i > 1 && keepAll2 && keep23);
    final upw = dtr && (i > 1 && dtr) && utr;
    final dnw = utr && (i > 1 && utr) && dtr;
    if (upw != dnw) hacoltUpWithOffset = upw;
    final buySig = upw || (!dnw && hacoltUpWithOffset);
    final ltSellSig = close[i] < emaClose[i];
    isLong[i] = buySig;
    isShort[i] = !buySig && ltSellSig;
  }
  return HACOLTResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// AWESOME OSCILLATOR (Pine: lines 2280-2307)
// ═══════════════════════════════════════════════════════════════════

class AwesomeResult {
  final List<bool> isLong, isShort;

  const AwesomeResult({required this.isLong, required this.isShort});
}

AwesomeResult calcAwesome(List<double> high, List<double> low,
    {int fast = 5, int slow = 34, String type = 'Zero Line Cross'}) {
  final n = high.length;
  final hl2 = List.generate(n, (i) => (high[i] + low[i]) / 2);
  final smaF = sma(hl2, fast);
  final smaS = sma(hl2, slow);
  final ao = List.generate(n, (i) => smaF[i] - smaS[i]);
  final diff = change(ao);
  final nRes = List.generate(n, (i) => smaF[i] - smaS[i] - sma(sma(hl2, fast).map((v) => v - smaS[0]).toList(), fast)[i]);

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = 0; i < n; i++) {
    if (type == 'AC Zero Line Cross') {
      isLong[i] = i > 0 && nRes[i] > nRes[i - 1] && nRes[i] > 0;
      isShort[i] = i > 0 && nRes[i] < nRes[i - 1] && nRes[i] < 0;
    } else if (type == 'AC Momentum Bar') {
      isLong[i] = i > 0 && nRes[i] > nRes[i - 1];
      isShort[i] = i > 0 && nRes[i] < nRes[i - 1];
    } else {
      isLong[i] = ao[i] > 0;
      isShort[i] = ao[i] < 0;
    }
  }
  return AwesomeResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// WOLFPACK ID (Pine: lines 2317-2346)
// ═══════════════════════════════════════════════════════════════════

class WolfpackResult {
  final List<bool> isLong, isShort;

  const WolfpackResult({required this.isLong, required this.isShort});
}

WolfpackResult calcWolfpack(List<double> close,
    {int fastLen = 3, int slowLen = 8}) {
  final fastMA = ema(close, fastLen);
  final slowMA = ema(close, slowLen);
  final spread = List.generate(
      close.length, (i) => (fastMA[i] - slowMA[i]) * 1.001);
  return WolfpackResult(
    isLong: spread.map<bool>((v) => v > 0).toList(),
    isShort: spread.map<bool>((v) => v < 0).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════
// QQE MOD (Pine: lines 3784-3911)
// ═══════════════════════════════════════════════════════════════════

class QQEResult {
  final List<bool> isAbove, isBelow;

  const QQEResult({required this.isAbove, required this.isBelow});
}

QQEResult calcQQE(List<double> close,
    {int rsiPeriod = 6, int sf = 5, double qqe = 3, double threshold = 3,
    String qqeType = 'Line', double qqe2 = 1.61}) {
  final n = close.length;
  final wilders = rsiPeriod * 2 - 1;

  double calcRsi(List<double> src, int len) {
    double u = 0, d = 0;
    for (int i = 1; i <= len && i < src.length; i++) {
      final ch = src[i] - src[i - 1];
      if (ch > 0) u += ch; else d -= ch;
    }
    return d == 0 ? 100 : u == 0 ? 0 : 100 - 100 / (1 + u / d);
  }

  final rsi = List<double>.filled(n, 50);
  final rsiMa = List<double>.filled(n, 50);
  for (int i = rsiPeriod; i < n; i++) {
    // Simplified per-bar RSI
    final chunk = close.sublist(0, i + 1);
    double u = 0, d = 0;
    for (int j = 1; j <= rsiPeriod && j <= i; j++) {
      final ch = chunk[j] - chunk[j - 1];
      if (ch > 0) u += ch; else d -= ch;
    }
    rsi[i] = d == 0 ? 100 : u == 0 ? 0 : 100 - 100 / (1 + u / d);
    rsiMa[i] = ema(rsi, sf)[i];
  }

  final rsi2 = List<double>.filled(n, 50);
  final rsiMa2 = List<double>.filled(n, 50);
  for (int i = rsiPeriod; i < n; i++) {
    final chunk = close.sublist(0, i + 1);
    double u = 0, d = 0;
    for (int j = 1; j <= rsiPeriod && j <= i; j++) {
      final ch = chunk[j] - chunk[j - 1];
      if (ch > 0) u += ch; else d -= ch;
    }
    rsi2[i] = d == 0 ? 100 : u == 0 ? 0 : 100 - 100 / (1 + u / d);
    rsiMa2[i] = ema(rsi2, sf)[i];
  }

  // QQE line = FastAtrRsi2TL - 50
  final qqeLine = rsiMa2.map((v) => v - 50).toList();
  final greenBar1 = List.generate(n, (i) => rsiMa2[i] - 50 > threshold);
  final redBar1 = List.generate(n, (i) => rsiMa2[i] - 50 < -threshold);

  final isAbove = List<bool>.filled(n, false);
  final isBelow = List<bool>.filled(n, false);

  for (int i = 0; i < n; i++) {
    if (qqeType == 'Line') {
      isAbove[i] = qqeLine[i] > 0;
      isBelow[i] = qqeLine[i] < 0;
    } else if (qqeType == 'Bar') {
      isAbove[i] = rsiMa2[i] - 50 > 0 && greenBar1[i];
      isBelow[i] = rsiMa2[i] - 50 < 0 && redBar1[i];
    } else {
      isAbove[i] = rsiMa2[i] - 50 > 0 && greenBar1[i] && qqeLine[i] > 0;
      isBelow[i] = rsiMa2[i] - 50 < 0 && redBar1[i] && qqeLine[i] < 0;
    }
  }
  return QQEResult(isAbove: isAbove, isBelow: isBelow);
}

// ═══════════════════════════════════════════════════════════════════
// HULL SUITE (Pine: lines 2846-2883)
// ═══════════════════════════════════════════════════════════════════

class HullResult {
  final List<double> hull;
  final List<bool> isUp, isDown;

  const HullResult(
      {required this.hull, required this.isUp, required this.isDown});
}

HullResult calcHull(List<double> close,
    {int length = 55, String mode = 'Hma', double lengthMult = 1.0}) {
  final len = (length * lengthMult).round();
  List<double> hullFunc(List<double> src, int len, String m) {
    if (m == 'Hma') return hma(src, len);
    if (m == 'Ehma') {
      final half = ema(src, len ~/ 2);
      final full = ema(src, len);
      final diff = List.generate(src.length,
          (i) => i < half.length && i < full.length ? 2 * half[i] - full[i] : double.nan);
      return ema(diff, (math.sqrt(len)).round());
    }
    // THMA
    final t3 = wma(src, len ~/ 3);
    final t2 = wma(src, len ~/ 2);
    final t1 = wma(src, len);
    return List.generate(src.length,
        (i) => i < t3.length && i < t2.length && i < t1.length ? 3 * t3[i] - t2[i] - t1[i] : double.nan);
  }

  final hull = hullFunc(close, len, mode);
  final isUp = List<bool>.filled(close.length, false);
  final isDown = List<bool>.filled(close.length, false);
  for (int i = 2; i < close.length; i++) {
    isUp[i] = hull[i] > hull[i - 2];
    isDown[i] = hull[i] < hull[i - 2];
  }
  return HullResult(hull: hull, isUp: isUp, isDown: isDown);
}

// ═══════════════════════════════════════════════════════════════════
// VORTEX INDEX (Pine: lines 1913-1937)
// ═══════════════════════════════════════════════════════════════════

class VortexResult {
  final List<bool> vipCondition, vimCondition;

  const VortexResult({required this.vipCondition, required this.vimCondition});
}

VortexResult calcVortex(List<double> high, List<double> low, List<double> close,
    {int period = 14, double upper = 1.1, double lower = 0.9,
    String type = 'Simple'}) {
  final n = high.length;
  final vmp = List<double>.filled(n, 0);
  final vmm = List<double>.filled(n, 0);
  final str = List<double>.filled(n, 0);
  for (int i = period - 1; i < n; i++) {
    double sVmp = 0, sVmm = 0, sStr = 0;
    for (int j = 0; j < period; j++) {
      sVmp += (high[i - j] - low[i - j - 1 >= 0 ? i - j - 1 : 0]).abs();
      sVmm += (low[i - j] - high[i - j - 1 >= 0 ? i - j - 1 : 0]).abs();
      sStr += trueRange(high, low, close)[i - j];
    }
    vmp[i] = sVmp;
    vmm[i] = sVmm;
    str[i] = sStr;
  }
  final vip = List.generate(n, (i) => str[i] != 0 ? vmp[i] / str[i] : 0);
  final vim = List.generate(n, (i) => str[i] != 0 ? vmm[i] / str[i] : 0);
  final vipCond = List<bool>.filled(n, false);
  final vimCond = List<bool>.filled(n, false);

  for (int i = 0; i < n; i++) {
    if (type == 'Simple') {
      vipCond[i] = vip[i] > vim[i];
      vimCond[i] = vip[i] < vim[i];
    } else {
      vipCond[i] = vip[i] > vim[i] && vip[i] > upper && vip[i] > vip[i > 0 ? i - 1 : 0] &&
          vim[i] < vim[i > 0 ? i - 1 : 0] && vim[i > 0 ? i - 1 : 0] <= lower &&
          vip[i > 0 ? i - 1 : 0] >= upper;
      final vipPrev = i > 0 ? vip[i - 1] : 0;
      final vimPrev = i > 0 ? vim[i - 1] : 0;
      vimCond[i] = vip[i] < vim[i] && vim[i] > upper && vim[i] > vimPrev &&
          vip[i] < vipPrev && vipPrev <= lower && vipPrev >= upper;
    }
  }
  return VortexResult(vipCondition: vipCond, vimCondition: vimCond);
}

// ═══════════════════════════════════════════════════════════════════
// BB OSCILLATOR (Pine: lines 2386-2422)
// ═══════════════════════════════════════════════════════════════════

class BBOSCResult {
  final List<bool> isLong, isShort;

  const BBOSCResult({required this.isLong, required this.isShort});
}

BBOSCResult calcBBOsc(List<double> close, List<double> open,
    {int length = 20, double mult = 2.0, int trigLen = 4,
    String type = 'Entering Lower/Upper Band'}) {
  final n = close.length;
  final basis = sma(close, length);
  final dev = stdev(close, length).map<double>((v) => v * mult).toList();
  final upper = List<double>.generate(n, (i) => basis[i] + dev[i]);
  final lower = List<double>.generate(n, (i) => basis[i] - dev[i]);

  final uPercent = List<double>.generate(n, (i) => upper[i] != 0 ? (upper[i] - close[i]) / (upper[i] + close[i] / 2) : 0);
  final lPercent = List<double>.generate(n, (i) => lower[i] != 0 ? (lower[i] - close[i]) / (lower[i] + close[i] / 2) : 0);
  final bPercent = List<double>.generate(n, (i) => basis[i] != 0 ? (basis[i] - close[i]) / (basis[i] + close[i] / 2) : 0);
  final uSmooth = wma(uPercent, 6);
  final lSmooth = wma(lPercent, 6);
  final bSmooth = wma(bPercent, 6);
  final d1 = sma(bSmooth, 2);
  final j = List.generate(n, (i) => -(bSmooth[i] + d1[i]));
  final d2 = sma(j, trigLen);

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = 0; i < n; i++) {
    if (type == 'Entering Lower/Upper Band') {
      isLong[i] = j[i] > d2[i] && j[i] >= lSmooth[i];
      isShort[i] = j[i] < d2[i] && j[i] <= uSmooth[i];
    } else {
      isLong[i] = j[i] > d2[i] && j[i] > uSmooth[i];
      isShort[i] = j[i] < d2[i] && j[i] < lSmooth[i];
    }
  }
  return BBOSCResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// RANGE DETECTOR (Pine: lines 1990-2074)
// ═══════════════════════════════════════════════════════════════════

class RangeDetectorResult {
  final List<bool> isLong, isShort;
  final List<bool> signal;

  const RangeDetectorResult(
      {required this.isLong, required this.isShort, required this.signal});
}

RangeDetectorResult calcRangeDetector(List<double> high, List<double> low,
    List<double> close, {int length = 20, double mult = 1.0, int atrLen = 500}) {
  final n = close.length;
  final atrV = atr(high, low, close, atrLen).map((v) => v * mult).toList();
  final ma = sma(close, length);
  final rdMax = List<double>.filled(n, 0);
  final rdMin = List<double>.filled(n, 0);

  for (int i = length - 1; i < n; i++) {
    rdMax[i] = ma[i] + atrV[i];
    rdMin[i] = ma[i] - atrV[i];
  }

  return RangeDetectorResult(
    isLong: List.generate(n, (i) => close[i] > rdMax[i]),
    isShort: List.generate(n, (i) => close[i] < rdMin[i]),
    signal: List.generate(n, (i) => close[i] > rdMax[i] || close[i] < rdMin[i]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// TRENDLINE BREAKOUT (Pine: lines 1337-1391)
// ═══════════════════════════════════════════════════════════════════

class TrendlineBOResult {
  final List<bool> buySignal, sellSignal;

  const TrendlineBOResult({required this.buySignal, required this.sellSignal});
}

TrendlineBOResult calcTrendlineBO(List<double> high, List<double> low,
    List<double> close, {int length = 14, double mult = 1.0,
    String calcMethod = 'Atr'}) {
  final n = close.length;
  final atrV = atr(high, low, close, length);
  final slope = List<double>.filled(n, atrV[0] / length * mult);
  for (int i = 1; i < n; i++) {
    slope[i] = atrV[i] / length * mult;
  }
  final upper = List<double>.filled(n, 0.0);
  final lower = List<double>.filled(n, 0.0);
  final upos = List<int>.filled(n, 0);
  final dnos = List<int>.filled(n, 0);

  for (int i = length; i < n; i++) {
    if (i == length || (i > 0 && high[i] > high[i - 1] && close[i] > close[i - 1])) {
      upper[i] = high[i];
    } else {
      upper[i] = upper[i - 1] - slope[i];
    }
    if (i == length || (i > 0 && low[i] < low[i - 1] && close[i] < close[i - 1])) {
      lower[i] = low[i];
    } else {
      lower[i] = lower[i - 1] + slope[i];
    }
    upos[i] = (i > 0 && close[i] > upper[i] - slope[i] * length) ? 1 : 0;
    dnos[i] = (i > 0 && close[i] < lower[i] + slope[i] * length) ? 1 : 0;
  }

  final buy = List<bool>.filled(n, false);
  final sell = List<bool>.filled(n, false);
  for (int i = 1; i < n; i++) {
    buy[i] = i > 1 && upos[i] > upos[i - 1];
    sell[i] = i > 1 && dnos[i] > dnos[i - 1];
  }
  return TrendlineBOResult(buySignal: buy, sellSignal: sell);
}

// ═══════════════════════════════════════════════════════════════════
// CHAIKIN MONEY FLOW (Pine: lines 1900-1909)
// ═══════════════════════════════════════════════════════════════════

class ChaikinResult {
  final List<bool> isLong, isShort;

  const ChaikinResult({required this.isLong, required this.isShort});
}

ChaikinResult calcChaikin(List<double> high, List<double> low,
    List<double> close, List<int> volume, {int length = 20}) {
  final n = close.length;
  final mf = List<double>.filled(n, 0);
  for (int i = length - 1; i < n; i++) {
    double ad = 0, vSum = 0;
    for (int j = 0; j < length; j++) {
      final h = high[i - j], l = low[i - j], c = close[i - j];
      final v = volume[i - j].toDouble();
      ad += (c == h && c == l) || h == l
          ? 0
          : (2 * c - l - h) / (h - l) * v;
      vSum += v;
    }
    mf[i] = vSum != 0 ? ad / vSum : 0;
  }
  return ChaikinResult(
    isLong: mf.map((v) => v > 0).toList(),
    isShort: mf.map((v) => v < 0).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════
// VOLUME (Pine: lines 3917-3969)
// ═══════════════════════════════════════════════════════════════════

class VolumeResult {
  final List<bool> isLong, isShort;

  const VolumeResult({required this.isLong, required this.isShort});
}

VolumeResult calcVolume(List<double> open, List<double> close,
    List<int> volume, {String type = 'volume above MA', int smaLen = 20}) {
  final volDouble = volume.map((v) => v.toDouble()).toList();
  final volMA = sma(volDouble, smaLen);
  final n = close.length;

  final upVol = List<double>.filled(n, 0);
  final downVol = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    if (close[i] > open[i]) upVol[i] = volDouble[i];
    else if (close[i] < open[i]) downVol[i] = -volDouble[i];
    else if (i > 0 && close[i] >= close[i - 1]) upVol[i] = volDouble[i];
    else downVol[i] = -volDouble[i];
  }

  final delta = List.generate(n, (i) => upVol[i] + downVol[i]);

  final isLong = List<bool>.filled(n, false);
  final isShort = List<bool>.filled(n, false);
  for (int i = 1; i < n; i++) {
    if (type == 'Delta') {
      isLong[i] = delta[i] > 0 && delta[i] > delta[i - 1];
      isShort[i] = delta[i] < 0 && delta[i] < delta[i - 1];
    } else if (type == 'volume above MA') {
      isLong[i] = volDouble[i] > volMA[i];
      isShort[i] = volDouble[i] > volMA[i];
    } else {
      isLong[i] = upVol[i] > upVol[i - 1];
      isShort[i] = downVol[i] < downVol[i - 1];
    }
  }
  return VolumeResult(isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// MCGINLEY DYNAMIC (Pine: lines 1638-1650)
// ═══════════════════════════════════════════════════════════════════

class McGinleyResult {
  final List<double> mg;
  final List<bool> isLong, isShort;

  const McGinleyResult(
      {required this.mg, required this.isLong, required this.isShort});
}

McGinleyResult calcMcGinley(List<double> close, {int length = 14}) {
  final mg = List<double>.filled(close.length, 0);
  mg[0] = close[0];
  for (int i = 1; i < close.length; i++) {
    mg[i] = mg[i - 1] + (close[i] - mg[i - 1]) /
        (length * math.pow(close[i] / mg[i - 1], 4));
  }
  return McGinleyResult(
    mg: mg,
    isLong: List.generate(close.length, (i) => close[i] > mg[i]),
    isShort: List.generate(close.length, (i) => close[i] < mg[i]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// EMA CROSS (Pine: lines 657-704)
// ═══════════════════════════════════════════════════════════════════

class EMACrossResult {
  final List<double> fast, slow;
  final List<bool> isLong, isShort;

  const EMACrossResult({
    required this.fast, required this.slow,
    required this.isLong, required this.isShort,
  });
}

EMACrossResult calc2EMACross(List<double> close,
    {int fastLen = 50, int slowLen = 200, String signalType = 'Default',
    int lookback = 3}) {
  final fastMA = ema(close, fastLen);
  final slowMA = ema(close, slowLen);
  final isLong = List<bool>.filled(close.length, false);
  final isShort = List<bool>.filled(close.length, false);

  for (int i = 1; i < close.length; i++) {
    if (signalType == 'Default') {
      isLong[i] = fastMA[i - 1] <= slowMA[i - 1] && fastMA[i] > slowMA[i];
      isShort[i] = fastMA[i - 1] >= slowMA[i - 1] && fastMA[i] < slowMA[i];
    } else {
      // Lookback method: crosses within lookback period
      bool foundCross = false;
      for (int j = 0; j <= lookback && i - j >= 1; j++) {
        if (fastMA[i - j] > slowMA[i - j] && fastMA[i - j - 1] <= slowMA[i - j - 1]) {
          foundCross = true;
          break;
        }
      }
      isLong[i] = foundCross && fastMA[i] > slowMA[i];
      foundCross = false;
      for (int j = 0; j <= lookback && i - j >= 1; j++) {
        if (fastMA[i - j] < slowMA[i - j] && fastMA[i - j - 1] >= slowMA[i - j - 1]) {
          foundCross = true;
          break;
        }
      }
      isShort[i] = foundCross && fastMA[i] < slowMA[i];
    }
  }
  return EMACrossResult(fast: fastMA, slow: slowMA, isLong: isLong, isShort: isShort);
}

EMACrossResult calc3EMACross(List<double> close,
    {int fast = 9, int mid = 21, int slow = 55}) {
  final e1 = ema(close, fast);
  final e2 = ema(close, mid);
  final e3 = ema(close, slow);
  final isLong = List.generate(close.length,
      (i) => e1[i] > e2[i] && e1[i] > e3[i] && e2[i] > e3[i]);
  final isShort = List.generate(close.length,
      (i) => e1[i] < e2[i] && e1[i] < e3[i] && e2[i] < e3[i]);
  return EMACrossResult(fast: e1, slow: e2, isLong: isLong, isShort: isShort);
}

// ═══════════════════════════════════════════════════════════════════
// EMA FILTER (Pine: lines 3979-3981)
// ═══════════════════════════════════════════════════════════════════

class EMAFilterResult {
  final List<double> emaVal;
  final List<bool> isAbove, isBelow;

  const EMAFilterResult({
    required this.emaVal,
    required this.isAbove,
    required this.isBelow,
  });
}

EMAFilterResult calcEMAFilter(List<double> close, {int period = 200}) {
  final emaVal = ema(close, period);
  return EMAFilterResult(
    emaVal: emaVal,
    isAbove: List.generate(close.length, (i) => close[i] > emaVal[i]),
    isBelow: List.generate(close.length, (i) => close[i] < emaVal[i]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// STC — Schaff Trend Cycle (Pine: lines 2889-2919)
// ═══════════════════════════════════════════════════════════════════

class STCResult {
  final List<double> stc;
  final List<bool> isUp, isDown;

  const STCResult(
      {required this.stc, required this.isUp, required this.isDown});
}

STCResult calcSTC(List<double> close,
    {int fast = 23, int slow = 50, int cycle = 10, int d1 = 3, int d2 = 3,
    int upper = 75, int lower = 25}) {
  final n = close.length;
  final fastMA = ema(close, fast);
  final slowMA = ema(close, slow);
  final macd = List.generate(n, (i) => fastMA[i] - slowMA[i]);
  final k = List<double>.filled(n, 50);
  final d = List<double>.filled(n, 50);
  final stc = List<double>.filled(n, 50);

  for (int i = cycle; i < n; i++) {
    final hh = macd.sublist(0, i + 1).reduce(math.max);
    final ll = macd.sublist(0, i + 1).reduce(math.min);
    k[i] = hh != ll ? 100 * (macd[i] - ll) / (hh - ll) : 50;
  }
  for (int i = 0; i < n; i++) d[i] = ema(k, d1)[i];
  for (int i = cycle; i < n; i++) {
    final hh = d.sublist(0, i + 1).reduce(math.max);
    final ll = d.sublist(0, i + 1).reduce(math.min);
    final kd = hh != ll ? 100 * (d[i] - ll) / (hh - ll) : 50.0;
    stc[i] = ema(List<double>.generate(n, (j) => kd), d2)[i].clamp(0.0, 100.0) as double;
  }

  return STCResult(
    stc: stc,
    isUp: stc.map((v) => v >= upper).toList(),
    isDown: stc.map((v) => v <= lower).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════
// DAMIANI VOLATILITY (Pine: lines 2217-2244)
// ═══════════════════════════════════════════════════════════════════

class DVResult {
  final List<bool> isUp;

  const DVResult({required this.isUp});
}

DVResult calcDV(List<double> high, List<double> low, List<double> close,
    {int visAtr = 13, int visStd = 20, int sedAtr = 40, int sedStd = 100,
    double threshold = 1.4, bool lagSup = true,
    String type = 'Simple'}) {
  final n = close.length;
  final atrVis = atr(high, low, close, visAtr);
  final atrSed = atr(high, low, close, sedAtr);
  final stdVis = stdev(close, visStd);
  final stdSed = stdev(close, sedStd);
  final isUp = List<bool>.filled(n, false);

  for (int i = 0; i < n; i++) {
    final vol = atrSed[i] != 0
        ? atrVis[i] / atrSed[i] + (lagSup ? 0.5 * (i > 0 ? atrVis[i - 1] - atrSed[i - 1] : 0) : 0)
        : 0;
    final antiThres = stdSed[i] != 0 ? stdVis[i] / stdSed[i] : 0;
    final t = threshold - antiThres;

    if (type == 'Threshold') {
      isUp[i] = vol > t && vol >= 1.1;
    } else if (type == '10p Difference') {
      isUp[i] = vol > t && (vol - t >= 0.1);
    } else {
      isUp[i] = vol > t;
    }
  }
  return DVResult(isUp: isUp);
}

// ═══════════════════════════════════════════════════════════════════
// CHOPPINESS INDEX (Pine: lines 2205-2210)
// ═══════════════════════════════════════════════════════════════════

class CIResult {
  final List<double> index;
  final List<bool> isTrending;

  const CIResult({required this.index, required this.isTrending});
}

CIResult calcCI(List<double> high, List<double> low, List<double> close,
    {int length = 14, double limit = 61.8}) {
  final n = close.length;
  final tr = trueRange(high, low, close);
  final hh = highest(high, length);
  final ll = lowest(low, length);
  final idx = List<double>.filled(n, 50);
  final isTrending = List<bool>.filled(n, false);

  for (int i = length - 1; i < n; i++) {
    double sumTr = 0;
    for (int j = 0; j < length; j++) sumTr += tr[i - j];
    idx[i] = hh[i] != ll[i] && (hh[i] - ll[i]) > 0
        ? 100 * log10(sumTr / (hh[i] - ll[i])) / log10(length.toDouble())
        : 50;
    isTrending[i] = idx[i] < limit;
  }
  return CIResult(index: idx, isTrending: isTrending);
}
