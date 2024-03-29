﻿//+------------------------------------------------------------------+
//|                                              teste-regressao.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Math\Alglib\dataanalysis.mqh>
#include <Math\Stat\Math.mqh>
#include <Graphics\Graphic.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

void OnStart(){

   datetime to;
   while(true){
       to = TimeCurrent();
       prepAndAnalizeRegres(  to-300, to );
       Sleep(50);
   }

 //prepAndAnalizeRegres(  D'2020.05.15 10:00:00', D'2020.05.15 10:00:21' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:00:21', D'2020.05.15 10:00:42' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:00:42', D'2020.05.15 10:01:03' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:00:00', D'2020.05.15 10:01:03' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:31:00', D'2020.05.15 10:32:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:32:00', D'2020.05.15 10:33:00' );


 //prepAndAnalizeRegres(  D'2020.05.15 10:00:00', D'2020.05.15 10:11:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:01:00', D'2020.05.15 10:02:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:02:00', D'2020.05.15 10:03:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:03:00', D'2020.05.15 10:04:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:04:00', D'2020.05.15 10:05:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:05:00', D'2020.05.15 10:06:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:06:00', D'2020.05.15 10:07:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:07:00', D'2020.05.15 10:08:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:08:00', D'2020.05.15 10:09:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:09:00', D'2020.05.15 10:10:00' );
 //prepAndAnalizeRegres(  D'2020.05.15 10:10:00', D'2020.05.15 10:11:00' );

 //prepAndAnalizeRegres(  D'2020.05.15 10:00:00', D'2020.05.15 10:20:00' );
     
}
//+------------------------------------------------------------------+

void prepAndAnalizeRegres(datetime dtFrom, datetime dtTo){
   MqlTick ticks[];
   int qtdTicks = 0;
   
   MqlDateTime dtFrom_, dtTo_;
   TimeToStruct(dtFrom,dtFrom_);
   TimeToStruct(dtTo  ,dtTo_  );
   
   string desdeAte = dtFrom_.hour+":"+dtFrom_.min+":"+dtFrom_.sec+" a "+ 
                     dtTo_  .hour+":"+dtTo_  .min+":"+dtTo_  .sec      ;
   
   
     qtdTicks = CopyTicksRange(Symbol(),ticks,COPY_TICKS_INFO ,dtFrom*1000, dtTo*1000 ); analisarRegressao(ticks,qtdTicks,5.0, "INF:"+desdeAte);
   //qtdTicks = CopyTicksRange(Symbol(),ticks,COPY_TICKS_TRADE,dtFrom*1000, dtTo*1000 ); analisarRegressao(ticks,qtdTicks,5.0, "TRA:"+desdeAte);
   //qtdTicks = CopyTicksRange(Symbol(),ticks,COPY_TICKS_ALL  ,dtFrom*1000, dtTo*1000 ); analisarRegressao(ticks,qtdTicks,5.0, "ALL:"+desdeAte);
}

