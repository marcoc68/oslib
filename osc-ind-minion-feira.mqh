//+------------------------------------------------------------------+
//|                                          ClassMinionIndFeira.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.307"

#include <Indicators\Custom.mqh>

#define IFEIRA_NAME_0103             "Shared Projects\\oslib\\osi\\osi-teste-01-03-feira"
#define IFEIRA_NAME_0104             "Shared Projects\\oslib\\osi\\osi-teste-01-04-feira"
#define IFEIRA_NAME_0202             "Shared Projects\\oslib\\osi\\osi-teste-02-02-feira"
#define IFEIRA_NAME_0203             "Shared Projects\\oslib\\osi\\osi-teste-02-03-feira"
#define IFEIRA_NAME_0204             "Shared Projects\\oslib\\osi\\osi-teste-02-04-feira" // passa a sinalizar ponto de comprometimento institucional. Deixa de sinalizar as tendencias de alta e baixa.
#define IFEIRA_NAME_0205             "Shared Projects\\oslib\\osi\\osi-teste-02-05-feira" // passa a informar maior e menor precos negociados no periodo. Deixa de sinalizar forca do preco abaixo e acima.
#define IFEIRA_NAME_0206             "Shared Projects\\oslib\\osi\\osi-teste-02-06-feira" // passa a informar o volume de trades.
#define IFEIRA_NAME_0306             "Shared Projects\\oslib\\osi\\osi-teste-03-06-feira" // passa a informar o volume de trades.
#define IFEIRA_NAME_0307             "Shared Projects\\oslib\\osi\\osi-teste-03-07-feira" // passa a informar o volume de compras e vendas, receber periodo em segundos e adiciona parametro para escrever sql no log.
#define IFEIRA_VERSAO_0103           "V0103"
#define IFEIRA_VERSAO_0104           "V0104"
#define IFEIRA_VERSAO_0202           "V0202"
#define IFEIRA_VERSAO_0203           "V0203"
#define IFEIRA_VERSAO_0204           "V0204"
#define IFEIRA_VERSAO_0205           "V0205"
#define IFEIRA_VERSAO_0206           "V0206"
#define IFEIRA_VERSAO_0306           "V0306"
#define IFEIRA_VERSAO_0307           "V0307"
#define IFEIRA_VERSAO_DEFAULT        "V0307"
#define IFEIRA_QTD_BUFFERS           30
#define IFEIRA_QTD_PARAM             8
// #define IFEIRA_BUF_PRECO_MED_SEL      0
// #define IFEIRA_BUF_PRECO_MED_BUY      1
// #define IFEIRA_BUF_PRECO_MED_ASK      2
// #define IFEIRA_BUF_PRECO_MED_BID      3
// #define IFEIRA_BUF_SINAL_OFERTA_ASK   4
// #define IFEIRA_BUF_SINAL_OFERTA_BID   5
// #define IFEIRA_BUF_SINAL_DEMANDA_BUY  6 // descontinuado a partir da versao 0205
// #define IFEIRA_BUF_SINAL_DEMANDA_SEL  7 // descontinuado a partir da versao 0205
// #define IFEIRA_BUF_PRECO_HIGH         6 //               a partir da versao 0205
// #define IFEIRA_BUF_PRECO_LOW          7 //               a partir da versao 0205
// #define IFEIRA_BUF_SINAL_PRECO_UP1    8
// #define IFEIRA_BUF_SINAL_PRECO_UP2    9
// #define IFEIRA_BUF_SINAL_PRECO_DW1    10
// #define IFEIRA_BUF_SINAL_PRECO_DW2    11
// #define IFEIRA_BUF_PRECO_MED_TRA      12 // preco medio do trade  . Disponivel a partir da versao "0202"
// #define IFEIRA_BUF_PRECO_MED_BOK      13 // preco medio de afertas. Disponivel a partir da versao "0202"
// #define IFEIRA_BUF_SINAL_COMPINST_UP  14 // Comprometimento institucional para cima.  Disponivel a partir da versao "0204" Substitui o sinal de tendencia de alta  disponivel a partir da versao "0202"
// #define IFEIRA_BUF_SINAL_COMPINST_DW  15 // Comprometimento institucional para baixo. Disponivel a partir da versao "0204" Substitui o sinal de tendencia de baixa disponivel a partir da versao "0202"
// #define IFEIRA_BUF_SINAL_INCL_UP      16 // Inclinacao de alta.  Disponivel a partir da versao "0204". Substitui o sinal de reversao de alta  que estava disponivel a partir da versao "0202"
// #define IFEIRA_BUF_SINAL_INCL_DW      17 // Inclinacao de baixa. Disponivel a partir da versao "0204". Substitui o sinal de reversao de baixa que estava disponivel a partir da versao "0202"

