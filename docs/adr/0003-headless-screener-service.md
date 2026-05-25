# Headless Screener Service for Orchestration

To support both manual UI-triggered scans and headless background scans (via `workmanager`), the core screening orchestration logic (fetch OHLCV → filter → run indicators → dedup → persist) is extracted into a pure `ScreenerService` rather than being housed inside a `ScreenerCubit`. 

Because Cubits are tied to the UI isolate and lifecycle, placing the logic there would prevent the background isolate from running scans. With a headless `ScreenerService`, both the UI and background workers can trigger scans uniformly. UI components (like `ResultsCubit`) will decouple from the scan trigger and instead reactively update by listening to the Hive `results_box` streams.
