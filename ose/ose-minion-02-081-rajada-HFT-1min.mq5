﻿//+------------------------------------------------------------------+
//|            eaMinion-09-02-00-dx-bolinguer-e-feira-indefinido.mq5 |
//|                                         Copyright 2019, OS Corp. |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao 2.081                                                     |
//| 1. Fork da versao 2.080 feito em 19/11/2019.                     |
//| 2. Nova forma de entrada a XX ticks do preco atual (testando HFT)|
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "2.081"

#include <Indicators\Trend.mqh> // for class CiMA;
#include <Generic\Queue.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

#include <..\Projects\projetcts\os-ea\ClassMinion-02-com-estatistica.mqh>
#include <oslib\osc\osc-minion-trade-03.mqh>
#include <oslib\osc-ind-minion-feira.mqh>
#include <oslib\os-lib.mq5>

#define  SLEEP_PADRAO  50


enum ENUM_TIPO_OPERACAO{
    NAO_ABRIR_POSICAO                    = 0,
    CONTRA_TEND_DURANTE_COMPROMETIMENTO  = 1,
    CONTRA_TEND_APOS_COMPROMETIMENTO     = 2,
    CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR = 3,
    HFT_DISTANCIA_PRECO                  = 4,
    HFT_NA_TENDENCIA                     = 5
};

//---------------------------------------------------------------------------------------------
input string S01                    =  ""         ; //==== PARAMETROS GERAIS ====
//input bool   EA07_FULL_AUTO         =  false      ; //EA07_FULL_AUTO:se true, EA abre posicoes automaticamente.
input ENUM_TIPO_OPERACAO EA07_ABRIR_POSICAO  =  NAO_ABRIR_POSICAO ; //EA07_FULL_AUTO:se true, EA abre posicoes automaticamente.
input double EA03_PASSO_RAJADA      =  1          ; //EA03_PASSO_RAJADA:Incremento de preco, em tick, na direcao contraria a posicao;
input int    EA10_TICKS_ENTRADA_HTF =  2          ; //distancia do preco para entrar na proxima posicao;
input int    EA02_QTD_TICKS_4_GAIN  =  2          ; //EA02_QTD_TICKS_4_GAIN:Quantidade de ticks para o gain;
input int    EA01_MAX_VOL_EM_RISCO  =  200        ; //EA01_MAX_VOL_EM_RISCO:Qtd max de contratos em risco;
input double EA07_STOP_LOSS         = -150        ; //EA07_STOP_LOSS:Valor maximo de perda aceitavel;
input int    EA07_TICKS_STOP_LOSS   =  10         ; //EA07_TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
input bool   EA03_FECHAR_RAJADA     =  true       ; //Fechar ordens rajada qd nao houver posicao. 
input double EA05_VOLUME_LOTE_RAJ   =  1          ; //Tamanho do lote a ser usado nas rajadas.
input double EA05_VOLUME_LOTE_INI   =  2          ; //Tamanho do lote a ser usado na abertura de posicao.
input double EA09_VOLAT_ALTA        =  0.55       ; //Volatilidade a considerar alta(%).
//input double EA09_VOLAT_MEDIA     =  0.7        ; //Volatilidade a considerar media(%).
input double EA09_VOLAT_BAIXA       =  0.2        ; //Volatilidade a considerar baixa(%).
//input double EA09_INCL_MAX_IN     =  0.5        ; //EA09_INCL_MAX_IN:Inclinacao max p/ entrar no trade.
//input bool   EA01_DEBUG             =  false    ; //EA01_DEBUG:se true, grava informacoes de debug no log do EA.
//input double EA04_DX_TRAILLING_STOP =  1.0      ; //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
//input double EA10_DX1               =  0.2      ; //EA10_DX1:Tamanho do DX em relacao a banda em %;
input int    EA08_MAGIC             =  191102081  ; //Numero magico desse EA. yymmvvvvv.

#define EA01_DEBUG              false      //EA01_DEBUG:se true, grava informacoes de debug no log do EA.
#define EA04_DX_TRAILLING_STOP  1.0        //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
#define EA10_DX1                0.2        //EA10_DX1:Tamanho do DX em relacao a banda em %;


//---------------------------------------------------------------------------------------------
// configurando a feira...
input string S03                       = ""    ; //==== INDICADOR FEIRA ====
input bool   FEIRA01_DEBUG             = false ; // se true, grava informacoes de debug no log.
input bool   FEIRA02_GERAR_VOLUME      = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input bool   FEIRA03_GERAR_OFERTAS     = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
input int    FEIRA04_QTD_BAR_PROC_HIST = 0     ; // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input double FEIRA05_BOOK_OUT          = 0     ; // Porcentagem das extremidades dos precos do book que serão desprezados.
input int    FEIRA06_QTD_PERIODOS      = 1     ; // Quantidade de barras que serao acumulads para calcular as medias.
input bool   FEIRA99_ADD_IND_2_CHART   = true  ; // Se true apresenta o idicador feira no grafico.
//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
input string S04               = ""; //==== HORARIO DE OPERACAO ====
input int    HR_INI_OPERACAO   = 09; // Hora   de inicio da operacao;
input int    MI_INI_OPERACAO   = 05; // Minuto de inicio da operacao;
input int    HR_FIM_OPERACAO   = 17; // Hora   de fim    da operacao;
input int    MI_FIM_OPERACAO   = 55; // Minuto de fim    da operacao;
//---------------------------------------------------------------------------------------------

CiBands*      m_bb;
MqlDateTime   m_date;
string        m_name = "MINION-02-081-RAJADA-HFT-1MIN";
CSymbolInfo   m_symb                          ;
CPositionInfo m_posicao                       ;
CAccountInfo  m_cta                           ;
double        m_tick_size                     ;// alteracao minima de preco.
double        m_shift                         ;// valor do fastclose;
double        m_stopLoss                      ;// stop loss;
double        m_distMediasBook                ;// Distancia entre as medias Ask e Bid do book.

osc_minion_trade      m_trade;
osc_ind_minion_feira* m_feira;

int BB_SUPERIOR     =  1;
int BB_INFERIOR     = -1;
int BB_MEDIA        =  0;
int BB_DESCONHECIDA =  2;

int m_ult_toque     = BB_DESCONHECIDA; // indica em que banda foi o ultimo toque do preco.
int m_pri_toque     = BB_DESCONHECIDA; // indica em que banda estah o primeiro toque de preco; A operacao eh aberta no primeiro toque na banda;
int m_ult_oper      = BB_DESCONHECIDA; // indica em que banda foi a ultima operacao;

bool   m_comprado        = false;
bool   m_vendido         = false;
double m_precoPosicao    = 0;
double m_volumePosicao   = 0;    // volume da posicao atual
long   m_positionId      = 0;
double m_tstop           = 0;
string m_positionCommentStr     = "0";
long   m_positionCommentNumeric = 0;

