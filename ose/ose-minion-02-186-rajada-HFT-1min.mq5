//+------------------------------------------------------------------+
//|                            ose-minion-02-186-rajada-HFT-1min.mq5 |
//|                                         Copyright 2019, OS Corp. |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao 2.186                                                     |
//| 1. Fork da versao 2.086 feito em 30/11/2019.                     |
//|                                                                  |
//| 02-186 Eliminado o parametro EA03_FECHAR_RAJADA, pois as rajadas |
//|        sempre sao fechadas apos o fechamento da posicao.         |
//|                                                                  |
//| 02-186 Eliminado o parametro EA09_VOLAT_BAIXA, que ainda nao eh  |
//|        usado.                                                    |
//| 02-186 Transformado o parametro EA01_MAX_VOL_EM_RISCO em         |
//|        constante.                                                |
//|                                                                  |
//| 02-186 Novo parametro EA_SPREAD_MAXIMO. Se passar desse spread   |
//|        nao abre novas posicoes. VAlor em ticks.                  |
//|                                                                  |
//| 02-186 Novo parametro EA_SHOW_TELA. Se true, mostra variaveis na |
//|        tela. Desabilite quando operar no VPS.                    |
//|                                                                  |
//| X. Usar indicador feira para saber a volatilidade em funcao do   |
//|    volume (pendente).                                            |
//|                                                                  |
//| 02-086 Correcao da saida por qtd EA_STOP_QTD_CONTRAT.            |
//|    Nao considerava o volume da primeira transacao ao contar as   |
//|    transacoes da posicao. Aparece sempre que uma das transacoes  |
//|    da posicao for maior que 1.                                   |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "2.186"

#include <Indicators\Trend.mqh> 
#include <Indicators\Volumes.mqh> 
#include <Indicators\Oscilators.mqh> 
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
     NAO_OPERAR                           = 0,
     FECHAR_POSICAO                       = 1,
     FECHAR_POSICAO_POSITIVA              = 2,
     NAO_ABRIR_POSICAO                    = 3,
     CONTRA_TEND_DURANTE_COMPROMETIMENTO  = 4,
     CONTRA_TEND_APOS_COMPROMETIMENTO     = 5,
     CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR = 6,
     HFT_DISTANCIA_PRECO                  = 7,
     HFT_MAX_MIN_VOLATILIDADE             = 8,
     HFT_TEND_CCI                         = 9,
     HFT_NA_TENDENCIA                     = 10,
     HFT_NORTE_SUL                        = 11 // coloca as ordens de entrata e saida em paralelo.
};

//---------------------------------------------------------------------------------------------
input string S01                    =  ""         ; //==== PARAMETROS GERAIS ====
input ENUM_TIPO_OPERACAO EA07_ABRIR_POSICAO = FECHAR_POSICAO ; //EA07_ABRIR_POSICAO:Forma de operacao do EA.
input double EA_SPREAD_MAXIMO         =  4        ; //EA_SPREAD_MAXIMO em ticks. Se for maior que o maximo, nao abre novas posicoes.
input double EA03_PASSO_RAJADA        =  1        ; //EA03_PASSO_RAJADA:Incremento de preco, em tick, na direcao contraria a posicao;
input int    EA02_QTD_TICKS_4_GAIN    =  5        ; //EA02_QTD_TICKS_4_GAIN:Quantidade de ticks para o gain em cada transacao;
input double EA05_VOLUME_LOTE_INI     =  2        ; //Vol do lote a ser usado na abertura de posicao.
input double EA05_VOLUME_LOTE_RAJ     =  1        ; //Tamanho do lote a ser usado nas rajadas.
input int    EA10_TICKS_ENTRADA_HTF   =  1        ; //TICKS_ENTRADA_HTF:Usado na entrada tipo HFT_DISTANCIA_PRECO. Distancia do preco para entrar na proxima posicao; .
//
input int    EA07_TICKS_STOP_LOSS     =  25       ; //EA07_TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
input double EA_REBAIXAMENTO_MAX      =  0        ; //EA_REBAIXAMENTO_MAX: Rebaixamento maximo de saldo aceitavel desde a entrada na sessao.
input double EA07_STOP_LOSS           = -1200     ; //EA07_STOP_LOSS:Valor maximo de perda aceitavel;
input double EA_STOP_QTD_CONTRAT      =  10       ; //EA_STOP_QTD_CONTRAT: Fecha posicao positiva se tiver qtd contratos na posicao for maior que este numero. A forma de fechar, depende dos dois proximos parametros.
input double EA_STOP_PORC_CONTRAT     =  0.0001   ; //Porcentagen de contratos pendentes em relacao aos contratos totais para fechar a posicao.
input double EA_STOP_GAIN_PORC_L1     =  3        ; //STOP_GAIN_PORC_L1:Porc qtd contratos da posicao em reais para a saida;
input double EA_STOP_GAIN_PORC_L2     =  0        ; //STOP_GAIN_VALO_L2:Valor de gain em reais para saida;
input double EA_STOP_LOSS_PORC_L3     =  0.25     ; //STOP_LOSS_PORC_L3:Porc stoploss para saida;
input double EA_STOP_LOSS_PORC_L4     =  0.50     ; //STOP_LOSS_PORC_L4:Porc stoploss para saida;
input long   EA_10MINUTOS             =  0        ; //EA_10MINUTOS: fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
//
input double EA_VOLAT_ALTA            =  0.4      ; //EA_VOLAT_ALTA : Volatilidade a considerar alta(%).
input int    EA_VOLSEG_ALTO           =  200      ; //EA_VOLSEG_ALTO: Volume de contratos por segundo que eh considerado alto.
input double EA_INCL_ALTA             =  0.9      ; //EA_INCL_ALTA  : Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
input double EA_INCL_MIN              =  0.08     ; //EA_INCL_MIN   : Inclinacao minima para entrar no trade.
//
input bool   EA_SHOW_TELA             =  true     ; //EA_SHOW_TELA:mostra valor de variaveis na tela;
input int    EA08_MAGIC               =  191102186; //Numero magico desse EA. yymmvvvvv.

//input double EA09_VOLAT_BAIXA       =  0.2      ; //Volatilidade a considerar baixa(%).
//input double EA09_VOLAT_MEDIA       =  0.7      ; //Volatilidade a considerar media(%).
//input double EA09_INCL_MAX_IN       =  0.5      ; //EA09_INCL_MAX_IN:Inclinacao max p/ entrar no trade.
//input bool   EA01_DEBUG             =  false    ; //EA01_DEBUG:se true, grava informacoes de debug no log do EA.
//input double EA04_DX_TRAILLING_STOP =  1.0      ; //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
//input double EA10_DX1               =  0.2      ; //EA10_DX1:Tamanho do DX em relacao a banda em %;
//input double EA01_MAX_VOL_EM_RISCO  =  200      ; //EA01_MAX_VOL_EM_RISCO:Qtd max de contratos em risco; Sao os contratos pendentes da posicao.

#define EA01_MAX_VOL_EM_RISCO   200        //EA01_MAX_VOL_EM_RISCO:Qtd max de contratos em risco; Sao os contratos pendentes da posicao.
#define EA01_DEBUG              false      //EA01_DEBUG:se true, grava informacoes de debug no log do EA.
#define EA04_DX_TRAILLING_STOP  1.0        //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
#define EA10_DX1                0.2        //EA10_DX1:Tamanho do DX em relacao a banda em %;

//---------------------------------------------------------------------------------------------
// configurando a feira...
input string S03                         = ""    ; //==== INDICADOR FEIRA ====
//input bool   FEIRA01_DEBUG             = false ; // se true, grava informacoes de debug no log.
input bool     FEIRA02_GERAR_VOLUME      = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input bool     FEIRA03_GERAR_OFERTAS     = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
//input int    FEIRA04_QTD_BAR_PROC_HIST = 0     ; // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
//input double FEIRA05_BOOK_OUT          = 0     ; // Porcentagem das extremidades dos precos do book que serão desprezados.
input int      FEIRA06_QTD_PERIODOS      = 1     ; // Quantidade de barras que serao acumulads para calcular as medias.
//input bool   FEIRA99_ADD_IND_2_CHART   = true  ; // Se true apresenta o idicador feira no grafico.

#define FEIRA01_DEBUG             false  // se true, grava informacoes de debug no log.
#define FEIRA04_QTD_BAR_PROC_HIST 0      // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
#define FEIRA05_BOOK_OUT          0      // Porcentagem das extremidades dos precos do book que serão desprezados.
#define FEIRA99_ADD_IND_2_CHART   true   // Se true apresenta o idicador feira no grafico.

//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
input string S04               = ""; //==== HORARIO DE OPERACAO ====
input int    HR_INI_OPERACAO   = 09; // Hora   de inicio da operacao;
input int    MI_INI_OPERACAO   = 30; // Minuto de inicio da operacao;
input int    HR_FIM_OPERACAO   = 17; // Hora   de fim    da operacao;
input int    MI_FIM_OPERACAO   = 50; // Minuto de fim    da operacao;
//---------------------------------------------------------------------------------------------

CiBands*      m_ibb;
CiCCI*        m_icci;
CiAD*         m_iad;
CiMFI*        m_imfi;
CiMA*         m_ima;

