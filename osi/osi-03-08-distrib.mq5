﻿//+------------------------------------------------------------------+
//|                                            osi-03-08-distrib.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "3.008"

#include <Trade\SymbolInfo.mqh>
#include <Files\FileTxt.mqh>
#include <oslib\osc-util.mqh>
#include <oslib\os-lib.mq5>
#include <oslib\osc-estatistic2.mqh>
#include <oslib\osc-tick-util.mqh>
#include <oslib\osc\osc_db.mqh>

input bool   DEBUG                   = false ; // se true, grava informacoes de debug no log.
input bool   GERAR_VOLUME            = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input int    QTD_BAR_PROC_HIST       = 5     ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input int    QTD_SEGUNDOS_CALC_MEDIA = 300   ; // qtd de segundos usados no processamento estatistico.


#define LOG(txt)        if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha ",__LINE__,":",(txt));}
//#define LOG_ONCALC      LOG("RatesTot:"+IntegerToString(  rates_total)+" PrevCalc:"+IntegerToString(  prev_calculated) );
//#define LOG_ONCALC_HIST LOG("RatesTot:"+IntegerToString(p_rates_total)+" PrevCalc:"+IntegerToString(p_prev_calculated) );

#define OSI_FEIRA_SHORT_NAME "osi-03-08-distrib"
#define DEBUG_TICK     false

//#define LOG_DEBUG_ONCALC                if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha:",__LINE__,": ratesTot:",rates_total," prevCalc:",prev_calculated);}

#property description "Calcula vwap dos ultimos XX minutos baseado nos ticks processados"
#property description "Informa posicoes de variabilidade do volume em torno da vwap."

#property indicator_chart_window
#property indicator_buffers 6 // era 31
#property indicator_plots   3 // era 31

//---- plotar linha com o preco medio de vendas
#property indicator_label1  "pm_sell"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrFireBrick
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

//---- plotar linha com preco medio de compras
#property indicator_label2  "pm_buy"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrMediumBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3

//---- plotar linha com o preco medio de ofertas de venda (ask)
#property indicator_label3  "pm_ask"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  3

//---- plotar linha com o preco medio de ofertas de compra (bid)
#property indicator_label4  "pm_bid"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDeepSkyBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  3

////---- plotar seta forca ask
//#property indicator_label5  "sig_ask"
//#property indicator_type5   DRAW_ARROW
//#property indicator_color5  clrMagenta
//#property indicator_style5  STYLE_SOLID
//#property indicator_width5  1
//
////---- plotar seta forca bid
//#property indicator_label6  "sig_bid"
//#property indicator_type6   DRAW_ARROW
//#property indicator_color6  clrDeepSkyBlue
//#property indicator_style6  STYLE_SOLID
//#property indicator_width6  1
//
////---- plotar seta forca buy
//#property indicator_label7  "high"
//#property indicator_type7   DRAW_ARROW
//#property indicator_color7  clrMediumBlue
//#property indicator_style7  STYLE_SOLID
//#property indicator_width7  1
//
////---- plotar seta forca sel
//#property indicator_label8  "low"
//#property indicator_type8   DRAW_ARROW
//#property indicator_color8  clrFireBrick
//#property indicator_style8  STYLE_SOLID
//#property indicator_width8  1
//
////---- plotar seta forca up1
//#property indicator_label9  "up1"
//#property indicator_type9   DRAW_ARROW
//#property indicator_color9  clrDeepSkyBlue
//#property indicator_style9  STYLE_SOLID
//#property indicator_width9  3
//
////---- plotar seta forca up2
//#property indicator_label10  "up2"
//#property indicator_type10   DRAW_ARROW
//#property indicator_color10  clrDeepSkyBlue
//#property indicator_style10  STYLE_SOLID
//#property indicator_width10  3
//
////---- plotar seta forca down1
//#property indicator_label11  "down1"
//#property indicator_type11   DRAW_ARROW
//#property indicator_color11  clrFireBrick
//#property indicator_style11  STYLE_SOLID
//#property indicator_width11  3
//
////---- plotar seta forca down2
//#property indicator_label12  "down2"
//#property indicator_type12   DRAW_ARROW
//#property indicator_color12  clrFireBrick
//#property indicator_style12  STYLE_SOLID
//#property indicator_width12  3