//--- variaveis atualizadas pela funcao refreshMe...
double m_med           = 0;//normalizar( m_bb.Base(0)  ); // preco medio das bandas de bollinguer
double m_inf           = 0;//normalizar( m_bb.Lower(0) ); // preco da banda de bollinger inferior
double m_sup           = 0;//normalizar( m_bb.Upper(0) ); // preco da banda de bollinger superior
double m_bdx           = 0;//MathAbs   ( sup-med       ); // distancia entre as bandas de bollinger e a media, sem sinal;
double m_dx1           = 0;//normalizar( DX1*bdx       ); // normalmente 20% da distancia entre a media e uma das bandas.
int    m_qtdOrdens     = 0;
int    m_qtdPosicoes   = 0;
double m_posicaoProfit = 0;
int    m_min_ult_trade = 0;
double m_ask           = 0;
double m_bid           = 0;
double m_val_order_4_gain   = 0;
double m_max_barra_anterior = 0;
double m_min_barra_anterior = 0;

//--precos medios do book e do timesAndTrades
double m_pmBid = 0;
double m_pmAsk = 0;
double m_pmBok = 0;
double m_pmBuy = 0;
double m_pmSel = 0;
double m_pmTra = 0;

// precos no periodo
double m_phigh  = 0; //-- preco maximo no periodo
double m_plow   = 0; //-- preco minimo no periodo


//-- controle dos sinais
double m_sigAsk  = 0; //-- seta rosa (pra cima)
double m_sigBid  = 0; //-- seta azul (pra baixo)

double m_comprometimento_up = 0;
double m_comprometimento_dw = 0;

//-- controle das inclinacoes
double   m_inclSel    = 0;
double   m_inclBuy    = 0;
double   m_inclTra    = 0;
double   m_inclBok    = 0;
double   m_inclSelAbs = 0;
double   m_inclBuyAbs = 0;
double   m_inclTraAbs = 0;
double   m_inclEntrada= 0; // inclinacao usada na entrada da operacao.

string   m_apmb       = "APMB"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
MqlRates m_rates[];

string   m_comment_fixo;
string   m_comment_var;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()  {

    printf("***** Iniciando " + m_name + ":" + IntegerToString(EA08_MAGIC) + " as " + TimeToString( TimeCurrent() ) +"... ******");

    m_symb.Name                  ( Symbol() );
    m_symb.Refresh               (); // propriedades do simbolo. Basta executar uma vez.
    m_symb.RefreshRates          (); // valores do tick. execute uma vez por tick.
    m_tick_size = m_symb.TickSize(); //Obtem a alteracao minima de preco
    m_shift     = m_symb.NormalizePrice(EA02_QTD_TICKS_4_GAIN*m_tick_size);
    m_stopLoss  = m_symb.NormalizePrice(EA07_TICKS_STOP_LOSS *m_tick_size);
    m_trade.setMagic   (EA08_MAGIC);
    m_trade.setStopLoss(m_stopLoss);
    m_trade.setTakeProf(0);
    ArraySetAsSeries(m_rates,true);
    
    m_comment_fixo = "LOGIN:"       + DoubleToString(m_cta.Login(),0)+ 
                     "  TRADEMODE:" + m_cta.TradeModeDescription()    + 
                     "  MARGINMODE:"  + m_cta.MarginModeDescription() ; 
                   //"alavancagem:" + m_cta.Leverage()               + "\n" +
                   //"stopoutmode:" + m_cta.StopoutModeDescription() + "\n" +
                   //"max_ord_pend:"+ m_cta.LimitOrders()            + "\n" + // max ordens pendentes permitidas
    Comment(m_comment_fixo);
                         
    double lotes = EA05_VOLUME_LOTE_INI < m_symb.LotsMin()? m_symb.LotsMin():
                   EA05_VOLUME_LOTE_INI > m_symb.LotsMax()? m_symb.LotsMax():
                   EA05_VOLUME_LOTE_INI;
    m_trade.setVolLote (lotes);

    // inicializando a banda de bolinguer...
    //m_bb = new CiBands();
    //if ( !m_bb.Create(_Symbol         , //string           string,        // Symbol
    //                 PERIOD_CURRENT   , //ENUM_TIMEFRAMES  period,        // Period
    //                 BB_QTD_PERIODO_MA, //int              ma_period,     // Averaging period
    //                 0                , //int              ma_shift,      // Horizontal shift
    //                 BB_DESVIO_PADRAO , //double           deviation      // Desvio
    //                 PRICE_MEDIAN       //int              applied        // (máximo + mínimo)/2 (see ENUM_APPLIED_PRICE)
    //                 )
    //    ){
    //    Print(m_name,": Erro inicializando o indicador BB :-(");
    //    return(1);
    //}

    // inicializando a feira...
    m_feira = new osc_ind_minion_feira();
    if( ! m_feira.Create(  m_symb.Name(),PERIOD_CURRENT           ,
                                         FEIRA01_DEBUG            ,
                                         FEIRA02_GERAR_VOLUME     ,
                                         FEIRA03_GERAR_OFERTAS    ,
                                         FEIRA04_QTD_BAR_PROC_HIST,
                                         FEIRA05_BOOK_OUT         ,
                                         FEIRA06_QTD_PERIODOS     ,
                                         IFEIRA_VERSAO_0205       )   ){
        Print(m_name,": Erro inicializando o indicador FEIRA :-( ", GetLastError() );
        return(1);
    }

    Print(m_name,": Expert ", m_name, " inicializado :-)" );

    // adicionando FEIRA ao grafico...
    if( FEIRA99_ADD_IND_2_CHART ){ m_feira.AddToChart(0,0); }

    return(0);
}

double m_len_canal_ofertas = 0; // tamanho do canal de oefertas do book.
double m_len_barra_atual   = 0; // tamanho da barra de trades atual.
double m_volatilidade      = 0; // calculamos a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;

