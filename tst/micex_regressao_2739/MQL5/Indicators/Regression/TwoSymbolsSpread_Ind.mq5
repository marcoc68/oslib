﻿//+------------------------------------------------------------------+
//|                                        TwoSymbolsSpread_Ind.mql5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot Label1
#property indicator_label1  "Spread"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrDodgerBlue,clrDarkOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- Include the Alglib library
#include <Math\Alglib\alglib.mqh>
//--- input parameters
input int             last_bars=500;         // Number of bars for calculation
input ENUM_TIMEFRAMES period=PERIOD_M5;      // Time-frame
input string          symbol1="Si-12.16";    // Symbol A
input string          symbol2="RTS-12.16";   // Symbol B
//--- indicator buffers
double         SpreadBuffer[];
double         ColorsBuffer[];
//--- linear regression coefficients 
double A,B;
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
   SetIndexBuffer(1,ColorsBuffer,INDICATOR_COLOR_INDEX);
//--- Index elements in indicator buffers as timeseries - from present to past
   ArraySetAsSeries(SpreadBuffer,true);
   ArraySetAsSeries(ColorsBuffer,true);
//--- Zero values should be considered empty and should not be displayed in the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("Spread (%s, %s)",symbol1,symbol2));
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
      ZeroMemory(SpreadBuffer);
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
     }
//--- Initial index for indicator calculation
   int noncalculated=rates_total-prev_calculated;
   if(noncalculated==0 || first_call)
      noncalculated=1;
//--- Fill in spreads for last noncalculated bars
   CopyLastCloses(y_array,x_array,symbol1,symbol2,period,time[rates_total-1],noncalculated);
   FillSpreadBuffer(0,y_array,x_array,A,B);
//--- Color the spread histogram
   for(int i=noncalculated;i>=0;i--)
      ColorsBuffer[i]=(SpreadBuffer[i]>0?0:1);
//--- return the prev_calculated value for the next call
   return(rates_total);
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
   if(rates1[0].time!=rates2[0].time)
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
     {
      SpreadBuffer[i+shift]=y[i]-(a*x[i]+b);
      ColorsBuffer[i+shift]=(SpreadBuffer[i+shift]>0?0:1);
     }
  }
//+------------------------------------------------------------------+
//| Calculates linear regression coefficients of two arrays          |
//+------------------------------------------------------------------+
bool CalculateRegression(string sym1,string sym2,ENUM_TIMEFRAMES timeframe,
                         int amount,double &Acoef,double &Bcoef)
  {
   MqlRates rates1[],rates2[];
//--- Copy the price series of the first symbol to rates1
   int copied=CopyRates(sym1,timeframe,start_regression,amount,rates1);
   if(copied!=amount)
     {
      PrintFormat("%s Error! %s recieved just %d bars out of %d. Code=",
                  __FUNCTION__,sym1,copied,amount,GetLastError());
      return (false);
     }
//--- Copy the price series of the second symbol to rates2
   copied=CopyRates(sym2,timeframe,start_regression,amount,rates2);
   if(copied!=amount)
     {
      PrintFormat("%s Error! %s recieved just %d bars out of %d. Code=",
                  __FUNCTION__,sym2,copied,amount,GetLastError());
      return (false);
     }
//--- If the series are synchronized, the times of last bar are equal
   if(rates1[amount-1].time!=rates2[amount-1].time)
     {
      PrintFormat("Last bar time on %s=%s != Last bar time on %s=%s",
                  sym1,TimeToString(rates1[amount-1].time,TIME_MINUTES),
                  sym2,TimeToString(rates2[amount-1].time,TIME_MINUTES));
      return(false);
     }
//--- Everything is good, prepare arrays for calculations
   double Y_array[],X_array[],Yx[];
   int size=ArraySize(rates1);
   ArrayResize(X_array,size);
   ArrayResize(Y_array,size);
   ArrayResize(Yx,size);
   for(int i=0;i<size;i++)
     {
      Y_array[i]=rates1[i].close;
      X_array[i]=rates2[i].close;
     }
//--- Calculate regression coefficients and Yx array with values Y(X)=A*X+B
   Regression(X_array,Y_array,Yx,Acoef,Bcoef);
   if(IS_DEBUG_MODE)
     {
      PrintFormat("A=%G B=%G Formula: %s=%G*%s+%G",Acoef,Bcoef,sym1,Acoef,sym2,Bcoef);
      int last=amount-1;
      double last_delta=Y_array[last]-Yx[last];
      PrintFormat("Check: %Y=%G   Y(X)=%G=(%G*X+%G)  Y-Y(X)=%G(%.2f%%)",
                  Y_array[last],(Acoef*X_array[last]+Bcoef),Acoef,Bcoef,last_delta,last_delta/Y_array[last]*100);

     }
//---
   return (true);
  }
//+------------------------------------------------------------------+
//| Calculates linear regression Function(X)=A*X+B                   |
//+------------------------------------------------------------------+
bool Regression(double &X[],double &Y[],double &Function[],double &Acoeff,double &Bcoeff)
  {
//---
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