MqlDateTime   m_date;
string        m_name = "MINION-02-186-RAJADA-HFT-1MIN";
CSymbolInfo   m_symb                          ;
CPositionInfo m_posicao                       ;
CAccountInfo  m_cta                           ;
double        m_tick_size                     ;// alteracao minima de preco.
double        m_shift                         ;// valor do fastclose;
double        m_stopLoss                      ;// stop loss;
double        m_distMediasBook                ;// Distancia entre as medias Ask e Bid do book.

osc_minion_trade       m_trade;
osc_ind_minion_feira*  m_feira;

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
double m_posicaoVolume       = 0; // volume da posicao atual
double m_posicaoVolumeTot    = 0; // volume total de contratos da posicao, inclusive os que jah foram fechados
long   m_positionId          = 0;
int    m_qtdComprasNaPosicao = 0; // quantidade de compras na posicao atual;
int    m_qtdVendasNaPosicao  = 0; // quantidade de vendas  na posicao atual;
double m_capitalInicial      = 0; // capital justamente antes de iniciar uma posicao
double m_capitalLiquido      = 0; // capital atual durante a posicao.
double m_lucroPosicao        = 0; // lucro da posicao atual
double m_lucroPosicao4Gain   = 0; // lucro para o gain caso a quantidade de contratos tenha ultrapassado o valor limite.
double m_lucroStops          = 0; // lucro acumulado durante stops de quantidade

double m_tstop                  = 0;
string m_positionCommentStr     = "0";
long   m_positionCommentNumeric = 0;

//--- variaveis atualizadas pela funcao refreshMe...
double m_med           = 0;//normalizar( m_ibb.Base(0)  ); // preco medio das bandas de bollinguer
double m_inf           = 0;//normalizar( m_ibb.Lower(0) ); // preco da banda de bollinger inferior
double m_sup           = 0;//normalizar( m_ibb.Upper(0) ); // preco da banda de bollinger superior
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

string   m_apmb       = "APMB"    ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_sel   = "APMBSELL"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_buy   = "APMBBUY" ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_ns    = "APMB_NS" ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
MqlRates m_rates[];

string   m_comment_fixo;
string   m_comment_var;

double m_razaoVolReal = 0;
double m_razaoVolTick = 0;

int    m_qtd_erros        = 0;
double m_sld_sessao_ini   = 0;
double m_sld_sessao_atu   = 0;
double m_rebaixamento_atu = 0;
int    m_day              = 0;
bool   m_mudou_dia        = false;
bool   m_acionou_stop_rebaixamento_saldo = false;
double m_spread_maximo    = 0;

int    m_ganhos_consecutivos = 0;
int    m_perdas_consecutivas = 0;
long   m_tempo_posicao_atu   = 0;
long   m_tempo_posicao_ini   = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()  {

    printf("***** Iniciando " + m_name + ":" + IntegerToString(EA08_MAGIC) + " as " + TimeToString( TimeCurrent() ) +"... ******");

    m_symb.Name                  ( Symbol() );
    m_symb.Refresh               (); // propriedades do simbolo. Basta executar uma vez.
    m_symb.RefreshRates          (); // valores do tick. execute uma vez por tick.
    m_tick_size    = m_symb.TickSize(); //Obtem a alteracao minima de preco
    m_shift        = m_symb.NormalizePrice(EA02_QTD_TICKS_4_GAIN*m_tick_size);
    m_stopLoss     = m_symb.NormalizePrice(EA07_TICKS_STOP_LOSS *m_tick_size);
    m_trade.setMagic   (EA08_MAGIC);
    m_trade.setStopLoss(m_stopLoss);
    m_trade.setTakeProf(m_stopLoss);
    ArraySetAsSeries(m_rates,true);
    //m_spread_maximo = EA_SPREAD_MAXIMO;
    m_spread_maximo = EA_SPREAD_MAXIMO*m_tick_size;
    
    m_sld_sessao_ini = m_cta.Balance(); // saldo da conta no inicio da sessao;
    m_sld_sessao_atu = m_cta.Balance();
    m_capitalInicial = m_cta.Balance();
    
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
    //m_ibb = new CiBands();
    //if ( !m_ibb.Create(_Symbol         , //string           string,        // Symbol
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

    // inicializando CCI...
    m_icci = new CiCCI();
    if ( !m_icci.Create(_Symbol          , //string          string,        // Symbol
                         PERIOD_CURRENT  , //ENUM_TIMEFRAMES  period,        // Period
                        14, //BB_QTD_PERIODO_MA, //int              ma_period,     // Averaging period
                        PRICE_MEDIAN       //int              applied        // (máximo + mínimo)/2 (see ENUM_APPLIED_PRICE)
                       )
        ){
        Print(m_name,": Erro inicializando o indicador CCI :-(");
        return(1);
    }

    // inicializando a feira...
    m_feira = new osc_ind_minion_feira();
    if( ! m_feira.Create(  m_symb.Name(),PERIOD_CURRENT           ,
                                         FEIRA01_DEBUG            ,
                                         FEIRA02_GERAR_VOLUME     ,
                                         FEIRA03_GERAR_OFERTAS    ,
                                         FEIRA04_QTD_BAR_PROC_HIST,
                                         FEIRA05_BOOK_OUT         ,
                                         FEIRA06_QTD_PERIODOS     ,
                                         IFEIRA_VERSAO_0206       )   ){
        Print(m_name,": Erro inicializando o indicador FEIRA :-( ", GetLastError() );
        return(1);
    }
    
    //m_trade.setAsync(true); Print(":-| Ordens serao executadas em modo assincrono.");
    
    //Print(m_name,":-| Aguardando 5 seg antes de colocar o indicador feira no grafico... " );
    //Sleep (5000);
    
    // adicionando FEIRA ao grafico...
    if( FEIRA99_ADD_IND_2_CHART ){ m_feira.AddToChart(0,0); }
    
    //Print(m_name,":-| Aguardando 5 seg apos colocar o indicador feira no grafico... " );
    //Sleep (5000);

    Print(m_name,":-) Expert ", m_name, " inicializado !! " );
    return(0);
}

