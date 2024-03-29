﻿//+------------------------------------------------------------------+
//|                                        osi-teste-02-01-feira.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#include <Trade\SymbolInfo.mqh>
#include <Files\FileTxt.mqh>
#include <oslib\osc-util.mqh>
#include <oslib\os-lib.mq5>
#include <oslib\osc-estatistic2.mqh>
#include <oslib\osc-tick-util.mqh>

input bool   DEBUG                  = false ; // se true, grava informacoes de debug no log.
input bool   GERAR_VOLUME           = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input bool   GERAR_OFERTAS          = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
input int    QTD_BAR_PROC_HIST              = 0     ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input double OSI_FEIRA_BOOK_OUT             = 0.4   ; // Porcentagem das extremidades dos precos do book que serão desprezados.
input int    OSI_FEIRA_QTD_PERIODO_CALC_MEDIAS = 7 ; // qtd de ticks usados no processamento estatistico.
//input int    OSI_FEIRA_BOOK_ON_CALCULATE    = true  ; // se true, processa processa o book somente na execucao do oncalculate

#define LOG(txt)        if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha ",__LINE__,":",(txt));}
#define LOG_ONCALC      LOG("RatesTot:"+IntegerToString(  rates_total)+" PrevCalc:"+IntegerToString(  prev_calculated) );
#define LOG_ONCALC_HIST LOG("RatesTot:"+IntegerToString(p_rates_total)+" PrevCalc:"+IntegerToString(p_prev_calculated) );

#define OSI_FEIRA_SHORT_NAME "osi-02-01-feira"
#define DEBUG_TICK           false

//#define LOG_DEBUG_ONCALC                if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha:",__LINE__,": ratesTot:",rates_total," prevCalc:",prev_calculated);}
//#define LOG_DEBUG_RESULT_REGISTRO_BOOK  if(DEBUG){Print("DEBUGINDICATOR:Resultado registro book "+m_symb.Name()+":", m_tembook);}

#property description "Indicador que considera a bolsa como uma feira, com barracas"
#property description "de vendedores e compradores."
#property description "---------------"
#property description "osi-02-01-feira: Passa a acumular por quantidade de periodos. As versões 01-0X acumulavam por quantidade de ticks."
#property description "---------------"

#property indicator_chart_window
#property indicator_buffers 14
#property indicator_plots   14

//---- plotar linha com o preco medio de vendas
#property indicator_label1  "pm_sell"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrFireBrick
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//---- plotar linha com preco medio de compras
#property indicator_label2  "pm_buy"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrMediumBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//---- plotar linha com o preco medio de ofertas de venda (ask)
#property indicator_label3  "pm_ask"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

//---- plotar linha com o preco medio de ofertas de compra (bid)
#property indicator_label4  "pm_bid"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDeepSkyBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

//---- plotar seta forca ask
#property indicator_label5  "sig_ask"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrMagenta
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

//---- plotar seta forca bid
#property indicator_label6  "sig_bid"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrDeepSkyBlue
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

//---- plotar seta forca buy
#property indicator_label7  "sig_buy"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrMediumBlue
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

//---- plotar seta forca sel
#property indicator_label8  "sig_sel"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrFireBrick
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1

//---- plotar seta forca up1
#property indicator_label9  "up1"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrDeepSkyBlue
#property indicator_style9  STYLE_SOLID
#property indicator_width9  3

//---- plotar seta forca up2
#property indicator_label10  "up2"
#property indicator_type10   DRAW_ARROW
#property indicator_color10  clrDeepSkyBlue
#property indicator_style10  STYLE_SOLID
#property indicator_width10  3

//---- plotar seta forca down1
#property indicator_label11  "down1"
#property indicator_type11   DRAW_ARROW
#property indicator_color11  clrFireBrick
#property indicator_style11  STYLE_SOLID
#property indicator_width11  3

//---- plotar seta forca down2
#property indicator_label12  "down2"
#property indicator_type12   DRAW_ARROW
#property indicator_color12  clrFireBrick
#property indicator_style12  STYLE_SOLID
#property indicator_width12  3

//---- plotar linha preco medio do trade
#property indicator_label13  "pm_trade"
#property indicator_type13   DRAW_LINE
#property indicator_color13  clrDarkViolet  // clrDarkOrchid
#property indicator_style13  STYLE_DASH
#property indicator_width13  3

//---- plotar linha preco medio do book de ofertas
#property indicator_label14  "pm_book"
#property indicator_type14   DRAW_LINE
#property indicator_color14  clrGold //clrDarkOrange //clrOrangeRed
#property indicator_style14  STYLE_DASH
#property indicator_width14  3


//--- buffers do indicador
double m_bufPsel     []; // preco medio de compras                    :1
double m_bufPbuy     []; // preco medio de vendas                     :2
double m_bufPask     []; // preco medio de ofertas de venda           :3
double m_bufPbid     []; // preco medio de ofertas de compra          :4
double m_bufPaskArrow[]; // forca do preco medio de ofertas de venda  :5
double m_bufPbidArrow[]; // forca do preco medio de ofertas de compra :6
double m_bufPbuyArrow[]; // forca do preco medio de venda             :7
double m_bufPselArrow[]; // forca do preco medio de compra            :8
double m_bufPup1Arrow[]; // forca acima 1                             :9
double m_bufPup2Arrow[]; // forca acima 2                             :10
double m_bufPdw1Arrow[]; // forca acima 1                             :11
double m_bufPdw2Arrow[]; // forca acima 2                             :12
double m_bufPtra     []; // preco medio de trades (buy/sel)           :13
double m_bufPbok     []; // preco medio de ofertas(ask/bid)           :14

