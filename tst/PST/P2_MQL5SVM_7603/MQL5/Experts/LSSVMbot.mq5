//+------------------------------------------------------------------+
//|                                                     LSSVMbot.mq5 |
//|                                    Copyright (c) 2020, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                          Test forecasting EA based on SOM-LS-SVM |
//|                            https://www.mql5.com/ru/articles/7603 |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2020 Marketeer"
#property link "https://www.mql5.com/en/users/marketeer"
#property version "1.0"
#property description "Test expert adviser for timeseries forecasting based on SOM-LS-SVM"


input string _1 = "";          // M A I N
input int _VectorNumber = 250; // VectorNumber (training)
input int _VectorNumber2 = 25; // VectorNumber (validating)
input int _VectorSize = 20;    // VectorSize
input double _Gamma = 0;       // Gamma (0 - auto)
input double _Sigma = 0;       // Sigma (0 - auto)
input int _KernelNumber = 0;   // KernelNumber (sqrt, 0 - auto)
input int DifferencingOrder = 1;
input int StepsAhead = 0;
input double Lot = 0.1;
input bool MultipleOrders = false;
input bool PreviousTargetCheck = false;

enum CUSTOM_ESTIMATOR
{
  RMSE,
  CC,
  R2,
  PCT,
  TRADING
};

input string _2 = "";          // O P T I M I Z A T I O N
input int _GammaIndex = 0;     // Gamma Power Iterator
input int _SigmaIndex = 0;     // Sigma Power Iterator
input double _GammaStep = 0;   // Gamma Power Multiplier (0 - off)
input double _SigmaStep = 0;   // Sigma Power Multiplier (0 - off)
input int WindowIndex = 0;     // Window Iterator
input CUSTOM_ESTIMATOR Estimator = R2;


      int _TrainingOffset = _VectorNumber2; // training bars start after validation set ('before' in history)
const int _ValidationOffset = 0; // validation always starts (chronologically ends) at last bar
const double _Threshold = 0.0;   // Threshold AlgLib (0 - auto)
const double Sparsity = 0;


#include <MT4Bridge/MT4Orders.mqh>
#include <MT4Bridge/MT4Time.mqh>

// NB. SOM is randomized (every pass will differ if srand not called)
#include <SOMLSSVM.mqh>


LSSVM *lssvm = NULL;
LSSVM *test = NULL;


bool processed = false;
int requiredBarNumber;
double customResult;
bool updateMonthly;
bool updateQuarterly;
bool updateYearly;
datetime customDate = 0;


int OnInit()
{
  if(StringLen(_1) > 0)
  {
    const uint seed = (uint)StringToInteger(_1);
    MathSrand(seed);
  }
  updateMonthly = _2 == "m" || _2 == "M";
  updateQuarterly = _2 == "q" || _2 == "Q";
  updateYearly = _2 == "y" || _2 == "Y";
  if(StringLen(_2) == 10) // YYYY.MM.DD
  {
    customDate = StringToTime(_2);
  }
  
  _TrainingOffset = Estimator == TRADING ? 0 : _VectorNumber2;
  int KernelNumber = _KernelNumber * _KernelNumber;
  lssvm = new LSSVM(_VectorNumber, _VectorSize, KernelNumber, _Gamma, _Sigma, _TrainingOffset);
  test = new LSSVM(_VectorNumber2, _VectorSize, KernelNumber, 1, 1, _ValidationOffset);
  lssvm.setDifferencingOrder(DifferencingOrder);
  test.setDifferencingOrder(DifferencingOrder);
  
  processed = false;
  requiredBarNumber = _VectorNumber + _TrainingOffset + _VectorSize + DifferencingOrder;
  customResult = 0;
  
  Print("Bars required: ", requiredBarNumber);

  return INIT_SUCCEEDED;
}


