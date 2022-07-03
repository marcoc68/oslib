//+------------------------------------------------------------------+
//|                         osi-03-18-04-desbalanceamento-volume.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//|                                                                  |
//| Indicador cusum. Mesmo esquema do osi-03-18-033-cusum, com as    |
//| seguintes diferencas:                                            |
//| 1. Usa volume do desbalanceamento de agressoes no lugar dos      |
//|    retornos.                                                     |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, OS Corp."
#property link      "http://www.os.org"
#property version   "1.000"

#include <Trade/SymbolInfo.mqh>
#include <Files/FileTxt.mqh>
#include <oslib/osc-tick-util.mqh>
#include <oslib/os-lib.mq5>
//#include <oslib/osc/data/osc-vetor-fila-item-volume.mqh>
#include <oslib/osc/data/osc-vet-circular-volume.mqh>
#include <oslib/osc/est/c00101cusum.mqh>

input bool   DEBUG                   = false   ; // se true, grava informacoes de debug no log.
input bool   NORMALIZAR_TICK         = false   ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input int    QTD_BAR_PROC_HIST       = 60      ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input double KK                      = 1       ; // K passo do preco para uma acumulacao direcional
input double HH                      = 5       ; // H qtd somas na mesma direcao para caracterizar a tendencia 
input int    QTD_TICKS_DESB_VOL      = 1000    ; // QTD_TICKS_DESB_VOL janela, em ticks, usada no calculo do desbalanceamento
input int    QTD_TICKS_ACUM_CUSUM    = 200     ; // QTD_TICKS_ACUM calcula a cada X ticks
input bool   APRESENTAR_COMMENT      = false   ; // APRESENTAR_COMMENT apresenta valor de variaveis na tela;


#define LOG(txt)        if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha ",__LINE__,":",(txt));}

#define OSI_SHORT_NAME "osi-03-18-04-desbalanceamento-volume"
#define DEBUG_TICK     false

#property description "Calcula tendencia do desbalanceamento dos volumes de agressões de compra e venda. O cálculo é feito com o algoritimo CUSUM."

#property indicator_separate_window
//#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

//---- [mostra o preco medio do trade]
#property indicator_label1  "desbalanceamento_medio"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue  //clrFireBrick //clrDarkViolet  // clrDarkOrchid
#property indicator_style1  STYLE_SOLID  //STYLE_DASH
#property indicator_width1  2

//---- plotar linha com o C+ 
#property indicator_label2  "C+"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue  //clrDarkViolet //clrFireBrick
#property indicator_style2  STYLE_SOLID    //STYLE_DASH    //STYLE_SOLID
#property indicator_width2  2

//---- plotar linha com o C-
#property indicator_label3  "C-"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

//---- [mostra o ultimo strike C+]
//#property indicator_label4  "C+"
//#property indicator_type4   DRAW_ARROW
//#property indicator_color4  clrBlue //clrFireBrick //clrDarkViolet  // clrDarkOrchid
//#property indicator_style4  STYLE_SOLID  //STYLE_DASH
//#property indicator_width4  2

//---- [mostra o ultimo strike C-]
//#property indicator_label5  "C-"
//#property indicator_type5   DRAW_ARROW
//#property indicator_color5  clrRed  //clrFireBrick //clrDarkViolet  // clrDarkOrchid
//#property indicator_style5  STYLE_SOLID  //STYLE_DASH
//#property indicator_width5  2

//--- buffers do indicador
double m_bufDesbMedio   []; // desbalanceamento medio :1
double m_bufStrikeMais  []; // c+                     :2
double m_bufStrikeMenos []; // c-                     :3
double m_bufStrikeHmais []; // H+                     :4
double m_bufStrikeHmenos[]; // H-                     :5

// variaveis para controle dos ticks
osc_vet_circular_volume m_vet_vol; // vetor circular para acumulacao de volumes
osc_tick_util   m_tick_util         ; // para simular ticks de trade em bolsas que nao informam last/volume.
CSymbolInfo     m_symb              ;
c00101cusum     m_cusum             ; //
bool            m_prochist          ; // para nao reprocessar o historico sempre que mudar de barra;