// ANTIGO ////////////////////////////////////////////////////////////////////////////////////////////////////
// #define IFEIRA_BUF_SINAL_COMPINST_UP  14 // tendencia de alta . Disponivel a partir da versao "0202"
// #define IFEIRA_BUF_SINAL_COMPINST_DW  15 // tendencia de baixa. Disponivel a partir da versao "0202"
// #define IFEIRA_BUF_SINAL_INCL_UP      16 // Reversao com alta . tendencia era pra baixo. Disponivel a partir da versao "0202"
// #define IFEIRA_BUF_SINAL_INCL_DW      17 // Reversao com baixa. tendencia era pra cima . Disponivel a partir da versao "0202"
// NOVO ////////////////////////////////////////////////////////////////////////////////////////////////////

enum ifeiraBuf{
    IFEIRA_BUF_PRECO_MED_SEL     = 0 ,
    IFEIRA_BUF_PRECO_MED_BUY     = 1 ,
    IFEIRA_BUF_PRECO_MED_ASK     = 2 ,
    IFEIRA_BUF_PRECO_MED_BID     = 3 ,
    IFEIRA_BUF_SINAL_OFERTA_ASK  = 4 ,
    IFEIRA_BUF_SINAL_OFERTA_BID  = 5 ,
    IFEIRA_BUF_PRECO_HIGH        = 6 ,
    IFEIRA_BUF_PRECO_LOW         = 7 ,
    IFEIRA_BUF_SINAL_PRECO_UP1   = 8 ,
    IFEIRA_BUF_SINAL_PRECO_UP2   = 9 ,
    IFEIRA_BUF_SINAL_PRECO_DW1   = 10,
    IFEIRA_BUF_SINAL_PRECO_DW2   = 11,
    IFEIRA_BUF_PRECO_MED_TRA     = 12, // preco medio do trade  . Disponivel a partir da versao "0202"
    IFEIRA_BUF_PRECO_MED_BOK     = 13, // preco medio de afertas. Disponivel a partir da versao "0202"

    // inicio: substituicoes do significado do indicador
    IFEIRA_BUF_SINAL_COMPINST_UP = 14, // comprometimento institucional para cima.  Disponivel a partir da versao "0204" Substitui o sinal de tendencia de alta  disponivel a partir da versao "0202"
    IFEIRA_BUF_SINAL_COMPINST_DW = 15, // comprometimento institucional para baixo. Disponivel a partir da versao "0204" Substitui o sinal de tendencia de baixa disponivel a partir da versao "0202"
    IFEIRA_BUF_SINAL_INCL_UP     = 16, // Inclinacao de alta.  Disponivel a partir da versao "0204". Substitui o sinal de reversao de alta  que estava disponivel a partir da versao "0202"
    IFEIRA_BUF_SINAL_INCL_DW     = 17, // Inclinacao de baixa. Disponivel a partir da versao "0204". Substitui o sinal de reversao de baixa que estava disponivel a partir da versao "0202"
    // final: substituicoes do significado do indicador