void refreshMe(){
    //m_bb.Refresh(-1);
    m_posicao.Select( m_symb.Name() );
    m_symb.RefreshRates();
    m_feira.Refresh();
    
    m_ask = m_symb.Ask();
    m_bid = m_symb.Bid();

    // atualizando maximo, min e tamnaho das barras anterior de preco atual e anterior...
    CopyRates(m_symb.Name(),_Period,0,2,m_rates);
    m_max_barra_anterior = m_rates[1].high;
    m_min_barra_anterior = m_rates[1].low ;

    //m_med = normalizar( m_bb.Base(0)  ); // preco medio das bandas de bollinguer
    //m_inf = normalizar( m_bb.Lower(0) ); // preco da banda de bollinger inferior
    //m_sup = normalizar( m_bb.Upper(0) ); // preco da banda de bollinger superior
    //m_bdx = MathAbs   ( m_sup-m_med   ); // distancia entre as bandas de bollinger e a media, sem sinal;
    //m_dx1 = normalizar( EA10_DX1*m_bdx); // normalmente 20% da distancia entre a media e uma das bandas.

    m_qtdOrdens   = OrdersTotal();
    m_qtdPosicoes = PositionsTotal();

    // adminstrando posicao aberta...
    if( m_qtdPosicoes > 0 ){
        m_posicaoProfit = 0;
        if ( PositionSelect  (m_symb.Name()) ){ // soh funciona em contas hedge
      //if ( m_posicao.Select(m_symb.Name()) ){ // soh funciona em contas hedge
            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                setCompradoSoft();
            }else{
                setVendidoSoft();
            }
            m_posicaoProfit          = PositionGetDouble (POSITION_PROFIT     );
            m_precoPosicao           = PositionGetDouble (POSITION_PRICE_OPEN );
            m_volumePosicao          = PositionGetDouble (POSITION_VOLUME     );
            m_positionId             = PositionGetInteger(POSITION_IDENTIFIER );
            m_positionCommentStr     = PositionGetString (POSITION_COMMENT    );
            m_positionCommentNumeric = StringToInteger   (m_positionCommentStr);          

            // se o comentario da posicao for numerico, precisamos saber pois trata-se de um engano e deveremos fechar a posicao e todas as ordens.
            if( !MathIsValidNumber(m_positionCommentNumeric) ) m_positionCommentNumeric = 0; 

        }else{
           m_comprado = false;
           m_vendido  = false;
        }
    }else{
        m_comprado = false;
        m_vendido  = false;
    }

   //-- precos medios do book
   m_pmBid = normalizar( m_feira.getPrecoMedioBid(0) );
   m_pmAsk = normalizar( m_feira.getPrecoMedioAsk(0) );
   m_pmBok = normalizar( m_feira.getPrecoMedioBok(0) );
   m_pmSel = normalizar( m_feira.getPrecoMedioSel(0) );
   m_pmBuy = normalizar( m_feira.getPrecoMedioBuy(0) );
   m_pmTra = normalizar( m_feira.getPrecoMedioTra(0) );

   // canal de ofertas no book...
   m_len_canal_ofertas = m_pmAsk - m_pmBid;

   //-- precos no periodo
   m_phigh           = m_feira.getPrecoHigh(0);
   m_plow            = m_feira.getPrecoLow(0);
   m_len_barra_atual = m_phigh - m_plow;

   // calculamos a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
   if( m_len_canal_ofertas > 0 ) m_volatilidade = m_len_barra_atual / m_len_canal_ofertas;

   
   //--inclinacoes dos precos medios de compra e venda...
   m_inclSel    = m_feira.getInclinacaoSel(0);
   m_inclBuy    = m_feira.getInclinacaoBuy(0);
   m_inclTra    = m_feira.getInclinacaoTra(0);
   m_inclBok    = m_feira.getInclinacaoBok(0);
   m_inclSelAbs = MathAbs(m_inclSel);
   m_inclBuyAbs = MathAbs(m_inclBuy);
   m_inclTraAbs = MathAbs(m_inclTra);


   //-- sinais de compra e venda
   m_sigAsk = m_feira.getSinalOfertaAsk (0); //-- seta pra cima
   m_sigBid = m_feira.getSinalOfertaBid (0); //-- seta pra baixo
   
   //-- Informa a maxima ou minima da vela anterior caso tenha havido comprometimento institucional naquela vela.
   m_comprometimento_up = m_feira.getSinalCompromissoUp(1);
   m_comprometimento_dw = m_feira.getSinalCompromissoDw(1);   
   
   
   m_comment_var = 
                   "  CTA SLD:"      + DoubleToString(m_cta.Balance(),2) + 
                   "  CR:"           + DoubleToString(m_cta.Credit(),2) + 
                   "  PROFIT:"       + DoubleToString(m_cta.Profit(),2) + 
                   "  CAPLIQ: "      + DoubleToString(m_cta.Equity(),2) + 
                   "  MARGEM:"       + DoubleToString(m_cta.Margin(),2) + 
                   "  MARGEM LIVRE:" + DoubleToString(m_cta.FreeMargin(),2) + 
                   "  NIVEL MARGEM:" + DoubleToString(m_cta.FreeMargin(),2) +

                   "\nABRIR_POSICAO:"    +                EA07_ABRIR_POSICAO       +
                   "  MAX_VOL_EM_RISCO:" + DoubleToString(EA01_MAX_VOL_EM_RISCO,0) + 
                   "  STOP_LOSS:"        + DoubleToString(EA07_STOP_LOSS       ,0) +
                   "  TICKS_STOP_LOSS:"  + DoubleToString(EA07_TICKS_STOP_LOSS ,0) +
  
                   ///"VAL: " + DoubleToString(m_posicaoProfit,2) + " de " + DoubleToString(EA07_STOP_LOSS,_Digits) + " VOL: " + DoubleToString(m_volumePosicao,_Digits) +" de " + DoubleToString(EA01_MAX_VOL_EM_RISCO,_Digits) + "\n"+
                   //"  EA09_INCL_MIN_IN: " + DoubleToString(EA09_INCL_MIN_IN,2)+ // " EA09_INCL_MAX_IN: " + DoubleToString(EA09_INCL_MAX_IN,2)+ "\n" +
                   ///"m_pmBok: " + m_pmBok + "\n" +
                   ///"m_pmTra: " + m_pmTra + "\n" +
                   ///"\n\nm_pmAsk: "   + m_pmAsk + "  m_ask: " + m_ask + "  dist:" + DoubleToString((m_pmAsk-m_ask),_Digits)+ "  MAX_ANT " + DoubleToString(m_max_barra_anterior,_Digits) + "  COMPROMISSO_UP " + DoubleToString(m_comprometimento_up,_Digits) + "  VOLATILIDADE " + DoubleToString(m_volatilidade,2) +
                   ///"\nm_pmBid: "     + m_pmBid + "  m_bid: " + m_bid + "  dist:" + DoubleToString((m_bid-m_pmBid),_Digits)+ "  MIN_ANT " + DoubleToString(m_min_barra_anterior,_Digits) + "  COMPROMISSO_DW " + DoubleToString(m_comprometimento_dw,_Digits) +
                   ///"VVOL/VMAX/VMIN: " + DoubleToString(m_symb.Volume(),_Digits)+ "/"+  DoubleToString(m_symb.VolumeHigh(),_Digits) + "/"+ DoubleToString(m_symb.VolumeLow(),_Digits) +"\n"+
                   ///"SPREAD: " + DoubleToString(m_symb.Spread(),_Digits) + "\n" + // STOPSLEVEL: " + m_symb.StopsLevel() + " FREEZELEVEL: " +  m_symb.FreezeLevel() + "\n" +
                   ///"BID/BHIGH/BLOW: " + DoubleToString(m_symb.Bid(),_Digits)  + "/" + DoubleToString(m_symb.BidHigh(),_Digits)  +"/"+DoubleToString(m_symb.BidLow(),_Digits)  + "\n" +
                   ///"ASK/AHIGH/ALOW: " + DoubleToString(m_symb.Ask(),_Digits)  + "/" + DoubleToString(m_symb.AskHigh(),_Digits)  +"/"+DoubleToString(m_symb.AskLow(),_Digits)  + "\n" +
                   ///"LAS/LHIGH/LLOW: " + DoubleToString(m_symb.Last(),_Digits) + "/" + DoubleToString(m_symb.LastHigh(),_Digits) +"/"+ DoubleToString(m_symb.LastLow(),_Digits) + "\n" +
                   ///////
                   //"SESSION \n" +
                   //"QTD_ORD_BUY: " + m_symb.SessionBuyOrders() + "\n" +
                   //"QTD_ORD_SEL: " + m_symb.SessionSellOrders()+ "\n" +
                   //"TURNOVER: "    + m_symb.SessionTurnover()  + "\n" +
                   //"INTEREST: "    + m_symb.SessionInterest()  + "\n" +
                   //"VOL_ORD_BUY: " + m_symb.SessionBuyOrdersVolume()  + "\n" +
                   //"VOL_ORD_SEL: " + m_symb.SessionSellOrdersVolume() + "\n" +
                   //"\n\nQTD_POS: "    + IntegerToString(m_qtdPosicoes) +
                   "\n\nVAL_GAIN:"   + DoubleToString (m_val_order_4_gain, _Digits) +
                   "  VOL:"          + IntegerToString(m_qtdOrdens) + 
                   "  INCLINACAO: "  + DoubleToString (m_inclTra,2) + 
                   "  VOLATILIDADE " + DoubleToString (m_volatilidade,2) +
                   "\n" + (m_qtdPosicoes==0?"SEM POSICAO":estouComprado()?"COMPRADO":"VENDIDO") +
                   "\nm_posicaoProfit: " + DoubleToString(m_posicaoProfit,2)+
                   "\nPROFIT:" + DoubleToString(m_cta.Profit(),2) +
                   
                   
                   "\n\nQTD_OFERTAS: " + IntegerToString(m_symb.SessionDeals()) +
                   "  OPEN "           + DoubleToString (m_symb.SessionOpen(),_Digits) +
                   "  VWAP "           + DoubleToString (m_symb.SessionAW(),_Digits) ;
                   //"CLOSE: "       + m_symb.SessionClose() + "\n" +
                   //"PRECO_LIQ: "   + m_symb.SessionPriceSettlement() + "\n" +
                   //"PRECO_MIN: "   + m_symb.SessionPriceLimitMin() + "\n" +
                   //"PRECO_MAX: "   + m_symb.SessionPriceLimitMax() + "\n" ;
                    
   Comment(m_comment_fixo + m_comment_var);
}


