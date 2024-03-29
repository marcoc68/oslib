﻿//+------------------------------------------------------------------+
//|                                        osi-teste-01-03-feira.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
//#include <..\Projects\projetcts\os-ea\OsPadraoDefineIndicator.mqh>
#include <..\Projects\projetcts\os-ea\OsPadraoLib.mqh>
#include <..\Projects\projetcts\os-ea\ClassMinion-02-com-estatistica.mqh>
#include <Files\FileTxt.mqh>

input bool   DEBUG             = false ; // se true, grava informacoes de debug no log.
input bool   GERAR_VOLUME      = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input bool   GERAR_OFERTAS     = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
input int    QTD_BAR_PROC_HIST = 10    ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input double BOOK_OUT          = 0.4   ; // Porcentagem das extremidades dos precos do book que serão desprezados.  

#define LOG(txt)        if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha ",__LINE__,":",(txt));}
#define LOG_ONCALC      LOG("RatesTot:"+IntegerToString(  rates_total)+" PrevCalc:"+IntegerToString(  prev_calculated) );
#define LOG_ONCALC_HIST LOG("RatesTot:"+IntegerToString(p_rates_total)+" PrevCalc:"+IntegerToString(p_prev_calculated) );

//#define LOG_DEBUG_ONCALC                if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha:",__LINE__,": ratesTot:",rates_total," prevCalc:",prev_calculated);}
//#define LOG_DEBUG_RESULT_REGISTRO_BOOK  if(DEBUG){Print("DEBUGINDICATOR:Resultado registro book "+m_symb.Name()+":", m_tembook);}

#property description "Indicador que considera a bolsa como uma grande feira, cheia de barracas"
#property description "de vendedores e compradores."
#property description "Se o comprador ou vendedor é dono de barraca"
#property description "continuar..."

#property indicator_chart_window 

#property indicator_buffers 12
#property indicator_plots   12

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

// variaveis para controle do livro de ofertas
MqlBookInfo m_book[];
double      m_pmask      = 0;
double      m_pmbid      = 0;
double      m_pm         = 0;
uint        m_qtdWinAsk  = 0;
uint        m_qtdWinBid  = 0;
uint        m_qtdEmpate  = 0;
double      m_dask       = 0;
double      m_dbid       = 0;
bool        m_tembook    = false;
uint        m_id_oferta  = 0;

// variaveis para controle dos ticks
CSymbolInfo   m_symb  ;
ClassMinion02 m_minion;
bool          m_prochist; // para nao reprocessar o historico sempre que mudar de barra;

double m_vbuy    = 0;
double m_vsel    = 0;
double m_tickvol = 0;

// apresentacao de depuracao
string m_dom_txt     ;
string m_dom_previsao;
string m_tick_txt    ;

// variaveis para controle do arquivo de log
int  m_log             ; // para gravar dados estatisticos em arquivo de log

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

ENUM_TIMEFRAMES m_periodo;
double          m_sec_barra;    // segundos na barra atual
double          m_sec_barraAnt; // segundos na barra atual
double          m_sec_barraAtu; // segundos na barra atual

