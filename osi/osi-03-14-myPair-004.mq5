//+------------------------------------------------------------------+
//|                                         osi-03-14-myPair-002.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//|                                                                  |
//|                                                                  |
//| Versao 2 usando C0002ArbitragemPar no lugar do calculo direto    |
//|          do ratio e de sua media.                                |
//|                                                                  |
//| Versao 3 usando cointegracao pra dar medida de possibilidade de  |
//|          execucao de long-short.                                 |
//|                                                                  |
//| Versao 4 calculando ratio simples, sem media.                    |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "3.013"

#include <Trade\SymbolInfo.mqh>
#include <Math\Stat\Math.mqh>
#include <oslib\osc\est\C00021Pairs.mqh>
#include <oslib\osc-tick-util.mqh>

//input int    QTD_BAR_PROC_HIST        = 0       ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input bool   GERAR_VOLUME           = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input string PAIR2                  = "EURUSD"; // segundo ativo do par. O primeiro é o do gráfico.
//input string PAIR2                = "GBPUSD"; // par do simbolo do grafico.
input uint   PERIODOS_MEDIA           = 60   ; // quantidade de periodos para calcular a media do ratio.
input double MU_STD1                  = 1.0  ; // qtd desvios do primeiro desvio padrao.
input double MU_STD2                  = 2.0  ; // qtd desvios do segundo desvio padrao.
input double MU_STD3                  = 3.0  ; // qtd desvios do terceiro desvio padrao.


#define OSI_FEIRA_SHORT_NAME "osi-03-14-myPair-004"

#property description "Apresenta o ratio entre pares de ativos."

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   8

//---- plotar linha com aceleracao do volume liquida 
#property indicator_label1  "SPREAD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime //clrFireBrick
#property indicator_style1  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "MED"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "STD1+"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "STD1-"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRed
#property indicator_style4  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width4  1

#property indicator_label5  "STD2+"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrRed
#property indicator_style5  STYLE_DASH //STYLE_DASH    //STYLE_SOLID
#property indicator_width5  1

#property indicator_label6  "STD2-"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrRed
#property indicator_style6  STYLE_DASH //STYLE_DASH    //STYLE_SOLID
#property indicator_width6  1

#property indicator_label7  "STD3+"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrRed
#property indicator_style7  STYLE_DASH //STYLE_DASH    //STYLE_SOLID
#property indicator_width7  1

#property indicator_label8  "STD3-"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrRed
#property indicator_style8  STYLE_DASH //STYLE_DASH    //STYLE_SOLID
#property indicator_width8  1


//--- buffers do indicador
  double m_buf_spread        []; // ratio atual                                    :1
  double m_buf_media         []; // media do ratio nos ultimos xx periodos         :2
  double m_buf_std_pos1      []; // variancia positiva do ratio medio              :3
  double m_buf_std_neg1      []; // variancia negativa do ratio medio              :4
  double m_buf_std_pos2      []; // variancia positiva do ratio medio              :5
  double m_buf_std_neg2      []; // variancia negativa do ratio medio              :6
  double m_buf_std_pos3      []; // variancia positiva do ratio medio              :7
  double m_buf_std_neg3      []; // variancia negativa do ratio medio              :8

// variaveis para controle dos ticks
CSymbolInfo     m_symb1     ;
CSymbolInfo     m_symb2     ;
bool            m_prochist  ; // para nao reprocessar o historico sempre que mudar de barra;
C00021Pairs     m_par       ; // processando os dados atuais, por ticks
C00021Pairs     m_parH      ; // para processar o historico (por rate)
osc_tick_util   m_tick_util1; // para simular ticks de trade em bolsas que nao informam last/volume.
osc_tick_util   m_tick_util2; // para simular ticks de trade em bolsas que nao informam last/volume.

// apresentacao de depuracao
string m_tick_txt    ;