void fecharTudo(string descr){
      // se tem posicao ou ordem aberta, fecha.
      if( m_qtdOrdens   > 0 ){ m_trade.cancelarOrdens(descr)       ;                     }
      if( m_qtdPosicoes > 0 ){ m_trade.fecharQualquerPosicao(descr); Sleep(SLEEP_PADRAO);}   
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
    refreshMe();

    if( !estah_no_intervalo_de_negociacao() ) { fecharTudo("INTERVALO"                      ); return; }// posicao aberta fora do horario
    
    
    m_trade.setStopLoss( m_stopLoss        );
    m_trade.setVolLote ( m_symb.LotsMin()  );

    if ( m_qtdPosicoes > 0 ) {
     
       //if( m_positionCommentStr == "RAJADA"    ) { fecharTudo("POSICAO_RAJADA"                 ); return; }// posicao de rajada, nao estah planejada
       //if( m_positionCommentNumeric != 0       ) { fecharTudo("POSICAO_COM_COMENTARIO_NUMERICO"); return; }// posicao aberta para fechar rajada, nao estah planejada
       
         // se tem posicao aberta, cancelamos as ordens apmb que porventura tenham ficado abertas
         m_trade.cancelarOrdensComentadas(m_apmb);

         if( m_posicaoProfit < EA07_STOP_LOSS ){ 
             Print("Acionando STOPLOSS. Valor posicao=",m_posicaoProfit, " :-(");
             fecharTudo("STOP_LOSS"); 
             return;
         }

         // Este trecho salvou de perder uma posicao de 30 contratos no final do dia 20191121...
         // Entao pense bem antes alterar aqui !!!!!!
         if( m_qtdOrdens > 5 && m_posicaoProfit >= 0 && volatilidadeEstahAlta() ){ 
             Print("Acionando STOPVOLATILIDADE_X_QTD. Valor posicao=",m_posicaoProfit, " :-|");
             fecharTudo("STOP_VOLATILIDADE"); 
             return;
         }
         
         // passo    : aumento de preco, em tick, na direcao contraria a posicao
         // volLimite: volume maximo em risco
         // volLote  : volume de ordem aberta na direcao contraria a posicao (usada pra fechar a posicao).
         // profit   : quantidade de ticks para o gain
         doOpenRajada(EA03_PASSO_RAJADA, EA01_MAX_VOL_EM_RISCO, EA05_VOLUME_LOTE_RAJ, EA02_QTD_TICKS_4_GAIN); // acionando saida rapida...

    }else{
        // aqui neste bloco, estah garantido que nao ha posicao aberta...
        m_val_order_4_gain = 0; // zerando o valor da primeira ordem da posicao...

        if( m_qtdOrdens > 0 ){
           
           //apmb(nunca fechar), vazio(nunca fechar), numero(sempre fechar, pois soh pode ter ordem com comentario numerico se tiver posicao aberta)...
           m_trade.cancelarOrdensComComentarioNumerico(_Symbol); // sao as ordens de fechamento de rajada.
           
           // se tiver ordens RAJADA sem posicao aberta e parametro manda fechar, fecha elas...
           if(EA03_FECHAR_RAJADA){  m_trade.cancelarOrdensComentadas("RAJADA"); Sleep(SLEEP_PADRAO); } // Parada de meio segundo apos os cancelamentos visando evitar atropelos...
           
           // se tiver ordem sem stop, coloca agora...
           m_trade.colocarStopEmTodasAsOrdens(m_stopLoss);
        }
      
        //if( EA07_FULL_AUTO ){ 
        //   abrirPosicaoNasMediasDoBook();
        //}
        
        switch(EA07_ABRIR_POSICAO){
          case CONTRA_TEND_DURANTE_COMPROMETIMENTO : abrirPosicaoDuranteComprometimentoInstitucional(); break;
          case CONTRA_TEND_APOS_COMPROMETIMENTO    : abrirPosicaoAposComprometimentoInstitucional   (); break;
          case CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR: abrirPosicaoAposMaxMinBarraAnterior            (); break;
          case HFT_DISTANCIA_PRECO                 : abrirPosicaoHFTdistanciaDoPreco                (); break;
          case HFT_NA_TENDENCIA                    : abrirPosicaoHFTnaTendencia                     (); break;
        //case NAO_ABRIR_POSICAO                     
        }
        return;
    }
    return;
}//+------------------------------------------------------------------+

