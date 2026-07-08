// ignore_for_file: argument_type_not_assignable, non_bool_operand, inference_failure_on_untyped_parameter
import '../data/models/screen_signal_config.dart';
import 'ohlcv_data.dart';
import 'indicator_engine.dart';

enum FreshCheckResult { fresh, staleRepeat, insufficientHistory }

/// Mirrors Pine Script's longCond/shortCond AND-gate logic (lines 4212-4220)
class SignalEngine {
  final ScreenSignalConfig config;

  SignalEngine({ScreenSignalConfig? config})
    : config = config ?? ScreenSignalConfig();

  List<SignalType> evaluateAll({required OhlcvData data}) {
    if (data.length < 2) return List.filled(data.length, SignalType.neutral);

    // Cache indicators that are stateful or expensive on the full data
    final pRangeFilter = config.parameters['Range Filter'] ?? {};
    final rangeFilter = calcRangeFilter(
      data.close,
      pRangeFilter['period'] ?? 100,
      pRangeFilter['multiplier'] ?? 3.0,
    );
    final pRqk = config.parameters['Rational Quadratic Kernel (RQK)'] ?? {};
    final rqk = calcRQK(
      data.close,
      pRqk['h2'] ?? 8.0,
      pRqk['r'] ?? 8.0,
      pRqk['x0'] ?? 25,
      pRqk['lagVal'] ?? 2,
    );
    final pHt = config.parameters['Half Trend'] ?? {};
    final halfTrend = calcHalfTrend(
      data.high,
      data.low,
      data.close,
      amplitude: pHt['amplitude'] ?? 2,
      channelDeviation: pHt['channelDeviation'] ?? 2,
    );
    final pSt = config.parameters['Supertrend'] ?? {};
    final superTrend = calcSuperTrend(
      data.high,
      data.low,
      data.close,
      period: pSt['period'] ?? 10,
      multiplier: pSt['multiplier'] ?? 3.0,
    );
    final pTsi = config.parameters['True Strength Indicator (TSI)'] ?? {};
    final tsi = calcTSI(
      data.close,
      longLen: pTsi['longLen'] ?? 25,
      shortLen: pTsi['shortLen'] ?? 13,
      signalLen: pTsi['signalLen'] ?? 13,
    );
    final pDon = config.parameters['Donchian Trend Ribbon'] ?? {};
    final donchian = calcDonchian(
      data.high,
      data.low,
      data.close,
      period: pDon['period'] ?? 15,
    );
    final pRoc = config.parameters['Rate of Change (ROC)'] ?? {};
    final roc = calcROC(data.close, length: pRoc['length'] ?? 9);
    final pMacd = config.parameters['MACD'] ?? {};
    final macd = calcMACD(
      data.close,
      fast: pMacd['fast'] ?? 12,
      slow: pMacd['slow'] ?? 26,
      signalLen: pMacd['signalLen'] ?? 9,
      macdType: pMacd['macdType'] ?? 'MACD Crossover',
    );
    final pSsl = config.parameters['SSL Channel'] ?? {};
    final ssl = calcSSL(
      data.high,
      data.low,
      data.close,
      period: pSsl['period'] ?? 10,
    );
    final pBbpt = config.parameters['Bull Bear Power Trend'] ?? {};
    final bbpt = calcBBPT(
      data.high,
      data.low,
      data.close,
      type: pBbpt['type'] ?? 'Follow Trend',
    );
    final pRsi = config.parameters['RSI'] ?? {};
    final rsi = calcRSI(
      data.close,
      length: pRsi['length'] ?? 14,
      maType: pRsi['maType'] ?? 'SMA',
      maLen: pRsi['maLen'] ?? 14,
      ob: pRsi['ob'] ?? 80,
      os: pRsi['os'] ?? 20,
      level: pRsi['level'] ?? 50,
      rsiType: pRsi['rsiType'] ?? 'RSI MA Cross',
    );
    final pStoch = config.parameters['Stochastic'] ?? {};
    final stoch = calcStochastic(
      data.high,
      data.low,
      data.close,
      length: pStoch['length'] ?? 14,
      smoothK: pStoch['smoothK'] ?? 3,
      smoothD: pStoch['smoothD'] ?? 3,
      ob: pStoch['ob'] ?? 80,
      os: pStoch['os'] ?? 20,
      type: pStoch['type'] ?? 'CrossOver',
    );
    final pIchi = config.parameters['Ichimoku Cloud'] ?? {};
    final ichi = calcIchimoku(
      data.high,
      data.low,
      data.close,
      conversion: pIchi['conversion'] ?? 9,
      base: pIchi['base'] ?? 26,
      spanB: pIchi['spanB'] ?? 52,
      displace: pIchi['displace'] ?? 26,
    );

    final chandelier = calcChandelier(data.high, data.low, data.close);
    final cci = calcCCI(data.high, data.low, data.close);
    final adx = calcADX(data.high, data.low, data.close);
    final psar = calcPSAR(data.high, data.low, data.close);
    final wae = calcWAE(data.high, data.low, data.close);
    final haColt = calcHACOLT(data.open, data.high, data.low, data.close);
    final awesome = calcAwesome(data.high, data.low);
    final wolf = calcWolfpack(data.close);
    final qqe = calcQQE(data.close);
    final hull = calcHull(data.close);
    final vortex = calcVortex(data.high, data.low, data.close);
    final bbOsc = calcBBOsc(data.close, data.open);
    final rd = calcRangeDetector(data.high, data.low, data.close);
    final tb = calcTrendlineBO(data.high, data.low, data.close);
    final chaikin = calcChaikin(data.high, data.low, data.close, data.volume);
    final volume = calcVolume(data.open, data.close, data.volume);
    final mg = calcMcGinley(data.close);
    final ema2 = calc2EMACross(data.close);
    final ema3 = calc3EMACross(data.close);
    final emaFilt = calcEMAFilter(data.close);
    final stc = calcSTC(data.close);
    final dv = calcDV(data.high, data.low, data.close);
    final ci = calcCI(data.high, data.low, data.close);
    final volatilityOsc = calcVolatilityOsc(
      data.open,
      data.high,
      data.low,
      data.close,
    );
    final dpo = calcDPO(data.close);
    final tdfi = calcTDFI(data.close);
    final superIchi = calcSuperIchi(data.high, data.low, data.close);
    final bx = calcBXtrender(data.close);
    final vwap = calcVWAP(data.high, data.low, data.close, data.volume);

    final results = List<SignalType>.filled(data.length, SignalType.neutral);

    for (int barIndex = 0; barIndex < data.length; barIndex++) {
      // Leading indicator signal
      final leadingLong = _getLeadingLong(
        config.leadingIndicator,
        rangeFilter,
        rqk,
        halfTrend,
        superTrend,
        tsi,
        donchian,
        roc,
        macd,
        ssl,
        bbpt,
        chandelier,
        cci,
        adx,
        psar,
        wae,
        haColt,
        awesome,
        wolf,
        qqe,
        hull,
        vortex,
        bbOsc,
        rd,
        tb,
        chaikin,
        volume,
        mg,
        ema2,
        ema3,
        emaFilt,
        stc,
        dv,
        ci,
        volatilityOsc,
        dpo,
        tdfi,
        rsi,
        stoch,
        ichi,
        superIchi,
        bx,
        vwap,
        barIndex,
      );
      final leadingShort = _getLeadingShort(
        config.leadingIndicator,
        rangeFilter,
        rqk,
        halfTrend,
        superTrend,
        tsi,
        donchian,
        roc,
        macd,
        ssl,
        bbpt,
        chandelier,
        cci,
        adx,
        psar,
        wae,
        haColt,
        awesome,
        wolf,
        qqe,
        hull,
        vortex,
        bbOsc,
        rd,
        tb,
        chaikin,
        volume,
        mg,
        ema2,
        ema3,
        emaFilt,
        stc,
        dv,
        ci,
        volatilityOsc,
        dpo,
        tdfi,
        rsi,
        stoch,
        ichi,
        superIchi,
        bx,
        vwap,
        barIndex,
      );

      if (!leadingLong && !leadingShort) continue;

      // Confirmation AND gate
      final allConfirmLong = _allConfirmationsLong(
        config,
        rangeFilter,
        rqk,
        halfTrend,
        superTrend,
        tsi,
        donchian,
        roc,
        macd,
        ssl,
        bbpt,
        chandelier,
        cci,
        adx,
        psar,
        wae,
        haColt,
        awesome,
        wolf,
        qqe,
        hull,
        vortex,
        bbOsc,
        rd,
        tb,
        chaikin,
        volume,
        mg,
        ema2,
        ema3,
        emaFilt,
        stc,
        dv,
        ci,
        volatilityOsc,
        dpo,
        tdfi,
        rsi,
        stoch,
        ichi,
        superIchi,
        bx,
        vwap,
        barIndex,
      );
      final allConfirmShort = _allConfirmationsShort(
        config,
        rangeFilter,
        rqk,
        halfTrend,
        superTrend,
        tsi,
        donchian,
        roc,
        macd,
        ssl,
        bbpt,
        chandelier,
        cci,
        adx,
        psar,
        wae,
        haColt,
        awesome,
        wolf,
        qqe,
        hull,
        vortex,
        bbOsc,
        rd,
        tb,
        chaikin,
        volume,
        mg,
        ema2,
        ema3,
        emaFilt,
        stc,
        dv,
        ci,
        volatilityOsc,
        dpo,
        tdfi,
        rsi,
        stoch,
        ichi,
        superIchi,
        bx,
        vwap,
        barIndex,
      );

      if (leadingLong && allConfirmLong) {
        results[barIndex] = SignalType.buy;
      } else if (leadingShort && allConfirmShort) {
        results[barIndex] = SignalType.sell;
      }
    }

    return results;
  }

