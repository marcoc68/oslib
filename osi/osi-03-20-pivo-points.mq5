﻿//+------------------------------------------------------------------+
//|                                        osi-03-20-pivo-points.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//|                                                                  |
//|  Desenha os pontos de pivo da grafico de precos.                 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
//#property version   "01.01"

#include <Trade\SymbolInfo.mqh>
#include <oslib\osc-util.mqh>
#include <oslib\os-lib.mq5>
#include <oslib\osc\osc-pivo-points.mqh>

input      ENUM_TIMEFRAMES PERIODO_PIVO = PERIOD_D1; // Periodo para calculo do pivo.
input bool PIVO_POR_PERIODO             = true     ; // calcular pivo por periodo.
input int  QTD_PERIODOS                 = 5        ; // Qtd Periodos quando calculado por periodo.
//input bool   DEBUG                   = false ; // se true, grava informacoes de debug no log.
//input bool   GERAR_VOLUME            = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
//input bool   PROCESSAR_BOOK          = false ; // PROCESSAR_BOOK
//input int    QTD_BAR_PROC_HIST       = 5     ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
//input int    QTD_SEGUNDOS_CALC_MEDIA = 300   ; // qtd de segundos usados no processamento estatistico.
//input double BOOK_OUT                = 0     ; // BOOK_OUT % das extermidades do book a ser desprezada

#define OSI_INDICATOR_NAME   "osi-03-20-pivo-points"

#property description "Calcula pontos de pivo baseado no processamento do dia anterior."

#property indicator_chart_window
#property indicator_buffers 8            
#property indicator_plots   8           

//---- plotar linha com o terceiro nivel de resistencia
#property indicator_label1  "res3"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrTomato
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//---- plotar linha com o segundo nivel de resistencia
#property indicator_label2  "res2"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrCrimson
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//---- plotar linha com o primeiro nivel de resistencia
#property indicator_label3  "res1"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBrown  
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

//---- plotar linha com o pivo
#property indicator_label4  "pivo"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrGold 
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

//---- plotar linha com o primeiro nivel de suporte
#property indicator_label5  "sup1"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

//---- plotar linha com o segundo nivel de suporte
#property indicator_label6  "sup2"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrMediumBlue 
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

//---- plotar linha com o terceiro nivel de suporte
#property indicator_label7  "sup3"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrRoyalBlue
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

//---- plotar linha com o fechamento do dia anterior
#property indicator_label8  "close_ant"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrMagenta
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1


//--- buffers do indicador
double m_bufRes3            []; // terceiro nivel de resistencia  
double m_bufRes2            []; // segundo  nivel de resistencia  
double m_bufRes1            []; // primeiro nivel de resistencia  
double m_bufPivo            []; // pivo         
double m_bufSup1            []; // primeiro nivel de suporte
double m_bufSup2            []; // segundo  nivel de suporte
double m_bufSup3            []; // terceiro nivel de suporte
double m_bufCloA            []; // fechamento do dia anterior

CSymbolInfo     m_symb;
osc_pivo_points m_pivo;

//+------------------------------------------------------------------+
//| Função de inicialização do indicador customizado                 |
//+------------------------------------------------------------------+
int OnInit() {
   m_symb.Name        ( Symbol() );
   m_symb.Refresh     ();
   m_symb.RefreshRates();
   
   Print("Definindo buffers do indicador...");
   SetIndexBuffer( 0,m_bufRes3       , INDICATOR_DATA  );
   SetIndexBuffer( 1,m_bufRes2       , INDICATOR_DATA  );
   SetIndexBuffer( 2,m_bufRes1       , INDICATOR_DATA  );
   SetIndexBuffer( 3,m_bufPivo       , INDICATOR_DATA  );
   SetIndexBuffer( 4,m_bufSup1       , INDICATOR_DATA  );
   SetIndexBuffer( 5,m_bufSup2       , INDICATOR_DATA  );
   SetIndexBuffer( 6,m_bufSup3       , INDICATOR_DATA  );
   SetIndexBuffer( 7,m_bufCloA       , INDICATOR_DATA  );

   Print("Definindo valores para nao plotar...");
   PlotIndexSetDouble( 0 ,PLOT_EMPTY_VALUE,0); // m_bufRes3
   PlotIndexSetDouble( 1 ,PLOT_EMPTY_VALUE,0); // m_bufRes2
   PlotIndexSetDouble( 2 ,PLOT_EMPTY_VALUE,0); // m_bufRes1   
   PlotIndexSetDouble( 3, PLOT_EMPTY_VALUE,0); // m_bufPivo 
   PlotIndexSetDouble( 4, PLOT_EMPTY_VALUE,0); // m_bufSup1 
   PlotIndexSetDouble( 5, PLOT_EMPTY_VALUE,0); // m_bufSup2 
   PlotIndexSetDouble( 6, PLOT_EMPTY_VALUE,0); // m_bufSup3 
   PlotIndexSetDouble( 7, PLOT_EMPTY_VALUE,0); // m_bufCloA 

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,OSI_INDICATOR_NAME);
   
   setAsSeries(true);
   //Print("Chamando execucao de calcPivoPoints()..." );
   //calcPivoPoints();

   // fim...
   return(INIT_SUCCEEDED);
}

