# IDX Stock Screener — Product Requirements Document & Project Roadmap

**Version:** 1.0  
**Author:** Solo Developer  
**Date:** May 2026  
**Classification:** Personal Tool — Single User  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Vision & Scope](#2-product-vision--scope)
3. [Architecture Design](#3-architecture-design)
4. [Data Layer & Yahoo Finance Integration](#4-data-layer--yahoo-finance-integration)
5. [Indicator Engine — Pine Script to Dart Translation](#5-indicator-engine--pine-script-to-dart-translation)
6. [Screening Logic & Signal System](#6-screening-logic--signal-system)
7. [State Management Architecture](#7-state-management-architecture)
8. [UI/UX Design & Wireframe Concepts](#8-uiux-design--wireframe-concepts)
9. [Background Processing & Scheduling](#9-background-processing--scheduling)
10. [Notification System](#10-notification-system)
11. [Local Persistence & Caching](#11-local-persistence--caching)
12. [Known Bugs & Corrections from Reference Code](#12-known-bugs--corrections-from-reference-code)
13. [Technical Risks & Mitigations](#13-technical-risks--mitigations)
14. [Testing Strategy](#14-testing-strategy)
15. [Implementation Roadmap](#15-implementation-roadmap)
16. [Flutter Package Manifest](#16-flutter-package-manifest)

---

## 1. Executive Summary

This document specifies a **cross-platform mobile application** (Android & iOS) built with Flutter that replicates and extends the capabilities of the Python-based IDX stock screener prototype. The app runs entirely **on-device** — no backend server, no cloud functions — and screens Indonesian Stock Exchange (IDX) equities using three primary technical indicators derived from TradingView Pine Script logic.

The core value proposition is that a solo swing trader can configure screening parameters through a rich UI, schedule automated scans during IDX market hours, and receive local push notifications the moment a fresh confluence signal is detected — without ever opening a laptop.

**Source of Truth for Indicator Logic:** The Pine Script file `diy_custom_strategy.pine` is the canonical reference. All Dart implementations must be validated against Pine Script behavior, not against the Python prototype.

---

## 2. Product Vision & Scope

### 2.1 In Scope (MVP)

- Screening engine for all IDX tickers using three indicators: Range Filter, Rational Quadratic Kernel (RQK), and Half Trend.
- Dynamic parameter UI — every indicator period, multiplier, and threshold adjustable from the UI.
- Leading Indicator selector (match the Pine Script's 40+ indicator list; implement the three core ones first, extend in later phases).
- Confirmation Indicator multi-selector with AND logic.
- Fresh signal detection (first reversal signal after opposing direction).
- Smart deduplication (only notify once per fresh signal per ticker).
- Scheduled background scans (user-defined intervals during IDX market hours: 09:00–15:00 WIB).
- Local push notifications via flutter_local_notifications.
- Results table with ticker, signal type, price, change %, and signal timestamp.
- Offline mode — show last cached scan results with a clear "last updated" timestamp.
- Stock filtering: skip illiquid stocks (volume = 0 or below threshold) and skip delisted stocks (no recent data).

### 2.2 Out of Scope (MVP)

- Multi-user accounts or cloud sync.
- Real-time tick data or websocket feeds.
- Charting / candlestick visualization.
- Paper trading or order execution.
- Telegram or email notifications (Phase 2).
- All 40+ Pine Script indicators (Phase 2+).

### 2.3 Target Platform

| Platform | Minimum OS | Architecture |
|---|---|---|
| Android | Android 8.0 (API 26) | ARM64, x86_64 |
| iOS | iOS 14.0 | ARM64 |

---

## 3. Architecture Design

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                          │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌───────────────┐  │
│  │   UI Layer   │   │  BLoC Layer  │   │  Data Layer   │  │
│  │  (Screens,   │◄──│  (Business   │◄──│  (Repos,      │  │
│  │   Widgets)   │   │   Logic)     │   │   Services)   │  │
│  └──────────────┘   └──────────────┘   └───────────────┘  │
│                                                │            │
│                          ┌─────────────────────▼──────┐    │
│                          │      Core Services          │    │
│                          │                             │    │
│                          │  ┌─────────────────────┐   │    │
│                          │  │  Indicator Engine   │   │    │
│                          │  │  (Pure Dart)        │   │    │
│                          │  └─────────────────────┘   │    │
│                          │  ┌─────────────────────┐   │    │
│                          │  │  Yahoo Finance      │   │    │
│                          │  │  HTTP Client        │   │    │
│                          │  └─────────────────────┘   │    │
│                          │  ┌─────────────────────┐   │    │
│                          │  │  Scheduler Service  │   │    │
│                          │  │  (workmanager)      │   │    │
│                          │  └─────────────────────┘   │    │
│                          │  ┌─────────────────────┐   │    │
│                          │  │  Local DB           │   │    │
│                          │  │  (Hive / SQLite)    │   │    │
│                          │  └─────────────────────┘   │    │
│                          └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Directory Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp, theme, routing
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # IDX session times, defaults
│   │   └── indicator_defaults.dart   # All default parameter values
│   ├── errors/
│   │   └── failures.dart
│   ├── utils/
│   │   ├── date_utils.dart           # WIB timezone helpers
│   │   └── math_utils.dart           # Shared math (EMA, SMA, etc.)
│   └── extensions/
│       └── list_extensions.dart      # Rolling window helpers
│
├── data/
│   ├── models/
│   │   ├── ohlcv_bar.dart
│   │   ├── screen_result.dart
│   │   ├── ticker_config.dart
│   │   └── indicator_config.dart     # Serializable parameter model
│   ├── sources/
│   │   ├── yahoo_finance_client.dart # HTTP client
│   │   └── local_cache.dart          # Hive adapter
│   └── repositories/
│       ├── market_data_repository.dart
│       └── screen_result_repository.dart
│
├── domain/
│   ├── indicators/
│   │   ├── indicator_base.dart       # Abstract base
│   │   ├── range_filter.dart
│   │   ├── rational_quadratic_kernel.dart
│   │   ├── half_trend.dart
│   │   ├── supertrend.dart
│   │   └── ... (one file per indicator)
│   ├── screener/
│   │   ├── screener_engine.dart      # Orchestrates all indicators
│   │   ├── signal_types.dart         # Enums: BUY, SELL, NEUTRAL
│   │   └── fresh_signal_detector.dart
│   └── use_cases/
│       ├── run_screen_use_case.dart
│       └── get_cached_results_use_case.dart
│
├── blocs/
│   ├── screener/
│   │   ├── screener_bloc.dart
│   │   ├── screener_event.dart
│   │   └── screener_state.dart
│   ├── settings/
│   │   ├── settings_bloc.dart
│   │   ├── settings_event.dart
│   │   └── settings_state.dart
│   └── notification/
│       ├── notification_bloc.dart
│       └── ...
│
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart          # Results table + scan trigger
│   │   ├── settings_screen.dart      # Main settings hub
│   │   ├── indicator_config_screen.dart
│   │   ├── scheduler_screen.dart
│   │   └── ticker_universe_screen.dart
│   └── widgets/
│       ├── signal_card.dart
│       ├── indicator_param_tile.dart
│       ├── signal_badge.dart
│       └── scan_progress_indicator.dart
│
└── services/
    ├── notification_service.dart     # flutter_local_notifications wrapper
    ├── scheduler_service.dart        # workmanager wrapper
    └── background_task.dart          # Entry point for background execution
```

---

## 4. Data Layer & Yahoo Finance Integration

### 4.1 Yahoo Finance API Approach

The free Yahoo Finance endpoint used is the unofficial v8 chart API. No API key is required.

**Base URL pattern:**
```
https://query1.finance.yahoo.com/v8/finance/chart/{TICKER}
  ?interval={1d|1h|60m}
  &range={1y|3mo|6mo}
  &includePrePost=false
```

**IDX Ticker Format:** Append `.JK` suffix.  
Example: `BBCA` → `BBCA.JK`

### 4.2 Data Fetching Strategy

Because this app is on-device with no server, fetching ~900 tickers sequentially would take unacceptably long. The strategy is:

**Batch Concurrent Fetch with Rate Limiting:**

```dart
// Pseudo-code for concurrent fetching
Future<List<OhlcvData>> fetchAllTickers(List<String> tickers) async {
  const int batchSize = 20;       // 20 concurrent requests
  const Duration batchDelay = Duration(milliseconds: 500); // throttle
  
  final results = <OhlcvData>[];
  
  for (int i = 0; i < tickers.length; i += batchSize) {
    final batch = tickers.sublist(i, min(i + batchSize, tickers.length));
    final batchResults = await Future.wait(
      batch.map((t) => _fetchSingle(t).catchError((_) => null)),
    );
    results.addAll(batchResults.whereType<OhlcvData>());
    await Future.delayed(batchDelay);
  }
  return results;
}
```

### 4.3 Illiquid & Delisted Stock Filtering

A stock is **skipped** if any of the following conditions are true:

| Condition | Rule |
|---|---|
| Insufficient history | `bars.length < 150` (need enough for RQK warm-up) |
| No recent data | Last bar date is more than 7 calendar days ago |
| Zero volume streak | Last 5 bars all have `volume == 0` |
| Stale ticker | HTTP 404 or empty response from Yahoo Finance |
| Extreme low price | `close < 50` IDR (penny stocks, often illiquid) — configurable threshold |

### 4.4 Data Model

```dart
class OhlcvBar {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;
}

class TickerData {
  final String ticker;         // e.g., "BBCA"
  final List<OhlcvBar> bars;   // Chronological order, oldest first
  final DateTime fetchedAt;
}
```

### 4.5 Caching Policy

| Data Type | Cache Duration | Storage |
|---|---|---|
| OHLCV bars (daily) | 24 hours | Hive box |
| OHLCV bars (hourly) | 2 hours | Hive box |
| Ticker universe list | 7 days | Hive box |
| Screen results | Until next successful scan | Hive box |
| Indicator configs | Permanent (user-set) | SharedPreferences |

When offline, the app reads from Hive and renders the last scan results with a banner: `"Showing cached results from [timestamp]"`.

---

## 5. Indicator Engine — Pine Script to Dart Translation

**Canonical Reference:** All logic below is translated from `diy_custom_strategy.pine`. The Python prototype is for structural reference only. Where the Python and Pine Script diverge, **Pine Script wins.**

### 5.1 Shared Math Utilities

These are used by multiple indicators and should live in `core/utils/math_utils.dart`.

```dart
/// Exponential Moving Average
/// Pine Script: ta.ema(source, length)
List<double> ema(List<double> source, int length) {
  final k = 2.0 / (length + 1);
  final result = List<double>.filled(source.length, double.nan);
  
  // Seed with first non-NaN value
  int start = 0;
  while (start < source.length && source[start].isNaN) start++;
  if (start >= source.length) return result;
  
  result[start] = source[start];
  for (int i = start + 1; i < source.length; i++) {
    result[i] = source[i] * k + result[i - 1] * (1 - k);
  }
  return result;
}

/// Simple Moving Average
/// Pine Script: ta.sma(source, length)
List<double> sma(List<double> source, int length) {
  final result = List<double>.filled(source.length, double.nan);
  for (int i = length - 1; i < source.length; i++) {
    double sum = 0;
    for (int j = 0; j < length; j++) sum += source[i - j];
    result[i] = sum / length;
  }
  return result;
}

/// RMA (Wilder's Smoothing / RMA)
/// Pine Script: ta.rma(source, length)
List<double> rma(List<double> source, int length) {
  final alpha = 1.0 / length;
  final result = List<double>.filled(source.length, double.nan);
  
  // Seed with SMA
  if (source.length < length) return result;
  double sum = 0;
  for (int i = 0; i < length; i++) sum += source[i];
  result[length - 1] = sum / length;
  
  for (int i = length; i < source.length; i++) {
    result[i] = alpha * source[i] + (1 - alpha) * result[i - 1];
  }
  return result;
}

/// True Range
List<double> trueRange(List<double> high, List<double> low, List<double> close) {
  final n = high.length;
  final tr = List<double>.filled(n, 0.0);
  tr[0] = high[0] - low[0];
  for (int i = 1; i < n; i++) {
    tr[i] = [
      high[i] - low[i],
      (high[i] - close[i - 1]).abs(),
      (low[i] - close[i - 1]).abs(),
    ].reduce(math.max);
  }
  return tr;
}

/// ATR
/// Pine Script: ta.atr(length)
List<double> atr(List<double> high, List<double> low, List<double> close, int length) {
  return rma(trueRange(high, low, close), length);
}
```

### 5.2 Range Filter Indicator

**Pine Script Reference (Default type, from `diy_custom_strategy.pine`):**

```pinescript
smoothrng(x, t, m) =>
    wper = t * 2 - 1
    avrng = ta.ema(math.abs(x - x[1]), t)
    smoothrng = ta.ema(avrng, wper) * m
    smoothrng

rngfilt(x, r) =>
    rngfilt = x
    rngfilt := x > nz(rngfilt[1]) ? x - r < nz(rngfilt[1]) ? nz(rngfilt[1]) : x - r 
                                   : x + r > nz(rngfilt[1]) ? nz(rngfilt[1]) : x + r
    rngfilt
```

**Dart Implementation:**

```dart
class RangeFilterResult {
  final List<double> filterLine;
  final List<int> signal;     // 1 = bullish, -1 = bearish
  final List<double> upward;
  final List<double> downward;
}

RangeFilterResult calculateRangeFilter({
  required List<double> source,  // close
  required int period,           // default: 100
  required double multiplier,    // default: 3.0
}) {
  final n = source.length;
  
  // smoothrng: double EMA of absolute change, times multiplier
  final wper = period * 2 - 1;
  final absDiff = List<double>.generate(n, (i) => 
    i == 0 ? 0.0 : (source[i] - source[i - 1]).abs());
  final avrng = ema(absDiff, period);
  final smrng = ema(avrng, wper).map((v) => v * multiplier).toList();
  
  // rngfilt: stateful range filter
  final filt = List<double>.filled(n, source[0]);
  for (int i = 1; i < n; i++) {
    final prev = filt[i - 1];
    final r = smrng[i];
    if (source[i] > prev) {
      filt[i] = (source[i] - r < prev) ? prev : source[i] - r;
    } else {
      filt[i] = (source[i] + r > prev) ? prev : source[i] + r;
    }
  }
  
  // Direction tracking (matches Pine Script upward/downward counters)
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
  
  // Signal: rfupward / rfdownward from Pine Script
  // rfupward := src > filt and src > src[1] and upward > 0
  //          or src > filt and src < src[1] and upward > 0
  final signal = List<int>.filled(n, 0);
  for (int i = 1; i < n; i++) {
    if (source[i] > filt[i] && upward[i] > 0) {
      signal[i] = 1;
    } else if (source[i] < filt[i] && downward[i] > 0) {
      signal[i] = -1;
    }
  }
  
  return RangeFilterResult(
    filterLine: filt,
    signal: signal,
    upward: upward,
    downward: downward,
  );
}
```

**Configurable Parameters:**

| Parameter | Type | Default | UI Control |
|---|---|---|---|
| `period` | int | 100 | Slider (10–500) |
| `multiplier` | double | 3.0 | Slider (0.5–10.0, step 0.1) |
| `source` | enum | Close | Dropdown (Close, HL2, HLC3, OHLC4) |

### 5.3 Rational Quadratic Kernel (RQK)

**Pine Script Reference (from `diy_custom_strategy.pine`):**

```pinescript
kernel_regression(_rqksrc, _size, _h2) =>
    float _currentWeight = 0.
    float _cumulativeWeight = 0.
    for i = 0 to _size + x_0
        y = _rqksrc[i] 
        w = math.pow(1 + (math.pow(i, 2) / ((math.pow(_h2, 2) * 2 * r))), -r)
        _currentWeight += y*w
        _cumulativeWeight += w
    _currentWeight / _cumulativeWeight
```

**Key Pine Script Variables:**
- `h2`: Lookback Window (default: 8.0)
- `r`: Relative Weighting (default: 8.0)
- `x_0`: Start Regression at Bar (default: 25)
- `lag`: Lag for crossover detection (default: 2)

The signal is `rqkuptrend := yhat1[1] < yhat1` — the kernel line is rising.

```dart
class RQKResult {
  final List<double> yhat1;    // kernel estimate (h2 window)
  final List<double> yhat2;    // kernel estimate (h2 - lag window)
  final List<bool> uptrend;    // yhat1[i-1] < yhat1[i]
  final List<bool> downtrend;  // yhat1[i-1] > yhat1[i]
}

RQKResult calculateRQK({
  required List<double> source,
  required double lookbackWindow,  // h2, default 8.0
  required double relativeWeight,  // r,  default 8.0
  required int startBar,           // x_0, default 25
  required int lag,                // default 2
}) {
  final n = source.length;
  final yhat1 = List<double>.filled(n, double.nan);
  final yhat2 = List<double>.filled(n, double.nan);
  
  // NOTE: Pine Script iterates `for i = 0 to _size + x_0` on each bar.
  // _size is array.size(array.from(rqksrc)) = 1 in Pine Script (scalar source).
  // So effective lookback per bar = 1 + x_0 = 26 bars by default.
  // The kernel weight formula: w = (1 + i² / (h² * 2 * r))^(-r)
  
  final int effectiveLookback = 1 + startBar;
  
  double _kernelValue(int barIndex, double h) {
    double wSum = 0, vSum = 0;
    final maxLookback = math.min(effectiveLookback, barIndex + 1);
    for (int i = 0; i < maxLookback; i++) {
      final y = source[barIndex - i];
      final w = math.pow(1 + (i * i) / (h * h * 2 * relativeWeight), 
                         -relativeWeight).toDouble();
      vSum += y * w;
      wSum += w;
    }
    return wSum > 0 ? vSum / wSum : double.nan;
  }
  
  for (int i = startBar; i < n; i++) {
    yhat1[i] = _kernelValue(i, lookbackWindow);
    yhat2[i] = _kernelValue(i, lookbackWindow - lag);
  }
  
  final uptrend = List<bool>.filled(n, false);
  final downtrend = List<bool>.filled(n, false);
  for (int i = startBar + 1; i < n; i++) {
    if (!yhat1[i - 1].isNaN && !yhat1[i].isNaN) {
      uptrend[i] = yhat1[i - 1] < yhat1[i];
      downtrend[i] = yhat1[i - 1] > yhat1[i];
    }
  }
  
  return RQKResult(yhat1: yhat1, yhat2: yhat2, 
                   uptrend: uptrend, downtrend: downtrend);
}
```

**Configurable Parameters:**

| Parameter | Type | Default | UI Control |
|---|---|---|---|
| `lookbackWindow` | double | 8.0 | Slider (3–50) |
| `relativeWeight` | double | 8.0 | Slider (0.25–25, step 0.25) |
| `startBar` | int | 25 | Slider (5–50) |
| `lag` | int | 2 | Dropdown (1, 2) |

### 5.4 Half Trend

**Pine Script Reference:**

```pinescript
if respectht or leadingindicator=="Half Trend" or switch_halftrend
    ht_atr2 = ta.atr(100) / 2
    ht_dev = channelDeviation * ht_atr2
    highPrice = high[math.abs(ta.highestbars(amplitude))]
    lowPrice = low[math.abs(ta.lowestbars(amplitude))]
    highma = ta.sma(high, amplitude)
    lowma = ta.sma(low, amplitude)
    ...
    halftrend_long  := ht_trend == 0
    halftrend_short := ht_trend != 0
```

**Pine Script defaults:** `amplitude = 2`, `channelDeviation = 2`

```dart
class HalfTrendResult {
  final List<int> trend;     // 0 = long, 1 = short (matches Pine Script)
  final List<double> htLine;
  final List<bool> isLong;
  final List<bool> isShort;
}

HalfTrendResult calculateHalfTrend({
  required List<double> high,
  required List<double> low,
  required List<double> close,
  required int amplitude,         // default: 2
  required int channelDeviation,  // default: 2
}) {
  final n = close.length;
  final atrValues = atr(high, low, close, 100);
  
  // ht_dev = channelDeviation * atr(100) / 2
  final dev = List<double>.generate(n, (i) => channelDeviation * atrValues[i] / 2);
  
  // highestbars / lowestbars over amplitude
  // highPrice = high[abs(highestbars(amplitude))]
  // This finds the index of the highest high in the last `amplitude` bars
  List<double> highPrice = List<double>.filled(n, high[0]);
  List<double> lowPrice = List<double>.filled(n, low[0]);
  
  for (int i = amplitude - 1; i < n; i++) {
    double maxH = high[i], minL = low[i];
    for (int j = 0; j < amplitude; j++) {
      maxH = math.max(maxH, high[i - j]);
      minL = math.min(minL, low[i - j]);
    }
    highPrice[i] = maxH;
    lowPrice[i] = minL;
  }
  
  // SMA of high and low over amplitude
  final highma = sma(high, amplitude);
  final lowma = sma(low, amplitude);
  
  // State variables (stateful loop — cannot be vectorized)
  final trend = List<int>.filled(n, 0);
  final htUp = List<double>.filled(n, 0.0);
  final htDown = List<double>.filled(n, 0.0);
  final ht = List<double>.filled(n, 0.0);
  int nextTrend = 0;
  double maxLowPrice = low[0];
  double minHighPrice = high[0];
  
  for (int i = 1; i < n; i++) {
    if (nextTrend == 1) {
      maxLowPrice = math.max(lowPrice[i], maxLowPrice);
      if (highma[i] < maxLowPrice && close[i] < low[i - 1]) {
        trend[i] = 1;
        nextTrend = 0;
        minHighPrice = highPrice[i];
      } else {
        trend[i] = trend[i - 1];
      }
    } else {
      minHighPrice = math.min(highPrice[i], minHighPrice);
      if (lowma[i] > minHighPrice && close[i] > high[i - 1]) {
        trend[i] = 0;
        nextTrend = 1;
        maxLowPrice = lowPrice[i];
      } else {
        trend[i] = trend[i - 1];
      }
    }
    
    if (trend[i] == 0) {
      htUp[i] = (i > 0 && trend[i - 1] != 0) ? htDown[i - 1] 
                                               : math.max(maxLowPrice, (i > 0 ? htUp[i - 1] : maxLowPrice));
      ht[i] = htUp[i];
    } else {
      htDown[i] = (i > 0 && trend[i - 1] != 1) ? htUp[i - 1] 
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
```

**Configurable Parameters:**

| Parameter | Type | Default | UI Control |
|---|---|---|---|
| `amplitude` | int | 2 | Slider (1–10) |
| `channelDeviation` | int | 2 | Slider (1–10) |

### 5.5 Additional Phase-2 Indicators (Stubbed)

For Phase 2, translate in this priority order based on Pine Script usage frequency in the strategy:

1. Supertrend (`Periods=10`, `Multiplier=3.0`)
2. 2 EMA Cross
3. MACD
4. RSI (all three modes: MA Cross, OB/OS Zones, Level)
5. Stochastic
6. SSL Channel
7. Donchian Trend Ribbon
8. QQE Mod (with bug fix — see Section 12)
9. Chandelier Exit
10. ADX/DMI
11. TSI, TDFI, B-Xtrender, etc.

Each indicator must implement the abstract base:

```dart
abstract class IndicatorBase<TResult, TConfig> {
  TResult calculate(TickerData data, TConfig config);
  bool get longSignal;
  bool get shortSignal;
  String get name;
}
```

---

## 6. Screening Logic & Signal System

### 6.1 Confluence Logic

Matches the Pine Script `longCond` / `shortCond` expressions. The logic is:

```
longSignal  = leadingIndicatorLong  AND ALL enabled confirmations are long
shortSignal = leadingIndicatorShort AND ALL enabled confirmations are short
```

This is a strict AND gate. Relaxing it to a minimum-confirmation count (e.g., 2 of 3) is a Phase 2 enhancement.

```dart
class ScreenerEngine {
  final ScreenerConfig config;
  
  ScreenResult? evaluate(TickerData data) {
    // 1. Leading indicator
    final leading = _calculateLeading(data);
    if (!leading.hasSignal) return null;
    
    // 2. All enabled confirmation indicators
    final confirmations = config.enabledConfirmations
        .map((c) => _calculateConfirmation(c, data))
        .toList();
    
    final allLong = leading.isLong && 
                    confirmations.every((c) => c.isLong);
    final allShort = leading.isShort && 
                     confirmations.every((c) => c.isShort);
    
    if (!allLong && !allShort) return null;
    
    final signal = allLong ? SignalType.buy : SignalType.sell;
    
    // 3. Fresh signal detection
    if (config.freshOnly || config.freshToday) {
      final isFresh = _freshSignalDetector.check(data.ticker, signal);
      if (!isFresh) return null;
    }
    
    return ScreenResult(
      ticker: data.ticker,
      signal: signal,
      signalTime: data.bars.last.timestamp,
      closePrice: data.bars.last.close,
      changePercent: _calcChange(data.bars),
      confirmationStatus: _buildConfirmationMap(confirmations),
    );
  }
}
```

### 6.2 Fresh Signal Detection

This is the corrected implementation of the Pine Script's concept of an "alternate signal" combined with the signal expiry counter. A **fresh signal** means:

> The current signal is the first occurrence of direction X, preceded (within a lookback window) by direction -X or a neutral period. A signal that has been continuously true for many bars is NOT fresh.

```dart
class FreshSignalDetector {
  final LocalCache _cache;
  static const int maxNeutralBars = 30;

  /// Returns true if the current last-bar signal is a genuine reversal.
  bool isFreshSignal({
    required String ticker,
    required List<int> combinedSignals,  // 1=BUY, -1=SELL, 0=neutral
    required int currentSignal,
  }) {
    if (combinedSignals.length < 2) return false;
    
    final last = combinedSignals.length - 1;
    
    // Walk back to find where this signal streak started
    int signalStart = last;
    for (int i = last - 1; i >= 0; i--) {
      if (combinedSignals[i] != currentSignal) {
        signalStart = i + 1;
        break;
      }
      if (i == 0) return false; // Signal fills entire history
    }
    
    if (signalStart == last + 1) return false;
    
    // Look before signalStart for opposing signal
    int neutralCount = 0;
    for (int i = signalStart - 1; i >= 0 && i >= signalStart - 1 - maxNeutralBars; i--) {
      final s = combinedSignals[i];
      if (s == -currentSignal) {
        // Found opposing signal — this IS a fresh reversal
        return true;
      } else if (s == 0) {
        neutralCount++;
        if (neutralCount > maxNeutralBars) return false;
      } else if (s == currentSignal) {
        return false; // Same signal appeared before — not fresh
      }
    }
    return false;
  }
}
```

### 6.3 Smart Deduplication

To avoid re-notifying about the same signal across multiple scans:

```dart
class DeduplicationService {
  final LocalCache _cache;
  
  // A signal is "new" if we haven't notified about it,
  // defined by: ticker + signal direction + signal start date
  Future<bool> isNewSignal(ScreenResult result) async {
    final key = '${result.ticker}_${result.signal.name}_'
                '${result.signalTime.toIso8601String().substring(0, 10)}';
    final seen = await _cache.get<bool>(key);
    if (seen == true) return false;
    await _cache.set(key, true, ttl: const Duration(days: 7));
    return true;
  }
}
```

---

## 7. State Management Architecture

### 7.1 BLoC Pattern

All business logic flows through BLoC. The UI never talks to repositories directly.

```
ScreenerBloc
├── Events
│   ├── RunScreenEvent(config)
│   ├── StopScreenEvent
│   ├── LoadCachedResultsEvent
│   └── ClearResultsEvent
│
└── States
    ├── ScreenerInitial
    ├── ScreenerLoading(progress: double, currentTicker: String)
    ├── ScreenerSuccess(results: List<ScreenResult>, cachedAt: DateTime)
    ├── ScreenerPartialResult(results, progress)   // streaming updates
    └── ScreenerFailure(message: String)
```

```
SettingsBloc
├── Events
│   ├── LoadSettingsEvent
│   ├── UpdateLeadingIndicatorEvent(name)
│   ├── UpdateIndicatorParamEvent(indicator, param, value)
│   ├── ToggleConfirmationEvent(indicatorName, enabled)
│   ├── UpdateScheduleEvent(ScheduleConfig)
│   └── UpdateUniverseEvent(universe)
│
└── States
    ├── SettingsLoaded(config: ScreenerConfig)
    └── SettingsSaving
```

### 7.2 Screener Configuration Model

```dart
@HiveType(typeId: 0)
class ScreenerConfig {
  @HiveField(0) final String leadingIndicator;      // "Range Filter", "Supertrend", etc.
  @HiveField(1) final Map<String, IndicatorParams> indicatorParams;
  @HiveField(2) final List<String> enabledConfirmations;
  @HiveField(3) final String universe;              // "lq45", "idx80", "all"
  @HiveField(4) final String interval;              // "1d", "1h"
  @HiveField(5) final bool freshOnly;
  @HiveField(6) final bool freshToday;
  @HiveField(7) final ScheduleConfig schedule;
  @HiveField(8) final FilterConfig filters;         // liquidity thresholds
}

@HiveType(typeId: 1)
class IndicatorParams {
  // Generic key-value map for any indicator's parameters
  // Key: param name (e.g., "period", "multiplier")
  // Value: num (int or double)
  @HiveField(0) final Map<String, num> values;
}

@HiveType(typeId: 2)
class ScheduleConfig {
  @HiveField(0) final bool enabled;
  @HiveField(1) final List<int> runAtHoursWIB;  // e.g., [9, 11, 13, 15]
  @HiveField(2) final bool weekdaysOnly;
}
```

---

## 8. UI/UX Design & Wireframe Concepts

### 8.1 Navigation Structure

```
Bottom Navigation Bar
├── [Results]   Home — scan results table
├── [Settings]  Configuration — indicator & universe setup  
└── [Schedule]  Automation — scan timing & notification prefs
```

### 8.2 Screen 1: Home / Results Screen

**Layout:**
```
┌─────────────────────────────────────────────┐
│  IDX Screener             [▶ Run Scan]  [⚙] │
│─────────────────────────────────────────────│
│  [BUY ▼] [SELL ▼] [Sort: Value ▼]  [Filter]│
│─────────────────────────────────────────────│
│  ⚠ Showing cached results from 09:15 WIB   │  ← only when offline/stale
│─────────────────────────────────────────────│
│  ┌──────────────────────────────────────┐   │
│  │ 🟢 BUY  BBCA              IDR 9,350 │   │
│  │         +1.2%  Vol: 42.3B  09:00 WIB│   │
│  │         RF ✔  RQK ✔  HT ✔         │   │
│  └──────────────────────────────────────┘   │
│  ┌──────────────────────────────────────┐   │
│  │ 🔴 SELL TLKM              IDR 3,200 │   │
│  │         -0.8%  Vol: 18.1B  09:00 WIB│   │
│  │         RF ✔  RQK ✔  HT ✔         │   │
│  └──────────────────────────────────────┘   │
│  ...                                         │
│─────────────────────────────────────────────│
│  Scanned 524 stocks · 12 BUY · 8 SELL      │
│  [Results] [Settings] [Schedule]            │
└─────────────────────────────────────────────┘
```

**Tap on a result card** → Detail bottom sheet:
```
┌─────────────────────────────────────────────┐
│  BBCA — BUY Signal                      [✕] │
│─────────────────────────────────────────────│
│  Signal appeared: 26 May 2026, 09:00 WIB   │
│  Price at signal: IDR 9,350  (+1.2%)        │
│  Current price:   IDR 9,400  (+1.7%)        │
│─────────────────────────────────────────────│
│  LEADING INDICATOR                          │
│  Range Filter ......................... ✅  │
│─────────────────────────────────────────────│
│  CONFIRMATION INDICATORS                    │
│  Rational Quadratic Kernel (RQK) ...... ✅  │
│  Half Trend ........................... ✅  │
│─────────────────────────────────────────────│
│  [ Open TradingView ]  [ Add to Watchlist ] │
└─────────────────────────────────────────────┘
```

**Progress during scan:**
```
┌─────────────────────────────────────────────┐
│  Scanning IDX Universe...                   │
│  ████████████████░░░░░░░░░  65%            │
│  Fetching TLKM... (324 / 500)               │
│                          [Cancel]           │
└─────────────────────────────────────────────┘
```

### 8.3 Screen 2: Settings Screen

The settings screen mirrors the Pine Script group structure exactly.

```
┌─────────────────────────────────────────────┐
│  ← Settings                                 │
│─────────────────────────────────────────────│
│  INDICATOR SETUP                            │
│  ┌──────────────────────────────────────┐   │
│  │ Leading Indicator                    │   │
│  │ [Range Filter              ▼]        │   │  ← Dropdown, 40+ options (Phase 2)
│  │                                      │   │
│  │ Signal Expiry Candle Count: [3]      │   │  ← Int input
│  │ ☑ Alternate Signal                   │   │  ← Toggle
│  │ ☑ Show Long/Short Signal             │   │  ← Toggle
│  └──────────────────────────────────────┘   │
│                                             │
│  LEADING INDICATOR PARAMETERS  [›]          │  ← Taps into Range Filter config
│  ┌──────────────────────────────────────┐   │
│  │ Period          ━━━━●━━━━━   100     │   │  ← Slider
│  │ Multiplier      ━━━━━━●━━   3.0     │   │  ← Slider (step 0.1)
│  │ Source          [Close       ▼]      │   │  ← Dropdown
│  └──────────────────────────────────────┘   │
│                                             │
│  CONFIRMATION INDICATORS                    │
│  ┌──────────────────────────────────────┐   │
│  │ ☑ Rational Quadratic Kernel (RQK) [›]│   │  ← toggle + tap for params
│  │ ☑ Half Trend                      [›]│
│  │ ☐ Supertrend                      [›]│
│  │ ☐ EMA Filter                      [›]│
│  │ ☐ 2 EMA Cross                     [›]│
│  │ ...                                  │
│  └──────────────────────────────────────┘   │
│                                             │
│  STOCK UNIVERSE                             │
│  ┌──────────────────────────────────────┐   │
│  │ Universe: ( ) LQ45 (●) IDX80 ( ) All│
│  │ Timeframe: [Daily ▼]                 │
│  │ Min Volume (IDR): [500,000,000]      │
│  │ Min Price (IDR):  [50]               │
│  └──────────────────────────────────────┘   │
│─────────────────────────────────────────────│
│  [Results] [Settings] [Schedule]            │
└─────────────────────────────────────────────┘
```

### 8.4 Indicator Parameter Sub-Screen

Tapping `[›]` next to any indicator opens a full sub-screen for that indicator's parameters — matching all parameters defined in the Pine Script group for that indicator.

Example for RQK:
```
┌─────────────────────────────────────────────┐
│  ← RQK Parameters                          │
│─────────────────────────────────────────────│
│  Lookback Window (h)                        │
│  ━━━━━●━━━━━━━━━━━━━━   8.0               │
│  Min: 3.0  Max: 50.0  Step: 0.5            │
│                                             │
│  Relative Weighting (r)                     │
│  ━━━━━━━━●━━━━━━━━━━━   8.0               │
│  Min: 0.25  Max: 25.0  Step: 0.25          │
│                                             │
│  Start Regression at Bar                    │
│  ━━━━━━━━━━━━━●━━━━━━   25                │
│  Min: 5  Max: 50  Step: 1                  │
│                                             │
│  Lag                                        │
│  ( ) 1   (●) 2                             │
│                                             │
│  [Reset to Defaults]          [Save]        │
└─────────────────────────────────────────────┘
```

### 8.5 Screen 3: Schedule Screen

```
┌─────────────────────────────────────────────┐
│  ← Schedule & Notifications                 │
│─────────────────────────────────────────────│
│  AUTOMATED SCANNING                         │
│  ┌──────────────────────────────────────┐   │
│  │ ☑ Enable Auto-Scan                   │   │
│  │ ☑ Weekdays Only (Mon–Fri)            │   │
│  │                                      │   │
│  │ Scan Times (WIB)                     │   │
│  │ ☑ 09:00 — Market Open               │   │
│  │ ☑ 11:00 — Mid Morning               │   │
│  │ ☑ 13:30 — Post Lunch                │   │
│  │ ☑ 15:00 — Market Close              │   │
│  │ ☐ Custom: [+ Add Time]              │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  NOTIFICATION SETTINGS                      │
│  ┌──────────────────────────────────────┐   │
│  │ ☑ Notify on BUY signals              │   │
│  │ ☑ Notify on SELL signals             │   │
│  │ ☑ Smart deduplication (skip repeats) │   │
│  │                                      │   │
│  │ Quiet Hours: 15:00 – 09:00 WIB      │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  LAST SCANS                                 │
│  ┌──────────────────────────────────────┐   │
│  │ 26 May 09:00 WIB — 12 BUY, 8 SELL  │   │
│  │ 25 May 15:00 WIB — 5 BUY, 3 SELL   │   │
│  └──────────────────────────────────────┘   │
│─────────────────────────────────────────────│
│  [Results] [Settings] [Schedule]            │
└─────────────────────────────────────────────┘
```

### 8.6 Design Tokens

| Token | Value |
|---|---|
| Background | `#0D1117` (dark, TradingView-inspired) |
| Surface | `#161B22` |
| Card | `#1F2937` |
| BUY Green | `#00C853` |
| SELL Red | `#FF1744` |
| Neutral | `#78909C` |
| Text Primary | `#E6EDF3` |
| Text Secondary | `#8B949E` |
| Accent | `#2962FF` |
| Font | Inter (Google Fonts) |

---

## 9. Background Processing & Scheduling

### 9.1 Platform Constraints

| Platform | Background Mechanism | Constraint |
|---|---|---|
| Android | `WorkManager` via `flutter_workmanager` | Minimum 15-min interval; OS may defer |
| iOS | `BGTaskScheduler` via `flutter_workmanager` | OS controls exact execution timing; no guarantee |

**Critical:** iOS background execution is at the OS's discretion. The app must not rely on precise timing for iOS — it is best-effort. The user should understand that on iOS, scans may run slightly late or be batched.

### 9.2 Background Task Design

```dart
// Register at app startup (main.dart)
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    switch (taskName) {
      case 'scheduled_screen':
        await _runBackgroundScan();
        return Future.value(true);
      default:
        return Future.value(false);
    }
  });
}

Future<void> _runBackgroundScan() async {
  // 1. Load saved config from Hive
  final config = await ScreenerConfigRepository.load();
  
  // 2. Fetch data
  final marketRepo = MarketDataRepository();
  final allData = await marketRepo.fetchAll(
    universe: config.universe,
    interval: config.interval,
  );
  
  // 3. Run screener engine
  final engine = ScreenerEngine(config: config);
  final results = allData
      .map((d) => engine.evaluate(d))
      .whereType<ScreenResult>()
      .toList();
  
  // 4. Cache results
  await ScreenResultRepository.save(results, DateTime.now());
  
  // 5. Smart dedup + notify
  final dedup = DeduplicationService();
  final notifService = NotificationService();
  
  for (final result in results) {
    if (await dedup.isNewSignal(result)) {
      await notifService.showSignalNotification(result);
    }
  }
}
```

### 9.3 Scheduling Registration

```dart
class SchedulerService {
  Future<void> applySchedule(ScheduleConfig config) async {
    // Cancel all existing tasks
    await Workmanager().cancelAll();
    
    if (!config.enabled) return;
    
    // WorkManager doesn't support "run at specific clock time" natively.
    // Strategy: register a periodic task at minimum 15-min interval,
    // and gate execution inside the callback based on WIB time windows.
    
    await Workmanager().registerPeriodicTask(
      'scheduled_screen',
      'scheduled_screen',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}

// Inside the callback — gate by configured scan times
bool _shouldRunNow(ScheduleConfig config) {
  final nowWIB = DateTime.now().toUtc().add(const Duration(hours: 7));
  
  if (config.weekdaysOnly) {
    final dow = nowWIB.weekday; // 1=Mon, 7=Sun
    if (dow >= 6) return false;
  }
  
  final currentHour = nowWIB.hour;
  
  // Only run within ±7 minutes of a configured scan hour
  return config.runAtHoursWIB.any((h) => (currentHour - h).abs() <= 0 
      && nowWIB.minute < 15);
}
```

---

## 10. Notification System

### 10.1 Local Notifications (flutter_local_notifications)

Because all processing is on-device, Firebase Cloud Messaging cannot be used without a server to trigger it. The app uses **local notifications** exclusively in MVP.

```dart
class NotificationService {
  static const _channelId = 'idx_screener_signals';
  final FlutterLocalNotificationsPlugin _plugin = 
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
  }

  Future<void> showSignalNotification(ScreenResult result) async {
    final isBuy = result.signal == SignalType.buy;
    final emoji = isBuy ? '🟢' : '🔴';
    final title = '$emoji ${result.ticker} — ${result.signal.name} Signal';
    final body = 'IDR ${result.closePrice.toStringAsFixed(0)}  '
                 '${result.changePercent >= 0 ? '+' : ''}${result.changePercent.toStringAsFixed(1)}%  '
                 '${result.signalTime.hour.toString().padLeft(2, '0')}:${result.signalTime.minute.toString().padLeft(2, '0')} WIB';
    
    await _plugin.show(
      result.ticker.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, 'IDX Signals',
          importance: Importance.high,
          priority: Priority.high,
          color: isBuy ? const Color(0xFF00C853) : const Color(0xFFFF1744),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
    );
  }
  
  void _onTap(NotificationResponse response) {
    // Navigate to results screen, highlight the tapped ticker
  }
}
```

### 10.2 Notification Content Design

**Single signal notification:**
```
🟢 BBCA — BUY Signal
IDR 9,350  +1.2%  09:00 WIB
Range Filter · RQK · Half Trend ✔
```

**Batch summary (if >5 signals in one scan):**
```
📊 IDX Scan Complete — 09:00 WIB
12 BUY signals · 8 SELL signals
Tap to view results
```

---

## 11. Local Persistence & Caching

### 11.1 Hive Boxes

| Box Name | Contents | Key Type |
|---|---|---|
| `ohlcv_cache` | `Map<ticker, List<OhlcvBar>>` | String (ticker) |
| `screen_results` | `List<ScreenResult>` | `'latest'` |
| `scan_history` | `List<ScanHistoryEntry>` | DateTime string |
| `dedup_log` | `bool` (seen = true) | Composite key (see §6.3) |
| `settings` | `ScreenerConfig` | `'config'` |

### 11.2 Cache Invalidation

```dart
class OhlcvCache {
  Future<List<OhlcvBar>?> get(String ticker, String interval) async {
    final entry = await _box.get('${ticker}_$interval');
    if (entry == null) return null;
    
    final maxAge = interval == '1d' 
        ? const Duration(hours: 24) 
        : const Duration(hours: 2);
    
    if (DateTime.now().difference(entry.fetchedAt) > maxAge) {
      await _box.delete('${ticker}_$interval');
      return null; // Force re-fetch
    }
    return entry.bars;
  }
}
```

---

## 12. Known Bugs & Corrections from Reference Code

The following bugs exist in the reference files and **must be fixed** in the Dart implementation.

### Bug 1: QQE Mod — Short Signal Uses Wrong Variable (Pine Script)

**File:** `diy_custom_strategy.pine`  
**Line:** Near the QQE leading indicator assignment block.

```pinescript
// BUGGY — both long and short use isqqeabove
else if leadingindicator == 'QQE Mod'
    leadinglongcond  := isqqeabove
    leadingshortcond := isqqeabove   // ← BUG: should be isqqebelow
```

**Fix in Dart:**
```dart
case 'QQE Mod':
  leadingLong  = qqeResult.isAbove;
  leadingShort = qqeResult.isBelow;  // corrected
```

### Bug 2: Python `is_fresh_signal` — Ambiguous Signal History Edge Case

**File:** `idx_screener_fast.py`  
**Function:** `is_fresh_signal`

When the signal has been the same direction for the **entire** dataset (no prior opposing signal exists in history), the function falls through to `return False, None`. This is correct behavior — it's not fresh — but the Dart implementation must clearly document this as "insufficient history" in the UI rather than treating it as a "stale signal." The distinction matters when a stock has only recently listed.

**Dart fix:** Return a typed result:
```dart
enum FreshCheckResult { fresh, staleRepeat, insufficientHistory }
```

### Bug 3: Pine Script `ma_function` — Redundant Definition

The Pine Script defines `ma()` and `ma_function()` separately with overlapping functionality. In the Dart implementation, consolidate into a single `movingAverage(List<double> source, int length, MaType type)` function used by all indicators.

### Bug 4: Python `calculate_half_trend_vectorized` — ATR Initialization

The Python prototype initializes `high_ma` and `low_ma` as simple averages of adjacent bars rather than using `ta.sma()` as specified in Pine Script. The Dart implementation must use proper SMA of length `amplitude`.

---

## 13. Technical Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Yahoo Finance blocks on-device IP after repeated requests | Medium | High | Rate-limit to 20 concurrent, add 500ms batch delay, cache aggressively. If blocked, expose a retry-after backoff (30 min). |
| iOS background scan never executes | High | Medium | Inform user via UI banner. Recommend Android as primary device. Provide manual "Run Now" button always visible. |
| ~900 ticker scan takes >5 min on-device | Medium | Medium | Scan LQ45 (45 stocks) or IDX80 (80 stocks) as default. Only switch to "All" on explicit user request. Show partial results as they arrive. |
| RQK computation is O(n²) per ticker | Medium | Medium | Cap `effectiveLookback` at 26 bars (matching Pine Script). Pre-compute and cache kernel weights at app start. |
| Dart indicator math diverges from Pine Script | High | High | Write unit tests for each indicator against known OHLCV fixtures with Pine Script-verified expected outputs. |
| Memory pressure screening 900 stocks | Low | Medium | Process tickers in batches of 50. Dispose OHLCV arrays after computing signals. Keep only `ScreenResult` objects in memory. |
| App killed by OS during background task | Medium | Medium | Persist partial results to Hive after each batch. Resume from last-completed ticker on retry. |

---

## 14. Testing Strategy

### 14.1 Indicator Unit Tests

For each indicator, create a test file with a known OHLCV fixture (e.g., 200 bars of BBCA daily data verified against TradingView Pine Script output).

```dart
// test/domain/indicators/range_filter_test.dart
void main() {
  group('Range Filter', () {
    test('matches Pine Script output on BBCA fixture', () {
      final bars = loadFixture('bbca_daily_200.json');
      final result = calculateRangeFilter(
        source: bars.map((b) => b.close).toList(),
        period: 100,
        multiplier: 3.0,
      );
      // Last 5 filter line values verified against TradingView
      expect(result.filterLine.last, closeTo(9234.0, 1.0));
      expect(result.signal.last, equals(1)); // bullish
    });
  });
}
```

### 14.2 Fresh Signal Tests

```dart
test('detects fresh buy after sell period', () {
  final signals = [-1,-1,-1,-1,-1,0,0,1,1,1];
  final result = FreshSignalDetector().isFreshSignal(
    ticker: 'TEST',
    combinedSignals: signals,
    currentSignal: 1,
  );
  expect(result, isTrue);
});

test('does not trigger on continuous buy', () {
  final signals = [1,1,1,1,1,1,1,1,1,1];
  final result = FreshSignalDetector().isFreshSignal(
    ticker: 'TEST',
    combinedSignals: signals,
    currentSignal: 1,
  );
  expect(result, isFalse);
});
```

### 14.3 Integration Tests

- End-to-end scan of 10 known tickers verifying result structure.
- Deduplication: run same scan twice, assert no duplicate notifications on second pass.
- Cache round-trip: write OHLCV to Hive, read back, assert data integrity.

### 14.4 Manual Validation Checklist

Before any release, manually verify on TradingView:
- [ ] Range Filter signal matches for 3 random IDX tickers
- [ ] RQK uptrend/downtrend matches for 3 random IDX tickers
- [ ] Half Trend long/short matches for 3 random IDX tickers
- [ ] Fresh signal correctly identified on a ticker with known recent reversal

---

## 15. Implementation Roadmap

### Phase 0 — Foundation (Weeks 1–2)

**Goal:** Project skeleton compiles and runs. Data pipeline works end-to-end.

| Task | Details |
|---|---|
| Flutter project setup | BLoC, Hive, Dio, flutter_local_notifications packages installed |
| Directory structure | All folders and abstract base classes created |
| Yahoo Finance client | `fetchOhlcv(ticker, interval, range)` with error handling |
| OHLCV model & Hive adapter | Serialize/deserialize with type IDs |
| Ticker universe list | LQ45, IDX80, All (~900) hardcoded; Hive cache layer |
| Stock filter logic | Skip delisted, illiquid, insufficient-history stocks |
| Basic home screen | Empty results list + "Run Scan" button |

**Deliverable:** App fetches BBCA daily data and displays raw OHLCV count on screen.

---

### Phase 1 — Core Indicator Engine (Weeks 3–5)

**Goal:** Three indicators compute correct signals. Manual scan works from UI.

| Task | Details |
|---|---|
| Shared math utils | `ema`, `sma`, `rma`, `atr`, `trueRange` |
| Range Filter indicator | Full implementation + unit tests vs TradingView fixture |
| RQK indicator | Full implementation + unit tests |
| Half Trend indicator | Full implementation + unit tests |
| ScreenerEngine | AND-gate confluence logic |
| FreshSignalDetector | With full unit test suite |
| Basic results table | Shows ticker, signal, price, change % |

**Deliverable:** Can manually run a scan on LQ45 universe and see results table.

---

### Phase 2 — Settings UI & Dynamic Parameters (Weeks 6–8)

**Goal:** Every indicator parameter is configurable from the UI. Config persists across restarts.

| Task | Details |
|---|---|
| SettingsBloc | Full implementation with Hive persistence |
| Leading indicator selector | Dropdown with all 3 MVP indicators |
| Indicator param screen | Sliders, dropdowns, number inputs for each indicator |
| Confirmation indicators multi-select | Toggle list with per-indicator param drill-down |
| Universe & filter settings | LQ45/IDX80/All, min volume, min price, timeframe |
| Config reset to defaults | Per-indicator and global reset |
| ScreenerConfig serialization | Full Hive round-trip with migration support |

**Deliverable:** All indicator parameters adjustable from UI, persisted across app restarts.

---

### Phase 3 — Scheduling & Notifications (Weeks 9–10)

**Goal:** App auto-scans during IDX market hours and notifies on fresh signals.

| Task | Details |
|---|---|
| NotificationService | init, permissions, showSignalNotification, batch summary |
| WorkManager integration | Register periodic task, Android & iOS setup |
| WIB time-gate logic | Only execute within configured scan hours |
| Schedule settings UI | Checkboxes for scan times, quiet hours |
| Smart deduplication | Hive-backed seen-key store with 7-day TTL |
| Scan history log | Last 10 scans with timestamp and counts |
| Notification tap routing | Opens app and highlights relevant ticker |

**Deliverable:** App auto-scans at 09:00 WIB and sends local notification for fresh BUY/SELL signals.

---

### Phase 4 — Polish & Reliability (Weeks 11–12)

**Goal:** Production-quality UX, offline resilience, and performance.

| Task | Details |
|---|---|
| Offline mode | Cached results banner, graceful degradation |
| Partial results streaming | Show results as they arrive during scan |
| Concurrency optimization | Batch fetch with rate limiting, memory management |
| Progress indicator | Per-ticker progress during manual scan |
| Error handling | Network timeout, YF rate limit, empty results |
| Dark theme polish | Design token implementation, consistent spacing |
| TradingView deep link | "Open in TradingView" from result detail sheet |
| Performance profiling | Ensure <3 min for LQ45, <15 min for all-IDX on mid-range Android |

**Deliverable:** Stable, polished app ready for daily personal use.

---

### Phase 5 — Extended Indicators (Weeks 13–18)

Add all remaining Pine Script indicators in priority order:

| Week | Indicators |
|---|---|
| 13 | Supertrend, 2 EMA Cross, EMA Filter |
| 14 | MACD (crossover + zero-line modes), SSL Channel |
| 15 | RSI (all 3 modes + MA direction + limits) |
| 16 | Stochastic (all 3 modes), Donchian Trend Ribbon |
| 17 | QQE Mod (with bug fix), Chandelier Exit, ADX/DMI |
| 18 | TSI, TDFI, B-Xtrender, WolfPack, VWAP |

Each indicator follows the same pattern: implement → unit test vs TradingView → integrate into ScreenerEngine → expose params in Settings UI.

---

### Phase 6 — Advanced Features (Post-MVP, Future)

| Feature | Notes |
|---|---|
| Telegram notification channel | Requires Telegram Bot setup; no server needed (Telegram Bot API is HTTP) |
| Minimum-N confirmation mode | "Pass if at least N of M indicators agree" instead of strict AND |
| Watchlist screen | Pin specific tickers for priority monitoring |
| Signal history chart | Timeline of signals per ticker |
| OR logic between confirmation groups | E.g., (RSI OR MACD) AND (Supertrend) |
| Custom indicator scripting | Free-form parameter expression (very long term) |

---

## 16. Flutter Package Manifest

```yaml
# pubspec.yaml (relevant dependencies)
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.4
  equatable: ^2.0.5

  # HTTP
  dio: ^5.4.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2

  # Background Tasks
  workmanager: ^0.5.2

  # Notifications
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.2             # For WIB timezone handling

  # UI
  google_fonts: ^6.1.0
  fl_chart: ^0.67.0            # Phase 4+: signal history chart

  # Utilities
  intl: ^0.19.0
  collection: ^1.18.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
```

**Note on Compute Isolation:** For the screening engine, use Flutter's `compute()` function to run indicator calculations on a separate isolate, preventing UI jank during scans:

```dart
final results = await compute(_runScreenerIsolate, SerializableScreenerInput(
  tickerDataList: allData,
  config: config,
));
```

---

*End of Document*

**Version History:**

| Version | Date | Notes |
|---|---|---|
| 1.0 | May 2026 | Initial PRD — single-user, on-device, 3-indicator MVP |
