def get_lookahead_prices(close, lookahead_days):
    """
    Obtém o preço de fechamento dias antes no tempo
    Get the lookahead prices for `lookahead_days` number of days.
    Retorne os precos deslocados no futuro.
    
    Parameters
    ----------
    close : DataFrame
        Close price for each ticker and date
    lookahead_days : int
        The number of days to look ahead
    
    Returns
    -------
    lookahead_prices : DataFrame
        The lookahead prices for each ticker and date
    """
    #TODO: Implement function
    lookahead_prices = close.shift(-lookahead_days)
    
    return lookahead_prices

project_tests.test_get_lookahead_prices(get_lookahead_prices)