# IDX Stock Screener — Domain Context

## Product

Cross-platform Flutter mobile app (Android & iOS) for screening Indonesian Stock Exchange (IDX) equities using technical indicators. Runs entirely on-device — no backend server, no cloud functions.

## Target user

Solo swing trader who configures screening parameters through a rich UI, schedules automated scans during IDX market hours, and receives local push notifications on fresh confluence signals.

## Source of Truth

The Pine Script file `diy_custom_strategy.pine` is the canonical reference for all indicator logic. All Dart implementations must be validated against Pine Script behavior, not against the Python prototype.

## Glossary

| Term | Definition |
| ---- | ---------- |
| IDX | Indonesian Stock Exchange (Bursa Efek Indonesia) |
| WIB | Western Indonesian Time (UTC+7), used for market hours and scheduling |
| IDX market hours | 09:00–15:00 WIB |
| Ticker | Stock symbol on IDX, appended with `.JK` for Yahoo Finance API (e.g. BBCA → BBCA.JK) |
| LQ45 | Universe of top 45 most liquid IDX stocks |
| IDX80 | Universe of top 80 IDX stocks |
| OHLCV | Open, High, Low, Close, Volume — per-bar market data |
| Range Filter | Primary technical indicator with period (default 100) and multiplier (default 3.0) |
| RQK | Rational Quadratic Kernel regression indicator — lookbackWindow (8.0), relativeWeight (8.0), startBar (25), lag (2) |
| Half Trend | Trend-following indicator — amplitude (2), channelDeviation (2) |
| Leading Indicator | Primary indicator driving the signal direction |
| Confirmation Indicator | Secondary indicators using AND-gate confluence with the leading indicator |
| Fresh Signal | First reversal signal after an opposing direction period; deduplicated to notify only once |
| Confluence | ALL enabled confirmation indicators must agree with the leading indicator direction |
| Signal types | BUY (long), SELL (short), NEUTRAL |

## Architecture pattern

BLoC (Business Logic Component) for state management. UI never talks to repositories directly. Core services: Indicator Engine (pure Dart), Yahoo Finance HTTP Client, Scheduler Service (workmanager), Local DB (Hive).

## Data flow

1. Fetch OHLCV from Yahoo Finance v8 chart API (batch concurrent, 20 at a time, 500ms throttle)
2. Filter out illiquid/delisted stocks (volume=0, insufficient history <150 bars, stale data >7 days, price <50 IDR)
3. Run indicators via ScreenerEngine (leading + confirmations AND gate)
4. Check fresh signal detection (reversal from opposing direction)
5. Smart deduplication (ticker + signal + date composite key, 7-day TTL)
6. Persist results to Hive, fire local notification

## Cache policy

| Data | Duration | Storage |
| ---- | -------- | ------- |
| OHLCV daily | 24h | Hive |
| OHLCV hourly | 2h | Hive |
| Ticker universe | 7d | Hive |
| Screen results | Until next successful scan | Hive |
| Indicator configs | Permanent | SharedPreferences |

## Known bugs to fix in Dart

1. QQE Mod short signal uses wrong variable in Pine Script (`isqqeabove` instead of `isqqebelow`)
2. Fresh signal detection needs typed `FreshCheckResult` enum (fresh / staleRepeat / insufficientHistory)
3. Consolidate Pine Script's redundant `ma()` and `ma_function()` into one Dart `movingAverage()`
4. Half Trend must use proper `sma()` not adjacent-bar averaging (Python bug)
