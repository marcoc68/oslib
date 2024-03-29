﻿//+------------------------------------------------------------------+
//|                                              teste-dist-tick.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Math\Alglib\dataanalysis.mqh>
#include <Math\Stat\Math.mqh>
#include <Graphics\Graphic.mqh>
#include <Trade\SymbolInfo.mqh>

#include <oslib\osc\est\CStat.mqh>


enum ENUM_TDN_TIPO_EXEC{
     TEX_NOW_MINUS_MINUTE   , // NOW_MINUS_MINUTE execucao continua. tempo atual menos qtd minutos configurados.
     TEX_FROM_TO            , // FROM_TO          execucao unica, no intervalo informado.
     TEX_FROM_TO_INTERV_CUM , // FROM_TO_INTERV_CUM  execucao unica, no intervalo informado com incremento de minutos configurados (acumulativa).
     TEX_FROM_TO_INTERV_DESL, // FROM_TO_INTERV_DESL execucao unica, no intervalo informado com incremento de minutos configurados (deslizante).
};

enum ENUM_TDN_TIPO_DADO{
     TDA_PRICE     , // TDA_PRICE      distribuicao do preco.
     TDA_PRICE_RET , // TDA_PRICE_RET  distribuicao do retorno.
     TDA_PRICE_RETX, // TDA_PRICE_RETX distribuicao do retorno X.
     TDA_VOLUME    , // TDA_VOLUME     distribuicao do volume.
};

enum ENUM_TDN_TIPO_PESO{
     TPE_VOLUME   , // TPE_VOLUME ponderado pelo volume.
     TPE_1        , // TPE_1      nao ponderado.
};



#property script_show_inputs
input string             IN_SYMBOL           = "VAZIO";
input int                IN_WINDOW_MINUTO    = 5 ; 
input double             IN_SLIP_MINUTO      = 1  ; // SLIP quanto exec unica e janela deslizante
input int                IN_REFRESH_IN_MILIS = 10 ;
input ENUM_TDN_TIPO_EXEC IN_TIPO_EXEC        = TEX_FROM_TO_INTERV_DESL;
input ENUM_TDN_TIPO_DADO IN_TIPO_DADO        = TDA_PRICE_RET;
input ENUM_TDN_TIPO_PESO IN_TIPO_PESO        = TPE_VOLUME;
input datetime           IN_1X_DT_INI        = D'2020.10.30 09:00:00';
input datetime           IN_1X_DT_FIM        = D'2020.10.30 17:54:00';
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

void OnStart(){

    // resolvendo o ticker...
    string symbol_str;
    if( IN_SYMBOL =="VAZIO"){ symbol_str = _Symbol; }else{symbol_str=IN_SYMBOL;}
    CSymbolInfo cSymb;
    cSymb.Name(symbol_str);
    //double tickSize = cSymb.TickSize();
    //int    digits   = cSymb.Digits();

    // resolvendo o tamanho do tick e a quantidade de digitos...
    double tickSize;
    int    digits  ;
    if( IN_TIPO_DADO==TDA_PRICE || IN_TIPO_DADO==TDA_PRICE_RET ){
        tickSize = cSymb.TickSize();
        digits   = cSymb.Digits();
        Print(__FUNCTION__, " ticksize=",tickSize, " digitos=", digits);
    }else{
        tickSize = 1;
        digits   = 0;
    }
    
    // processando...
    switch(IN_TIPO_EXEC){
        // processando em loop com os ultimos IN_WINDOW_MINUTO...
        case TEX_NOW_MINUS_MINUTE:
            {
                while(true){
                    processar(IN_WINDOW_MINUTO,symbol_str,tickSize,digits,IN_TIPO_DADO,IN_TIPO_PESO );
                    Sleep(IN_REFRESH_IN_MILIS);
                }
            }
            break;

        // processando uma unica vez com os ticks do intervalo de datas informado...
        case TEX_FROM_TO:
            processar(symbol_str, IN_1X_DT_INI, IN_1X_DT_FIM,tickSize,digits,IN_TIPO_DADO,IN_TIPO_PESO); break;
        
        // processa uma vez o intervalo de dadas com janela acumulativa. Acumula a cada IN_WINDOW_MINUTO e refresh a cada IN_REFRESH_IN_MILIS;
        case TEX_FROM_TO_INTERV_CUM:
            processarIntervaloAcumulativo(symbol_str, IN_1X_DT_INI, IN_1X_DT_FIM, tickSize,digits, IN_SLIP_MINUTO, IN_REFRESH_IN_MILIS,IN_TIPO_DADO,IN_TIPO_PESO); break;
            
        // processa uma vez o intervalo de datas com janela deslizante. Janela a cada IN_WINDOW_MINUTO e refresh a cada IN_REFRESH_IN_MILIS;
        case TEX_FROM_TO_INTERV_DESL:
            processarIntervaloDeslizante(symbol_str, IN_1X_DT_INI, IN_1X_DT_FIM, tickSize,digits, IN_WINDOW_MINUTO, IN_SLIP_MINUTO, IN_REFRESH_IN_MILIS,IN_TIPO_DADO,IN_TIPO_PESO); break;
    }
}