  /// Aggregate all indicator results and produce final signal.
  /// [barIndex] is the current bar to evaluate.
  /// Returns [SignalType] for the current bar.
  SignalType evaluate({required OhlcvData data, required int barIndex}) {
    final allSignals = evaluateAll(data: data);
    if (barIndex >= 0 && barIndex < allSignals.length) {
      return allSignals[barIndex];
    }
    return SignalType.neutral;
  }

  /// Check if a signal is "fresh" — first reversal after opposing direction.
  FreshCheckResult isFreshSignal(List<SignalType> history, SignalType current) {
    if (history.length < 2 || current == SignalType.neutral) {
      return FreshCheckResult.insufficientHistory;
    }
    final last = history.length - 1;
    int signalStart = last;
    for (int i = last - 1; i >= 0; i--) {
      if (history[i] != current) {
        signalStart = i + 1;
        break;
      }
      if (i == 0) return FreshCheckResult.insufficientHistory;
    }

    // If the signal started before the last bar, it's a stale repeat of an ongoing trend.
    if (signalStart != last) return FreshCheckResult.staleRepeat;

    int neutralCount = 0;
    for (int i = signalStart - 1; i >= 0 && i >= signalStart - 1 - 30; i--) {
      if (history[i] == SignalType.neutral) {
        neutralCount++;
        if (neutralCount > 30) return FreshCheckResult.insufficientHistory;
      } else if (history[i] != current) {
        return FreshCheckResult.fresh; // found opposing signal
      } else {
        return FreshCheckResult.staleRepeat;
      }
    }
    return FreshCheckResult.insufficientHistory;
  }

