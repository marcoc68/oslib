import MetaTrader5 as mt5
import pandas as pd
import numpy as np
from datetime import datetime
import random
import matplotlib.pyplot as plt
from catboost import CatBoostClassifier
from sklearn.model_selection import train_test_split

mt5.initialize()

# check for gpu devices is availible
from catboost.utils import get_gpu_device_count
print('%i GPU devices' % get_gpu_device_count())

LOOK_BACK = 250
MA_PERIOD = 15
SYMBOL = 'EURUSD'
MARKUP = 0.0000
TIMEFRAME = mt5.TIMEFRAME_H1
START = datetime(2020, 5, 1)
STOP = datetime(2021, 1, 1)

def get_prices(look_back = 15):
    prices = pd.DataFrame(mt5.copy_rates_range(SYMBOL, TIMEFRAME, START, STOP), 
                            columns=['time', 'close']).set_index('time')
    # set df index as datetime
    prices.index = pd.to_datetime(prices.index, unit='s')
    prices = prices.dropna()
    ratesM = prices.rolling(MA_PERIOD).mean()
    ratesD = prices - ratesM
    for i in range(look_back):
        prices[str(i)] = ratesD.shift(i)
    return prices.dropna()

def add_labels(dataset, min, max):
    labels = []
    for i in range(dataset.shape[0]-max):
        rand = random.randint(min, max)
        if dataset['close'][i] >= (dataset['close'][i + rand]):
            labels.append(1.0)
        elif dataset['close'][i] <= (dataset['close'][i + rand]):
            labels.append(0.0)              
        else:
            labels.append(0.0)
    dataset = dataset.iloc[:len(labels)].copy()
    dataset['labels'] = labels
    dataset = dataset.dropna()
    return dataset

def tester(dataset, markup = 0.0):
    last_deal = int(2)
    last_price = 0.0
    report = [0.0]
    for i in range(dataset.shape[0]):
        pred = dataset['labels'][i]
        if last_deal == 2:
            last_price = dataset['close'][i]
            last_deal = 0 if pred <=0.5 else 1
            continue
        if last_deal == 0 and pred > 0.5:
            last_deal = 1
            report.append(report[-1] - markup + (dataset['close'][i] - last_price))
            last_price = dataset['close'][i]
            continue
        if last_deal == 1 and pred <=0.5:
            last_deal = 0
            report.append(report[-1] - markup + (last_price - dataset['close'][i]))
            last_price = dataset['close'][i]      
    return report

def export_model_to_MQL_code(model):
    model.save_model('catmodel.h',
           format="cpp",
           export_parameters=None,
           pool=None)
    code = 'double catboost_model' + '(const double &features[]) { \n'
    code += '    '
    with open('catmodel.h', 'r') as file:
        data = file.read()
        code += data[data.find("unsigned int TreeDepth"):data.find("double Scale = 1;")]
    code +='\n\n'
    code+= 'return ' + 'ApplyCatboostModel(features, TreeDepth, TreeSplits , BorderCounts, Borders, LeafValues); } \n\n'

    code += 'double ApplyCatboostModel(const double &features[],uint &TreeDepth_[],uint &TreeSplits_[],uint &BorderCounts_[],float &Borders_[],double &LeafValues_[]) {\n\
    uint FloatFeatureCount=ArrayRange(BorderCounts_,0);\n\
    uint BinaryFeatureCount=ArrayRange(Borders_,0);\n\
    uint TreeCount=ArrayRange(TreeDepth_,0);\n\
    bool     binaryFeatures[];\n\
    ArrayResize(binaryFeatures,BinaryFeatureCount);\n\
    uint binFeatureIndex=0;\n\
    for(uint i=0; i<FloatFeatureCount; i++) {\n\
       for(uint j=0; j<BorderCounts_[i]; j++) {\n\
          binaryFeatures[binFeatureIndex]=features[i]>Borders_[binFeatureIndex];\n\
          binFeatureIndex++;\n\
       }\n\
    }\n\
    double result=0.0;\n\
    uint treeSplitsPtr=0;\n\
    uint leafValuesForCurrentTreePtr=0;\n\
    for(uint treeId=0; treeId<TreeCount; treeId++) {\n\
       uint currentTreeDepth=TreeDepth_[treeId];\n\
       uint index=0;\n\
       for(uint depth=0; depth<currentTreeDepth; depth++) {\n\
          index|=(binaryFeatures[TreeSplits_[treeSplitsPtr+depth]]<<depth);\n\
       }\n\
       result+=LeafValues_[leafValuesForCurrentTreePtr+index];\n\
       treeSplitsPtr+=currentTreeDepth;\n\
       leafValuesForCurrentTreePtr+=(1<<currentTreeDepth);\n\
    }\n\
    return 1.0/(1.0+MathPow(M_E,-result));\n\
    }'

    file = open('C:/Users/dmitrievsky/AppData/Roaming/MetaQuotes/Terminal/D0E8209F77C8CF37AD8BF550E51FF075/MQL5/Include/' + 'cat_model' + '.mqh', "w")
    file.write(code)
    file.close()
    print('The file ' + 'cat_model' + '.mqh ' + 'has been written to disc')

pr = get_prices(look_back=LOOK_BACK)
pr = add_labels(pr, 10, 25)
rep = tester(pr, MARKUP)
plt.plot(rep)
plt.show()

#splitting on train and validation subsets
X = pr[pr.columns[1:-1]]
y = pr[pr.columns[-1]]
train_X, test_X, train_y, test_y = train_test_split(X, y, train_size = 0.5, test_size = 0.5, shuffle=True)

#learning with train and validation subsets
model = CatBoostClassifier(iterations=500,
                        depth=6,
                        learning_rate=0.1,
                        custom_loss=['Accuracy'],
                        eval_metric='Accuracy',       
                        verbose=True, 
                        use_best_model=True,
                        task_type='CPU')
model.fit(train_X, train_y, eval_set = (test_X, test_y), early_stopping_rounds=15, plot=False)

#test the learned model
p = model.predict_proba(X)
p2 = [x[0]<0.5 for x in p]
pr2 = pr.iloc[:len(p2)].copy()
pr2['labels'] = p2
rep = tester(pr2, MARKUP)
plt.plot(rep)
plt.show()

#export the model
export_model_to_MQL_code(model)