//+------------------------------------------------------------------+
//| Função de inicialização do indicador customizado                 |
//+------------------------------------------------------------------+
int OnInit() {
   Print("Definindo buffers do indicador...");
   SetIndexBuffer( 0,m_buf_spread  , INDICATOR_DATA  ); 
   SetIndexBuffer( 1,m_buf_media   , INDICATOR_DATA  ); 
   SetIndexBuffer( 2,m_buf_std_pos1, INDICATOR_DATA  ); 
   SetIndexBuffer( 3,m_buf_std_neg1, INDICATOR_DATA  ); 
   SetIndexBuffer( 4,m_buf_std_pos2, INDICATOR_DATA  ); 
   SetIndexBuffer( 5,m_buf_std_neg2, INDICATOR_DATA  ); 
   SetIndexBuffer( 6,m_buf_std_pos3, INDICATOR_DATA  ); 
   SetIndexBuffer( 7,m_buf_std_neg3, INDICATOR_DATA  ); 


//--- Definir um valor vazio
   PlotIndexSetDouble( 0 ,PLOT_EMPTY_VALUE,0); // m_buf_spread     
   PlotIndexSetDouble( 1 ,PLOT_EMPTY_VALUE,0); // m_buf_media     
   PlotIndexSetDouble( 2 ,PLOT_EMPTY_VALUE,0); // m_buf_std_pos1     
   PlotIndexSetDouble( 3 ,PLOT_EMPTY_VALUE,0); // m_buf_std_neg1     
   PlotIndexSetDouble( 4 ,PLOT_EMPTY_VALUE,0); // m_buf_std_pos2
   PlotIndexSetDouble( 5 ,PLOT_EMPTY_VALUE,0); // m_buf_std_neg2     
   PlotIndexSetDouble( 6 ,PLOT_EMPTY_VALUE,0); // m_buf_std_pos3
   PlotIndexSetDouble( 7 ,PLOT_EMPTY_VALUE,0); // m_buf_std_neg3     

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,
                      OSI_FEIRA_SHORT_NAME+"("+IntegerToString(PERIODOS_MEDIA)+","+
                                                               PAIR2          +","+
                                                               DoubleToString(MU_STD1,1)     +","+
                                                               DoubleToString(MU_STD2,1)     +","+
                                                               DoubleToString(MU_STD3,1)     +")");
   
   IndicatorSetInteger(INDICATOR_DIGITS,4);
   
   m_symb1.Name        ( Symbol() );
   m_symb1.Refresh     ();
   m_symb1.RefreshRates();

   m_symb2.Name        ( PAIR2 );
   m_symb2.Refresh     ();
   m_symb2.RefreshRates();
   
   m_tick_util1.setTickSize( m_symb1.TickSize(), m_symb1.Digits() );
   m_tick_util2.setTickSize( m_symb2.TickSize(), m_symb2.Digits() );

   m_par.initialize ( PERIODOS_MEDIA, PERIOD_CURRENT );
   m_parH.initialize( PERIODOS_MEDIA, PERIOD_CURRENT );
   
   m_prochist = false; // indica se deve reprocessar o historico.
   setAsSeries(true);
   Print("ESTA EH VERSAO COMPILADA EM: ",__DATETIME__);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int i){
  MarketBookRelease( m_symb1.Name() );
  MarketBookRelease( m_symb2.Name() );
  delete(&m_symb1  );
  delete(&m_symb2 );
}

