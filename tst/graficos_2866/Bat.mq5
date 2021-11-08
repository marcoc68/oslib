//+------------------------------------------------------------------+
//|                                                          Bat.mq5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Graphics\Graphic.mqh>
#define RESULT_OR_NAN(x,expression) ((x==0)?(double)"nan":expression)
//--- Functions
double BlueFunction(double x)
  {
   return(RESULT_OR_NAN((fabs(x)-1) *(fabs(x)-3),2*sqrt(-fabs(fabs(x)-1)*fabs(3-fabs(x))/
   ((fabs(x)-1)*(3-fabs(x))))*(1+fabs(fabs(x)-3)/(fabs(x)-3))*sqrt(1-pow(x/7,2))+(5+0.97*
   (fabs(x-.5)+fabs(x+.5))-3*(fabs(x-.75)+fabs(x+.75)))*(1+fabs(1-fabs(x))/(1-fabs(x)))));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double RedFunction(double x)
  {
   return(RESULT_OR_NAN(fabs(x)-4,(-3*sqrt(1-pow(x/7,2))*sqrt(fabs(fabs(x)-4)/(fabs(x)-4)))));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OrangeFunction(double x)
  {
   return(fabs(x/2)-0.0913722*(x*x)-3+sqrt(1-pow(fabs(fabs(x)-2)-1,2)));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GreenFunction(double x)
  {
   return(RESULT_OR_NAN(fabs(x)-1,(2.71052+(1.5-.5*fabs(x))-1.35526*sqrt(4-pow(fabs(x)-1,2)))*
   sqrt(fabs(fabs(x)-1)/(fabs(x)-1))+0.9));
  }
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   double from=-7;
   double to=7;
   double step=0.01;
   CGraphic graphic;
   graphic.Create(0,"G",0,30,30,780,380);
//--- colors
   CColorGenerator generator;
   uint blue= generator.Next();
   uint red = generator.Next();
   uint orange=generator.Next();
   uint green=generator.Next();
//--- plot all curves
   graphic.CurveAdd(RedFunction,from,to,step,red,CURVE_LINES,"Red");
   graphic.CurveAdd(OrangeFunction,from,to,step,orange,CURVE_LINES,"Orange");
   graphic.CurveAdd(BlueFunction,from,to,step,blue,CURVE_LINES,"Blue");
   graphic.CurveAdd(GreenFunction,from,to,step,green,CURVE_LINES,"Green");
   graphic.CurvePlotAll();
   graphic.Update();  
  }
//+------------------------------------------------------------------+
