﻿//+------------------------------------------------------------------+
//|                                     osi-03-22-00-vol-profile.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//|                                                                  |
//|  Desenha os pontos do volume profile nas barras de preco.        |
//|  Serao plotados:                                                 |
//|  - um ponto POC                                                  |
//|  - um ponto VAH                                                  |
//|  - um ponto VAL                                                  |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, OS Corp."
#property link      "http://www.os.org"
//#property version   "01.00"

#include <Trade\SymbolInfo.mqh>
#include <oslib\osc-util.mqh>
#include <oslib\os-lib.mq5>
#include <oslib\osc\data\osc-vol-profile.mqh>

#define OSI_INDICATOR_NAME   "osi-03-22-vprof"

#property description "Calcula volume profile por barra no grafico."

#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5


input int QTD_BAR_PROC_HIST      = 60  ; // Qtd barras historicas a processar.
input int QTD_BAR_ACUM_VPROFILE  = 15  ; // Qtd barras acumuladas usadas no calculo do volume profile.
//input int SLEEP_ENTRE_TICKS    = 250 ; // Milisegundos entre ticks.
#define     SLEEP_ENTRE_TICKS       5  


//---- plotar PMAX
#property indicator_label1  "pmax"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//---- plotar VAH
#property indicator_label2  "vah"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLime
#property indicator_style2  STYLE_DASH
#property indicator_width2  2

//---- plotar POC
#property indicator_label3  "poc"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrYellow
#property indicator_style3  STYLE_DASH
#property indicator_width3  2

//---- plotar VAL
#property indicator_label4  "val"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRed  
#property indicator_style4  STYLE_DASH
#property indicator_width4  2

//---- plotar PMIN
#property indicator_label5  "pmin"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrRed  
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

//--- buffers do indicador
double m_bufPma            []; // PAMX
double m_bufVah            []; // VAH
double m_bufPoc            []; // POC
double m_bufVal            []; // VAL
double m_bufPmi            []; // PMIN

CSymbolInfo     m_symb ;
osc_vol_profile m_vprof;

//+------------------------------------------------------------------+
//| Função de inicialização do indicador customizado                 |
//+------------------------------------------------------------------+
int OnInit() {
   m_symb.Name        ( Symbol() );
   m_symb.Refresh     ();
   m_symb.RefreshRates();
   
   m_vprof.m_param.qtd_seg_acum_vprof = QTD_BAR_ACUM_VPROFILE * PeriodSeconds(); // qtd segundos acumulados no calculo do volume_profile.
   
   Print("Definindo buffers do indicador...");
   SetIndexBuffer( 0,m_bufPma       , INDICATOR_DATA  );
   SetIndexBuffer( 1,m_bufVah       , INDICATOR_DATA  );
   SetIndexBuffer( 2,m_bufPoc       , INDICATOR_DATA  );
   SetIndexBuffer( 3,m_bufVal       , INDICATOR_DATA  );
   SetIndexBuffer( 4,m_bufPmi       , INDICATOR_DATA  );

   Print("Definindo valores para nao plotar...");
   PlotIndexSetDouble( 0 ,PLOT_EMPTY_VALUE,0); // m_bufPma
   PlotIndexSetDouble( 1 ,PLOT_EMPTY_VALUE,0); // m_bufVah
   PlotIndexSetDouble( 2 ,PLOT_EMPTY_VALUE,0); // m_bufPoc
   PlotIndexSetDouble( 3 ,PLOT_EMPTY_VALUE,0); // m_bufVal   
   PlotIndexSetDouble( 4 ,PLOT_EMPTY_VALUE,0); // m_bufPmi   

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,OSI_INDICATOR_NAME);
   
   setAsSeries(true);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int i){
  delete(&m_symb  );
}

//+------------------------------------------------------------------+
//| Atualizando os volumes de bid e oferta                           |
//+------------------------------------------------------------------+
MqlTick m_tick;
bool    m_prochist = false;
int     m_i = 0;

long    m_time_desde_ultimo_calculo = 0;
long    m_time_atual                = 0;
long    m_time_ultimo_calculo       = 0;
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

    
    //if( rates_total==prev_calculated) return (rates_total);
    //comentar_na_tela(time[prev_calculated]);
    //Print("rates_total:",rates_total," prev_calculated:",prev_calculated);
    
    if(!m_prochist || prev_calculated==0){ // para nao reprocessar a ultima barra sempre que mudar de barra.
        setAsSeries(false);
        doOnCalculateHistorico(rates_total, prev_calculated, time             );
        setAsSeries(true);
        return (rates_total);
    }
    
    // aguardando milisegundos antes do proximo tick...
    m_time_atual = GetTickCount()                                     ;
    m_time_desde_ultimo_calculo = m_time_atual - m_time_ultimo_calculo;
    m_time_ultimo_calculo = m_time_atual                              ;
    if(m_time_desde_ultimo_calculo < SLEEP_ENTRE_TICKS) return (rates_total);
            
    //Sleep(SLEEP_ENTRE_TICKS); // aguardando milisegundos antes do proximo tick...
   
    m_i++;
    SymbolInfoTick(_Symbol,m_tick);
    m_vprof.add( m_tick );
    m_vprof.calcular_area_de_valor();
    plotar(0);
    if( m_i%100000 == 0 ) Print( __FUNCTION__," i:",m_i, " VPROF1:", m_vprof.toString() );

    
    //if( rates_total != prev_calculated && m_i < 1000 ){ 
    //    Print( __FUNCTION__," rates_total:",rates_total, " prev_calculated:", prev_calculated );
    //    m_vprof.calcular_area_de_valor();
    //    Print( __FUNCTION__," i:",m_i, " VPROF2:", m_vprof.toString() );
    //    
    //    plotar(0);
    //    m_i++;
    //}

    return(rates_total);
}