bool processarIntervaloDeslizante(string symb, datetime from, datetime to, double tickSize, int digits, int minutosAcum, double slip, int refresInMillis,ENUM_TDN_TIPO_DADO tpDado, ENUM_TDN_TIPO_PESO tpPeso){
   
    datetime dtIni = from;
    datetime dtFim = from + minutosAcum*60;
    while( dtFim <= to ){
        processar(symb, dtIni, dtFim, tickSize, digits, tpDado, tpPeso );
        dtIni = dtIni + (int)(slip*60);
        dtFim = dtIni + minutosAcum*60;
        Sleep(refresInMillis);
    }
    processar(symb, dtIni, dtFim, tickSize, digits, tpDado, tpPeso, true );
    return true;
}

bool processarIntervaloAcumulativo(string symb, datetime from, datetime to, double tickSize, int digits, int minutosAcum, int refresInMillis,ENUM_TDN_TIPO_DADO tpDado, ENUM_TDN_TIPO_PESO tpPeso){
   
    datetime dtFimAcum = from + minutosAcum*60;
    while( dtFimAcum <= to ){
        processar(symb, from, dtFimAcum, tickSize, digits, tpDado, tpPeso );
        dtFimAcum = dtFimAcum + minutosAcum*60;
        Sleep(refresInMillis);
    }
    processar(symb, from, dtFimAcum, tickSize, digits, tpDado, tpPeso, true );
    return true;
}

bool processar(int qtdMinutos, string symb, double tickSize, int digits,ENUM_TDN_TIPO_DADO tpDado, ENUM_TDN_TIPO_PESO tpPeso){
     datetime to   = TimeCurrent();       
     datetime from = to-qtdMinutos*60;
     return processar(symb, from, to, tickSize, digits, tpDado, tpPeso);
}