// apresentacao de depuracao
string m_comment    ;

// variaveis para controle do arquivo de log
int  m_log_tick      ; // descarreganto ticks em arquivo de log (debug)
//=================================================================================================

uint       m_qtd_sec_periodo;// qtd de segundos que tem o periodo grafico atual.
uint       m_sec_barra   ; // segundos na barra atual
datetime   m_sec_barraAnt; // segundos na barra atual
datetime   m_sec_barraAtu; // segundos na barra atual

bool m_strikeHmais  = false; 
bool m_strikeHmenos = false; 
bool m_strikeMais   = false; 
bool m_strikeMenos  = false;

//+------------------------------------------------------------------+
//| Função de inicialização do indicador customizado                 |
//+------------------------------------------------------------------+
int OnInit() {
   //PRINT_DEBUG_INIT_INI
   LOG("=======================================");
   m_symb.Name        ( Symbol() );
   m_symb.Refresh     ();
   m_symb.RefreshRates();

   Print(OSI_SHORT_NAME," [",__FUNCTION__,"]","[DEBUG                  =", DEBUG                  , "]");
   Print(OSI_SHORT_NAME," [",__FUNCTION__,"]","[NORMALIZAR_TICK        =", NORMALIZAR_TICK        , "]");
   Print(OSI_SHORT_NAME," [",__FUNCTION__,"]","[QTD_BAR_PROC_HIST      =", QTD_BAR_PROC_HIST      , "]");
   
   m_qtd_sec_periodo = PeriodSeconds();
   setAsSeries(true);

   Print("Definindo buffers do indicador...");
   SetIndexBuffer( 0,m_bufDesbMedio    , INDICATOR_DATA  );
   SetIndexBuffer( 1,m_bufStrikeMais    , INDICATOR_DATA  );
   SetIndexBuffer( 2,m_bufStrikeMenos   , INDICATOR_DATA  );
   //SetIndexBuffer( 3,m_bufStrikeHmais   , INDICATOR_DATA  ); 
   //SetIndexBuffer( 4,m_bufStrikeHmenos  , INDICATOR_DATA  );

//--- Definir um valor vazio
   //PlotIndexSetDouble( 0 ,PLOT_EMPTY_VALUE,0); // m_bufDesbMedio
   //PlotIndexSetDouble( 1 ,PLOT_EMPTY_VALUE,0); // m_bufStrikeMais    
   //PlotIndexSetDouble( 2 ,PLOT_EMPTY_VALUE,0); // m_bufStrikeMenos    
   //PlotIndexSetDouble( 3 ,PLOT_EMPTY_VALUE,0); // m_bufStrikeHmais    
   //PlotIndexSetDouble( 4 ,PLOT_EMPTY_VALUE,0); // m_bufStrikeHmenos    

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,OSI_SHORT_NAME);

//--- ticks
   m_prochist = false; // indica se deve reprocessar o historico.
   m_tick_util.setTickSize(m_symb.TickSize(), m_symb.Digits() );
   //m_cusum.setAcumularAcadaXTicks(QTD_TICKS_ACUM_CUSUM);
   m_cusum.initialize(HH,KK,QTD_TICKS_ACUM_CUSUM);
   //m_vet_vol.set_tamanho_fila(QTD_TICKS_DESB_VOL);
   m_vet_vol.initialize(QTD_TICKS_DESB_VOL);

//--- debug
   if( DEBUG ){
      string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
      StringReplace ( dt, ".", ""  );
      StringReplace ( dt, ":", ""  );
      StringReplace ( dt, " ", "_" );
      openLogFileTick(OSI_SHORT_NAME + "_" + m_symb.Name() + IntegerToString(_Period) + "_" + dt + "_tick.csv" );
      //if( !m_mydb.create_or_open_mydb() ) return (INIT_FAILED);
   }

   if( DEBUG_TICK ){
      string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
      StringReplace ( dt, ".", ""  );
      StringReplace ( dt, ":", ""  );
      StringReplace ( dt, " ", "_" );
      openLogFileTick(OSI_SHORT_NAME + "_" + m_symb.Name() + IntegerToString(_Period) + "_" + dt + "_tick.csv" );
   }

   return(INIT_SUCCEEDED);
}

