"""
Indonesian Stock Screener - FAST VERSION
=========================================
Optimized screener with parallel data fetching and concurrent processing.
Screens all Indonesian stocks (~900) based on confluence of three indicators:
1. Range Filter - Identifies trend direction using smooth range bands
2. Rational Quadratic Kernel (Nadaraya-Watson) - Kernel regression for major trend
3. Half Trend - Amplitude-based trend algorithm

Performance Improvements:
- Batch data download using yfinance threads
- Concurrent stock processing with ThreadPoolExecutor
- Vectorized indicator calculations
- Progress bar with tqdm

Author: Senior Python Quant Developer
Target: Indonesian Stock Exchange (IDX)
"""

import pandas as pd
import numpy as np
import yfinance as yf
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import warnings
import argparse

# Optional: tqdm for progress bar
try:
    from tqdm import tqdm
    TQDM_AVAILABLE = True
except ImportError:
    TQDM_AVAILABLE = False

# Import ticker lists
from idx_tickers import get_ticker_universe, LQ45_TICKERS

warnings.filterwarnings('ignore')


# ============================================================================
# VECTORIZED INDICATOR CALCULATIONS
# ============================================================================

def calculate_range_filter_vectorized(close: np.ndarray, high: np.ndarray, 
                                       low: np.ndarray, period: int = 100, 
                                       multiplier: float = 3.0) -> tuple:
    """
    Vectorized Range Filter Indicator.
    
    Returns:
    --------
    Tuple of (rf_value, rf_signal)
    """
    n = len(close)
    
    # Calculate True Range (vectorized where possible)
    true_range = np.zeros(n)
    true_range[0] = high[0] - low[0]
    
    prev_close = np.roll(close, 1)
    prev_close[0] = close[0]
    
    tr1 = high - low
    tr2 = np.abs(high - prev_close)
    tr3 = np.abs(low - prev_close)
    true_range = np.maximum(tr1, np.maximum(tr2, tr3))
    true_range[0] = high[0] - low[0]
    
    # EMA of True Range (vectorized using cumulative approach)
    alpha = 2 / (period + 1)
    smooth_range = np.zeros(n)
    smooth_range[0] = true_range[0]
    
    for i in range(1, n):
        smooth_range[i] = alpha * true_range[i] + (1 - alpha) * smooth_range[i-1]
    
    # Apply multiplier
    range_size = smooth_range * multiplier
    
    # Calculate Range Filter Value
    rf_value = np.zeros(n)
    rf_value[0] = close[0]
    
    for i in range(1, n):
        upper = rf_value[i-1] + range_size[i]
        lower = rf_value[i-1] - range_size[i]
        
        if close[i] > upper:
            rf_value[i] = close[i] - range_size[i]
        elif close[i] < lower:
            rf_value[i] = close[i] + range_size[i]
        else:
            rf_value[i] = rf_value[i-1]
    
    # Generate signal
    rf_signal = np.where(close > rf_value, 1, -1)
    
    return rf_value, rf_signal


def calculate_kernel_regression_vectorized(close: np.ndarray, lookback: int = 50,
                                            relative_weight: float = 1.0,
                                            start_bar: int = 25) -> tuple:
    """
    Optimized Rational Quadratic Kernel Regression.
    Pre-compute kernel weights for efficiency.
    
    Returns:
    --------
    Tuple of (kernel_value, kernel_slope)
    """
    n = len(close)
    kernel_value = np.full(n, np.nan)
    
    # Pre-compute kernel weights (they only depend on distance, not data)
    distances = np.arange(lookback)
    weights = np.power(1 + (distances ** 2) / (2 * relative_weight * (lookback ** 2)), -relative_weight)
    
    # Calculate kernel regression for each bar
    for i in range(start_bar, n):
        effective_lookback = min(lookback, i)
        w = weights[:effective_lookback]
        v = close[i-effective_lookback+1:i+1][::-1][:effective_lookback]
        
        weight_sum = np.sum(w)
        if weight_sum > 0:
            kernel_value[i] = np.sum(w * v) / weight_sum
    
    # Calculate slope (vectorized)
    kernel_slope = np.zeros(n)
    kernel_slope[1:] = np.diff(kernel_value)
    kernel_slope[np.isnan(kernel_value)] = 0
    
    return kernel_value, kernel_slope


