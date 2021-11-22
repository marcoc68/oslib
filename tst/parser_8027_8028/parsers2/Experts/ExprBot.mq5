//+------------------------------------------------------------------+
//|                                                      ExprBot.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//|                           https://www.mql5.com/ru/articles/8028/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.0"

#define INDICATOR_FUNCTORS

#include <MT4Orders.mqh>
#include <ExpresSParserS/ExpressionCompiler.mqh>


input string SignalBuy = "EMA_OPEN_{Fast}(0)/EMA_OPEN_{Slow}(0) > 1 + Threshold";
input string SignalSell = "EMA_OPEN_{Fast}(0)/EMA_OPEN_{Slow}(0) < 1 - Threshold";
input string Variables = "Threshold=0.001";
input int Fast = 10;
input int Slow = 21;
input double Lot = 0.1;


ExpressionCompiler ecb(Variables), ecs(Variables);
Promise *p1, *p2;


int OnInit()
{
  if(Fast >= Slow) return INIT_PARAMETERS_INCORRECT;
  
  ecb.variableTable().set("Fast", Fast);
  ecb.variableTable().set("Slow", Slow);
  p1 = ecb.evaluate(SignalBuy, true);
  if(!ecb.success())
  {
    Print("Syntax error in Buy signal:");
    p1.print();
    return INIT_FAILED;
  }
  ecs.variableTable().set("Fast", Fast);
  ecs.variableTable().set("Slow", Slow);
  p2 = ecs.evaluate(SignalSell, true);
  if(!ecs.success())
  {
    Print("Syntax error in Sell signal:");
    p2.print();
    return INIT_FAILED;
  }
  
  return INIT_SUCCEEDED;
}


bool isNewBar()
{
  static datetime lastBar = 0;

  if(lastBar != iTime(_Symbol, 0, 0))
  {
    lastBar = iTime(_Symbol, 0, 0);
    return true;
  }
  return false;
}


#define _Ask SymbolInfoDouble(_Symbol, SYMBOL_ASK)
#define _Bid SymbolInfoDouble(_Symbol, SYMBOL_BID)

void OnTick()
{
  MqlTick tick;
  if(!SymbolInfoTick(_Symbol, tick)) return;
  
  if(!isNewBar()) return;
  
  bool buy = p1.resolve();
  bool sell = p2.resolve();
  
  if(buy && sell)
  {
    buy = false;
    sell = false;
  }
  
  if(buy)
  {
    OrdersCloseAll(_Symbol, OP_SELL);
    if(OrdersTotalByType(_Symbol, OP_BUY) == 0)
    {
      OrderSend(_Symbol, OP_BUY, Lot, _Ask, 100, 0, 0);
    }
  }
  else if(sell)
  {
    OrdersCloseAll(_Symbol, OP_BUY);
    if(OrdersTotalByType(_Symbol, OP_SELL) == 0)
    {
      OrderSend(_Symbol, OP_SELL, Lot, _Bid, 100, 0, 0);
    }
  }
  else
  {
    OrdersCloseAll();
  }
}


void OrdersCloseAll(const string symbol = NULL, const int type = -1) // OP_BUY or OP_SELL
{
  for(int i = OrdersTotal() - 1; i >= 0; i--)
  {
    if(OrderSelect(i, SELECT_BY_POS))
    {
      if(OrderType() <= OP_SELL
      && (type == -1 || OrderType() == type)
      && (symbol == NULL || symbol == OrderSymbol()))
      {
        OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 100);
      }
    }
  }
}

int OrdersTotalByType(const string symbol = NULL, const int type = -1) // OP_BUY or OP_SELL
{
  int count = 0;
  for(int i = OrdersTotal() - 1; i >= 0; i--)
  {
    if(OrderSelect(i, SELECT_BY_POS))
    {
      if(OrderType() <= OP_SELL
      && (type == -1 || OrderType() == type)
      && (symbol == NULL || symbol == OrderSymbol()))
      {
        count++;
      }
    }
  }
  return count;
}