// variaveis para controle do livro de ofertas
//MqlBookInfo m_book[];
double      m_pmask      = 0;
double      m_pmbid      = 0;
double      m_pmbok      = 0; //eh proco medio do book
uint        m_qtdWinAsk  = 0;
uint        m_qtdWinBid  = 0;
uint        m_qtdEmpate  = 0;
double      m_dask       = 0;
double      m_dbid       = 0;
bool        m_tembook    = false;
uint        m_id_oferta  = 0;

// variaveis para controle dos ticks
osc_estatistic2 m_minion   ; // estatisticas de ticks e book de ofertas
osc_tick_util  m_tick_util; // para simular ticks de trade em bolsas que nao informam last/volume.
CSymbolInfo    m_symb     ;
bool           m_prochist ; // para nao reprocessar o historico sempre que mudar de barra;

double m_vbuy    = 0;
double m_vsel    = 0;
double m_tickvol = 0;

// apresentacao de depuracao
string m_dom_txt     ;
string m_dom_previsao;
string m_tick_txt    ;

// variaveis para controle do arquivo de log
int  m_log_book         ; // descarreganto book de ofetas em arquivo de log (debug)
int  m_log_tick         ; // descarreganto ticks         em arquivo de log (debug)

//=================================================================================================
// Indicador demanda e oferta...
// Oferta media ask(book) maior que demanda buy(tick) médio --> força pra cima
// Oferta media bid(book) menor que demanda sel(tick) médio --> força pra baixo
//
// Oferta media ask(book) maior          que demanda buy(tick) médio e
// Oferta media bid(book) maior ou igual a   demanda sel(tick) médio --> força pra cima  maior ainda
//
// Oferta media bid(book) menor          que demanda sel(tick) médio e
// Oferta media ask(book) menor ou igual a   demanda buy(tick) médio --> força pra baixo maior ainda
//=================================================================================================
// variaveis para controle das forças liquidas
double m_ofertaAsk = 0; // oferta  media ask (oferta  de venda )...
double m_ofertaBid = 0; // oferta  media bid (oferta  de compra)...
double m_demandBuy = 0; // demanda media buy (demanda de compra)...
double m_demandSel = 0; // demanda media sel (demanda de venda )...

bool m_forcaAcima1 ;// Oferta media ask(book) maior que demanda buy(tick) médio --> força pra cima
bool m_forcaAbaix1 ;// Oferta media bid(book) menor que demanda sel(tick) médio --> força pra baixo
bool m_forcaAcima2 ;// força pra cima  maior ainda
bool m_forcaAbaix2 ;// força pra baixo maior ainda
//=================================================================================================

uint       m_qtd_sec_periodo  ;// qtd de segundos que tem o periodo grafico atual.
uint       m_sec_barra   ; // segundos na barra atual
datetime   m_sec_barraAnt; // segundos na barra atual
datetime   m_sec_barraAtu; // segundos na barra atual

