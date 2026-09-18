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

#include <Math\Stat\Math.mqh>

//input int    QTD_BAR_PROC_HIST        = 0       ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
//input string PAIR2                  = "WDOJ21"; // segundo ativo do par. O primeiro é o do gráfico.
//input string PAIR2                  = "GBPUSD"; // par do simbolo do grafico.
input string PAIR2                    = "EURUSD"; // segundo ativo do par. O primeiro é o do gráfico.
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
bool            m_prochist  ; // para nao reprocessar o historico sempre que mudar de barra;

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
   
   m_prochist = false; // indica se deve reprocessar o historico.
   setAsSeries(true);
   Print("ESTA EH VERSAO COMPILADA EM: ",__DATETIME__);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int i){
}

//+------------------------------------------------------------------+
//| Atualizando os volumes de bid e oferta                           |
//+------------------------------------------------------------------+
double      m_vetMoments[],m_mmean,m_mvariance,m_mskewness,m_mkurtosis, m_mdp;
MqlRates    m_rates_array1[1],m_rates_array2[1];
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
    // Processamento do historico...
    //===============================================================================================
    if( rates_total != prev_calculated && !m_prochist){
        setAsSeries(false);
        // colocando o ultimo spread em todo o historico...
        double close2 = 0;
        for( int i=prev_calculated; i<rates_total; i++ ){
            
            if(i < rates_total - PERIODOS_MEDIA*6){continue;}
            Print("rates_tot:",rates_total," prev_calc:",prev_calculated, " i:", i, " dt:", time[i] );

            close2 = getClose(PAIR2, time[i]);
            if( close2 > 0 ){
                m_buf_spread[i] = log(close[i])-log(close2);
            }else{
                if( i>0 ){
                    m_buf_spread[i]= m_buf_spread[i-1];
                    Print("i:",i," Rate nao encontrado ao processar historico de ",PAIR2," para data:",time[i],". Usando rate anterior:",m_buf_spread[i-1]);
                }
            }
            
            if( i>PERIODOS_MEDIA ){
                ArrayCopy(m_vetMoments,m_buf_spread,0,i-PERIODOS_MEDIA,PERIODOS_MEDIA);
                setBuffers(i);
            }
         }
         m_prochist=true;
         Print(__FUNCTION__, " Historico processado :-)");
    }
    
    //===============================================================================================
    // Processamento do tick da barra atual...
    //===============================================================================================
    double my_spread = log(getClose(_Symbol)) - log(getClose(PAIR2));
    setAsSeries(true);
    m_buf_spread[0] = my_spread;
    ArrayCopy(m_vetMoments,m_buf_spread,0,0,PERIODOS_MEDIA);
    setBuffers(0);
    return(rates_total);
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

double getClose(string symbol){
   MqlRates rates_array[1];
   if(CopyRates( symbol        , // nome do ativo
                 PERIOD_CURRENT, // período
                 0             , // posição de início
                 1             , // quantidade de dados para copiar
                 rates_array     // array destino para copiar
                ) > 0
      ) return rates_array[0].close;
   return -1;
}

double getClose(string symbol, datetime dt){
    MqlRates rates_array[1];
    if(CopyRates( symbol        ,  // nome do ativo
                  PERIOD_CURRENT,  // período
                  dt            ,  // data e hora de início
                  1             ,  // quantidade de dados para copiar
                  rates_array      // array destino para copiar
         ) > 0
      ) return rates_array[0].close;
   return -1;
}
//+------------------------------------------------------------------+