//----------------------------------------------------------------------------------------------------------------------------
// Esta funcao deve ser chamada sempre qua ha uma posicao aberta.
// Ela cria rajada de ordens no sentido da posicao, bem como as ordens de fechamento da posicao baseadas nas ordens da rajada.
// passo    : aumento de preco na direcao contraria a posicao
// volLimite: volume maximo em risco
// volLote  : volume de ordem aberta na direcao contraria a posicao
// profit   : quantidade de ticks para o gain
//----------------------------------------------------------------------------------------------------------------------------
bool doOpenRajada(double passo, double volLimite, double volLote, double profit){

   if( estouVendido() ){
         // se nao tem ordem pendente acima do preco atual, abre uma...
         double precoOrdem = m_symb.NormalizePrice( m_ask+m_tick_size*passo );
         
         if( (precoOrdem > m_val_order_4_gain || m_val_order_4_gain==0 )                                   && // vender sempre acima da primeira ordem da posicao  
             !m_trade.tenhoOrdemLimitadaDeVenda ( precoOrdem                   , m_symb.Name(), "RAJADA" ) &&
             !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem-profit*m_tick_size, m_symb.Name(), "RAJADA" ) // se tiver a ordem de compra pendente,
                                                                                                           // significa que a ordem de venda foi
                                                                                                           // executada, entao nao abrimos nova
                                                                                                           // ordem de venda ateh que a compra,
                                                                                                           // que eh seu fechamento, seja executada.
           ){
            // se nao tiver, verifica o volume de ordens abertas de venda mais o volume da posicao (obs: a posicao deve ser vendedora)
            double vol = m_volumePosicao;// + m_trade.getVolOrdensPendentesDeVenda(_Symbol);

            // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
            if( vol <= volLimite){
                Print("HFT_ORDEM OPEN_RAJADA SELL_LIMIT=",precoOrdem, ". Enviando...");
                if( m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, volLote, "RAJADA") ){
                    if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem;}
                }
            }
         }
         // abrindo ordens pra fechar a posicao
         return doCloseRajada(passo, volLote, profit, true);
   }else{
         // se nao tem ordem pendente abaixo do preco atual, abre uma...
         double precoOrdem = m_symb.NormalizePrice( m_bid-m_tick_size*passo );
         
         if( (precoOrdem < m_val_order_4_gain || m_val_order_4_gain==0 )                                   && // comprar sempre abaixo da primeira ordem da posicao  
             !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem                   , m_symb.Name(), "RAJADA" ) &&
             !m_trade.tenhoOrdemLimitadaDeVenda ( precoOrdem+profit*m_tick_size, m_symb.Name(), "RAJADA" ) // se tiver a ordem de venda pendente,
                                                                                                           // significa que a ordem de compra foi
                                                                                                           // executada, entao nao abrimos nova
                                                                                                           // ordem de compra ateh que a venda,
                                                                                                           // que eh seu fechamento, seja executada.
           ){
            // se nao tiver, verifica o volume de ordens abertas de compra mais o volume da posicao (obs: a posicao deve ser compradora)
            double vol = m_volumePosicao;// + m_trade.getVolOrdensPendentesDeCompra(_Symbol);

            // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
            if( vol <= volLimite){
                Print("HFT_ORDEM OPEN_RAJADA BUY_LIMIT=",precoOrdem, ". Enviando...");
                if( m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, volLote, "RAJADA") ){
                    if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem;}
                }
            }
         }
         // abrindo ordens pra fechar a posicao
         return doCloseRajada(passo, volLote, profit, false);
   }

   // nao deveria chegar aqui, a menos que esta funcao seja chamada sem uma posicao aberta.
   return false;
}
//----------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------
// Faz      : Abre as ordens de fechamento das posicoes abertas no doOpenRajada. As posicoes de fechamento sao
//            abertas sempre que as ordens da rajada sao executadas, ou seja, sempre que vao pra posicao.
//            Aqui vamos eliminar o bug da versao doCloseRajada, que estah duplicando as ordens de fechamento
//            da primeira ordem executada no fechamento da posicao.
//
// passo    : aumento de preco na direcao contraria a posicao
// volLote  : volume de ordem aberta na direcao contraria a posicao
// profit   : quantidade de ticks para o gain
// close_seel: true se estah fechando uma rajada de vendas e false se quer fechar uma rajada de compras.
//------------------------------------------------------------------------------------------------------------
bool doCloseRajada(double passo, double volLote, double profit, bool close_sell){

   // agora vamos processar as transacoes...
   ulong        deal_ticket; // ticket da transacao
   int          deal_type  ; // tipo de operação comercial
   CQueue<long> qDealSel   ; // fila de transacoes de venda  da posicao. Ao final do segundo laco, devem ficar na fila, as vendas cuja compra nao foi concretizada...
   CQueue<long> qDealBuy   ; // fila de transacoes de compra da posicao. Ao final do segundo laco, deve ficar vazia.

   // Faca assim:
   // 1. Coloque vendas e compras em filas separadas
   // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
   // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.
   
   HistorySelectByPosition(m_positionId); // recuperando ordens e transacoes da posicao atual no historico...
   int deals = HistoryDealsTotal();
   for(int i=0;i<deals;i++) {  // selecionando as tranacoes (entradas e saidas) para processamento...

      deal_ticket =      HistoryDealGetTicket(i);
      deal_type   = (int)HistoryDealGetInteger(deal_ticket,DEAL_TYPE);

      // 1. Colocando vendas e compras em filas separadas...
      switch(deal_type){
         case DEAL_TYPE_SELL: qDealSel.Enqueue(deal_ticket); break;
         case DEAL_TYPE_BUY : qDealBuy.Enqueue(deal_ticket); break;
      }
   }

   // abrindo ordens de compra pra fechar uma rajada de vendas...
   if(close_sell){
      // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
      int    qtd     = qDealBuy.Count();
      long   ticketSel;
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealBuy.Dequeue();
         ticketSel   = StringToInteger( HistoryDealGetString(deal_ticket,DEAL_COMMENT) ); // obtendo o ticket de venda no comentario da ordem de compra...
         qDealSel.Remove(ticketSel); // removendo a venda da fila de vendas pendentes de abrir posicao de compra...
      }

      // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.
      // se sobrou elemento na fila, checamos se jah tem a ordem de compra correspondente. Se nao tiver, criamos.
             qtd         = qDealSel.Count();
      double val         = 0               ;
      double precoProfit = 0               ;
      string idClose                       ;
      double vol         = 0               ;
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealSel.Dequeue();
         idClose = IntegerToString(deal_ticket); // colocando o ticket da venda na ordem de compra. Serah usado posteriormente
                                                 // para encontrar as compras que jah foram processadas.
         if( !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){

             // se nao tem ordem de fechamento da posicao, criamos uma agora:
             precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) - profit*m_tick_size );
             vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
             Print("HFT_ORDEM CLOSE_RAJADA BUY_LIMIT=",precoProfit, " ID=", idClose, "...");
             m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT,precoProfit, vol, idClose);
         }
      }
   // abrindo ordens de venda pra fechar uma rajada de compras...
   }else{
      // 2. Percorra a fila de vendas e, pra cada venda encontrada, busque a compra correspondente e retire-a da fila de compras.
      int    qtd     = qDealSel.Count();
      long   ticketBuy;
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealSel.Dequeue();
         ticketBuy   = StringToInteger( HistoryDealGetString(deal_ticket,DEAL_COMMENT) ); // obtendo o ticket de compra no comentario da ordem de venda...
         qDealBuy.Remove(ticketBuy); // removendo a compra da fila de compras pendentes de abrir posicao de venda...
      }

      // 3. Se sobraram compras na fila de compras, processe-a conforme abaixo.
      // se sobrou elemento na fila, checamos se jah tem a ordem de venda correspondente. Se nao tiver, criamos.
             qtd         = qDealBuy.Count();
      double val         = 0               ;
      double precoProfit = 0               ;
      string idClose                       ;
      double vol         = 0               ;
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealBuy.Dequeue();
         idClose = IntegerToString(deal_ticket); // colocando o ticket da compra na ordem de venda. Serah usado posteriormente
                                                 // para encontrar as vendas que jah foram processadas.
         if( !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){
             // se nao tem ordem de fechamento da posicao, criamos uma agora:
             precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) + profit*m_tick_size );
             vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
             Print("HFT_ORDEM CLOSE_RAJADA SELL_LIMIT=",precoProfit, " ID=", idClose, "...");
             m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,precoProfit, vol, idClose);
         }
      }
   }

   return true;
}