void iterate(const int Gindex, const double Gstep, const int Sindex, const double Sstep)
{
  double Gamma = _Gamma;
  double Sigma = _Sigma;

  if(Gstep > 0)
  {
    for(int i = 0; i < Gindex; i++)
    {
      Gamma *= Gstep;
    }
  }
  
  if(Sstep > 0)
  {
    for(int i = 0; i < Sindex; i++)
    {
      Sigma *= Sstep;
    }
  }

  Print("G[", Gindex, "]=", (float)Gamma, " S[", Sindex, "]=", (float)Sigma);

  lssvm.setGamma(Gamma);
  lssvm.setSigma(Sigma);
}


bool optimize()
{
  if(Estimator != TRADING) lssvm.bindCrossValidator(test);
  iterate(_GammaIndex, _GammaStep, _SigmaIndex, _SigmaStep);
  bool success = lssvm.process();
  if(success)
  {
    LSSVM::LSSVM_Error result;
    lssvm.checkAll(result);
    
    Print("Parameters: ", lssvm.getGamma(), " ", lssvm.getSigma());
    Print("  training: ", result.RMSE[0], " ", result.CC[0], " ", result.R2[0], " ", result.PCT[0]);
    Print("  test: ", result.RMSE[1], " ", result.CC[1], " ", result.R2[1], " ", result.PCT[1]);
    
    customResult = Estimator == CC ? result.CC[1]
                : (Estimator == RMSE ? -result.RMSE[1] // the lesser |absolute error value| the better
                : (Estimator == PCT ? result.PCT[1] : result.R2[1]));
  }
  return success;
}

const string prefix = "botsvm";

datetime lastBar = 0;

bool isNewBar()
{
  if(lastBar != iTime(_Symbol, 0, 0))
  {
    lastBar = iTime(_Symbol, 0, 0);
    return true;
  }
  return false;
}

