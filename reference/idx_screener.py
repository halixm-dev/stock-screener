"""
Indonesian Stock Screener (LQ45)
================================
Screens Indonesian stocks based on a confluence of three custom indicators:
1. Range Filter - Identifies trend direction using smooth range bands
2. Rational Quadratic Kernel (Nadaraya-Watson) - Kernel regression for major trend
3. Half Trend - Amplitude-based trend algorithm

Author: Senior Python Quant Developer
Target: Indonesian Stock Exchange (IDX) - LQ45 stocks
"""

import pandas as pd
import numpy as np
import yfinance as yf
from datetime import datetime, timedelta
import warnings

warnings.filterwarnings('ignore')

# ============================================================================
# LQ45 STOCK UNIVERSE (45 Most Liquid Indonesian Stocks)
# ============================================================================
LQ45_TICKERS = [
    'ACES.JK', 'ADRO.JK', 'AKRA.JK', 'AMMN.JK', 'AMRT.JK',
    'ANTM.JK', 'ASII.JK', 'BBCA.JK', 'BBNI.JK', 'BBRI.JK',
    'BBTN.JK', 'BMRI.JK', 'BRPT.JK', 'BUKA.JK', 'CPIN.JK',
    'EMTK.JK', 'ESSA.JK', 'EXCL.JK', 'GGRM.JK', 'GOTO.JK',
    'HRUM.JK', 'ICBP.JK', 'INCO.JK', 'INDF.JK', 'INKP.JK',
    'INTP.JK', 'ITMG.JK', 'KLBF.JK', 'MAPI.JK', 'MDKA.JK',
    'MEDC.JK', 'MIKA.JK', 'PGAS.JK', 'PTBA.JK', 'SMGR.JK',
    'TBIG.JK', 'TINS.JK', 'TLKM.JK', 'TPIA.JK', 'UNTR.JK',
    'UNVR.JK', 'ARTO.JK', 'BRIS.JK', 'MBMA.JK', 'TOWR.JK'
]


# ============================================================================
# INDICATOR 1: RANGE FILTER
# ============================================================================
def calculate_range_filter(df: pd.DataFrame, period: int = 100, multiplier: float = 3.0) -> pd.DataFrame:
    """
    Range Filter Indicator (similar to TradingView implementation)
    
    Logic:
    1. Calculate smooth range = EMA of True Range * multiplier
    2. Define filter value that moves within the range bounds
    3. Bullish when price > filter, Bearish when price < filter
    
    Parameters:
    -----------
    df : DataFrame with 'High', 'Low', 'Close' columns
    period : Lookback period for EMA (default: 100)
    multiplier : Range multiplier (default: 3.0)
    
    Returns:
    --------
    DataFrame with 'rf_value', 'rf_signal' columns
    """
    close = df['Close'].values
    high = df['High'].values
    low = df['Low'].values
    n = len(close)
    
    # Calculate True Range
    true_range = np.zeros(n)
    true_range[0] = high[0] - low[0]
    for i in range(1, n):
        tr1 = high[i] - low[i]
        tr2 = abs(high[i] - close[i-1])
        tr3 = abs(low[i] - close[i-1])
        true_range[i] = max(tr1, tr2, tr3)
    
    # EMA of True Range (smooth range)
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
        # Upper/Lower bounds
        upper = rf_value[i-1] + range_size[i]
        lower = rf_value[i-1] - range_size[i]
        
        # Filter logic - follows price within range bounds
        if close[i] > upper:
            rf_value[i] = close[i] - range_size[i]
        elif close[i] < lower:
            rf_value[i] = close[i] + range_size[i]
        else:
            rf_value[i] = rf_value[i-1]
    
    # Generate signal: 1 = bullish (price above filter), -1 = bearish
    rf_signal = np.where(close > rf_value, 1, -1)
    
    result = df.copy()
    result['rf_value'] = rf_value
    result['rf_signal'] = rf_signal
    
    return result


