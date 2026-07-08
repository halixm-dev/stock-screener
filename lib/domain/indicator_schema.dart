sealed class ConfigParam {
  final String label;
  const ConfigParam(this.label);
}

class IntParam extends ConfigParam {
  final int min;
  final int max;
  final int defaultValue;

  const IntParam(
    super.label, {
    required this.min,
    required this.max,
    required this.defaultValue,
  });
}

class DoubleParam extends ConfigParam {
  final double min;
  final double max;
  final double defaultValue;

  const DoubleParam(
    super.label, {
    required this.min,
    required this.max,
    required this.defaultValue,
  });
}

class BoolParam extends ConfigParam {
  final bool defaultValue;

  const BoolParam(super.label, {required this.defaultValue});
}

class ChoiceParam extends ConfigParam {
  final List<String> options;
  final String defaultValue;

  const ChoiceParam(
    super.label, {
    required this.options,
    required this.defaultValue,
  });
}

class IndicatorSchema {
  final String name;
  final Map<String, ConfigParam> parameters;

  const IndicatorSchema(this.name, this.parameters);
}

final Map<String, IndicatorSchema> indicatorRegistry = {
  'Range Filter': IndicatorSchema('Range Filter', {
    'period': IntParam('Period', min: 1, max: 200, defaultValue: 100),
    'multiplier': DoubleParam(
      'Multiplier',
      min: 0.1,
      max: 10.0,
      defaultValue: 3.0,
    ),
  }),
  'Rational Quadratic Kernel (RQK)':
      IndicatorSchema('Rational Quadratic Kernel (RQK)', {
        'h2': DoubleParam(
          'Lookback Window',
          min: 1.0,
          max: 50.0,
          defaultValue: 8.0,
        ),
        'r': DoubleParam(
          'Relative Weight',
          min: 1.0,
          max: 50.0,
          defaultValue: 8.0,
        ),
        'x0': IntParam('Start Bar', min: 1, max: 100, defaultValue: 25),
        'lagVal': IntParam('Lag', min: 1, max: 20, defaultValue: 2),
      }),
  'Half Trend': IndicatorSchema('Half Trend', {
    'amplitude': IntParam('Amplitude', min: 1, max: 50, defaultValue: 2),
    'channelDeviation': IntParam(
      'Channel Deviation',
      min: 1,
      max: 20,
      defaultValue: 2,
    ),
  }),
  'Supertrend': IndicatorSchema('Supertrend', {
    'period': IntParam('ATR Period', min: 1, max: 100, defaultValue: 10),
    'multiplier': DoubleParam(
      'ATR Multiplier',
      min: 0.1,
      max: 10.0,
      defaultValue: 3.0,
    ),
  }),
  'True Strength Indicator (TSI)': IndicatorSchema(
    'True Strength Indicator (TSI)',
    {
      'longLen': IntParam('Long Length', min: 1, max: 100, defaultValue: 25),
      'shortLen': IntParam('Short Length', min: 1, max: 100, defaultValue: 13),
      'signalLen': IntParam(
        'Signal Length',
        min: 1,
        max: 100,
        defaultValue: 13,
      ),
    },
  ),
  'Donchian Trend Ribbon': IndicatorSchema('Donchian Trend Ribbon', {
    'period': IntParam('Period', min: 1, max: 100, defaultValue: 15),
  }),
  'Rate of Change (ROC)': IndicatorSchema('Rate of Change (ROC)', {
    'length': IntParam('Length', min: 1, max: 100, defaultValue: 9),
  }),
  'MACD': IndicatorSchema('MACD', {
    'fast': IntParam('Fast Length', min: 1, max: 100, defaultValue: 12),
    'slow': IntParam('Slow Length', min: 1, max: 100, defaultValue: 26),
    'signalLen': IntParam('Signal Length', min: 1, max: 50, defaultValue: 9),
    'macdType': ChoiceParam(
      'MACD Type',
      options: ['MACD Crossover', 'MACD line Crosses 0'],
      defaultValue: 'MACD Crossover',
    ),
  }),
  'SSL Channel': IndicatorSchema('SSL Channel', {
    'period': IntParam('Period', min: 1, max: 100, defaultValue: 10),
  }),
  'Bull Bear Power Trend': IndicatorSchema('Bull Bear Power Trend', {
    'type': ChoiceParam(
      'Type',
      options: ['Follow Trend', 'Reversal'],
      defaultValue: 'Follow Trend',
    ),
  }),
  'RSI': IndicatorSchema('RSI', {
    'length': IntParam('Length', min: 1, max: 100, defaultValue: 14),
    'maType': ChoiceParam(
      'MA Type',
      options: ['SMA', 'EMA', 'WMA', 'RMA'],
      defaultValue: 'SMA',
    ),
    'maLen': IntParam('MA Length', min: 1, max: 100, defaultValue: 14),
    'ob': IntParam('Overbought', min: 50, max: 100, defaultValue: 80),
    'os': IntParam('Oversold', min: 0, max: 50, defaultValue: 20),
    'level': IntParam('Level', min: 0, max: 100, defaultValue: 50),
    'rsiType': ChoiceParam(
      'RSI Type',
      options: [
        'RSI MA Cross',
        'RSI Exits OB/OS zones',
        'RSI Crosses Level 50',
      ],
      defaultValue: 'RSI MA Cross',
    ),
  }),
  'Stochastic': IndicatorSchema('Stochastic', {
    'length': IntParam('Length', min: 1, max: 100, defaultValue: 14),
    'smoothK': IntParam('Smooth K', min: 1, max: 50, defaultValue: 3),
    'smoothD': IntParam('Smooth D', min: 1, max: 50, defaultValue: 3),
    'ob': IntParam('Overbought', min: 50, max: 100, defaultValue: 80),
    'os': IntParam('Oversold', min: 0, max: 50, defaultValue: 20),
    'type': ChoiceParam(
      'Type',
      options: [
        'CrossOver',
        'CrossOver in OB & OS levels',
        'K & D > OB & < OS',
      ],
      defaultValue: 'CrossOver',
    ),
  }),
  'Ichimoku Cloud': IndicatorSchema('Ichimoku Cloud', {
    'conversion': IntParam(
      'Conversion Line',
      min: 1,
      max: 100,
      defaultValue: 9,
    ),
    'base': IntParam('Base Line', min: 1, max: 100, defaultValue: 26),
    'spanB': IntParam('Leading Span B', min: 1, max: 200, defaultValue: 52),
    'displace': IntParam('Displacement', min: 1, max: 100, defaultValue: 26),
  }),
  // Empty schemas for the rest so they don't crash
  'Chandelier Exit': IndicatorSchema('Chandelier Exit', {}),
  'CCI': IndicatorSchema('CCI', {}),
  'DMI (Adx)': IndicatorSchema('DMI (Adx)', {}),
  'Parabolic SAR (PSAR)': IndicatorSchema('Parabolic SAR (PSAR)', {}),
  'Waddah Attar Explosion': IndicatorSchema('Waddah Attar Explosion', {}),
  'Heiken-Ashi Candlestick Oscillator': IndicatorSchema(
    'Heiken-Ashi Candlestick Oscillator',
    {},
  ),
  'Awesome Oscillator': IndicatorSchema('Awesome Oscillator', {}),
  'Wolfpack Id': IndicatorSchema('Wolfpack Id', {}),
  'QQE Mod': IndicatorSchema('QQE Mod', {}),
  'Hull Suite': IndicatorSchema('Hull Suite', {}),
  'Vortex Index': IndicatorSchema('Vortex Index', {}),
  'BB Oscillator': IndicatorSchema('BB Oscillator', {}),
  'Range Detector': IndicatorSchema('Range Detector', {}),
  'Trendline Breakout': IndicatorSchema('Trendline Breakout', {}),
  'Chaikin Money Flow': IndicatorSchema('Chaikin Money Flow', {}),
  'Volume': IndicatorSchema('Volume', {}),
  'McGinley Dynamic': IndicatorSchema('McGinley Dynamic', {}),
  '2 EMA Cross': IndicatorSchema('2 EMA Cross', {}),
  '3 EMA Cross': IndicatorSchema('3 EMA Cross', {}),
  'Schaff Trend Cycle (STC)': IndicatorSchema('Schaff Trend Cycle (STC)', {}),
  'Damiani Volatility (DV)': IndicatorSchema('Damiani Volatility (DV)', {}),
  'Volatility Oscillator': IndicatorSchema('Volatility Oscillator', {}),
  'Detrended Price Oscillator (DPO)': IndicatorSchema(
    'Detrended Price Oscillator (DPO)',
    {},
  ),
  'Trend Direction Force Index (TDFI)': IndicatorSchema(
    'Trend Direction Force Index (TDFI)',
    {},
  ),
  'SuperIchi': IndicatorSchema('SuperIchi', {}),
  'B-Xtrender': IndicatorSchema('B-Xtrender', {}),
  'VWAP': IndicatorSchema('VWAP', {}),
};
