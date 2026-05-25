# Hive Caching Schema with Read-Time TTL

Hive is a key-value store without native Time-To-Live (TTL) capabilities. To satisfy the various caching durations required by the app (24h for daily OHLCV, 7d for tickers/dedup, etc.), we will wrap all cached payloads in a `CacheEntry<T>` class that contains a `createdAt` timestamp. 

TTL enforcement will happen dynamically at read-time in the Repository layer: if an entry's age exceeds the allowed policy duration, it will be deleted and treated as a cache miss.

We will use separate Hive boxes for structurally different data to keep serialization simple:
- `universe_box`: List of stock tickers.
- `ohlcv_box`: Serialized OHLCV data, keyed by `ticker_timeframe` (e.g., `BBCA.JK_1d`).
- `results_box`: The latest screener results (Signals).
- `dedup_box`: Simple booleans keyed by `ticker_signal_date` for fresh signal deduplication.
