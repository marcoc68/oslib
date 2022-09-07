from scipy.stats import kstest
import pandas    as     pd

def calculate_kstest(long_short_signal_returns):
    """
    Calcula os valores ks e p.
    Calculate the KS-Test against the signal returns with a long or short signal.
    
    Parameters
    ----------
    long_short_signal_returns : DataFrame
        The signal returns which have a signal.
        This DataFrame contains two columns, "ticker" and "signal_return"
    
    Returns
    -------
    ks_values : Pandas Series
        KS static for all the tickers
    p_values : Pandas Series
        P value for all the tickers
    """
    #TODO: Implement function
    
    # grouping...
    dfg = long_short_signal_returns.groupby(['ticker'],sort=False)

    # for CDF distribution used in kstest...
    portfolio_mean = long_short_signal_returns.mean()
    portfolio_std  = long_short_signal_returns.std(ddof=0)
    normal_args    = ( portfolio_mean, portfolio_std )

    vind = [] 
    vkst = []
    vpv  = []
    # for each group (ticker)...
    for i,data in dfg:

        sample = data['signal_return']
        kst,pv  = kstest( sample, 'norm', normal_args )
        vind.append(i)
        vkst.append(kst)
        vpv.append(pv)
    
    ks_values=pd.Series(vkst, index=vind)
    p_values =pd.Series(vpv , index=vind)

    return ks_values, p_values

    # implementacao alternativa sugerida pela revisao do teste
    # g_mu,g_std = long_short_signal_returns.mean(), long_short_signal_returns.std(ddof=0)
    #
    # grp  = pd.DataFrame(long_short_signal_returns.groupby('ticker')['signal_return'].apply(list))
    # rzlt = pd.DataFrame(grp['signal_return'].map(lambda x: kstest(x, 'norm', args=(g_mu,g_std))))
    # rzlt['k'] = rzlt['signal_return'].map(lambda x: x[0])
    # rzlt['p'] = rzlt['signal_return'].map(lambda x: x[1])
    #
    # return  rzlt['k'], rzlt['p'] 


project_tests.test_calculate_kstest(calculate_kstest)

#def calc_kstest(long_short_signal_returns):
#    res = pd.DataFrame(columns=['statistic', 'pvalue'])
#    
#    mean = long_short_signal_returns.signal_return.mean()
#    std = long_short_signal_returns.signal_return.std(ddof=0)
#    
#    for ticker, data in long_short_signal_returns.groupby('ticker'):
#        res = res.append(pd.Series(kstest(data.signal_return, 'norm', args = (mean, std)), index=['statistic', 'pvalue'], name=ticker))
#    res = res.sort_index()
#    
#    return res.statistic, res.pvalue