double m_len_canal_ofertas = 0; // tamanho do canal de oefertas do book.
double m_len_barra_atual   = 0; // tamanho da barra de trades atual.
double m_volatilidade      = 0; // calculamos a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
double m_ticks_por_segundo = 0; // volume do ultimo minuto (entregue pelo feira) divido por 60.
void refreshMe(){
    m_posicao.Select( m_symb.Name() );
    m_symb.RefreshRates();
    m_feira.Refresh();

    //m_ibb.Refresh (-1);
    //m_ima.Refresh (-1);
    m_icci.Refresh(-1);
    //m_iad.Refresh (-1);
    //m_imfi.Refresh(-1);
    

    m_trade.setStopLoss( m_stopLoss        );
    m_trade.setVolLote ( m_symb.LotsMin()  );

    m_ask = m_symb.Ask();
    m_bid = m_symb.Bid();

    // atualizando maximo, min e tamnaho das barras anterior de preco atual e anterior...
    CopyRates(m_symb.Name(),_Period,0,2,m_rates);
    m_max_barra_anterior = m_rates[1].high;
    m_min_barra_anterior = m_rates[1].low ;

    //m_med = normalizar( m_ibb.Base(0)  ); // preco medio das bandas de bollinguer
    //m_inf = normalizar( m_ibb.Lower(0) ); // preco da banda de bollinger inferior
    //m_sup = normalizar( m_ibb.Upper(0) ); // preco da banda de bollinger superior
    //m_bdx = MathAbs   ( m_sup-m_med   ); // distancia entre as bandas de bollinger e a media, sem sinal;
    //m_dx1 = normalizar( EA10_DX1*m_bdx); // normalmente 20% da distancia entre a media e uma das bandas.

    m_qtdOrdens           = OrdersTotal();
    m_qtdPosicoes         = PositionsTotal();
    m_qtdComprasNaPosicao = 0;
    m_qtdVendasNaPosicao  = 0;

    
    // adminstrando posicao aberta...
    if( m_qtdPosicoes > 0 ){
      //m_posicaoProfit = 0;
        if ( PositionSelect  (m_symb.Name()) ){ // soh funciona em contas hedge
      //if ( m_posicao.Select(m_symb.Name()) ){ // soh funciona em contas hedge
            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                setCompradoSoft();
            }else{
                setVendidoSoft();
            }
            m_posicaoProfit          = PositionGetDouble (POSITION_PROFIT     );
            m_precoPosicao           = PositionGetDouble (POSITION_PRICE_OPEN );
            m_posicaoVolume          = PositionGetDouble (POSITION_VOLUME     );
            m_positionId             = PositionGetInteger(POSITION_IDENTIFIER );
            m_positionCommentStr     = PositionGetString (POSITION_COMMENT    );
            m_positionCommentNumeric = StringToInteger   (m_positionCommentStr);
            m_capitalLiquido         = m_cta.Equity();
            m_lucroPosicao           = m_capitalLiquido - m_capitalInicial;

            // se o comentario da posicao for numerico, precisamos saber pois trata-se de um engano e deveremos fechar a posicao e todas as ordens.
            //if( !MathIsValidNumber(m_positionCommentNumeric) ) m_positionCommentNumeric = 0; 
            
            contarTransacoesDaPosicao();
            if( estouComprado() ) m_posicaoVolumeTot = m_qtdComprasNaPosicao;
            if( estouVendido () ) m_posicaoVolumeTot = m_qtdVendasNaPosicao ;
            m_lucroPosicao4Gain = (m_posicaoVolumeTot*EA_STOP_GAIN_PORC_L1);

            if( m_tempo_posicao_ini == 0 ) m_tempo_posicao_ini = TimeCurrent();
            m_tempo_posicao_atu = TimeCurrent() - m_tempo_posicao_ini;
        }else{
           // aqui neste bloco, estah garantido que nao ha posicao aberta...
           m_capitalInicial    = m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
           m_comprado          = false;
           m_vendido           = false;
           m_lucroPosicao      = 0;
           m_lucroPosicao4Gain = 0;
           m_posicaoVolume     = 0; //versao 02-085
           m_posicaoProfit     = 0;
           m_posicaoVolumeTot  = 0;
           m_val_order_4_gain  = 0; // zerando o valor da primeira ordem da posicao...
           m_tempo_posicao_atu = 0;
           m_tempo_posicao_ini = 0;
        }
    }else{
        // aqui neste bloco, estah garantido que nao ha posicao aberta...
        m_capitalInicial  = m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
        m_comprado = false;
        m_vendido  = false;
        m_lucroPosicao      = 0;
        m_lucroPosicao4Gain = 0;
        m_posicaoVolume     = 0; //versao 02-085
        m_posicaoProfit     = 0;
        m_posicaoVolumeTot  = 0;
        m_val_order_4_gain  = 0; // zerando o valor da primeira ordem da posicao...
        m_tempo_posicao_atu = 0;
        m_tempo_posicao_ini = 0;
        
        //bool m_ganhou_ultimo_trade = false;
        // administrando ganhos e perdas consecutivas...
        // primeira passagem apos o encerramento de uma posicao
        //if(  m_cta.Balance() > m_capitalInicial && m_capitalInicial != 0 ){
        //   m_ganhos_consecutivos++;
        //   m_perdas_consecutivas = 0;
        //   //m_ganhou_ultimo_trade = true;

        //}else if(m_cta.Balance() < m_capitalInicial && m_capitalInicial != 0){
        //   m_perdas_consecutivas++;
        //   m_ganhos_consecutivos = 0;
        //   //m_ganhou_ultimo_trade = false;
        //}
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
   
   // ticks por segundo. medida de volatilidade
   m_ticks_por_segundo = m_feira.getVolTrade(0)/60.0;
   
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

   if (EA_SHOW_TELA){
       m_comment_var = 
                       "  CTA SLD:"      + DoubleToString(m_cta.Balance()    ,2      ) + 
                       "  CAPLIQ: "      + DoubleToString(m_cta.Equity()     ,2      ) + 
                       "  VAL_GAIN:"     + DoubleToString(m_val_order_4_gain ,_Digits) +
                       "\n" + strPosicao() +                       
                       "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"+
                       "\n\n\n\n\n\n\n\n\n\n"+
                       //"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"+
                //       "\nABRIR_POSICAO:"    +                EA07_ABRIR_POSICAO             +
                //       "  MAX_VOL_EM_RISCO:" + DoubleToString(EA01_MAX_VOL_EM_RISCO,_Digits) + 
                //       "  MAX_REBAIX_SLD:"   + DoubleToString(EA_REBAIXAMENTO_MAX  ,0      ) +
                //       "  TICKS_STOP_LOSS:"  + DoubleToString(EA07_TICKS_STOP_LOSS ,0      ) +
                //       "  TICK_SIZE:"        + DoubleToString(m_symb.TickSize() ,_Digits     ) +
                //       "  TICK_VALUE:"       + DoubleToString(m_symb.TickValue(),_Digits     ) +
                //       "  POINT:"            + DoubleToString(m_symb.Point()    ,_Digits     ) +
                       
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
                       "\nVOLSEG/MAX: "+ DoubleToString(m_ticks_por_segundo   ,0           ) + "/" + IntegerToString(EA_VOLSEG_ALTO  ) + 
                       "  VOLAT/MAX: " + DoubleToString(m_volatilidade        ,2           ) + "/" + DoubleToString (EA_VOLAT_ALTA ,2) +
                       "  SPREAD/MAX: "+ DoubleToString(m_symb.Spread()       ,_Digits     ) +
                       "/"             + DoubleToString(m_spread_maximo       ,_Digits     ) +
                       "  INCLI/MAX: " + DoubleToString(m_inclTra             ,2           ) + "/" + DoubleToString(EA_INCL_ALTA   ,2) +
                       " CCI ANT/ATU/DIF: " + DoubleToString(m_icci.Main(1),2)+"/"+
                                              DoubleToString(m_icci.Main(0),2)+"/"+
                                              DoubleToString((m_icci.Main(0)-m_icci.Main(1)),2)+
                        //
                       "  VOLTOT: "    + DoubleToString(m_feira.getVolTrade(0),2) + 
                       //
                       "\nPROFIT/4GAIN/LOSS: " + DoubleToString(m_lucroPosicao     ,0      ) +"/"+
                                                 DoubleToString(m_lucroPosicao4Gain,0      ) +"/"+ 
                                                 DoubleToString(EA07_STOP_LOSS     ,_Digits) + 
                       "  VOL PEN/TOT: "       + DoubleToString(m_posicaoVolume    ,_Digits) + "/"+ 
                                                 DoubleToString(m_posicaoVolumeTot ,_Digits) +
                       "  m_posicaoProfit: " + DoubleToString(m_posicaoProfit,2)+
                       "  PROFIT:"           + DoubleToString(m_cta.Profit(),2) +
                       "  " + (m_qtdPosicoes==0?"SEM POSICAO":estouComprado()?"COMPRADO":"VENDIDO") +
                       
                       
                       "\nQTD_OFERTAS: "   + IntegerToString(m_symb.SessionDeals()        )+
                       "  OPEN:"           + DoubleToString (m_symb.SessionOpen (),_Digits)+
                       "  VWAP:"           + DoubleToString (m_symb.SessionAW   (),_Digits)+
                       "  DATA:"           + TimeToString   (TimeCurrent()                )+
                       "  MIN:"            + TimeToString   (TimeCurrent(),TIME_MINUTES   )+
                       "  SEG:"            + TimeToString   (TimeCurrent(),TIME_SECONDS   )+
                       "  TEMPO_POSICAO:"  + IntegerToString(m_tempo_posicao_atu)          ;
                       
     

       /*
        TimeToStruct(TimeCurrent(),m_date);
        int min = (m_date.hour - 9 )*60 + 
                   m_date.min           ;  
        int seg = (min*60) + m_date.sec ;  
        //if( m_date.min != m_min_ult_trade ) { return true; }
        //return true;
        int mediaOfertasMin = m_symb.SessionDeals()/min;
        int mediaOfertasSeg = m_symb.SessionDeals()/seg;
        
        double tickVolume2      = m_rates[0].tick_volume==0?1:m_rates[0].tick_volume; 
        double realVolume2      = m_rates[0].real_volume==0?1:m_rates[0].real_volume; 
        double mediaOfertasSeg2 = mediaOfertasSeg       ==0?1:mediaOfertasSeg;
        double seg2             = m_date.sec            ==0?1:m_date.sec;
        
        double razaoVolReal = realVolume2/(mediaOfertasSeg2*seg2);
        double razaoVolTick = tickVolume2/(mediaOfertasSeg2*seg2);
        
        m_razaoVolTick = razaoVolTick;
        m_razaoVolReal = razaoVolReal;
        
        
        string comment_data = "\n QTD_MIN:" + min +
                                " QTD_SEG:" + seg +
                                " QTD_OFERTA_MEDIA_MIN:" + mediaOfertasMin +
                                " QTD_OFERTA_MEDIA_SEG:" + mediaOfertasSeg +
                                " QTD_OFERTA_JUSTA_NOW:" + mediaOfertasSeg*m_date.sec +
                                "/"                      + m_rates[0].real_volume     +
                                " RVOL:"                 + DoubleToString(razaoVolReal,2) +
                                " TVOL:"                 + DoubleToString(razaoVolTick,2);
                              ;
       Comment(m_comment_fixo + m_comment_var + comment_data);
       */
                       
       Comment(m_comment_fixo + m_comment_var );
   }
}

//
// conta as transacoes da posicao atual; Estas transacoes ficam atualizadas
// nas variaveis m_qtdComprasNaPosicao e m_qtdVendasNaPosicao;
//
void contarTransacoesDaPosicao(){
   HistorySelectByPosition(m_positionId); // recuperando ordens e transacoes da posicao atual no historico...
   int    deals = HistoryDealsTotal()      ; // quantidade de ordens na posicao
   long   deal_ticket;
   long   deal_type;
   double deal_vol; // versao 02-086
   m_qtdComprasNaPosicao = 0;
   m_qtdVendasNaPosicao  = 0;
   
   for(int i=0;i<deals;i++) {  // selecionando as tranacoes (entradas e saidas) para processamento...

      deal_ticket = HistoryDealGetTicket(i);
      deal_type   = HistoryDealGetInteger(deal_ticket,DEAL_TYPE);
      deal_vol    = HistoryDealGetDouble (deal_ticket,DEAL_VOLUME); // versao 02-086

      switch(deal_type){
         case DEAL_TYPE_SELL: m_qtdVendasNaPosicao  += deal_vol; break; // versao 02-086
         case DEAL_TYPE_BUY : m_qtdComprasNaPosicao += deal_vol; break; // versao 02-086
      }
   }
}   

