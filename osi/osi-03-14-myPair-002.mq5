﻿//+------------------------------------------------------------------+
//|                                         osi-03-14-myPair-002.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//|                                                                  |
//|                                                                  |
//| Versao 2 usando C0002ArbitragemPar no lugar do calculo direto    |
//|          do ratio e de sua media.                                |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "3.013"

#include <Trade\SymbolInfo.mqh>
#include <Files\FileTxt.mqh>
#include <oslib\osc-util.mqh>
#include <oslib\os-lib.mq5>
//#include <oslib\osc-estatistic2.mqh>
#include <oslib\osc-tick-util.mqh>
#include <oslib\osc\est\C0002ArbitragemPar.mqh>
#include <Math\Stat\Math.mqh>

input bool   DEBUG                    = false   ; // se true, grava informacoes de debug no log.
input bool   GERAR_VOLUME             = false   ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input int    QTD_BAR_PROC_HIST        = 0       ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input int    QTD_SEGUNDOS_MEDIA_TICKS = 05      ; // qtd de segundos usados no processamento estatistico.
input string MY_PAIR                  = "BOVA11"; // par do simbolo do grafico.
input double MULTIPLICADO             = 1000.0  ; // multiplicador para igualar a razao dos simbolos.
input int    PERIODOS_MEDIA           = 21      ; // quantidade de periodos para calcular a media do ratio.


#define LOG(txt)        if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha ",__LINE__,":",(txt));}

#define OSI_FEIRA_SHORT_NAME "osi-03-14-myPair-002"
#define DEBUG_TICK     false

#property description "Apresenta o ratio entre pares de ativos."

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   4

//---- plotar linha com aceleracao do volume liquida 
#property indicator_label1  "media"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime //clrFireBrick
#property indicator_style1  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "ratio"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "var+"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "var-"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRed
#property indicator_style4  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width4  1


//--- buffers do indicador
//double m_bufPsel           []; // preco medio de compras                         :1
//double m_bufPbuy           []; // preco medio de vendas                          :2
//double m_bufPtra           []; // preco medio de trades (buy/sel)                :13

  double m_buf_media         []; // media do ratio nos ultimos xx periodos         :1
  double m_buf_ratio         []; // ratio atual                                    :2
  double m_buf_var_pos       []; // variancia positiva do ratio medio              :3
  double m_buf_var_neg       []; // variancia negativa do ratio medio              :4

// variaveis para controle dos ticks
//osc_estatistic2 m_minion    ; // estatisticas de ticks e book de ofertas do primeiro ativo
//osc_estatistic2 m_minion2   ; // estatisticas de ticks e book de ofertas do segundo  ativo
osc_tick_util   m_tick_util ; // para simular ticks de trade em bolsas que nao informam last/volume.
osc_tick_util   m_tick_util2; // para simular ticks de trade em bolsas que nao informam last/volume (segundo ativo).
CSymbolInfo     m_symb      ;
CSymbolInfo     m_symb2     ;
bool            m_prochist  ; // para nao reprocessar o historico sempre que mudar de barra;
C0002ArbitragemPar m_par    ; // para encontrar oportunidades de arbitragem entre pares de ativos.

// apresentacao de depuracao
string m_tick_txt    ;

// variaveis para controle do arquivo de log
int  m_log_tick      ; // descarreganto ticks         em arquivo de log (debug)

// variaveis para controle das forças liquidas
//double m_demandBuy = 0; // demanda media buy (demanda de compra)...
//double m_demandSel = 0; // demanda media sel (demanda de venda )...

//=================================================================================================

uint       m_qtd_sec_periodo;// qtd de segundos que tem o periodo grafico atual.
uint       m_sec_barra      ; // segundos na barra atual
datetime   m_sec_barraAnt   ; // segundos na barra atual
datetime   m_sec_barraAtu   ; // segundos na barra atual

