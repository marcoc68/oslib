import numpy as np
def get_return_lookahead(close, lookahead_prices):
    """
    Gera o retorno do preço do log entre o preço de fechamento e o preço antecipado.

    Calculate the log returns from the lookahead days to the signal day.
    
    Parameters
    ----------
    close : DataFrame
        Close price for each ticker and date
    lookahead_prices : DataFrame
        The lookahead prices for each ticker and date
    
    Returns
    -------
    lookahead_returns : DataFrame
        The lookahead log returns for each ticker and date
    """
    #TODO: Implement function
    lookahead_returns = np.log(lookahead_prices) - np.log(close)
    
    return lookahead_returns

project_tests.test_get_return_lookahead(get_return_lookahead)