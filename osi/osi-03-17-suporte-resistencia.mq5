﻿//+------------------------------------------------------------------+
//|                                 osi-03-16-assimetria-mercado.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Trade\SymbolInfo.mqh>
#include <Files\FileTxt.mqh>
#include <oslib\osc-util.mqh>
#include <oslib\os-lib.mq5>
#include <oslib\osc\est\osc-estatistic3.mqh>
#include <oslib\osc-tick-util.mqh>
//#include <oslib\osc\osc_db.mqh>

input bool   DEBUG                   = false ; // se true, grava informacoes de debug no log.
input bool   GERAR_VOLUME            = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input int    QTD_BAR_PROC_HIST       = 5     ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input int    QTD_SEGUNDOS_CALC_MEDIA = 21    ; // qtd de segundos usados no processamento estatistico.
//input double DISTANCIA_PRECO         = 0.0   ; // 
//input double AVERSAO_RISCO           = 0.1   ; // coef aversao risco (CARA)
//input double FATOR_DF                = 1     ; // fator de diminuicao de frequencia

//#define      MULTIPLICADOR             0.99    // MULTIPLICADOR.
#define      BOOK_OUT                  0.7     // Porcentagem das extremidades dos precos do book que serão desprezados.


#define LOG(txt)        if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha ",__LINE__,":",(txt));}

#define OSI_FEIRA_SHORT_NAME "osi-03-16-assimetria-mercado"
#define DEBUG_TICK     false

#property description "Calcula assimetria do mercado segundo Avellaneda e Stoikov(2008)."

//#property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5

//---- plotar linha com o suporte 
#property indicator_label1  "resistencia"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMagenta  //clrDarkViolet //clrFireBrick
#property indicator_style1  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width1  2

//---- plotar linha com a resistencia
#property indicator_label2  "suporte"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//---- plotar linha com o suporte previst 
#property indicator_label3  "resistencia_fut"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta  //clrDarkViolet //clrFireBrick
#property indicator_style3  STYLE_DASH //STYLE_DASH    //STYLE_SOLID
#property indicator_width3  2

//---- plotar linha com a resistencia
#property indicator_label4  "suporte_fut"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDodgerBlue
#property indicator_style4  STYLE_DASH
#property indicator_width4  2

//---- plotar linha com o preco medio
#property indicator_label5  "preco_medio"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrYellow
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2



//--- buffers do indicador
double m_bufResistencia   []; // suporte                                     :1
double m_bufSuporte       []; // resistencia                                 :2
double m_bufResistenciaFut[]; // suporte previsto para o proximo periodo     :3
double m_bufSuporteFut    []; // resistencia prevista para o proximo periodo :4
double m_bufPrecoMed      []; // preco medio ponderado pelo volume           :5

// variaveis para controle dos ticks
osc_estatistic3 m_minion   ; // estatisticas de ticks e book de ofertas
osc_tick_util   m_tick_util; // para simular ticks de trade em bolsas que nao informam last/volume.
CSymbolInfo     m_symb     ;
bool            m_prochist ; // para nao reprocessar o historico sempre que mudar de barra;

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
//osc_db     m_mydb;
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
   SetIndexBuffer( 0,m_bufResistencia   , INDICATOR_DATA  ); 
   SetIndexBuffer( 1,m_bufSuporte       , INDICATOR_DATA  );
   SetIndexBuffer( 2,m_bufResistenciaFut, INDICATOR_DATA  ); 
   SetIndexBuffer( 3,m_bufSuporteFut    , INDICATOR_DATA  );
   SetIndexBuffer( 4,m_bufPrecoMed      , INDICATOR_DATA  );

//--- Definir um valor vazio
   PlotIndexSetDouble( 0 ,PLOT_EMPTY_VALUE,0); // m_bufResistencia    
   PlotIndexSetDouble( 1 ,PLOT_EMPTY_VALUE,0); // m_bufSuporte    
   PlotIndexSetDouble( 2 ,PLOT_EMPTY_VALUE,0); // m_bufResistenciaFut    
   PlotIndexSetDouble( 3 ,PLOT_EMPTY_VALUE,0); // m_bufSuporteFut    
   PlotIndexSetDouble( 4 ,PLOT_EMPTY_VALUE,0); // m_bufPrecoMed

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,OSI_FEIRA_SHORT_NAME);

//--- ticks
 //m_minion.setModoHibrido(GERAR_VOLUME)       ; //se opcao eh true, gera volume baseado nos ticks. Usado em papeis que nao informam volume.
   m_minion.initialize(QTD_SEGUNDOS_CALC_MEDIA); // quantidade de segundos que serao usados no calculo das medias.
 //m_minion.setConsertarTicksSemFlag(true);
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
   //MarketBookAdd( m_symb.Name() );
   
   return(INIT_SUCCEEDED);
}