def calculate_half_trend_vectorized(close: np.ndarray, high: np.ndarray,
                                     low: np.ndarray, amplitude: int = 2) -> tuple:
    """
    Optimized Half Trend Indicator.
    
    Returns:
    --------
    Tuple of (ht_trend, ht_value)
    """
    n = len(close)
    atr_period = 100
    
    # Calculate True Range
    prev_close = np.roll(close, 1)
    prev_close[0] = close[0]
    
    tr1 = high - low
    tr2 = np.abs(high - prev_close)
    tr3 = np.abs(low - prev_close)
    tr = np.maximum(tr1, np.maximum(tr2, tr3))
    tr[0] = high[0] - low[0]
    
    # ATR using cumsum for efficiency
    atr = np.zeros(n)
    cumsum = np.cumsum(tr)
    
    for i in range(n):
        if i < atr_period - 1:
            atr[i] = cumsum[i] / (i + 1)
        else:
            atr[i] = (cumsum[i] - cumsum[i - atr_period]) / atr_period
    
    # Half Trend calculation
    trend = np.zeros(n)
    ht_value = np.zeros(n)
    dev = amplitude * atr / 2
    
    # Moving averages of high and low
    high_ma = np.zeros(n)
    low_ma = np.zeros(n)
    high_ma[0] = high[0]
    low_ma[0] = low[0]
    high_ma[1:] = (high[1:] + high[:-1]) / 2
    low_ma[1:] = (low[1:] + low[:-1]) / 2
    
    # Initialize
    trend[0] = 1 if close[0] >= (high[0] + low[0]) / 2 else -1
    ht_value[0] = (high[0] + low[0]) / 2
    
    # Calculate trend (still requires loop due to state dependency)
    for i in range(1, n):
        high_half = high_ma[i] - dev[i]
        low_half = low_ma[i] + dev[i]
        
        if trend[i-1] == 1:
            new_ht = max(ht_value[i-1], low_half)
            if close[i] < new_ht - dev[i]:
                trend[i] = -1
                ht_value[i] = high_half
            else:
                trend[i] = 1
                ht_value[i] = new_ht
        else:
            new_ht = min(ht_value[i-1], high_half)
            if close[i] > new_ht + dev[i]:
                trend[i] = 1
                ht_value[i] = low_half
            else:
                trend[i] = -1
                ht_value[i] = new_ht
    
    return trend, ht_value


# ============================================================================
# SCREENING FUNCTION
# ============================================================================

def get_combined_signal(rf_signal: np.ndarray, kernel_slope: np.ndarray, 
                         ht_trend: np.ndarray) -> np.ndarray:
    """
    Calculate the combined signal based on all three indicators.
    
    Returns:
    --------
    np.ndarray: 1 for BUY, -1 for SELL, 0 for neutral
    """
    n = len(rf_signal)
    combined = np.zeros(n)
    
    for i in range(n):
        if np.isnan(kernel_slope[i]):
            combined[i] = 0
        elif rf_signal[i] == 1 and kernel_slope[i] > 0 and ht_trend[i] == 1:
            combined[i] = 1  # BUY
        elif rf_signal[i] == -1 and kernel_slope[i] < 0 and ht_trend[i] == -1:
            combined[i] = -1  # SELL
        else:
            combined[i] = 0  # Neutral
    
    return combined


