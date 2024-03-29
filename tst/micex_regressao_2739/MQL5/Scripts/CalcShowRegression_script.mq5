﻿//+------------------------------------------------------------------+
//|                                    CalcShowRegression_script.mq5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs
//--- Include files
#include <Math\Alglib\alglib.mqh>
#include <Graphics\Graphic.mqh>
//--- input parameters
input int             bars=500;            // Number of bars
input ENUM_TIMEFRAMES timeframe=PERIOD_M5; // Time-frame
input string          symbol1="WIN$";      // Leg A
input string          symbol2="WDO$";      // Leg B 
input int             show_time=10;        // Duration of chart display in seconds
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- Close prices of two financial instruments
   double closes1[],closes2[];
//--- Copy Close prices of the first instrument
   int copied=CopyClose(symbol1,timeframe,1,bars,closes1);
   if(copied!=bars)
     {
      PrintFormat("Error! %s copied just %d bars out of %d",symbol1,copied,bars);
      return;
     }
//--- Copy Close prices of the second instrument
   copied=CopyClose(symbol2,timeframe,1,bars,closes2);
   if(copied!=bars)
     {
      PrintFormat("Error! %s recieved just %d bars out of %d",symbol2,copied,bars);
      return;
     }
//---
   CLinearRegression regression(closes2,closes1,symbol2,symbol1);
   regression.Plot();
   if(IS_DEBUG_MODE)
     {
      MessageBox("The script is running in debug mode, go to MetaEditor to view");
      DebugBreak();
     }
   else
     {
      int seconds=show_time;
      while(seconds>=0)
        {
         Comment("Chart will be deleted after ",seconds," seconds");
         Sleep(1000);
         seconds--;
        }
      Comment("");
     }
  }
//+------------------------------------------------------------------+
//| Class to draw a regression line on two arrays                    |
//+------------------------------------------------------------------+
class CLinearRegression
  {
private:
   double            m_x[];      // Data of the first array
   double            m_y[];      // Data of the second array
   double            m_a;        // coefficient A in regression Y=A*X+B
   double            m_b;        // coefficient B in regression Y=A*X+B
   double            m_x1;
   double            m_y1;
   double            m_x2;
   double            m_y2;
   CGraphic          m_graphic;  // Class for drawing the chart
   string            m_xname;    // The name for the first array data
   string            m_yname;    // The name for the second array data

public:
                     CLinearRegression(const double &x[],const double &y[],
                                                         const string xname,const string yname);
                    ~CLinearRegression(){m_graphic.Destroy();};
   void              Plot(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLinearRegression::CLinearRegression(const double &x[],const double &y[],
                                     const string xname,const string yname)
  {
   int size=ArraySize(x);
   if(ArraySize(x)!=ArraySize(y) || size<=0)
      return;
   m_xname=xname;
   m_yname=yname;  
   ArraySetAsSeries(m_x,true);
   ArraySetAsSeries(m_y,true);
//---   
   ArrayCopy(m_x,x);
   ArrayCopy(m_y,y);  
   m_x1=m_x[0];
   m_x2=m_x[0];
   CMatrixDouble xy(size,2);
   xy[0].Set(0, m_x[0]);
   xy[0].Set(1, m_y[1]);
   for(int i=1; i<size; i++)
     {
      //---   
      if(m_x1>m_x[i])
         m_x1=m_x[i];
      if(m_x2<m_x[i])
         m_x2=m_x[i];
      //---
      xy[i].Set(0,m_x[i]);
      xy[i].Set(1,m_y[i]);
     }
//--- Calculating linear regression
   CLinReg linear_regression;
   CLinearModel linear_model;
   CLRReport linear_report;
   int retcode;
   linear_regression.LRBuild(xy,size,1,retcode,linear_model,linear_report);
   if(retcode!=1)
      Print("Linear regression failed, error code=",retcode);
   int nvars;
   double v[];
   linear_regression.LRUnpack(linear_model,v,nvars);
   m_a=v[0];
   m_b=v[1];
   m_y1 = m_b + m_a*m_x1;
   m_y2 = m_b + m_a*m_x2;
   PrintFormat("%s  A=%G  B=%G",__FILE__,m_a,m_b);
  }
//+------------------------------------------------------------------+
//| Plot linear regression                                           |
//+------------------------------------------------------------------+
void CLinearRegression::Plot(void)
  {
   double xr[2];
   double yr[2];
   xr[0]=m_x1;
   xr[1]=m_x2;
   yr[0]=m_y1;
   yr[1]=m_y2;
//--- Linear regression equation
   string equal="y="+StringFormat("%.3g",m_b)+"+"+StringFormat("%.3g",m_a)+"x";
//--- Set the field size to the left
   m_graphic.BackgroundMainSize(35); // Font size for the chart header
   m_graphic.BackgroundMain("Linear regression");  // Chart header
//--- Names of axes
   m_graphic.YAxis().NameSize(15);     // Font size for the X axis 
   m_graphic.XAxis().MaxLabels(12);    // max number of labels on the X axis
   m_graphic.XAxis().ValuesSize(13);   // Font size for the values on the X axis
   m_graphic.XAxis().Name(m_xname);    // The name of the X axis
   m_graphic.XAxis().NameSize(15);     // Font size for the name of the X axis   
//--- y axis setting      
   m_graphic.XAxis().NameSize(15);     // Font size for the Y axis 
   m_graphic.YAxis().ValuesWidth(45);  // Length of values along the Y axis 
   m_graphic.YAxis().ValuesSize(13);   // Font size for the values on the Y axis
   m_graphic.YAxis().Name(m_yname);    // The name of the Y axis
   m_graphic.YAxis().NameSize(15);     // Font size for the name of the Y axis   
//--- Creating the chart
   m_graphic.BackgroundMainSize(25);
   m_graphic.HistoryNameSize(13);
   m_graphic.HistoryNameWidth(StringLen(equal)*7);
   m_graphic.XAxis().Name(m_xname);
   m_graphic.YAxis().Name(m_yname);
   m_graphic.Create(0,"LinearRegression",0,30,35,800,450);
   m_graphic.CurveAdd(m_x,m_y,CURVE_POINTS,m_xname+" "+m_yname);
   m_graphic.CurveAdd(xr,yr,CURVE_LINES,equal);
   m_graphic.CurvePlotAll();
   m_graphic.Update();
  }
//+------------------------------------------------------------------+