// obter preco da sessao anterior e atualizar o calculo do pivo ...
MqlRates m_ratesDia[2];
bool m_calculei_pivo_points_ok = false;
void calcPivoPoints(){

    if( m_calculei_pivo_points_ok ) return;

    ResetLastError();
    int copiados = CopyRates(m_symb.Name(),PERIODO_PIVO,1,1,m_ratesDia);
    
    if( copiados < 1 || GetLastError() != 0 ){
        Print("RATES COPIADOS:", copiados, " LastError:", GetLastError() );
    }
    
    
    m_pivo.calc(m_ratesDia[0].high, m_ratesDia[0].low, m_ratesDia[0].close);
    
    if( copiados > 0 ) m_calculei_pivo_points_ok = true;
}

void calcPivoPoints(datetime dt){

    //if( m_calculei_pivo_points_ok ) return;

    ResetLastError();
    int copiados = CopyRates(m_symb.Name(),PERIODO_PIVO,dt,2,m_ratesDia);

    if( copiados < 1 || GetLastError() != 0 ){
        Print("RATES COPIADOS:", copiados, " LastError:", GetLastError(), " dt:", dt );
        //Print("Aguardando 10seg...");
        //Sleep(10000);
    }
    
    m_pivo.calc(m_ratesDia[0].high, m_ratesDia[0].low, m_ratesDia[0].close);
    
}

void calcPivoPoints(int shift){

    ResetLastError();
    double close = iClose(m_symb.Name(),PERIODO_PIVO,shift);
    double high  = iHigh (m_symb.Name(),PERIODO_PIVO,shift);
    double low   = iLow  (m_symb.Name(),PERIODO_PIVO,shift);
    
    m_pivo.calc(high, low, close);
}

void calcPivoPoints(const double&    high [],
                    const double&    low  [],
                    const double&    close[], const int i){

    m_pivo.calc(high[i], low[i], close[i] );
    
}

void OnDeinit(const int i){
  delete(&m_symb  );
}

//+------------------------------------------------------------------+
//| Atualizando os volumes de bid e oferta                           |
//+------------------------------------------------------------------+
MqlTick m_tick;
bool    m_prochist = false;
int OnCalculate( const int rates_total,       // tamanho do array price[] 
                 const int prev_calculated,   // barras tratadas na chamada anterior 
                 const datetime&  time[],
                 const double&    open[],
                 const double&    high[],
                 const double&    low[],
                 const double&    close[],
                 const long&      tick_volume[],
                 const long&      volume[]     ,
                 const int&       spread[]     ) {

    
    if( rates_total==prev_calculated) return (rates_total);
    comentar_na_tela(time[prev_calculated]);

    Print("rates_total:",rates_total," prev_calculated:",prev_calculated);
    
    if(!m_prochist || prev_calculated==0){ // para nao reprocessar a ultima barra sempre que mudar de barra.
        
        setAsSeries(false);
        ArraySetAsSeries(high ,false);
        ArraySetAsSeries(low  ,false);
        ArraySetAsSeries(close,false);
        
        if(PIVO_POR_PERIODO){
            doOnCalculateHistorico(rates_total, prev_calculated, high, low, close );
        }else{
            doOnCalculateHistorico(rates_total, prev_calculated, time             );
        }
        
        setAsSeries(true);
        ArraySetAsSeries(high ,true);
        ArraySetAsSeries(low  ,true);
        ArraySetAsSeries(close,true);
        return (rates_total);
    }
    
    if( rates_total != prev_calculated ){
        setAsSeries(true);
        ArraySetAsSeries(high ,true);
        ArraySetAsSeries(low  ,true);
        ArraySetAsSeries(close,true);
    }else{
        return(rates_total);
    }

    if(PIVO_POR_PERIODO){
        calcPivoPoints( high,low,close, QTD_PERIODOS );
    }else{
        calcPivoPoints(time[prev_calculated]);
    }
    
    plotar(0);
    return(rates_total);
}