// Abre e mantem as ordens limitadas de abertura de posicao.
// Condicoes:
// Compra abaixo da media de compra(barato) e vende acima da media de compra(caro);
// Ordens limitadas sao colocadas EA10_TICKS_ENTRADA_HTF (geralmente 2 ticks) de distancia do preco atual.
// Nao abre posicao durante o pregao.
// Nao abre posicao se a volatilidade estiver alta.
// Nao chame este metodo se houver posicao aberta.
void abrirPosicaoHFTdistanciaDoPreco(){

   double vol        = EA05_VOLUME_LOTE_INI;
   double precoOrdem = 0;

     // Se o mercado estah em leilao, cancela as ordens de abertura de posicao
     // quando mercado estah em leilao, o preco ask fica menor que o bid...
     if ( m_ask<=m_bid            ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

     // Se a volatilidade estah alta ou o mercado estah em leilao, cancela as ordens de abertura de posicao.
     if ( volatilidadeEstahAlta() ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

     // Vende EA10_TICKS_ENTRADA_HTF ticks acima do preco atual.
     precoOrdem = m_ask+(m_tick_size*EA10_TICKS_ENTRADA_HTF);
     
     // vendendo acima da media (caro)...
     if( precoOrdem < m_pmTra + (m_tick_size*EA02_QTD_TICKS_4_GAIN) ){
         precoOrdem = m_pmTra + (m_tick_size*EA02_QTD_TICKS_4_GAIN); 
     }
     
     //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
     if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
          Print("HFT_ASK=",m_ask,".  Criando ordem de VENDA a ",  precoOrdem, " Volatilidade=",m_volatilidade," ...");
          if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
     }

     //Compra EA10_TICKS_ENTRADA_HTF abaixo do preco atual.
     precoOrdem = m_bid-(m_tick_size*EA10_TICKS_ENTRADA_HTF); 

     // comprando abaixo da media (barato)...
     if( precoOrdem > m_pmTra - (m_tick_size*EA02_QTD_TICKS_4_GAIN) ){
         precoOrdem = m_pmTra - (m_tick_size*EA02_QTD_TICKS_4_GAIN); 
     }

     //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
     if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
          Print("HFT_BID=",m_min_barra_anterior,".  Criando ordem de COMPRA a ",  precoOrdem, " Volatilidade=",m_volatilidade, " ...");
          if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
     }
}

//------------------------------------------------------------------------------------------------------------
// Abre e mantem as ordens de abertura de posicao HFT. 
// Abre e mantem as ordens limitadas de abertura de posicao.
// Condicoes:
// Tenta abrir na tendencia.
// Compra abaixa da media de compra(barato) e vende acima da media de compra(caro);
// Nao abre posicao durante o pregao.
// Nao abre posicao se a volatilidade estiver alta.
// Nao chame este metodo se houver posicao aberta.
//------------------------------------------------------------------------------------------------------------
void abrirPosicaoHFTnaTendencia(){

   double vol         = EA05_VOLUME_LOTE_INI;
   double precoOrdem  = 0;
   double incl_limite = 0.08;

     // Se o mercado estah em leilao, cancela as ordens de abertura de posicao
     // quando mercado estah em leilao, o preco ask fica menor que o bid...
     if ( m_ask<=m_bid            ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

     //Se a volatilidade estah alta ou o mercado estah em leilao, cancela as ordens de abertura de posicao.
     if ( volatilidadeEstahAlta() ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

     // Vendendo na inclinacao negativa...
     if( m_inclTra <= -incl_limite ){
         //Vendendo na queda. 1 tick acima do preco atual...
         //precoOrdem = m_ask+m_tick_size;
         precoOrdem = m_ask;
              
         //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
         if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
              Print("HFT_ORDEM OPEN_POS ASK=",m_ask,". Criando ord VENDA a ",  precoOrdem, " Volat=",m_volatilidade,"  INCLI=",m_inclTra ," ...");
              if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
         }
     }

     // Comprando na inclinacao positiva...
     if( m_inclTra >= incl_limite ){

         //Comprando na subida. 1 tick abaixo do preco atual...
         //precoOrdem = m_bid-m_tick_size; 
         precoOrdem = m_bid; 
    
         //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
         if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
              Print("HFT_ORDEM OPEN_POS BID=",m_min_barra_anterior,". Criando ord COMPRA a ",  precoOrdem, " Volat=",m_volatilidade,"  INCLI=",m_inclTra ," ...");
              if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
         }
     }
}
//------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------
void abrirPosicaoDuranteComprometimentoInstitucional(){
   double vol        = EA05_VOLUME_LOTE_INI;
   double precoOrdem = 0;
   double shift = m_tick_size;
 //double shift = 0


   //  Venda: na media do preco ask
    if  ( m_ask >= (m_pmAsk-shift) ){

        precoOrdem = m_ask; // venda no preco medio de compra

        //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
        if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
             Print("MEDIA_ASK=",m_pmAsk,".  Criando ordem de VENDA a ",  precoOrdem, "...");
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
        }
        return;
        
   }else{
        // compra na media do preco bid.
        if(  m_bid <= (m_pmBid+shift) ){
         
             precoOrdem = m_bid; // copmpra no preco medio de venda
      
             //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
             if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
                  Print("MEDIA_BID ",m_pmBid,".  Criando ordem de COMPRA a ",  precoOrdem, "...");
                  if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
             }
             return;             
        }
   }

   // chegou aqui, pode ser que existam ordens abertas que nao satisfacam as condicoes de entrada. Entao as cancelamos.
   m_trade.cancelarOrdensComentadas(m_apmb);
}


