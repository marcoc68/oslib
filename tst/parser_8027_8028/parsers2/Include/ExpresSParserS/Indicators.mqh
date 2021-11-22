//+------------------------------------------------------------------+
//|                                                   Indicators.mqh |
//|                                    Copyright (c) 2020, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//+------------------------------------------------------------------+

#include "Functors.mqh"

class IndicatorFunc: public AbstractFunc
{
  public:
    IndicatorFunc(const string n, const int a = 1): AbstractFunc(n, a)
    {
      // the single argument is the bar number,
      // two arguments are bar number and buffer index
      
      // NB. indicator parameters, such as period, price type etc. should be specified in its name,
      // because MT creates indicator handle per parameter set,
      // so the identifier is the name plus the parameter set;
      // here indicators are created during parsing, then called during calculation
    }
    static IndicatorFunc *create(const string name);
};

class MAIndicatorFunc: public IndicatorFunc
{
  protected:
    const int handle;
    
  public:
    MAIndicatorFunc(const string n, const int h): IndicatorFunc(n), handle(h) {}
    
    ~MAIndicatorFunc()
    {
      IndicatorRelease(handle);
    }
    
    static MAIndicatorFunc *create(const string name) // SMA_OPEN_10(0)
    {
      string parts[];
      if(StringSplit(name, '_', parts) != 3) return NULL;
      
      ENUM_MA_METHOD m = -1;
      ENUM_APPLIED_PRICE t = -1;
      
      static string methods[] = {"SMA", "EMA", "SMMA", "LWMA"};
      for(int i = 0; i < ArraySize(methods); i++)
      {
        if(parts[0] == methods[i])
        {
          m = (ENUM_MA_METHOD)i;
          break;
        }
      }

      static string types[] = {"NULL", "CLOSE", "OPEN", "HIGH", "LOW", "MEDIAN", "TYPICAL", "WEIGHTED"};
      for(int i = 1; i < ArraySize(types); i++)
      {
        if(parts[1] == types[i])
        {
          t = (ENUM_APPLIED_PRICE)i;
          break;
        }
      }
      
      if(m == -1 || t == -1) return NULL;
      
      int h = iMA(_Symbol, _Period, (int)StringToInteger(parts[2]), 0, m, t);
      if(h == INVALID_HANDLE) return NULL;
      
      return new MAIndicatorFunc(name, h);
    }
    
    double execute(const double &params[]) override
    {
      const int bar = (int)params[0];
      double result[1] = {0};
      if(CopyBuffer(handle, 0, bar, 1, result) != 1)
      {
        Print("CopyBuffer error: ", GetLastError());
      }
      return result[0];
    }
};

static IndicatorFunc *IndicatorFunc::create(const string name)
{
  // TODO: support more indicator types, dispatch calls based on the name
  return MAIndicatorFunc::create(name);
}
