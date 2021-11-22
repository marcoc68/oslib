//+------------------------------------------------------------------+
//|                                                      TestEMD.mq5 |
//|                                    Copyright (c) 2020, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                            https://www.mql5.com/ru/articles/7601 |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2020 Marketeer"
#property link "https://www.mql5.com/en/users/marketeer"
#property version "1.0"
#property description "Test expert adviser for timeseries forecasting based on Empirical Mode Decomposition (EMD)"

// I N P U T S

input int Length = 200;
      int Offset = 0;
input int Forecast = 2;
input int Reconstruction = 1;

input int SignalBar = -2;
input double Lot = 0.01;

const int deviation = 10;
const double sl = 0, tp = 0;


#include <MT4Bridge/MT4Orders.mqh>


// G L O B A L S

int handle;
double totalPlus, totalMinus;
int total, correct, skipped;


// E V E N T   H A N D L E R S

int OnInit()
{
  totalPlus = totalMinus = 0;
  total = correct = skipped = 0;
  
  if(Forecast <= 0) return INIT_PARAMETERS_INCORRECT;
  if(SignalBar > 0) return INIT_PARAMETERS_INCORRECT;

  Offset = SignalBar == 0 ? Forecast : 0;

  handle = iCustom(_Symbol, _Period, "EMD", Length, Offset, Forecast, Reconstruction);
  return handle == INVALID_HANDLE ? INIT_FAILED : INIT_SUCCEEDED;
}

void OnTick()
{
  static datetime lastBar = 0;
  const datetime now = iTime(NULL, 0, 0);
  if(now == lastBar) return;
  lastBar = now;
  
  double mult = 0;

  static double buffer[];
  ArrayResize(buffer, Forecast + 1);
  int result = CopyBuffer(handle, 0, SignalBar, Forecast + 1, buffer);
  ArrayPrint(buffer);
  
  if(SignalBar == 0)
  {
    if(result == Forecast + 1 && buffer[Forecast] != EMPTY_VALUE && buffer[0] != EMPTY_VALUE)
    {
      double forecast = (buffer[Forecast] - buffer[0]) / _Point;
      
      static double open[];
      ArrayResize(open, Forecast + 1);
      CopyOpen(_Symbol, _Period, 0, Forecast + 1, open);
      ArrayPrint(open);
    
      double actual = (open[Forecast] - open[0]) / _Point;
      mult = forecast * actual;
    }
    
    if(mult > 0)
    {
      correct++;
      totalPlus += mult;
    }
    else if(mult < 0)
    {
      totalMinus -= mult;
    }
    else
    {
      skipped++;
    }
    
    Print("    ", (string)lastBar, " ", mult);
  
    total++;
  }
  else
  {
    closeMarketOrders(iTime(_Symbol, _Period, Forecast - 1));
    if(result == Forecast + 1 && buffer[Forecast] != EMPTY_VALUE && buffer[0] != EMPTY_VALUE)
    {
      if(buffer[Forecast] > buffer[0])
      {
        placeMarketOrder(OP_BUY);
      }
      else
      {
        placeMarketOrder(OP_SELL);
      }
    }
  }
}

double OnTester()
{
  if(totalPlus == 0) return 0;
  if(skipped * 1.0 / total > 0.5) return 0;
  return (totalMinus != 0) ? totalPlus / totalMinus : DBL_MAX;
}

void OnDeinit(const int r)
{
  if(total > 0)
  {
    Print(correct, " (", skipped, ") / ", total, " = ", (float)(correct * 1.0 / total * 100), "%; PF ", (float)((totalMinus != 0) ? (totalPlus / totalMinus) : DBL_MAX));
  }
}


// A U X   F U N C T I O N S

void closeMarketOrders(const datetime olderThan = 0)
{
  for(int i = OrdersTotal() - 1; i >= 0; i--)
  {
    if(OrderSelect(i, SELECT_BY_POS))
    {
      if((OrderType() == OP_BUY || OrderType() == OP_SELL))
      {
        if(olderThan > 0 && OrderOpenTime() >= olderThan) continue;
        
        if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), deviation))
        {
          Print("OrderClose failed for #", OrderTicket(), " ", OrderSymbol(), " with error ", GetLastError());
        }
      }
    }
  }
}

long placeMarketOrder(const int type)
{
  static ENUM_SYMBOL_INFO_DOUBLE priceTypes[2] = {SYMBOL_ASK, SYMBOL_BID};
  const double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
  const double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
  double price = SymbolInfoDouble(_Symbol, priceTypes[type]);
  price = MathRound(price / tickSize) * tickSize;
  
  return OrderSend(_Symbol, type, Lot, price, deviation, sl, tp);
}
