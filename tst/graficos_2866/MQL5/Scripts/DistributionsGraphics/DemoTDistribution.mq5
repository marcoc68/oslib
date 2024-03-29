﻿//+------------------------------------------------------------------+
//|                                            DemoTDistribution.mq5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Graphics\Graphic.mqh>
#include <Math\Stat\T.mqh>
#include <Math\Stat\Math.mqh>
#property script_show_inputs
//--- input parameters
input double nu_par=10;    // число степеней свободы
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- отключим показ ценового графика
   ChartSetInteger(0,CHART_SHOW,false);
//--- инициализируем генератор случайных чисел  
   MathSrand(GetTickCount());
//--- сгенерируем выборку случайной величины
   long chart=0;
   string name="GraphicNormal";
   int n=1000000;       // количество значений в выборке
   int ncells=51;       // количество интервалов в гистограмме
   double x[];          // центры интервалов гистограммы
   double y[];          // количество значений из выборки, попавших в интервал
   double data[];       // выборка случайных значений 
   double max,min;      // максимальное и минимальное значения в выборке
//--- получим выборку из T-распределения
   MathRandomT(nu_par,n,data);
//--- рассчитаем данные для построения гистограммы
   CalculateHistogramArray(data,x,y,max,min,ncells);
//--- получим границы последовательности и шаг для построения теоретической кривой
   double step;
   GetMaxMinStepValues(max,min,step);
   step=MathMin(step,(max-min)/ncells);
//--- получим теоретически рассчитанные данные на интервале [min,max]
   double x2[];
   double y2[];
   MathSequence(min,max,step,x2);
   MathProbabilityDensityT(x2,nu_par,false,y2);
//--- масштабируем
   double theor_max=y2[ArrayMaximum(y2)];
   double sample_max=y[ArrayMaximum(y)];
   double k=sample_max/theor_max;
   for(int i=0; i<ncells; i++)
      y[i]/=k;
//---     
   CGraphic graphic;
   if(ObjectFind(chart,name)<0)
      graphic.Create(chart,name,0,0,0,780,380);
   else
      graphic.Attach(chart,name);
   graphic.BackgroundMain(StringFormat("t-distribution nu=%G",nu_par));
   graphic.BackgroundMainSize(16);
//--- plot all curves
   graphic.CurveAdd(x,y,CURVE_HISTOGRAM,"Sample").HistogramWidth(6);
//--- а теперь построим теоретическую кривую плотности распределения 
   graphic.CurveAdd(x2,y2,CURVE_LINES,"Theory");
   graphic.CurvePlotAll();
//--- plot all curves
   graphic.Update();
  }
//+------------------------------------------------------------------+
//|  Calculate frequencies for data set                              |
//+------------------------------------------------------------------+
bool CalculateHistogramArray(const double &data[],double &intervals[],double &frequency[],
                             double &maxv,double &minv,const int cells=10)
  {
   if(cells<=1) return (false);
   int size=ArraySize(data);
   if(size<cells*10) return (false);
   minv=data[ArrayMinimum(data)];
   maxv=data[ArrayMaximum(data)];
   double range=maxv-minv;
   double width=range/cells;
   if(width==0) return false;
   ArrayResize(intervals,cells);
   ArrayResize(frequency,cells);
//--- зададим центры интервалов
   for(int i=0; i<cells; i++)
     {
      intervals[i]=minv+(i+0.5)*width;
      frequency[i]=0;
     }
//--- заполним частоты попадания в интервал
   for(int i=0; i<size; i++)
     {
      int ind=int((data[i]-minv)/width);
      if(ind>=cells) ind=cells-1;
      frequency[ind]++;
     }
   return (true);
  }
//+------------------------------------------------------------------+
//|  Calculates values for sequence generation                       |
//+------------------------------------------------------------------+
void GetMaxMinStepValues(double &maxv,double &minv,double &stepv)
  {
//--- вычислим абсолютный размах последовательности, чтобы получить точность нормализации
   double range=MathAbs(maxv-minv);
   int degree=(int)MathRound(MathLog10(range));
//--- нормализуем макс. и мин. значения с заданной точностью
   maxv=NormalizeDouble(maxv,degree);
   minv=NormalizeDouble(minv,degree);
//--- шаг генерации последовательности также зададим от заданной точности
   stepv=NormalizeDouble(MathPow(10,-degree),degree);
   if((maxv-minv)/stepv<10)
      stepv/=10.;
  }
//+------------------------------------------------------------------+

