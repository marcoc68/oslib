﻿//+------------------------------------------------------------------+
//|                                         SpreadRegression_Ind.mq5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
s#property indicator_plots   2
//--- plot Value
#property indicator_label1  "Spread"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot LR
#property indicator_label2  "LR"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- indicator buffers
double         SpreadBuffer[];            // Spread between the price and linear regression of two instruments
double         LRBuffer[];                // Linear regression on the array of spreads
//--- Include the Alglib library
#include <Math\Alglib\alglib.mqh>
//--- input parameters
input int      LR_length=100;             // Number of values for LR calculation
input int      last_bars=500;             // Number of bars for spread calculation 
input ENUM_TIMEFRAMES period=PERIOD_M5;   // Time-frame
input string   symbol1="Si-12.16";        // Symbol A
input string   symbol2="RTS-12.16";       // Symbol B
//--- Linear regression coefficients for two symbols
double A,B;
//--- Linear regression coefficients for spreads
double A_spread,B_spread;
//--- Previous bar opening time
datetime time_prev;
//--- The bar to start calculation of regression
int start_regression=1;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- The indicator is designed for the M5 time-frame
   if(_Period!=PERIOD_M5)
     {
      Alert("Wrong time-frame, M5 is required");
      Print("The indicator can only be run on the M5 time-frame");
      return (INIT_FAILED);
     }
//--- indicator buffers mapping
   SetIndexBuffer(0,SpreadBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,LRBuffer,INDICATOR_DATA);
//--- Index elements in indicator buffers as timeseries - from present to past
   ArraySetAsSeries(SpreadBuffer,true);
   ArraySetAsSeries(LRBuffer,true);
//--- Zero values should be considered empty and should not be displayed in the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   bool first_call=(prev_calculated==0);
   if(first_call)
     {
      ZeroMemory(SpreadBuffer);
      ZeroMemory(LRBuffer);
     }
   datetime time_lastbar=time_prev;
   double x_array[],y_array[],yx[];
//--- If the bar is new, calculate values on last_bars
   if(isNewBar(time_prev))
     {
      //--- Copy prices of symbol1 and symbol2, y[0] and x[0] contain prices of the last closed bar
      if(!CopyLastCloses(y_array,x_array,symbol1,symbol2,period,time[rates_total-2],last_bars)) //
        {
         //--- Error, restore previous bar open time
         time_prev=time_lastbar;
         return(rates_total-1);
        }
      //--- Calculate linear regression on symbol1 and symbol2
      Regression(x_array,y_array,yx,A,B);      // y=A*x+B
      PrintFormat("A=%G B=%G Formula: %s=%G*%s+%G",A,B,symbol1,A,symbol2,B);

      //--- Calculate spreads on last_bars 
      FillSpreadBuffer(1,y_array,x_array,A,B);
      //--- Calculate linear regression on the array of spreads, skip the current bar
      CalculateLRBuffer();  // LR=номер_бара*A_spread + B_spread                   
      PrintFormat("Aspread=%G Bspread=%G Formula: LR=%G*Spread+(%G)",A_spread,B_spread,A_spread,B_spread);
     }
//--- Initial index for indicator calculation
   int noncalculated=rates_total-prev_calculated;
   if(noncalculated==0 || first_call)
      noncalculated=1;
//--- Fill in spreads for last noncalculated bars
   CopyLastCloses(y_array,x_array,symbol1,symbol2,period,time[rates_total-1],noncalculated);
   FillSpreadBuffer(0,y_array,x_array,A,B);
   for(int i=0;i<noncalculated;i++)
      LRBuffer[i]=A_spread*i+B_spread;
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Copies Close prices of two symbols as of the specified date      |
//+------------------------------------------------------------------+
bool CopyLastCloses(double &x_array[],double &y_array[],string sym1,string sym2,
                    ENUM_TIMEFRAMES timeframe,datetime time,int amount)
  {
   MqlRates rates1[],rates2[];
   ArraySetAsSeries(rates1,true);
   ArraySetAsSeries(rates2,true);
//--- Copy the price series of the first symbol to rates1
   int copied=CopyRates(sym1,timeframe,time,amount,rates1);
   if(copied!=amount)
     {
      PrintFormat("%s Error! %s recieved just %d bars out of %d",
                  __FUNCTION__,sym1,copied,amount);
      return (false);
     }
//--- Copy the price series of the second symbol to rates2
   copied=CopyRates(sym2,timeframe,time,amount,rates2);
   if(copied!=amount)
     {
      PrintFormat("%s Error! %s recieved just %d bars out of %d",__FUNCTION__,sym2,copied,amount);
      return (false);
     }
//--- If the timeseries are synchronized, the times of last bar are equal
   if((rates1[0].time!=rates2[0].time)&&(IS_DEBUG_MODE))
     {
      PrintFormat("%s: Last bar time on %s=%s != Last bar time on %s=%s",
                  __FUNCTION__,
                  sym1,TimeToString(rates1[0].time),
                  sym2,TimeToString(rates2[0].time));
      return(false);
     }
//--- Copy prices from timeseries to arrays 
   int size=ArraySize(rates1);
   ArrayResize(x_array,size);
   ArrayResize(y_array,size);
   for(int i=0;i<size;i++)
     {
      x_array[i]=rates1[i].close;
      y_array[i]=rates2[i].close;
     }
//--- Data received
   return (true);
  }