void calcularTempoPosicao(){
   
}   

void fecharTudo(string descr){
      // se tem posicao ou ordem aberta, fecha.
      if( m_qtdPosicoes > 0 ){ m_trade.fecharQualquerPosicao(descr); Sleep(SLEEP_PADRAO);}
      if( m_qtdOrdens   > 0 ){ m_trade.cancelarOrdens       (descr);                     }

}

void fecharTudo(string descr, string strLog){

      //m_trade.setAsync(true);
      // se tem posicao ou ordem aberta, fecha.
      if( m_qtdOrdens   > 0 ){ 
          Print("HFT_FECHAR_TUDO_ORDENS: ", strLog, strPosicao());
          m_trade.cancelarOrdens(descr);
      }
      
      if( m_qtdPosicoes > 0 ){ 
          Print("HFT_FECHAR_TUDO_POSICAO: ", strLog, strPosicao());
          m_trade.fecharQualquerPosicao(descr); 
          Sleep(SLEEP_PADRAO);
      }   
      //m_trade.setAsync(false);

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
    refreshMe();
    
    // Esta opcao NAO_OPERAR nao interfere nas ordens...
    if( EA07_ABRIR_POSICAO == NAO_OPERAR ) return;

    if( !estah_no_intervalo_de_negociacao() ) { fecharTudo("INTERVALO"); return; }// posicao aberta fora do horario

    // mudou o dia, atualizamos o saldo da sessao...
    if( m_mudou_dia ){ m_sld_sessao_ini = m_cta.Balance(); m_mudou_dia = false; }

    // saldo da conta subiu, atualizamos o saldo da sessao pra controle do rebaixamento maximo do dia.
    if( m_sld_sessao_atu > m_sld_sessao_ini ){ 
        m_sld_sessao_ini = m_sld_sessao_atu;
    }else{
        m_rebaixamento_atu = m_sld_sessao_ini - m_sld_sessao_atu; // se houver rebaixamento, esse numero fica positivo;
    }
    
    // saldo da conta rebaixou mais que o permitodo pra sessao.
    if ( m_rebaixamento_atu  != 0  &&
         EA_REBAIXAMENTO_MAX != 0  &&
         EA_REBAIXAMENTO_MAX  < m_rebaixamento_atu ){

         if( !m_acionou_stop_rebaixamento_saldo ){ // eh pra nao fical escrevendo no log ateh a sessao seguinte caso rebaixe o saldo.
              Print(":-( Acionando STOP_REBAIXAMENTO_DE_CAPITAL. ", strPosicao() ); 
              fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return; 
              m_acionou_stop_rebaixamento_saldo = true;
         }
    } 
    
    if ( m_qtdPosicoes > 0 ) {
    
         // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
         if( EA07_ABRIR_POSICAO == FECHAR_POSICAO                                 ) { fecharTudo("OPCAO_FECHAR_POSICAO"         ,"OPCAO_FECHAR_POSICAO"         ); return; } 
         if( EA07_ABRIR_POSICAO == FECHAR_POSICAO_POSITIVA && m_posicaoProfit > 0 ) { fecharTudo("OPCAO_FECHAR_POSICAO_POSITIVA","OPCAO_FECHAR_POSICAO_POSITIVA"); return; } 
     
         // se tem posicao aberta, cancelamos as ordens apmb que porventura tenham ficado abertas
         m_trade.cancelarOrdensComentadas(m_apmb);

       //if( m_posicaoProfit < EA07_STOP_LOSS ){
         if( m_lucroPosicao  < EA07_STOP_LOSS && m_capitalInicial != 0 ){          
             Print(":-( Acionando STOPLOSS. ", strPosicao() );
             fecharTudo("STOP_LOSS"); 
             return;
         }

         // Este trecho salvou de perder uma posicao de 30 contratos no final do dia 20191121...
         // Entao pense bem antes alterar aqui !!!!!!
         //if( m_qtdOrdens > 5 && m_posicaoProfit >= 10 && volatilidadeEstahAltaDemais() ){ 
         //if( m_qtdOrdens > 5 && volatilidadeEstahAltaDemais() ){
         //    Print(":-| Acionando STOPVOLATILIDADE_X_QTD.", strPosicao() );
         //    fecharTudo("STOP_VOLATILIDADE"); 
         //    return;
         //}
         
         if( emLeilao() ){ 
             Print(":-| Acionando STOPLEILAO.", strPosicao() );
             fecharTudo("STOP_LEILAO"); 
             return;
         }
         
         
         // STOP se tiver mais de XX contratos na posicao.
         //if(    m_posicaoVolumeTot > EA_STOP_QTD_CONTRAT 
         //    && m_capitalInicial   > 0  // deixe isso aqui, senao dah merda na inicializacao, hehe
         //  //&& m_capitalLiquido > m_capitalInicial
         //  //&& m_lucroPosicao     > 0
         //    && m_lucroPosicao     > (m_posicaoVolumeTot*0.33) //*m_tick_size;
         //  ){
         //    Print(":-| Acionando STOP_QTD_CONTRATOS_14.", strPosicao() );
         //    m_lucroStops += m_lucroPosicao;
         //    fecharTudo("STOP_QTD_14"); 
         //    return;
         //}

         // STOP se faltar menos de 20% dos contratos totais pra fechar a posicao.
         if(    m_capitalInicial   != 0  // deixe isso aqui, senao dah merda na inicializacao, hehe
             && m_posicaoVolumeTot  > EA_STOP_QTD_CONTRAT 
             && m_posicaoVolume     > 0                  
           //&& ( m_posicaoVolume/m_posicaoVolumeTot < EA_STOP_PORC_CONTRAT ) //0.15
           ){
         
                 if( m_posicaoVolume/m_posicaoVolumeTot < EA_STOP_PORC_CONTRAT ){
                     Print(":-| Acionando STOP_QTD_PORC_CONTRATOS.", strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_QTD_PORC_CONTRATOS"); 
                     return;
                 }
    
                 //+----------------------------------------------------------------------------------------------------
                 // 1. se a quantidade de contratos pendentes estah maior que 1x o inicio do stop, a tolerancia eh (1), a qtd de contratos totais;
                 // 2. se a quantidade de contratos pendentes estah maior que 2x o inicio do stop, muda a tolerancia para 0;
                 // 3. se a quantidade de contratos pendentes estah maior que 3x o inicio do stop, muda a tolerancia para 1/4 do stoploss (125);
                 // 4. se a quantidade de contratos pendentes estah maior que 4x o inicio do stop, muda a tolerancia para 1/2 do stoploss (250);
                 //+----------------------------------------------------------------------------------------------------
                 // 1. se a quantidade de contratos pendentes estah maior que 1x o inicio do stop, a tolerancia eh (1), a qtd de contratos totais;
                 if( m_lucroPosicao > m_lucroPosicao4Gain     ){ // testando o ganho obtido com o calculo em pips (vpips)
               //if( m_lucroPosicao > (m_lucroPosicao4Gain/2.5)    ){ // testando o ganho obtido com o calculo em pips (vpips)
               //if( m_posicaoVolume > EA_STOP_QTD_CONTRAT    ){ // (m_posicaoVolumeTot*EA_STOP_GAIN_PORC_L1) (v1))
               //if( m_lucroPosicao >  m_lucroPosicao4Gain*(EA02_QTD_TICKS_4_GAIN*0.75) ){ // (v2))
                     Print(":-| Acionando STOP_GAIN_LEVEL1.", strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_GAIN_LEVEL1"); 
                     return;
                 }
                 // 2. se a quantidade de contratos pendentes estah maior que 2x o inicio do stop, muda a tolerancia para 0;
                 if( m_posicaoVolume > EA_STOP_QTD_CONTRAT*2                &&
                     m_lucroPosicao  > EA_STOP_GAIN_PORC_L2*m_posicaoVolumeTot ){                    // v8
                   //m_lucroPosicao  > 0                            ){                    // vpips
                   //m_lucroPosicao  > 0                            ){                    // v1 a v6
                   //m_lucroPosicao  > m_posicaoVolumeTot           ){                    // v7
                   //m_lucroPosicao  > m_lucroPosicao4Gain*(EA02_QTD_TICKS_4_GAIN*0.5) ){ // v2 
                     Print(":-| Acionando STOP_GAIN_LEVEL2.", strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_GAIN_LEVEL2"); 
                     return;
                 }
                 // 3. se a quantidade de contratos pendentes estah maior que 3x o inicio do stop, muda a tolerancia para metade do stoploss (250);
                 if( m_posicaoVolume > EA_STOP_QTD_CONTRAT*3 &&
                     m_lucroPosicao  > EA07_STOP_LOSS*EA_STOP_LOSS_PORC_L3 ){ // v8
                   //m_lucroPosicao  > (EA07_STOP_LOSS/4)      ){ // v7
                   //m_lucroPosicao  > (EA07_STOP_LOSS/4)      ){ // maior que 1/4 do stop loss vpips
                   //m_lucroPosicao  > (EA07_STOP_LOSS/4)      ){ // maior que 1/4 do stop loss v1, v5, v6
                   //m_lucroPosicao  > 0                       ){ // maior que zero             v2
                   //m_lucroPosicao  > EA07_STOP_LOSS*0.1      ){ // 10% do stop loss           v3
                     Print(":-( Acionando STOP_LOSS_LEVEL3.", strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LOSS_LEVEL3"); 
                     return;
                 }
                 // 4. se a quantidade de contratos pendentes estah maior que 4x o inicio do stop, muda a tolerancia para 3/4    do stoploss (375);
                 if( m_posicaoVolume > EA_STOP_QTD_CONTRAT*4 &&
                     m_lucroPosicao  > EA07_STOP_LOSS*EA_STOP_LOSS_PORC_L4    ){ //maior que metade do stoploss //v8
                   //m_lucroPosicao  > EA07_STOP_LOSS*0.5      ){ //maior que metade do stoploss //v7
                   //m_lucroPosicao  > EA07_STOP_LOSS/2        ){ //maior que metade do stoploss //v1 a v6
                   //m_lucroPosicao  > EA07_STOP_LOSS/2        ){ //maior que metade do stoploss //vpips
                   //m_lucroPosicao  > EA07_STOP_LOSS*0.25     ){ //maior que 1/4 do stoploss     //v2
                     Print(":-( Acionando STOP_LOSS_LEVEL4.", strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LOSS_LEVEL4"); 
                     return;
                 }
                 
                 // vpips nao tem a etapa 5
                 // 5. se a quantidade de contratos pendentes estah maior que 4x o inicio do stop, muda a tolerancia para 3/4    do stoploss (375);
                 //if( m_posicaoVolume > EA_STOP_QTD_CONTRAT*5 &&
                 //    m_lucroPosicao  > EA07_STOP_LOSS*0.5      ){ //maior que metade do stoploss
                 //    Print(":-( Acionando STOP_QTD_PORC_PROFIT_LEVEL5.", strPosicao() );
                 //    m_lucroStops += m_lucroPosicao;
                 //    fecharTudo("STOP_QTD_PORC_PROFIT_LEVEL5"); 
                 //    return;
                 //}
                 //+----------------------------------------------------------------------------------------------------
             
         }

         // fecha a posicao ativa a mais de 10 min
         if( m_tempo_posicao_atu > EA_10MINUTOS && EA_10MINUTOS > 0){ 
             Print(":-( Acionando STOP_LOSS_TEMPO_ALTO. T=",m_tempo_posicao_atu," ", strPosicao() );
             m_lucroStops += m_lucroPosicao;
             fecharTudo("STOP_LOSS_TEMPO_ALTO"); 
             return;
         }
         

         // STOP se faltar menos de 20% dos contratos totais pra fechar a posicao.
         //if(    m_capitalInicial   > 0  // deixe isso aqui, senao dah merda na inicializacao, hehe
         //    && m_posicaoVolumeTot > m_posicaoVolume 
         //    && ( m_posicaoVolume  > 20                  )
         //  ){
         //    Print(":-| Acionando STOP_QTD_Y.", strPosicao() );
         //    m_lucroStops += m_lucroPosicao;
         //    fecharTudo("STOP_QTD_Y"); 
         //    return;
         //}

         //if(    m_posicaoVolumeTot > 16 
         //    && m_posicaoProfit    > 0   ){
         //    Print(":-| Acionando STOP_QTD_CONTRATOS_16.", strPosicao() );
         //    m_lucroStops += m_lucroPosicao;
         //    fecharTudo("STOP_QTD_16"); 
         //    return;
         //}

         //if( m_posicaoVolumeTot > 18 ){    // m_qtdOrdens>5 && m_posicaoProfit>0
         //    Print(":-| Acionando STOP_QTD_CONTRATOS_18.", strPosicao() );
         //    m_lucroStops += m_lucroPosicao;
         //    fecharTudo("STOP_QTD_18"); 
         //    return;
         //}
         
         // passo    : aumento de preco, em tick, na direcao contraria a posicao
         // volLimite: volume maximo em risco
         // volLote  : volume de ordem aberta na direcao contraria a posicao (usada pra fechar a posicao).
         // profit   : quantidade de ticks para o gain
           doOpenRajada (EA03_PASSO_RAJADA, EA01_MAX_VOL_EM_RISCO, EA05_VOLUME_LOTE_RAJ , EA02_QTD_TICKS_4_GAIN); // abrindo rajada...
         //doCloseRajada(EA03_PASSO_RAJADA, EA05_VOLUME_LOTE_RAJ , EA02_QTD_TICKS_4_GAIN, false                ); // acionando saida rapida...

    }else{

        if( m_qtdOrdens > 0 ){

           // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
           if( EA07_ABRIR_POSICAO == FECHAR_POSICAO           ) { fecharTudo("OPCAO_FECHAR_POSICAO"         , "OPCAO_FECHAR_POSICAO"         ); return; }
           if( EA07_ABRIR_POSICAO == FECHAR_POSICAO_POSITIVA  ) { fecharTudo("OPCAO_FECHAR_POSICAO_POSITIVA", "OPCAO_FECHAR_POSICAO_POSITIVA"); return; }
           
           // cancela as ordens existentes e nao abre novas ordens se o spread for maior que maximo.
           if( m_symb.Spread() > m_spread_maximo              ) { fecharTudo("SPREAD_ALTO", "SPREAD_ALTO"); return; } 

           //apmb(nunca fechar), vazio(nunca fechar), numero(sempre fechar, pois soh pode ter ordem com comentario numerico se tiver posicao aberta)...
           m_trade.cancelarOrdensComComentarioNumerico(_Symbol); // sao as ordens de fechamento de rajada.
           
           // se tiver ordens RAJADA sem posicao aberta fecha elas...
           m_trade.cancelarOrdensComentadas("RAJADA");

           // Parada apos os cancelamentos visando evitar atropelos...
           //Sleep(SLEEP_PADRAO); 
            
           // se tiver ordem sem stop, coloca agora...
           //m_trade.colocarStopEmTodasAsOrdens(m_stopLoss);
        }
        
        // nao abrir posicao se o indicador feira estiver com problemas...        
        if( m_pmTra == 0 ){
            m_qtd_erros++;
            if(m_qtd_erros>1000){
                Print(":-( MEDIA_TRADE ",m_pmTra,". Indicador feira com preco medio do trade zerado... VERIFIQUE!", strPosicao());
                m_qtd_erros=0;
            }
        }

        switch(EA07_ABRIR_POSICAO){
          case CONTRA_TEND_DURANTE_COMPROMETIMENTO : abrirPosicaoDuranteComprometimentoInstitucional(); break;
          case CONTRA_TEND_APOS_COMPROMETIMENTO    : abrirPosicaoAposComprometimentoInstitucional   (); break;
          case CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR: abrirPosicaoAposMaxMinBarraAnterior            (); break;
          case HFT_DISTANCIA_PRECO                 : abrirPosicaoHFTdistanciaDoPreco                (); break;
          case HFT_MAX_MIN_VOLATILIDADE            : abrirPosMaxMinVolatContraTend                  (); break;
          case HFT_TEND_CCI                        : abrirPosicaoCCINaTendencia                     (); break;
          case HFT_NA_TENDENCIA                    : abrirPosicaoHFTnaTendencia                     (); break;
          case HFT_NORTE_SUL                       : abrirPosicaoHFTnorteSul                        (); break;
          case NAO_ABRIR_POSICAO                   :                                                    break;
        }
        return;
    }
    return;
    
}//+------------------------------------------------------------------+

string strPosicao(){
   return " Contr="     + IntegerToString(m_posicaoVolume      )+ "/"+
                          IntegerToString(m_posicaoVolumeTot   )+
          " SPRE= "     + DoubleToString (m_symb.Spread()    ,2)+
          " VSEG= "     + DoubleToString (m_ticks_por_segundo,2)+
          " Volat="     + DoubleToString (m_volatilidade     ,2)+
          " Incli="     + DoubleToString (m_inclTra          ,2)+
          " CCI[DIF]="  + DoubleToString ( ( m_icci.Main(0)-m_icci.Main(1) )  ,2)+
          " CCI[1]="    + DoubleToString (m_icci.Main(1)     ,2)+
          " CCI[0]="    + DoubleToString (m_icci.Main(0)     ,2)+
          " CAPINI="    + DoubleToString (m_capitalInicial   ,2)+
          " CAPLIQ="    + DoubleToString (m_capitalLiquido   ,2)+
          " LUCRPOS="   + DoubleToString (m_lucroPosicao     ,2)+
          " LUCRSTOPS=" + DoubleToString (m_lucroStops       ,2)+
          " Proft="     + DoubleToString (m_posicaoProfit    ,2)+
          " CAP="       + DoubleToString (m_cta.Equity   ()  ,2)+
          " SLD="       + DoubleToString (m_cta.Balance  ()  ,2)+
          " ORDPEN="    + IntegerToString(m_qtdOrdens          )+
          " PMTRADE="   + DoubleToString (m_pmTra            ,2)+
          " Leilao="    +                 strEmLeilao()        ;
}

bool      emLeilao(){return (m_ask<=m_bid);}
string strEmLeilao(){ if(emLeilao()) return "SIM"; return "NAO";}


//----------------------------------------------------------------------------------------------------------------------------
// Esta funcao deve ser chamada sempre qua ha uma posicao aberta.
// Ela cria rajada de ordens no sentido da posicao, bem como as ordens de fechamento da posicao baseadas nas ordens da rajada.
// passo    : aumento de preco na direcao contraria a posicao
// volLimite: volume maximo em risco
// volLote  : volume de ordem aberta na direcao contraria a posicao
// profit   : quantidade de ticks para o gain
//
// versao 02-084: closerajada antes do openrajada. 
//                Para abrir logo o close da ordem de abertura da posicao.
//                Estava abrindo as rajadas antes da ordem de fechamento da posicao. 
//----------------------------------------------------------------------------------------------------------------------------
bool doOpenRajada(double passo, double volLimite, double volLote, double profit){

   if( estouVendido() ){
         // abrindo ordens pra fechar a posicao
         doCloseRajada(passo, volLote, profit, true); // versao 02-084

         if(passo == 0) return true;
         
         // se nao tem ordem pendente acima do preco atual mais o passo, abre uma...
         double precoOrdem = m_symb.NormalizePrice( m_ask+m_tick_size*passo );

         // com HFT, espera-se que pelo menos 1 de errado.
         //m_trade.setAsync(true);
         openOrdemRajadaVenda(passo,volLimite,volLote,profit,precoOrdem                      );
         //openOrdemRajadaVenda(passo,volLimite,volLote,profit,precoOrdem+(m_tick_size*passo  ));
         //openOrdemRajadaVenda(passo,volLimite,volLote,profit,precoOrdem+(m_tick_size*passo*2));
         //openOrdemRajadaVenda(passo,volLimite,volLote,profit,precoOrdem+(m_tick_size*passo*3));
         //m_trade.setAsync(false);
         return true;
       
   }else{   
        if( estouComprado() ){

             // abrindo ordens pra fechar a posicao
             doCloseRajada(passo, volLote, profit, false); // versao 02-084
    
             if(passo == 0) return true;
    
             // se nao tem ordem pendente abaixo do preco atual, abre uma...
             double precoOrdem = m_symb.NormalizePrice( m_bid-m_tick_size*passo );
    
             // com HFT, espera-se que pelo menos 1 de errado.
             //m_trade.setAsync(true);
             openOrdemRajadaCompra(passo,volLimite,volLote,profit,precoOrdem                      );
             //openOrdemRajadaCompra(passo,volLimite,volLote,profit,precoOrdem-(m_tick_size*passo  ));
             //openOrdemRajadaCompra(passo,volLimite,volLote,profit,precoOrdem-(m_tick_size*passo*2));
             //openOrdemRajadaCompra(passo,volLimite,volLote,profit,precoOrdem-(m_tick_size*passo*3));
             //m_trade.setAsync(false);
             return true;
        }
   }

   // nao deveria chegar aqui, a menos que esta funcao seja chamada sem uma posicao aberta.
   Print(":-( ATENCAO OPENRAJADA chamado sem posicao aberta. Verifique! ",strPosicao() );

   return false;
}

bool openOrdemRajadaVenda( int passo, double volLimite, double volLote, double profit, double precoOrdem){
     
     // distancia entre a primeira ordem da posicao e a ordem atual...
     int distancia = (m_val_order_4_gain==0)?0:(precoOrdem-m_val_order_4_gain);

     if(  m_posicaoVolume <= volLimite                                                                 && // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
         ( distancia%(passo*(int)m_tick_size) ) == 0                                                   && // posiciona rajada em distancias multiplas do passo.
       //( distancia%(passo)                  ) == 0                                                   && // posiciona rajada em distancias multiplas do passo.
         (precoOrdem > m_val_order_4_gain || m_val_order_4_gain==0 )                                   && // vender sempre acima da primeira ordem da posicao  
         !m_trade.tenhoOrdemLimitadaDeVenda ( precoOrdem                   , m_symb.Name(), "RAJADA" ) &&
         !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem-profit*m_tick_size, m_symb.Name(), "RAJADA" ) // se tiver a ordem de compra pendente,
                                                                                                       // significa que a ordem de venda foi
                                                                                                       // executada, entao nao abrimos nova
                                                                                                       // ordem de venda ateh que a compra,
                                                                                                       // que eh seu fechamento, seja executada.
       ){
            Print(":-| HFT_ORDEM OPEN_RAJADA SELL_LIMIT=",precoOrdem, ". Enviando... ",strPosicao() );
            if( m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, volLote, "RAJADA") ){
                if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem; }
                return true;
            }
     }
     return false;
}

bool openOrdemRajadaCompra( int passo, double volLimite, double volLote, double profit, double precoOrdem){

     // distancia entre a primeira ordem da posicao e a ordem atual...
     int distancia = (m_val_order_4_gain==0)?0:(m_val_order_4_gain-precoOrdem);
     
     if(  m_posicaoVolume <= volLimite                                                                 && // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
         ( distancia%(passo*(int)m_tick_size) ) == 0                                                   && // posiciona rajada em distancias multiplas do passo.
       //( distancia%(passo)                  ) == 0                                                   && // posiciona rajada em distancias multiplas do passo.
         (precoOrdem < m_val_order_4_gain || m_val_order_4_gain==0 )                                   && // comprar sempre abaixo da primeira ordem da posicao  
         !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem                   , m_symb.Name(), "RAJADA" ) &&
         !m_trade.tenhoOrdemLimitadaDeVenda ( precoOrdem+profit*m_tick_size, m_symb.Name(), "RAJADA" ) // se tiver a ordem de venda pendente,
                                                                                                       // significa que a ordem de compra foi
                                                                                                       // executada, entao nao abrimos nova
                                                                                                       // ordem de compra ateh que a venda,
                                                                                                       // que eh seu fechamento, seja executada.
       ){
        
            Print(":-| HFT_ORDEM OPEN_RAJADA BUY_LIMIT=",precoOrdem, ". Enviando...",strPosicao());
            if( m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, volLote, "RAJADA") ){
                if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem;}
                return true;
            }
     }
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
      long ticketSel;
      int  qtd = qDealBuy.Count();
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealBuy.Dequeue();
         ticketSel   = StringToInteger( HistoryDealGetString(deal_ticket,DEAL_COMMENT) ); // obtendo o ticket de venda no comentario da ordem de compra...
         qDealSel.Remove(ticketSel); // removendo a venda da fila de vendas pendentes de abrir posicao de compra...
      }

      // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.
      // se sobrou elemento na fila, checamos se jah tem a ordem de compra correspondente. Se nao tiver, criamos.
      double val         = 0               ;
      double precoProfit = 0               ;
      string idClose                       ;
      double vol         = 0               ;
      
      qtd = qDealSel.Count();
      if( qtd > 0 ){ // nao precisa desse IF. Isso aqui eh desespero por conta do erro na fila.
          for(int i=0;i<qtd;i++) {
             deal_ticket = qDealSel.Dequeue();
             idClose = IntegerToString(deal_ticket); // colocando o ticket da venda na ordem de compra. Serah usado posteriormente
                                                     // para encontrar as compras que jah foram processadas.
             if( !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){
    
                 // se nao tem ordem de fechamento da posicao, criamos uma agora:
                 precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) - profit*m_tick_size );
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 Print("HFT_ORDEM CLOSE_RAJADA BUY_LIMIT=",precoProfit, " ID=", idClose, "... ", strPosicao() );
                 m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT,precoProfit, vol, idClose);
             }
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
      double val         = 0               ;
      double precoProfit = 0               ;
      string idClose                       ;
      double vol         = 0               ;
      
      qtd = qDealBuy.Count();
      if( qtd > 0 ){ // nao precisa desse IF. Isso aqui eh desespero por conta do erro na fila.
          for(int i=0;i<qtd;i++) {
             deal_ticket = qDealBuy.Dequeue();
             idClose = IntegerToString(deal_ticket); // colocando o ticket da compra na ordem de venda. Serah usado posteriormente
                                                     // para encontrar as vendas que jah foram processadas.
             if( !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){
                 // se nao tem ordem de fechamento da posicao, criamos uma agora:
                 precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) + profit*m_tick_size );
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 Print("HFT_ORDEM CLOSE_RAJADA SELL_LIMIT=",precoProfit, " ID=", idClose, "...", strPosicao() );
                 m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,precoProfit, vol, idClose);
             }
          }
      }
   }

   return true;
}

