import MetaTrader5 as mt5
from datetime import datetime
import numpy as np
import pandas as pd 
import matplotlib.pyplot as plt 
#import seaborn; seaborn.set()

#%matplotlib inline
#import seaborn; seaborn.set()

# exibimos dads sobre o pacote MetaTrader5
print("MetaTrader5 package author: ",mt5.__author__)
print("MetaTrader5 package version: ",mt5.__version__)

# Initializing MT5 connection 
if not mt5.initialize():
    print("initialize() failed, error code =",mt5.last_error())
    quit()

# imprimimos informacoes sobre o estado da conexao, o nome do servidor e a conta de negociacao
print(mt5.terminal_info())
print(mt5.version()      )



rates = pd.DataFrame(mt5.copy_rates_range("BOVA11", mt5.TIMEFRAME_D1, 
                     datetime(2018, 8, 1), 
                     datetime(2020, 8, 28)), 
                     columns=['time', 'open', 'low', 'high', 'close', 'tick_volume', 'spread', 'real_volume']
                    )
# leave only 'time' and 'close' columns
rates.drop(['open', 'low', 'high', 'tick_volume', 'spread', 'real_volume'], axis=1)

# convertendo a data em segundos para data normal
rates['time']=pd.to_datetime(rates['time'], unit='s')

# get percent change (price returns)
returns = pd.DataFrame(rates['close'].pct_change(1))
returns = returns.set_index(rates['time'])
returns = returns[1:]
print(returns.head(10))

Monthly_Returns = returns.groupby([returns.index.year.rename('year'), 
                                   returns.index.month.rename('month')]).mean()
Monthly_Returns.boxplot(column='close', by='month', figsize=(15, 8))

print(Monthly_Returns)