//+------------------------------------------------------------------+
//| Função de inicialização do indicador customizado                 |
//+------------------------------------------------------------------+
int OnInit() {
   //PRINT_DEBUG_INIT_INI
   LOG("=======================================");
   m_symb.Name        ( Symbol() );
   m_symb.Refresh     ();
   m_symb.RefreshRates();

   m_symb2.Name        ( MY_PAIR );
   m_symb2.Refresh     ();
   m_symb2.RefreshRates();

   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[DEBUG                   =", DEBUG                   , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[GERAR_VOLUME            =", GERAR_VOLUME            , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[QTD_BAR_PROC_HIST       =", QTD_BAR_PROC_HIST       , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[QTD_SEGUNDOS_MEDIA_TICKS=", QTD_SEGUNDOS_MEDIA_TICKS, "]");
   
   m_qtd_sec_periodo = PeriodSeconds();
   setAsSeries(true);

   Print("Definindo buffers do indicador...");
   SetIndexBuffer( 0,m_buf_media   , INDICATOR_DATA  ); 
   SetIndexBuffer( 1,m_buf_ratio   , INDICATOR_DATA  ); 
   SetIndexBuffer( 2,m_buf_var_pos , INDICATOR_DATA  ); 
   SetIndexBuffer( 3,m_buf_var_neg , INDICATOR_DATA  ); 


//--- Definir um valor vazio
   PlotIndexSetDouble( 0 ,PLOT_EMPTY_VALUE,0); // m_buf_media     
   PlotIndexSetDouble( 1 ,PLOT_EMPTY_VALUE,0); // m_buf_ratio     
   PlotIndexSetDouble( 2 ,PLOT_EMPTY_VALUE,0); // m_buf_var_pos     
   PlotIndexSetDouble( 3 ,PLOT_EMPTY_VALUE,0); // m_buf_var_neg     

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,
                      OSI_FEIRA_SHORT_NAME+"("+IntegerToString(QTD_BAR_PROC_HIST      )+","+
                                               IntegerToString(QTD_SEGUNDOS_MEDIA_TICKS)+")");
   
   IndicatorSetInteger(INDICATOR_DIGITS,9);

//--- ticks
 //m_minion.setModoHibrido(GERAR_VOLUME)    ; //se opcao eh true, gera volume baseado nos ticks. Usado em papeis que nao informam volume.
   //m_minion.initialize(QTD_SEGUNDOS_MEDIA_TICKS); // quantidade de segundos que serao usados no calculo das medias.
   //m_minion.setConsertarTicksSemFlag(false);
   //m_minion.setSymbolStr( m_symb.Name() );
   
   //m_minion2.initialize(QTD_SEGUNDOS_MEDIA_TICKS); // quantidade de segundos que serao usados no calculo das medias.
   //m_minion2.setConsertarTicksSemFlag(false);
   //m_minion2.setSymbolStr( MY_PAIR );
   
   m_prochist = false; // indica se deve reprocessar o historico.
   m_tick_util .setTickSize(m_symb .TickSize(), m_symb .Digits() );
   m_tick_util2.setTickSize(m_symb2.TickSize(), m_symb2.Digits() );
   
 //m_med.initialize(PERIODOS_MEDIA*m_qtd_sec_periodo);
   m_par.initialize(QTD_SEGUNDOS_MEDIA_TICKS, PERIODOS_MEDIA*m_qtd_sec_periodo);
   

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
void normalizar2trade(MqlTick& tick, MqlTick& tick2){
   if(GERAR_VOLUME){
      writeDetLogTick( "ANT" );
      m_tick_util .normalizar2trade(tick );
      m_tick_util2.normalizar2trade(tick2);
      writeDetLogTick( "POS" );
   }
}

void OnDeinit(const int i){
  LOG("Executando OnDeinit...");
  MarketBookRelease( m_symb .Name() );
  MarketBookRelease( m_symb2.Name() );
  delete(&m_symb  );
  delete(&m_symb2 );
  //m_par.Clear();
  FileClose( m_log_tick );
  LOG("OnDeinit Finalizado!");
}

//+------------------------------------------------------------------+
//| Atualizando os volumes de bid e oferta                           |
//+------------------------------------------------------------------+
MqlTick     m_tick,m_tick2;
MqlDateTime m_dt;
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
    if(!m_prochist){ // para nao reprocessar a ultima barra sempre que mudar de barra.
        setAsSeries(false);
        doOnCalculateHistorico(rates_total, prev_calculated,time);
        setAsSeries(true);
    }

    //===============================================================================================
    // Processamento o tick da barra atual...
    //===============================================================================================
    //processando o evento atual...
    SymbolInfoTick  ( _Symbol,m_tick  );// um tick por chamada a oncalculate
    SymbolInfoTick  ( MY_PAIR,m_tick2 );// um tick por chamada a oncalculate

    normalizar2trade( m_tick,m_tick2 );// soh normaliza se a opcao GERAR_VOLUME estiver ativa
    m_par.addTick(m_tick,m_tick2);
    //Comment( m_dt.hour,":",m_dt.min,":", m_dt.sec,"   ", m_par.getRatio());
    
    // plotando no grafico entre 10:15 e 15:59
    m_buf_media   [0] = 0;
    m_buf_var_pos [0] = 0;
    m_buf_var_neg [0] = 0;
    
    TimeCurrent(m_dt);
    if( (m_dt.hour  < 10 || m_dt.hour > 16) ||
        (m_dt.hour == 10 && m_dt.min  < 08) ||
        (m_dt.hour == 16 && m_dt.min  > 54)  ){
        m_buf_ratio[0] = 0;
    }else{
        m_buf_ratio[0] = m_par.getRatio();
        
        // calculando a media ratio...
        if( m_dt.hour > 10 || m_dt.min > PERIODOS_MEDIA+08 ){
            m_buf_media  [0] = m_par.getRatioMedio();
            m_buf_var_pos[0] = m_buf_media[0]+ m_par.getRatioMedioDP();
            m_buf_var_neg[0] = m_buf_media[0]- m_par.getRatioMedioDP();
        }
    }
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
      qtdTicks = CopyTicksRange( _Symbol          , //const string     symbol_name,          // nome do símbolo
                                 ticks            , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                 COPY_TICKS_ALL   , //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                 p_time[i-1]*1000 , //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                 p_time[i  ]*1000); //ulong            to_msc=0              // data ate a qual são solicitados os ticks

      for(int ind=0; ind<qtdTicks; ind++){

       //m_minion .addTick(ticks [ind]);
         m_buf_media   [i] = 0;
         m_buf_var_pos [i] = 0;
         m_buf_var_neg [i] = 0;
         m_buf_ratio   [i] = 0; //m_minion2.getPrecoMedTrade()/m_minion.getPrecoMedTrade();

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

void setAsSeries(bool modo){
     ArraySetAsSeries(m_buf_media  , modo );
     ArraySetAsSeries(m_buf_ratio  , modo );
     ArraySetAsSeries(m_buf_var_pos, modo );
     ArraySetAsSeries(m_buf_var_neg, modo );
}

void zerarBufForca(uint i){
   m_buf_media  [i] = 0;
   m_buf_ratio  [i] = 0;
   m_buf_var_pos[i] = 0;
   m_buf_var_neg[i] = 0;
}

void zerarBufAll(uint i){
   zerarBufForca  (i);
}

void openLogFileTick(string arqLog){m_log_tick=FileOpen(arqLog, FILE_WRITE             );                      }
void flushLogTick()                 { if( DEBUG || DEBUG_TICK ){ FileFlush(m_log_tick                                   ); } }
void writeDetLogTick(string comment){ if( DEBUG || DEBUG_TICK ){ 
                                          FileWrite(m_log_tick, m_tick_util .toStringCSV(comment) ); 
                                          FileWrite(m_log_tick, m_tick_util2.toStringCSV(comment) ); 
                                      } 
                                    } // escrevendo o log de ticks...

//+------------------------------------------------------------------+