//===============================================================================================
// Processando o historico de ticks no oncalculate...
//===============================================================================================
void doOnCalculateHistorico(const int        p_rates_total    ,
                            const int        p_prev_calculated,
                            const datetime&  p_time[]         ){
   MqlTick ticks[];
   int     qtdTicks;
   setAsSeries(false);

   // zerando lixo do historico...
   for( int i=p_prev_calculated; i<p_rates_total; i++ ){plotar_zero(i);}
   Print("Feita a limpeza do historico desde a barra:"                   , p_prev_calculated              , " ateh a barra:", p_rates_total, "...");
   Print("Iniciando processamento dos dados do historico, desde a barra:", p_rates_total-QTD_BAR_PROC_HIST, " ateh a barra:", p_rates_total, "...");

   // processando o historico...
   for( int i=p_prev_calculated; i<p_rates_total; i++ ){ // O -1 eh pra nao processar o periodo atual dentro do laco.

      // durante os testes, seguimos somente com as ultimas n barras
      // se prev_calculated eh zero, acontece erro ao buscar o tempo de fechamento da barra anterior
      if( (p_rates_total-i) > QTD_BAR_PROC_HIST || i==0 ){
         //zerarBufAll(p_prev_calculated); continue;
         continue;
      }

      Print(__FUNCTION__,":" ," Obtendo ticks no historico desde ", p_time[i-1], " ateh ", p_time[i], "..." );

      qtdTicks = 0;
      while(qtdTicks < 1){
          qtdTicks = CopyTicksRange( _Symbol         , //const string     symbol_name,          // nome do símbolo
                                     ticks           , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                     COPY_TICKS_TRADE, //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                     p_time[i-1]*1000, //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                     p_time[i  ]*1000  //ulong            to_msc=0              // data ate a qual são solicitados os ticks
                     );
          if(qtdTicks == 0){
              mySleep(1000);
              Print(__FUNCTION__, ":", qtdTicks, " ticks obtidos :-( Aguardando 1seg e tentando novamente..." );
          }
      }
      Print(__FUNCTION__, ":", qtdTicks, " ticks obtidos no historico desde ", p_time[i-1], " ateh ", p_time[i], "..." );

      for(int ind=0; ind<qtdTicks; ind++){
         m_vprof.add(ticks[ind]);

        //===============================================================================================
        // Imprimindo dados de depuracao...
        //===============================================================================================
       //imprimirComment();
      }// final for processamento dos ticks
      m_vprof.calcular_area_de_valor();
      plotar(i);
      Print( __FUNCTION__, m_vprof.toString() );

   }// final for do processamento das barras

   m_prochist = true; Print( "Historico processado :-)" );

}//doOnCalculateHistorico.


void plotar(int i){
    // plotando no grafico
    m_bufPma[i] = m_vprof.m_vprof.pmax;
    m_bufVah[i] = m_vprof.m_vprof.pvah;
    m_bufPoc[i] = m_vprof.m_vprof.ppoc;
    m_bufVal[i] = m_vprof.m_vprof.pval;
    m_bufPmi[i] = m_vprof.m_vprof.pmin;
}

void plotar_zero(int i){
    // plotando no grafico
    m_bufPma[i] = 0;
    m_bufVah[i] = 0;
    m_bufPoc[i] = 0;
    m_bufVal[i] = 0;
    m_bufPmi[i] = 0;
}

void comentar_na_tela(datetime dt){
    Comment("dt              :",dt                       ,"\n",
            "m_vprof.m_vprof.pmax: ",m_vprof.m_vprof.pmax,"\n",
            "m_vprof.m_vprof.pvah: ",m_vprof.m_vprof.pvah,"\n",
            "m_vprof.m_vprof.ppoc: ",m_vprof.m_vprof.ppoc,"\n",
            "m_vprof.m_vprof.pval: ",m_vprof.m_vprof.pval,"\n",
            "m_vprof.m_vprof.pmin: ",m_vprof.m_vprof.pmin     );
}

void setAsSeries(bool modo){
     ArraySetAsSeries(m_bufPma, modo );
     ArraySetAsSeries(m_bufVah, modo );
     ArraySetAsSeries(m_bufPoc, modo );
     ArraySetAsSeries(m_bufVal, modo );
     ArraySetAsSeries(m_bufPmi, modo );
}

// Sleep nao funciona com indcadores... Cuidado ao usar este sleep em indicadores...
void mySleep(int sleep){
    long ini = GetTickCount();
    long fim = ini + sleep;
    while( GetTickCount() < fim ){}
}
