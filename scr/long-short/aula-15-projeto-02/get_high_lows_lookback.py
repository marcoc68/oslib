def get_high_lows_lookback(high, low, lookback_days):
    """

    Calcula o máximo e o mínimo dos preços de fechamento em uma janela de dias

    Descricao do funcionamento (copiada do projeto 2)
    -------------------------------------------------
    Você usarah os precos highs(altos) e lows(baixos) como um indicador para a estrategia de fuga.
    Nesta secao, implemente get_high_lows_lookback para obter o preco maximo alto e o preco minimo baixo
    em uma janela de dias. A variavel lookback_days contem o numero de dias para olhar no passado.
    Certifique-se de que nao inclui o dia atual.
    
    Parameters
    ----------
    high : DataFrame
        High price for each ticker and date
    low : DataFrame
        Low price for each ticker and date
    lookback_days : int
        The number of days to look back
    
    Returns
    -------
    lookback_high : DataFrame
        Lookback high price for each ticker and date
    lookback_low : DataFrame
        Lookback low price for each ticker and date
    """
    #TODO: Implement function
    #shift(1) -> usei para excluir o dia atual conforme solicitado na descricao do projeto.
    lookback_high = high.shift(1).rolling(window = lookback_days).max()
    lookback_low  =  low.shift(1).rolling(window = lookback_days).min()
    
    return lookback_high, lookback_low

project_tests.test_get_high_lows_lookback(get_high_lows_lookback)