﻿//+------------------------------------------------------------------+
//|                             Strategy4_SpreadDeltaPercent_EA.mq5  |
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
input double    profit_percent=2;                  // Percent of profit to lock in
input SPREAD_STRATEGY strategy=SELL_AND_BUY_ON_UP; // Type of a spread strategy
input double    spread_delta=0.5;                  // Spread size in % to enter
//--- Indicator handles
int ind_spreadLR,ind,ind_2_symbols;
//--- A class for trading operations
CTrade trade;
//--- Type of open positions
int positionstype;
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
//--- Deleting comments from the chart
   Comment("");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isNewBar())
      PrintFormat("New bar %s opened at %s",_Symbol,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
//--- Wait for indicator data to refresh, because it works on two symbols
   if(BarsCalculated(ind_spreadLR)==Bars(_Symbol,_Period))
     {
      //--- Get spread value on the current (today) bar
      double SpreadValues[];
      int copied=CopyBuffer(ind_spreadLR,0,0,1,SpreadValues);
      double Spread_curr=SpreadValues[0]; // spread on the current incomplete bar
      if(copied!=-1)
        {
         MqlTick tick;
         SymbolInfoTick(symbol1,tick);
         double last=tick.last;
         double spread_percent=Spread_curr/last*100;
         //--- If spread % reached the spread_delta value
         if(MathAbs(spread_percent)>=spread_delta)
           {
            PrintFormat("Spread reached %.1f%% (%G) %s",
                        spread_percent,TimeToString(TimeCurrent(),TIME_SECONDS),
                        Spread_curr);
            //--- Show on the chart the values of the last ticks_for_trade trades of both symbols
            ShowLastTicksComment(spread_percent,10);
            //--- If we have no open positions, enter the market with both symbols
            if(PositionsTotal()==0)
               DoTrades(Spread_curr,strategy,symbol1,1,symbol2,1);
            //--- There are open positions, reverse them
            else
               ReverseTrades(Spread_curr,positionstype,symbol1,symbol2);
           }
         //--- Spread is within acceptable range, check the floating profit - isn't it time to close?
         else
           {
            double profit=AccountInfoDouble(ACCOUNT_PROFIT);
            double balance=AccountInfoDouble(ACCOUNT_BALANCE);
            if(profit/balance*100>=profit_percent)
              {
               //--- Required floating profit level reached, take it 
               trade.PositionClose(symbol1);
               trade.PositionClose(symbol2);
               positionstype=0;
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Returns the sign of the number                                   |
//+------------------------------------------------------------------+
int Sign(double v)
  {
   if(v>0)
      return 1;
   if(v<0)
      return -1;
   return 0;
  }
//+------------------------------------------------------------------+
//| Shows on the chart the values of last 'amount' ticks             |
//+------------------------------------------------------------------+
void ShowLastTicksComment(double spread,int amount)
  {
//--- Get the last 'amount' ticks of the two symbols
   MqlTick symbol1_ticks[],symbol2_ticks[];
   if(CopyTicks(symbol1,symbol1_ticks,COPY_TICKS_TRADE,0,amount)==-1)
      PrintFormat("Failed in CopyTicks(%s,%d), code=%d",symbol1,amount,GetLastError());
   if(CopyTicks(symbol2,symbol2_ticks,COPY_TICKS_TRADE,0,amount)==-1)
      PrintFormat("Failed in CopyTicks(%s,%d), code=%d",symbol2,amount,GetLastError());
   string comment=StringFormat("\n%s spread reached %,1f%% \n\n",
                               TimeToString(TimeCurrent(),TIME_SECONDS),spread);
   for(int i=0;i<amount;i++)
     {
      comment=comment+StringFormat("%s=%s            %s=%s\n",
                                   symbol1,
                                   TickDescription(symbol1_ticks[i]),
                                   symbol2,
                                   TickDescription(symbol2_ticks[i]));
     }
   Comment(comment);
  }
//+------------------------------------------------------------------+
//| A brief description of a tick                                    |
//+------------------------------------------------------------------+
string TickDescription(MqlTick &tick)
  {
   string desc=StringFormat("%G %s.%03I64u",
                            tick.last,                                         // Last price
                            TimeToString(tick.time,TIME_MINUTES|TIME_SECONDS), // minutes:seconds
                            tick.time_msc%1000);                               // milliseconds
   return desc;
  }
//+------------------------------------------------------------------+
//| Reverse positions on the specified symbols                       |
//+------------------------------------------------------------------+
void ReverseTrades(double spread,int pos_type,
                   string sym1,string sym2)
  {
Check if we need to reverse the position - compare trend sign and position type
<75/80/89% >
   int strat_type=(spread>0?1:-1);
   if(strat_type==pos_type)
      return;
//--- Reverse position
   int pos=PositionsTotal();
   for(int i=0;i<pos;i++)
     {
      string symbol=PositionGetSymbol(i);
      if((symbol==sym1) || (symbol==sym2))
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
   positionstype=positionstype*(-1);
  }
//+------------------------------------------------------------------+
//| Buying the first asset and selling the seconds one               |
//+------------------------------------------------------------------+
void DoTrades(double spread,SPREAD_STRATEGY strategy_on_up,
              string sym1,double lot1,string sym2,double lot2)
  {
//--- Positive spread
   if(spread>0)
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
   positionstype=Sign(spread);
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
