//+------------------------------------------------------------------+
//|                                                          EMD.mq5 |
//|                      Copyright (c) 2012-2020, victorg, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                            https://www.mql5.com/ru/articles/7601 |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2012-2020 victorg, Marketeer"
#property link "https://www.mql5.com/en/users/marketeer"
#property version "1.0"
#property description "Empirical Mode Decomposition (EMD)\n"
#property description "This indicator breaks down Open[] price line into multiple simple components - polynomial splines (Intrinsic Mode Functions, IMF)."

#define BUF_NUM 18 // 16 IMF maximum (including input at 0-th index) + residue + reconstruction

#property indicator_separate_window
#property indicator_buffers BUF_NUM
#property indicator_plots   BUF_NUM

#property indicator_color1 Green
#property indicator_width1 2
#property indicator_color2 DarkBlue
#property indicator_color3 Red
#property indicator_color4 Gray
#property indicator_color5 Peru
#property indicator_color6 Gold
#property indicator_color7 Purple
#property indicator_color8 Teal
#property indicator_color9 Lime
#property indicator_color10 Aqua
#property indicator_color11 DarkOrange
#property indicator_color12 LightGray
#property indicator_color13 MediumSlateBlue
#property indicator_color14 Olive
#property indicator_color15 Magenta
#property indicator_color16 MediumAquamarine
#property indicator_color17 RosyBrown
#property indicator_color18 Yellow


#include <IndArray.mqh>
IndicatorArray buffers(BUF_NUM);
IndicatorArrayGetter getter(buffers);


#include "EMD.mqh"


input int Length = 300;  // Length (bars, > 5)
input int _Offset = 0;   // Offset (0..P bars)
input int Forecast = 0;  // Forecast (0..N bars)
input int Reconstruction = 0; // Reconstruction (0..M IMFs)


int Offset;
string ID = "EMD_OFFSETTER_";


int OnInit()
{
  ID += (string)ChartWindowFind();
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
  
  IndicatorSetString(INDICATOR_SHORTNAME, "EMD (" + (string)Length + ")");
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
                const datetime& Time[],
                const double& Open[],
                const double& High[],
                const double& Low[],
                const double& Close[],
                const long& Tick_volume[],
                const long& Volume[],
                const int& Spread[])
{
  int i, ret;

  ArraySetAsSeries(Time, true);
  ArraySetAsSeries(Open, true);

  static datetime lastBar = 0;
  static int barCount = 0;

  if(Time[0] == lastBar && barCount == rates_total && prev_calculated != 0) return rates_total;
  
  if(rates_total < Length || ArraySize(Time) < Length) return prev_calculated;
  if(rates_total - 1 < Offset || ArraySize(Time) - 1 < Offset) return prev_calculated;

  for(int k = 0; k < BUF_NUM; k++)
  {
    buffers[k].empty();
  }
  
  lastBar = Time[0];
  barCount = rates_total;
  ObjectSetInteger(0, ID, OBJPROP_TIME, 0, Time[Offset]); // advance the line to next bar

  // Preparation of the input sequence
  double yy[];
  int n = Length;
  ArrayResize(yy, n, n + Forecast);

  for(i = 0; i < n; i++)
  {
    yy[i] = Open[n - i + Offset - 1]; // we need to reverse for optional extrapolation
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
  IndicatorSetString(INDICATOR_SHORTNAME, "EMD (" + (string)Length + "," + (string)N + "," + (string)Offset + ")");

  for(i = 0; i < BUF_NUM; i++)
  {
    PlotIndexSetInteger(i, PLOT_SHOW_DATA, i <= N + 1);
    PlotIndexSetInteger(i, PLOT_LINE_WIDTH, i == N + 1 ? 2 : 1);
    PlotIndexSetInteger(i, PLOT_LINE_STYLE, STYLE_SOLID);
  }

  PlotIndexSetString(N + 1, PLOT_LABEL, "Input Line " + (string)(float)mean);
  
  emd.getIMF(yy, 0, true);
  if(Forecast > 0)
  {
    for(i = 0; i < Forecast; i++) yy[i] = EMPTY_VALUE;
  }
  buffers[N + 1].set(Offset, yy);

  double sum[];
  ArrayResize(sum, n);
  ArrayInitialize(sum, 0);

  for(i = 1; i < N; i++)
  {
    PlotIndexSetString(i, PLOT_LABEL, "IMF " + (string)i);
    emd.getIMF(yy, i, true);
    buffers[i].set(Offset, yy);
    if(i > Reconstruction)
    {
      for(int j = 0; j < n; j++)
      {
        sum[j] += yy[j];
      }
    }
  }

  PlotIndexSetString(N, PLOT_LABEL, "Residue");
  PlotIndexSetInteger(N, PLOT_LINE_STYLE, STYLE_DOT);
  emd.getIMF(yy, N, true);
  buffers[N].set(Offset, yy);

  for(int j = 0; j < n; j++)
  {
    sum[j] += yy[j];
    if(j < Forecast && (Reconstruction <= 0 || Reconstruction > N - 1)) // completely fitted curve can not be forecasted (gives a constant)
    {
      sum[j] = EMPTY_VALUE;
    }
  }
  
  PlotIndexSetString(0, PLOT_LABEL, "Reconstruction"
     + (Reconstruction > 0 ?
       " -" + (Reconstruction < N - 1 ? (string)Reconstruction : (Reconstruction == N - 1 ? "R" : "X"))
     : ""));
  PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);
  
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

void OnDeinit(const int reason)
{
  if(reason != REASON_RECOMPILE
  && reason != REASON_CHARTCHANGE
  && reason != REASON_ACCOUNT
  && reason != REASON_PARAMETERS)
  {
    ObjectDelete(0, ID);
  }
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
