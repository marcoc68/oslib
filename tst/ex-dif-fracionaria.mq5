//+------------------------------------------------------------------+
//|                                           ex-dif-fracionaria.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Graphics/Graphic.mqh>

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
   for(double i=0.05; i<1.0; plotFFD(i+=0.05,1e-5))     
}
//+------------------------------------------------------------------+

void plotFFD(double fd, double thresh) {
   double prarr[], out[];
   CopyClose(_Symbol, 0, 0, 10000, prarr);
   
   for(int i=0; i < ArraySize(prarr); i++)
      prarr[i] = log(prarr[i]);
    
   frac_diff_ffd(prarr, fd, thresh, out);
   GraphPlot(out,1); Sleep(500);
}
//+------------------------------------------------------------------+

void get_weight_ffd(double d, double thres, int lim, double &w[]) {
    ArrayResize(w,1); 
    ArrayInitialize(w,1.0);
    ArraySetAsSeries(w,true);
    
    int k = 1;
    int ctr = 0;
    double w_ = 0;
    while (ctr != lim - 1) {
        w_ = -w[ctr] / k * (d - k + 1);
        if (MathAbs(w_) < thres) break;  
        ArrayResize(w,ArraySize(w)+1); 
        w[ctr+1] = w_;      
        k += 1;
        ctr += 1;
    }
}
//+------------------------------------------------------------------+

void frac_diff_ffd(double &x[], double d, double thres, double &output[]) {
   double w[];
   get_weight_ffd(d, thres, ArraySize(x), w);

   int width = ArraySize(w) - 1;
   
   ArrayResize(output, width);
   ArrayInitialize(output,0.0);
   ArraySetAsSeries(output,true);
   ArraySetAsSeries(x,true);
   ArraySetAsSeries(w,true);
   
   int o = 0;
   for(int i=width;i<ArraySize(x);i++) {
      ArrayResize(output,ArraySize(output)+1);
      
      for(int l=0;l<ArraySize(w);l++) output[o] += w[l]*x[i-width+l];      
      o++; 
   } 
   ArrayResize(output,ArraySize(output)-width);
}
