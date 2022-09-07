import numpy as np
import pandas as pd

def clear_signals(signals, window_size):
    """
    Clear out signals in a Series of just long or short signals.    
    Remove the number of signals down to 1 within the window size time period.

    Limpe os sinais em uma serie de sinais longos ou curtos.
    Reduza o numero de sinais para 1 dentro do período de tempo do tamanho da janela.    
    
    Parameters
    ----------
    signals : Pandas Series
        The long, short, or do nothing signals
    window_size : int
        The number of days to have a single signal       
    
    Returns
    -------
    signals : Pandas Series
        Signals with the signals removed from the window size
    """
    
    # Start with buffer of window size
    # This handles the edge case of calculating past_signal in the beginning

    # Comece com o buffer do tamanho da janela
    # Isso lida com o caso extremo de calcular past_signal no início
    clean_signals = [0]*window_size
    
    for signal_i, current_signal in enumerate(signals):
        # Check if there was a signal in the past window_size of days
        has_past_signal = bool(sum(clean_signals[signal_i:signal_i+window_size]))
        # Use the current signal if there's no past signal, else 0/False
        clean_signals.append(not has_past_signal and current_signal)
        
    # Remove buffer
    clean_signals = clean_signals[window_size:]

    # Return the signals as a Series of Ints
    return pd.Series(np.array(clean_signals).astype(np.int), signals.index)


def filter_signals(signal, lookahead_days):
    """
    Filtra sinais longos ou curtos repetidos
    Filter out signals in a DataFrame.
    
    Parameters
    ----------
    signal : DataFrame
        The long, short, and do nothing signals for each ticker and date
    lookahead_days : int
        The number of days to look ahead
    
    Returns
    -------
    filtered_signal : DataFrame
        The filtered long, short, and do nothing signals for each ticker and date
    """
    #TODO: Implement function
    filtered_signal = signal.copy()
    for col in signal.columns:
        # colocando os sinais long e short em series separadas
        short = (signal[col]==-1).astype(np.int)*-1
        long  = (signal[col]== 1).astype(np.int)
        
        short_clean = clear_signals(short,lookahead_days-1)
        long_clean  = clear_signals(long ,lookahead_days-1)
        filtered_signal[col] = short_clean + long_clean 
    
    return filtered_signal
    
    ###########################################################################
    # sugestao da revisao do projeto
    #
    # Você também pode usar iterrows em cada coluna, conforme recomendado.
    # iterrows() método é otimizado para trabalhar com dataframes Pandas, portanto, 
    # uma melhoria significativa sobre o looping bruto.
    #
    # filter_signals também pode ser implementado usando a função lambda como esta:
    # pos_signal = signal[signal == 1].fillna(0)
    # neg_signal = signal[signal == -1].fillna(0) 
    #
    # pos_signal = pos_signal.apply(lambda signals: clear_signals(signals, lookahead_days))
    # neg_signal = neg_signal.apply(lambda signals: clear_signals(signals, lookahead_days))
    #
    # return pos_signal + neg_signal
    #
    # filter_signals também pode ser implementado em uma linha da seguinte maneira:
    # return signal.replace(-1, 0).apply(lambda x: clear_signals(x, lookahead_days), axis=0) + signal.replace(1, 0).apply(lambda x: clear_signals(x, lookahead_days), axis=0)
    #
    # filter_signalstambém pode ser implementado sem a função lambda da seguinte forma:
    # return (signal == 1).replace({True: 1, False: 0}).apply(clear_signals, args=(lookahead_days,)) + (signal == -1).replace({True: -1, False: 0}).apply(clear_signals, args=(lookahead_days,))
    #
    # aqui está uma maneira de resolvê-lo sem loop (sugestao do segundo revisor)
    # return (signal == 1).astype(np.int).apply(clear_signals, args=(lookahead_days,)) - (signal == -1).astype(np.int).apply(clear_signals, args=(lookahead_days,))
    ###########################################################################

project_tests.test_filter_signals(filter_signals)