//+------------------------------------------------------------------+ 
//| Função de inicialização do indicador customizado                 | 
//+------------------------------------------------------------------+ 
int OnInit() { 
   //PRINT_DEBUG_INIT_INI
   LOG("=======================================");
   m_symb.Name        ( Symbol() );
   m_symb.Refresh     ();
   m_symb.RefreshRates();
   
   m_periodo = PeriodSeconds();

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
   
   Print("Definindo buffers do indicador...");
   SetIndexBuffer(0,m_bufPsel     , INDICATOR_DATA  ); 
   SetIndexBuffer(1,m_bufPbuy     , INDICATOR_DATA  ); 
   SetIndexBuffer(2,m_bufPask     , INDICATOR_DATA  ); 
   SetIndexBuffer(3,m_bufPbid     , INDICATOR_DATA  ); 
   SetIndexBuffer(4,m_bufPaskArrow, INDICATOR_DATA  ); 
   SetIndexBuffer(5,m_bufPbidArrow, INDICATOR_DATA  ); 
   SetIndexBuffer(6,m_bufPbuyArrow, INDICATOR_DATA  ); 
   SetIndexBuffer(7,m_bufPselArrow, INDICATOR_DATA  ); 
   SetIndexBuffer(8 ,m_bufPup1Arrow, INDICATOR_DATA  ); 
   SetIndexBuffer(9 ,m_bufPup2Arrow, INDICATOR_DATA  ); 
   SetIndexBuffer(10,m_bufPdw1Arrow, INDICATOR_DATA  ); 
   SetIndexBuffer(11,m_bufPdw2Arrow, INDICATOR_DATA  ); 

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
   IndicatorSetString(INDICATOR_SHORTNAME,"osi-01-03-feira");    

//--- ticks 
   m_minion.setPeriodoDinamico(true);     //controle de periodo externo ao minion (eu controlo) 
   m_minion.setModoHibrido(GERAR_VOLUME); //se opcao eh true, gera volume baseado nos ticks. Usado em papeis que nao informam volume.
   m_minion.refresh();

   m_prochist = false; // indica se deve reprocessar o historico.
      
//--- debug
   if( DEBUG ){
      string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
      StringReplace ( dt, ".", ""  );
      StringReplace ( dt, ":", ""  );
      StringReplace ( dt, " ", "_" );
      
      openLogFile            ("osi-01-03-feira_" + m_symb.Name() + "_" + dt + "_book.csv" );
      m_minion.setLogFileName("osi-01-03-feira_" + m_symb.Name() + "_" + dt + "_ticks.csv");
   }
   

//--- 
   return(INIT_SUCCEEDED); 
} 
  
void OnDeinit(const int i){
  LOG("Executando...");
  MarketBookRelease( m_symb.Name() );
  delete(&m_symb  );
  //delete(&m_minion);
  //delete(&m_book);
  FileClose( m_log );
  LOG("Finalizado!");
}  