MqlBookInfo m_book[];
void OnBookEventx(const string &symbol){
   MarketBookGet(symbol, m_book);
   m_minion.addBook(TimeCurrent(), m_book, m_symb.TicksBookDepth(), BOOK_OUT, m_symb.TickSize() );
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
    m_bufResistencia   [0] = 0;//m_minion.getTradeResistenciaM   ();
    m_bufSuporte       [0] = 0;//m_minion.getTradeSuporteM       ();
    m_bufResistenciaFut[0] = m_minion.getTradeResistenciaFut();
    m_bufSuporteFut    [0] = m_minion.getTradeSuporteFut    ();
    m_bufPrecoMed      [0] = m_minion.getPrecoMedTrade      ();

     //===============================================================================================
     //calcTempoBarraAtual(time); // segundos na barra atual...
     //===============================================================================================
     // Imprimindo dados de depuracao...
     //===============================================================================================
     imprimirComment();

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
       //normalizar2trade(ticks[ind]);
         m_minion.addTick(ticks[ind]);
         
         m_bufResistencia   [i] = 0;//m_minion.getTradeResistenciaM   ();
         m_bufSuporte       [i] = 0;//m_minion.getTradeSuporteM       ();
         m_bufResistenciaFut[i] = m_minion.getTradeResistenciaFut();
         m_bufSuporteFut    [i] = m_minion.getTradeSuporteFut    ();
         m_bufPrecoMed      [i] = m_minion.getPrecoMedTrade      ();

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

string m_deslocamento = ""+
                  //    "                                                                   "+
                  //    "                                                                   "+
//                //    "                                                                   "+
                        "";
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
//   "\n" +m_deslocamento+"=== VOL/VOL MEDIO/ACEL VOL ====\n" +
//         m_deslocamento+"TOT: " + DoubleToString(m_minion.getVolTrade      ()    ,_Digits)+ "/"+
//                                  DoubleToString(m_bufVol[0]                     ,_Digits)+ "/"+
//                                  DoubleToString(m_minion.getVolMedTrade   ()    ,1      )+ "/"+
//         m_deslocamento+"BUY: " + DoubleToString(m_minion.getVolTradeBuy   ()    ,_Digits)+ "/"+
//                                  DoubleToString(m_minion.getVolMedTradeBuy()    ,1      )+ "/"+
//         m_deslocamento+"SEL: " + DoubleToString(m_minion.getVolTradeSel   ()    ,_Digits)+ "/"+
//                                  DoubleToString(m_minion.getVolMedTradeSel()    ,1      )+ "/n"+
//

//   "\n" +m_deslocamento+"=== INCLINACAO PRECO MED/BUY/SELL ====\n" +
//         m_deslocamento+"MED: " + DoubleToString(m_minion.getInclinacaoTrade   (), 9)+ "/"+
//                                  DoubleToString(m_minion.getInclinacaoTradeBuy(), 9)+ "/"+
//                                  DoubleToString(m_minion.getInclinacaoTradeSel(), 9)+ "\n" +
//         m_deslocamento+"MED: " + DoubleToString(log1p( oneIfZero(m_minion.getInclinacaoTrade   ()) ), 5)+ "/"+
//                                  DoubleToString(log1p( oneIfZero(m_minion.getInclinacaoTradeBuy()) ), 5)+ "/"+
//                                  DoubleToString(log1p( oneIfZero(m_minion.getInclinacaoTradeSel()) ), 5)+ "\n" 

     "\n" +m_deslocamento+"=== SUPORTE E RESISTENCIA ====\n" +
           m_deslocamento+"RES :"+DoubleToString(m_bufResistencia   [0], _Digits)+ "\n" +
           m_deslocamento+"SUP :"+DoubleToString(m_bufSuporte       [0], _Digits)+ "\n" +
           m_deslocamento+"RESF:"+DoubleToString(m_bufResistenciaFut[0], _Digits)+ "\n" +
           m_deslocamento+"SUPF:"+DoubleToString(m_bufSuporteFut    [0], _Digits)+ "\n" +
           m_deslocamento+"PMED:"+DoubleToString(m_bufPrecoMed      [0], _Digits)+ "\n" +

   "\n"+ m_deslocamento+"=== BARRAS ACUMULADAS ========================\n"                                           +
         m_deslocamento+"TOT/BUY/SEL====:"+ DoubleToString(double(m_minion.getTempoAcumTrade     ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumTradeBuy  ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumTradeSel  ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"TOT/ASK/BID====:"+ DoubleToString(double(m_minion.getTempoAcumBook      ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumBookAsk   ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumBookBid   ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
       //m_deslocamento+"ACE TOT/BUY/SEL:"+ DoubleToString(double(m_minion.getTempoAcumAceVol    ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
       //                                   DoubleToString(double(m_minion.getTempoAcumAceVolBuy ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
       //                                   DoubleToString(double(m_minion.getTempoAcumAceVolSel ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
  //     m_deslocamento+"TEND/REV=======:"+ DoubleToString(double(m_minion.getTempoAcumTendencia ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
  //                                        DoubleToString(double(m_minion.getTempoAcumRversao   ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"TATU/BAR: "      + DoubleToString (m_sec_barra                    ,0 ) + "/"  +
                                            DoubleToString (m_qtd_sec_periodo              ,0 ) + "\n" +

   "\n"+ m_deslocamento+"======= TAMANHO DOS VETORES DE MEDIAS ========\n"+
         m_deslocamento+"TRADE TOT/BUY/SEL:" + IntegerToString(m_minion.getLenVetAcumTrade    ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumTradeBuy ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumTradeSel ()) + "\n" +
         m_deslocamento+"BOOK TOT/ASK/BID=:" + IntegerToString(m_minion.getLenVetAcumBook     ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumBookAsk  ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumBookBid  ()) + "\n"  
     //  m_deslocamento+"ACEVO TOT/BUY/SEL:" + IntegerToString(m_minion.getLenVetAcumAceVol   ()) + "/"  +
     //                                        IntegerToString(m_minion.getLenVetAcumAceVolBuy()) + "/"  +
     //                                        IntegerToString(m_minion.getLenVetAcumAceVolSel()) + "\n" 
                                                                                                         ;

   Comment(       m_deslocamento+"TICK ===========================\n"+
                  m_tick_txt+
         //   "\n" + m_deslocamento+"TERMINAL ===============================\n"+
         //          terminal_txt+
           "\n" + m_deslocamento+"FIM ================================"  );
  //===============================================================================================
}

void setAsSeries(bool modo){
    ArraySetAsSeries(m_bufResistencia   , modo );
    ArraySetAsSeries(m_bufSuporte       , modo );
    ArraySetAsSeries(m_bufResistenciaFut, modo );
    ArraySetAsSeries(m_bufSuporteFut    , modo );
    ArraySetAsSeries(m_bufPrecoMed      , modo );
}
//void zerarBufDemanda(uint i){
//   m_bufPbuy     [i] = 0;
//   m_bufPsel     [i] = 0;
//   m_bufPtra     [i] = 0;
//}
void zerarBufForca(uint i){
   m_bufResistencia   [i] = 0;
   m_bufSuporte       [i] = 0;
   m_bufResistenciaFut[i] = 0;
   m_bufSuporteFut    [i] = 0;
   m_bufPrecoMed      [i] = 0;
}

void zerarBufAll(uint i){
 //zerarBufDemanda(i);
   zerarBufForca  (i);
}

//////--------------------------------------------------------------------------------------
////// calcula a quantidade de segundos da barra atual e bem como a % de tempo decorrido...
//////--------------------------------------------------------------------------------------
////uint   m_sec_barra_pro_fim        ;
////double m_porcTempoDesdeInicioBarra;
////double m_porcTempoToFimBarra      ;
//////--------------------------------------------------------------------------------------
////void calcTempoBarraAtual(const datetime&  time[]){
////    // segundos na barra atual...
////     bool tipo = ArrayIsSeries(time);
////     ArraySetAsSeries(time,true);
////     m_sec_barraAtu =   TimeCurrent();
////     m_sec_barraAnt =   time[0];
////     m_sec_barra            =   (int)(m_sec_barraAtu    - m_sec_barraAnt);
////     m_sec_barra_pro_fim    =   (int)(m_qtd_sec_periodo - m_sec_barra   );
////     ArraySetAsSeries(time,tipo);
////     m_porcTempoDesdeInicioBarra = (m_sec_barra        /m_qtd_sec_periodo)*100.0;
////     m_porcTempoToFimBarra       = (m_sec_barra_pro_fim/m_qtd_sec_periodo)*100.0;
////}
//////--------------------------------------------------------------------------------------


void openLogFileTick(string arqLog){m_log_tick=FileOpen(arqLog, FILE_WRITE             );                      }
void flushLogTick()                 { if( DEBUG || DEBUG_TICK ){ FileFlush(m_log_tick                                   ); } }
void writeDetLogTick(string comment){ if( DEBUG || DEBUG_TICK ){ FileWrite(m_log_tick, m_tick_util.toStringCSV(comment) ); } } // escrevendo o log de ticks...

//+------------------------------------------------------------------+
