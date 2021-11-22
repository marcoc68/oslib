//+------------------------------------------------------------------+
//|                                           ex-dif-fracionaria.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Graphics\Graphic.mqh>
//#include <oslib\tst\fractional_entropy.mq5>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

input int hist = 500; //tamanho do serie de dados que serah analisada.

void OnStart()
  {
 //for(double i=0.05; i<1.0; plotFFD(i+=0.05,1e-5))     
   for(double i=0.50; i<1.0; plotFFD(i+=0.01,1e-5))     
  }
//+------------------------------------------------------------------+
void plotFFD(double fd, double thresh) {
   Print("***FD:",fd, "***THRESH:",thresh);
   double prarr[], out[];

   datetime dtIni = D'2020.08.14 09:00:00';
   datetime dtFim = D'2020.08.14 19:00:00';
   CopyClose(_Symbol, _Period, dtIni, dtFim, prarr);
 //CopyClose(_Symbol, 0, 0, hist, prarr);
   
   for(int i=0; i < ArraySize(prarr); i++)
      prarr[i] = log(prarr[i]);
    
   frac_diff_ffd(prarr, fd, thresh, out);
   GraphPlot(out,1); Sleep(2000);
}
//+------------------------------------------------------------------+

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
//+------------------------------------------------------------------+
// Calculate the cross-sample entropy of 2 signals
// u : signal 1
// v : signal 2
// m : length of the patterns that compared to each other
// r : tolerance
// return the cross-sample entropy value
double cross_SampEn(double &u[], double &v[], int m, double r) {
    double B = 0.0;
    double A = 0.0;
    if (ArraySize(u) != ArraySize(v))
        Print("Error : lenght of u different than lenght of v");
    int N = ArraySize(u);
    
    for(int i=0;i<(N-m);i++)
      {
         for(int j=0;j<(N-m);j++)
           {   
               double ins[]; ArrayResize(ins, m); double ins2[]; ArrayResize(ins2, m);
               ArrayCopy(ins, u, 0, i, m); ArrayCopy(ins2, v, 0, j, m);
               B += cross_match(ins, ins2, m, r) / (N - m);
               ArrayResize(ins, m+1); ArrayResize(ins2, m+1);
               ArrayCopy(ins, u, 0, i, m + 1); ArrayCopy(ins2, v, 0, j, m +1);
               A += cross_match(ins, ins2, m + 1, r) / (N - m);
           }
      }
    
    B /= N - m;
    A /= N - m;
    return -log(A / B);
}
//+------------------------------------------------------------------+
// calculation of the matching number
// it use in the cross-sample entropy calculation
double cross_match(double &signal1[], double &signal2[], int m, double r) {
    // return 0 if not match and 1 if match
    double darr[];
    for(int i=0; i<m; i++)
      {
         double ins[1]; ins[0] = MathAbs(signal1[i] - signal2[i]);
         ArrayInsert(darr, ins, 0, 0, 1);
      }    
    if(darr[ArrayMaximum(darr)] <= r)  return 1.0; else return 0.0;
}//+------------------------------------------------------------------+

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
      
      for(int l=0;l<ArraySize(w);l++)       
         output[o] += w[l]*x[i-width+l];      
      o++; } 
   ArrayResize(output,ArraySize(output)-width);
}