//---- plotar linha preco medio do trade
#property indicator_label5  "pm_trade"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrDarkViolet  // clrDarkOrchid
#property indicator_style5  STYLE_DASH
#property indicator_width5  3

//---- plotar linha preco medio do book de ofertas
#property indicator_label16  "pm_book"
#property indicator_type16   DRAW_LINE
#property indicator_color16  clrGold //clrDarkOrange //clrOrangeRed
#property indicator_style16  STYLE_DASH
#property indicator_width16  3

////---- plotar seta inclinacao do trade para cima
//#property indicator_label15  "sinal_incl_alta"
//#property indicator_type15   DRAW_ARROW
//#property indicator_color15  clrMediumBlue
//#property indicator_style15  STYLE_SOLID
//#property indicator_width15  1
//
////---- plotar seta inclinacao do trade para baixo
//#property indicator_label16  "sinal_incl_baixa"
//#property indicator_type16   DRAW_ARROW
//#property indicator_color16  clrFireBrick
//#property indicator_style16  STYLE_SOLID
//#property indicator_width16  1
//
////---- plotar sinal de comprometimento para aumentar o preco
//#property indicator_label17  "sinal_comp_alta"
//#property indicator_type17   DRAW_ARROW
//#property indicator_color17  clrMediumBlue
//#property indicator_style17  STYLE_SOLID
//#property indicator_width17  1
//
////---- plotar sinal de comprometimento para baixar o preco
//#property indicator_label18  "sinal_comp_baixa"
//#property indicator_type18   DRAW_ARROW
//#property indicator_color18  clrFireBrick
//#property indicator_style18  STYLE_SOLID
//#property indicator_width18  1
//
////---- armazenar dados da tendencia
//#property indicator_label19  "tend"
//#property indicator_type19   DRAW_NONE
////#property indicator_color19  clrFireBrick
////#property indicator_style19  STYLE_SOLID
////#property indicator_width19  1
//
////---- armazenar dados da reversao
//#property indicator_label20  "reve"
//#property indicator_type20   DRAW_NONE
////#property indicator_color19  clrFireBrick
////#property indicator_style19  STYLE_SOLID
////#property indicator_width19  1
//
////---- armazenar inclinacao da linha de venda media
//#property indicator_label21  "incl_sel"
//#property indicator_type21   DRAW_NONE
////#property indicator_color21  clrFireBrick
////#property indicator_style21  STYLE_SOLID
////#property indicator_width21  1
//
////---- armazenar inclinacao da linha de compra media
//#property indicator_label22  "incl_buy"
//#property indicator_type22   DRAW_NONE
////#property indicator_color22  clrFireBrick
////#property indicator_style22  STYLE_SOLID
////#property indicator_width22  1
//
////---- armazenar inclinacao da linha de media de trades
//#property indicator_label23  "incl_trade"
//#property indicator_type23   DRAW_NONE
//
////---- armazenar inclinacao da linha oferts de venda
//#property indicator_label24  "incl_ask"
//#property indicator_type24   DRAW_NONE
//
////---- armazenar inclinacao da linha de ofertas de compra
//#property indicator_label25  "incl_bid"
//#property indicator_type25   DRAW_NONE
//
////---- armazenar inclinacao da linha de ofertas gerais
//#property indicator_label26  "incl_bok"
//#property indicator_type26   DRAW_NONE

//---- armazenar volume
#property indicator_label27  "vol"
#property indicator_type27   DRAW_NONE

#property indicator_label28  "vol_sel"
#property indicator_type28   DRAW_NONE

#property indicator_label28  "vol_buy"
#property indicator_type28   DRAW_NONE

//--- buffers do indicador
double m_bufPsel            []; // preco medio de compras                         :1
double m_bufPbuy            []; // preco medio de vendas                          :2
double m_bufPtra            []; // preco medio de trades (buy/sel)                :13
double m_bufVol             []; // volume                                         :27
double m_bufVolBuy          []; // volume de compras                              :28
double m_bufVolSel          []; // volume de vendas                               :29