void analisarRegressao(MqlTick &ticks[], int qtdTicks, double tickSize, string comment){

   //MqlTick ticks[];
   //int qtdMinutos = 5;
   
   //datetime dtFrom=D'2020.05.15 10:00:00';
   //datetime dtTo  =D'2020.05.15 10:00:01';
   
   
   
   //int    qtdTicks = CopyTicksRange(Symbol(),ticks,COPY_TICKS_INFO,dtFrom*1000, dtTo*1000 );
   double rAtu = 0 ; // run atual
   double rAnt = 0 ; // run anterior
   double ret  = 0 ; // retorno
   double rets[]   ; // vetor de retornos
   double retacum[]; // vetor de retornos acumulados
   double is[]     ; // vetor de I's
   ArrayResize(rets   ,qtdTicks);
   ArrayResize(retacum,qtdTicks);
   ArrayResize(is     ,qtdTicks);
   rets   [0] = 0.0;
   retacum[0] = 0.0;
   int runs   = 0;


   // obtendo o vetor de runs...
   for(int i = 1; i < qtdTicks; i++){

      rAnt    = rAtu;
      
    //ret  = (ticks[i].last/ticks[i-1].last)-1.0;
      rAtu = (ticks[i].ask-ticks[i-1].ask) + rAnt    ;
      
      //if( (rAtu*rAnt)<0 ){ rAtu=0;}
          
      if( ( rAtu >=  tickSize*2.0 || 
            rAtu <= -tickSize*2.0  )  ){
        //ret     = (ticks[i].ask/(ticks[i].ask -(rAtu) ) ) -1.0; // retorno normal...
        //ret     = MathLog( ticks[i].ask/(ticks[i].ask-rAtu) ); // log retorno
          ret     =                                     rAtu   ; // retorno em pontos
          
          rets   [runs] = ret;
          retacum[runs] = (runs>0)?(retacum[runs-1]+ret):(ret);

          rAtu    = 0.0;
          runs++;
      }else{
          ret = 0.0;
      }
   }
   

   //-- Preenche a matriz: Y - precos, X - numero ordinal do tick
   CMatrixDouble xy(qtdTicks, 2);
   for(int i = 1; i < runs; i++){

      rAnt    = rAtu;
      
    //ret  = (ticks[i].last/ticks[i-1].last)-1.0;
      rAtu = (ticks[i].ask-ticks[i-1].ask) + rAnt    ;
      
      //if( (rAtu*rAnt)<0 ){ rAtu=0;}
          
      if( ( rAtu >=  tickSize*2.0 || 
            rAtu <= -tickSize*2.0  )  ){
        //ret     = (ticks[i].ask/(ticks[i].ask -(rAtu) ) ) -1.0; // retorno normal...
        //ret     = MathLog( ticks[i].ask/(ticks[i].ask-rAtu) ); // log retorno
          ret     =                                     rAtu   ; // retorno em pontos
          rAtu    = 0.0;
          runs++;
      }else{
          ret = 0.0;
      }

      is[i] = i;
    //xy[i].Set(0, i         );
      xy[i].Set(0, rets[i-1] );
      xy[i].Set(1, ret       );
      rets   [i] = ret;
      retacum[i] = retacum[i-1]+ret;
      /*
      Print( " last:"    , ticks[i].last              ,
             " ask:"     , ticks[i].ask               , 
             " bid:"     , ticks[i].bid               ,
             " spd:"     , ticks[i].ask - ticks[i].bid,
             " time:"    , ticks[i].time              ,
             " time_msc:", ticks[i].time_msc          ,
             " rAnt:"    , rAnt        , 
             " rAtu:"    , rAtu        , 
             " i:"       , i           ,
             " ret:"     , ret         );
      */
   }
   
   

   //-- Encontre os coeficientes a e b do modelo linear y = a*x + b;
   int retcode = 0;
   double a, b;
   //CLinReg::LRLine(xy, qtdTicks, retcode, a, b);

   double vara  =0;
   double varb  =0;
   double covab =0;
   double corrab=0;
   double p     =0;

//--- create array
   double s[];
   ArrayResize(s,qtdTicks);
   for(int i=0;i<=qtdTicks-1;i++){ s[i]=1; }

   CLinReg::LRLines(xy, s, qtdTicks, retcode, a, b, vara, varb, covab, corrab, p);
   
   //-- Gerar os valores de regressão linear para cada X;
   double estimate      [];
   double estimateAr    [];
   double estimateArAcum[];
 //ArrayResize(rets    , qtdTicks);
   ArrayResize(estimate      , qtdTicks);
   ArrayResize(estimateAr    , qtdTicks);
   ArrayResize(estimateArAcum, qtdTicks);
   for(int x = 1; x < qtdTicks; x++) {
       estimate      [x] = x*a+b;
       estimateAr    [x] = rets          [x-1]*a+b;
       estimateArAcum[x] = estimateArAcum[x-1]+estimateAr[x];
     //rets    [x] = ticks[x].ask;
   }
   
   //-- Encontra o coeficiente de correlacao dos valores com sua regressão linear
     double corr = 0.0;
   //corr = CAlglib::PearsonCorr2(ticks, estimate);
   //corr = CAlglib::SpearmanCorr2(equity, estimate);
     MathCorrelationPearson(rets, estimate, corr);

   //-- Encontra R²
   double r2 = MathPow(corr, 2.0);

   //-- Printando os resultados
   Print(                    comment                  ,
          " a="            , DoubleToString(a     ,5), 
          " b="            , DoubleToString(b     ,5), 
          " corrab:"       , DoubleToString(corrab,5),
        //" corrR="        , DoubleToString(corr  ,5),
        //" corrR2="       , DoubleToString(r2    ,5),
          " tks="          , qtdTicks                 ,
          " runs:"         , runs                     ,
          " retcod:"       , retcode                  ,
          " vara:"         , DoubleToString(vara  ,5),
          " varb:"         , DoubleToString(varb  ,5),
          " covab:"        , DoubleToString(covab ,5),
          " p:"            , DoubleToString(p     ,5));
   
 //GraphPlot( is, estimate, is, rets, CURVE_POINTS,"nome_teste");
 //GraphPlot( is, estimate, is, rets, CURVE_POINTS,"nome_teste");
 //GraphPlot(     estimate, CURVE_POINTS,"nome_teste");
 //GraphPlot(     rets    , CURVE_LINES,"nome_teste");
 //GraphPlot(     retacum , CURVE_LINES,"nome_teste");
 //GraphPlot( is, retacum , CURVE_LINES,"nome_teste");
 //GraphPlot( is, retacum , is, estimate      , CURVE_LINES,"nome_teste");
 //GraphPlot( is, retacum , is, estimateAr    , CURVE_LINES,"nome_teste");
   GraphPlot( is, retacum , is, estimateArAcum, CURVE_LINES,"nome_teste");
 //GraphPlot(                   estimateArAcum, CURVE_LINES,"nome_teste");
 //GraphPlot( is, estimateAr, is, estimateArAcum, CURVE_LINES,"nome_teste");
}