// transforma o tick informativo em tick de trade. Usamos em mercados que nao informam volume ou last nos ticks.
void normalizar2trade(MqlTick& tick){
   if(NORMALIZAR_TICK){
      writeDetLogTick( "ANT" );
      m_tick_util.normalizar2trade(tick);
      writeDetLogTick( "POS" );
   }
}

void OnDeinit(const int i){
  LOG("Executando OnDeinit...");
  delete(&m_symb);
  FileClose( m_log_tick );
  LOG("OnDeinit Finalizado!");
}

int m_dig = _Digits;
void printTick(MqlTick& tick){
    //Print(osc_tick_util::toString(tick,m_dig) );
    /*
    Print(
        "[time "        ,tick.time       ,   // Hora da última atualização de preços 
       "][bid "         ,tick.bid        ,   // Preço corrente de venda 
       "][ask "         ,tick.ask        ,   // Preço corrente de compra 
       "][last "        ,tick.last       ,   // Preço da última operação (preço último) 
       "][volume "      ,tick.volume     ,   // Volume para o preço último corrente
       "][time_msc "    ,tick.time_msc   ,   // Tempo do "Last" preço atualizado em  milissegundos 
       "][flags "       ,tick.flags      ,   // Flags de tick  
       "][volume_real " ,tick.volume_real,   // Volume para o preço Last atual com maior precisão     
       "]"
    );
    */
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
    if(!m_prochist){ // para nao reprocessar a ultima barra sempre que mudar de barra.
        setAsSeries(false);
        doOnCalculateHistorico(rates_total, prev_calculated,time);
        setAsSeries(true);
    }

    //===============================================================================================
    // Processamento o tick da barra atual...
    //===============================================================================================
    //processando o evento atual...
    SymbolInfoTick  (_Symbol,m_tick);// um tick por chamada a oncalculate
    normalizar2trade(        m_tick);// soh normaliza se a opcao NORMALIZAR_TICK estiver ativa
    m_vet_vol.add   (        m_tick);// adicionando o tick ao vetor de volumes

    
    // plotando no grafico
// xi   eh a ocorrencia sendo monitorada (preco)
// T    eh o alvo. Normalmente a media
// K    eh o desvio minimo para que se acumule em uma das direcoes
// H    eh o limiar (alarme)
    //calcC( m_vet_vol.calc_desbalanceamento_com_peso() );
      calcC( m_vet_vol.get_desbalanceamento() );

      m_bufDesbMedio     [0] = m_cusum.getMedia();
      m_bufStrikeMais    [0] = + m_c_mais ; // log(m_c_mais ); //( (m_c_mais >1)?log(m_c_mais ):m_c_mais  );
      m_bufStrikeMenos   [0] = - m_c_menos; // log(m_c_menos); //( (m_c_menos>1)?log(m_c_menos):m_c_menos );

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
      //Print(__FUNCTION__, " ", qtdTicks, " copiados. Processando...");
      for(int ind=0; ind<qtdTicks; ind++){
         normalizar2trade(ticks[ind]);
         m_vet_vol.add   (ticks[ind]);
      
       //calcC(m_vet_vol.calc_desbalanceamento());
       //calcC(m_vet_vol.calc_desbalanceamento_com_peso());
         calcC(m_vet_vol.get_desbalanceamento() );

         m_bufDesbMedio    [i] = m_cusum.getMedia()  ;
         m_bufStrikeMais   [i] = 0   + m_c_mais      ; //log(m_c_mais ); // ( (m_c_mais >1)?log(m_c_mais ):m_c_mais  );
         m_bufStrikeMenos  [i] = 0   - m_c_menos     ; // log(m_c_menos); // ( (m_c_menos>1)?log(m_c_menos):m_c_menos );


         //===============================================================================================
         // Imprimindo dados de depuracao...
         //===============================================================================================
         //imprimirComment();
      }// final for processamento dos ticks

      // mudou a barra, entao verificamos se eh necessario alterar o tamanho dos vetores de acumulacao de medias...
      //m_minion.checkResize(0.3);

   }// final for do processamento das barras

   m_prochist = true; 
   Print( __FUNCTION__, " Historico processado :-)");
   Print( __FUNCTION__, " Tamanho do vetor de volume:", m_vet_vol.count() );

}//doOnCalculateHistorico.