// coloca duas ordens 
void abrirPosicaoHFTnorteSul(){

   double vol           = EA05_VOLUME_LOTE_INI;
   double precoOrdem    = 0;
   double inclinacaoMin = 0.1;
   double shift         = 1;
   

     // Se o mercado estah em leilao, cancela as ordens de abertura de posicao
     if ( emLeilao() ){ m_trade.cancelarOrdensComentadas(m_apmb_ns); return; }

     // Se a volatilidade estah alta, cancela as ordens de abertura de posicao.
     //if ( volatilidadeEstahAlta() ){ m_trade.cancelarOrdensComentadas(m_apmb_ns); return; }

     //Se o taxa volume por segundo estiver alta, nao entra na posicao
     if ( taxaVolumeEstahAlta()   ){ m_trade.cancelarOrdensComentadas(m_apmb); return; } // 04/12/2019: testando com 150
      
     if( m_qtdOrdens == 1 ){
         //m_trade.cancelarOrdensComentadas(m_apmb);
         m_trade.cancelarOrdensComentadas(m_apmb_ns);
     }

    if(m_qtdOrdens==0){
  
       // processando em paralelo
       m_trade.setAsync(true);

       if( m_inclBok < 0 ) {     
               // colocando a venda
               precoOrdem = m_ask;
             //precoOrdem = m_ask+m_tick_size;
             //precoOrdem = m_ask+m_tick_size*2;
               Print("HFT_VENDA_NS=",precoOrdem,". Criando ordem de VENDA.", strPosicao()," ...");
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_ns );
                 
               // colocando a compra         
               precoOrdem = m_bid;
             //precoOrdem = m_bid-m_tick_size;
             //precoOrdem = m_bid-m_tick_size*2;
               Print("HFT_COMPRA_NS=",precoOrdem,". Criando ordem de COMPRA.", strPosicao()," ...");
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, m_apmb_ns );
       }else{
               // colocando a compra         
               precoOrdem = m_bid;
             //precoOrdem = m_bid-m_tick_size;
             //precoOrdem = m_bid-m_tick_size*2;
               Print("HFT_COMPRA_NS=",precoOrdem,". Criando ordem de COMPRA.", strPosicao()," ...");
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, m_apmb_ns );

               // colocando a venda
               precoOrdem = m_ask;
             //precoOrdem = m_ask+m_tick_size;
             //precoOrdem = m_ask+m_tick_size*2;
               Print("HFT_VENDA_NS=",precoOrdem,". Criando ordem de VENDA.", strPosicao()," ...");
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_ns );
       }
    
       m_trade.setAsync(false);
    }