# ============================================================================
# INDICATOR 2: RATIONAL QUADRATIC KERNEL (NADARAYA-WATSON ESTIMATOR)
# ============================================================================
def calculate_kernel_regression(df: pd.DataFrame, lookback: int = 50, 
                                 relative_weight: float = 1.0, 
                                 start_bar: int = 25) -> pd.DataFrame:
    """
    Rational Quadratic Kernel Regression (Nadaraya-Watson Estimator)
    
    Kernel Formula: K(x) = (1 + (x² / (2 * α * l²)))^(-α)
    Where:
    - x = distance between points
    - α = relative weight (shape parameter)
    - l = lookback (length scale)
    
    The estimator uses weighted average of prices where weights are
    determined by the kernel function.
    
    Parameters:
    -----------
    df : DataFrame with 'Close' column
    lookback : Lookback window / length scale (default: 50)
    relative_weight : Alpha parameter for kernel shape (default: 1.0)
    start_bar : Start regression calculation at this bar (default: 25)
    
    Returns:
    --------
    DataFrame with 'kernel_value', 'kernel_slope' columns
    """
    close = df['Close'].values
    n = len(close)
    
    kernel_value = np.full(n, np.nan)
    
    # Rational Quadratic Kernel function
    def rq_kernel(distance, alpha, length_scale):
        """
        K(x) = (1 + (x² / (2 * α * l²)))^(-α)
        """
        return np.power(1 + (distance ** 2) / (2 * alpha * (length_scale ** 2)), -alpha)
    
    # Calculate kernel regression for each bar
    for i in range(start_bar, n):
        # Determine the effective lookback (can't look back more than available data)
        effective_lookback = min(lookback, i)
        
        weights = np.zeros(effective_lookback)
        values = np.zeros(effective_lookback)
        
        for j in range(effective_lookback):
            # Distance from current bar
            distance = j
            weights[j] = rq_kernel(distance, relative_weight, lookback)
            values[j] = close[i - j]
        
        # Nadaraya-Watson estimator: weighted average
        if np.sum(weights) > 0:
            kernel_value[i] = np.sum(weights * values) / np.sum(weights)
    
    # Calculate slope (rate of change of kernel)
    kernel_slope = np.zeros(n)
    for i in range(1, n):
        if not np.isnan(kernel_value[i]) and not np.isnan(kernel_value[i-1]):
            kernel_slope[i] = kernel_value[i] - kernel_value[i-1]
    
    result = df.copy()
    result['kernel_value'] = kernel_value
    result['kernel_slope'] = kernel_slope
    
    return result


# ============================================================================
# INDICATOR 3: HALF TREND
# ============================================================================
def calculate_half_trend(df: pd.DataFrame, amplitude: int = 2) -> pd.DataFrame:
    """
    Half Trend Indicator (Amplitude-based trend algorithm)
    
    Logic:
    1. Calculate ATR for volatility measurement
    2. Create high/low channels using ATR and amplitude
    3. Trend flips when price breaks channel with confirmation
    
    Parameters:
    -----------
    df : DataFrame with 'High', 'Low', 'Close' columns
    amplitude : Channel amplitude multiplier (default: 2)
    
    Returns:
    --------
    DataFrame with 'ht_trend', 'ht_value' columns
    ht_trend: 1 for uptrend (long), -1 for downtrend (short)
    """
    high = df['High'].values
    low = df['Low'].values
    close = df['Close'].values
    n = len(close)
    
    # ATR calculation (14-period by default for Half Trend)
    atr_period = 100
    atr = np.zeros(n)
    
    # True Range
    tr = np.zeros(n)
    tr[0] = high[0] - low[0]
    for i in range(1, n):
        tr1 = high[i] - low[i]
        tr2 = abs(high[i] - close[i-1])
        tr3 = abs(low[i] - close[i-1])
        tr[i] = max(tr1, tr2, tr3)
    
    # Simple moving average of TR for ATR
    for i in range(n):
        if i < atr_period - 1:
            atr[i] = np.mean(tr[:i+1])
        else:
            atr[i] = np.mean(tr[i-atr_period+1:i+1])
    
    # Half Trend calculation
    trend = np.zeros(n)  # 1 = up, -1 = down
    ht_value = np.zeros(n)  # The half trend line value
    
    # Channel calculations
    dev = amplitude * atr / 2
    
    # Moving averages of high and low (using 2-period for smoothing)
    high_ma = np.zeros(n)
    low_ma = np.zeros(n)
    
    for i in range(n):
        if i == 0:
            high_ma[i] = high[i]
            low_ma[i] = low[i]
        else:
            high_ma[i] = (high[i] + high[i-1]) / 2
            low_ma[i] = (low[i] + low[i-1]) / 2
    
    # Initialize trend
    trend[0] = 1 if close[0] >= (high[0] + low[0]) / 2 else -1
    ht_value[0] = (high[0] + low[0]) / 2
    
    # Calculate trend
    for i in range(1, n):
        prev_trend = trend[i-1]
        prev_ht = ht_value[i-1]
        
        # Upper and lower half values
        high_half = high_ma[i] - dev[i]
        low_half = low_ma[i] + dev[i]
        
        if prev_trend == 1:  # Currently in uptrend
            # Trend line follows the low half, but can't go down
            new_ht = max(prev_ht, low_half)
            
            # Check for trend reversal to downtrend
            if close[i] < new_ht - dev[i]:
                trend[i] = -1
                ht_value[i] = high_half
            else:
                trend[i] = 1
                ht_value[i] = new_ht
                
        else:  # Currently in downtrend
            # Trend line follows the high half, but can't go up
            new_ht = min(prev_ht, high_half)
            
            # Check for trend reversal to uptrend
            if close[i] > new_ht + dev[i]:
                trend[i] = 1
                ht_value[i] = low_half
            else:
                trend[i] = -1
                ht_value[i] = new_ht
    
    result = df.copy()
    result['ht_trend'] = trend
    result['ht_value'] = ht_value
    
    return result