// variaveis para controle dos ticks
osc_estatistic2 m_minion   ; // estatisticas de ticks e book de ofertas
osc_tick_util   m_tick_util; // para simular ticks de trade em bolsas que nao informam last/volume.
CSymbolInfo     m_symb     ;
bool            m_prochist ; // para nao reprocessar o historico sempre que mudar de barra;

double m_vbuy    = 0;
double m_vsel    = 0;
double m_tickvol = 0;

// apresentacao de depuracao
string m_tick_txt    ;

// variaveis para controle do arquivo de log
int  m_log_tick      ; // descarreganto ticks         em arquivo de log (debug)

// variaveis para controle das forças liquidas
//double m_demandBuy = 0; // demanda media buy (demanda de compra)...
//double m_demandSel = 0; // demanda media sel (demanda de venda )...

//=================================================================================================

uint       m_qtd_sec_periodo;// qtd de segundos que tem o periodo grafico atual.
uint       m_sec_barra   ; // segundos na barra atual
datetime   m_sec_barraAnt; // segundos na barra atual
datetime   m_sec_barraAtu; // segundos na barra atual
osc_db     m_mydb;
//+------------------------------------------------------------------+
//| Função de inicialização do indicador customizado                 |
//+------------------------------------------------------------------+
int OnInit() {
   //PRINT_DEBUG_INIT_INI
   LOG("=======================================");
   m_symb.Name        ( Symbol() );
   m_symb.Refresh     ();
   m_symb.RefreshRates();

   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[DEBUG                  =", DEBUG                  , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[GERAR_VOLUME           =", GERAR_VOLUME           , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[QTD_BAR_PROC_HIST      =", QTD_BAR_PROC_HIST      , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[QTD_SEGUNDOS_CALC_MEDIA=", QTD_SEGUNDOS_CALC_MEDIA, "]");
   
   m_qtd_sec_periodo = PeriodSeconds();
   setAsSeries(true);

   Print("Definindo buffers do indicador...");
   SetIndexBuffer( 0,m_bufPsel       , INDICATOR_DATA  );
   SetIndexBuffer( 1,m_bufPbuy       , INDICATOR_DATA  );
   SetIndexBuffer( 2,m_bufPtra       , INDICATOR_DATA  ); // era 12
   SetIndexBuffer( 3,m_bufVol        , INDICATOR_DATA  ); // era 26
   SetIndexBuffer( 4,m_bufVolBuy     , INDICATOR_DATA  ); // era 27
   SetIndexBuffer( 5,m_bufVolSel     , INDICATOR_DATA  ); // era 28

//--- Definir um valor vazio
   PlotIndexSetDouble( 0 ,PLOT_EMPTY_VALUE,0); // m_bufPsel
   PlotIndexSetDouble( 1 ,PLOT_EMPTY_VALUE,0); // m_bufPbuy
   PlotIndexSetDouble( 2 ,PLOT_EMPTY_VALUE,0); // m_bufPtra    // era 12
//   PlotIndexSetDouble(26,PLOT_EMPTY_VALUE,0); // m_bufVol     nao eh plotado
//   PlotIndexSetDouble(27,PLOT_EMPTY_VALUE,0); // m_bufVolBuy  nao eh plotado
//   PlotIndexSetDouble(28,PLOT_EMPTY_VALUE,0); // m_bufVolSel  nao eh plotado

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,OSI_FEIRA_SHORT_NAME);

//--- ticks
 //m_minion.setModoHibrido(GERAR_VOLUME)    ; //se opcao eh true, gera volume baseado nos ticks. Usado em papeis que nao informam volume.
   m_minion.initialize(QTD_SEGUNDOS_CALC_MEDIA); // quantidade de segundos que serao usados no calculo das medias.
   m_minion.setSymbolStr( m_symb.Name() );
   
   m_prochist = false; // indica se deve reprocessar o historico.
   m_tick_util.setTickSize(m_symb.TickSize(), m_symb.Digits() );

//--- debug
   if( DEBUG ){
      string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
      StringReplace ( dt, ".", ""  );
      StringReplace ( dt, ":", ""  );
      StringReplace ( dt, " ", "_" );
      openLogFileTick(OSI_FEIRA_SHORT_NAME + "_" + m_symb.Name() + IntegerToString(_Period) + "_" + dt + "_tick.csv" );
      //if( !m_mydb.create_or_open_mydb() ) return (INIT_FAILED);
   }

   if( DEBUG_TICK ){
      string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
      StringReplace ( dt, ".", ""  );
      StringReplace ( dt, ":", ""  );
      StringReplace ( dt, " ", "_" );
      openLogFileTick(OSI_FEIRA_SHORT_NAME + "_" + m_symb.Name() + IntegerToString(_Period) + "_" + dt + "_tick.csv" );
   }

//---
   return(INIT_SUCCEEDED);
}