void OnTick()
{
  if(!isNewBar()) return;
  
  if(customDate > TimeCurrent()) return;

  const int bars = Bars(_Symbol, _Period);
  const int offset = requiredBarNumber + _TrainingOffset * WindowIndex; // rolling walk-forward imitation (option)
  if(bars < offset)
  {
    static bool firstStart = true;
    
    if(firstStart)
    {
      Print(bars, " ", iTime(_Symbol, _Period, bars - 1));
      firstStart = false;
    }
    
    return;
  }
  
  static bool started = false;
  if(!started)
  {
    Print("Starting at ", iTime(_Symbol, _Period, offset - 1),
      " - ", iTime(_Symbol, _Period, 0), ", bars=", bars);
    started = true;
  }
  
  if(Estimator != TRADING)
  {
    if(!processed)
    {
      processed = optimize();
    }
  }
  else if(DifferencingOrder < 4)
  {
    // predict next open price using current _Gamma and _Sigma

    static bool solved = false;
    if(!solved)
    {
      const bool opt = (bool)MQLInfoInteger(MQL_OPTIMIZATION) || (_GammaStep != 0 && _SigmaStep != 0);
      solved = opt ? optimize() : lssvm.process();
    }

    if(solved)
    {
      // test is used to read latest _VectorNumber2 prices
      if(!test.buildXYVectors())
      {
        Print("No vectors");
        return;
      }
      test.normalizeXYVectors();

      double out[];

      // read latest vector
      if(!test.buildVector(out))
      {
        Print("No last price");
        return;
      }
      test.normalizeVector(out);

      double z = lssvm.approximate(out);
      
      for(int i = 0; i < StepsAhead; i++)
      {
        ArrayCopy(out, out, 0, 1);
        out[ArraySize(out) - 1] = z;
        z = lssvm.approximate(out);
      }

      z = test.denormalize(z);
      
      double open[];
      if(3 == CopyOpen(_Symbol, _Period, 0, 3, open)) // open[1] - previous, open[2] - current
      {
        ArrayPrint(open);
        
        static double previousTarget = 0;
        double target = 0;
        if(DifferencingOrder == 0)
        {
          target = z;
        }
        else if(DifferencingOrder == 1)
        {
          target = open[2] + z;
        }
        else if(DifferencingOrder == 2)
        {
          target = 2 * open[2] - open[1] + z;
        }
        else if(DifferencingOrder == 3)
        {
          target = 3 * open[2] - 3 * open[1] + open[0] + z;
        }
        else
        {
          // unsupported yet
        }
        
        string comment = (string)(float)(target - open[2]);
        
        Print((float)target);

        if(MQLInfoInteger(MQL_VISUAL_MODE))
        {
          string name = prefix + (string)(long)iTime(_Symbol, _Period, 0);
          ObjectCreate(0, name, OBJ_TEXT, 0, iTime(_Symbol, _Period, 0), target);
          ObjectSetString(0, name, OBJPROP_TEXT, "l");
          ObjectSetString(0, name, OBJPROP_FONT, "Wingdings");
          ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_CENTER);
          ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
        }
        
        int mode = 0;
        mode = target >= open[2] ? +1 : -1;
        
        if(PreviousTargetCheck)
        {
          if(target > previousTarget) mode = +1;
          if(target < previousTarget) mode = -1;
        }
        
        int dir = CurrentOrderDirection();
        if(dir * mode <= 0 || MultipleOrders)
        {
          if(dir != 0) // there is an order
          {
            if(!MultipleOrders || dir * mode <= 0)
            {
              OrdersCloseAll();
              dir = 0;
            }
          }
          
          if(mode != 0)
          {
            const int type = mode > 0 ? OP_BUY : OP_SELL;
            
            const double p = type == OP_BUY ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

            bool canSendOrder = true;
            if(MultipleOrders && dir != 0) // more orders allowed and previous order exists
            {
              const double price = OrderOpenPrice(); // check if a better price available
              if(type == OP_BUY) canSendOrder = p < price;
              if(type == OP_SELL) canSendOrder = p > price;
            }
            
            if(canSendOrder)
            {
              OrderSend(_Symbol, type, Lot, p, 100, 0, 0, comment);
            }
          }
        }
        previousTarget = target;
      }
      else
      {
        Print("CopyOpen failed: ", GetLastError());
      }
    }

    if(updateMonthly || updateQuarterly || updateYearly)
    {
      const int m0 = TimeMonth(iTime(_Symbol, _Period, 0));
      const int m1 = TimeMonth(iTime(_Symbol, _Period, 1));
      if(m0 != m1)
      {
        if( updateMonthly
        || (updateQuarterly && (m1 % 3 == 0)) // 3, 6, 9, 12
        || (updateYearly && m0 < m1)
        )
        {
          solved = false; // re-solve in every month/quarter/year
        }
      }
    }
  }
}

double OnTester()
{
  return processed ? customResult : -1;
}

void OnDeinit(const int)
{
  // ObjectsDeleteAll(0, prefix, 0, OBJ_TEXT); nothing to delete except for visual mode, but in this mode objects should be kept on chart
  delete lssvm;
  delete test;
}

int CurrentOrderDirection(const string symbol = NULL)
{
  for(int i = OrdersTotal() - 1; i >= 0; i--)
  {
    if(OrderSelect(i, SELECT_BY_POS))
    {
      if(OrderType() <= OP_SELL && (symbol == NULL || symbol == OrderSymbol()))
      {
        return OrderType() == OP_BUY ? +1 : -1;
      }
    }
  }
  return 0;
}

void OrdersCloseAll(const string symbol = NULL, const int type = -1) // OP_BUY or OP_SELL
{
  for(int i = OrdersTotal() - 1; i >= 0; i--)
  {
    if(OrderSelect(i, SELECT_BY_POS))
    {
      if(OrderType() <= OP_SELL && (type == -1 || OrderType() == type) && (symbol == NULL || symbol == OrderSymbol()))
      {
        OrderClose(OrderTicket(), OrderLots(), OrderType() == OP_BUY ? SymbolInfoDouble(OrderSymbol(), SYMBOL_BID) : SymbolInfoDouble(OrderSymbol(), SYMBOL_ASK), 100);
      }
    }
  }
}
