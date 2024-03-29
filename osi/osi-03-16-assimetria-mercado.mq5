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
input double DISTANCIA_PRECO         = 0.0   ; // 
input double AVERSAO_RISCO           = 0.1   ; // coef aversao risco (CARA)
input double FATOR_DF                = 1     ; // fator de diminuicao de frequencia

#define      MULTIPLICADOR             0.99    // MULTIPLICADOR.
#define      BOOK_OUT                  0.7     // Porcentagem das extremidades dos precos do book que serão desprezados.


#define LOG(txt)        if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha ",__LINE__,":",(txt));}

#define OSI_FEIRA_SHORT_NAME "osi-03-16-assimetria-mercado"
#define DEBUG_TICK     false

#property description "Calcula assimetria do mercado segundo Avellaneda e Stoikov(2008)."

//#property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

//---- plotar linha com o delta ask 
#property indicator_label1  "delta_ask"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMagenta  //clrDarkViolet //clrFireBrick
#property indicator_style1  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width1  2

//---- plotar linha com o delta bid
#property indicator_label2  "delta_bid"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//---- plotar linha com [disponivel para proxima informacao]
#property indicator_label3  "disponivel"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed  //clrFireBrick //clrDarkViolet  // clrDarkOrchid
#property indicator_style3  STYLE_SOLID  //STYLE_DASH
#property indicator_width3  2


//--- buffers do indicador
double m_bufDeltaAsk  []; // alteracao na frequencia de cotacoes ask :1
double m_bufDeltaBid  []; // alteracao na frequencia de cotacoes bid :2
double m_bufIsel      []; // disponivel                              :3

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
   SetIndexBuffer( 0,m_bufDeltaAsk   , INDICATOR_DATA  ); 
   SetIndexBuffer( 1,m_bufDeltaBid   , INDICATOR_DATA  );
   SetIndexBuffer( 2,m_bufIsel       , INDICATOR_DATA  );

//--- Definir um valor vazio
   PlotIndexSetDouble( 0 ,PLOT_EMPTY_VALUE,0); // m_bufDeltaAsk    
   PlotIndexSetDouble( 1 ,PLOT_EMPTY_VALUE,0); // m_bufDeltaBid    
   PlotIndexSetDouble( 2 ,PLOT_EMPTY_VALUE,0); // m_bufIsel    

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,OSI_FEIRA_SHORT_NAME);

//--- ticks
 //m_minion.setModoHibrido(GERAR_VOLUME)    ; //se opcao eh true, gera volume baseado nos ticks. Usado em papeis que nao informam volume.
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
      m_bufDeltaAsk     [0] = calcOptmalAsk(m_tick.ask);
      m_bufDeltaBid     [0] = calcOptmalBid(m_tick.bid);
    //m_bufDeltaAsk     [0] = naoMaiorQue( m_minion.getDeltaFreqAsk(), MULTIPLICADOR );
    //m_bufDeltaBid     [0] = naoMaiorQue( m_minion.getDeltaFreqBid(), MULTIPLICADOR );
    //m_bufIsel         [0] = log1p(oneIfZero(m_minion.getInclinacaoTradeSel() ) );

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
         
         // ficando duas barras sem imprimir pra nao dar problema da escala.
         //if( (p_rates_total-i) > QTD_BAR_PROC_HIST-2 ){continue;}
         
         //m_bufDeltaAsk     [i] = naoMaiorQue( m_minion.getDeltaFreqAsk(),MULTIPLICADOR );
         //m_bufDeltaBid     [i] = naoMaiorQue( m_minion.getDeltaFreqBid(),MULTIPLICADOR );

         m_bufDeltaAsk     [i] = calcOptmalAsk(ticks[ind].ask);
         m_bufDeltaBid     [i] = calcOptmalBid(ticks[ind].bid);

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