  // --- Helpers ----------------------------------------------------

  bool _getLeadingLong(
    String name,
    /* all indicator results */ rf,
    dynamic rqk,
    dynamic ht,
    dynamic st,
    dynamic tsi,
    dynamic don,
    dynamic rocVal,
    dynamic macd,
    dynamic ssl,
    dynamic bbpt,
    dynamic chandelier,
    dynamic cci,
    dynamic adx,
    dynamic psar,
    dynamic wae,
    dynamic hacolt,
    dynamic awesome,
    dynamic wolf,
    dynamic qqe,
    dynamic hull,
    dynamic vortex,
    dynamic bbosc,
    dynamic rd,
    dynamic tb,
    dynamic chaikin,
    dynamic vol,
    dynamic mg,
    dynamic ema2,
    dynamic ema3,
    dynamic emaFilt,
    dynamic stc,
    dynamic dv,
    dynamic ci,
    dynamic vo,
    dynamic dpo,
    dynamic tdfi,
    dynamic rsi,
    dynamic stoch,
    dynamic ichi,
    dynamic superIchi,
    dynamic bx,
    dynamic vwap,
    int i,
  ) {
    // Maps Pine Script lines 4004-4179
    switch (name) {
      case 'Range Filter':
        return i < rf.uprf.length && rf.uprf[i];
      case 'Rational Quadratic Kernel (RQK)':
        return i < rqk.uptrend.length && rqk.uptrend[i];
      case 'Half Trend':
        return i < ht.isLong.length && ht.isLong[i];
      case 'Supertrend':
        return i < st.isUp.length && st.isUp[i];
      case 'True Strength Indicator (TSI)':
        return i < tsi.isLong.length && tsi.isLong[i];
      case 'Donchian Trend Ribbon':
        return i < don.isLong.length && don.isLong[i];
      case 'Rate of Change (ROC)':
        return i < rocVal.isLong.length && rocVal.isLong[i];
      case 'MACD':
        return i < macd.isLong.length && macd.isLong[i];
      case 'SSL Channel':
        return i < ssl.isLong.length && ssl.isLong[i];
      case 'Bull Bear Power Trend':
        return i < bbpt.isLong.length && bbpt.isLong[i];
      case 'Chandelier Exit':
        return i < chandelier.isLong.length && chandelier.isLong[i];
      case 'CCI':
        return i < cci.isLong.length && cci.isLong[i];
      case 'DMI (Adx)':
        return i < adx.isLong.length && adx.isLong[i];
      case 'Parabolic SAR (PSAR)':
        return i < psar.isUp.length && psar.isUp[i];
      case 'Waddah Attar Explosion':
        return i < wae.isLong.length && wae.isLong[i];
      case 'Heiken-Ashi Candlestick Oscillator':
        return i < hacolt.isLong.length && hacolt.isLong[i];
      case 'Awesome Oscillator':
        return i < awesome.isLong.length && awesome.isLong[i];
      case 'Wolfpack Id':
        return i < wolf.isLong.length && wolf.isLong[i];
      case 'QQE Mod':
        return i < qqe.isAbove.length && qqe.isAbove[i];
      case 'Hull Suite':
        return i < hull.isUp.length && hull.isUp[i];
      case 'Vortex Index':
        return i < vortex.vipCondition.length && vortex.vipCondition[i];
      case 'BB Oscillator':
        return i < bbosc.isLong.length && bbosc.isLong[i];
      case 'Range Detector':
        return i < rd.isLong.length && rd.isLong[i];
      case 'Trendline Breakout':
        return i < tb.buySignal.length && tb.buySignal[i];
      case 'Chaikin Money Flow':
        return i < chaikin.isLong.length && chaikin.isLong[i];
      case 'Volume':
        return i < vol.isLong.length && vol.isLong[i];
      case 'McGinley Dynamic':
        return i < mg.isLong.length && mg.isLong[i];
      case '2 EMA Cross':
        return i < ema2.isLong.length && ema2.isLong[i];
      case '3 EMA Cross':
        return i < ema3.isLong.length && ema3.isLong[i];
      case 'Schaff Trend Cycle (STC)':
        return i < stc.isUp.length && stc.isUp[i];
      case 'Damiani Volatility (DV)':
        return i < dv.isUp.length && dv.isUp[i];
      case 'Volatility Oscillator':
        return i < vo.isLong.length && vo.isLong[i];
      case 'Detrended Price Oscillator (DPO)':
        return i < dpo.isLong.length && dpo.isLong[i];
      case 'Trend Direction Force Index (TDFI)':
        return i < tdfi.isLong.length && tdfi.isLong[i];
      case 'RSI':
        return i < rsi.isLong.length && rsi.isLong[i];
      case 'Stochastic':
        return i < stoch.isLong.length && stoch.isLong[i];
      case 'Ichimoku Cloud':
        return i < ichi.isLong.length && ichi.isLong[i];
      case 'SuperIchi':
        return i < superIchi.isLong.length && superIchi.isLong[i];
      case 'B-Xtrender':
        return i < bx.isLong.length && bx.isLong[i];
      case 'VWAP':
        return i < vwap.isLong.length && vwap.isLong[i];
      default:
        return false;
    }
  }