def is_fresh_signal(combined_signals: np.ndarray, current_signal: int, max_neutral_bars: int = 30) -> tuple:
    """
    Check if the current signal is a fresh reversal signal.
    
    A signal is considered a "fresh reversal" if:
    - Current bar has a BUY signal, and within the last few bars there was a SELL signal
    - Current bar has a SELL signal, and within the last few bars there was a BUY signal
    - The opposing signal must be within max_neutral_bars of the signal start
    
    Parameters:
    -----------
    combined_signals : Array of combined signals (1=BUY, -1=SELL, 0=neutral)
    current_signal : The current signal to check (1 or -1)
    max_neutral_bars : Maximum neutral bars allowed between opposing signal and current signal
    
    Returns:
    --------
    tuple: (is_fresh: bool, signal_start_index: int or None)
           signal_start_index is the index where the fresh signal first appeared
    """
    if len(combined_signals) < 2:
        return True, len(combined_signals) - 1
    
    # Find the first bar where this signal started (looking backwards)
    signal_start_idx = len(combined_signals) - 1
    
    # Walk backwards to find where this signal streak started
    for i in range(len(combined_signals) - 2, -1, -1):
        if combined_signals[i] != current_signal:
            signal_start_idx = i + 1
            break
    else:
        # Signal has been the same for all bars
        return False, None
    
    # Now check what came before signal_start_idx - we need an opposing signal within max_neutral_bars
    # Count neutral bars and look for opposing signal
    neutral_count = 0
    for i in range(signal_start_idx - 1, max(signal_start_idx - 1 - max_neutral_bars - 1, -1), -1):
        if combined_signals[i] == -current_signal:
            # Found opposing signal within the allowed range - this is a true reversal!
            return True, signal_start_idx
        elif combined_signals[i] == 0:
            neutral_count += 1
            if neutral_count > max_neutral_bars:
                # Too many neutral bars, not a fresh reversal
                return False, None
        elif combined_signals[i] == current_signal:
            # Found same signal before, not fresh
            return False, None
    
    # No opposing signal found within the lookback range
    return False, None


