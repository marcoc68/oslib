# Copyright 2020, MetaQuotes Software Corp.
# https://www.mql5.com

#from datetime import datetime
#import MetaTrader5 as mt5
#import tensorflow as tf
#import numpy as np
#import matplotlib.pyplot as plt
#
#mt5.initialize()
# you code here
# 
#mt5.shutdown()



#from MetaTrader5 import *
import MetaTrader5 as mt5
from datetime import datetime
import numpy as np
import pandas as pd 
import matplotlib.pyplot as plt 
#%matplotlib inline
import seaborn; seaborn.set()
# Initializing MT5 connection
mt5.initialize() 
#MT5Initialize("C:\\Program Files\\MetaTrader 5\\terminal64.exe")
MT5WaitForTerminal()

print(MT5TerminalInfo())
print(MT5Version())