//===============================================================================================
// Processando o historico de ticks no oncalculate...
//===============================================================================================
void doOnCalculateHistorico(const int        p_rates_total    ,
                            const int        p_prev_calculated, 
                            const datetime&  time[]           ){
    setAsSeries(false);

    // ZERANDO PRA APAGAR O HISTORICO... 
    for( int i=p_prev_calculated; i<p_rates_total; i++ ){ plotar_zero(i); }

    // plotando nas barras historicas
    for( int i=p_prev_calculated; i<p_rates_total; i++ ){
        
        calcPivoPoints(time[i]);
        plotar(i);
    }
    setAsSeries(true);
    
    m_prochist = true; Print( "Historico processado :-)" );

}
//===============================================================================================
// Processando o historico de ticks no oncalculate...
//===============================================================================================
void doOnCalculateHistorico(const int     p_rates_total    ,
                            const int     p_prev_calculated, 
                            const double& high[]           ,
                            const double& low[]            ,
                            const double& close[]          ){
    setAsSeries(false);

    // ZERANDO PRA APAGAR O HISTORICO... 
    for( int i=p_prev_calculated; i<p_rates_total; i++ ){ plotar_zero(i); }

    // plotando nas barras historicas
    for( int i=QTD_PERIODOS; i<p_rates_total; i++ ){
        
        calcPivoPoints(high,low,close,i-QTD_PERIODOS);
        plotar(i);
    }
    setAsSeries(true);
    
    m_prochist = true; Print( "Historico processado :-)" );

}

void plotar(int i){
    // plotando no grafico
    m_bufRes3[i] = m_pivo.getRes3();
    m_bufRes2[i] = m_pivo.getRes2();
    m_bufRes1[i] = m_pivo.getRes1();
    m_bufPivo[i] = m_pivo.getPivo();
    m_bufSup1[i] = m_pivo.getSup1();
    m_bufSup2[i] = m_pivo.getSup2();
    m_bufSup3[i] = m_pivo.getSup3();
    m_bufCloA[i] = m_pivo.getCloA();
}

void plotar_zero(int i){
    // plotando no grafico
    m_bufRes3[i] = 0;
    m_bufRes2[i] = 0;
    m_bufRes1[i] = 0;
    m_bufPivo[i] = 0;
    m_bufSup1[i] = 0;
    m_bufSup2[i] = 0;
    m_bufSup3[i] = 0;
    m_bufCloA[i] = 0;
}

void comentar_na_tela(datetime dt){
    Comment("dt              :",dt              ,"\n",
            "m_pivo.getRes3():",m_pivo.getRes3(),"\n",
            "m_pivo.getRes2():",m_pivo.getRes2(),"\n",
            "m_pivo.getRes1():",m_pivo.getRes1(),"\n",
            "m_pivo.getPivo():",m_pivo.getPivo(),"\n",
            "m_pivo.getSup1():",m_pivo.getSup1(),"\n",
            "m_pivo.getSup2():",m_pivo.getSup2(),"\n",
            "m_pivo.getSup3():",m_pivo.getSup3(),"\n",
            "m_pivo.getCloA():",m_pivo.getCloA()     );
}

void setAsSeries(bool modo){
     ArraySetAsSeries(m_bufRes3, modo );
     ArraySetAsSeries(m_bufRes2, modo );
     ArraySetAsSeries(m_bufRes1, modo );
     ArraySetAsSeries(m_bufPivo, modo );
     ArraySetAsSeries(m_bufSup1, modo );
     ArraySetAsSeries(m_bufSup2, modo );
     ArraySetAsSeries(m_bufSup3, modo );
     ArraySetAsSeries(m_bufCloA, modo );
}