# ============================================================================
# DATA FETCHING
# ============================================================================
def fetch_stock_data(ticker: str, period: str = '1y') -> pd.DataFrame:
    """
    Fetch historical stock data from Yahoo Finance.
    
    Parameters:
    -----------
    ticker : Stock ticker symbol (e.g., 'BBCA.JK')
    period : Data period (default: '1y' for 1 year)
    
    Returns:
    --------
    DataFrame with OHLCV data or None if error
    """
    try:
        stock = yf.Ticker(ticker)
        df = stock.history(period=period)
        
        if df.empty or len(df) < 100:  # Need at least 100 bars for indicators
            return None
        
        # Ensure required columns exist
        required_cols = ['Open', 'High', 'Low', 'Close', 'Volume']
        for col in required_cols:
            if col not in df.columns:
                return None
        
        return df
        
    except Exception as e:
        return None


# ============================================================================
# SCREENING LOGIC
# ============================================================================
def screen_stock(ticker: str) -> dict:
    """
    Screen a single stock using all three indicators.
    
    Buy signal when ALL conditions are met:
    1. Range Filter is bullish (signal == 1)
    2. Kernel slope is positive (rising curve)
    3. Half Trend is bullish (trend == 1)
    
    Returns:
    --------
    Dict with screening results or None if error/doesn't pass
    """
    # Fetch data
    df = fetch_stock_data(ticker)
    if df is None:
        return None
    
    try:
        # Calculate all indicators
        df = calculate_range_filter(df, period=100, multiplier=3.0)
        df = calculate_kernel_regression(df, lookback=50, relative_weight=1.0, start_bar=25)
        df = calculate_half_trend(df, amplitude=2)
        
        # Get latest values
        latest = df.iloc[-1]
        
        rf_signal = int(latest['rf_signal'])
        kernel_slope = latest['kernel_slope']
        ht_trend = int(latest['ht_trend'])
        close_price = latest['Close']
        
        # Check if kernel_slope is valid
        if np.isnan(kernel_slope):
            return None
        
        # Screening conditions
        rf_bullish = rf_signal == 1
        kernel_rising = kernel_slope > 0
        ht_bullish = ht_trend == 1
        
        # All conditions must be true for buy signal
        if rf_bullish and kernel_rising and ht_bullish:
            return {
                'Ticker': ticker,
                'Close Price': round(close_price, 2),
                'Range Filter Signal': 'Bullish' if rf_bullish else 'Bearish',
                'Kernel Slope': round(kernel_slope, 4),
                'Half Trend Signal': 'Long' if ht_bullish else 'Short'
            }
        
        return None
        
    except Exception as e:
        return None


# ============================================================================
# MAIN SCREENING FUNCTION
# ============================================================================
def run_screener(tickers: list = None, verbose: bool = True) -> pd.DataFrame:
    """
    Run the screening process on all tickers.
    
    Parameters:
    -----------
    tickers : List of tickers to screen (default: LQ45_TICKERS)
    verbose : Print progress messages (default: True)
    
    Returns:
    --------
    DataFrame with stocks that passed the screening
    """
    if tickers is None:
        tickers = LQ45_TICKERS
    
    if verbose:
        print("=" * 60)
        print("INDONESIAN STOCK SCREENER (LQ45)")
        print("Confluence: Range Filter + Kernel Regression + Half Trend")
        print("=" * 60)
        print(f"\nScreening {len(tickers)} stocks...\n")
    
    results = []
    processed = 0
    errors = 0
    
    for ticker in tickers:
        if verbose:
            print(f"  Processing: {ticker}...", end=" ")
        
        result = screen_stock(ticker)
        processed += 1
        
        if result:
            results.append(result)
            if verbose:
                print("✓ PASSED")
        else:
            if verbose:
                print("–")
    
    # Create results DataFrame
    if results:
        results_df = pd.DataFrame(results)
        results_df = results_df.sort_values('Ticker').reset_index(drop=True)
    else:
        results_df = pd.DataFrame(columns=[
            'Ticker', 'Close Price', 'Range Filter Signal', 
            'Kernel Slope', 'Half Trend Signal'
        ])
    
    if verbose:
        print("\n" + "=" * 60)
        print(f"SCREENING COMPLETE")
        print(f"Processed: {processed} | Passed: {len(results)}")
        print("=" * 60)
    
    return results_df


# ============================================================================
# MAIN EXECUTION
# ============================================================================
if __name__ == "__main__":
    # Run the screener
    results = run_screener()
    
    print("\n" + "=" * 60)
    print("STOCKS PASSING ALL CRITERIA (BUY SIGNALS)")
    print("=" * 60)
    
    if len(results) > 0:
        # Display results with nice formatting
        pd.set_option('display.max_columns', None)
        pd.set_option('display.width', None)
        print(results.to_string(index=False))
    else:
        print("\nNo stocks passed all screening criteria at this time.")
    
    print("\n" + "=" * 60)
    print("Screening Date:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    print("=" * 60)