//------------------------------------------------------------------------------------------------------------
// Abre posicao na vela seguinte ao comprometimento institucional, no mesmo valor do ponto de comprometimento
// e contra sua direcao.
//------------------------------------------------------------------------------------------------------------
void abrirPosicaoAposComprometimentoInstitucional(){

   double vol        = EA05_VOLUME_LOTE_INI;
   double precoOrdem = 0;
 //double shift = m_tick_size;
   double shift = 0          ;
   bool   tem_comprometimento = false;

   //  Vende se o preco ficar maior que o comprometimento institucional da vela anterior
  //if ( m_comprometimento_up > 0 && m_ask >= (m_comprometimento_up-shift) ){
    if ( m_comprometimento_up > 0  ){
    
        tem_comprometimento = true;
        
        if( m_ask >= (m_comprometimento_up-shift) ){
            precoOrdem = m_ask; // se o ask jah passou do valor do comprometimento, entramos com o preco ask.
        }else{
            precoOrdem = m_comprometimento_up; // se ask nao passou do valor do comprometimento, entramos no valor do comprometimento
        }

        //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
        if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
             Print("COMPROMISSO_UP=",m_comprometimento_up,".  Criando ordem de VENDA a ",  precoOrdem, "...");
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
        }
        
        
   }
   //  Compra se o preco ficar menor que o comprometimento institucional da vela anterior
   //if(  m_comprometimento_dw > 0 && m_bid <= (m_comprometimento_dw+shift) ){
   //     precoOrdem = m_bid; // copmpra no preco medio de venda
   if ( m_comprometimento_dw > 0  ){

        tem_comprometimento = true;

        if( m_bid <= (m_comprometimento_up+shift) ){
           precoOrdem = m_bid; // se o bid jah passou do valor do comprometimento, entramos com o preco bid.
        }else{
           precoOrdem = m_comprometimento_dw; // se bid nao passou do valor do comprometimento, entramos no valor do comprometimento
        }

        //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
        if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
             Print("COMPROMISSO_DW=",m_comprometimento_dw,".  Criando ordem de COMPRA a ",  precoOrdem, "...");
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
        }
   }
   

   // se nao tem comprometimento, cancela as ordens abertas.
   if (!tem_comprometimento) m_trade.cancelarOrdensComentadas(m_apmb);
}
//----------------------------------------------------------------------------------------------------------------------------------
// Abre e mantem as ordens de abertura de posicao. Nao chame este metodo se houver posicao aberta.
void abrirPosicaoAposMaxMinBarraAnterior(){

   double vol        = EA05_VOLUME_LOTE_INI;
   double precoOrdem = 0;

     //Nao abrir posicao se volatilidade for alta.
     //se a volatilidade estah alta, cancela as ordens de abertura de posicao.
     if ( volatilidadeEstahAlta() ) {
          m_trade.cancelarOrdensComentadas(m_apmb);
          return;
     }

     //Vende se o preco ficar maior que a maxima da vela anterior.
     if( m_ask >= m_max_barra_anterior ){
         precoOrdem = m_ask; // se o ask jah passou a maxima da barra anterior, entramos com o preco ask.
     }else{
         precoOrdem = m_max_barra_anterior; // se ask nao passou a maxima da barra anterior, entramos na maxima da barra anterior
     }

     //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
     if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
          Print("MAX_BARRA_ANT=",m_max_barra_anterior,".  Criando ordem de VENDA a ",  precoOrdem, " Volatilidade=",m_volatilidade," ...");
          if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
     }

     //Compra se o preco ficar menor que a minima da vela anterior.
     //Nao abrir posicao se volatilidade for alta.
     if( m_bid <= m_min_barra_anterior ){
        precoOrdem = m_bid; // se o bid jah passou o minimo da barra anterior, entramos com o preco bid.
     }else{
        precoOrdem = m_min_barra_anterior; // se bid nao passou o minimo da barra anterior, entramos no minimo da barra anterior
     }

     //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
     if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
          Print("MIN_BARRA_ANT=",m_min_barra_anterior,".  Criando ordem de COMPRA a ",  precoOrdem, " Volatilidade=",m_volatilidade, " ...");
          if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
     }

}

 
bool volatilidadeEstahAlta (){ return m_volatilidade > EA09_VOLAT_ALTA ;}
bool volatilidadeEstahBaixa(){ return m_volatilidade < EA09_VOLAT_BAIXA;}
//bool volatilidadeEstahMedia(){ return m_volatilidade >  m_volBaixa && m_volatilidade <  m_volBaixa ;}








bool m_fastClose     = true;
bool m_traillingStop = false;
void setFastClose()    { m_fastClose=true ; m_traillingStop=false; m_inclEntrada = m_inclTra;}
void setTraillingStop(){ m_fastClose=false; m_traillingStop=true ;}



// verifica se jah passou um minuto apos o ultimo trade...
bool passouUmMinutoDesdeUltimoTrade(){
    TimeToStruct(TimeCurrent(),m_date);
    if( m_date.min != m_min_ult_trade ) { return true; }
    return true;
}

bool estah_no_intervalo_de_negociacao(){
    TimeToStruct(TimeCurrent(),m_date);
//  TimeToStruct(TimeLocal(),m_date);

    // restricao para nao operar no inicio nem no final do dia...
    if(m_date.hour <   HR_INI_OPERACAO     ) {  return false; } // operacao antes de 9:00 distorce os testes.
    if(m_date.hour >=  HR_FIM_OPERACAO + 1 ) {  return false; } // operacao apos    18:00 distorce os testes.

    if(m_date.hour == HR_INI_OPERACAO && m_date.min < MI_INI_OPERACAO ) { return false; } // operacao antes de 9:10 distorce os testes.
    if(m_date.hour == HR_FIM_OPERACAO && m_date.min > MI_FIM_OPERACAO ) { return false; } // operacao apos    17:50 distorce os testes.

    return true;
}