bool processar(string symb, datetime from, datetime to, double tickSize, int digits, ENUM_TDN_TIPO_DADO tpDado, ENUM_TDN_TIPO_PESO tpPeso, bool print=false){

    CStat    stat;
   
// Print(":-| ",__FUNCTION__,": Copiando ticks...");
    MqlTick  ticks[];
    int qtdTicks = CopyTicksRange(symb, ticks, COPY_TICKS_TRADE, from*1000, to*1000);
    if( qtdTicks < 2){
        Print(":-| ",__FUNCTION__,": ", qtdTicks," Copiados. LastError:",GetLastError());
        return false;
    }
   
// Print(":-| ",__FUNCTION__,": Inicializando os arrays de precos e volumes last...");
    double last [];
    double vol  [], volSel[], volBuy[];
    ArrayResize(last  ,qtdTicks);
    ArrayResize(vol   ,qtdTicks);
    ArrayResize(volSel,qtdTicks);
    ArrayResize(volBuy,qtdTicks);
    if( tpDado==TDA_PRICE_RETX ){
        last[0] = 0;
        vol [0] = 0;
        for(int i=1; i<qtdTicks; i++){
            //selecionando somente qd o retorno eh maior que 1 tick...
            if( ( (last[i-1]<0) && (ticks[i].last - ticks[i-1].last)<0 ) ||
                ( (last[i-1]>0) && (ticks[i].last - ticks[i-1].last)>0 ) ||
                            MathAbs(ticks[i].last - ticks[i-1].last)>5     ){
                last[i] = (ticks[i].last - ticks[i-1].last);
                vol [i] =  ticks[i].volume                 ;
            }else{
                last[i] = 0;
                vol [i] = ticks[i].volume;
            }
        }
    }else{
        for(int i=1; i<qtdTicks; i++){
           // selecionando somente quando muda o preco...
            last[i]= (tpDado==TDA_PRICE     ) ?              ticks[i].last                   :
                     (tpDado==TDA_PRICE_RET ) ?             (ticks[i].last - ticks[i-1].last):
                                                MathAbs( log(ticks[i].volume) )              ;
            vol [i]= (tpPeso==TPE_VOLUME)     ?              ticks[i].volume : 1             ;
               
               //if( ((ticks[i].flags&TICK_FLAG_BUY )==TICK_FLAG_BUY   ) ) volBuy[i]=(int)ticks[i].volume;
               //if( ((ticks[i].flags&TICK_FLAG_SELL)==TICK_FLAG_SELL  ) ) volSel[i]=(int)ticks[i].volume;
        }
    }
    last[0] = last[1];
    vol [0] = vol [1];
   
//   Print(":-| ",__FUNCTION__,": Chamando a funcao que calcula a distribuicao...");
    double freq[], price[];
    stat.calcDist2(last,vol,freq,price);
   
    if(print){
        printDistrib(freq,price);
        return true;
    }
   
//   Print(":-| ",__FUNCTION__,": Plotando grafico da distribuicao...");
   //GraphPlot    (price,dist,CURVE_HISTOGRAM);

    double mean    =0;      // [out] Variável para a média      (1º momento)
    double variance=0;      // [out] Variável para a variância  (2º momento)
    double skewness=0;      // [out] Variável para a assimetria (3º momento)
    double kurtosis=0;      // [out] Variável para a curtose    (4º momento)
    double dpadrao =0;      // desvio padrao
    double cv      =0;      // coeficiente de variacao
   
   //if( MathMoments( last    ,  // [in]  Array com dados
   //                 mean    ,  // [out] Variável para a média(1º momento)
   //                 variance,  // [out] Variável para a variância (2º momento)
   //                 skewness,  // [out] Variável para a assimetria (3º momento)
   //                 kurtosis) ) {
   //                 dpadrao = MathSqrt(variance);

    if( stat.describe(last, vol, mean, variance, skewness, kurtosis, dpadrao, cv ) ){


      // Print(":-| ",__FUNCTION__,": mean:"                 ,mean    ,
      //                           " \nvariance:"            ,variance,
      //                           " \nskewness(assimetria):",skewness,
      //                           " \nkurtosis:"            ,kurtosis,
      //                           " \ndpadrao:"             ,dpadrao 
      //                           );
    }else{
        Print(":-( ",__FUNCTION__,": ERRO calculando momentos!!");
    }

    CGraphic graphic;
   
    string name  = "distrib";
    int    chart = 0;
    if(ObjectFind(chart,name)<0) graphic.Create(chart,name,0,0,0,700,267); 
    else                         graphic.Attach(chart,name); 

   // X: precos, Y:frequencias   
    CCurve *curve=graphic.CurveAdd(price,freq,CURVE_HISTOGRAM);
    curve.Name("vol");
   
   // bolinha com a media... 
    double meanx[]; // desvio padrao
    double meany[]; // frequencia absoluta do desvio padrao
    ArrayResize(meanx,1);
    ArrayResize(meany,1);
    meanx[0] = normalizePrice(mean,tickSize,digits);
    meany[0] = freq[ ArraySearchSerial(price,meanx[0]) ];
    CCurve *curveMedia=graphic.CurveAdd(meanx,meany,CURVE_HISTOGRAM);
            curveMedia.Name("med:"+DoubleToString(mean,digits));
            curveMedia.HistogramWidth(2);
            curveMedia.PointsFill(true);
            curveMedia.Color(clrGold);
                   
   // bolinha com o desvio padrao acima e abaixo da media... 
   double dpx[]; // desvio padrao
   double dpy[]; // frequencia absoluta do desvio padrao
   ArrayResize(dpx,4);
   ArrayResize(dpy,4);

   dpx[0] = normalizePrice(mean-dpadrao*1.5,tickSize,digits);
   dpx[1] = normalizePrice(mean-dpadrao*1.0,tickSize,digits);
   dpx[2] = normalizePrice(mean+dpadrao*1.0,tickSize,digits);
   dpx[3] = normalizePrice(mean+dpadrao*1.5,tickSize,digits);
   
   dpy[0] = freq[ ArraySearchSerial(price,dpx[0]) ];
   dpy[1] = freq[ ArraySearchSerial(price,dpx[1]) ];
   dpy[2] = freq[ ArraySearchSerial(price,dpx[2]) ];
   dpy[3] = freq[ ArraySearchSerial(price,dpx[3]) ];

   //dpx[0] = m_cSymb.NormalizePrice(mean+dpadrao);
   //dpx[1] = m_cSymb.NormalizePrice(mean-dpadrao);
   //dpy[0] = dist[ ArraySearchSerial(price,dpx[0]) ];
   //dpy[1] = dist[ ArraySearchSerial(price,dpx[1]) ];
   CCurve *curveDpadraoP=graphic.CurveAdd(dpx,dpy,CURVE_HISTOGRAM);
           curveDpadraoP.Name("dpad:"+DoubleToString(dpadrao,digits));
           curveDpadraoP.HistogramWidth(2);
           curveDpadraoP.PointsFill(true);
         //curveDpadraoP.PointsColor(clrBlack);
           curveDpadraoP.Color(clrBlack);

   // bolinha com o preco atual...
   double patux[]; // preco atual
   double qatuy[]; // frequencia absoluta do preco atual
   ArrayResize(patux,1);
   ArrayResize(qatuy,1);
   patux[0] = normalizePrice( last[qtdTicks-1], tickSize,digits);
   qatuy[0] = freq[ ArraySearchSerial(price,patux[0]) ];
   CCurve *curveUltPreco=graphic.CurveAdd(patux,qatuy,CURVE_HISTOGRAM);
           curveUltPreco.Name("prc:"+DoubleToString(patux[0],digits));
           curveUltPreco.HistogramWidth(2);
           curveUltPreco.PointsFill(true);
           curveUltPreco.Color(ColorToARGB(clrRed,255));

   //graphic.YAxis().AutoScale(false);
   //double cv = dpadrao/mean; // coeficiente de variacao...            
   graphic.BackgroundMain( "["+symb + " " + to + 
                                    "] ["      + IntegerToString(IN_WINDOW_MINUTO) + "min"   +
                                    "] [skew " + DoubleToString(skewness,3) +
                                    "] [kurt " + DoubleToString(kurtosis,3) +
                                    "] [cv "   + DoubleToString(cv      ,5) +
                                    "]");
   graphic.BackgroundMainSize(15);
   graphic.XAxis().Name("preco");      
   graphic.XAxis().NameSize(12);          
   graphic.YAxis().Name("volume");      
   graphic.YAxis().NameSize(12);
   graphic.YAxis().Min(0);
   //graphic.YAxis().ValuesWidth(15);
   graphic.CurvePlotAll();
   graphic.Update();
   return true;

//   Print(":-| ",__FUNCTION__,": Retirando os valores com zero do array...");
   double x[];
   int j=0;
   for(int i=0; i<ArraySize(freq); i++){
       
       if(ArraySize(x)<j+1){ArrayResize(x,j+1);}
       
       if(freq[i] != 0){
           x[j++] = freq[i];
       }
   }

   return true;
}

