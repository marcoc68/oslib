﻿//+------------------------------------------------------------------+
//|                                                     bAnditos.mq5 |
//|                                 Copyright 2019, Max Dmitrievskiy |
//|                        https://www.mql5.com/ru/users/dmitrievsky |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Dmitrievsky Max."
#property link      "https://www.mql5.com/en/users/dmitrievsky"
#property version   "1.00"

#include <Math\Alglib\dataanalysis.mqh>
#include <Graphics\Graphic.mqh>
//+------------------------------------------------------------------+
//|Auto optimizer class                                              |
//+------------------------------------------------------------------+
class CAuto_optimizer
  {
private:
// Logit regression model |||||||||||||||
   CMatrixDouble    LRPM;
   CLogitModel      Lmodel;
   CLogitModelShell Lshell; 
   CMNLReport       Lrep;
   int              Linfo;
   double           Lout[];
//|||||||||||||||||||||||||||||||||||||||
   int              number_of_samples, relearn_timout, relearnCounter;
   virtual void     virtual_optimizer();
   double           lVector[][2];
   int              hnd, hnd1;
   double           probab; //
   
public:
                    CAuto_optimizer(int    number_of_sampleS,  // 1000
                                    int    relearn_timeouT  ,  // 100
                                    double diff_degree      ,  // 0.5
                                    int    entropy_window   ,  // 50
                                    double probaB=0.0       ){ // 0.5
                        this.number_of_samples = number_of_sampleS;
                        this.relearn_timout    = relearn_timeouT  ;
                        this.probab            = probaB           ;
                        relearnCounter         = 0                ;
                        LRPM.Resize(this.number_of_samples, 5);
                        hnd  = iCustom(NULL, 0, "Shared Projects\\oslib\\tst\\fractional_entropy", false, diff_degree, 1e-05, number_of_sampleS, entropy_window); //soh diferenciacao fracionaria
                        hnd1 = iCustom(NULL, 0, "Shared Projects\\oslib\\tst\\fractional_entropy", true , diff_degree, 1e-05, number_of_sampleS, entropy_window); //entropia
                    }
                    ~CAuto_optimizer() {};
   double           getTradeSignal();
};

//+------------------------------------------------------------------+
//|Virtual tester                                                    |
//+------------------------------------------------------------------+
void CAuto_optimizer::virtual_optimizer(void) {
   double indarr[], indarr2[];
   CopyBuffer(hnd , 0, 1, this.number_of_samples, indarr ); //hnd : soh diferenciacao fracionaria
   CopyBuffer(hnd1, 0, 1, this.number_of_samples, indarr2); //hnd1: entropia
   ArraySetAsSeries(indarr , true); 
   ArraySetAsSeries(indarr2, true);
   
    for(int s=this.number_of_samples-1;s>=0;s--) {
      //preenchendo os parametros de entrada (variaveis independentes)...
        LRPM[s].Set(0, indarr [s]); // resultado do indicador diferenciacao fracionaria
        LRPM[s].Set(1, indarr2[s]); // resultado do indicador entropia
        LRPM[s].Set(2,         s ); // ordem
     
      //registrando, na saida, se o movimento dos precos foi para cima ou para baixo...
        if(iClose(NULL, 0, s) > iClose(NULL, 0, s+1)) { 
            LRPM[s].Set(3, 0.0);
            LRPM[s].Set(4, 1.0);
        }else{
            LRPM[s].Set(3, 1.0);
            LRPM[s].Set(4, 0.0);
        }  
    }
     
    /*
    Essa sub-rotina treina o modelo de logit.
    PARAMETROS DE ENTRADA:
        XY       - Conjunto de treinamento, matriz [0..NPoints-1,0..NVars] // [1000,5]
                   As primeiras NVars colunas armazenam valores de variaveis independentes,
                   a proxima coluna armazena o numero da classe (de 0 ateh NClasses-1)
                   a qual elemento do conjunto de dados pertence.
                   Valores fracionarios sao arredondados para o inteiro mais proximo.
        NPoints  - Tamanho do conjunto de treinamento, NPoints >=1 // 1000
        NVars    - Numero de variaveis ​​independentes , NVars   >=1 // 3
        NClasses - numero de classes                 , NClasses>=2 // 2
    
    PARAMETROS DE SAIDA:
        Info - codigo de retorno:
               * -2, se houver um ponto com o numero da classe fora de [0..NClasses-1].
               * -1, se parametros incorretos foram passados (NPoints<NVars+2, NVars<1, NClasses<2).
               *  1, se a tarefa foi resolvida.
        LM   - modelo construido
        Rep  - relatório de treinamento
    */
    CLogit::MNLTrainH(LRPM, LRPM.Size(), 3, 2, Linfo, Lmodel, Lrep);
    
    double profit[], out[], prof[1];
    ArrayResize     (profit,1); 
    ArraySetAsSeries(profit, true); 
    profit[0] = 0.0;
    
    int pos = 0, openpr = 0;
    
    for(int s=this.number_of_samples-1;s>=0;s--) {
      double in[3];
      in[0] = indarr [s];
      in[1] = indarr2[s];
      in[2] =         s ;
      CLogit::MNLProcess(Lmodel, in, out);
      
      if(out[0] >  0.5 + probab && !pos) {pos =  1; openpr = s;};
      if(out[0] <  0.5 - probab && !pos) {pos = -1; openpr = s;};
      
      if(out[0] >  0.5 + probab && pos ==  1) continue;
      if(out[0] <  0.5 - probab && pos == -1) continue;
      
      if(out[0] > 0.5 + probab && pos == -1) {
         prof[0] = profit[0] + (iClose(NULL, 0, openpr) - iClose(NULL, 0, s)); 
         ArrayInsert(profit, prof, 0, 0, 1); pos = 0; 
      } // copiando prof para profit
         
      if(out[0] < 0.5 - probab && pos == 1) {
         prof[0] = profit[0] + (iClose(NULL, 0, s) - iClose(NULL, 0, openpr)); 
         ArrayInsert(profit, prof, 0, 0, 1); pos = 0; 
      }
    }
    GraphPlot(profit);
}
//+------------------------------------------------------------------+
//|Get trade signal                                                  |
//+------------------------------------------------------------------+
double CAuto_optimizer::getTradeSignal() {
   
   if(this.relearnCounter==0) this.virtual_optimizer(); // executando o treinamento
   
   relearnCounter++;
   if(this.relearnCounter>=this.relearn_timout) this.relearnCounter=0;
   
   double in[], in1[];
   CopyBuffer(hnd, 0, 0, 1, in); CopyBuffer(hnd1, 0, 0, 1, in1);
   double inn[3];
   inn[0] = in[0]; 
   inn[1] = in1[0]; 
   inn[2] = relearnCounter + this.number_of_samples - 1;         
   
   CLogit::MNLProcess(Lmodel, inn, Lout);
   return Lout[0];
}