//+------------------------------------------------------------------+
//| Atualizando os volumes de bid e oferta                           |
//+------------------------------------------------------------------+
MqlTick     m_tick,m_tick2;
double      m_vetMoments[],m_mmean,m_mvariance,m_mskewness,m_mkurtosis, m_mdp;
MqlDateTime m_dt;
int OnCalculate(const int        rates_total,
                const int        prev_calculated,
                const datetime&  time [],
                const double&    open [],
                const double&    high [],
                const double&    low  [],
                const double&    close[],
                const long&      tick_volume[],
                const long&      volume[]     ,
                const int&       spread[]     ) {

    //===============================================================================================
    // Processando o hitorico...
    //===============================================================================================
    //if(!m_prochist){ // para nao reprocessar a ultima barra sempre que mudar de barra.
    //    setAsSeries(false);
    //    doOnCalculateHistorico(rates_total, prev_calculated,time);
    //    setAsSeries(true);
    //}

    //===============================================================================================
    // Processamento o tick da barra atual...
    //===============================================================================================
    if( rates_total != prev_calculated && !m_prochist){
        setAsSeries(false);
        // colocando o ultimo spread em todo o historico...
        MqlRates  rates_array[1];
        for( uint i=prev_calculated; i<(uint)rates_total; i++ ){

            if(  CopyRates(
                            PAIR2         ,  // nome do ativo
                            PERIOD_CURRENT,  // período
                            time[i]       ,  // data e hora de início
                            1             ,  // quantidade de dados para copiar
                            rates_array      // array destino para copiar
                 ) > 0
            ){
                Print("rates_tot:",rates_total," prev_calc:",prev_calculated, " i:", i, " dt:", time[i] );
                m_buf_spread[i]= m_parH.calcSpread(close[i],rates_array[0].close,rates_array[0].time);
            }else{
                 if( i>0 ){
                     m_buf_spread[i]= m_buf_spread[i-1];
                     Print("i:",i," Rate nao encontrado ao processar historico de ",PAIR2," para data:",time[i],". Usando rate anterior:",m_buf_spread[i-1]);
                 }
            }

            if( i>PERIODOS_MEDIA ){
                setBuffersFromPar(i,m_parH);
            }
         }
         m_prochist=true;
    }
    
    // obtendo ultimos dados de ticks...
    if( !SymbolInfoTick  ( _Symbol,m_tick ) ){Print("Erro obtendo preco ", _Symbol,"..."); return prev_calculated;}// um tick por chamada a oncalculate [bova11]
    if( !SymbolInfoTick  ( PAIR2,m_tick2  ) ){Print("Erro obtendo preco ", PAIR2  ,"..."); return prev_calculated;}// um tick por chamada a oncalculate [win...]
    
//    m_symb1.RefreshRates();
//    m_symb2.RefreshRates();
//    Comment(
//        "m_symb1.Name:",m_symb1.Name()," m_symb1.Last:",m_symb1.Last()," m_tick1.last:",m_tick.last ," m_tick1.last:",m_tick.last ,"\n",
//        "m_symb2.Name:",m_symb2.Name()," m_symb2.Last:",m_symb2.Last()," m_tick2.last:",m_tick2.last," m_tick1.last:",m_tick2.last ,"\n",
//        "-----------------------\n",
//        "m_symb1.Name:",m_symb1.Name()," m_symb1.Time:",m_symb1.Time()," m_tick1.time:",m_tick.time ,"\n",
//        "m_symb2.Name:",m_symb2.Name()," m_symb2.Time:",m_symb2.Time()," m_tick2.time:",m_tick2.time,"\n",
//        "-----------------------\n",
//        "m_symb1.Name:",m_symb1.Name()," m_symb1.Bid:",m_symb1.Bid()," m_tick1.bid:",m_tick.bid ,"\n",
//        "m_symb2.Name:",m_symb2.Name()," m_symb2.Bid:",m_symb2.Bid()," m_tick2.bid:",m_tick2.bid,"\n"
//    );
    
    //double my_spread = m_par.calcSpread(m_tick, m_tick2);
//    setAsSeries(true);
//    Print("Apos historico ra8133tes_tot:",rates_total," prev_calc:",prev_calculated, " dt:", time[rates_total-1], " dt0:", time[0] );
    m_buf_spread[0] = m_parH.calcSpread(m_tick, m_tick2);
    
    setBuffersFromPar(0,m_parH);
    return(rates_total);
}

void setBuffersFromPar(int i, C00021Pairs& par){
       if(i<0){
          Print(__FUNCTION__, ":Indice invalido:", i);
          return;
       }
        
        m_mdp   = par.getSpreadStd();
        m_mmean = par.getSpreadMed();
        
        m_buf_spread  [i] = par.getSpread();
        m_buf_media   [i] = m_mmean;
        m_buf_std_pos1[i] = m_mmean+m_mdp*MU_STD1;
        m_buf_std_neg1[i] = m_mmean-m_mdp*MU_STD1;
        m_buf_std_pos2[i] = m_mmean+m_mdp*MU_STD2;
        m_buf_std_neg2[i] = m_mmean-m_mdp*MU_STD2;
        m_buf_std_pos3[i] = m_mmean+m_mdp*MU_STD3;
        m_buf_std_neg3[i] = m_mmean-m_mdp*MU_STD3;
}

