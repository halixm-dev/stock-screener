import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_screener/domain/math_utils.dart';

List<double> prices(int n, double Function(int) fn) =>
    List<double>.generate(n, (i) => fn(i));

List<double> constantPrices(int n, double v) => prices(n, (_) => v);

List<double> rampUp(int n) => prices(n, (i) => (i + 1).toDouble());

List<double> rampDown(int n) => prices(n, (i) => (n - i).toDouble());

void main() {
  group('sma', () {
    test('returns nan for empty src', () {
      final r = sma(<double>[], 3);
      expect(r, isEmpty);
    });

    test('returns nan for src shorter than len', () {
      final r = sma([1.0, 2.0], 3);
      expect(r[0], isNaN);
      expect(r[1], isNaN);
    });

    test('constant values', () {
      final r = sma(constantPrices(5, 5.0), 3);
      expect(r[0], isNaN);
      expect(r[1], isNaN);
      expect(r[2], closeTo(5.0, 1e-9));
      expect(r[3], closeTo(5.0, 1e-9));
      expect(r[4], closeTo(5.0, 1e-9));
    });

    test('ramp up len=3', () {
      final r = sma(rampUp(6), 3);
      expect(r[2], closeTo(2.0, 1e-9));
      expect(r[3], closeTo(3.0, 1e-9));
      expect(r[4], closeTo(4.0, 1e-9));
      expect(r[5], closeTo(5.0, 1e-9));
    });
  });

  group('ema', () {
    test('empty src returns empty', () {
      expect(ema(<double>[], 3), isEmpty);
    });

    test('initialises first non-nan as seed, then smooths', () {
      final r = ema(rampUp(5), 3);
      expect(r[0], closeTo(1.0, 1e-9));
      expect(r[1], closeTo(1.5, 1e-9));
      expect(r[2], closeTo(2.25, 1e-9));
      expect(r[3], closeTo(3.125, 1e-9));
      expect(r[4], closeTo(4.0625, 1e-9));
    });

    test('constant values converge to constant', () {
      final r = ema(constantPrices(10, 10.0), 3);
      expect(r[0], closeTo(10.0, 1e-9));
      for (int i = 1; i < 10; i++) {
        expect(r[i], closeTo(10.0, 1e-9));
      }
    });

    test('len=1 is same as identity', () {
      final src = rampUp(4);
      final r = ema(src, 1);
      for (int i = 0; i < 4; i++) {
        expect(r[i], closeTo(src[i], 1e-9));
      }
    });

    test('skips leading nans', () {
      final src = [double.nan, double.nan, 1.0, 2.0, 3.0];
      final r = ema(src, 3);
      expect(r[0], isNaN);
      expect(r[1], isNaN);
      expect(r[2], closeTo(1.0, 1e-9));
    });
  });

  group('rma', () {
    test('returns nan when src length < len', () {
      final r = rma([1.0, 2.0], 5);
      expect(r[0], isNaN);
      expect(r[1], isNaN);
    });

    test('constant values', () {
      final r = rma(constantPrices(6, 3.0), 3);
      expect(r[0], isNaN);
      expect(r[1], isNaN);
      expect(r[2], closeTo(3.0, 1e-9));
      expect(r[3], closeTo(3.0, 1e-9));
      expect(r[4], closeTo(3.0, 1e-9));
      expect(r[5], closeTo(3.0, 1e-9));
    });

    test('ramp up known values', () {
      final r = rma(rampUp(6), 3);
      expect(r[2], closeTo(2.0, 1e-9));
      expect(r[3], closeTo(8.0 / 3, 1e-9));
      expect(r[4], closeTo(31.0 / 9, 1e-9));
    });
  });

  group('wma', () {
    test('returns nan for short src', () {
      final r = wma([1.0], 3);
      expect(r[0], isNaN);
    });

    test('constant values', () {
      final r = wma(constantPrices(5, 7.0), 3);
      for (int i = 2; i < 5; i++) {
        expect(r[i], closeTo(7.0, 1e-9));
      }
    });

    test('ramp up len=3', () {
      final r = wma(rampUp(5), 3);
      expect(r[2], closeTo((1 * 1 + 2 * 2 + 3 * 3) / 6, 1e-9));
      expect(r[3], closeTo((2 * 1 + 3 * 2 + 4 * 3) / 6, 1e-9));
    });
  });

  group('vwma', () {
    test('returns nan for short src', () {
      final r = vwma([1.0], [1.0], 3);
      expect(r[0], isNaN);
    });

    test('equal volumes equals sma', () {
      final src = rampUp(6);
      final vol = constantPrices(6, 1.0);
      final v = vwma(src, vol, 3);
      final s = sma(src, 3);
      for (int i = 2; i < 6; i++) {
        expect(v[i], closeTo(s[i], 1e-9));
      }
    });

    test('heavier volume shifts weight', () {
      final src = rampUp(5);
      final vol = [100.0, 100.0, 1.0, 1.0, 1.0];
      final r = vwma(src, vol, 3);
      expect(r[2], closeTo((1 * 100 + 2 * 100 + 3 * 1) / 201, 1e-9));
    });

    test('zero total volume returns nan', () {
      final r = vwma(rampUp(5), [0.0, 0.0, 0.0, 0.0, 0.0], 3);
      expect(r[2], isNaN);
    });
  });

  group('hma', () {
    test('returns nan for short src', () {
      final r = hma([1.0], 4);
      expect(r[0], isNaN);
    });

    test('constant values', () {
      final r = hma(constantPrices(10, 5.0), 4);
      for (int i = 5; i < 10; i++) {
        expect(r[i], closeTo(5.0, 1e-6));
      }
    });

    test('len=2 first two are nan then finite', () {
      final r = hma(rampUp(10), 2);
      expect(r[0], isNaN);
      expect(r[1], isNaN);
      for (int i = 2; i < 10; i++) {
        expect(r[i].isNaN, isFalse);
      }
    });
  });

  group('tema', () {
    test('returns nan for empty src', () {
      final r = tema(<double>[], 5);
      expect(r, isEmpty);
    });

    test('constant values', () {
      final r = tema(constantPrices(10, 4.0), 3);
      for (int i = 6; i < 10; i++) {
        expect(r[i], closeTo(4.0, 1e-6));
      }
    });

    test('ramp up converges', () {
      final r = tema(rampUp(20), 5);
      for (int i = 10; i < 20; i++) {
        expect(r[i].isNaN, isFalse);
      }
    });
  });

  group('swma', () {
    test('single element returns same', () {
      expect(swma([3.14]), [3.14]);
    });

    test('constant values', () {
      final r = swma(constantPrices(5, 10.0));
      for (int i = 0; i < 5; i++) {
        expect(r[i], closeTo(10.0, 1e-9));
      }
    });

    test('ramp up', () {
      final r = swma(rampUp(5));
      expect(r[0], closeTo(1.0, 1e-9));
      expect(r[1], closeTo(5.0 / 3, 1e-9));
      expect(r[2], closeTo((5.0 / 3 + 6) / 3, 1e-9));
    });
  });

  group('movingAverage dispatcher', () {
    final src = rampUp(8);

    test('SMA dispatches to sma', () {
      expect(movingAverage(src, 3, 'SMA'), sma(src, 3));
    });

    test('EMA dispatches to ema', () {
      expect(movingAverage(src, 3, 'EMA'), ema(src, 3));
    });

    test('RMA dispatches to rma', () {
      expect(movingAverage(src, 3, 'RMA'), rma(src, 3));
    });

    test('SMMA (RMA) dispatches to rma', () {
      expect(movingAverage(src, 3, 'SMMA (RMA)'), rma(src, 3));
    });

    test('WMA dispatches to wma', () {
      expect(movingAverage(src, 3, 'WMA'), wma(src, 3));
    });

    test('VWMA dispatches to vwma', () {
      final vol = constantPrices(8, 1.0);
      expect(movingAverage(src, 3, 'VWMA', volume: vol), vwma(src, vol, 3));
    });

    test('HMA dispatches to hma', () {
      expect(movingAverage(src, 3, 'HMA'), hma(src, 3));
    });

    test('TEMA dispatches to tema', () {
      expect(movingAverage(src, 3, 'TEMA'), tema(src, 3));
    });

    test('SWMA dispatches to swma', () {
      expect(movingAverage(src, 3, 'SWMA'), swma(src));
    });

    test('unknown type defaults to SMA', () {
      expect(movingAverage(src, 3, 'XYZ'), sma(src, 3));
    });
  });

  group('trueRange', () {
    test('single element', () {
      final tr = trueRange([10.0], [7.0], [9.0]);
      expect(tr, [3.0]);
    });

    test('known sequence', () {
      final h = [10.0, 12.0, 11.0];
      final l = [7.0, 8.0, 8.5];
      final c = [9.0, 11.0, 10.5];
      final tr = trueRange(h, l, c);
      expect(tr[0], closeTo(3.0, 1e-9));
      expect(tr[1], closeTo(4.0, 1e-9));
      expect(tr[2], closeTo(2.5, 1e-9));
    });

    test('gap down uses low - prevClose', () {
      final h = [100.0, 80.0];
      final l = [95.0, 78.0];
      final c = [97.0, 79.0];
      final tr = trueRange(h, l, c);
      expect(tr[1], closeTo(19.0, 1e-9));
    });

    test('gap up uses high - prevClose', () {
      final h = [10.0, 30.0];
      final l = [8.0, 25.0];
      final c = [9.0, 28.0];
      final tr = trueRange(h, l, c);
      expect(tr[1], closeTo(21.0, 1e-9));
    });
  });

  group('atr', () {
    test('same as rma of trueRange', () {
      final h = [10.0, 12.0, 11.0, 13.0, 14.0];
      final l = [7.0, 8.0, 8.5, 9.0, 10.0];
      final c = [9.0, 11.0, 10.5, 12.0, 13.0];
      expect(atr(h, l, c, 3), rma(trueRange(h, l, c), 3));
    });
  });

  group('stdev', () {
    test('returns nan for short src', () {
      final r = stdev([1.0], 3);
      expect(r[0], isNaN);
    });

    test('constant values have zero stdev', () {
      final r = stdev(constantPrices(5, 5.0), 3);
      expect(r[2], closeTo(0.0, 1e-9));
      expect(r[3], closeTo(0.0, 1e-9));
      expect(r[4], closeTo(0.0, 1e-9));
    });

    test('ramp up known value', () {
      final r = stdev(rampUp(5), 3);
      final vals = [1.0, 2.0, 3.0];
      final m = 2.0;
      final v = ((1 - m) * (1 - m) + (2 - m) * (2 - m) + (3 - m) * (3 - m)) / 3;
      expect(r[2], closeTo(math.sqrt(v), 1e-9));
    });

    test('single element len=1 gives zero', () {
      final r = stdev([5.0], 1);
      expect(r[0], closeTo(0.0, 1e-9));
    });
  });

  group('variance', () {
    test('returns nan for short src', () {
      final r = variance([1.0], 3);
      expect(r[0], isNaN);
    });

    test('constant values have zero variance', () {
      final r = variance(constantPrices(5, 5.0), 3);
      expect(r[2], closeTo(0.0, 1e-9));
    });

    test('variance equals stdev squared', () {
      final src = rampUp(6);
      final v = variance(src, 3);
      final s = stdev(src, 3);
      for (int i = 2; i < 6; i++) {
        expect(v[i], closeTo(s[i] * s[i], 1e-9));
      }
    });
  });

  group('highest', () {
    test('empty src', () {
      expect(highest(<double>[], 3), isEmpty);
    });

    test('single element', () {
      final r = highest([42.0], 5);
      expect(r[0], closeTo(42.0, 1e-9));
    });

    test('ramp up', () {
      final r = highest(rampUp(6), 3);
      expect(r[0], closeTo(1.0, 1e-9));
      expect(r[1], closeTo(2.0, 1e-9));
      expect(r[2], closeTo(3.0, 1e-9));
      expect(r[3], closeTo(4.0, 1e-9));
      expect(r[4], closeTo(5.0, 1e-9));
      expect(r[5], closeTo(6.0, 1e-9));
    });

    test('ramp down', () {
      final r = highest(rampDown(6), 3);
      expect(r[0], closeTo(6.0, 1e-9));
      expect(r[1], closeTo(6.0, 1e-9));
      expect(r[2], closeTo(6.0, 1e-9));
      expect(r[3], closeTo(5.0, 1e-9));
      expect(r[4], closeTo(4.0, 1e-9));
      expect(r[5], closeTo(3.0, 1e-9));
    });
  });

  group('lowest', () {
    test('empty src', () {
      expect(lowest(<double>[], 3), isEmpty);
    });

    test('single element', () {
      final r = lowest([42.0], 5);
      expect(r[0], closeTo(42.0, 1e-9));
    });

    test('ramp up', () {
      final r = lowest(rampUp(6), 3);
      expect(r[0], closeTo(1.0, 1e-9));
      expect(r[1], closeTo(1.0, 1e-9));
      expect(r[2], closeTo(1.0, 1e-9));
      expect(r[3], closeTo(2.0, 1e-9));
      expect(r[4], closeTo(3.0, 1e-9));
      expect(r[5], closeTo(4.0, 1e-9));
    });

    test('ramp down', () {
      final r = lowest(rampDown(6), 3);
      expect(r[0], closeTo(6.0, 1e-9));
      expect(r[1], closeTo(5.0, 1e-9));
      expect(r[2], closeTo(4.0, 1e-9));
      expect(r[3], closeTo(3.0, 1e-9));
      expect(r[4], closeTo(2.0, 1e-9));
      expect(r[5], closeTo(1.0, 1e-9));
    });
  });

  group('correlation', () {
    test('returns nan when src too short', () {
      final r = correlation([1.0], [2.0], 3);
      expect(r[0], isNaN);
    });

    test('perfect positive correlation is 1', () {
      final x = rampUp(6);
      final y = rampUp(6);
      final r = correlation(x, y, 3);
      for (int i = 2; i < 6; i++) {
        expect(r[i], closeTo(1.0, 1e-9));
      }
    });

    test('perfect negative correlation is -1', () {
      final x = rampUp(6);
      final y = rampDown(6);
      final r = correlation(x, y, 3);
      for (int i = 2; i < 6; i++) {
        expect(r[i], closeTo(-1.0, 1e-9));
      }
    });

    test('zero variance returns 0', () {
      final r = correlation(constantPrices(5, 1.0), rampUp(5), 3);
      expect(r[2], closeTo(0.0, 1e-9));
    });
  });

  group('change', () {
    test('first element is zero', () {
      final r = change([5.0]);
      expect(r[0], closeTo(0.0, 1e-9));
    });

    test('ramp up differences', () {
      final r = change(rampUp(5));
      expect(r[0], closeTo(0.0, 1e-9));
      expect(r[1], closeTo(1.0, 1e-9));
      expect(r[2], closeTo(1.0, 1e-9));
      expect(r[3], closeTo(1.0, 1e-9));
      expect(r[4], closeTo(1.0, 1e-9));
    });

    test('negative changes', () {
      final r = change(rampDown(4));
      expect(r[1], closeTo(-1.0, 1e-9));
      expect(r[2], closeTo(-1.0, 1e-9));
      expect(r[3], closeTo(-1.0, 1e-9));
    });
  });

  group('fixnan', () {
    test('no nans returns src unchanged', () {
      final r = fixnan(rampUp(4));
      expect(r, rampUp(4));
    });

    test('leading nans stay nan until first non-nan', () {
      final r = fixnan([double.nan, double.nan, 5.0, 6.0]);
      expect(r[0], isNaN);
      expect(r[1], isNaN);
      expect(r[2], closeTo(5.0, 1e-9));
      expect(r[3], closeTo(6.0, 1e-9));
    });

    test('interleaved nans carry last valid forward', () {
      final r = fixnan([1.0, double.nan, double.nan, 4.0]);
      expect(r[0], closeTo(1.0, 1e-9));
      expect(r[1], closeTo(1.0, 1e-9));
      expect(r[2], closeTo(1.0, 1e-9));
      expect(r[3], closeTo(4.0, 1e-9));
    });

    test('all nans stays nan', () {
      final r = fixnan([double.nan, double.nan]);
      expect(r[0], isNaN);
      expect(r[1], isNaN);
    });
  });

  group('log10', () {
    test('log10 of 1 is 0', () {
      expect(log10(1.0), closeTo(0.0, 1e-9));
    });

    test('log10 of 10 is 1', () {
      expect(log10(10.0), closeTo(1.0, 1e-9));
    });

    test('log10 of 100 is 2', () {
      expect(log10(100.0), closeTo(2.0, 1e-9));
    });

    test('log10 of 0.1 is -1', () {
      expect(log10(0.1), closeTo(-1.0, 1e-9));
    });

    test('log10 of 0 is -infinity', () {
      expect(log10(0.0), double.negativeInfinity);
    });
  });

  group('highestBars', () {
    test('first element is highest, bars back is 0', () {
      expect(highestBars(rampUp(5), 5, 0), 0);
    });

    test('last element is highest in ramp up', () {
      expect(highestBars(rampUp(5), 5, 4), 0);
    });

    test('bars back to highest in window', () {
      final src = [10.0, 20.0, 5.0, 3.0, 8.0];
      expect(highestBars(src, 3, 4), 0);
    });
  });

  group('lowestBars', () {
    test('first element is lowest, bars back is 0', () {
      expect(lowestBars(rampDown(5), 5, 0), 0);
    });

    test('last element is lowest in ramp down', () {
      expect(lowestBars(rampDown(5), 5, 4), 0);
    });

    test('bars back to lowest in window', () {
      final src = [10.0, 5.0, 15.0, 3.0, 8.0];
      expect(lowestBars(src, 3, 4), 4 - 3);
    });
  });
}