def screen_single_stock(ticker: str, data_dict: dict, fresh_only: bool = False, fresh_today: bool = False) -> dict:
    """
    Screen a single stock using pre-downloaded data.
    
    Parameters:
    -----------
    ticker : Stock ticker symbol
    data_dict : Dict mapping ticker to DataFrame with OHLCV data
    fresh_only : Only return signals that are fresh (first after opposing signal)
    fresh_today : Only return fresh signals that appeared on the latest bar
    
    Returns:
    --------
    Dict with screening results or None if doesn't pass
    """
    try:
        # Get pre-downloaded data
        if ticker not in data_dict or data_dict[ticker] is None:
            return None
        
        df = data_dict[ticker]
        
        if df.empty or len(df) < 100:
            return None
        
        # Extract arrays
        close = df['Close'].values
        high = df['High'].values
        low = df['Low'].values
        volume = df['Volume'].values
        
        # Calculate indicators
        rf_value, rf_signal = calculate_range_filter_vectorized(close, high, low)
        kernel_value, kernel_slope = calculate_kernel_regression_vectorized(close)
        ht_trend, ht_value = calculate_half_trend_vectorized(close, high, low)
        
        # Get latest values
        rf_signal_latest = int(rf_signal[-1])
        kernel_slope_latest = kernel_slope[-1]
        ht_trend_latest = int(ht_trend[-1])
        close_price = close[-1]
        latest_volume = int(volume[-1]) if not np.isnan(volume[-1]) else 0
        
        # Calculate price change percentage
        if len(close) >= 2 and close[-2] != 0:
            change_pct = ((close[-1] - close[-2]) / close[-2]) * 100
        else:
            change_pct = 0.0
        
        # Check if kernel_slope is valid
        if np.isnan(kernel_slope_latest):
            return None
        
        # Screening conditions
        rf_bullish = rf_signal_latest == 1
        rf_bearish = rf_signal_latest == -1
        kernel_rising = kernel_slope_latest > 0
        kernel_falling = kernel_slope_latest < 0
        ht_bullish = ht_trend_latest == 1
        ht_bearish = ht_trend_latest == -1
        
        # Helper function to format signal time
        def format_signal_time(idx):
            signal_time = df.index[idx]
            if hasattr(signal_time, 'tz_localize'):
                # If naive datetime, localize to UTC first
                if signal_time.tzinfo is None:
                    signal_time = signal_time.tz_localize('UTC')
                # Convert to Indonesia Time (WIB)
                signal_time = signal_time.tz_convert('Asia/Jakarta')
                return signal_time.strftime('%Y-%m-%d %H:%M WIB')
            elif hasattr(signal_time, 'strftime'):
                return signal_time.strftime('%Y-%m-%d %H:%M')
            else:
                return str(signal_time)
        
        # Calculate combined signals for fresh detection
        if fresh_only or fresh_today:
            combined_signals = get_combined_signal(rf_signal, kernel_slope, ht_trend)
        
        # BUY signal: All conditions bullish
        if rf_bullish and kernel_rising and ht_bullish:
            # Check if fresh signal is required
            if fresh_only or fresh_today:
                is_fresh, signal_start_idx = is_fresh_signal(combined_signals, 1)
                if not is_fresh:
                    return None
                # For fresh_today, only show if signal started on the latest bar
                if fresh_today and signal_start_idx != len(combined_signals) - 1:
                    return None
                # Use the actual signal start time
                signal_time_str = format_signal_time(signal_start_idx)
                signal_close = round(close[signal_start_idx], 2)
                signal_volume = int(volume[signal_start_idx]) if not np.isnan(volume[signal_start_idx]) else 0
                # Change % from the bar before signal started
                if signal_start_idx >= 1 and close[signal_start_idx - 1] != 0:
                    signal_change_pct = round(((close[signal_start_idx] - close[signal_start_idx - 1]) / close[signal_start_idx - 1]) * 100, 2)
                else:
                    signal_change_pct = 0.0
            else:
                signal_time_str = format_signal_time(-1)
                signal_close = round(close_price, 2)
                signal_volume = latest_volume
                signal_change_pct = round(change_pct, 2)
            
            return {
                'Ticker': ticker.replace('.JK', ''),
                'Signal': 'BUY',
                'Signal Time': signal_time_str,
                'Close Price': signal_close,
                'Change %': signal_change_pct,
                'Value': float(signal_close * signal_volume),
                'Range Filter': 'Bullish',
                'Kernel Slope': round(kernel_slope_latest, 4),
                'Half Trend': 'Long'
            }
        
        # SELL signal: All conditions bearish
        if rf_bearish and kernel_falling and ht_bearish:
            # Check if fresh signal is required
            if fresh_only or fresh_today:
                is_fresh, signal_start_idx = is_fresh_signal(combined_signals, -1)
                if not is_fresh:
                    return None
                # For fresh_today, only show if signal started on the latest bar
                if fresh_today and signal_start_idx != len(combined_signals) - 1:
                    return None
                # Use the actual signal start time
                signal_time_str = format_signal_time(signal_start_idx)
                signal_close = round(close[signal_start_idx], 2)
                signal_volume = int(volume[signal_start_idx]) if not np.isnan(volume[signal_start_idx]) else 0
                # Change % from the bar before signal started
                if signal_start_idx >= 1 and close[signal_start_idx - 1] != 0:
                    signal_change_pct = round(((close[signal_start_idx] - close[signal_start_idx - 1]) / close[signal_start_idx - 1]) * 100, 2)
                else:
                    signal_change_pct = 0.0
            else:
                signal_time_str = format_signal_time(-1)
                signal_close = round(close_price, 2)
                signal_volume = latest_volume
                signal_change_pct = round(change_pct, 2)
            
            return {
                'Ticker': ticker.replace('.JK', ''),
                'Signal': 'SELL',
                'Signal Time': signal_time_str,
                'Close Price': signal_close,
                'Change %': signal_change_pct,
                'Value': float(signal_close * signal_volume),
                'Range Filter': 'Bearish',
                'Kernel Slope': round(kernel_slope_latest, 4),
                'Half Trend': 'Short'
            }
        
        return None
        
    except Exception:
        return None


