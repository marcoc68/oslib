import numpy as np

def find_outliers(ks_values, p_values, ks_threshold, pvalue_threshold=0.05):
    """
    Find outlying symbols using KS values and P-values
    
    Parameters
    ----------
    ks_values : Pandas Series
        KS static for all the tickers
    p_values : Pandas Series
        P value for all the tickers
    ks_threshold : float
        The threshold for the KS statistic
    pvalue_threshold : float
        The threshold for the p-value
    
    Returns
    -------
    outliers : set of str
        Symbols that are outliers
    """
    
    #TODO: Implement function
    r = (ks_values > ks_threshold) & (p_values  < pvalue_threshold)
    r = r.loc[r&True]

    outliers = set(np.array(r.index))
    return outliers

    # implementacoes alternativas sugerida na revisao do projeto
    # find_outlierstambém podem ser implementados em uma linha da seguinte maneira:
    # return set(ks_values[ks_values > ks_threshold].index).intersection(p_values[p_values < pvalue_threshold].index)
    # return set(ks_values[ks_values > ks_threshold][p_values < pvalue_threshold].index.values)


project_tests.test_find_outliers(find_outliers)