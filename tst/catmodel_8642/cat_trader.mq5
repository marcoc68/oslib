//+------------------------------------------------------------------+
//|                                                   cat_trader.mq5 |
//|                                 Copyright 2020, Dmitrievsky Max. |
//|                        https://www.mql5.com/ru/users/dmitrievsky |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Dmitrievsky Max."
#property link      "https://www.mql5.com/ru/users/dmitrievsky"
#property version   "1.00"
#include <MT4Orders.mqh>
#include <Trade\AccountInfo.mqh>
#include <cat_model.mqh>

sinput int look_back = 50;
sinput int MA_period = 15;
sinput int      OrderMagic = 666;       //Orders magic
sinput double   MaximumRisk=0.01;       //Maximum risk
sinput double   CustomLot=0;            //Custom lot
input int stoploss = 500;
static datetime last_time=0;
#define Ask SymbolInfoDouble(_Symbol, SYMBOL_ASK)
#define Bid SymbolInfoDouble(_Symbol, SYMBOL_BID)
int hnd;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   hnd = iMA(NULL,PERIOD_CURRENT,MA_period,0,MODE_SMA,PRICE_CLOSE);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if(!isNewBar()) return;
   double ma[];
   double pr[];
   double ret[];
   ArrayResize(ret, look_back);
   CopyBuffer(hnd, 0, 1, look_back, ma);
   CopyClose(NULL,PERIOD_CURRENT,1,look_back,pr);
   for(int i=0; i<look_back; i++)
      ret[i] = pr[i] - ma[i];
   ArraySetAsSeries(ret, true);
   double sig = catboost_model(ret);

   for(int b = OrdersTotal() - 1; b >= 0; b--)
      if(OrderSelect(b, SELECT_BY_POS) == true) {
         if(OrderType() == 0 && OrderSymbol() == _Symbol && OrderMagicNumber() == OrderMagic && sig > 0.5)
            if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, Red)) {
            }
         if(OrderType() == 1 && OrderSymbol() == _Symbol && OrderMagicNumber() == OrderMagic && sig < 0.5)
            if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 0, Red)) {
            }
      }

   if(countOrders(0) == 0 && countOrders(1) == 0) {
      if(sig < 0.5)
         OrderSend(Symbol(),OP_BUY,LotsOptimized(), Ask, 0, Bid-stoploss*_Point, 0, NULL, OrderMagic);
      else if(sig > 0.5)
         OrderSend(Symbol(),OP_SELL,LotsOptimized(), Bid, 0, Ask+stoploss*_Point, 0, NULL, OrderMagic);
      return;
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LotsOptimized() {
   CAccountInfo myaccount;
   SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   double lot;

   lot=NormalizeDouble(myaccount.FreeMargin()*MaximumRisk/1000.0,2);
   if(CustomLot!=0.0) lot=CustomLot;

   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   int ratio=(int)MathRound(lot/volume_step);
   if(MathAbs(ratio*volume_step-lot)>0.0000001) {
      lot = ratio*volume_step;
   }
   if(lot<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN)) lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(lot>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   return(lot);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int countOrders(int a) {
   int result=0;
   for(int k=OrdersTotal()-1; k>=0; k--) {
      if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES)==true)
         if(OrderType()==a && OrderMagicNumber()==OrderMagic && OrderSymbol() == _Symbol) result++;
   }
   return(result);
}

//+------------------------------------------------------------------+
//| New bar func                                                     |
//+------------------------------------------------------------------+
bool isNewBar() {
   datetime lastbar_time=datetime(SeriesInfoInteger(Symbol(),PERIOD_M5,SERIES_LASTBAR_DATE));

   if(last_time==0) {
      last_time=lastbar_time;
      return(false);
   }
   if(last_time!=lastbar_time) {
      last_time=lastbar_time;
      return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+