/*     
     if( m_inclTra > 0 ){
     
             // colocando a saida antes da entrada
             precoOrdem = m_ask+m_tick_size;
             Print("HFT_VENDA_NS=",precoOrdem,". Criando ordem de VENDA.", strPosicao()," ...");
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb );

             precoOrdem = m_ask;
             Print("HFT_COMPRA_NS=",precoOrdem,". Criando ordem de COMPRA.", strPosicao()," ...");
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, "RAJADA" );
     }else{
             precoOrdem = m_bid-m_tick_size;
             Print("HFT_COMPRA_NS=",precoOrdem,". Criando ordem de COMPRA.", strPosicao()," ...");
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, m_apmb );

             precoOrdem = m_bid;
             Print("HFT_VENDA_NS=",precoOrdem,". Criando ordem de VENDA.", strPosicao()," ...");
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, "RAJADA" );
     }
*/

}


// Abre e mantem as ordens limitadas de abertura de posicao.
// Condicoes:
// Compra abaixo da media de compra(barato) e vende acima da media de compra(caro);
// Ordens limitadas sao colocadas EA10_TICKS_ENTRADA_HTF (geralmente zero, 1 ou 2 ticks) de distancia do preco atual.
// Nao abre posicao durante o pregao.
// Nao abre posicao se a volatilidade estiver alta.
// Nao chame este metodo se houver posicao aberta.
// Correcoes na versao 02-084
// - Passa a considerar o ask pra comprar e o bid pra vender (estava invertido).
// - Passa a proteger a compra pra que o gain nao ultrapasse a media de agressoes (estava protegendo somente a venda).
// - Corrige a impressao do ordem de compra (estava colocando o valor errado).
void abrirPosicaoHFTdistanciaDoPreco(){

   double vol           = EA05_VOLUME_LOTE_INI;
   double precoOrdem    = 0;
   double inclinacaoMin = 0.08;
 //double inclinacaoMin = 0.1;
 //double inclinacaoMin = 0.00;
   double shift         = 1;

     // Se o mercado estah em leilao, cancela as ordens de abertura de posicao
     if ( emLeilao() ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

     // Se a volatilidade estah alta, cancela as ordens de abertura de posicao.
     //if ( volatilidadeEstahAlta() ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }
          
     //Se o taxa volume por segundo estiver alta, nao entra na posicao
     if ( taxaVolumeEstahAlta()   ){ m_trade.cancelarOrdensComentadas(m_apmb); return; } // 04/12/2019: testando com 150

     //switch( m_ganhos_consecutivos ){
     //    case 0 :          break;
     //    case 1 : vol +=1; break;
     //    case 2 : vol +=2; break;
     //    //         vol +=3; break;
     //}

     if( m_inclTra <= -inclinacaoMin ){

         // Vende EA10_TICKS_ENTRADA_HTF ticks acima do preco atual.
         precoOrdem = m_bid+(m_tick_size*EA10_TICKS_ENTRADA_HTF); // colocamos bid a partir da versao 02-084
         
         //vendendo acima da media (caro)...
         //if( precoOrdem < m_pmTra  ){
         //    precoOrdem = m_pmTra ; 
         //}
         if( precoOrdem < m_pmTra + (m_tick_size*EA02_QTD_TICKS_4_GAIN) ){
             precoOrdem = m_pmTra + (m_tick_size*EA02_QTD_TICKS_4_GAIN); 
         }

         if( precoOrdem > m_pmAsk ){ precoOrdem = m_pmAsk; }
          
         //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
         if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*shift ) ){
              Print(":-| HFT_VENDA BID=",m_bid,". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao(),"...");
              if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
         }
     }else{
         m_trade.cancelarOrdensComentadasDeVenda(_Symbol, m_apmb);
     }
     

     if( m_inclTra >= inclinacaoMin ){
         //Compra EA10_TICKS_ENTRADA_HTF abaixo do preco atual.
         precoOrdem = m_ask-(m_tick_size*EA10_TICKS_ENTRADA_HTF); 
    
         // comprando abaixo da media (barato)...
         //if( precoOrdem > m_pmTra ){
         //    precoOrdem = m_pmTra; 
         //}
         if( precoOrdem > m_pmTra - (m_tick_size*EA02_QTD_TICKS_4_GAIN ) ){
             precoOrdem = m_pmTra - (m_tick_size*EA02_QTD_TICKS_4_GAIN ); 
         }
    
         if( precoOrdem < m_pmBid ){ precoOrdem = m_pmBid; }

         //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
         if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*shift ) ){
              Print(":-| HFT_COMPRA ASK=",m_ask,". Criando ordem de COMPRA a ",  precoOrdem, " ", strPosicao(),"...");
              if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
         }
     }else{
         m_trade.cancelarOrdensComentadasDeCompra( _Symbol, m_apmb);
     }
}

