//+------------------------------------------------------------------+
//|                                                           3F.mq5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Graphics\Graphic.mqh>
#define RESULT_OR_NAN(x,expression) ((x==0)?(double)"nan":expression)
//--- Functions
double BlueFunction(double x)   { return(RESULT_OR_NAN(x,10*x*sin(1/x)));      }
double RedFunction(double x)    { return(RESULT_OR_NAN(x,sin(100*x)/sqrt(x))); }
double OrangeFunction(double x) { return(RESULT_OR_NAN(x,sin(100*x)/sqrt(-x)));}
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   double from=-1.2;
   double to=1.2;
   double step=0.005;
   CGraphic graphic;
   graphic.Create(0,"G",0,30,30,780,380);
//--- colors
   CColorGenerator generator;
   uint blue= generator.Next();
   uint red = generator.Next();
   uint orange=generator.Next();
//--- plot all curves
   graphic.CurveAdd(RedFunction,from,to,step,red,CURVE_LINES,"Red");
   graphic.CurveAdd(OrangeFunction,from,to,step,orange,CURVE_LINES,"Orange");
   graphic.CurveAdd(BlueFunction,from,to,step,blue,CURVE_LINES,"Blue");
   graphic.CurvePlotAll();
   graphic.Update();
  }
//+------------------------------------------------------------------+