//+------------------------------------------------------------------+ 
//| Atualizando os volumes de bid e oferta                       | 
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

     // testando o indicador
     MqlTick tick   ;    
     double dxSel   = 0;
     double dxBuy   = 0;
     double medTick = 0;
     //---------
     LOG_ONCALC;
     if( !m_prochist ){ // para nao reprocessar a ultima barra sempre que mudar de barra.
          setAsSeries(false);
          doOnCalculateHistorico(rates_total, prev_calculated,time);
          setAsSeries(true);
     }
     LOG_ONCALC;
      
     int irt = rates_total-1;
   //Print("[i]:",i, " [irt]:",irt, " rates_total:",rates_total, " prev_calculated:",prev_calculated);
    
     SymbolInfoTick(_Symbol,tick);// um tick por chamada a oncalculate
   //Print("Atual time[irt]:",time[irt], " time tick atual:", tick.time, " time_tick_msc atual:",tick.time_msc);
     

     //===============================================================================================
     // Processamento atualizando a barra anterior assim que inicia a nova...
     //===============================================================================================
     if(rates_total > prev_calculated){
        //--
        m_minion.fecharPeriodo();
        //-- book
        m_bufPbidArrow[1] = 0; 
        m_bufPaskArrow[1] = 0;
        if( m_dbid > m_dask ){ m_bufPbidArrow[1] = m_pmbid;}
        if( m_dbid < m_dask ){ m_bufPaskArrow[1] = m_pmask;}
        m_qtdWinAsk     = 0;
        m_qtdWinBid     = 0;
        m_qtdEmpate     = 0;
        m_dask          = 0;
        m_dbid          = 0;
        //-- ticks
        m_bufPbuyArrow[1] = 0;
        m_bufPselArrow[1] = 0;
        dxSel   = MathAbs(m_minion.getDxSell0());
        dxBuy   = MathAbs(m_minion.getDxBuy0 ());
        medTick =         m_minion.getMed0   () ;
        m_bufPbuyArrow[1] = dxBuy <= dxSel ? m_minion.getMedBuy0() : 0;
        m_bufPselArrow[1] = dxSel <= dxBuy ? m_minion.getMedSell0(): 0;
        m_bufPbuy     [1] = m_minion.getMedBuy0() ;
        m_bufPsel     [1] = m_minion.getMedSell0();
        printf("-------------------------");
        flushLogBook();
     }
     //===============================================================================================
     
     
     //===============================================================================================
     // Processamento o tick da barra atual...
     //===============================================================================================
     //processando o evento atual...
     m_minion.refresh(tick);
     writeDetLogTick( "PC:"+IntegerToString(prev_calculated) + "/RT:" + IntegerToString(rates_total) );

     dxSel   = MathAbs(m_minion.getDxSell0());
     dxBuy   =         m_minion.getDxBuy0 () ;
     medTick =         m_minion.getMed0   () ;
     
  //if( rates_total >= prev_calculated ){//&& dxSel>0 && dxBuy>0 && medTick>0 ){
     m_bufPbuy     [0] = m_minion.getMedBuy0();
     m_bufPsel     [0] = m_minion.getMedSell0();
     m_bufPbuyArrow[0] = dxBuy < dxSel ? m_minion.getMedBuy0() : 0;
     m_bufPselArrow[0] = dxSel < dxBuy ? m_minion.getMedSell0(): 0;
     //m_bufPbuy     [irt] = m_minion.getMedBuy0();
     //m_bufPsel     [irt] = m_minion.getMedSell0();
     //m_bufPbuyArrow[irt] = dxBuy < dxSel ? m_minion.getMedBuy0() : 0;
     //m_bufPselArrow[irt] = dxSel < dxBuy ? m_minion.getMedSell0(): 0;
     //===============================================================================================
  //}
  
     //===============================================================================================
     // plotando as ofertas do book na barra atual
     //===============================================================================================
     if( m_tembook ){
        if( rates_total >= prev_calculated && m_pmask>0 && m_pmbid>0 && m_pm>0 ){
            m_bufPask[0] = m_pmask;
            m_bufPbid[0] = m_pmbid;
           if( m_dbid >  m_dask ){ m_bufPbidArrow[0] = m_pmbid; m_bufPaskArrow[0] = 0; }
           if( m_dbid <  m_dask ){ m_bufPaskArrow[0] = m_pmask; m_bufPbidArrow[0] = 0; }
           if( m_dbid == m_dask ){ m_bufPaskArrow[0] = m_pmask; m_bufPbidArrow[0] = 0; }

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
           m_ofertaAsk   = m_bufPask[0]; // oferta  media ask (oferta  de venda )...
           m_ofertaBid   = m_bufPbid[0]; // oferta  media bid (oferta  de compra)...
           m_demandBuy   = m_bufPbuy[0]; // demanda media buy (demanda de compra)...
           m_demandSel   = m_bufPsel[0]; // demanda media sel (demanda de venda )...
           
           m_forcaAcima1 = (m_ofertaAsk > m_demandBuy);// Oferta media ask(book) maior que demanda buy(tick) médio --> força pra cima
           m_forcaAbaix1 = (m_ofertaBid < m_demandSel);// Oferta media bid(book) menor que demanda sel(tick) médio --> força pra baixo
           m_forcaAcima2 = ( m_forcaAcima1 && (m_ofertaBid >= m_demandSel) );// força pra cima  maior ainda
           m_forcaAbaix2 = ( m_forcaAbaix1 && (m_ofertaAsk <= m_demandBuy) );// força pra baixo maior ainda
           
           m_bufPup1Arrow[0] = m_forcaAcima1 ? m_ofertaAsk : 0;
           m_bufPup2Arrow[0] = m_forcaAcima2 ? m_ofertaAsk : 0;
           m_bufPdw1Arrow[0] = m_forcaAbaix1 ? m_ofertaBid : 0;
           m_bufPdw2Arrow[0] = m_forcaAbaix2 ? m_ofertaBid : 0;
           
           if( (m_ofertaAsk-m_minion.getMed0()) > (m_minion.getMed0()-m_ofertaBid) ) {
              //reforcar seta acima;
               m_bufPdw1Arrow[0] = 0;
               m_bufPdw2Arrow[0] = 0;
           }else{
              if( (m_ofertaAsk-m_minion.getMed0()) < (m_minion.getMed0()-m_ofertaBid) ) {
                 //reforcar seta abaixo
                 m_bufPup1Arrow[0] = 0;
                 m_bufPup2Arrow[0] = 0;
              }else{
                 // nao reforcar
                 m_bufPup1Arrow[0] = 0;
                 m_bufPup2Arrow[0] = 0;
                 m_bufPdw1Arrow[0] = 0;
                 m_bufPdw2Arrow[0] = 0;
              }
              
           }
           
           //=================================================================================================
        }
     }else{
        m_bufPask     [0] = 0;m_bufPbid     [0] = 0; m_bufPaskArrow[0] = 0; m_bufPbidArrow[0] = 0;
        m_bufPup1Arrow[0] = 0;m_bufPup2Arrow[0] = 0; m_bufPdw1Arrow[0] = 0; m_bufPdw2Arrow[0] = 0;
        m_bufPask     [0] = m_minion.ask();
        m_bufPbid     [0] = m_minion.bid();
        m_bufPaskArrow[0] = m_minion.last()>=m_minion.ask()?m_minion.ask():0;// <TODO> continue daqui. Isso tá dando errado.
        m_bufPbidArrow[0] = m_minion.last()<=m_minion.bid()?m_minion.bid():0;// <TODO> continue daqui. Isso tá dando errado.
     }
     //===============================================================================================

    // segundos na barra atual...
     bool tipo = ArrayIsSeries(time);
     ArraySetAsSeries(time,true);
     m_sec_barraAtu =   TimeCurrent();
     m_sec_barraAnt =   time[0];
     m_sec_barra    =   m_sec_barraAtu - m_sec_barraAnt;
     
     ArraySetAsSeries(time,tipo);

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

     double dxSel   = 0;
     double dxBuy   = 0;
     double medTick = 0;
     
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
          
          m_minion.fecharPeriodo(); // fechando o periodo anterior de coleta de estatisticas
          qtdTicks = CopyTicksRange( _Symbol         , //const string     symbol_name,          // nome do símbolo 
                                     ticks           , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks 
                                     COPY_TICKS_ALL  , //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos 
                                     p_time[i-1]*1000, //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks 
                                     p_time[i  ]*1000  //ulong            to_msc=0              // data ate a qual são solicitados os ticks 
                     );
                        
          for(int ind=0; ind<qtdTicks; ind++){
            //Print("[i]:", i,                                 // indice da barra no historico 
            //      " p_time[i-1]",p_time[i-1]," p_time[i]",p_time[i], // tempo inicial e final da barra 
            //      " Hqtdtick:", qtdTicks,                    // quantidade de tick recuperados para esta barra
            //      " Hind:", ind, " HTick:", ticks[ind].time);// cada tick da barra
            
            m_minion.refresh(ticks[ind]);
            writeDetLogTick( "PC:"+IntegerToString(p_prev_calculated) + "/RT:" + IntegerToString(p_rates_total) );
   
            dxSel   = MathAbs(m_minion.getDxSell0());
            dxBuy   =         m_minion.getDxBuy0 () ;
            medTick =         m_minion.getMed0   () ;
   
            m_bufPbuy     [i] = m_minion.getMedBuy0 ();
            m_bufPsel     [i] = m_minion.getMedSell0();
            
            m_bufPbuyArrow[i] = dxBuy < dxSel ? m_minion.getMedBuy0() : 0;
            m_bufPselArrow[i] = dxSel < dxBuy ? m_minion.getMedSell0(): 0;
            
            // pra nao ficar aparecendo as linhas do book com valores errados no passado.
            m_bufPask     [i] = 0;
            m_bufPbid     [i] = 0;
            m_bufPaskArrow[i] = 0;
            m_bufPbidArrow[i] = 0;
            
            m_bufPask     [i] = m_minion.ask();
            m_bufPbid     [i] = m_minion.bid();
            m_bufPaskArrow[i] = m_minion.last()>=m_minion.ask()?m_minion.ask():0;// continue daqui. Isso tá dando errado.
            m_bufPbidArrow[i] = m_minion.last()<=m_minion.bid()?m_minion.bid():0;// continue daqui. Isso tá dando errado.
            //m_bufPask     [i] = ticks[ind].ask;
            //m_bufPbid     [i] = ticks[ind].bid;
            //m_bufPaskArrow[i] = ticks[ind].last>=ticks[ind].ask?ticks[ind].ask:0;
            //m_bufPbidArrow[i] = ticks[ind].last<=ticks[ind].bid?ticks[ind].bid:0;
            m_bufPup1Arrow[i] = 0;
            m_bufPup2Arrow[i] = 0; 
            m_bufPdw1Arrow[i] = 0; 
            m_bufPdw2Arrow[i] = 0;
   
           //===============================================================================================
           // Imprimindo dados de depuracao...
           //===============================================================================================
            imprimirComment();  
          }
     }
     m_minion.fecharPeriodo(); // fechando o periodo anterior de coleta de estatisticas
     m_prochist = true;
     Print( "Historico processado :-)" );
}//doOnCalculateHistorico.