bool doTraillingStop(){

   double last = m_symb.Last();// m_minion.last(); // preco do ultimo tick;
   double bid  = m_symb.Bid ();
   double ask  = m_symb.Ask ();

   double lenstop  = m_dx1 * EA04_DX_TRAILLING_STOP;
   double   sl  = 0;
   //string m_line_tstop = "linha_stoploss";
   //int tendencia = getEstrategiaTendencia_02();
   //string strTendencia = tendencia == 1?"UP":(tendencia==-1?"DW":"ST");

   if( lenstop < 30 ) lenstop = 30;

   // calculando o trailling stop...
   if( estouComprado() ){
    //sl = last - dxsl;
      sl = bid - lenstop;
      if ( m_tstop < sl || m_tstop == 0 ) {
           m_tstop = sl;
           Print(m_name,":COMPRADO: [OPEN "   ,m_precoPosicao,
                                  "][LENSTOP ",lenstop       ,
                                  "][SL "     ,sl            ,
                                  "][BID "    ,bid            ,
                                  "][m_tstop ",m_tstop,
                                  "][profit " ,m_posicaoProfit,
                                  "][sldstop ",m_tstop-m_precoPosicao,"]");
           //if( !HLineMove(0,m_line_tstop,m_tstop) ){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
           //ChartRedraw(0);
      }
   }else{
      if( estouVendido() ){
         //sl = last + dxsl;
         sl = ask + lenstop;
         if ( m_tstop > sl || m_tstop == 0 ) {
              m_tstop = sl;
              Print(m_name,":VENDIDO: [OPEN ",m_precoPosicao,
                                    "][LENSTOP ",lenstop,
                                    "][SL "     ,sl            ,
                                    "][ASK "    ,ask            ,
                                    "][m_tstop ",m_tstop,
                                    "][profit ",m_posicaoProfit,
                                    "][sldstop ",m_precoPosicao-m_tstop,"]");
              //if( !HLineMove(0,m_line_tstop,m_tstop) ){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
              //ChartRedraw(0);
         }
      }
   }

   //if(!HlineMove(0,m_line_tstop,m_tstop){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
   //if ( !ObjectMove(0,"linha_stoploss",0,0,m_tstop) ){
   //    ObjectCreate(0,"linha_stoploss",OBJ_HLINE,0,0,m_tstop);
   //    ObjectSetInteger(0,"linha_stoploss",OBJPROP_COLOR,clrYellow);
   //}

   // acionando o trailling stop...
   if( ( estouComprado() && m_tstop != 0        )  &&
       ( ( bid < m_tstop && bid > m_precoPosicao ) )
     ){
       Print("TSTOP COMPRADO: bid:"+DoubleToString(bid,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       //HLineDelete(0,m_line_tstop);
       //ChartRedraw(0);

       return true;
   }
   if( ( estouVendido() && m_tstop != 0 ) &&
       ( ( ask > m_tstop && ask < m_precoPosicao ) )
     ){
       Print("TSTOP VENDIDO: ask:"+DoubleToString(ask,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       //HLineDelete(0,m_line_tstop);
       //ChartRedraw(0);

       return true;
   }
   return false;
}

bool doTraillingStop2(){

   m_symb.Refresh();
   m_bb.Refresh(-1);

   double last = m_symb.Last();// m_minion.last(); // preco do ultimo tick;
   double bid  = m_symb.Bid ();
   double ask  = m_symb.Ask ();

   double lenstop  = m_dx1 * EA04_DX_TRAILLING_STOP;
   double sl       = 0;
   double posicaoProfit = 0;

   if( lenstop < 30 ) lenstop = 30;

   // calculando o trailling stop...
   if( m_trade.estouComprado() ){
       sl = bid - lenstop - m_symb.Spread(); // SL eh fixo
       //tstop = sl;         // tstop varia assim que o lucro passar sl

      if ( m_tstop < sl || m_tstop == 0 ) {
           m_tstop = sl;
           Print(m_name,":COMPRADO2: [OPEN "   ,m_precoPosicao,
                                  "][LENSTOP ",lenstop       ,
                                  "][SL "     ,sl            ,
                                  "][BID "    ,bid            ,
                                  "][m_tstop ",m_tstop,
                                  "][profit " ,m_posicaoProfit,
                                  "][sldstop ",m_tstop-m_precoPosicao,"]");
      }
   }else{
      if( m_trade.estouVendido() ){
         sl = ask + lenstop + m_symb.Spread();
         if ( m_tstop > sl || m_tstop == 0 ) {
              m_tstop = sl;
              Print(m_name,":VENDIDO2: [OPEN ",m_precoPosicao,
                                    "][LENSTOP ",lenstop,
                                    "][SL "     ,sl            ,
                                    "][ASK "    ,ask            ,
                                    "][m_tstop ",m_tstop,
                                    "][profit " ,m_posicaoProfit,
                                    "][sldstop ",m_precoPosicao-m_tstop,"]");
         }
      }
   }

   // acionando o trailling stop...
   if( ( estouComprado() && m_tstop != 0        )  &&
       ( ( bid < m_tstop && ask > m_precoPosicao ) )
     ){
       Print("TSTOP2 COMPRADO2: bid:"+DoubleToString(bid,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );
       fecharPosicao("TRLSTP2");

       return true;
   }
   if( ( estouVendido() && m_tstop != 0 ) &&
       ( ( ask > m_tstop && ask < m_precoPosicao ) )
     ){
       Print("TSTOP2 VENDIDO2: ask:"+DoubleToString(ask,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );
       fecharPosicao("TRLSTP2");

       return true;
   }
   return false;
}

double normalizar(double preco){  return m_symb.NormalizePrice(preco); }

bool precoPosicaoAbaixoDaMedia(){ return m_precoPosicao < m_bb.Base(0) ;}
bool precoPosicaoAcimaDaMedia (){ return m_precoPosicao > m_bb.Base(0) ;}

bool precoNaMedia             (){ return m_symb.Last() < m_bb.Base(0) + m_tick_size &&
                                         m_symb.Last() > m_bb.Base(0) - m_tick_size    ;}

bool precoNaBandaInferior     (){ return m_symb.Ask() < m_bb.Lower(0) + m_tick_size &&
                                         m_symb.Ask() > m_bb.Lower(0) - m_tick_size    ;}

bool precoAbaixoBandaInferior (){ return m_symb.Ask() < m_bb.Lower(0) + m_tick_size;}

bool precoNaBandaSuperior     (){ return m_symb.Bid() < m_bb.Upper(0) + m_tick_size &&
                                         m_symb.Bid() > m_bb.Upper(0) - m_tick_size    ;}

bool precoAcimaBandaSuperior  (){ return m_symb.Bid() > m_bb.Upper(0) - m_tick_size;}

void fecharPosicao (string comentario){ m_trade.fecharQualquerPosicao (comentario); setSemPosicao(); }
void cancelarOrdens(string comentario){ m_trade.cancelarOrdens(comentario); setSemPosicao(); }

void setCompradoSoft(){ m_comprado = true ; m_vendido = false; }
void setVendidoSoft() { m_comprado = false; m_vendido = true ; }
void setComprado()    { m_comprado = true ; m_vendido = false; m_tstop = 0;}
void setVendido()     { m_comprado = false; m_vendido = true ; m_tstop = 0;}
void setSemPosicao()  { m_comprado = false; m_vendido = false; m_tstop = 0;}

bool estouComprado(){ return m_comprado; }
bool estouVendido (){ return m_vendido ; }

string status(){
   string obs =
         //" preco="       + m_tick.ask                         +
         //" bid="         + m_tick.bid                         +
         //" spread="      + (m_tick.ask-m_tick.bid)            +
           " last="        + DoubleToString( m_symb.Last() )
         //" time="        + m_tick.time
         ;
   return obs;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {
    EventKillTimer();
    m_feira.DeleteFromChart(0,0);
    IndicatorRelease( m_feira.Handle() );
    //IndicatorRelease( m_bb.Handle()    );
    return;
}


void escreverLogAfterNewBar(string msg){
    MqlDateTime mdt;
    TimeToStruct(TimeCurrent(),mdt);
    //if(estah_no_intervalo_de_negociacao()) { m_minion.logWriteAfterNewBar(msg); }
}

void escreverLog(string msg){
    MqlDateTime mdt;
    TimeToStruct(TimeCurrent(),mdt);
    //if(estah_no_intervalo_de_negociacao()) { m_minion.logWrite(msg); }
}

//+-----------------------------------------------------------+
//| Lucro da ultima transacao                                 |
//+-----------------------------------------------------------+
//void OnTradeTransaction() {
//   printf("ACCOUNT_BALANCE =  %G",AccountInfoDouble(ACCOUNT_BALANCE));
//   printf("ACCOUNT_CREDIT  =  %G",AccountInfoDouble(ACCOUNT_CREDIT));
//   printf("ACCOUNT_PROFIT  =  %G",AccountInfoDouble(ACCOUNT_PROFIT));
//   printf("ACCOUNT_EQUITY  =  %G",AccountInfoDouble(ACCOUNT_EQUITY));
//}

void OnTrade() {
    //Print(m_name,": ACCOUNT_BALANCE    = ",AccountInfoDouble(ACCOUNT_BALANCE));
    //Print(m_name,": ACCOUNT_PROFIT     = ",AccountInfoDouble(ACCOUNT_PROFIT));
    //Print(m_name,": ACCOUNT_EQUITY     = ",AccountInfoDouble(ACCOUNT_EQUITY));
}