  bool _getLeadingShort(
    String name,
    dynamic rf,
    dynamic rqk,
    dynamic ht,
    dynamic st,
    dynamic tsi,
    dynamic don,
    dynamic rocVal,
    dynamic macd,
    dynamic ssl,
    dynamic bbpt,
    dynamic chandelier,
    dynamic cci,
    dynamic adx,
    dynamic psar,
    dynamic wae,
    dynamic hacolt,
    dynamic awesome,
    dynamic wolf,
    dynamic qqe,
    dynamic hull,
    dynamic vortex,
    dynamic bbosc,
    dynamic rd,
    dynamic tb,
    dynamic chaikin,
    dynamic vol,
    dynamic mg,
    dynamic ema2,
    dynamic ema3,
    dynamic emaFilt,
    dynamic stc,
    dynamic dv,
    dynamic ci,
    dynamic vo,
    dynamic dpo,
    dynamic tdfi,
    dynamic rsi,
    dynamic stoch,
    dynamic ichi,
    dynamic superIchi,
    dynamic bx,
    dynamic vwap,
    int i,
  ) {
    switch (name) {
      case 'Range Filter':
        return i < rf.downrf.length && rf.downrf[i];
      case 'Rational Quadratic Kernel (RQK)':
        return i < rqk.downtrend.length && rqk.downtrend[i];
      case 'Half Trend':
        return i < ht.isShort.length && ht.isShort[i];
      case 'Supertrend':
        return i < st.isDown.length && st.isDown[i];
      case 'True Strength Indicator (TSI)':
        return i < tsi.isShort.length && tsi.isShort[i];
      case 'Donchian Trend Ribbon':
        return i < don.isShort.length && don.isShort[i];
      case 'Rate of Change (ROC)':
        return i < rocVal.isShort.length && rocVal.isShort[i];
      case 'MACD':
        return i < macd.isShort.length && macd.isShort[i];
      case 'SSL Channel':
        return i < ssl.isShort.length && ssl.isShort[i];
      case 'Bull Bear Power Trend':
        return i < bbpt.isShort.length && bbpt.isShort[i];
      case 'Chandelier Exit':
        return i < chandelier.isShort.length && chandelier.isShort[i];
      case 'CCI':
        return i < cci.isShort.length && cci.isShort[i];
      case 'DMI (Adx)':
        return i < adx.isShort.length && adx.isShort[i];
      case 'Parabolic SAR (PSAR)':
        return i < psar.isDown.length && psar.isDown[i];
      case 'Waddah Attar Explosion':
        return i < wae.isShort.length && wae.isShort[i];
      case 'Heiken-Ashi Candlestick Oscillator':
        return i < hacolt.isShort.length && hacolt.isShort[i];
      case 'Awesome Oscillator':
        return i < awesome.isShort.length && awesome.isShort[i];
      case 'Wolfpack Id':
        return i < wolf.isShort.length && wolf.isShort[i];
      case 'QQE Mod':
        return i < qqe.isBelow.length && qqe.isBelow[i];
      case 'Hull Suite':
        return i < hull.isDown.length && hull.isDown[i];
      case 'Vortex Index':
        return i < vortex.vimCondition.length && vortex.vimCondition[i];
      case 'BB Oscillator':
        return i < bbosc.isShort.length && bbosc.isShort[i];
      case 'Range Detector':
        return i < rd.isShort.length && rd.isShort[i];
      case 'Trendline Breakout':
        return i < tb.sellSignal.length && tb.sellSignal[i];
      case 'Chaikin Money Flow':
        return i < chaikin.isShort.length && chaikin.isShort[i];
      case 'Volume':
        return i < vol.isShort.length && vol.isShort[i];
      case 'McGinley Dynamic':
        return i < mg.isShort.length && mg.isShort[i];
      case '2 EMA Cross':
        return i < ema2.isShort.length && ema2.isShort[i];
      case '3 EMA Cross':
        return i < ema3.isShort.length && ema3.isShort[i];
      case 'Schaff Trend Cycle (STC)':
        return i < stc.isDown.length && stc.isDown[i];
      case 'Volatility Oscillator':
        return i < vo.isShort.length && vo.isShort[i];
      case 'Detrended Price Oscillator (DPO)':
        return i < dpo.isShort.length && dpo.isShort[i];
      case 'Trend Direction Force Index (TDFI)':
        return i < tdfi.isShort.length && tdfi.isShort[i];
      case 'RSI':
        return i < rsi.isShort.length && rsi.isShort[i];
      case 'Stochastic':
        return i < stoch.isShort.length && stoch.isShort[i];
      case 'Ichimoku Cloud':
        return i < ichi.isShort.length && ichi.isShort[i];
      case 'SuperIchi':
        return i < superIchi.isShort.length && superIchi.isShort[i];
      case 'B-Xtrender':
        return i < bx.isShort.length && bx.isShort[i];
      case 'VWAP':
        return i < vwap.isShort.length && vwap.isShort[i];
      default:
        return false;
    }
  }

