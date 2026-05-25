import 'dart:math' as math;

/// Pine Script: ta.ema(source, length)
List<double> ema(List<double> src, int len) {
  final k = 2.0 / (len + 1);
  final r = List<double>.filled(src.length, double.nan);
  int s = 0;
  while (s < src.length && src[s].isNaN) {
    s++;
  }
  if (s >= src.length) return r;
  r[s] = src[s];
  for (int i = s + 1; i < src.length; i++) {
    r[i] = src[i] * k + r[i - 1] * (1 - k);
  }
  return r;
}

/// Pine Script: ta.sma(source, length)
List<double> sma(List<double> src, int len) {
  final r = List<double>.filled(src.length, double.nan);
  for (int i = len - 1; i < src.length; i++) {
    double s = 0;
    for (int j = 0; j < len; j++) s += src[i - j];
    r[i] = s / len;
  }
  return r;
}

/// Pine Script: ta.rma(source, length)
List<double> rma(List<double> src, int len) {
  final a = 1.0 / len;
  final r = List<double>.filled(src.length, double.nan);
  if (src.length < len) return r;
  double s = 0;
  for (int i = 0; i < len; i++) s += src[i];
  r[len - 1] = s / len;
  for (int i = len; i < src.length; i++) {
    r[i] = a * src[i] + (1 - a) * r[i - 1];
  }
  return r;
}

/// Pine Script: ta.wma(source, length)
List<double> wma(List<double> src, int len) {
  final r = List<double>.filled(src.length, double.nan);
  final wSum = len * (len + 1) / 2;
  for (int i = len - 1; i < src.length; i++) {
    double s = 0;
    for (int j = 0; j < len; j++) s += src[i - j] * (len - j);
    r[i] = s / wSum;
  }
  return r;
}

/// Pine Script: ta.vwma(source, length) — uses volume as weight
List<double> vwma(List<double> src, List<double> vol, int len) {
  final r = List<double>.filled(src.length, double.nan);
  for (int i = len - 1; i < src.length; i++) {
    double pv = 0, v = 0;
    for (int j = 0; j < len; j++) {
      pv += src[i - j] * vol[i - j];
      v += vol[i - j];
    }
    if (v != 0) r[i] = pv / v;
  }
  return r;
}

/// Pine Script: ta.hma(source, length)
List<double> hma(List<double> src, int len) {
  final sqrtLen = math.max(2, (math.sqrt(len)).round());
  final half = wma(src, len ~/ 2);
  final full = wma(src, len);
  final diff = List<double>.generate(src.length,
      (i) => i < half.length && i < full.length ? 2 * half[i] - full[i] : double.nan);
  return wma(diff, sqrtLen);
}

/// Pine Script: tema(src, len) — triple exponential moving average
List<double> tema(List<double> src, int len) {
  final e1 = ema(src, len);
  final e2 = ema(e1, len);
  final e3 = ema(e2, len);
  return List<double>.generate(src.length,
      (i) => i < e1.length && i < e2.length && i < e3.length && !e1[i].isNaN && !e2[i].isNaN && !e3[i].isNaN
          ? 3 * e1[i] - 3 * e2[i] + e3[i]
          : double.nan);
}

/// Pine Script: ta.swma(source)
/// Simple weighted moving average: (prev + src*2) / 3 approximation
List<double> swma(List<double> src) {
  final r = List<double>.filled(src.length, double.nan);
  if (src.isNotEmpty) r[0] = src[0];
  for (int i = 1; i < src.length; i++) {
    r[i] = (r[i - 1] + src[i] * 2) / 3;
  }
  return r;
}

/// Generic MA function matching Pine Script ma() and ma_function()
List<double> movingAverage(List<double> src, int len, String type,
    {List<double>? volume}) {
  switch (type) {
    case 'SMA':
      return sma(src, len);
    case 'EMA':
      return ema(src, len);
    case 'RMA':
    case 'SMMA (RMA)':
      return rma(src, len);
    case 'WMA':
      return wma(src, len);
    case 'VWMA':
      return vwma(src, volume ?? src, len);
    case 'HMA':
      return hma(src, len);
    case 'TEMA':
      return tema(src, len);
    case 'SWMA':
      return swma(src);
    default:
      return sma(src, len);
  }
}

/// Pine Script: ta.tr(true) — true range
List<double> trueRange(List<double> h, List<double> l, List<double> c) {
  final n = h.length;
  final tr = List<double>.filled(n, 0.0);
  tr[0] = h[0] - l[0];
  for (int i = 1; i < n; i++) {
    tr[i] = [h[i] - l[i], (h[i] - c[i - 1]).abs(), (l[i] - c[i - 1]).abs()]
        .reduce(math.max);
  }
  return tr;
}

