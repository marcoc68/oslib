﻿//+------------------------------------------------------------------+
//|                                     Strategy1_AngleChange_EA.mq5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//| Spread strategy type                                             |
//+------------------------------------------------------------------+
enum SPREAD_STRATEGY
  {
   BUY_AND_SELL_ON_UP,  // Buy 1-st, Sell 2-nd
   SELL_AND_BUY_ON_UP,  // Sell 1-st, Buy 2-nd
  };
//---
input int       LR_length=100;                     // Number of bars for a regression on spread
input int       Spread_length=500;                 // Number of bars for spread calculation
input ENUM_TIMEFRAMES  period=PERIOD_M5;           // Time-frame
input string    symbol1="Si-12.16";                // The first symbol of the pair 
input string    symbol2="RTS-12.16";               // The second symbol of the pair
input double    profit_percent=10;                 // Percent of profit to lock in
input SPREAD_STRATEGY strategy=SELL_AND_BUY_ON_UP; // Type of a spread strategy
//--- Indicator handles
int ind_spreadLR,ind,ind_2_symbols;
//--- A class for trading operations
CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ind_spreadLR=iCustom(_Symbol,period,"Regression\\SpreadRegression_Ind",LR_length,Spread_length,period,symbol1,symbol2);
   if(ind_spreadLR==INVALID_HANDLE)
     {
      PrintFormat("Failed to create % indicator handle, error %d",
                  "SpreadRegression_Ind",GetLastError());
      return(INIT_FAILED);
     }
   ind_2_symbols=iCustom(_Symbol,period,"Regression\\TwoSymbolsSpread_Ind",Spread_length,period,symbol1,symbol2);
   if(ind_2_symbols==INVALID_HANDLE)
     {
      PrintFormat("Failed to create % indicator handle, error %d",
                  "TwoSymbolsSpread_Ind",GetLastError());
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- The A coefficient of the linear regression slope on the spread chart Y(X)=A*X+B
   static double Spread_A_prev=0;
   if(isNewBar())
      PrintFormat("New bar %s opened at %s",_Symbol,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
//--- Wait for indicator data to refresh, because it works on two symbols
   if(BarsCalculated(ind_spreadLR)==Bars(_Symbol,_Period))
     {
      //--- Get linear regression values on the spread chart for bars with indices 1 and 2 ("yesterday" and "the day before yesterday")
      double LRvalues[];
      double Spread_A_curr;
      int copied=CopyBuffer(ind_spreadLR,1,1,2,LRvalues);
      if(copied!=-1)
        {
         //--- Linear regression coefficient on the last completed ("yesterday") bar
         Spread_A_curr=LRvalues[1]-LRvalues[0];
         //--- If the linear regression slope has changed, the product of current and previous value is less than zero
         if(Spread_A_curr*Spread_A_prev<0)
           {
            PrintFormat("Slope of LR changed, Spread_A_curr=%.2f, Spread_A_prev=%.2f: %s",
                        Spread_A_curr,Spread_A_prev,TimeToString(TimeCurrent(),TIME_SECONDS));
            //--- If we have no open positions, enter the market with both symbols
            if(PositionsTotal()==0)
               DoTrades(Spread_A_curr-Spread_A_prev>0,strategy,symbol1,1,symbol2,1);
            //--- There are open positions, reverse them
            else
               ReverseTrades(symbol1,symbol2);
           }
         //--- LR slope has not changed, check the floating profit - isn't it time to close?
         else
           {
            double profit=AccountInfoDouble(ACCOUNT_PROFIT);
            double balance=AccountInfoDouble(ACCOUNT_BALANCE);
            if(profit/balance*100>=profit_percent)
              {
               //--- Required floating profit level reached, take it 
               trade.PositionClose(symbol1);
               trade.PositionClose(symbol2);
              }
           }
         //--- Remember trend direction to compare at the opening of a new bar
         Spread_A_prev=Spread_A_curr;
        }
     }
  }
//+------------------------------------------------------------------+
//| Reverse positions on the specified symbols                       |
//+------------------------------------------------------------------+
void ReverseTrades(string sym1, string sym2)
  {
   int pos=PositionsTotal();
   for(int i=0;i<pos;i++)
     {
      string symbol=PositionGetSymbol(i);
      if((symbol==sym1)||(symbol==sym2))
        {
         double vol=PositionGetDouble(POSITION_VOLUME);
         double rev_vol=2*vol;
         ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(type==POSITION_TYPE_BUY)
            trade.Sell(rev_vol,symbol);
         if(type==POSITION_TYPE_SELL)
            trade.Buy(rev_vol,symbol);

        }
     }
  }
//+------------------------------------------------------------------+
//| Buying the first asset and selling the seconds one               |
//+------------------------------------------------------------------+
void DoTrades(bool up_trend,SPREAD_STRATEGY strategy_on_up,
              string sym1,double lot1,string sym2,double lot2)
  {
//--- Positive spread
   if(up_trend)
     {
      if(strategy_on_up==BUY_AND_SELL_ON_UP)
         //--- Buying and selling 
         BuyAndSell(sym1,sym2,lot1,lot2);
      else
      //--- Selling and buying
         SellAndBuy(sym1,sym2,lot1,lot2);
     }
//--- Negative spread
   else
     {
      if(strategy_on_up==BUY_AND_SELL_ON_UP)
         //--- Selling and buying
         SellAndBuy(sym1,sym2,lot1,lot2);
      else
      //--- Buying and selling 
         BuyAndSell(sym1,sym2,lot1,lot2);
     }
  }
//+------------------------------------------------------------------+
//| Buying sym1 and selling sym2                                     |
//+------------------------------------------------------------------+
bool BuyAndSell(string sym1,string sym2,double lot1,double lot2)
  {
//--- Buying and selling 
   trade.Buy(lot1,sym1);
   trade.Sell(lot2,sym2);
//--- 
   return true;
  }
//+------------------------------------------------------------------+
//| Selling sym1 and buying sym2                                     |
//+------------------------------------------------------------------+
bool SellAndBuy(string sym1,string sym2,double lot1,double lot2)
  {
//--- Buying and selling 
   trade.Sell(lot1,sym1);
   trade.Buy(lot2,sym2);
//--- 
   return true;
  }
//+------------------------------------------------------------------+
//| Returns true when a new bar appears                              |
//+------------------------------------------------------------------+
bool isNewBar()
  {
   static datetime prevbartime=0;
   datetime time_last[1];
//---- Getting the opening time of the last completed bar
   CopyTime(_Symbol,PERIOD_M5,0,1,time_last);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(time_last[0]!=prevbartime)
     {
      prevbartime=time_last[0];
      return(true);
     }
   else
      return(false);
  }
//+------------------------------------------------------------------+