//-- 
double m_c_mais  = 0;
double m_c_menos = 0;
double m_c_mais_ant  = 0;
double m_c_menos_ant = 0;
//-- 
// xi   eh a ocorrencia sendo monitorada (preco)
// T    eh o alvo. Normalmente a media
// K    eh o desvio minimo para que se acumule em uma das direcoes
// H    eh o limiar (alarme)

//void calcC(const double xi, const double T, const double K, const double H, bool& strikeHmais, bool& strikeHmenos, bool& strikeMais, bool& strikeMenos){
void calcC(double xi){

   //m_cusum.calcC(xi, T, K, H, strikeHmais, strikeHmenos, strikeMais, strikeMenos);
   if( xi == 0 ) return;
   
   m_cusum.add(xi);
   m_c_mais  = m_cusum.getCmais ();
   m_c_menos = m_cusum.getCmenos();
   //m_cusum.print();
}

string m_deslocamento = ""+
                  //    "                                                                   "+
                  //    "                                                                   "+
//                //    "                                                                   "+
                        "";
int m_qtdImpressao = 0;                        
void imprimirComment(){
  if(!APRESENTAR_COMMENT) return;
  // imprimir a cada 2 ticks...
  if( m_qtdImpressao++ < 2 ){ return; }
  m_qtdImpressao = 0;

  //===============================================================================================
  // Imprimindo dados de depuracao...
  //===============================================================================================
   m_comment =
     "\n" +m_deslocamento+"=== ASSIMETRIA DO MERCADO ====\n"     +
           m_deslocamento+"TICKSD:"+ TimeToString(m_vet_vol.dt_tick_mais_antigo(),TIME_MINUTES|TIME_SECONDS) + "\n" +
           m_deslocamento+"DESBAL INSTANT/MEDIO:"+DoubleToString(m_vet_vol.calc_desbalanceamento(),2)+ "/" +
                                                  DoubleToString(m_cusum.getMedia()               ,2)+ "\n"+
           m_deslocamento+"C+/H+ :"+DoubleToString(m_c_mais                        , 2)+ "/" +
                                    DoubleToString(m_strikeMais                    , 2)+ "/" +
                                    DoubleToString(m_strikeHmais                   , 2)+ "\n"+
           m_deslocamento+"C-/H- :"+DoubleToString(m_c_menos                       , 2)+ "/" +
                                    DoubleToString(m_strikeMenos                   , 2)+ "/" +
                                    DoubleToString(m_strikeHmenos                  , 2)+ "\n";

   Comment(       m_deslocamento+"TICK ===========================\n"+
                  m_comment+
           "\n" + m_deslocamento+"FIM ================================"  );
  //===============================================================================================
}

void setAsSeries(bool modo){
    ArraySetAsSeries(m_bufDesbMedio  , modo );
    ArraySetAsSeries(m_bufStrikeMais  , modo );
    ArraySetAsSeries(m_bufStrikeMenos , modo );
  //ArraySetAsSeries(m_bufStrikeHmais , modo );
  //ArraySetAsSeries(m_bufStrikeHmenos, modo );
}

void zerarBufAll(uint i){
   m_bufDesbMedio      [i] = 0;
   m_bufStrikeMais     [i] = 0;
   m_bufStrikeMenos    [i] = 0;
 //m_bufStrikeHmais    [i] = 0;
 //m_bufStrikeHmenos   [i] = 0;
}

void openLogFileTick(string arqLog){m_log_tick=FileOpen(arqLog, FILE_WRITE             );                      }
void flushLogTick()                 { if( DEBUG || DEBUG_TICK ){ FileFlush(m_log_tick                                   ); } }
void writeDetLogTick(string comment){ if( DEBUG || DEBUG_TICK ){ FileWrite(m_log_tick, m_tick_util.toStringCSV(comment) ); } } // escrevendo o log de ticks...

//+------------------------------------------------------------------+