string m_deslocamento = "                                                "+
                        "                                                "+
                        "                                                "+
                        "                                                "+
                        "                                                "+
                        "                                                "+
                        "                                                ";
void imprimirComment(){
  //===============================================================================================
  // Imprimindo dados de depuracao...
  //===============================================================================================
   m_tick_txt = m_deslocamento+"VBUY===: " + DoubleToString(m_minion.getVolBuy0() ,_Digits)+ "(" + DoubleToString(m_minion.getAceVolBuy0(),5 )+")\n"+
                m_deslocamento+"VSEL===: " + DoubleToString(m_minion.getVolSell0(),_Digits)+ "(" + DoubleToString(m_minion.getAceVolSel0(),5 )+")\n"+
                m_deslocamento+"VTOT===: " + DoubleToString(m_minion.getVol0()    ,_Digits)+ "(" + DoubleToString(m_minion.getAceVol0   (),5 )+")\n"+
                m_deslocamento+"PMEDBUY: " + DoubleToString(m_minion.getMedBuy0() ,2      )+ "\n" +
                m_deslocamento+"PMEDSEL: " + DoubleToString(m_minion.getMedSell0(),2      )+ "\n" +
                m_deslocamento+"PMED===: " + DoubleToString(m_minion.getMed0()    ,2      )+ "\n" +
                m_deslocamento+"DXBUY==: " + DoubleToString(m_minion.getDxBuy0()  ,2      )+ "\n" +
                m_deslocamento+"DXSEL==: " + DoubleToString(m_minion.getDxSell0() ,2      )+ "\n" +
                m_deslocamento+"================================================\n"              +
                m_deslocamento+"ACEVTOT: " + DoubleToString(m_minion.getAceVol0   (),5    )+ "\n" +
                m_deslocamento+"ACEVBUY: " + DoubleToString(m_minion.getAceVolBuy0(),5    )+ "\n" +
                m_deslocamento+"ACEVSEL: " + DoubleToString(m_minion.getAceVolSel0(),5    )+ "\n" +
                m_deslocamento+"TBARRA : " + DoubleToString(m_periodo               ,0    )+ "\n" +
                m_deslocamento+"TSEC   : " + DoubleToString(m_sec_barra             ,0    )+ "\n" +
                m_deslocamento+"================================================\n"              ;

   Comment(m_deslocamento+"DOM PREVISAO ======================================\n"+
           m_dom_previsao + 
          //"DOM TXT ==========================================\n"+
           //m_dom_txt + 
           m_deslocamento+"TICK TXT ==========================================\n"+
           m_tick_txt);
  //===============================================================================================
}


