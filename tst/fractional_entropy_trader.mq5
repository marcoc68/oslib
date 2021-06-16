//+------------------------------------------------------------------+
//|                                                   fractional.mq5 |
//|                                 Copyright 2019, Dmitrievsky Max. |
//|                        https://www.mql5.com/en/users/dmitrievsky |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Dmitrievsky Max."
#property link      "https://www.mql5.com/en/users/dmitrievsky"
#property version   "1.00"

#include <MT4Orders.mqh>
#include <Math\Stat\Math.mqh>
#include <Trade\AccountInfo.mqh>
#include "Auto_optimizer.mqh"

input int       History_depth = 1000;
input double    FracDiff = 0.65;
input int       Entropy_window = 50;
input int       Recalc_period = 100;
sinput double   MaximumRisk=0.01;
sinput double   CustomLot=0;
//input int       Stop_loss = 500;           //Stop loss, positions protection
input int       Stop_loss = 50;           //Stop loss, positions protection
//input int       BreakEven = 300;           //Break even
input int       BreakEven = 30;           //Break even
sinput int      OrderMagic=111;
input double    probab    = 0.0;          // probabilidade

static datetime last_time=0;

CAuto_optimizer *optimizer = new CAuto_optimizer(History_depth , // 1000
                                                 Recalc_period , // 100
                                                 FracDiff      , // 0.15
                                                 Entropy_window, // 50
                                                 probab
                                                );
double sig1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   if(!isNewBar())
      return;
   
   MqlDateTime dt;   
   TimeCurrent(dt);
   if( dt.hour == 9  ){ if( dt.min < 10 ) return; }
   if( dt.hour >= 16 ){ if( dt.min >  0 ) return; }
      
   Trailing_fnc(Stop_loss, BreakEven);
   sig1 = optimizer.getTradeSignal();
   placeOrders();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void placeOrders(){
   if(countOrders(0)!=0 || countOrders(1)!=0)   {
      for(int b=OrdersTotal()-1; b>=0; b--)
         if(OrderSelect(b,SELECT_BY_POS)==true) {
          Print("sig1:",sig1);
          if(OrderType()==0 && sig1 < 0.5-probab) if(OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Red )) {};
          if(OrderType()==1 && sig1 > 0.5+probab) if(OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Blue)) {};
      }
    }
   
   if(countOrders(0)!=0 || countOrders(1)!=0) return;
   //double prices[];
   //CopyClose(NULL, 0, 0, 500, prices);
   //if(sample_entropy(prices, 2, 0.2, ArraySize(prices), MathStandardDeviation(prices))< 0.4) return;
   if(sig1 > 0.5+probab && (OrderSend(Symbol(),OP_BUY,lotsOptimized(),SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0,0,NULL,OrderMagic,INT_MIN)>0)) {
      do {Trailing_fnc(Stop_loss,BreakEven);} while(countOrders()==0); return; }
   if(sig1 < 0.5-probab && (OrderSend(Symbol(),OP_SELL,lotsOptimized(),SymbolInfoDouble(_Symbol,SYMBOL_BID),0,0,0,NULL,OrderMagic,INT_MIN)>0)) {
      do {Trailing_fnc(Stop_loss,BreakEven);} while(countOrders()==0);}
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int countOrders() {
 int result=0;
 for(int k=0; k<OrdersTotal(); k++) {
  if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES)==true)
   if(OrderMagicNumber()==OrderMagic && OrderSymbol() == _Symbol) result++; }
 return(result); }

