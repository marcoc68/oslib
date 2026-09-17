//+------------------------------------------------------------------+
//|                                         osi-03-14-myPair-006.mq5 |
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
//input string PAIR2                = "WDOJ21"; // segundo ativo do par. O primeiro é o do gráfico.
//input string PAIR2                = "GBPUSD"; // par do simbolo do grafico.
input int    PERIODOS_MEDIA           = 60   ; // quantidade de periodos para calcular a media do ratio.
input double MU_STD1                  = 1.0  ; // qtd desvios do primeiro desvio padrao.
input double MU_STD2                  = 2.0  ; // qtd desvios do segundo desvio padrao.
input double MU_STD3                  = 3.0  ; // qtd desvios do terceiro desvio padrao.


#define OSI_FEIRA_SHORT_NAME "osi-03-14-myPair-006"

#property description "Apresenta o ratio entre pares de ativos."

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   8

//---- plotar linha com aceleracao do volume liquida 
#property indicator_label1  "SPREAD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime //clrFireBrick
#property indicator_style1  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "MED"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "STD1+"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGoldenrod
#property indicator_style3  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "STD1-"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrGoldenrod
#property indicator_style4  STYLE_SOLID //STYLE_DASH    //STYLE_SOLID
#property indicator_width4  1

#property indicator_label5  "STD2+"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrMagenta
#property indicator_style5  STYLE_DASH //STYLE_DASH    //STYLE_SOLID
#property indicator_width5  1

#property indicator_label6  "STD2-"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrMagenta
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

   m_par.initialize ( PERIODOS_MEDIA*PeriodSeconds() );
   m_parH.initialize( PERIODOS_MEDIA                 );
   
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
    // obtendo ultimos dados de ticks...
    if( !SymbolInfoTick  ( _Symbol,m_tick ) ){Print("Erro obtendo preco ", _Symbol,"..."); return prev_calculated;}// um tick por chamada a oncalculate [bova11]
    if( !SymbolInfoTick  ( PAIR2,m_tick2  ) ){Print("Erro obtendo preco ", PAIR2  ,"..."); return prev_calculated;}// um tick por chamada a oncalculate [win...]
    normalizar2trade() ; // soh normaliza se GERAR_VOLUME for true
    
    //m_symb1.RefreshRates();
    //m_symb2.RefreshRates();
    //Comment(
    //    "m_symb1.Name:",m_symb1.Name()," m_symb1.Last:",m_symb1.Last()," m_tick1.last:",m_tick.last ,"\n",
    //    "m_symb2.Name:",m_symb2.Name()," m_symb2.Last:",m_symb2.Last()," m_tick2.last:",m_tick2.last,"\n"
    //);
    
    // atualizando o spread...
    double my_spread = log(m_tick.last) - log(m_tick2.last);
    //double my_spread = m_par.calcSpread(m_tick, m_tick2);
    
    
    if( rates_total != prev_calculated && !m_prochist){ 
        setAsSeries(false);
        // colocando o ultimo spread em todo o historico...
        MqlRates  rates_array[1];
        for( int i=prev_calculated; i<rates_total; i++ ){ 
            
            // 
            //if(i < rates_total - PERIODOS_MEDIA*2){continue;}
            Print("rates_tot:",rates_total," prev_calc:",prev_calculated, " i:", i, " dt:", time[i] );
            
            if(  CopyRates( 
                            PAIR2         ,  // nome do ativo 
                            PERIOD_CURRENT,  // período 
                            time[i]       ,  // data e hora de início 
                            1             ,  // quantidade de dados para copiar 
                            rates_array      // array destino para copiar 
                 ) > 0
            ){
                   m_buf_spread[i]= log(close[i])-log(rates_array[0].close);
                 //m_buf_spread[i]= m_parH.calcSpread(close[i],rates_array[0].close,rates_array[0].time);
            }else{
                  if( i>0 ){ 
                      m_buf_spread[i]= m_buf_spread[i-1];
                      Print("i:",i," Rate nao encontrado ao processar historico de ",PAIR2," para data:",time[i],". Usando rate anterior:",m_buf_spread[i-1]);
                  }
            }
            
            if( i>PERIODOS_MEDIA ){
              //setBuffersFromPar(i,m_parH);
                
                ArrayCopy(m_vetMoments,m_buf_spread,0,i-PERIODOS_MEDIA,PERIODOS_MEDIA);
                setBuffers(i);
                
                //ArrayCopy(m_vetMoments,m_buf_spread,0,i-PERIODOS_MEDIA,PERIODOS_MEDIA);
                //if( MathMoments(m_vetMoments,m_mmean,m_mvariance,m_mskewness,m_mkurtosis) ){
                //    m_mdp = MathSqrt(m_mvariance);
                //    m_buf_media   [i] = m_mmean;
                //    m_buf_std_pos1[i] = m_mmean+m_mdp*MU_STD1;
                //    m_buf_std_neg1[i] = m_mmean-m_mdp*MU_STD1;
                //    m_buf_std_pos2[i] = m_mmean+m_mdp*MU_STD2;
                //    m_buf_std_neg2[i] = m_mmean-m_mdp*MU_STD2;
                //    m_buf_std_pos3[i] = m_mmean+m_mdp*MU_STD3;
                //    m_buf_std_neg3[i] = m_mmean-m_mdp*MU_STD3;
                //}
            }
         }
         m_prochist=true;
    }
    
    //double my_spread = m_par.calcSpread(m_tick, m_tick2);
    setAsSeries(true);
    //m_buf_spread[0] = m_par.calcSpread(m_tick, m_tick2);
    //setBuffersFromPar(0,m_par);
    
    m_buf_spread[0] = my_spread;
    ArrayCopy(m_vetMoments,m_buf_spread,0,0,PERIODOS_MEDIA);
    setBuffers(0);
    
    //ArrayCopy(m_vetMoments,m_buf_spread,0,0,PERIODOS_MEDIA);
    //if( MathMoments(m_vetMoments,m_mmean,m_mvariance,m_mskewness,m_mkurtosis) ){
    //    m_mdp = MathSqrt(m_mvariance);
    //    m_buf_media   [0] = m_mmean;
    //    m_buf_std_pos1[0] = m_mmean+m_mdp*MU_STD1;
    //    m_buf_std_neg1[0] = m_mmean-m_mdp*MU_STD1;
    //    m_buf_std_pos2[0] = m_mmean+m_mdp*MU_STD2;
    //    m_buf_std_neg2[0] = m_mmean-m_mdp*MU_STD2;
    //    m_buf_std_pos3[0] = m_mmean+m_mdp*MU_STD3;
    //    m_buf_std_neg3[0] = m_mmean-m_mdp*MU_STD3;
    //}
    return(rates_total);
}

