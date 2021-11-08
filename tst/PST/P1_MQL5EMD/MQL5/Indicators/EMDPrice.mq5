//+------------------------------------------------------------------+
//|                                                          EMD.mq5 |
//|                      Copyright (c) 2012-2020, victorg, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                            https://www.mql5.com/ru/articles/7601 |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2012-2020 victorg, Marketeer"
#property link "https://www.mql5.com/en/users/marketeer"
#property version "1.0"
#property description "Price Forecast based on Empirical Mode Decomposition (EMD)\n"
#property description "This indicator breaks down price line into multiple simple components - polynomial splines (Intrinsic Mode Functions, IMF) - and builds their superposition in near future."

#define BUF_NUM 1

#property indicator_chart_window
#property indicator_buffers BUF_NUM
#property indicator_plots   BUF_NUM

#property indicator_color1 DodgerBlue
#property indicator_width1 2
#property indicator_applied_price PRICE_OPEN


#include <IndArray.mqh>
IndicatorArray buffers(BUF_NUM);
IndicatorArrayGetter getter(buffers);


#include "EMD.mqh"


input int Length = 300;  // Length (bars, > 5)
input int _Offset = 0;   // Offset (0..P bars)
input int Forecast = 0;  // Forecast (0..N bars)
input int Reconstruction = 0; // Reconstruction (0..M IMFs)


int Offset;
const string ID = "EMDP_OFFSETTER";


int OnInit()
{
  Offset = _Offset;

  const datetime dt = (datetime)ObjectGetInteger(0, ID, OBJPROP_TIME, 0);
  if(dt > TimeCurrent())
  {
    Offset = 0;
  }
  else if(dt > 0)
  {
    Offset = iBarShift(_Symbol, _Period, dt);
  }
  
  IndicatorSetString(INDICATOR_SHORTNAME, "EMDPrice (" + (string)Length + ")");
  for(int i = 0; i < BUF_NUM; i++)
  {
    PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(i, PLOT_SHIFT, Forecast);
  }
  
  ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, ChartWindowFind(), true);

  showOffsetter(true);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
  int i, ret;

  ArraySetAsSeries(price, true);

  static datetime lastBar = 0;
  static int barCount = 0;

  if(iTime(NULL, 0, 0) == lastBar && barCount == rates_total && prev_calculated != 0) return rates_total;

  for(int k = 0; k < BUF_NUM; k++)
  {
    buffers[k].empty();
  }
  
  lastBar = iTime(NULL, 0, 0);
  barCount = rates_total;
  ObjectSetInteger(0, ID, OBJPROP_TIME, 0, iTime(NULL, 0, Offset)); // advance the line to next bar

  // Preparation of the input sequence
  double yy[];
  int n = Length;
  ArrayResize(yy, n, n + Forecast);

  for(i = 0; i < n; i++)
  {
    yy[i] = price[n - i + Offset - 1]; // we need to reverse for optional extrapolation
  }
  
  // EMD
  CEMD emd;
  ret = emd.decomp(yy, Forecast);
  
  if(ret < 0) return prev_calculated;

  const int N = emd.getN();
  const double mean = emd.getMean();

  n += Forecast;
  ArrayResize(yy, n);

  // Visualization
  IndicatorSetString(INDICATOR_SHORTNAME, "EMDPrice (" + (string)Length + "," + (string)N + "," + (string)(float)mean + ")");

  for(i = 0; i < BUF_NUM; i++)
  {
    PlotIndexSetInteger(i, PLOT_SHOW_DATA, i <= N + 1);
    PlotIndexSetInteger(i, PLOT_LINE_WIDTH, i == 0 ? 2 : 1);
    PlotIndexSetInteger(i, PLOT_LINE_STYLE, STYLE_SOLID);
  }

  double sum[];
  ArrayResize(sum, n);
  ArrayInitialize(sum, 0);
  
  PlotIndexSetString(0, PLOT_LABEL, "Input Line");
  
  for(i = 1; i < N; i++)
  {
    emd.getIMF(yy, i, true);
    if(i > Reconstruction)
    {
      for(int j = 0; j < n; j++)
      {
        sum[j] += yy[j];
      }
    }
  }

  emd.getIMF(yy, N, true);

  for(int j = 0; j < n; j++)
  {
    sum[j] += yy[j] + mean;
    if(j < Forecast && (Reconstruction <= 0 || Reconstruction > N - 1)) // completely fitted curve can not be forecasted (gives a constant)
    {
      sum[j] = EMPTY_VALUE;
    }
  }
  
  PlotIndexSetString(0, PLOT_LABEL, "EMD"
     + (Reconstruction > 0 ?
       " -" + (Reconstruction < N - 1 ? (string)Reconstruction : "R")
     : ""));
  
  buffers[0].set(Offset, sum);
  
  return rates_total;
}


void showOffsetter(const bool selectable = false)
{
  ObjectCreate(0, ID, OBJ_VLINE, ChartWindowFind(), iTime(_Symbol, _Period, Offset), 0);
  ObjectSetInteger(0, ID, OBJPROP_STYLE, STYLE_DOT);
  ObjectSetInteger(0, ID, OBJPROP_COLOR, ChartGetInteger(0, CHART_COLOR_GRID) & 0xFFFF);
  ObjectSetInteger(0, ID, OBJPROP_BACK, true);
  ObjectSetInteger(0, ID, OBJPROP_SELECTABLE, selectable);
  ObjectSetInteger(0, ID, OBJPROP_ZORDER, 1000);
  ObjectSetString(0, ID, OBJPROP_TEXT, "past <--> future");
}

double OnTester(void)
{
  return 0;
}

void OnDeinit(const int)
{
  ObjectDelete(0, ID);
}

#define MOUSE_LEFT 1

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp)
{
  static bool dragged = false;
  if(id == CHARTEVENT_OBJECT_DRAG && sp == ID)
  {
    dragged = true;
  }
  else if(id == CHARTEVENT_MOUSE_MOVE)
  {
    const int flags = (int)StringToInteger(sp);
    static int current = 0;
    if((current & MOUSE_LEFT) != 0 && (flags & MOUSE_LEFT) == 0)
    {
      if(dragged)
      {
        dragged = false;
        const int x = (int)lp;
        const int y = (int)dp;
        int window;
        datetime time;
        double price;
        ChartXYToTimePrice(0, x, y, window, time, price);
        
        double cursor = (double)time;
        datetime newtime = (datetime)(MathRound(cursor / PeriodSeconds()) * PeriodSeconds());

        adjust(newtime);
      }
    }
    current = flags;
  }
}

void adjust(const datetime dt)
{
  const int PrevOffset = Offset;

  if(dt + PeriodSeconds() > TimeCurrent())
  {
    Offset = 0;
    ObjectSetInteger(0, ID, OBJPROP_TIME, 0, iTime(_Symbol, _Period, 0));
    
    ChartRedraw();
  }
  else
  {
    Offset = iBarShift(_Symbol, _Period, dt);
  }
  
  if(PrevOffset != Offset)
  {
    // we need this because OnCalculate can be called before we update Offset,
    // and the line is moved to its previous place before the dragging
    ObjectSetInteger(0, ID, OBJPROP_TIME, 0, iTime(_Symbol, _Period, Offset));
    ChartSetSymbolPeriod(0, NULL, 0);
  }
}
