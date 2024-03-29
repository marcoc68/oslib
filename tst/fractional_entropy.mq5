﻿//+------------------------------------------------------------------+
//|                                                   fractional.mq5 |
//|                                 Copyright 2019, Dmitrievsky Max. |
//|                        https://www.mql5.com/en/users/dmitrievsky |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Dmitrievsky Max."
#property link      "https://www.mql5.com/en/users/dmitrievsky"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1

#include <Math\Stat\Math.mqh>
//+----------------------------------------------+
//| Indicaor display parameters                  |
//+----------------------------------------------+
//--- draw indicaor 1 as a line
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- draw the indicator's bullish label
#property indicator_label1  "Fracdiff"

double ind_buffer[], calc_buffer[];
double weights[];

input bool   entropy_eval   = true; // exibir leituras de entropia ou incremento
input double diff_degree    = 0.3 ; // grau de diferenciacao da serie temporal
input double treshhold      = 1e-5; // limite para cortar pesos em excesso (pode ser deixado por padrao)
input int    hist_display   = 5000; // profundidade do historico exibido
input int    entropy_window = 50  ; // janela deslizante para avaliar a entropia do processo
double maxdigit, mindigit;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
      get_weight_ffd(diff_degree, treshhold, 10000, weights);
//--- indicator buffers mapping
      SetIndexBuffer(0, ind_buffer, INDICATOR_DATA);
      SetIndexBuffer(1, calc_buffer, INDICATOR_CALCULATIONS);
      PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, NULL);
      PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, NULL);
      ArraySetAsSeries(ind_buffer, true);
      ArraySetAsSeries(calc_buffer, true);
      IndicatorSetInteger(INDICATOR_DIGITS, 2);
//---
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,      // price[] array size 
                 const int prev_calculated,  // pricessed bars at the previous call 
                 const int begin,            // where the meaningful data starts from 
                 const double& price[])      // array for calculation 
  {
//---

   frac_diff_ffd(weights, price, calc_buffer, (entropy_eval) ? hist_display+entropy_window+1 : hist_display, prev_calculated !=0);  
   
   if(!entropy_eval) calc_zscore(calc_buffer, ind_buffer);   
   else {
      double prpr  []; ArrayResize(prpr  , entropy_window+1); ArraySetAsSeries(prpr  , true);
      double calcEn[]; ArrayResize(calcEn, entropy_window  ); ArraySetAsSeries(calcEn, true);
   
      for(int i=0;i<hist_display;i++){
          ArrayCopy(prpr, calc_buffer, 0, i, entropy_window + 1);
          for(int r=0;r<entropy_window;r++) calcEn[r] = (prpr[r] - prpr[r+1]) > 0 ? 1 : -1;
          double st = MathStandardDeviation(calcEn);
          ind_buffer[i] = sample_entropy(calcEn, 1, 0.01, entropy_window, st);
          if(prev_calculated != 0) break;
      }
   }
       
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
void calc_zscore(double &inp[], double &out[]) {
   static double max = DBL_MIN, min = DBL_MAX, zmean, zstd;
   double buff[]; ArraySetAsSeries(buff, true);
   ArrayCopy(buff, inp, 0, 0, hist_display);
   
   if(buff[ArrayMaximum(buff)] > max || buff[ArrayMinimum(buff)] < min) {
      max = buff[ArrayMaximum(buff)];
      min = buff[ArrayMinimum(buff)];
      zmean = MathMean(buff);
      zstd = MathStandardDeviation(buff);
   
      for(int i=0;i<hist_display;i++) {   
         if   (entropy_eval) out[i] = NormalizeDouble((buff[i] - zmean) / zstd, 2);
         else                out[i] =                 (buff[i] - zmean) / zstd;
      }
   }
   else out[0] = (buff[0] - zmean) / zstd;
}

// d    : grau de diferenciacao da serie temporal                           (padrao = 0.3 )
// thres: limite para cortar pesos em excesso (pode ser deixado por padrao) (padrao = 1e-5)
// w    : vetor de pesos. Eh a saida.
void get_weight_ffd(double d, double thres, int lim, double &w[]) {
    ArrayResize     (w,1   ); 
    ArrayInitialize (w,1.0 );
    ArraySetAsSeries(w,true);
    
    int    k   = 1;
    int    ctr = 0;
    double w_  = 0;
    while (ctr != lim - 1) {
        w_ = -w[ctr] / k * (d - k + 1); // -1 / 1 *(0.3 - 1 + 1)
        
        if (MathAbs(w_) < thres) break;
        
        ArrayResize(w,ArraySize(w)+1); 
        w[ctr+1] = w_;   
       
        k   += 1;
        ctr += 1;
    }
}

void frac_diff_ffd(const double &w[], const double &x[], double &output[], int len, bool last) {
   ArraySetAsSeries(x, true);
   //Print("ArraySize(w):",ArraySize(w), " ArraySize(x):",ArraySize(x), " len:",len, " len-entropy_window-1:",len-entropy_window-1);   
 
   int o = 0;
   output[o] = 0.0;
   for(int i=0; i<len; i++) {
    //for(int l=0;l<ArraySize(w);l++){
      for(int l=0;l<len-entropy_window-1;l++){
       //Print("ArraySize(w):",ArraySize(w), " ArraySize(x):",ArraySize(x), " len:",len, " i:",i, " l:",l);   
         output[o] += w[l]*x[i+l];
      }
      if(last)
       return;  
      o++;
      if(i < ArraySize(x)-1) output[o] = 0.0;
     }
}

double sample_entropy(double &data[], int m, double r, int N, double sd)
{
  int Cm = 0, Cm1 = 0;
  double err = 0.0, sum = 0.0;
  
  err = sd * r;
  
  for (int i = 0; i < N - (m + 1) + 1; i++) {
    for (int j = i + 1; j < N - (m + 1) + 1; j++) {      
      bool eq = true;
      //m - length series
      for (int k = 0; k < m; k++) {
        if (MathAbs(data[i+k] - data[j+k]) > err) {
          eq = false;
          break;
        }
      }
      if (eq) Cm++;
      
      //m+1 - length series
      int k = m;
      if (eq && MathAbs(data[i+k] - data[j+k]) <= err)
        Cm1++;
    }
  }
  
  if (Cm > 0 && Cm1 > 0)
    return log((double)Cm / (double)Cm1);
  else
    return 0.0; 
}