  //IFEIRA_BUF_TENDENCIA         = 18, // Positivo significa tendencia para acima, negativo eh tendencia para baixo.                                    // descontinuado na versao 03-06
  //IFEIRA_BUF_REVERSAO          = 19, // Igual ao de tendencia, mas em periodo de tempo mais curto. Normalmente 25% da tendencia (falta parametrizar)  // descontinuado na versao 03-06
    IFEIRA_BUF_DESB_UP0          = 18, // Desbalanceamento na primeira fila do book.
    IFEIRA_BUF_DESB_UP1          = 19, // Desbalanceamento na segunda  fila do book.
    IFEIRA_BUF_INCLINACAO_SEL    = 20, // Inclinacao do preco  medio de venda . Disponivel a partir da versao "0203".
    IFEIRA_BUF_INCLINACAO_BUY    = 21, // Inclinacao do preco  medio de compra. Disponivel a partir da versao "0203".
    IFEIRA_BUF_INCLINACAO_TRA    = 22, // Inclinacao do preco  medio    geral . Disponivel a partir da versao "0203".
    IFEIRA_BUF_INCLINACAO_ASK    = 23, // Inclinacao da oferta media de venda . Disponivel a partir da versao "0203".
    IFEIRA_BUF_INCLINACAO_BID    = 24, // Inclinacao da oferta media de compra. Disponivel a partir da versao "0203".
    IFEIRA_BUF_INCLINACAO_BOK    = 25, // Inclinacao da oferta media    geral . Disponivel a partir da versao "0203".
    IFEIRA_BUF_VOLUMETRADE       = 26, // Volume     de trades totais         . Disponivel a partir da versao "0206".
    IFEIRA_BUF_VOLUMETRADE_BUY   = 27, // Volume     de trades de compra      . Disponivel a partir da versao "0207".
    IFEIRA_BUF_VOLUMETRADE_SEL   = 28  // Volume     de trades de venda       . Disponivel a partir da versao "0207".
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class osc_ind_minion_feira : public CiCustom {
private:
   int    m_feira;
   string m_feira_name;
   int    m_feira_qtd_buffers;

public:
   osc_ind_minion_feira();
  ~osc_ind_minion_feira();

   bool Create ( const string          symbol             ,
                 const ENUM_TIMEFRAMES period             ,
                 const bool            debug01            ,
                 const bool            gerarVolume02      ,
                 const bool            gerarOfertas03     ,
                 const int             qtdBarProcHist04   ,
                 const double          bookOut05          ,
                 const int             qtdPeriodo06       , // quantidade de periodos que serao usados no calculo das medias, a partir da versao 0307, passa a ser a quantide de segundos do periodo
                 const bool            gerarSqlLog07=false, // a partir da versao 0307: define se gera ou nao sql no log.
                 const string          versao=IFEIRA_VERSAO_DEFAULT   );

   // preco medio
   double getPrecoMedioTra  (int i){return CiCustom::GetData(IFEIRA_BUF_PRECO_MED_TRA,i);}//12,
   double getPrecoMedioSel  (int i){return CiCustom::GetData(IFEIRA_BUF_PRECO_MED_SEL,i);}//0,m_bufPsel      , INDICATOR_DATA  );
   double getPrecoMedioBuy  (int i){return CiCustom::GetData(IFEIRA_BUF_PRECO_MED_BUY,i);}//1,m_bufPbuy      , INDICATOR_DATA  );
   double getPrecoMedioBok  (int i){return CiCustom::GetData(IFEIRA_BUF_PRECO_MED_BOK,i);}//13,
   double getPrecoMedioAsk  (int i){return CiCustom::GetData(IFEIRA_BUF_PRECO_MED_ASK,i);}//2,m_bufPask      , INDICATOR_DATA  );
   double getPrecoMedioBid  (int i){return CiCustom::GetData(IFEIRA_BUF_PRECO_MED_BID,i);}//3,m_bufPbid      , INDICATOR_DATA  );

   // inclinacao dos precos medios do book e de trade
   double getInclinacaoSel  (int i){return CiCustom::GetData(IFEIRA_BUF_INCLINACAO_SEL,i);}//20,m_bufInclSel  , INDICATOR_DATA
   double getInclinacaoBuy  (int i){return CiCustom::GetData(IFEIRA_BUF_INCLINACAO_BUY,i);}//21,m_bufInclBuy  , INDICATOR_DATA
   double getInclinacaoTra  (int i){return CiCustom::GetData(IFEIRA_BUF_INCLINACAO_TRA,i);}//22,m_bufInclTra  , INDICATOR_DATA
   double getInclinacaoAsk  (int i){return CiCustom::GetData(IFEIRA_BUF_INCLINACAO_ASK,i);}//23,m_bufInclAsk  , INDICATOR_DATA
   double getInclinacaoBid  (int i){return CiCustom::GetData(IFEIRA_BUF_INCLINACAO_BID,i);}//24,m_bufInclBid  , INDICATOR_DATA
   double getInclinacaoBok  (int i){return CiCustom::GetData(IFEIRA_BUF_INCLINACAO_BOK,i);}//25,m_bufInclBok  , INDICATOR_DATA

   // forca de de oferta e demanda
   double getSinalOfertaAsk (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_OFERTA_ASK ,i);}//4,m_bufPaskArrow , INDICATOR_DATA  );
   double getSinalOfertaBid (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_OFERTA_BID ,i);}//5,m_bufPbidArrow , INDICATOR_DATA  );

   // precos no ultimo periodo
   double getPrecoHigh      (int i){return CiCustom::GetData(IFEIRA_BUF_PRECO_HIGH       ,i);}//6,m_bufPHigArrow , INDICATOR_DATA  );
   double getPrecoLow       (int i){return CiCustom::GetData(IFEIRA_BUF_PRECO_LOW        ,i);}//7,m_bufPLowArrow , INDICATOR_DATA  );

   // sinais de compra ou venda em funcao da forca de oferta e demanda
   double getSinalPrecoUp1  (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_PRECO_UP1,i);}//8 ,m_bufPup1Arrow, INDICATOR_DATA  );
   double getSinalPrecoUp2  (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_PRECO_UP2,i);}//9 ,m_bufPup2Arrow, INDICATOR_DATA  );
   double getSinalPrecoDw1  (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_PRECO_DW1,i);}//10,m_bufPdw1Arrow, INDICATOR_DATA  );
   double getSinalPrecoDw2  (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_PRECO_DW2,i);}//11,m_bufPdw2Arrow, INDICATOR_DATA  );

   // sinais de tendencia e reversao
   //double getSinalTendUp  (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_COMPINST_UP,i);}//14 , comprometimento institucional para cima
   //double getSinalTendDw  (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_COMPINST_DW,i);}//15 , comprometimento institucional para baixo
   //double getSinalRevrUp  (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_INCL_UP    ,i);}//16 , inclinacao para cima
   //double getSinalRevrDw  (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_INCL_DW    ,i);}//17 , inclinacao para baixo

   // sinais de inclinacao e comprometimento institucional
   double getSinalCompromissoUp(int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_COMPINST_UP,i);}//14 , comprometimento institucional para cima
   double getSinalCompromissoDw(int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_COMPINST_DW,i);}//15 , comprometimento institucional para baixo
   double getSinalInclinacaoUp (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_INCL_UP    ,i);}//16 , inclinacao para cima
   double getSinalInclinacaoDw (int i){return CiCustom::GetData(IFEIRA_BUF_SINAL_INCL_DW    ,i);}//17 , inclinacao para baixo

   // forca da tendencia e reversao
 //double getTendencia  (int i){return CiCustom::GetData(IFEIRA_BUF_TENDENCIA,i);}//18 , forca da tendencia em ticks // descontinuado na versao 03-06
 //double getReversao   (int i){return CiCustom::GetData(IFEIRA_BUF_REVERSAO ,i);}//19 , forca da reversao em ticks  // descontinuado na versao 03-06

   // forca da tendencia e reversao
   double getDesbUP0(int i){return CiCustom::GetData(IFEIRA_BUF_DESB_UP0,i);}//18 , desbalanceamento na primeira fila do book (preco deve subir). Subtraia 1 para encontrar o desbalanceamento DW.
   double getDesbUP1(int i){return CiCustom::GetData(IFEIRA_BUF_DESB_UP1,i);}//19 , desbalanceamento na segunda  fila do book (preco deve subir). subtraia 1 para encontrar o desbalanceamento DW.

   //double getDemandaMedia(){ return ( getPrecoMedioSel(0) + getPrecoMedioBuy(0) ) / 2.0; }
   //double getOfertaMedia() { return ( getPrecoMedioAsk(0) + getPrecoMedioBid(0) ) / 2.0; }
   
   double getVolTrade   (int i) {return CiCustom::GetData(IFEIRA_BUF_VOLUMETRADE     ,i);}//26 , volume total dos trades           no periodo. // a partir da versao 0307.
   double getVolTradeBuy(int i) {return CiCustom::GetData(IFEIRA_BUF_VOLUMETRADE_BUY ,i);}//27 , volume       dos trades de compra no periodo. // a partir da versao 0307.
   double getVolTradeSel(int i) {return CiCustom::GetData(IFEIRA_BUF_VOLUMETRADE_SEL ,i);}//28 , volume       dos trades de venda  no periodo. // a partir da versao 0307.
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool osc_ind_minion_feira::Create( const string          symbol             ,
                                   const ENUM_TIMEFRAMES period             ,
                                   const bool            debug01            ,
                                   const bool            gerarVolume02      ,
                                   const bool            gerarOfertas03     , //nao eh usado
                                   const int             qtdBarProcHist04   ,
                                   const double          bookOut05          ,
                                   const int             qtdPeriodo06       ,
                                   const bool            gerarSqlLog07=false,
                                   const string          versao=IFEIRA_VERSAO_DEFAULT ){

//--- set parameters of the indicator
   if     ( versao == IFEIRA_VERSAO_0103 ){ m_feira_name = IFEIRA_NAME_0103;}
   else if( versao == IFEIRA_VERSAO_0104 ){ m_feira_name = IFEIRA_NAME_0104;}
   else if( versao == IFEIRA_VERSAO_0202 ){ m_feira_name = IFEIRA_NAME_0202;}
   else if( versao == IFEIRA_VERSAO_0203 ){ m_feira_name = IFEIRA_NAME_0203;}
   else if( versao == IFEIRA_VERSAO_0204 ){ m_feira_name = IFEIRA_NAME_0204;}
   else if( versao == IFEIRA_VERSAO_0205 ){ m_feira_name = IFEIRA_NAME_0205;}
   else if( versao == IFEIRA_VERSAO_0206 ){ m_feira_name = IFEIRA_NAME_0206;}
   else if( versao == IFEIRA_VERSAO_0306 ){ m_feira_name = IFEIRA_NAME_0306;}
   else if( versao == IFEIRA_VERSAO_0307 ){ m_feira_name = IFEIRA_NAME_0307;}
   else                                   { Print(__FUNCTION__+": ERROR criando indicador feira :-( " + m_feira_name + " : versao ", versao, " invalida." );
                                            return false;
   }
   m_feira_qtd_buffers = IFEIRA_QTD_BUFFERS;
   MqlParam parameters[IFEIRA_QTD_PARAM];
//---
   parameters[0].type=TYPE_STRING; parameters[0].string_value  = m_feira_name    ;
   parameters[1].type=TYPE_BOOL  ; parameters[1].integer_value = debug01         ;
   parameters[2].type=TYPE_BOOL  ; parameters[2].integer_value = gerarVolume02   ;
   parameters[3].type=TYPE_BOOL  ; parameters[3].integer_value = gerarOfertas03  ;
   parameters[4].type=TYPE_INT   ; parameters[4].integer_value = qtdBarProcHist04;
   parameters[5].type=TYPE_DOUBLE; parameters[5].double_value  = bookOut05       ;
   parameters[6].type=TYPE_INT   ; parameters[6].integer_value = qtdPeriodo06    ;
   parameters[7].type=TYPE_BOOL  ; parameters[7].integer_value = gerarSqlLog07   ;

//--- object initialization
   if( !CiCustom::Create(symbol,period,IND_CUSTOM,7,parameters) ){
       Print(__FUNCTION__+": ERROR criando indicador feira :-(  " + m_feira_name + " : ", GetLastError() );
       return false;
   }
//--- number of buffers
   if(!CiCustom::NumBuffers(m_feira_qtd_buffers)){
       Print(__FUNCTION__+": ERROR criando buffers do indicador feira :-(  " + m_feira_name + " : ", GetLastError() );
       return false;
   }
//--- ok
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
osc_ind_minion_feira::osc_ind_minion_feira(){}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
osc_ind_minion_feira::~osc_ind_minion_feira(){}
//+------------------------------------------------------------------+