// retorna o indice da primeira ocorrencia de V no array A ou -1 se não encontrar.
int ArraySearchSerial(const double &a[], const double v){

    int size = ArraySize(a);

  //for(int i=0; i<size; i++){ if(a[i]==v) return i; if(a[i]>v) break; }
    for(int i=0; i<size; i++){ if(a[i]==v) return i;                   }
    
    ArrayPrint(a);
    Print(__FUNCTION__, "ind nao encontrado valor ",v, " em vetor de tamanho ", size);
    return 0;

}

void printDistrib(double& y[], double& x[]){
    int size = ArraySize(x);
    Print(__FUNCTION__," Imprimindo distribuicao...");
    for(int i=0; i<size; i++){
        if(y[i]!=0.0) Print("(",x[i],",",y[i],")");
    }
}
//+------------------------------------------------------------------+

   
 //GraphPlot( is, estimate, is, rets, CURVE_POINTS,"nome_teste");
 //GraphPlot( is, estimate, is, rets, CURVE_POINTS,"nome_teste");
 //GraphPlot(     estimate, CURVE_POINTS,"nome_teste");
 //GraphPlot(     rets    , CURVE_LINES,"nome_teste");
 //GraphPlot(     retacum , CURVE_LINES,"nome_teste");
 //GraphPlot( is, retacum , CURVE_LINES,"nome_teste");
 //GraphPlot( is, retacum , is, estimate      , CURVE_LINES,"nome_teste");
 //GraphPlot( is, retacum , is, estimateAr    , CURVE_LINES,"nome_teste");
 //GraphPlot(                   estimateArAcum, CURVE_LINES,"nome_teste");
 //GraphPlot( is, estimateAr, is, estimateArAcum, CURVE_LINES,"nome_teste");

double normalizePrice(const double price, const double tickSize, const int digits )
  {
   if(tickSize!=0)
      return(NormalizeDouble(MathRound(price/tickSize)*tickSize,digits));
//---
   return(NormalizeDouble(price,digits));
  }