//------------------------------------------------------------------------------------------------------------
// Abre e mantem as ordens de abertura de posicao HFT. 
// Abre e mantem as ordens limitadas de abertura de posicao.
// Condicoes:
// Tenta abrir na tendencia.
// Compra abaixo da media de compra(barato) e vende acima da media de compra(caro);
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
     if ( emLeilao()              ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

     //Se a volatilidade estah alta, cancela as ordens de abertura de posicao.
     if ( volatilidadeEstahAlta() ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

     // Vendendo na inclinacao negativa e gain acima ou igual a media de precos...
     if( m_inclTra <= -incl_limite && m_bid-m_tick_size*EA02_QTD_TICKS_4_GAIN>=m_pmTra){
         //Vendendo na queda. 1 tick acima do preco atual...
         //precoOrdem = m_ask+m_tick_size;
         precoOrdem = m_bid;
              
         //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
         if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
              Print("HFT_ORDEM OPEN_POS BID=",m_bid,". Criando ord VENDA a ",  precoOrdem, strPosicao());
              if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
         }
     }

     // Comprando na inclinacao positiva e gain abaixo ou igual a media de precos...
     if( m_inclTra >= incl_limite && m_ask+m_tick_size*EA02_QTD_TICKS_4_GAIN<=m_pmTra){

         //Comprando na subida. 1 tick abaixo do preco atual...
         //precoOrdem = m_bid-m_tick_size; 
         precoOrdem = m_ask; 
    
         //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
         if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
              Print("HFT_ORDEM OPEN_POS ASK=",m_ask,". Criando ord COMPRA a ",  precoOrdem, strPosicao() ," ... profit=", m_posicaoProfit);
              if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
         }
     }

}
//------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------
// Estrategia testada em 29/11/2019 retornou 
void abrirPosicaoDuranteComprometimentoInstitucional(){
    double vol        = EA05_VOLUME_LOTE_INI;
    double precoOrdem = 0;
    double shift = m_tick_size*6;
  //double shift = 0


    // Se o mercado estah em leilao, cancela as ordens de abertura de posicao
    // quando mercado estah em leilao, o preco ask fica menor que o bid...
    if ( emLeilao()              ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

    //Se a volatilidade estah alta, cancela as ordens de abertura de posicao.
    //if ( volatilidadeEstahAlta() ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

    //Se o taxa volume por segundo estiver alta, nao entra na posicao
    if ( taxaVolumeEstahAlta()   ){ m_trade.cancelarOrdensComentadas(m_apmb); return; } // 04/12/2019: testando com 400

    precoOrdem = m_pmAsk; // venda no preco medio de compra
    //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
    if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, shift ) ){
         if(precoOrdem!=0) {
            Print(":-| MEDIA_ASK=",m_pmAsk,". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao(),"...");
            m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
         }else{
            m_qtd_erros++;
            if(m_qtd_erros>1000){
                Print(":-( MEDIA_ASK=",m_pmAsk,".  Preco zerado ao criar ordem de VENDA a ",  precoOrdem, "... VERIFIQUE!", strPosicao());
                m_qtd_erros=0;
            }
         }
    }    
     
    precoOrdem = m_pmBid; // copmpra no preco medio de venda
    //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
    if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, shift ) ){
         if(precoOrdem!=0){
            Print(":-| MEDIA_BID ",m_pmBid,".  Criando ordem de COMPRA a ",  precoOrdem, " ", strPosicao(), "...");
            m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
         }else{
            m_qtd_erros++;
            if(m_qtd_erros>1000){
                Print(":-( MEDIA_BID ",m_pmBid,".  Preco zerado ao criar ordem de COMPRA a ",  precoOrdem, "... VERIFIQUE!", strPosicao());
                m_qtd_erros=0;
            }
         }
    }
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
// Abre posicao apos rompimento do max ou min da volatilidade...
// ESta opcao nao se importa se a volatilidade estiver alta
void abrirPosicaoCCINaTendencia(){
   double vol        = EA05_VOLUME_LOTE_INI;
   double precoOrdem = 0;
 //double shift      = m_tick_size*3;
   double inclinacao_min = EA_INCL_MIN;

    // Se o mercado estah em leilao, cancela as ordens de abertura de posicao
    // quando mercado estah em leilao, o preco ask fica menor que o bid...
    if ( emLeilao()              ){ 
         m_trade.cancelarOrdensComentadas(m_apmb_sel); 
         m_trade.cancelarOrdensComentadas(m_apmb_buy); 
         return; 
    }

    //Se a volatilidade estah alta, cancela as ordens de abertura de posicao.
    //if ( volatilidadeEstahAlta() ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

    //Se o taxa volume por segundo estiver alta, nao entra na posicao
    if ( taxaVolumeEstahAlta()   ){ 
         m_trade.cancelarOrdensComentadas(m_apmb_sel); 
         m_trade.cancelarOrdensComentadas(m_apmb_buy); 
         return; 
    } // 04/12/2019: testando com 400
    



   precoOrdem = m_bid; // venda no topo superior do canal de volatilidade
   if( precoOrdem <= m_pmTra + (m_tick_size*EA02_QTD_TICKS_4_GAIN ) ){   //cci-v5
 //if( precoOrdem <  m_pmTra                                        ){   //cci-v6
     //precoOrdem =  m_pmTra + (m_tick_size*EA02_QTD_TICKS_4_GAIN);      //cci-v5
     //precoOrdem =  m_pmTra;                                            //cci-v6

       if( m_icci.Main(0) <  m_icci.Main(1) && 
           m_icci.Main(1) <= m_icci.Main(2) && // comentado na cci-v6
           m_inclTra      <  -inclinacao_min ){ // CCI  pra baixo;
    
           //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
           if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb_sel, vol , true, m_tick_size ) ){
           
                 if(precoOrdem!=0) {
                    Print(":-| MEDIA_TRADE=",m_pmTra,". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao(),"...");
                    m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_sel);
                 }
           }
       }else{
           m_trade.cancelarOrdensComentadas(m_apmb_sel);
       }
   }


   precoOrdem = m_ask; // compra no topo inferior do canal de volatilidade
   if( precoOrdem >= m_pmTra - (m_tick_size*EA02_QTD_TICKS_4_GAIN ) ){ //cci-v5
 //if( precoOrdem >  m_pmTra                                        ){ //cci-v6
     //precoOrdem =  m_pmTra - (m_tick_size*EA02_QTD_TICKS_4_GAIN );   //cci-v5
     //precoOrdem =  m_pmTra                                       ;   //cci-v6

       if( m_icci.Main(0) >  m_icci.Main(1) && 
           m_icci.Main(1) >= m_icci.Main(2) &&  // comentado na cci-v6
           m_inclTra      > inclinacao_min   ){ // CCI  pra cima;
           //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
           if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb_buy, vol , true, m_tick_size ) ){
    
                 if(precoOrdem!=0){
                    Print(":-| MEDIA_TRADE ",m_pmTra,".  Criando ordem de COMPRA a ",  precoOrdem, " ", strPosicao(), "...");
                    m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb_buy);
                 }
           }
       }else{
           m_trade.cancelarOrdensComentadas(m_apmb_buy);
       }
   }
}

