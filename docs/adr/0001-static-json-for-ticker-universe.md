# Static JSON for Ticker Universe

The app will fetch the LQ45/IDX80 ticker universe from a static `tickers.json` hosted on GitHub Pages (for this repository), rather than hardcoding it or fetching it directly from the IDX website. This decouples the 6-monthly index composition updates from app store releases, while avoiding the CORS issues, rate limits, and unannounced API changes associated with fetching directly from the official IDX website. The fetched list will be cached locally in Hive with a 7-day TTL.