  bool _allConfirmationsLong(
    ScreenSignalConfig config,
    dynamic rf,
    dynamic rqk,
    dynamic ht,
    dynamic st,
    dynamic tsi,
    dynamic don,
    dynamic rocVal,
    dynamic macd,
    dynamic ssl,
    dynamic bbpt,
    dynamic chandelier,
    dynamic cci,
    dynamic adx,
    dynamic psar,
    dynamic wae,
    dynamic hacolt,
    dynamic awesome,
    dynamic wolf,
    dynamic qqe,
    dynamic hull,
    dynamic vortex,
    dynamic bbosc,
    dynamic rd,
    dynamic tb,
    dynamic chaikin,
    dynamic vol,
    dynamic mg,
    dynamic ema2,
    dynamic ema3,
    dynamic emaFilt,
    dynamic stc,
    dynamic dv,
    dynamic ci,
    dynamic vo,
    dynamic dpo,
    dynamic tdfi,
    dynamic rsi,
    dynamic stoch,
    dynamic ichi,
    dynamic superIchi,
    dynamic bx,
    dynamic vwap,
    int i,
  ) {
    if (config.confirmations.isEmpty) return true;
    for (final conf in config.confirmations) {
      if (!_getLeadingLong(
        conf,
        rf,
        rqk,
        ht,
        st,
        tsi,
        don,
        rocVal,
        macd,
        ssl,
        bbpt,
        chandelier,
        cci,
        adx,
        psar,
        wae,
        hacolt,
        awesome,
        wolf,
        qqe,
        hull,
        vortex,
        bbosc,
        rd,
        tb,
        chaikin,
        vol,
        mg,
        ema2,
        ema3,
        emaFilt,
        stc,
        dv,
        ci,
        vo,
        dpo,
        tdfi,
        rsi,
        stoch,
        ichi,
        superIchi,
        bx,
        vwap,
        i,
      )) {
        return false;
      }
    }
    return true;
  }