def download_data_batch(tickers: list, period: str = '1y', interval: str = '1d') -> dict:
    """
    Download data for all tickers in a single batch request.
    
    Parameters:
    -----------
    tickers : List of ticker symbols
    period : Data period (default: '1y' for daily, '60d' recommended for hourly)
    interval : Data interval - '1d' for daily, '1h' for hourly (default: '1d')
    
    Returns:
    --------
    Dict mapping ticker to DataFrame
    """
    print(f"Downloading {interval} data for {len(tickers)} stocks (period: {period})...")
    
    try:
        # Download all at once with threading
        data = yf.download(
            tickers=tickers,
            period=period,
            interval=interval,
            group_by='ticker',
            threads=True,
            progress=True
        )
        
        # Parse into individual DataFrames
        data_dict = {}
        
        if len(tickers) == 1:
            # Single ticker returns different format
            if not data.empty:
                data_dict[tickers[0]] = data
        else:
            for ticker in tickers:
                try:
                    if ticker in data.columns.get_level_values(0):
                        df = data[ticker].dropna()
                        if len(df) >= 100:
                            data_dict[ticker] = df
                except Exception:
                    pass
        
        print(f"Successfully downloaded data for {len(data_dict)} stocks")
        return data_dict
        
    except Exception as e:
        print(f"Batch download failed: {e}")
        return {}


def run_screener_fast(universe: str = 'all', 
                      max_workers: int = 10,
                      interval: str = '1d',
                      fresh_only: bool = False,
                      fresh_today: bool = False,
                      verbose: bool = True) -> pd.DataFrame:
    """
    Run the optimized screening process.
    
    Parameters:
    -----------
    universe : 'lq45', 'idx80', or 'all'
    max_workers : Number of concurrent workers for processing
    interval : Data interval - '1d' for daily, '1h' for hourly
    fresh_only : Only show signals that appear first after opposing signals
    fresh_today : Only show fresh signals that appeared on the latest bar
    verbose : Print progress messages
    
    Returns:
    --------
    DataFrame with stocks that passed the screening
    """
    # Get tickers
    tickers = get_ticker_universe(universe)
    
    # Set appropriate period based on interval
    # Hourly data limited to 730 days max by yfinance
    if interval == '1h':
        period = '60d'  # 60 days of hourly data
    elif interval in ['5m', '15m', '30m']:
        period = '30d'  # 30 days for minute data
    else:
        period = '1y'   # 1 year for daily data
    
    if verbose:
        print("=" * 60)
        print("INDONESIAN STOCK SCREENER (FAST)")
        print("Confluence: Range Filter + Kernel Regression + Half Trend")
        print("=" * 60)
        print(f"\nUniverse: {universe.upper()} ({len(tickers)} stocks)")
        print(f"Timeframe: {interval.upper()} (period: {period})")
        if fresh_today:
            print("Filter: Fresh signals today only (signal appeared on latest bar)")
        elif fresh_only:
            print("Filter: Fresh signals only (first after opposing signal)")
    
    # Batch download all data
    start_time = datetime.now()
    data_dict = download_data_batch(tickers, period=period, interval=interval)
    download_time = (datetime.now() - start_time).total_seconds()
    
    if verbose:
        print(f"Download completed in {download_time:.1f}s")
        print(f"\nScreening stocks...")
    
    # Screen all stocks concurrently
    results = []
    process_start = datetime.now()
    
    if TQDM_AVAILABLE and verbose:
        # With progress bar
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = {
                executor.submit(screen_single_stock, ticker, data_dict, fresh_only, fresh_today): ticker 
                for ticker in tickers
            }
            
            for future in tqdm(as_completed(futures), total=len(futures), 
                              desc="Screening", unit="stock"):
                result = future.result()
                if result:
                    results.append(result)
    else:
        # Without progress bar
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = {
                executor.submit(screen_single_stock, ticker, data_dict, fresh_only, fresh_today): ticker 
                for ticker in tickers
            }
            
            completed = 0
            for future in as_completed(futures):
                result = future.result()
                if result:
                    results.append(result)
                completed += 1
                if verbose and completed % 50 == 0:
                    print(f"  Processed {completed}/{len(futures)} stocks...")
    
    process_time = (datetime.now() - process_start).total_seconds()
    total_time = (datetime.now() - start_time).total_seconds()
    
    # Create results DataFrame
    if results:
        results_df = pd.DataFrame(results)
        # Sort by Value (descending)
        results_df = results_df.sort_values('Value', ascending=False).reset_index(drop=True)
        # Add number separator
        results_df['Value'] = results_df['Value'].apply(lambda x: f"{int(x):,}")
    else:
        results_df = pd.DataFrame(columns=[
            'Ticker', 'Signal', 'Signal Time', 'Close Price', 'Change %',
            'Value', 'Range Filter', 'Kernel Slope', 'Half Trend'
        ])
    
    if verbose:
        print("\n" + "=" * 60)
        print(f"SCREENING COMPLETE")
        buy_count = len(results_df[results_df['Signal'] == 'BUY']) if len(results_df) > 0 else 0
        sell_count = len(results_df[results_df['Signal'] == 'SELL']) if len(results_df) > 0 else 0
        print(f"Downloaded: {len(data_dict)} | Screened: {len(tickers)} | Passed: {len(results)} (BUY: {buy_count}, SELL: {sell_count})")
        print(f"Time: Download {download_time:.1f}s | Process {process_time:.1f}s | Total {total_time:.1f}s")
        print("=" * 60)
    
    return results_df