double m_fator_df = 1;
double calcOptmalBid(double bid){
    
    double optquote = calcOptmalBid(bid,m_fator_df);
    int passo = 1;
    while( !MathIsValidNumber(optquote) ){ 
        Comment(__FUNCTION__,":-| recalculando diminuicao de frequencia. Passo:", passo, " DF:", m_fator_df );
        m_fator_df = m_fator_df*log(FATOR_DF); 
        optquote = calcOptmalBid(bid,m_fator_df);
        passo++;
    }
    return optquote;
}
double calcOptmalAsk(double ask){
    // primeiro calcula com o fator de diminuicao de frequencia atual...
    double optquote = calcOptmalAsk(ask,m_fator_df);
    
    // se deu certo e jah foi ajustado, ajusta pra tras XX vezes tentando calcular com valores mais proximos de 1(ideal).
    if( MathIsValidNumber(optquote) && m_fator_df < 1 ){
        for( int i=0; i<2 && MathIsValidNumber(optquote) && m_fator_df < 1; i++ ){
            m_fator_df = m_fator_df/log(FATOR_DF); // aproximando o fator do 1...
            if( m_fator_df > 1 ) m_fator_df = 1;
            optquote = calcOptmalBid(ask,m_fator_df);
        }
    }
    
    // se entrar no laco eh porque o ultimo calculo deu errado, entao vai afastar do 1 ateh dar certo.
    //int passo = 1;
    while( !MathIsValidNumber(optquote) ){ 
        //Comment(__FUNCTION__,":-| recalculando diminuicao de frequencia. Passo:", passo, " DF:", m_fator_df );
        m_fator_df = m_fator_df*log(FATOR_DF); // afastando o fator do 1...
        optquote = calcOptmalBid(ask,m_fator_df); 
        //passo++;
    }
    return optquote;
}

double calcOptmalBid(double bid, double fator_df){
    if(    m_minion.getFreqBid     ()==0
      //|| m_minion.getDeltaFreqBid()==0
      //|| m_minion.getFreqBid()     == m_minion.getDeltaFreqBid() 
      ) return (bid-DISTANCIA_PRECO);
    
    return (bid-DISTANCIA_PRECO) - (1/AVERSAO_RISCO)*log( 1- AVERSAO_RISCO*( oneIfZero(m_minion.getFreqBid()*fator_df)/oneIfZero(m_minion.getDeltaFreqBid()) ) );
}

double calcOptmalAsk(double ask, double fator_df){
    if(    m_minion.getFreqAsk     () == 0
      //|| m_minion.getDeltaFreqAsk() == 0 
      //|| m_minion.getFreqAsk     () == m_minion.getDeltaFreqAsk() ]
      ) return (ask+DISTANCIA_PRECO);
        
    return (ask+DISTANCIA_PRECO) - (1/AVERSAO_RISCO)*log( 1- AVERSAO_RISCO*( oneIfZero(m_minion.getFreqAsk()*fator_df)/oneIfZero(m_minion.getDeltaFreqAsk()) ) );
}

double naoMaiorQue(double ori, double maior){
    if( ori < maior ) return ori  ;
                      return maior;
}


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

     "\n" +m_deslocamento+"=== ASSIMETRIA DO MERCADO FASK/FBID/DASK/DBID ====\n" +
           m_deslocamento+"FDF:" +DoubleToString(m_fator_df                   )+ "\n"+
           m_deslocamento+"FRIN:"+DoubleToString(m_minion.getFreqAskIni  (), 1)+ "/"+
                                  DoubleToString(m_minion.getFreqBidIni  (), 1)+ "\n"+
           m_deslocamento+"FRAT:"+DoubleToString(m_minion.getFreqAsk     (), 1)+ "/"+
                                  DoubleToString(m_minion.getFreqBid     (), 1)+ "\n"+
           m_deslocamento+"DFRE:"+DoubleToString(m_minion.getDeltaFreqAsk(), 7)+ "/" +
                                  DoubleToString(m_minion.getDeltaFreqBid(), 7)+ "\n" +
           m_deslocamento+"OPQU:"+DoubleToString(m_bufDeltaAsk          [0], 2)+ "/" +
                                  DoubleToString(m_bufDeltaBid          [0], 2)+ "\n" +
          m_deslocamento+"LRTRADE   :"+DoubleToString(m_minion.getLogRetTrade     (), 15)+ "\n" +
          m_deslocamento+"LRTRADEMED:"+DoubleToString(m_minion.getLogRetTradeMedio(), 15)+ "\n" +

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
    ArraySetAsSeries(m_bufDeltaAsk , modo );
    ArraySetAsSeries(m_bufDeltaBid , modo );
    ArraySetAsSeries(m_bufIsel     , modo );
}
//void zerarBufDemanda(uint i){
//   m_bufPbuy     [i] = 0;
//   m_bufPsel     [i] = 0;
//   m_bufPtra     [i] = 0;
//}
void zerarBufForca(uint i){
   m_bufDeltaAsk     [i] = 0;
   m_bufDeltaBid     [i] = 0;
   m_bufIsel         [i] = 0;
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