  bool _allConfirmationsShort(
    ScreenSignalConfig config,
    dynamic rf,
    dynamic rqk,
    dynamic ht,
    dynamic st,
    dynamic tsi,
    dynamic don,
    dynamic rocVal,
    dynamic macd,
    dynamic ssl,
    dynamic bbpt,
    dynamic chandelier,
    dynamic cci,
    dynamic adx,
    dynamic psar,
    dynamic wae,
    dynamic hacolt,
    dynamic awesome,
    dynamic wolf,
    dynamic qqe,
    dynamic hull,
    dynamic vortex,
    dynamic bbosc,
    dynamic rd,
    dynamic tb,
    dynamic chaikin,
    dynamic vol,
    dynamic mg,
    dynamic ema2,
    dynamic ema3,
    dynamic emaFilt,
    dynamic stc,
    dynamic dv,
    dynamic ci,
    dynamic vo,
    dynamic dpo,
    dynamic tdfi,
    dynamic rsi,
    dynamic stoch,
    dynamic ichi,
    dynamic superIchi,
    dynamic bx,
    dynamic vwap,
    int i,
  ) {
    if (config.confirmations.isEmpty) return true;
    for (final conf in config.confirmations) {
      if (!_getLeadingShort(
        conf,
        rf,
        rqk,
        ht,
        st,
        tsi,
        don,
        rocVal,
        macd,
        ssl,
        bbpt,
        chandelier,
        cci,
        adx,
        psar,
        wae,
        hacolt,
        awesome,
        wolf,
        qqe,
        hull,
        vortex,
        bbosc,
        rd,
        tb,
        chaikin,
        vol,
        mg,
        ema2,
        ema3,
        emaFilt,
        stc,
        dv,
        ci,
        vo,
        dpo,
        tdfi,
        rsi,
        stoch,
        ichi,
        superIchi,
        bx,
        vwap,
        i,
      )) {
        return false;
      }
    }
    return true;
  }
}
