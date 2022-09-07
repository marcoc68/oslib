import numpy as np

def get_long_short(close, lookback_high, lookback_low):
    """
    Calcula sinais longos e curtos usando uma estratégia de fuga.

    Generate the signals long, short, and do nothing.

    | Signal | Condition          |
    | ------ | ---------          |
    | -1     | Low  > Close Price |
    |  1     | High < Close Price |
    |  0     | Otherwise          |    
    
    Parameters
    ----------
    close : DataFrame
        Close price for each ticker and date
    lookback_high : DataFrame
        Lookback high price for each ticker and date
    lookback_low : DataFrame
        Lookback low price for each ticker and date
    
    Returns
    -------
    long_short : DataFrame
        The long, short, and do nothing signals for each ticker and date
    """
    
    # implementacoes que deram errado...
    #ls  = [-1 if c>h else 0 for c,h,l in zip(close,lookback_high,lookback_low)]
    #long_short = pd.DataFrame(ls).astype(np.int)
    #long_short = ( close > lookback_high ).astype(np.int)

    #TODO: Implement function
    signal_plus  = (lookback_high < close).astype(np.int)
    signal_minus = (lookback_low  > close).astype(np.int)*-1
    long_short   = signal_plus + signal_minus
    
    return long_short
    
    #implementacao sugerida na revisao do projeto
    #long_short = pd.DataFrame(0,index = close.index, columns = close.columns) 
    #long_short[lookback_low > close] = -1
    #long_short[lookback_high < close] = 1
    #return long_short

project_tests.test_get_long_short(get_long_short)