//+------------------------------------------------------------------+
//| Calculates and fills values in SpreadBuffer                    |
//+------------------------------------------------------------------+
void FillSpreadBuffer(int shift,double &y[],double &x[],double a,double b)
  {
   int total=ArraySize(y);
//--- Fill the array of spreads
   for(int i=0;i<total;i++)
      SpreadBuffer[i+shift]=y[i]-(a*x[i]+b);
  }
//+------------------------------------------------------------------+
//| Calculates regression of SpreadBuffer and fills LRBuffer         |
//+------------------------------------------------------------------+
void  CalculateLRBuffer()
  {
//---
   double y_array[],x_array[],yx[];
   ArrayResize(y_array,LR_length);
   ArrayResize(x_array,LR_length);
   ArraySetAsSeries(x_array,true);
   ArraySetAsSeries(y_array,true);
   ArraySetAsSeries(yx,true);
//---
   for(int i=0;i<LR_length;i++) y_array[i]=SpreadBuffer[i+1];
   for(int i=0;i<LR_length;i++) x_array[i]=i+1;
//---
   Regression(x_array,y_array,yx,A_spread,B_spread);
   for(int i=0;i<LR_length;i++)
     {
      LRBuffer[i+1]=yx[i];
     }
//LRBuffer[0]=B_spread;//=0*A+B
  }
//+------------------------------------------------------------------+
//| Returns true when a new bar appears                              |
//+------------------------------------------------------------------+
bool isNewBar(datetime &prevbartime)
  {
//----
   datetime time_last[1];

   CopyTime(_Symbol,PERIOD_M5,0,1,time_last);
   if(time_last[0]!=prevbartime)
     {
      prevbartime=time_last[0];
      return(true);
     }
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Calculates linear regression Function(X)=A*X+B                   |
//+------------------------------------------------------------------+
bool Regression(double &X[],double &Y[],double &Function[],double &Acoeff,double &Bcoeff)
  {
   int size=ArraySize(Y);
   if(size!=ArraySize(X)||size==0)
     {
      PrintFormat("%s Error! Invalid array sizes");
      return (false);
     }
   ArrayResize(Function,size);
//--- Preparing xy matrix
   double x1=X[0];
   double x2=X[0];
   CMatrixDouble xy(size,2);
   xy[0].Set(0, X[0]);
   xy[0].Set(1, Y[1]);
   for(int i=1; i<size; i++)
     {
      //---   
      if(x1>X[i])
         x1=X[i];
      if(x2<X[i])
         x2=X[i];
      //---
      xy[i].Set(0,X[i]);
      xy[i].Set(1,Y[i]);
     }
//--- Calculating linear regression
   CLinReg linear_regression;
   CLinearModel linear_model;
   CLRReport linear_report;
   int retcode;
   linear_regression.LRBuild(xy,size,1,retcode,linear_model,linear_report);
   if(retcode!=1)
     {
      Print("Linear regression failed, error code=",retcode);
      return(false);
     }
   int nvars;
   double v[];
   linear_regression.LRUnpack(linear_model,v,nvars);
   Acoeff=v[0];
   Bcoeff=v[1];
   PrintFormat("%s  A=%G  B=%G",__FILE__,Acoeff,Bcoeff);
   for(int i=0;i<size;i++)
      Function[i]=Acoeff*X[i]+Bcoeff;
//--- Successful calculation
   return (true);
  }
//+------------------------------------------------------------------+  