int countOrders(int a) {
 int result=0;
 for(int k=0; k<OrdersTotal(); k++) {
  if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES)==true)
   if(OrderType()==a && OrderMagicNumber()==OrderMagic && OrderSymbol() == _Symbol) result++; }
 return(result); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double lotsOptimized()
  {
   double lot;

   if(MQLInfoInteger(MQL_OPTIMIZATION)==true)
     {
      lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
      return lot;
     }
   CAccountInfo myaccount; SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   lot=NormalizeDouble(myaccount.FreeMargin()*MaximumRisk/1000.0,2);
   if(CustomLot!=0.0) lot=CustomLot;

   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   int ratio=(int)MathRound(lot/volume_step);
   if(MathAbs(ratio*volume_step-lot)>0.0000001)
      lot=ratio*volume_step;

   if(lot<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN)) lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(lot>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   return(lot);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBar()
  {
   datetime lastbar_time=datetime(SeriesInfoInteger(Symbol(),_Period,SERIES_LASTBAR_DATE));
   if(last_time==0)
     {
      last_time=lastbar_time;
      return(false);
     }
   if(last_time!=lastbar_time)
     {
      last_time=lastbar_time;
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//| Expert ontester function                                         |
//+------------------------------------------------------------------+
double OnTester()
  {
   delete optimizer;
   return(0.0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(MQLInfoInteger(MQL_TESTER)==false)
     {
      delete optimizer;
     }
  }

//+------------------------------------------------------------------+
//| Trailing function                                                |
//+------------------------------------------------------------------+
int Trailing_fnc(int trail_p,int breakeven) {
     int result=0;
     for(int i=0;i<OrdersTotal();i++) {
          if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
               if(OrderSymbol()==_Symbol && OrderMagicNumber()==OrderMagic) {
                    long ValidStop  =SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL );
                    long ValidFreeze=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
                    if(trail_p  <ValidStop  ) trail_p  =int(ValidStop  +5*SymbolInfoDouble(_Symbol,SYMBOL_POINT));
                    if(breakeven<ValidStop  ) breakeven=int(ValidStop  +5*SymbolInfoDouble(_Symbol,SYMBOL_POINT));
                    if(trail_p  <ValidFreeze) trail_p  =int(ValidFreeze+5*SymbolInfoDouble(_Symbol,SYMBOL_POINT));
                    if(breakeven<ValidFreeze) breakeven=int(ValidFreeze+5*SymbolInfoDouble(_Symbol,SYMBOL_POINT));
                
                     if(OrderType() == 0) {
                          if(SymbolInfoDouble(_Symbol,SYMBOL_BID)>OrderOpenPrice()+
                             breakeven*SymbolInfoDouble(_Symbol,SYMBOL_POINT)+
                             SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)*SymbolInfoDouble(_Symbol,SYMBOL_POINT)
                             && SymbolInfoDouble(_Symbol,SYMBOL_BID)-breakeven*SymbolInfoDouble(_Symbol,SYMBOL_POINT)-
                             SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)*SymbolInfoDouble(_Symbol,SYMBOL_POINT)>OrderStopLoss()) {
                           if(!OrderModify(OrderTicket(),OrderOpenPrice(),SymbolInfoDouble(_Symbol,SYMBOL_BID)-breakeven*SymbolInfoDouble(_Symbol,SYMBOL_POINT),OrderTakeProfit(),OrderExpiration(),0)) {result=1;} }
                           else if(!OrderStopLoss()) if(!OrderModify(OrderTicket(),OrderOpenPrice(),SymbolInfoDouble(_Symbol,SYMBOL_BID)-
                                   trail_p*SymbolInfoDouble(_Symbol,SYMBOL_POINT)-SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)*SymbolInfoDouble(_Symbol,SYMBOL_POINT),OrderTakeProfit(),OrderExpiration(),0)) {result=1;}
                     }
                
                     if(OrderType() == 1) {
                          if(SymbolInfoDouble(_Symbol,SYMBOL_ASK)<OrderOpenPrice()-
                             breakeven*SymbolInfoDouble(_Symbol,SYMBOL_POINT)-
                             SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)*SymbolInfoDouble(_Symbol,SYMBOL_POINT)
                             && SymbolInfoDouble(_Symbol,SYMBOL_ASK)+breakeven*SymbolInfoDouble(_Symbol,SYMBOL_POINT)+
                             SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)*SymbolInfoDouble(_Symbol,SYMBOL_POINT)<OrderStopLoss()) {             
                           if(!OrderModify(OrderTicket(),OrderOpenPrice(),SymbolInfoDouble(_Symbol,SYMBOL_ASK)+breakeven*SymbolInfoDouble(_Symbol,SYMBOL_POINT),OrderTakeProfit(),OrderExpiration(),0)) {result=1;} }
                           else if(!OrderStopLoss()) if(!OrderModify(OrderTicket(),OrderOpenPrice(),SymbolInfoDouble(_Symbol,SYMBOL_ASK)+
                                   trail_p*SymbolInfoDouble(_Symbol,SYMBOL_POINT)+SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)*SymbolInfoDouble(_Symbol,SYMBOL_POINT),OrderTakeProfit(),OrderExpiration(),0)) {result=1;}
                                   
                     } 
               } 
          } 
     } 
     return(result); 
}
               