void OnBookEvent(const string &symbol){
  
   if(!m_tembook){ return; }
  
   MarketBookGet(symbol, m_book);
   uint tamanhoBook = ArraySize(m_book);
   if(tamanhoBook == 0) { printf("Falha carregando livro de ofertas. Motivo: " + (string)GetLastError()); return; }
 //Print("Tamanho do book:",tamanhoBook);
   double vask  = 0;
   double vbid  = 0;
   //
   double vpask = 0;
   double vpbid = 0;
   ///
   double pvpask = 0;
   double pvpbid = 0;
   ///
   double pmask  = 0; //preco medio das ofertas de venda
   double pmbid  = 0; //preco medio das ofertas de compra
   double pm     = 0;

   vpask  = 0; // volume de ofertas de venda  x peso
   vpbid  = 0; // volume de ofertas de compra x peso
   pvpask = 0; // preco de ofertas de venda  x volume de ofertas de venda x peso
   pvpbid = 0; // preco de ofertas de compra x volume de ofertas de venda x peso

//
   double pesoAsk = 0.0; // peso adicional das ofertas de venda  (peso referente a posicao do preco no book)
   double pesoBid = 0.0; // peso adicional das ofertas de compra (peso referente a posicao do preco no book)
   m_dom_txt      = "" ;
   
   
   // calculando os precos significativos no book...
   uint desprezarAsk = (int)( tamanhoBook * (BOOK_OUT/2.0) )-1;
   uint desprezarBid =  tamanhoBook - desprezarAsk - 1;
   
   
   for(uint i=0; i< tamanhoBook; i++ ){

     // calibrando os pesos em funcao da posicao do preco no book...
     pesoAsk = m_book[0].price - m_book[i            ].price + m_symb.TickSize();
     pesoBid = m_book[i].price - m_book[tamanhoBook-1].price + m_symb.TickSize();
          
     m_dom_txt += 
           symbol      +":"                                             +
           "[id]:"     + IntegerToString(m_id_oferta)                   + 
           "[i]:"      + IntegerToString(i                            ) +
           " TP:"      + IntegerToString(m_book[i].type               ) + 
           " VOL:"     + IntegerToString(m_book[i].volume             ) + 
           " VOLR:"    + DoubleToString (m_book[i].volume_real,m_symb.Digits() ) +
           " PRICE:"   + DoubleToString (m_book[i].price      ,m_symb.Digits() ) +
           " pesoAsk:" + DoubleToString (pesoAsk              ,m_symb.Digits() ) +
           " pesoBid:" + DoubleToString (pesoBid              ,m_symb.Digits() ) + "\n";
         //writeDetLogBook(m_id_oferta, i+1, m_book[i].type, m_book[i].volume, m_book[i].volume_real, m_book[i].price, pesoAsk, pesoBid );

     if( m_book[i].type == BOOK_TYPE_SELL && i > desprezarAsk ){
         vask       +=   m_book[i].volume_real;
         vpask      += (                         m_book[i].volume_real*pesoAsk );
         pvpask     += ( m_book[i].volume_real * m_book[i].price      *pesoAsk );
         writeDetLogBook(m_id_oferta, i+1, "ASK",m_book[i].volume_real, m_book[i].price, pesoAsk, m_book[i].volume_real*pesoAsk, pvpask );
     }else{
         if( m_book[i].type == BOOK_TYPE_BUY && i < desprezarBid ){
            vbid   +=   m_book[i].volume_real;
            vpbid  += (                         m_book[i].volume_real*pesoBid );
            pvpbid += ( m_book[i].volume_real * m_book[i].price      *pesoBid );
            writeDetLogBook(m_id_oferta, i+1, "BID",m_book[i].volume_real, m_book[i].price, pesoBid, m_book[i].volume_real*pesoBid, pvpbid );
         }else{
            if( i>desprezarAsk && i<desprezarBid ){
                Print("Nenhum tipo ///////////////////////////////////////// desprezarAsk:",desprezarAsk," desprezarBid:",desprezarBid, " i:", i);
            }
         }
     }
   }//laco for
   m_id_oferta++;
   //Comment(m_dom_txt);

   pmask = NormalizeDouble(  pvpask         / oneIfZero(  vpask        ), m_symb.Digits() );   
   pmbid = NormalizeDouble(  pvpbid         / oneIfZero(  vpbid        ), m_symb.Digits() );
   pm    = NormalizeDouble( (pvpask+pvpbid) / oneIfZero( (vpask+vpbid) ), m_symb.Digits() );
   
   string bolinha_ask    = "";
   string bolinha_bid    = "";
   string bolinha_empate = "";
   
   double dx_pmask = (pmask - pm   );
   double dx_pmbid = (pm    - pmbid);
   
   if(dx_pmbid  > dx_pmask){ m_qtdWinBid++   ; m_dbid += (dx_pmbid-dx_pmask); bolinha_bid    = " *";} 
   if(dx_pmbid  < dx_pmask){ m_qtdWinAsk++   ; m_dask += (dx_pmask-dx_pmbid); bolinha_ask    = " *";} 
   if(dx_pmbid == dx_pmask){ m_qtdEmpate++;                                   bolinha_empate = " *";} 
   
   m_dom_previsao = m_deslocamento+"EMPATE                    :" + IntegerToString(m_qtdEmpate   ,0)  + "    :" +                                   bolinha_empate +"\n"+ 
                    m_deslocamento+"OFERTAS VENDA  (ASK) SOBE :" + IntegerToString(m_qtdWinAsk   ,0)  + "    :" +  DoubleToString(m_dask,_Digits) + bolinha_ask    +"\n"+ 
                    m_deslocamento+"OFERTAS COMPRA (BID) DESCE:" + IntegerToString(m_qtdWinBid   ,0)  + "    :" +  DoubleToString(m_dbid,_Digits) + bolinha_bid    +"\n"+
                    m_deslocamento+"VOL OFERTAS DE VENDA (ASK):" + DoubleToString (vask            )  +"\n"+
                    m_deslocamento+"VOL OFERTAS DE COMPRA(BID):" + DoubleToString (vbid            )  +"\n"+
                    m_deslocamento+"VOL OFERTAS               :" + DoubleToString (vbid+vask       )  +"\n"
                  //m_deslocamento+"POINT                     :" + DoubleToString (_Point          )  +"\n"+
                  //m_deslocamento+"TICKSIZE                  :" + DoubleToString (m_symb.TickSize()) +"\n"
                    ;
 //Comment(m_dom_previsao + m_dom_txt);
   m_pmask = pmask;
   m_pmbid = pmbid; 
   m_pm    = pm;
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
}
void zerarBufDemanda(uint i){
  m_bufPbuy     [i] = 0;
  m_bufPsel     [i] = 0;
  m_bufPbuyArrow[i] = 0;
  m_bufPselArrow[i] = 0;
}
void zerarBufOferta(uint i){
  m_bufPask     [i] = 0;
  m_bufPbid     [i] = 0;
  m_bufPaskArrow[i] = 0;
  m_bufPbidArrow[i] = 0;
}
void zerarBufForca(uint i){
  m_bufPup1Arrow[i] = 0;
  m_bufPup2Arrow[i] = 0; 
  m_bufPdw1Arrow[i] = 0; 
  m_bufPdw2Arrow[i] = 0;
}
void zerarBufOfertaDemanda(uint i){ zerarBufOferta(i); zerarBufDemanda(i); zerarBufForca(i); }

//double oneIfZero( double n ){
//  if( n==0 ) return 1.0;
//  return n;
//}
void openLogFile(string arqLog){m_log=FileOpen(arqLog, FILE_WRITE|FILE_CSV,';'); writeHeaderLogBook();}

void writeHeaderLogBook(){
   if( !DEBUG ){ return; }

   FileWrite( m_log,
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
  FileWrite( m_log,
             m_symb.Name()                  , 
             dt                             ,
             IntegerToString( id           ),
             IntegerToString( i            ),
             tp                             ,
             DoubleToString ( volr           ,_Digits ),
             DoubleToString ( price          ,_Digits ),
             DoubleToString ( distPrice      ,_Digits ),
             DoubleToString ( volXdist       ,_Digits ),
             DoubleToString ( priceXvolXdist ,_Digits )
           );
}

void flushLogBook()                 { if( DEBUG ){ FileFlush(m_log)          ; } }
void writeDetLogTick(string comment){ if( DEBUG ){ m_minion.logWrite(comment); } } // escrevendo o log de ticks...

double getTime2EndPeriod(){
 int tempoDecorrido = PeriodSeconds(m_periodo);
 return tempoDecorrido;
}  
//+------------------------------------------------------------------+