// transforma o tick informativo em tick de trade. Usamos em mercados que nao informam volume ou last nos ticks.
void normalizar2trade(MqlTick& tick){
   if(GERAR_VOLUME){
      writeDetLogTick( "ANT" );
      m_tick_util.normalizar2trade(tick);
      writeDetLogTick( "POS" );
   }
}

void OnDeinit(const int i){
  LOG("Executando OnDeinit...");
  MarketBookRelease( m_symb.Name() );
  delete(&m_symb  );
  //delete(&m_minion);
  //delete(&m_book);
  FileClose( m_log_tick );
  //m_mydb.close();
  LOG("OnDeinit Finalizado!");
}

//+------------------------------------------------------------------+
//| Atualizando os volumes de bid e oferta                           |
//+------------------------------------------------------------------+
MqlTick m_tick   ;
int OnCalculate(const int        rates_total,
                const int        prev_calculated,
                const datetime&  time[],
                const double&    open[],
                const double&    high[],
                const double&    low[],
                const double&    close[],
                const long&      tick_volume[],
                const long&      volume[]     ,
                const int&       spread[]     ) {

    //===============================================================================================
    // Processando o hitorico...
    //===============================================================================================
  //LOG_ONCALC;
    if(!m_prochist){ // para nao reprocessar a ultima barra sempre que mudar de barra.
        setAsSeries(false);
        doOnCalculateHistorico(rates_total, prev_calculated,time);
        setAsSeries(true);
    }
  //LOG_ONCALC;

    //===============================================================================================
    // Processamento o tick da barra atual...
    //===============================================================================================
    //processando o evento atual...
    SymbolInfoTick  (_Symbol,m_tick);// um tick por chamada a oncalculate
    normalizar2trade(        m_tick);// soh normaliza se a opcao GERAR_VOLUME estiver ativa
    m_minion.addTick(        m_tick);// adicionando o tick as estatisticas
    
    // plotando no grafico
    m_bufPbuy     [0] = m_minion.getPrecoMedTradeBuy();
    m_bufPsel     [0] = m_minion.getPrecoMedTradeSel();
    m_bufPtra     [0] = m_minion.getPrecoMedTrade();
    m_bufVol      [0] = m_minion.getVolTrade();
    m_bufVolBuy   [0] = m_minion.getVolTradeBuy();
    m_bufVolSel   [0] = m_minion.getVolTradeSel();

   //===============================================================================================

     //===============================================================================================
     // plotando as ofertas do book na barra atual, e tambem salvando as inclinacoes...
     //===============================================================================================
     //if( rates_total >= prev_calculated ){
     //    m_demandBuy = m_bufPbuy[0]; // demanda media buy (demanda de compra)...
     //    m_demandSel = m_bufPsel[0]; // demanda media sel (demanda de venda )...
     // }

     //===============================================================================================
     //calcTempoBarraAtual(time); // segundos na barra atual...
     //===============================================================================================
     // Imprimindo dados de depuracao...
     //===============================================================================================
     //imprimirComment();

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
 //LOG_ONCALC_HIST;
   setAsSeries(false);
   zerarBufAll(p_prev_calculated);

   // zerando lixo do historico...
   for( int i=p_prev_calculated; i<p_rates_total; i++ ){zerarBufAll(i);}
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

      ///m_minion.fecharPeriodo(); // fechando o periodo anterior de coleta de estatisticas
      qtdTicks = CopyTicksRange( _Symbol         , //const string     symbol_name,          // nome do símbolo
                                 ticks           , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                 COPY_TICKS_ALL  , //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                 p_time[i-1]*1000, //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                 p_time[i  ]*1000  //ulong            to_msc=0              // data ate a qual são solicitados os ticks
                 );
      for(int ind=0; ind<qtdTicks; ind++){
         normalizar2trade(ticks[ind]);
         m_minion.addTick(ticks[ind]);
         m_bufPbuy     [i] = m_minion.getPrecoMedTradeBuy();
         m_bufPsel     [i] = m_minion.getPrecoMedTradeSel();
         m_bufPtra     [i] = m_minion.getPrecoMedTrade   ();
         m_bufVol      [i] = m_minion.getVolTrade        ();
         m_bufVolBuy   [i] = m_minion.getVolTradeBuy     ();
         m_bufVolSel   [i] = m_minion.getVolTradeSel     ();

       //calcSinalTendenciaReversao(i);

        //===============================================================================================
        // Imprimindo dados de depuracao...
        //===============================================================================================
       //imprimirComment();
      }// final for processamento dos ticks

      // mudou a barra, entao verificamos se eh necessario alterar o tamanho dos vetores de acumulacao de medias...
      //m_minion.checkResize(0.3);

   }// final for do processamento das barras

   m_prochist = true; Print( "Historico processado :-)" );

}//doOnCalculateHistorico.