# ============================================================================
# MAIN EXECUTION
# ============================================================================
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Indonesian Stock Screener (Fast)')
    parser.add_argument('--universe', type=str, default='all',
                        choices=['lq45', 'idx80', 'all'],
                        help='Stock universe to screen (default: all)')
    parser.add_argument('--workers', type=int, default=10,
                        help='Number of concurrent workers (default: 10)')
    parser.add_argument('--interval', type=str, default='1d',
                        choices=['1h', '1d'],
                        help='Data interval: 1h=hourly, 1d=daily (default: 1d)')
    parser.add_argument('--fresh-only', action='store_true',
                        help='Show only fresh signals (first appearance after opposing signal)')
    parser.add_argument('--fresh-today', action='store_true',
                        help='Show only fresh signals that appeared on the latest bar (today)')
    
    args = parser.parse_args()
    
    # Run the screener
    results = run_screener_fast(universe=args.universe, max_workers=args.workers, 
                                interval=args.interval, fresh_only=args.fresh_only,
                                fresh_today=args.fresh_today)
    
    pd.set_option('display.max_columns', None)
    pd.set_option('display.width', None)
    
    # Separate BUY and SELL signals
    buy_signals = results[results['Signal'] == 'BUY'] if len(results) > 0 else pd.DataFrame()
    sell_signals = results[results['Signal'] == 'SELL'] if len(results) > 0 else pd.DataFrame()
    
    print("\n" + "=" * 60)
    print("BUY SIGNALS (Sorted by Value)")
    print("=" * 60)
    if len(buy_signals) > 0:
        print(buy_signals.to_string(index=False))
    else:
        print("\nNo stocks with BUY signals at this time.")
    
    print("\n" + "=" * 60)
    print("SELL SIGNALS (Sorted by Value)")
    print("=" * 60)
    if len(sell_signals) > 0:
        print(sell_signals.to_string(index=False))
    else:
        print("\nNo stocks with SELL signals at this time.")
    
    print("\n" + "=" * 60)
    print("Screening Date:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    print("=" * 60)