// Abre posicao apos rompimento do max ou min da volatilidade...
// ESta opcao nao se importa se a volatilidade estiver alta
void abrirPosMaxMinVolatContraTend(){
   double vol        = EA05_VOLUME_LOTE_INI;
   double precoOrdem = 0;
   double shift      = m_tick_size*3;
 //double shift = 0

    // Se o mercado estah em leilao, cancela as ordens de abertura de posicao
    // quando mercado estah em leilao, o preco ask fica menor que o bid...
    if ( emLeilao()              ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

    //Se a volatilidade estah alta, cancela as ordens de abertura de posicao.
    //if ( volatilidadeEstahAlta() ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

    //Se o taxa volume por segundo estiver alta, nao entra na posicao
    if ( taxaVolumeEstahAlta()   ){ m_trade.cancelarOrdensComentadas(m_apmb); return; } // 04/12/2019: testando com 400

   precoOrdem = m_phigh; // venda no topo superior do canal de volatilidade
   if( precoOrdem < m_pmTra + (m_tick_size*EA02_QTD_TICKS_4_GAIN ) ){
       precoOrdem = m_pmTra + (m_tick_size*EA02_QTD_TICKS_4_GAIN ); 
   }
   //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
   if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb_sel, vol , true, m_tick_size ) ){
   
        Print("MEDIA_ASK=",m_pmAsk,".  Criando ordem de VENDA a ",  precoOrdem, "...");
        if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_sel);
   }


   precoOrdem = m_plow; // compra no topo inferior do canal de volatilidade
   if( precoOrdem > m_pmTra - (m_tick_size*EA02_QTD_TICKS_4_GAIN ) ){
       precoOrdem = m_pmTra - (m_tick_size*EA02_QTD_TICKS_4_GAIN ); 
   }
   //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
   if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb_buy, vol , true, m_tick_size ) ){
        Print("MEDIA_BID ",m_pmBid,".  Criando ordem de COMPRA a ",  precoOrdem, "...");
        if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb_buy);
   }
}

bool taxaVolumeEstahAlta        (){ return m_ticks_por_segundo > EA_VOLSEG_ALTO  && EA_VOLSEG_ALTO > 0;}
bool volatilidadeEstahAltaDemais(){ return m_volatilidade      > (EA_VOLAT_ALTA+0.3);}
bool volatilidadeEstahAlta      (){ return m_volatilidade      > EA_VOLAT_ALTA      ;}

//bool volatilidadeEstahBaixa   (){ return m_volatilidade      < EA09_VOLAT_BAIXA     ;}
//bool volatilidadeEstahMedia   (){ return m_volatilidade      >  m_volBaixa && m_volatilidade <  m_volBaixa ;}








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
//  TimeToStruct(TimeLocal  (),m_date);

    // informando a mudanca do dia (usada no controle do rebaixamento de saldo maximo da sessao).
    if( m_day != m_date.day ){ m_day = m_date.day; m_mudou_dia = true; }

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
   m_ibb.Refresh(-1);

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

bool precoPosicaoAbaixoDaMedia(){ return m_precoPosicao < m_ibb.Base(0) ;}
bool precoPosicaoAcimaDaMedia (){ return m_precoPosicao > m_ibb.Base(0) ;}

bool precoNaMedia             (){ return m_symb.Last() < m_ibb.Base(0) + m_tick_size &&
                                         m_symb.Last() > m_ibb.Base(0) - m_tick_size    ;}

bool precoNaBandaInferior     (){ return m_symb.Ask() < m_ibb.Lower(0) + m_tick_size &&
                                         m_symb.Ask() > m_ibb.Lower(0) - m_tick_size    ;}

bool precoAbaixoBandaInferior (){ return m_symb.Ask() < m_ibb.Lower(0) + m_tick_size;}

bool precoNaBandaSuperior     (){ return m_symb.Bid() < m_ibb.Upper(0) + m_tick_size &&
                                         m_symb.Bid() > m_ibb.Upper(0) - m_tick_size    ;}

bool precoAcimaBandaSuperior  (){ return m_symb.Bid() > m_ibb.Upper(0) - m_tick_size;}

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
    IndicatorRelease( m_icci.Handle()  );
    //IndicatorRelease( m_ibb.Handle()    );
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