int getIndiceTime(const datetime& p_times[], const datetime p_time){
  int len = ArraySize(p_times);
  for(int i=1; i<len; i++){
     if( p_time>p_times[i-1] && p_time<=p_times[i]) return i;
  }
  return -1;
}
//===============================================================================================
// Processando o historico de ticks no oncalculate...
//===============================================================================================
void doOnCalculateHistorico(const int        p_rates_total    ,
                            const int        p_prev_calculated,
                            const datetime&  p_times[]        ){
   MqlTick ticks1[], ticks2[];
   m_par.initialize ( PERIODOS_MEDIA, PERIOD_CURRENT );
   m_parH.initialize( PERIODOS_MEDIA, PERIOD_CURRENT );
   zerarBufAll(p_prev_calculated);
   //inicializarPairTrading();

   uint ind_ini_historico = p_rates_total - PERIODOS_MEDIA*2;

   Print(__FUNCTION__, " p_rates_total:",p_rates_total," PERIODOS_MEDIA:", PERIODOS_MEDIA, " ind_ini_historico:",ind_ini_historico);
   Print(__FUNCTION__, " p_times[ind_ini_historico]     :",p_times[ind_ini_historico]     );
   Print(__FUNCTION__, " p_times[ind_ini_historico]*1000:",p_times[ind_ini_historico]*1000);

   int qtdTicks1 = CopyTicksRange( _Symbol                     , //const string symbol_name,          // nome do símbolo
                                   ticks1                      , //MqlTick&     ticks_array[],        // matriz para recebimento de ticks
                                   COPY_TICKS_ALL              , //uint         flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                   p_times[ind_ini_historico]*1000 ); //ulong        from_msc=0,           // data a partir da qual são solicitados os ticks
   int qtdTicks2 = CopyTicksRange( PAIR2                       , //const string symbol_name,          // nome do símbolo
                                   ticks2                      , //MqlTick&     ticks_array[],        // matriz para recebimento de ticks
                                   COPY_TICKS_ALL              , //uint         flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                   p_times[ind_ini_historico]*1000 ); //ulong        from_msc=0,           // data a partir da qual são solicitados os ticks

   Print(__FUNCTION__, " qtdTicks1:", qtdTicks1, " qtdTicks2:", qtdTicks2, " primData:", p_times[ind_ini_historico], " ultData:", p_times[p_rates_total-1]);
   Print(__FUNCTION__, " primData ticks1:", ticks1[0          ].time, " primData ticks2:", ticks2[0          ].time);
   Print(__FUNCTION__, " ultData  ticks1:", ticks1[qtdTicks1-1].time, " ultData  ticks2:", ticks2[qtdTicks2-1].time);
   int posicao_ind2 = 0;
   for(int ind1=0; ind1<qtdTicks1; ind1++){
      Print(__FUNCTION__, " posicao_ind2:", posicao_ind2);
      Print(__FUNCTION__, " ticks1[",ind1,"]:", m_tick_util1.toString(ticks1[ind1],2));
      for(int ind2=posicao_ind2; ind2<qtdTicks2 && ticks2[ind2].time<=ticks1[ind1].time; ind2++){

         Print(__FUNCTION__, " ticks2[",ind2,"]:", m_tick_util1.toString(ticks2[ind2],2));
         m_par.calcSpread(ticks1[ind1],ticks2[ind2]);
         
         posicao_ind2++;
         return;
      }
      setBuffersFromPar(getIndiceTime(p_times, ticks1[ind1].time), m_par);
   }
   m_prochist = true; Print( "Historico processado :-)" );
}//doOnCalculateHistorico.

void setAsSeries(bool modo){
     Print(__FUNCTION__, " ", modo);
     ArraySetAsSeries(m_buf_media   , modo );
     ArraySetAsSeries(m_buf_spread  , modo );
     ArraySetAsSeries(m_buf_std_pos1, modo );
     ArraySetAsSeries(m_buf_std_neg1, modo );
     ArraySetAsSeries(m_buf_std_pos2, modo );
     ArraySetAsSeries(m_buf_std_neg2, modo );
     ArraySetAsSeries(m_buf_std_pos3, modo );
     ArraySetAsSeries(m_buf_std_neg3, modo );
}

void zerarBufAll(uint i){
   m_buf_media   [i] = 0;
   m_buf_spread  [i] = 0;
   m_buf_std_pos1[i] = 0;
   m_buf_std_neg1[i] = 0;
   m_buf_std_pos2[i] = 0;
   m_buf_std_neg2[i] = 0;
   m_buf_std_pos3[i] = 0;
   m_buf_std_neg3[i] = 0;
}
//+------------------------------------------------------------------+
