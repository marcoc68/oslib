//+------------------------------------------------------------------+
//|                                                  adjustment2.mq5 |
//|                                            Rafael Floriani Pinto |
//|                           https://www.mql5.com/pt/users/rafaelfp |
//+------------------------------------------------------------------+
//--------------------------------------------------------------------
#property copyright "Rafael Floriani Pinto"
#property link      "https://www.mql5.com/pt/users/rafaelfp"
#property version   "2.00"
//---------------------------------------------------------------------
#include "polynomials.mqh"
#include "adjustment.mqh"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4
//--- plot High
#property indicator_label1  "High"
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Close
#property indicator_label2  "Close"
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot Open
#property indicator_label3  "Open"
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//--- plot Low
#property indicator_label4  "Low"
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
//enum colors
enum ColorEnum {
   ColorGreen = 0,
   ColorBlue,
   ColorYellow,
   ColorRed,
   ColorPink,
   ColorBlack,
   ColorWhite,
   ColorBrown,
   ColorDarkBlue,
   ColorDarkGray,
   ColorDarkViolet,
   ColorDarkGreen,
   ColorGold,
};
color ColorIndicator[] = {clrGreen, clrBlue, clrYellow, clrRed, clrPink, clrBlack, clrWhite, clrBrown, clrDarkBlue, clrDarkGray, clrDarkViolet, clrDarkGreen, clrGold};
//--- indicator buffers
double         HighBuffer[];
double         CloseBuffer[];
double         OpenBuffer[];
double         LowBuffer[];
input int Coefficient = 1; //Polynomial coefficiente
input int NumberOfCandles = 15; //Numbers of candles
input int CandlesDelay = 0; // Candles delay
input ENUM_TIMEFRAMES PeriodToCalculate = PERIOD_CURRENT; //Period to calculate
input group "Switch Buffers"
input bool SwitchHigh = true; //Switch High
input bool SwitchClose = true; // Switch Close
input bool SwitchOpen = true; // Switch Open
input bool SwitchLow = true; //Switch Low
input group "Switch Buffers Plot"
input bool SwitchHighPlot = true; //Plot High
input bool SwitchClosePlot = true; // Plot Close
input bool SwitchOpenPlot = true; //Plot Open
input bool SwitchLowPlot = true; //Plot Low
input group "Buffer Plot Line Width"
input int HighPlotLineWidth = 2;  // Plot High Width
input int ClosePlotLineWidth = 2; // Plot Close Width
input int OpenPlotLineWidth = 2; //Plot Open Width
input int LowPlotLineWidth = 2; //Plot Low Width
input group "Buffer Plot Line Color"
input ColorEnum HighPlotColor = ColorGreen; //Plot High Color
input ColorEnum ClosePlotColor = ColorBlue; // Plot Close Color
input ColorEnum OpenPlotColor = ColorYellow; // Plot Open Color
input ColorEnum LowPlotColor = ColorRed; // Plot Low Color
double HighB[], LowB[], CloseB[], OpenB[];
double ArrayToX[];
double CoefHigh[], CoefLow[], CoefClose[], CoefOpen[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   if(Coefficient < 0 || CandlesDelay < 0) {
      printf("Coefficiente and CandlesDelay must be greater then zero");
      return(INIT_FAILED);
   }
   if(NumberOfCandles < 1) {
      printf("NumberOfCanfles must be greater then or equal to one");
      return(INIT_FAILED);
   }
   if(!SwitchHigh && !SwitchClose && !SwitchOpen && !SwitchLow) {
      printf("No minimum one of Switch must be true");
      return(INIT_FAILED);
   }
   if(HighPlotLineWidth < 0 || ClosePlotLineWidth < 0 || OpenPlotLineWidth < 0 || LowPlotLineWidth < 0) {
      printf("Every PlotLineWidth must be greater then zero");
      return(INIT_FAILED);
   }
//I0
   SetIndexBuffer(0, HighBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
   if(SwitchHighPlot) {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   } else {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
   }
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, HighPlotLineWidth);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, ColorIndicator[HighPlotColor]);
//I1
   SetIndexBuffer(1, CloseBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0);
   if(SwitchClosePlot) {
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   } else {
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
   }
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, ClosePlotLineWidth);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, ColorIndicator[ClosePlotColor]);
//I2
   SetIndexBuffer(2, OpenBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0);
   if(SwitchOpenPlot) {
      PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);
   } else {
      PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_NONE);
   }
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, OpenPlotLineWidth);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, ColorIndicator[OpenPlotColor]);
//I3
   SetIndexBuffer(3, LowBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0);
   if(SwitchLowPlot) {
      PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_LINE);
   } else {
      PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_NONE);
   }
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, LowPlotLineWidth);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, ColorIndicator[LowPlotColor]);
   printf("Starting Indicator..");
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
                const int &spread[]) {
   if(rates_total > prev_calculated) {
      AjusteV2DefinirX(ArrayToX, NumberOfCandles);
      int K = rates_total - NumberOfCandles - CandlesDelay;
      if(SwitchOpen) {
         CopyOpen(_Symbol, PeriodToCalculate, CandlesDelay, NumberOfCandles, OpenB);
         if(minquadrados(ArrayToX, OpenB, Coefficient, CoefOpen) != 1) {
            printf("Something wrong happened,Indicator will be reset");
            OnInit();
         }
         ZeroMemory(OpenBuffer);
         for(int i = K; i < rates_total; i++) {
            OpenBuffer[i] = valpoli(CoefOpen, i - K);
         }
      } else {
         ZeroMemory(OpenBuffer);
      }
      if(SwitchClose) {
         CopyClose(_Symbol, PeriodToCalculate, CandlesDelay, NumberOfCandles, CloseB);
         if(minquadrados(ArrayToX, CloseB, Coefficient, CoefClose) != 1) {
            printf("Something wrong happened,Indicator will be reset");
            OnInit();
         }
         ZeroMemory(CloseBuffer);
         for(int i = K; i < rates_total; i++) {
            CloseBuffer[i] = valpoli(CoefClose, i - K);
         }
      } else {
         ZeroMemory(CloseBuffer);
      }
      if(SwitchHigh) {
         CopyHigh(_Symbol, PeriodToCalculate, CandlesDelay, NumberOfCandles, HighB);
         if(minquadrados(ArrayToX, HighB, Coefficient, CoefHigh) != 1) {
            printf("Something wrong happened,Indicator will be reset");
            OnInit();
         }
         ZeroMemory(HighBuffer);
         for(int i = K; i < rates_total; i++) {
            HighBuffer[i] = valpoli(CoefHigh, i - K);
         }
      } else {
         ZeroMemory(HighBuffer);
      }
      if(SwitchLow) {
         CopyLow(_Symbol, PeriodToCalculate, CandlesDelay, NumberOfCandles, LowB);
         if(minquadrados(ArrayToX, LowB, Coefficient, CoefLow) != 1) {
            printf("Something wrong happened,Indicator will be reset");
            OnInit();
         }
         ZeroMemory(LowBuffer);
         for(int i = K; i < rates_total; i++) {
            LowBuffer[i] = valpoli(CoefLow, i - K);
         }
      } else {
         ZeroMemory(LowBuffer);
      }
   }
   return(rates_total);
}

//------------------------------------------------------------------
//    Custom function(s)
//------------------------------------------------------------------
void AjusteV2DefinirX(double &ArrayX[], int Numbers) {
   ArrayResize(ArrayX, Numbers);
   for(int i = 0; i < Numbers; i++) {
      ArrayX[i] = i;
   }
}

//+------------------------------------------------------------------+
