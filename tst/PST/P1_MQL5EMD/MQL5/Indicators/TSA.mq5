//-----------------------------------------------------------------------------------
//                                                                            TSA.mq5
//                                        Copyright (c) 2012-2020, victorg, Marketeer
//                                            https://www.mql5.com/en/users/marketeer
//-----------------------------------------------------------------------------------
#property copyright "Copyright (c) 2012-2020 Marketeer, victorg"
#property link "https://www.mql5.com/en/users/marketeer"
#property version "1.0"
#property description "Time Series Analysis on quotes in selected price type (raw or 1-st order difference)."

#define BUF_NUM 3

#property indicator_separate_window
#property indicator_buffers BUF_NUM
#property indicator_plots   BUF_NUM

#property indicator_color1 Green
#property indicator_color2 LightGray
#property indicator_color3 LightGray
#property indicator_style2 STYLE_DOT
#property indicator_style3 STYLE_DOT


#include "TSAnalysisMod.mqh"


input TSA_TYPE Type = tsa_TimeSeries;
input int Length = 500; // Length ( >= 8)
input int Offset = 0;
input bool Differencing = false;
input int _Smoothing = 0; // Smoothing
input ENUM_MA_METHOD Method = MODE_SMA;
input ENUM_APPLIED_PRICE Price = PRICE_OPEN;
input int EMD = -1;


const string title[2] = {"TSA ", "TSD "};

#include <IndArray.mqh>
IndicatorArray buffers(BUF_NUM);
IndicatorArrayGetter getter(buffers);

int handle;
int Smoothing;

int OnInit()
{
  IndicatorSetString(INDICATOR_SHORTNAME, title[Differencing] + "(" + (string)Length + ")");
  for(int i = 0; i < BUF_NUM; i++)
  {
    PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_LINE);
  }
  
  Smoothing = _Smoothing;
  if(Smoothing <= 0)
  {
    Smoothing = 1;
  }

  if(EMD < 0)
  {
    handle = iMA(_Symbol, _Period, Smoothing, 0, Method, Price);
  }
  else
  {
    const int Forecast = 0;
    const int Reconstruction = 1;
    handle = iCustom(_Symbol, _Period, "EMD", Length, Offset, Forecast, Reconstruction);
  }
  
  return INIT_SUCCEEDED;
}

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
  int i;

  if(prev_calculated == 0)
  {
    for(i = 0; i < rates_total; i++)
    {
      for(int k = 0; k < BUF_NUM; k++)
      {
        buffers[k][i] = EMPTY_VALUE;
      }
    }
  }

  ArraySetAsSeries(Time, true);
  ArraySetAsSeries(Open, true);

  static datetime lastBar = 0;
  static int barCount = 0;

  if(Time[0] == lastBar && barCount == rates_total && prev_calculated != 0) return rates_total;
  
  lastBar = Time[0];
  barCount = rates_total;

  double data[];
  ArrayResize(data, Length);
  double value[1];
  double p1;
  
  for(i = 0; i < Length; i++)
  {
    if(CopyBuffer(handle, (EMD < 0 ? 0 : EMD), Length + Offset - i - 1, 1, value) <= 0) return prev_calculated;
    
    if(Differencing)
    {
      p1 = value[0];
      if(CopyBuffer(handle, (EMD < 0 ? 0 : EMD), Length + Offset - i, 1, value) <= 0) return prev_calculated;
      data[i] = p1 - value[0];
    }
    else
    {
      data[i] = value[0];
    }
    
    // data[i] = Open[Length + Offset - i - 1] - (Differencing ? Open[Length + Offset - i] : 0);
  }
  
  if(Type == tsa_TimeSeries)
  {
    IndicatorSetString(INDICATOR_SHORTNAME, title[Differencing] + StringSubstr(EnumToString(Type), 4) + "(" + (string)Length + ")");
    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 1);
    PlotIndexSetInteger(1, PLOT_SHOW_DATA, false);
    PlotIndexSetInteger(2, PLOT_SHOW_DATA, false);
    for(i = 0; i < Length; i++)
    {
      buffers[0][i + Offset] = data[Length - i - 1];
    }
  }
  else
  {
    TSAnalysis tsa(data);

    TSStatMeasures stats;
    tsa.getStatMeasures(stats);
    StructPrint(stats);
    
    double result[];
    double bounds[];
    
    int n = tsa.getResult(Type, result);
    IndicatorSetString(INDICATOR_SHORTNAME, title[Differencing] + StringSubstr(EnumToString(Type), 4) + "(" + (string)Length + "," + (string)n + ")");
    if(Type == tsa_ACF || Type == tsa_PACF)
    {
      IndicatorSetInteger(INDICATOR_LEVELS, 3);
      IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0);
      IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, stats.UPLim);
      IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, -stats.UPLim);
      IndicatorSetString(INDICATOR_LEVELTEXT, 1, "5% significance upper level");
      IndicatorSetString(INDICATOR_LEVELTEXT, 2, "5% significance lower level");

      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_HISTOGRAM);
      PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);

      PlotIndexSetInteger(1, PLOT_SHOW_DATA, true);
      PlotIndexSetInteger(2, PLOT_SHOW_DATA, true);
      PlotIndexSetString(1, PLOT_LABEL, "Upper confidence band");
      PlotIndexSetString(2, PLOT_LABEL, "Lower confidence band");
      tsa.getResult(tsa_ACFConfidenceBandUpper, bounds);
      for(i = 0; i < n; i++)
      {
        buffers[1][i + Offset] = bounds[n - i - 1];
        buffers[2][i + Offset] = -bounds[n - i - 1];
      }
    }
    else
    {
      IndicatorSetInteger(INDICATOR_LEVELS, 0);
      const bool histogram = StringFind(EnumToString(Type), "Histogram") > -1;
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, histogram ? DRAW_HISTOGRAM : DRAW_LINE);
      PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 1 + histogram);
      PlotIndexSetInteger(1, PLOT_SHOW_DATA, false);
      PlotIndexSetInteger(2, PLOT_SHOW_DATA, false);
    }
    for(i = 0; i < n; i++)
    {
      buffers[0][i + Offset] = result[n - i - 1];
    }
  }

  return rates_total;
}

template<typename T>
void StructPrint(T &_struct)
{
  T array[1];
  array[0] = _struct;
  ArrayPrint(array);
}