string m_deslocamento = "                                                                   "+
                        "                                                                   "+
                        "                                                                   "+
//                      "                                                                   "+
                        "                                                                   ";
int m_qtdImpressao = 0;                        
void imprimirComment(){

  // imprimir a cada 2 ticks...
  if( m_qtdImpressao++ > 2 ){ m_qtdImpressao = 0; return; }

  //===============================================================================================
  // Imprimindo dados de depuracao...
  //===============================================================================================
   m_tick_txt =
//         m_deslocamento+"PMEDBUY: " + DoubleToString (m_minion.getPrecoMedTradeBuy()   ,_Digits )+ "\n" +
//         m_deslocamento+"PMEDSEL: " + DoubleToString (m_minion.getPrecoMedTradeSel()   ,_Digits )+ "\n" +
//         m_deslocamento+"PMED===: " + DoubleToString (m_minion.getPrecoMedTrade()      ,_Digits )+ "\n" +
//
     "\n" +m_deslocamento+"=== VOL/VOL MEDIO/ACEL VOL ====\n" +
           m_deslocamento+"TOT: " + DoubleToString(m_minion.getVolTrade      ()    ,_Digits)+ "/"+
                                    DoubleToString(m_bufVol[0]                     ,_Digits)+ "/"+
//                                  DoubleToString(m_minion.getVolMedTrade   ()    ,1      )+ "/"+
//         m_deslocamento+"BUY: " + DoubleToString(m_minion.getVolTradeBuy   ()    ,_Digits)+ "/"+
//                                  DoubleToString(m_minion.getVolMedTradeBuy()    ,1      )+ "/"+
//         m_deslocamento+"SEL: " + DoubleToString(m_minion.getVolTradeSel   ()    ,_Digits)+ "/"+
//                                  DoubleToString(m_minion.getVolMedTradeSel()    ,1      )+ "/n"+
//

   "\n"+ m_deslocamento+"=== BARRAS ACUMULADAS ========================\n"                                           +
         m_deslocamento+"TOT/BUY/SEL====:"+ DoubleToString(double(m_minion.getTempoAcumTrade     ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumTradeBuy  ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumTradeSel  ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"TOT/ASK/BID====:"+ DoubleToString(double(m_minion.getTempoAcumBook      ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumBookAsk   ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumBookBid   ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"ACE TOT/BUY/SEL:"+ DoubleToString(double(m_minion.getTempoAcumAceVol    ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumAceVolBuy ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumAceVolSel ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"TEND/REV=======:"+ DoubleToString(double(m_minion.getTempoAcumTendencia ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumRversao   ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"TATU/BAR: "      + DoubleToString (m_sec_barra                    ,0 ) + "/"  +
                                            DoubleToString (m_qtd_sec_periodo              ,0 ) + "\n" +

   "\n"+ m_deslocamento+"======= TAMANHO DOS VETORES DE MEDIAS ========\n"+
         m_deslocamento+"TRADE TOT/BUY/SEL:" + IntegerToString(m_minion.getLenVetAcumTrade    ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumTradeBuy ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumTradeSel ()) + "\n" +
         m_deslocamento+"BOOK TOT/ASK/BID=:" + IntegerToString(m_minion.getLenVetAcumBook     ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumBookAsk  ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumBookBid  ()) + "\n" +
         m_deslocamento+"ACEVO TOT/BUY/SEL:" + IntegerToString(m_minion.getLenVetAcumAceVol   ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumAceVolBuy()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumAceVolSel()) + "\n" ;

   Comment(       m_deslocamento+"TICK ===========================\n"+
                  m_tick_txt+
         //   "\n" + m_deslocamento+"TERMINAL ===============================\n"+
         //          terminal_txt+
           "\n" + m_deslocamento+"FIM ================================"  );
  //===============================================================================================
}

void setAsSeries(bool modo){
   ArraySetAsSeries(m_bufPsel            , modo );
   ArraySetAsSeries(m_bufPbuy            , modo );
   ArraySetAsSeries(m_bufPtra            , modo );
   ArraySetAsSeries(m_bufVol             , modo );
   ArraySetAsSeries(m_bufVolBuy          , modo );
   ArraySetAsSeries(m_bufVolSel          , modo );
}
void zerarBufDemanda(uint i){
   m_bufPbuy     [i] = 0;
   m_bufPsel     [i] = 0;
   m_bufPtra     [i] = 0;
}
void zerarBufForca(uint i){
   m_bufVol      [i] = 0;
   m_bufVolBuy   [i] = 0;
   m_bufVolSel   [i] = 0;
}

void zerarBufAll(uint i){
   zerarBufDemanda(i);
   zerarBufForca  (i);
}

//--------------------------------------------------------------------------------------
// calcula a quantidade de segundos da barra atual e bem como a % de tempo decorrido...
//--------------------------------------------------------------------------------------
uint   m_sec_barra_pro_fim        ;
double m_porcTempoDesdeInicioBarra;
double m_porcTempoToFimBarra      ;
//--------------------------------------------------------------------------------------
void calcTempoBarraAtual(const datetime&  time[]){
    // segundos na barra atual...
     bool tipo = ArrayIsSeries(time);
     ArraySetAsSeries(time,true);
     m_sec_barraAtu =   TimeCurrent();
     m_sec_barraAnt =   time[0];
     m_sec_barra            =   (int)(m_sec_barraAtu    - m_sec_barraAnt);
     m_sec_barra_pro_fim    =   (int)(m_qtd_sec_periodo - m_sec_barra   );
     ArraySetAsSeries(time,tipo);
     m_porcTempoDesdeInicioBarra = (m_sec_barra        /m_qtd_sec_periodo)*100.0;
     m_porcTempoToFimBarra       = (m_sec_barra_pro_fim/m_qtd_sec_periodo)*100.0;
}
//--------------------------------------------------------------------------------------


void openLogFileTick(string arqLog){m_log_tick=FileOpen(arqLog, FILE_WRITE             );                      }
void flushLogTick()                 { if( DEBUG || DEBUG_TICK ){ FileFlush(m_log_tick                                   ); } }
void writeDetLogTick(string comment){ if( DEBUG || DEBUG_TICK ){ FileWrite(m_log_tick, m_tick_util.toStringCSV(comment) ); } } // escrevendo o log de ticks...

//+------------------------------------------------------------------+