void setBuffersFromPar(int i, C00021Pairs& par){
        
        m_mdp   = par.getSpreadStd();
        m_mmean = par.getSpreadMed();
        
        //m_buf_spread  [i] = par.getSpread();
        m_buf_media   [i] = m_mmean;
        m_buf_std_pos1[i] = m_mmean+m_mdp*MU_STD1;
        m_buf_std_neg1[i] = m_mmean-m_mdp*MU_STD1;
        m_buf_std_pos2[i] = m_mmean+m_mdp*MU_STD2;
        m_buf_std_neg2[i] = m_mmean-m_mdp*MU_STD2;
        m_buf_std_pos3[i] = m_mmean+m_mdp*MU_STD3;
        m_buf_std_neg3[i] = m_mmean-m_mdp*MU_STD3;
}

void setBuffers(int i){
    if( MathMoments(m_vetMoments,m_mmean,m_mvariance,m_mskewness,m_mkurtosis) ){
        m_mdp = MathSqrt(m_mvariance);
        m_buf_media   [i] = m_mmean;
        m_buf_std_pos1[i] = m_mmean+m_mdp*MU_STD1;
        m_buf_std_neg1[i] = m_mmean-m_mdp*MU_STD1;
        m_buf_std_pos2[i] = m_mmean+m_mdp*MU_STD2;
        m_buf_std_neg2[i] = m_mmean-m_mdp*MU_STD2;
        m_buf_std_pos3[i] = m_mmean+m_mdp*MU_STD3;
        m_buf_std_neg3[i] = m_mmean-m_mdp*MU_STD3;
    }
}

/*
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
         zerarBufAll(p_prev_calculated); continue;
         //continue;
      }

      ///m_minion.fecharPeriodo(); // fechando o periodo anterior de coleta de estatisticas
      qtdTicks = CopyTicksRange( _Symbol          , //const string     symbol_name,          // nome do símbolo
                                 ticks            , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                 COPY_TICKS_ALL   , //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                 p_time[i-1]*1000 , //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                 p_time[i  ]*1000); //ulong            to_msc=0              // data ate a qual são solicitados os ticks

      for(int ind=0; ind<qtdTicks; ind++){

       //m_minion .addTick(ticks [ind]);
         //m_buf_media   [i] = 0;
         //m_buf_std_pos [i] = 0;
         //m_buf_std_neg [i] = 0;
         m_buf_spread  [i] = 0; //m_minion2.getPrecoMedTrade()/m_minion.getPrecoMedTrade();

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
*/

void setAsSeries(bool modo){
     ArraySetAsSeries(m_buf_media   , modo );
     ArraySetAsSeries(m_buf_spread  , modo );
     ArraySetAsSeries(m_buf_std_pos1, modo );
     ArraySetAsSeries(m_buf_std_neg1, modo );
     ArraySetAsSeries(m_buf_std_pos2, modo );
     ArraySetAsSeries(m_buf_std_neg2, modo );
     ArraySetAsSeries(m_buf_std_pos3, modo );
     ArraySetAsSeries(m_buf_std_neg3, modo );
}

//void zerarBufForca(uint i){
//   m_buf_media   [i] = 0;
//   m_buf_spread  [i] = 0;
//   m_buf_std_pos1[i] = 0;
//   m_buf_std_neg1[i] = 0;
//   m_buf_std_pos2[i] = 0;
//   m_buf_std_neg2[i] = 0;
//   m_buf_std_pos3[i] = 0;
//   m_buf_std_neg3[i] = 0;
//}

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

// transforma o tick informativo em tick de trade. Usamos em mercados que nao informam volume ou last nos ticks.
void normalizar2trade(){
   if(GERAR_VOLUME){
      //m_tick_util1.normalizar2trade(m_tick );
      //m_tick_util2.normalizar2trade(m_tick2);
      m_tick .last = m_tick .bid;
      m_tick2.last = m_tick2.bid;
   }
}

//+------------------------------------------------------------------+
