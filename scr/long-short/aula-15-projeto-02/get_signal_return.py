def get_signal_return(signal, lookahead_returns):
    """
    Gera os retornos do sinal
    Compute the signal returns.
    
    Parameters
    ----------
    signal : DataFrame
        The long, short, and do nothing signals for each ticker and date
    lookahead_returns : DataFrame
        The lookahead log returns for each ticker and date
    
    Returns
    -------
    signal_return : DataFrame
        Signal returns for each ticker and date
    """
    #TODO: Implement function
    signal_return = signal * lookahead_returns
    
    return signal_return

project_tests.test_get_signal_return(get_signal_return)