/// Pine Script: ta.atr(length)
List<double> atr(List<double> h, List<double> l, List<double> c, int len) {
  return rma(trueRange(h, l, c), len);
}

/// Pine Script: ta.stdev(source, length)
List<double> stdev(List<double> src, int len) {
  final r = List<double>.filled(src.length, double.nan);
  for (int i = len - 1; i < src.length; i++) {
    double m = 0;
    for (int j = 0; j < len; j++) m += src[i - j];
    m /= len;
    double v = 0;
    for (int j = 0; j < len; j++) v += (src[i - j] - m) * (src[i - j] - m);
    r[i] = math.sqrt(v / len);
  }
  return r;
}

/// Pine Script: ta.highest(source, length)
List<double> highest(List<double> src, int len) {
  final r = List<double>.filled(src.length, double.nan);
  for (int i = 0; i < src.length; i++) {
    final s = math.max(0, i - len + 1);
    double h = src[s];
    for (int j = s; j <= i; j++) if (src[j] > h) h = src[j];
    r[i] = h;
  }
  return r;
}

/// Pine Script: ta.lowest(source, length)
List<double> lowest(List<double> src, int len) {
  final r = List<double>.filled(src.length, double.nan);
  for (int i = 0; i < src.length; i++) {
    final s = math.max(0, i - len + 1);
    double l = src[s];
    for (int j = s; j <= i; j++) if (src[j] < l) l = src[j];
    r[i] = l;
  }
  return r;
}

/// Pine Script: math.log10(x)
double log10(double x) => math.log(x) / math.ln10;

/// Highest bars index lookup (Pine: ta.highestbars)
int highestBars(List<double> src, int len, int i) {
  final s = math.max(0, i - len + 1);
  int bi = s;
  double hv = src[s];
  for (int j = s; j <= i; j++) {
    if (src[j] > hv) {
      hv = src[j];
      bi = j;
    }
  }
  return i - bi;
}

/// Lowest bars index lookup (Pine: ta.lowestbars)
int lowestBars(List<double> src, int len, int i) {
  final s = math.max(0, i - len + 1);
  int bi = s;
  double lv = src[s];
  for (int j = s; j <= i; j++) {
    if (src[j] < lv) {
      lv = src[j];
      bi = j;
    }
  }
  return i - bi;
}

/// Pine Script: ta.correlation(x, y, length)
List<double> correlation(List<double> x, List<double> y, int len) {
  final r = List<double>.filled(x.length, double.nan);
  for (int i = len - 1; i < x.length; i++) {
    double sx = 0, sy = 0, sxy = 0, sx2 = 0, sy2 = 0;
    for (int j = 0; j < len; j++) {
      final xv = x[i - j], yv = y[i - j];
      sx += xv;
      sy += yv;
      sxy += xv * yv;
      sx2 += xv * xv;
      sy2 += yv * yv;
    }
    final n = len.toDouble();
    final num = n * sxy - sx * sy;
    final d1 = n * sx2 - sx * sx;
    final d2 = n * sy2 - sy * sy;
    r[i] = (d1 > 0 && d2 > 0) ? num / (math.sqrt(d1) * math.sqrt(d2)) : 0;
  }
  return r;
}

/// Pine Script: ta.variance(source, length)
List<double> variance(List<double> src, int len) {
  final r = List<double>.filled(src.length, double.nan);
  for (int i = len - 1; i < src.length; i++) {
    double m = 0;
    for (int j = 0; j < len; j++) m += src[i - j];
    m /= len;
    double v = 0;
    for (int j = 0; j < len; j++) v += (src[i - j] - m) * (src[i - j] - m);
    r[i] = v / len;
  }
  return r;
}

/// Pine Script: ta.change(x) = x - x[1]
List<double> change(List<double> src) {
  final r = List<double>.filled(src.length, 0.0);
  for (int i = 1; i < src.length; i++) r[i] = src[i] - src[i - 1];
  return r;
}

/// Pine Script: fixnan(x) — replace NaN with previous non-NaN
List<double> fixnan(List<double> src) {
  final r = List<double>.filled(src.length, double.nan);
  double last = double.nan;
  for (int i = 0; i < src.length; i++) {
    if (!src[i].isNaN) last = src[i];
    r[i] = last;
  }
  return r;
}