//+------------------------------------------------------------------+
//| Função de inicialização do indicador customizado                 |
//+------------------------------------------------------------------+
int OnInit() {
   //PRINT_DEBUG_INIT_INI
   LOG("=======================================");
   m_symb.Name        ( Symbol() );
   m_symb.Refresh     ();
   m_symb.RefreshRates();

   m_qtd_sec_periodo = PeriodSeconds();

   m_tembook = MarketBookAdd( m_symb.Name() );
   LOG("Resultado registro book "+m_symb.Name()+":"+IntegerToString(m_tembook) );

   if (!m_tembook){
     Print("DOM indisponivel para "+m_symb.Name()+" :-(");
     if( GERAR_VOLUME ){
       Print("Simulacao de volume ativada! Seguiremos gerando ofertas e demandas a partir dos Ticks :-)" );
     }else{
        return (INIT_FAILED);
     }
   };

   ArraySetAsSeries(m_bufPsel     , false );
   ArraySetAsSeries(m_bufPbuy     , false );
   ArraySetAsSeries(m_bufPask     , false );
   ArraySetAsSeries(m_bufPbid     , false );
   ArraySetAsSeries(m_bufPaskArrow, false );
   ArraySetAsSeries(m_bufPbidArrow, false );
   ArraySetAsSeries(m_bufPbuyArrow, false );
   ArraySetAsSeries(m_bufPselArrow, false );
   ArraySetAsSeries(m_bufPup1Arrow, false );
   ArraySetAsSeries(m_bufPup2Arrow, false );
   ArraySetAsSeries(m_bufPdw1Arrow, false );
   ArraySetAsSeries(m_bufPdw2Arrow, false );
   ArraySetAsSeries(m_bufPtra     , false );
   ArraySetAsSeries(m_bufPbok     , false );

   Print("Definindo buffers do indicador...");
   SetIndexBuffer(0,m_bufPsel      , INDICATOR_DATA  );
   SetIndexBuffer(1,m_bufPbuy      , INDICATOR_DATA  );
   SetIndexBuffer(2,m_bufPask      , INDICATOR_DATA  );
   SetIndexBuffer(3,m_bufPbid      , INDICATOR_DATA  );
   SetIndexBuffer(4,m_bufPaskArrow , INDICATOR_DATA  );
   SetIndexBuffer(5,m_bufPbidArrow , INDICATOR_DATA  );
   SetIndexBuffer(6,m_bufPbuyArrow , INDICATOR_DATA  );
   SetIndexBuffer(7,m_bufPselArrow , INDICATOR_DATA  );
   SetIndexBuffer(8 ,m_bufPup1Arrow, INDICATOR_DATA  );
   SetIndexBuffer(9 ,m_bufPup2Arrow, INDICATOR_DATA  );
   SetIndexBuffer(10,m_bufPdw1Arrow, INDICATOR_DATA  );
   SetIndexBuffer(11,m_bufPdw2Arrow, INDICATOR_DATA  );
   SetIndexBuffer(12,m_bufPtra     , INDICATOR_DATA  );
   SetIndexBuffer(13,m_bufPbok     , INDICATOR_DATA  );

//--- Definir um valor vazio
   PlotIndexSetDouble(0 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(8 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(9 ,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(12,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(13,PLOT_EMPTY_VALUE,0);

//--- Definir o código símbolo para desenho em PLOT_ARROW
   PlotIndexSetInteger(4,PLOT_ARROW,225);  //ask
   PlotIndexSetInteger(5,PLOT_ARROW,226);  //bid

   PlotIndexSetInteger(6,PLOT_ARROW,233);  //buy
   PlotIndexSetInteger(7,PLOT_ARROW,234);  //sel

   PlotIndexSetInteger(8 ,PLOT_ARROW,217);//241);  //up1 217
   PlotIndexSetInteger(9 ,PLOT_ARROW,217);//241);  //up2 217
   PlotIndexSetInteger(10,PLOT_ARROW,218);//242);  //dw1 218
   PlotIndexSetInteger(11,PLOT_ARROW,218);//242);  //dw2 218

//--- Definindo o deslocamento vertical das setas em pixels...
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,+10);
   PlotIndexSetInteger(6,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(7,PLOT_ARROW_SHIFT,+10);

   PlotIndexSetInteger(8 ,PLOT_ARROW_SHIFT,-20); //up1
   PlotIndexSetInteger(9 ,PLOT_ARROW_SHIFT,-30); //up2
   PlotIndexSetInteger(10,PLOT_ARROW_SHIFT,+20); //dw1
   PlotIndexSetInteger(11,PLOT_ARROW_SHIFT,+30); //dw2

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,OSI_FEIRA_SHORT_NAME);

//--- ticks
 //m_minion.setModoHibrido(GERAR_VOLUME)    ; //se opcao eh true, gera volume baseado nos ticks. Usado em papeis que nao informam volume.
   m_minion.initialize(OSI_FEIRA_QTD_PERIODO_CALC_MEDIAS*m_qtd_sec_periodo); // quantidade de segundos que serao usados no calculo das medias.
   m_prochist = false; // indica se deve reprocessar o historico.
   m_tick_util.setTickSize(m_symb.TickSize(), m_symb.Digits() );

//--- debug
   if( DEBUG ){
      string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
      StringReplace ( dt, ".", ""  );
      StringReplace ( dt, ":", ""  );
      StringReplace ( dt, " ", "_" );
      openLogFileBook(OSI_FEIRA_SHORT_NAME + "_" + m_symb.Name() + IntegerToString(_Period) + "_" + dt + "_book.csv" );
      openLogFileTick(OSI_FEIRA_SHORT_NAME + "_" + m_symb.Name() + IntegerToString(_Period) + "_" + dt + "_tick.csv" );
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
  FileClose( m_log_book );
  FileClose( m_log_tick );
  LOG("OnDeinit Finalizado!");
}

//+------------------------------------------------------------------+
//| Atualizando os volumes de bid e oferta                           |
//+------------------------------------------------------------------+
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
    // Processamentos dos ticks (demanda)
    //===============================================================================================
    //m_minion.refresh();
    //m_minion.logWrite( "PC:"+IntegerToString(prev_calculated) + "/RT:" + IntegerToString(rates_total) );
    //m_lineBuffer1[0] = (double)m_minion.getVolSell0();

     MqlTick tick   ;
     double dxSel   = 0;
     double dxBuy   = 0;
     //double medTick = 0;
     //---------
     LOG_ONCALC;
     if( !m_prochist ){ // para nao reprocessar a ultima barra sempre que mudar de barra.
          setAsSeries(false);
          doOnCalculateHistorico(rates_total, prev_calculated,time);
          setAsSeries(true);
     }
     LOG_ONCALC;

   //   //===============================================================================================
   //   // Processamento atualizando a barra anterior assim que inicia a nova...
   //   //===============================================================================================
   //   if(rates_total > prev_calculated){
   //      //-- book
   //      m_bufPbidArrow[1] = 0;
   //      m_bufPaskArrow[1] = 0;
   //      if( m_dbid > m_dask ){ m_bufPbidArrow[1] = m_pmbid;}
   //      if( m_dbid < m_dask ){ m_bufPaskArrow[1] = m_pmask;}
   //      m_qtdWinAsk     = 0;
   //      m_qtdWinBid     = 0;
   //      m_qtdEmpate     = 0;
   //      m_dask          = 0;
   //      m_dbid          = 0;
   //      //-- ticks
   //      m_bufPbuyArrow[1] = 0;
   //      m_bufPselArrow[1] = 0;
   //      dxSel   = m_minion.getDxSel();
   //      dxBuy   = m_minion.getDxBuy();
   //    //medTick =          m_minion.getPrecoMedTrade();// getMed0   () ;
   //      m_bufPbuyArrow[1] = dxBuy <= dxSel ? m_minion.getPrecoMedTradeBuy():0;
   //      m_bufPselArrow[1] = dxSel <= dxBuy ? m_minion.getPrecoMedTradeSel():0;
   //      m_bufPbuy     [1] = m_minion.getPrecoMedTradeBuy();
   //      m_bufPsel     [1] = m_minion.getPrecoMedTradeSel();
   //      m_bufPtra     [1] = m_minion.getPrecoMedTrade();
   //      printf("-------------------------");
   //      flushLogBook();
   //   }
     //===============================================================================================


     //===============================================================================================
     // Processamento o tick da barra atual...
     //===============================================================================================
     //processando o evento atual...
     SymbolInfoTick(_Symbol,tick);// um tick por chamada a oncalculate
     normalizar2trade(tick);
     m_minion.addTick(tick);

     dxSel   =  m_minion.getDxSel()  ;
     dxBuy   =  m_minion.getDxBuy()  ;

     m_bufPbuy     [0] = m_minion.getPrecoMedTradeBuy();
     m_bufPsel     [0] = m_minion.getPrecoMedTradeSel();
     m_bufPtra     [0] = m_minion.getPrecoMedTrade();
     m_bufPbuyArrow[0] = dxBuy < dxSel ? m_minion.getPrecoMedTradeBuy():0;
     m_bufPselArrow[0] = dxSel < dxBuy ? m_minion.getPrecoMedTradeSel():0;
     //===============================================================================================
  //}

     // Nao tem book, simulamos com os ticks...
     if( !m_tembook ){ doOnBookEvent(tick); }

     // processando book no oncalculate...
     //if( OSI_FEIRA_BOOK_ON_CALCULATE ) doOnBookEvent(_Symbol);

     //===============================================================================================
     // plotando as ofertas do book na barra atual
     //===============================================================================================
        if( rates_total >= prev_calculated && m_pmask>0 && m_pmbid>0 && m_pmbok>0 ){
            m_bufPask[0] = m_minion.getPrecoMedBookAsk();
            m_bufPbid[0] = m_minion.getPrecoMedBookBid();
            m_bufPbok[0] = m_minion.getPrecoMedBook();
           if( m_dbid >  m_dask ){ m_bufPbidArrow[0] = m_minion.getPrecoMedBookBid(); m_bufPaskArrow[0] = 0; }
           if( m_dbid <  m_dask ){ m_bufPaskArrow[0] = m_minion.getPrecoMedBookAsk(); m_bufPbidArrow[0] = 0; }
           if( m_dbid == m_dask ){ m_bufPaskArrow[0] = 0                            ; m_bufPbidArrow[0] = 0; }

           //=================================================================================================
           // Indicador demanda e oferta...
           // Oferta media ask(book) maior[menor] que demanda buy(tick) médio --> força pra cima
           // Oferta media bid(book) menor que demanda sel(tick) médio --> força pra baixo
           //
           // Oferta media ask(book) maior          que demanda buy(tick) médio e
           // Oferta media bid(book) maior ou igual a   demanda sel(tick) médio --> força pra cima  maior ainda
           //
           // Oferta media bid(book) menor          que demanda sel(tick) médio e
           // Oferta media ask(book) menor ou igual a   demanda buy(tick) médio --> força pra baixo maior ainda
           //=================================================================================================
           m_ofertaAsk   = m_bufPask[0]; // oferta  media ask (oferta  de venda )...
           m_ofertaBid   = m_bufPbid[0]; // oferta  media bid (oferta  de compra)...
           m_demandBuy   = m_bufPbuy[0]; // demanda media buy (demanda de compra)...
           m_demandSel   = m_bufPsel[0]; // demanda media sel (demanda de venda )...

           m_forcaAcima1 = (m_ofertaAsk < m_demandBuy);// Oferta media ask(book) maior[menor] que demanda buy(tick) médio --> força pra cima
           m_forcaAbaix1 = (m_ofertaBid > m_demandSel);// Oferta media bid(book) menor[maior] que demanda sel(tick) médio --> força pra baixo
           m_forcaAcima2 = ( m_forcaAcima1 && (m_ofertaBid < m_demandSel) );// força pra cima  maior ainda
           m_forcaAbaix2 = ( m_forcaAbaix1 && (m_ofertaAsk > m_demandBuy) );// força pra baixo maior ainda

           m_bufPup1Arrow[0] = m_forcaAcima1 ? m_ofertaAsk : 0;
           m_bufPup2Arrow[0] = m_forcaAcima2 ? m_ofertaAsk : 0;
           m_bufPdw1Arrow[0] = m_forcaAbaix1 ? m_ofertaBid : 0;
           m_bufPdw2Arrow[0] = m_forcaAbaix2 ? m_ofertaBid : 0;

         // //if( (m_ofertaAsk-m_minion.getMed0()) > (m_minion.getMed0()-m_ofertaBid) ) {
         //   if( (m_ofertaAsk-m_minion.getPrecoMedTrade()) > (m_minion.getPrecoMedTrade()-m_ofertaBid) ) {
         //      //reforcar seta acima;
         //       m_bufPdw1Arrow[0] = 0;
         //       m_bufPdw2Arrow[0] = 0;
         //   }else{
         //    //if( (m_ofertaAsk-m_minion.getMed0()) < (m_minion.getMed0()-m_ofertaBid) ) {
         //      if( (m_ofertaAsk-m_minion.getPrecoMedTrade()) < (m_minion.getPrecoMedTrade()-m_ofertaBid) ) {
         //         //reforcar seta abaixo
         //         m_bufPup1Arrow[0] = 0;
         //         m_bufPup2Arrow[0] = 0;
         //      }else{
         //         // nao reforcar
         //         m_bufPup1Arrow[0] = 0;
         //         m_bufPup2Arrow[0] = 0;
         //         m_bufPdw1Arrow[0] = 0;
         //         m_bufPdw2Arrow[0] = 0;
         //      }
         //   }
      //}
     }

     // mudou a barra, entao verificamos se eh necessario alterar o tamanho dos vetores de acumulacao de medias...
     //if( rates_total > prev_calculated ){ m_minion.checkResize(0.3); }

     //===============================================================================================
     calcTempoBarraAtual(time); // segundos na barra atual...
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
   LOG_ONCALC_HIST;
   setAsSeries(false);
   zerarBufOfertaDemanda(p_prev_calculated);

   // processando o historico...
   for( int i=p_prev_calculated; i<p_rates_total; i++ ){ // O -1 eh pra nao processar o periodo atual dentro do laco.

      // durante os testes, seguimos somente com as ultimas n barras
      // se prev_calculated eh zero, acontece erro ao buscar o tempo de fechamento da barra anterior
      if( (p_rates_total-i) > QTD_BAR_PROC_HIST || i==0 ){
         zerarBufOfertaDemanda(p_prev_calculated); continue;
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
         doOnBookEvent(ticks[ind])   ;// simulando o book de ofertas durante o processamento do historico...
         m_bufPbuy     [i] = m_minion.getPrecoMedTradeBuy();
         m_bufPsel     [i] = m_minion.getPrecoMedTradeSel();
         m_bufPtra     [i] = m_minion.getPrecoMedTrade();
         m_bufPbuyArrow[i] = m_minion.getDxBuy() < m_minion.getDxSel() ? m_minion.getPrecoMedTradeBuy():0;
         m_bufPselArrow[i] = m_minion.getDxSel() < m_minion.getDxBuy() ? m_minion.getPrecoMedTradeSel():0;
         m_bufPask     [i] = m_minion.getPrecoMedBookAsk();
         m_bufPbid     [i] = m_minion.getPrecoMedBookBid();
         m_bufPbok     [i] = m_minion.getPrecoMedBook();
         m_bufPaskArrow[i] = m_minion.getDxAsk() < m_minion.getDxBid() ? m_minion.getPrecoMedBookAsk():0;// verifique.
         m_bufPbidArrow[i] = m_minion.getDxBid() < m_minion.getDxAsk() ? m_minion.getPrecoMedBookBid():0;// verifique
         m_bufPup1Arrow[i] = 0;
         m_bufPup2Arrow[i] = 0;
         m_bufPdw1Arrow[i] = 0;
         m_bufPdw2Arrow[i] = 0;
        //===============================================================================================
        // Imprimindo dados de depuracao...
        //===============================================================================================
         imprimirComment();
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
void imprimirComment(){
  //===============================================================================================
  // Imprimindo dados de depuracao...
  //===============================================================================================
   m_tick_txt =
                m_deslocamento+"PMEDBUY: " + DoubleToString (m_minion.getPrecoMedTradeBuy()   ,_Digits )+ "\n" +
                m_deslocamento+"PMEDSEL: " + DoubleToString (m_minion.getPrecoMedTradeSel()   ,_Digits )+ "\n" +
                m_deslocamento+"PMED===: " + DoubleToString (m_minion.getPrecoMedTrade()      ,_Digits )+ "\n" +

         "\n" + m_deslocamento+"=== VOL/VOL MEDIO/(ACEL VOL) ====\n" +
                m_deslocamento+"TOT: " + DoubleToString(m_minion.getVolTrade      ()    ,_Digits)+ "/"+
                                         DoubleToString(m_minion.getVolMedTrade   ()    ,1      )+ "/"+
                                     "("+DoubleToString(m_minion.getAceVol        ()    ,5      )+")\n"+
                m_deslocamento+"BUY: " + DoubleToString(m_minion.getVolTradeBuy   ()    ,_Digits)+ "/"+
                                         DoubleToString(m_minion.getVolMedTradeBuy()    ,1      )+ "/"+
                                     "("+DoubleToString(m_minion.getAceVolBuy     ()    ,5      )+")\n"+
                m_deslocamento+"SEL: " + DoubleToString(m_minion.getVolTradeSel   ()    ,_Digits)+ "/"+
                                         DoubleToString(m_minion.getVolMedTradeSel()    ,1      )+ "/"+
                                     "("+DoubleToString(m_minion.getAceVolSel     ()    ,5      )+")\n"+

          "\n"+ m_deslocamento+"=== INCLINACOES E DX ========================\n"                                           +
                m_deslocamento+"BUY: " + DoubleToString (m_minion.getInclinacaoTradeBuy() ,5 )+ " / DX: " + DoubleToString (m_minion.getDxBuy() ,5 ) + "\n"+
                m_deslocamento+"SEL: " + DoubleToString (m_minion.getInclinacaoTradeSel() ,5 )+ " / DX: " + DoubleToString (m_minion.getDxSel() ,5 ) + "\n"+
                m_deslocamento+"TRA: " + DoubleToString (m_minion.getInclinacaoTrade()    ,5 )+ "\n" +
              //m_deslocamento+"===========================\n"                                           +
                m_deslocamento+"ASK: " + DoubleToString (m_minion.getInclinacaoBookAsk() ,5 )+ " / DX: " + DoubleToString (m_minion.getDxAsk() ,5 ) + "\n"+
                m_deslocamento+"BID: " + DoubleToString (m_minion.getInclinacaoBookBid() ,5 )+ " / DX: " + DoubleToString (m_minion.getDxBid() ,5 ) + "\n"+
                m_deslocamento+"BOK: " + DoubleToString (m_minion.getInclinacaoBook()    ,5 )+ "\n" +

          "\n"+ m_deslocamento+"=== BARRAS ACUMULADAS ========================\n"                                           +
                m_deslocamento+"TOT/BUY/SEL:"    + DoubleToString(double(m_minion.getTempoAcumTrade     ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                                   DoubleToString(double(m_minion.getTempoAcumTradeBuy  ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                                   DoubleToString(double(m_minion.getTempoAcumTradeSel  ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
                m_deslocamento+"TOT/ASK/BID:"    + DoubleToString(double(m_minion.getTempoAcumBook      ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                                   DoubleToString(double(m_minion.getTempoAcumBookAsk   ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                                   DoubleToString(double(m_minion.getTempoAcumBookBid   ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
                m_deslocamento+"ACE TOT/BUY/SEL:"+ DoubleToString(double(m_minion.getTempoAcumAceVol    ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                                   DoubleToString(double(m_minion.getTempoAcumAceVolBuy ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                                   DoubleToString(double(m_minion.getTempoAcumAceVolSel ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
                m_deslocamento+"TATU/BAR: "      + DoubleToString (m_sec_barra                    ,0 ) + "/"  +
                                                   DoubleToString (m_qtd_sec_periodo              ,0 ) + "\n" +

         //"\n" + m_deslocamento+"=== TAMANHO/VOLTAS/INDICE ====\n"                                                           +
                //m_deslocamento+"LEN_VET TRAD:"+ IntegerToString(m_minion.getLenVetAcumTrade()  )+ "  /  "  +
                //                       "BOOK:"+ IntegerToString(m_minion.getLenVetAcumBook()   )+ " (" + IntegerToString(m_minion.getLenVetAcumBook() /
                //                                                                                                         m_minion.getLenVetAcumTrade() ) + "x)\n"+
                //m_deslocamento+"VOLTA TOT/BUY/SEL  : " + IntegerToString(m_minion.getQtdVoltaTrade   ())+ "/"  +
                //                                   IntegerToString(m_minion.getQtdVoltaTradeBuy())+ "/"  +
                //                                   IntegerToString(m_minion.getQtdVoltaTradeSel())+ "\n" +
                //m_deslocamento+"VOLTA TOT/ASK/BID  : " + IntegerToString(m_minion.getQtdVoltaBook    ())+ "/"  +
                //                                   IntegerToString(m_minion.getQtdVoltaBookAsk ())+ "/"  +
                //                                   IntegerToString(m_minion.getQtdVoltaBookBid ())+ "\n" +
                //m_deslocamento+"IND TOT/BUY/SEL:" + IntegerToString(m_minion.getIndTrade   ()     )+ "/" +
                //                                    IntegerToString(m_minion.getIndTradeBuy()     )+ "/" +
                //                                    IntegerToString(m_minion.getIndTradeSel()     )+ "\n"+
                //m_deslocamento+"IND TOT/ASK/BID:" + IntegerToString(m_minion.getIndBook    ()     )+ "/" +
                //                                    IntegerToString(m_minion.getIndBookAsk ()     )+ "/" +
                //                                    IntegerToString(m_minion.getIndBookBid ()     )+ "\n"+
              //m_deslocamento+"TK:"       + m_tick_util.toString()                         + "\n" +
         "\n" + m_deslocamento+"=== TAMANHO DOS VETORES DE MEDIAS ====\n"+
                m_deslocamento+"TRADE TOT/BUY/SEL:" + IntegerToString(m_minion.getLenVetAcumTrade    ()) + "/"  +
                                                      IntegerToString(m_minion.getLenVetAcumTradeBuy ()) + "/"  +
                                                      IntegerToString(m_minion.getLenVetAcumTradeSel ()) + "\n" +
                m_deslocamento+"BOOK TOT/ASK/BID=:" + IntegerToString(m_minion.getLenVetAcumBook     ()) + "/"  +
                                                      IntegerToString(m_minion.getLenVetAcumBookAsk  ()) + "/"  +
                                                      IntegerToString(m_minion.getLenVetAcumBookBid  ()) + "\n" +
                m_deslocamento+"ACEVO TOT/BUY/SEL:" + IntegerToString(m_minion.getLenVetAcumAceVol   ()) + "/"  +
                                                      IntegerToString(m_minion.getLenVetAcumAceVolBuy()) + "/"  +
                                                      IntegerToString(m_minion.getLenVetAcumAceVolSel()) + "\n" ;

   // string terminal_txt =
   //              m_deslocamento+"MEM_FIS(MB):" + osc_util::getTermMemFisicaStr      () + "\n" +
   //              m_deslocamento+"MEM_TOT(MB):" + osc_util::getTermMemTotalStr       () + "\n" +
   //              m_deslocamento+"MEM_USA(MB):" + osc_util::getTermMemUsadaStr       () + "\n" +
   //              m_deslocamento+"MEM_DIS(MB):" + osc_util::getTermMemDispStr        () + "\n" +
   //       "\n" + m_deslocamento+"CPU_64==:"    + osc_util::getTermCpuX64Str         () + "\n" +
   //              m_deslocamento+"CPU_COR=:"    + osc_util::getTermCpuCoresStr       () + "\n" +
   //              m_deslocamento+"CPU_OPCL:"    + osc_util::getTermCpuOpenClSuportStr() + "\n" +
   //       "\n" + m_deslocamento+"DSK_DISP:"    + osc_util::getTermDiskSpaceStr      () + "\n" ;

   Comment(       m_deslocamento+"DOM PREVISAO ======================================\n"+
                  m_dom_previsao +
          //"DOM TXT ==========================================\n"+
           //m_dom_txt +
           "\n" + m_deslocamento+"TICK ==============================================\n"+
                  m_tick_txt+

         //   "\n" + m_deslocamento+"TERMINAL ==========================================\n"+
         //          terminal_txt+

           "\n" + m_deslocamento+"FIM ==============================================="  );
  //===============================================================================================
}

// gerado pelo sistema...
void OnBookEvent(const string &symbol){

   if(symbol!=_Symbol)             return; // garantindo que nao estamos processando o book de outro simbolo,
   //if(OSI_FEIRA_BOOK_ON_CALCULATE) return; // se processa o book somente no oncalculate, volta daqui...

   //MqlBookInfo book[];
   //MarketBookGet(symbol, book);
   //doOnBookEvent2(book,OSI_FEIRA_BOOK_OUT, TimeCurrent());
   doOnBookEvent(symbol);
}

// chamado no oncalculate quendo queremos processar book na mesma velocidade dos ticks. Um book pra cada oncalculate.
void doOnBookEvent(const string &symbol){
   MqlBookInfo book[];
   MarketBookGet(symbol, book);
   doOnBookEvent2(book,OSI_FEIRA_BOOK_OUT, TimeCurrent());
}

// chamado quando nao tem book disponivel
void doOnBookEvent(MqlTick& tick){
   MqlBookInfo book[2];
   book[0].price       = tick.ask      ;
   book[0].type        = BOOK_TYPE_SELL;
   book[0].volume      = 1             ;
   book[0].volume_real = 1             ;
   book[1].price       = tick.bid      ;
   book[1].type        = BOOK_TYPE_BUY ;
   book[1].volume      = 1             ;
   book[1].volume_real = 1             ;
 //doOnBookEvent (book,0);
   doOnBookEvent2(book,0, tick.time); // aqui pode ser processamento de historico, entao usamos a hora do tick e nao a hora atual do servidor.
}


// acumulacao do book de ofertas baseado no minion de estatisticas...
void doOnBookEvent2(MqlBookInfo& book[], double book_out, datetime pTime){
   int tamanhoBook = ArraySize(book);
   if(tamanhoBook == 0) { printf("Falha carregando livro de ofertas. Motivo: " + (string)GetLastError()); return; }

   // em processamento historico ou de mercados sem DOM, recebo a hora para usar na estatistisca do book...
   // em processamento online, usamos a hora da ultima cotacao recebida.
   datetime dth = (pTime==0)? TimeCurrent() : pTime;

   m_minion.addBook( dth, book, tamanhoBook,book_out, m_symb.TickSize() );

   string bolinha_ask    = "";
   string bolinha_bid    = "";
   string bolinha_empate = "";

   if(m_minion.getDxBid()  < m_minion.getDxAsk()){ m_qtdWinBid++; m_dbid += (m_minion.getDxAsk()-m_minion.getDxBid()); bolinha_bid    = " *";}
   if(m_minion.getDxBid()  > m_minion.getDxAsk()){ m_qtdWinAsk++; m_dask += (m_minion.getDxBid()-m_minion.getDxAsk()); bolinha_ask    = " *";}
   if(m_minion.getDxBid() == m_minion.getDxAsk()){ m_qtdEmpate++;                                                      bolinha_empate = " *";}

   m_pmask = m_minion.getPrecoMedBookAsk();
   m_pmbid = m_minion.getPrecoMedBookBid();
   m_pmbok = m_minion.getPrecoMedBook();

   m_dom_previsao = m_deslocamento+"FORCA EMPATE             :" + IntegerToString(m_qtdEmpate   ,0)  + "    :" +                                   bolinha_empate +"\n"+
                    m_deslocamento+"FORCA OFER VEN(ASK) SOBE :" + IntegerToString(m_qtdWinAsk   ,0)  + "    :" +  DoubleToString(m_dask,_Digits) + bolinha_ask    +"\n"+
                    m_deslocamento+"FORCA OFER COM(BID) DESCE:" + IntegerToString(m_qtdWinBid   ,0)  + "    :" +  DoubleToString(m_dbid,_Digits) + bolinha_bid    +"\n"+
                    m_deslocamento+"VOL TOT/VEN(ASK)/COM(BID):" + DoubleToString (m_minion.getVolBook()   , _Digits )  +"/"+
                                                                  DoubleToString (m_minion.getVolBookAsk(), _Digits )  +"/"+
                                                                  DoubleToString (m_minion.getVolBookBid(), _Digits )  +"\n"+

                  //m_deslocamento+"DXASK/DXBID : "             + DoubleToString (m_minion.getDxAsk()     , _Digits )  +"/" +
                  //                                              DoubleToString (m_minion.getDxBid()     , _Digits )  +"\n"  +

                    m_deslocamento+"PRECO MED ASK/BID:" + DoubleToString (m_minion.getPrecoMedBookAsk(), _Digits )  +"/" +
                                                          DoubleToString (m_minion.getPrecoMedBookBid(), _Digits )  +"\n"+
                   //m_deslocamento+"IND TOT/BUY/SEL: " + IntegerToString(m_minion.getIndBook   ()      )+ "/" +
                   //                                     IntegerToString(m_minion.getIndBookAsk()      )+ "/" +
                   //                                     IntegerToString(m_minion.getIndBookBid()      )+ "\n"  +
                   //m_deslocamento+"=======\n"                                                          +
                   //m_deslocamento+"BAR TOT/ASK/BID: " + DoubleToString(double(m_minion.getTempoAcumBook   ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                   //                                     DoubleToString(double(m_minion.getTempoAcumBookAsk())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                   //                                     DoubleToString(double(m_minion.getTempoAcumBookBid())/(double)m_qtd_sec_periodo, 2 )+ "\n"
                   m_deslocamento+"=======FIM\n";
}


void setAsSeries(bool modo){
   ArraySetAsSeries(m_bufPsel     , modo );
   ArraySetAsSeries(m_bufPbuy     , modo );
   ArraySetAsSeries(m_bufPask     , modo );
   ArraySetAsSeries(m_bufPbid     , modo );
   ArraySetAsSeries(m_bufPaskArrow, modo );
   ArraySetAsSeries(m_bufPbidArrow, modo );
   ArraySetAsSeries(m_bufPbuyArrow, modo );
   ArraySetAsSeries(m_bufPselArrow, modo );
   ArraySetAsSeries(m_bufPup1Arrow, modo );
   ArraySetAsSeries(m_bufPup2Arrow, modo );
   ArraySetAsSeries(m_bufPdw1Arrow, modo );
   ArraySetAsSeries(m_bufPdw2Arrow, modo );
   ArraySetAsSeries(m_bufPtra     , modo );
   ArraySetAsSeries(m_bufPbok     , modo );
}
void zerarBufDemanda(uint i){
  m_bufPbuy     [i] = 0;
  m_bufPsel     [i] = 0;
  m_bufPtra     [i] = 0;
  m_bufPbuyArrow[i] = 0;
  m_bufPselArrow[i] = 0;
}
void zerarBufOferta(uint i){
  m_bufPask     [i] = 0;
  m_bufPbid     [i] = 0;
  m_bufPbok     [i] = 0;
  m_bufPaskArrow[i] = 0;
  m_bufPbidArrow[i] = 0;
}
void zerarBufForca(uint i){
  m_bufPup1Arrow[i] = 0;
  m_bufPup2Arrow[i] = 0;
  m_bufPdw1Arrow[i] = 0;
  m_bufPdw2Arrow[i] = 0;
}

// calcula a quantidade de segundos da barra atual e bem como a % de tempo decorrido...
uint   m_sec_barra_pro_fim        ;
double m_porcTempoDesdeInicioBarra;
double m_porcTempoToFimBarra      ;
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

void zerarBufOfertaDemanda(uint i){ zerarBufOferta(i); zerarBufDemanda(i); zerarBufForca(i); }

void openLogFileBook(string arqLog){m_log_book=FileOpen(arqLog, FILE_WRITE|FILE_CSV,';'); writeHeaderLogBook();}
void openLogFileTick(string arqLog){m_log_tick=FileOpen(arqLog, FILE_WRITE             );                      }

void writeHeaderLogBook(){
   if( !DEBUG ){ return; }

   FileWrite( m_log_book ,
              "SYMB"     ,
              "DATA"     ,
              "ID"       ,
              "I"        ,
              "TP"       ,
              "VOLR"     ,
              "PRICE"    ,
              "DIST"     ,
              "volXdist" ,
              "priceXvolXdistACUM" );
}

void writeDetLogBook(uint id, int i, string tp, double volr, double price, double distPrice, double volXdist, double priceXvolXdist ){

  if( !DEBUG ){ return; }

  string dt = TimeToString(  m_symb.Time(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
  StringReplace ( dt, ".", "-" );
  FileWrite( m_log_book                      ,
             m_symb.Name()                   ,
             dt                              ,
             IntegerToString( id            ),
             IntegerToString( i             ),
             tp                              ,
             DoubleToString ( volr           ,_Digits ),
             DoubleToString ( price          ,_Digits ),
             DoubleToString ( distPrice      ,_Digits ),
             DoubleToString ( volXdist       ,_Digits ),
             DoubleToString ( priceXvolXdist ,_Digits )
           );
}

void flushLogBook()                 { if( DEBUG               ){ FileFlush(m_log_book                                   ); } }
void flushLogTick()                 { if( DEBUG || DEBUG_TICK ){ FileFlush(m_log_tick                                   ); } }
void writeDetLogTick(string comment){ if( DEBUG || DEBUG_TICK ){ FileWrite(m_log_tick, m_tick_util.toStringCSV(comment) ); } } // escrevendo o log de ticks...

//+------------------------------------------------------------------+

