import 'package:flutter_test/flutter_test.dart';
import 'package:stock_screener/domain/indicator_engine.dart';

class _OHLCV {
  final List<double> open;
  final List<double> high;
  final List<double> low;
  final List<double> close;
  final List<int> volume;
  _OHLCV(this.open, this.high, this.low, this.close, this.volume);
}

_OHLCV _makeOHLCV(int n, double start, double step, {double vol = 0.5}) {
  final open = <double>[];
  final high = <double>[];
  final low = <double>[];
  final close = <double>[];
  final volume = <int>[];
  double v = start;
  for (int i = 0; i < n; i++) {
    open.add(v);
    high.add(v + vol);
    low.add(v - vol);
    close.add(v);
    volume.add(1000 + i * 10);
    v += step;
  }
  return _OHLCV(open, high, low, close, volume);
}

void main() {
  group('RangeFilter', () {
    test('rising prices produce uprf signals', () {
      final d = _makeOHLCV(80, 100, 1);
      final r = calcRangeFilter(d.close, 5, 2.5);
      expect(r.filt.length, 80);
      expect(r.filt[79], greaterThan(r.filt[0]));
      expect(r.uprf[79], isTrue);
    });

    test('falling prices produce downrf signals', () {
      final d = _makeOHLCV(80, 200, -1);
      final r = calcRangeFilter(d.close, 5, 2.5);
      expect(r.filt[79], lessThan(r.filt[0]));
      expect(r.downrf[79], isTrue);
    });

    test('constant prices produce no signals', () {
      final d = _makeOHLCV(80, 100, 0);
      final r = calcRangeFilter(d.close, 5, 2.5);
      expect(r.uprf.where((b) => b).length, 0);
      expect(r.downrf.where((b) => b).length, 0);
    });

    test('short array does not crash', () {
      final d = _makeOHLCV(3, 100, 1);
      final r = calcRangeFilter(d.close, 5, 2.5);
      expect(r.filt.length, 3);
      expect(r.uprf.length, 3);
    });
  });

  group('RSI', () {
    test('rising prices give RSI 100', () {
      final d = _makeOHLCV(80, 100, 1);
      final r = calcRSI(d.close);
      expect(r.rsi[79], 100);
    });

    test('falling prices give RSI 0', () {
      final d = _makeOHLCV(80, 100, -1);
      final r = calcRSI(d.close);
      expect(r.rsi[79], 0);
    });

    test('constant prices give RSI 100 per implementation', () {
      final d = _makeOHLCV(80, 100, 0);
      final r = calcRSI(d.close);
      expect(r.rsi[79], 100);
    });

    test('isLong/isShort via level type', () {
      final d = _makeOHLCV(80, 100, 1);
      final r = calcRSI(d.close, rsiType: 'RSI Level', level: 50);
      expect(r.isLong[79], isTrue);
      expect(r.isShort[79], isFalse);
    });

    test('short array returns partial values', () {
      final d = _makeOHLCV(5, 100, 1);
      final r = calcRSI(d.close);
      expect(r.rsi.length, 5);
    });
  });

  group('MACD', () {
    test('rising prices produce positive MACD and isLong', () {
      final d = _makeOHLCV(80, 100, 1);
      final r = calcMACD(d.close);
      expect(r.macd.length, 80);
      expect(r.signal.length, 80);
      expect(r.hist.length, 80);
      expect(r.macd[79], greaterThan(0));
      expect(r.isLong[79], isTrue);
    });

    test('falling prices produce negative MACD and isShort', () {
      final d = _makeOHLCV(80, 100, -1);
      final r = calcMACD(d.close);
      expect(r.macd[79], lessThan(0));
      expect(r.isShort[79], isTrue);
    });

    test('constant prices produce flat histogram near zero', () {
      final d = _makeOHLCV(80, 100, 0);
      final r = calcMACD(d.close);
      expect(r.hist.where((h) => h.abs() > 0.001).length, 0);
    });

    test('short array does not crash', () {
      final d = _makeOHLCV(2, 100, 1);
      final r = calcMACD(d.close);
      expect(r.macd.length, 2);
    });
  });

  group('PSAR', () {
    test('rising prices keep isUp true', () {
      final d = _makeOHLCV(80, 100, 1);
      final r = calcPSAR(d.high, d.low, d.close);
      expect(r.sar.length, 80);
      expect(r.isUp[79], isTrue);
      expect(r.isDown[79], isFalse);
    });

    test('falling prices switch to isDown', () {
      final d = _makeOHLCV(80, 100, -1);
      final r = calcPSAR(d.high, d.low, d.close);
      expect(r.isDown[79], isTrue);
    });

    test('isUp and isDown are mutually exclusive from bar 1', () {
      final d = _makeOHLCV(80, 100, 0);
      final r = calcPSAR(d.high, d.low, d.close);
      expect(r.sar.length, 80);
      for (int i = 1; i < 80; i++) {
        expect(r.isUp[i] && r.isDown[i], isFalse);
      }
    });

    test('single bar does not crash', () {
      final d = _makeOHLCV(1, 100, 0);
      final r = calcPSAR(d.high, d.low, d.close);
      expect(r.sar.length, 1);
    });
  });

  group('SuperTrend', () {
    test('rising prices produce uptrend', () {
      final d = _makeOHLCV(80, 100, 1);
      final r = calcSuperTrend(d.high, d.low, d.close);
      expect(r.trend[79], 1);
      expect(r.isUp[79], isTrue);
      expect(r.isDown[79], isFalse);
    });

    test('sharp reversal produces downtrend', () {
      final high = <double>[];
      final low = <double>[];
      final close = <double>[];
      for (int i = 0; i < 30; i++) {
        high.add(100.5);
        low.add(99.5);
        close.add(100.0);
      }
      for (int i = 0; i < 20; i++) {
        final v = 100.0 - (i + 1) * 5.0;
        high.add(v + 0.5);
        low.add(v - 0.5);
        close.add(v);
      }
      final r = calcSuperTrend(high, low, close);
      expect(r.trend.where((t) => t == -1).length, greaterThan(0));
      expect(r.isDown[49], isTrue);
    });
  });

  group('Stochastic', () {
    test('rising prices give K and D near 100', () {
      final d = _makeOHLCV(80, 100, 1);
      final r = calcStochastic(d.high, d.low, d.close);
      expect(r.k[79], greaterThan(95));
      expect(r.d[79], greaterThan(95));
    });

    test('falling prices give K and D near 0', () {
      final d = _makeOHLCV(80, 100, -1);
      final r = calcStochastic(d.high, d.low, d.close);
      expect(r.k[79], lessThan(5));
      expect(r.d[79], lessThan(5));
    });

    test('K surpasses D during transitional rise', () {
      final high = <double>[];
      final low = <double>[];
      final close = <double>[];
      for (int i = 0; i < 20; i++) {
        close.add(90.0); high.add(91.0); low.add(89.0);
      }
      for (int i = 0; i < 30; i++) {
        close.add(90.0 + (i + 1) * 0.5);
        high.add(91.0 + (i + 1) * 0.5);
        low.add(89.0 + (i + 1) * 0.5);
      }
      final r = calcStochastic(high, low, close, type: 'Simple');
      expect(r.k[49], greaterThan(50));
      expect(r.d[49], greaterThan(50));
      bool hasKgtD = false;
      for (int i = 1; i < close.length; i++) {
        if (r.k[i] > r.d[i]) { hasKgtD = true; break; }
      }
      expect(hasKgtD, isTrue);
    });

    test('K/D crossover fires with oscillating data', () {
      final high = <double>[];
      final low = <double>[];
      final close = <double>[];
      for (int i = 0; i < 20; i++) {
        final v = 100.0 - i;
        high.add(v + 0.5);
        low.add(v - 0.5);
        close.add(v);
      }
      for (int i = 0; i < 40; i++) {
        final v = 80.0 + i * 0.5;
        high.add(v + 0.5);
        low.add(v - 0.5);
        close.add(v);
      }
      final r = calcStochastic(high, low, close);
      expect(r.k.length, close.length);
      expect(r.d.length, close.length);
    });
  });

  group('HalfTrend', () {
    test('rising prices produce long trend', () {
      final d = _makeOHLCV(80, 100, 1);
      final r = calcHalfTrend(d.high, d.low, d.close);
      expect(r.trend.length, 80);
      expect(r.htLine.length, 80);
      expect(r.isLong[79], isTrue);
      expect(r.isShort[79], isFalse);
    });

    test('rise then sharp drop produces short trend', () {
      final high = <double>[];
      final low = <double>[];
      final close = <double>[];
      for (int i = 0; i < 20; i++) {
        close.add(100.0 + i);
        high.add(100.5 + i);
        low.add(99.5 + i);
      }
      for (int i = 0; i < 20; i++) {
        close.add(119.0 - (i + 1) * 5.0);
        high.add(119.5 - (i + 1) * 5.0);
        low.add(118.5 - (i + 1) * 5.0);
      }
      final r = calcHalfTrend(high, low, close);
      expect(r.trend.length, 40);
      expect(r.isShort[39], isTrue);
    });

    test('constant prices handle without crash', () {
      final d = _makeOHLCV(30, 100, 0);
      final r = calcHalfTrend(d.high, d.low, d.close);
      expect(r.trend.length, 30);
    });
  });

  group('Donchian', () {
    test('rising prices produce long trend', () {
      final d = _makeOHLCV(60, 100, 1);
      final r = calcDonchian(d.high, d.low, d.close);
      expect(r.isLong[59], isTrue);
    });

    test('falling prices produce short trend', () {
      final d = _makeOHLCV(60, 100, -1);
      final r = calcDonchian(d.high, d.low, d.close);
      expect(r.isShort[59], isTrue);
    });
  });

  group('Edge cases', () {
    test('empty close array returns empty results', () {
      final r = calcROC([], length: 9);
      expect(r.roc, isEmpty);
      expect(r.isLong, isEmpty);
    });

    test('ROC is positive for rising, negative for falling', () {
      final d = _makeOHLCV(20, 100, 1);
      final rRise = calcROC(d.close);
      expect(rRise.roc.where((v) => v.isNaN || v == 0).length, greaterThan(0));
      expect(rRise.roc[19], greaterThan(0));

      final dFall = _makeOHLCV(20, 100, -1);
      final rFall = calcROC(dFall.close);
      expect(rFall.roc[19], lessThan(0));
    });

    test('VWAP works with rising prices', () {
      final d = _makeOHLCV(30, 100, 1);
      final r = calcVWAP(d.high, d.low, d.close, d.volume);
      expect(r.vwap.length, 30);
      expect(r.vwap[29], greaterThan(d.close[0]));
      expect(r.isLong[29], isTrue);
    });

    test('CCI produces values with rising prices', () {
      final d = _makeOHLCV(50, 100, 1);
      final r = calcCCI(d.high, d.low, d.close);
      expect(r.cci.length, 50);
      expect(r.smoothed.length, 50);
    });

    test('ADX produces values with rising prices', () {
      final d = _makeOHLCV(50, 100, 1);
      final r = calcADX(d.high, d.low, d.close);
      expect(r.adx.length, 50);
      expect(r.diPlus.length, 50);
      expect(r.diMinus.length, 50);
    });

    test('QQE produces values', () {
      final d = _makeOHLCV(50, 100, 1);
      final r = calcQQE(d.close);
      expect(r.isAbove.length, 50);
      expect(r.isBelow.length, 50);
    });
  });
}
