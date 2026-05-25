# Screener Logic Prototype

**Question:** Do the translated Dart indicator implementations produce BUY/SELL signals equivalent to the Pine Script reference (`reference/diy_custom_strategy.pine`) when fed the same OHLCV data?

## Run

```bash
dart run
```

## Structure

```
lib/
  math_utils.dart    — EMA, SMA, RMA, WMA, VWMA, HMA, TEMA, ATR, TR
  models.dart        — OHLCV data model, configs, signal types
  indicator_engine.dart — All 40+ indicator implementations
  signal_engine.dart — Leading + confirmation AND gate, alternate signal, expiry
bin/
  main.dart          — TUI: interactive bar stepping, mock data
```

## What this tests

1. Pine Script indicator math faithfully translated to Dart
2. Stateful indicators (Half Trend, SuperTrend, Chandelier Exit) handle state correctly
3. Signal combination AND gate works with all indicators
4. Alternate signal detection + expiry count logic
5. Fresh signal detection (first bar of new direction)

## Status

PROTOTYPE — throwaway. Validated logic will be lifted into `lib/domain/indicators/`.
