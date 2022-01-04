//+------------------------------------------------------------------+
//|                          ose-p7-004-000-transacao-por-evento.mq5 |
//|                                          Copyright 2019, OS Corp |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao p7-004-000                                                |
//| 1. Superficie de operacao usando OntradeTransaction para         |
//|    a abertura ou inclusao de ordens em uma posicao e disparar    |
//|    as ordens de fechamento. Reflete diretamente no closerajada,  |
//|    que eh mais lento devido a pesquisa das ordens de uma posicao |
//|    no historico de ordens.                                       |
//|                                                                  |
//|    Fechamento de posicoes por stop passa a ser pelo valor de     |
//|    m_precoSaidaPosicao, visando sua simplificacao.               |
//|                                                                  |
//| 2. Portifolio de Estrategias                                     |
//|                                                                  |
//|    2.1 HFT_OPERAR_VOLUME_CANAL                                   |
//|        Abre posicao em funcao de:                                |
//|        - posicao no canal operacional                            |
//|        - velocidade dos volumes de compra e venda                |
//|        - aceleracao da velocidade dos volumes de compra e venda  |
//|        - velocidade de mudanca de precos                         |
//|                                                                  |
//|    2.2 HFT_FORMADOR_DE_MERCADO                                    |
//|        Mantem ordens de abertura de posicao a pelo menos XX ticks|
//|        de distancia do nivel zero do book, visando ter prioridade|
//|        de execucao quando o preco chegar ao nivel zero.          |
//|                                                                  |
//| // 2.3 HFT_ARBITRAGEM_PAR                                        |
//| //     Monitora desvios na correlacao de pares de ativos visando |
//| //     abertura de posicoes quando os desvios forem maiores que  |
//| //     xx desvios padroes e fechamento quando os desvios forem   |
//| //     menoes que xx desvios padroes.                            |
//|                                                                  |
//+------------------------------------------------------------------+

#define COMPILE_PRODUCAO

#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "1.2"

//#include <Generic\Queue.mqh>
//#include <Generic\HashMap.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//#include <Indicators\Trend.mqh>

//#include <oslib\os-lib.mq5>
#include <oslib\osc\est\osc-estatistic3.mqh>
#include <oslib\osc\est\C0002ArbitragemPar.mqh>
#include <oslib\osc\osc-minion-trade-03.mqh>
#include <oslib\osc\osc-minion-trade-estatistica.mqh>
#include <oslib\osc\osc-media.mqh>
#include <oslib\osc\trade\osc_position.mqh>

//#include <oslib\svc\osc-svc.mqh>
//#include <oslib\svc\run\cls-run.mqh>

#include <oslib\osc\cp\osc-pc-p7-002-004-vel-vol.mqh> //painel de controle
#include <oslib\osc\osc-canal.mqh> //canais
//#include <oslib\osc\est\C0001FuzzyModel.mqh> // modelo para medir risco de entrar em uma operar 
#include <oslib\osc\data\osc-cusum.mqh> // implemantacao do algoritmo cumulative sum.



enum ENUM_TIPO_ENTRADA_PERMITDA{
     ENTRADA_NULA              , //ENTRADA_NULA  Nao permite abrir posicoes.
     ENTRADA_BUY               , //ENTRADA_BUY   Soh abre posicoes de compra.
     ENTRADA_SELL              , //ENTRADA_SELL  Soh abre posocoes de venda.
     ENTRADA_TODAS               //ENTRADA_TODAS Abre qualquer tipo de posicao.
};

enum ENUM_TIPO_OPERACAO{
     NAO_OPERAR                           , //NAO_OPERAR EA não abre nem fecha posições, fica apenas atualizando os indicadores.
     FECHAR_POSICAO                       , //FECHAR_POSICAO EA fecha a posição aberta. Usar em caso de emergencia.
     FECHAR_POSICAO_POSITIVA              , //FECHAR_POSICAO_POSITIVA Igual a anterior, mas aguarda o saldo da posição ficar positivo pra fechar.
     NAO_ABRIR_POSICAO                    , //NAO_ABRIR_POSICAO Pode ser usado para entrar manualmente e deixar o EA sair.
     HFT_OPERAR_VOLUME_CANAL              , //HFT_OPERAR_VOLUME_CANAL
     HFT_FORMADOR_DE_MERCADO                //HFT_FORMADOR_DE_MERCADO
  // HFT_ARBITRAGEM_PAR                     //HFT_ARBITRAGEM_PAR
};

//---------------------------------------------------------------------------------------------
  input group "Gerais"
  input ENUM_TIPO_OPERACAO         EA_ACAO_POSICAO           = FECHAR_POSICAO ; //EA_ACAO_POSICAO:Forma de operacao do EA.
  input ENUM_TIPO_ENTRADA_PERMITDA EA_TIPO_ENTRADA_PERMITIDA = ENTRADA_TODAS;//TIPO_ENTRADA_PERMITIDA Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
  input double                     EA_SPREAD_MAXIMO_EM_TICKS =  5 ; //EA_SPREAD_MAXIMO_EM_TICKS. Se for maior que o maximo, nao abre novas posicoes.
//
//input group "Volume por Segundo"
//input int    EA_VOLSEG_MAX_ENTRADA_POSIC = 150;//VOLSEG_MAX_ENTRADA_POSIC: vol/seg maximo para entrar na posicao.
//

  //input group "arbitragem par"
  //input string EA_TICKER_REF          = "BOVA11";//TICKER_REF
  //input int    EA_QTD_SEG_MEDIA_PRECO = 5       ;//QTD_SEG_MEDIA_PRECO
  //input int    EA_QTD_SEG_MEDIA_RATIO = 60*21   ;//QTD_SEG_MEDIA_RATIO
  //input double EA_QTD_DP_FIRE_ORDEM   = 1.0     ;//QTD_DP_FIRE_ORDEM
  //input double EA_QTD_DP_CLOSE_ORDEM  = 0.5     ;//QTD_DP_CLOSE_ORDEM

  input group "velocidade do volume"
  input int    EA_EST_QTD_SEGUNDOS = 5;   //EST_QTD_SEGUNDOS qtd seg para calc velocidade do volume 

  input group "canal operacional"
  input bool   EA_CANAL_DIARIO                  = true; //CANAL_DIARIO operacional
  input int    EA_TAMANHO_CANAL                 = 15  ; //TAMANHO_CANAL operacional
  input double EA_PORC_REGIAO_OPERACIONAL_CANAL = 0.5 ; //PORC_REGIAO_OPERACIONAL_CANAL regiao de operacao

  input group "formador de mercado"
  input int    EA_DIST_MIN_IN_BOOK_IN_POS                 = 6   ; //DIST_MIN_IN_BOOK_IN_POS abrindo posicao
  input int    EA_DIST_MIN_IN_BOOK_IN_POS_OBRIG           = 6   ; //DIST_MIN_IN_BOOK_IN_POS_OBRIG
  input int    EA_DIST_MIN_IN_BOOK_OUT_POS                = 6   ; //DIST_MIN_IN_BOOK_OUT_POS fechando posicao
  input int    EA_LAG_RAJADA                              = 6   ; //LAG_RAJADA
  input int    EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES        = 20  ; //STOP_PARCIAL_A_PARTIR_DE_X_LOTES
  input int    EA_STOP_PARCIAL_A_PARTIR_DE_X_GANHO        = 1000; //STOP_PARCIAL_A_PARTIR_DE_X_GANHO
  input bool   EA_DECISAO_ENTRADA_COMPRA_VENDA_AUTOMATICA = false;//DECISAO_ENTRADA_COMPRA_VENDA_AUTOMATICA
  input bool   EA_FECHA_POSICAO_NO_BREAK_EVEN             = false;//FECHA_POSICAO_NO_BREAK_EVEN
  input double EA_AUMENTO_LAG_POR_LOTE_PENDENTE           = 0.25 ;//AUMENTO_LAG_POR_LOTE_PENDENTE
  
  input group "entrada na posicao"
  input int    EA_TOLERANCIA_ENTRADA       = 1 ; //TOLERANCIA_ENTRADA: algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao 
  input double EA_VOL_LOTE_INI             = 1 ; //VOL_LOTE_INI:Vol do lote na abertura de posicao qd vol/seg eh L1.
  input double EA_QTD_TICKS_4_GAIN_INI     = 5 ; //TICKS_4_GAIN_INI Qtd ticks para o gain qd vol/seg eh level 1;
  input double EA_QTD_TICKS_4_GAIN_DECR    = 0 ; //TICKS_4_GAIN_DECR Qtd ticks a ser decrementado em tfg a cada aumento de volume de posicao;
  input double EA_QTD_TICKS_4_GAIN_MIN     = 5 ; //QTD_TICKS_4_GAIN_MIN menor alvo inicial possivel;
//input int    EA_PERIODO_CALC_TENDENCIA   = 3 ; //PERIODO_CALC_TENDENCIA para o calculo da tendencia
  input bool   EA_ALVO_DINAMICO            = false;//ALVO_DINAMICO alvo igual dp/TAMANHO_RAJADA

  //input ENUM_TIMEFRAMES    EA_BB_PERIODO       = PERIOD_CURRENT; // BB_PERIODO
  //input int                EA_BB_QTD_PERIODOS  = 10            ; // BB_QTD_PERIODOS
  //input double             EA_BB_DESVIO_PADRAO = 1.5           ; // BB_DESVIO_PADRAO
  //input ENUM_APPLIED_PRICE EA_BB_APPLIED       = PRICE_WEIGHTED; // BB_APPLIED

  input group "Rajada"
  input bool   EA_RAJADA_UNICA                    = true ; //RAJADA_UNICA se verdadeiro, cria uma raja unica na abertura da posicao. 
  input int    EA_TAMANHO_RAJADA                  = 1    ; //TAMANHO_RAJADA;
  input double EA_VOL_PRIM_ORDEM_RAJ              = 1    ; //VOL_PRIM_ORDEM_RAJ:Vol da primeira ordem da rajada.
  input double EA_INCREM_VOL_RAJ                  = 1    ; //INCREM_VOL_RAJ aumento(x) de volume a cada ordem da rajada;
  input double EA_DISTAN_PRIM_ORDEM_RAJ           = 1    ; //DISTAN_PRIM_ORDEM_RAJ Distancia em ticks desde abertura da posicao ateh prim ordem rajada;
  input double EA_DISTAN_DEMAIS_ORDENS_RAJ        = 1    ; //DISTAN_DEMAIS_ORDENS_RAJ Distancia entre as demais ordens da rajada;
  input double EA_INCREM_DISTAN_DEMAIS_ORDENS_RAJ = 1    ; //INCREM_DISTAN_DEMAIS_ORDENS_RAJ aumento (x) distancia ordens rajada;
  input bool   EA_STOP_NA_RAJADA                  = false; //STOP_NA_RAJADA
  input double EA_PORC_STOP_NA_RAJADA             = 0    ; //PORC_STOP_NA_RAJADA
  input bool   EA_FECHA_POSICAO_POR_EVENTO        = true ; //FECHA_POSICAO_POR_EVENTO
  input bool   EA_LOGAR_TRADETRANSACTION          = false; //LOGAR_TRADETRANSACTION

  input group "Entrada CUSUM"
  input double   EA_KK = 3    ; //K passo do preco para uma acumulacao direcional;
  input double   EA_HH = true ; //H soma de acumulacoes (K) na mesma direcao para caracterizar a tendencia.

//
//-------------------------------------------------------------------------------------------
//input group "Run"
//input int    EA_MINUTOS_RUN    = 300  ; //MINUTOS_RUN:minutos usados no calcula do indice das runs.
//-------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------
//input group "Passo dinamico"
#define EA_PASSO_DINAMICO                      false //PASSO_DINAMICO:tamanho do passo muda em funcao da volatilidade
#define EA_PASSO_DINAMICO_PORC_T4G             1     //PASSO_DINAMICO_PORC_TFG: % do TFG para definir o passo.
#define EA_PASSO_DINAMICO_MIN                  1     //PASSO_DINAMICO_MIN:menor passo possivel.
#define EA_PASSO_DINAMICO_MAX                  15    //PASSO_DINAMICO_MAX:maior passo possivel.
#define EA_PASSO_DINAMICO_PORC_CANAL_ENTRELACA 0.02  //PASSO_DINAMICO_PORC_CANAL_ENTRELACA
#define EA_PASSO_DINAMICO_STOP_QTD_CONTRAT     3     //PASSO_DINAMICO_STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
#define EA_PASSO_DINAMICO_STOP_CHUNK           2     //PASSO_DINAMICO_STOP_CHUNK:tamanho do chunk.
#define EA_PASSO_DINAMICO_STOP_PORC_CANAL      1     //PASSO_DINAMICO_STOP_PORC_CANAL:porcentagem do canal, usada para calcular o stop_loss dinamico.
#define EA_PASSO_DINAMICO_STOP_REDUTOR_RISCO   1     //PASSO_DINAMICO_STOP_REDUTOR_RISCO:porcentagem sobre o tamanho do passo para iniciar saida da posicao.

//input bool   EA_STOP_PORC_DINAMICO  = false; //STOP_PORC_DINAMICO:porcentagem de saida dinamica. Soh funciona se PASSO_DINAMICO eh true.
//input double EA_PORC_PASSO_DINAMICO = 0.25 ; //PORC_PASSO_DINAMICO:porcentagem do tamanho da barra de volatilidade para definir o tamanho do passo.
//input int    EA_INTERVALO_PASSO     = 2    ; //INTERVALO_PASSO:delta tolerancia para mudanca de passo.
//-------------------------------------------------------------------------------------------
//
  input group "Stops"
//input int    EA_STOP_TIPO_CONTROLE_RISCO = 1   ; //STOP_TIPO_CONTROLE_RISCO, se 1, controle normal. Se 2, controle por proximidade do breakeven.
  input int    EA_STOP_TICKS_STOP_LOSS   =  0    ; //STOP_TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
  input int    EA_STOP_TICKS_TKPROF      =  0    ; //STOP_TICKS_TKPROF:Quantidade de ticks usados no take profit;
  input double EA_STOP_REBAIXAMENTO_MAX  =  0    ; //STOP_REBAIXAMENTO_MAX:preencha com positivo.
  input double EA_STOP_OBJETIVO_DIA      =  0    ; //STOP_OBJETIVO_DIA:para se saldo alcancar objetivo do dia.
  input double EA_STOP_LOSS              =  0    ; //STOP_LOSS:Valor maximo de perda aceitavel;
  input int    EA_STOP_TICKS_TOLER_SAIDA =  1    ; //STOP_TICKS_TOLER_SAIDA: qtd de ticks a aguardar nas saidas stop;
  #define      EA_STOP_CHUNK                10     //STOP_CHUNK:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
  #define      EA_STOP_PORC_L1              1      //STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
  #define      EA_STOP_10MINUTOS            0      //STOP_10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
  #define      EA_STOP_QTD_CONTRATOS_PENDENTES 0   //STOP_QTD_CONTRATOS_PENDENTES fecha posic se qtd contrat maior que este
//
//input group "Entrelacamento"
//input int    EA_ENTRELACA_PERIODO_COEF    = 6    ;//ENTRELACA_PERIODO_COEF: periodo p/calc coef entrelacamento.
//input double EA_ENTRELACA_COEF_MIN        = 0.40 ;//ENTRELACA_COEF_MIN em porcentagem.
//input int    EA_ENTRELACA_CANAL_MAX       = 30   ;//ENTRELACA_CANAL_MAX: tamanho maximo em ticks do canal de entrelacamento.
//input int    EA_ENTRELACA_CANAL_STOP      = 35   ;//ENTRELACA_CANAL_STOP:StopLoss se canal maior que este parametro.
//
//input group "Regiao de compra e venda"
//input double EA_REGIAO_BUY_SELL       = 0.3  ; //REGIAO_BUY_SELL: regiao de compra e venda nas extremidades do canal de entrelacamento.
//input bool   EA_USA_REGIAO_CANAL_DIA  = false; //USA_REGIAO_CANAL_DIA: usa a regiao do canal diario (true) ou canal de entrelacamento(false) para calcular regiao de compra venda.
//
//input group "volatilidade e inclinacoes"
//input double EA_VOLAT_ALTA                = 1.5 ;//VOLAT_ALTA:Volatilidade a considerar alta(%). Calculada a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
//input double EA_VOLAT4S_ALTA_PORC         = 1.0 ;//VOLAT4S_ALTA_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media abrir posicao.
//input double EA_VOLAT4S_STOP_PORC         = 1.5 ;//VOLAT4S_STOP_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media para stopar.
//input double EA_VOLAT4S_MIN               = 1.5 ;//VOLAT4S_MIN:Acima deste valor, nao abre posicao.
//input double EA_VOLAT4S_MAX               = 2.0 ;//VOLAT4S_MAX:Acima deste valor, fecha a posicao.
//input double EA_INCL_ALTA                 = 0.9 ;//INCL_ALTA:Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
//input double EA_INCL_MIN                  = 0.1 ;//INCL_MIN:Inclinacao minima para entrar no trade.
//input int    EA_MIN_DELTA_VOL             = 10  ;//MIN_DELTA_VOL:%delta vol minimo para entrar na posicao
//input int    EA_MIN_DELTA_VOL_ACELERACAO  = 1   ;//MIN_DELTA_VOL_ACELERACAO:Aceleracao minima da %delta vol para entrar na posicao
//
  input group "show_tela"
  input bool   EA_SHOW_CONTROL_PANEL               = false; //SHOW_CONTROL_PANEL mostra painel de controle;
  input bool   EA_SHOW_TELA                        = false; //SHOW_TELA:mostra valor de variaveis na tela;
  input bool   EA_SHOW_CANAL_PRECOS                = false; //SHOW_CANAL_PRECOS:mostra linhas do canal de precos;  
  #define      EA_SHOW_TELA_LINHAS_ACIMA             0      //SHOW_TELA_LINHAS_ACIMA:permite impressao na parte inferior da tela;
//input bool   EA_SHOW_STR_PERMISSAO_ABRIR_POSICAO = false; //SHOW_STR_PERMISSAO_ABRIR_POSICAO:condicoes p/abrir posicao;

//
////
//input group "diversos"
//input bool   EA_DEBUG           =  false       ; //DEBUG:se true, grava informacoes de debug no log do EA.
input ulong  EA_MAGIC             =  20093007004000; //MAGIC: Numero magico desse EA. yy-mm-vv-vvv-vvv.
////
//input group "estrategia HFT_FLUXO_ORDENS"
//input double EA_PROB_UPDW                =  0.8 ;//PROB_UPDW:probabilidade do preco subir ou descer em funcao do fluxo de ordens;
////
input double EA_DOLAR_TARIFA             =  6.0 ;//DOLAR_TARIFA:usado para calcular a tarifa do dolar.
////

//#define EA_MAX_VOL_EM_RISCO     200        //EA_MAX_VOL_EM_RISCO:Qtd max de contratos em risco; Sao os contratos pendentes da posicao.
//#define EA04_DX_TRAILLING_STOP  1.0        //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
//#define EA10_DX1                0.2        //EA10_DX1:Tamanho do DX em relacao a banda em %;

//---------------------------------------------------------------------------------------------
// configurando a feira...
//input group "estatistica"
//input bool     FEIRA02_GERAR_VOLUME      = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
//input bool     FEIRA03_GERAR_OFERTAS     = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
//input int    FEIRA04_QTD_BAR_PROC_HIST = 0     ; // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
//input double FEIRA05_BOOK_OUT          = 0     ; // Porcentagem das extremidades dos precos do book que serão desprezados.
//input int      FEIRA06_QTD_SEGUNDOS      = 60    ; // Quantidade de segundos que serao acumulads para calcular as medias.
//input bool     FEIRA07_GERAR_SQL_LOG     = false ; // Se true grava comandos sql no log para insert do book em tabela postgres.
//input bool   FEIRA99_ADD_IND_2_CHART   = true  ; // Se true apresenta o idicador feira no grafico.


//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
input group "horario de operacao"
input int    EA_HR_INI_OPERACAO   = 09; // Hora   de inicio da operacao;
input int    EA_MI_INI_OPERACAO   = 15; // Minuto de inicio da operacao;
input int    EA_HR_FIM_OPERACAO   = 17; // Hora   de fim    da operacao;
input int    EA_MI_FIM_OPERACAO   = 52; // Minuto de fim    da operacao;
input int    EA_HR_FECHAR_POSICAO = 17; // HR_FECHAR_POSICAO fecha todas as posicoes;
input int    EA_MI_FECHAR_POSICAO = 53; // MI_FECHAR_POSICAO fecha todas as posicoes;
//---------------------------------------------------------------------------------------------
//
// group "sleep e timer"
input int    EA_SLEEP_INI_OPER     =  10 ;//SLEEP_INI_OPER:Aguarda estes segundos para iniciar abertura de posicoes.
input int    EA_QTD_MILISEG_TIMER  =  500;//QTD_SEG_TIMER:Tempo de acionamento do timer.

//input int    EA_SLEEP_ATRASO   =  0  ;//SLEEP_TESTE_ONLINE:atraso em milisegundos antes de enviar ordens.

//---------------------------------------------------------------------------------------------

//osc_estatistic2 m_est;

MqlDateTime       m_date;
string            m_name = "OSE-P7-004-001"   ; //
CSymbolInfo       m_symb, m_symb_ref          ;
CPositionInfo     m_posicao                   ;
CAccountInfo      m_cta                       ;

double        m_tick_size                     ;// alteracao minima de preco.
double        m_lots_step                     ;// alteracao minima de volume.
double        m_spread                        ;// spread.
double        m_point                         ;// valor do ponto.
double        m_stopLossOrdens                ;// stop loss;
double        m_tkprof                        ;// take profit;
double        m_distMediasBook                ;// Distancia entre as medias Ask e Bid do book.

osc_minion_trade             m_trade            ; // operacao com ordens
osc_minion_trade_estatistica m_trade_estatistica; // estatistica de trades
osc_estatistic3*             m_est              ; // estatistica de ticks
osc_control_panel_p7_002_004 m_cp               ; // painel de controle

//C0002ArbitragemPar*          m_par              ;

bool   m_comprado            =  false;
bool   m_vendido             =  false;
double m_posicaoVolumePend   =  0; // volume pendente pra fechar a posicao atual
double m_posicaoLotsPend     =  0; // lotes pendentes pra fechar a posicao atual
double m_posicaoVolumeTot    =  0; // volume total de contratos da posicao, inclusive os que jah foram fechados
long   m_positionId          = -1;
double m_volComprasNaPosicao =  0; // quantidade de compras na posicao atual;
double m_volVendasNaPosicao  =  0; // quantidade de vendas  na posicao atual;
double m_capitalInicial      =  0; // capital justamente antes de iniciar uma posicao
double m_capitalLiquido      =  0; // capital atual durante a posicao.
double m_lucroPosicao        =  0; // lucro da posicao atual
double m_lucroPosicao4Gain   =  0; // lucro para o gain caso a quantidade de contratos tenha ultrapassado o valor limite.
double m_lucroStops          =  0; // lucro acumulado durante stops de quantidade

double m_tstop                  =  0 ;
//string m_positionCommentStr     = "0";
//long   m_positionCommentNumeric =  0 ;


// barras atual e anterior...
//MqlRates m_rates[];
//double m_high0      = 0;
//double m_low0       = 0;
//double m_high1      = 0;
//double m_low1       = 0;
//double m_lenBar0    = 0;
//double m_lenBar1    = 0;
//double m_lenAteStop = 0;

//--- variaveis atualizadas pela funcao refreshMe...
int    m_qtdOrdens     = 0;
int    m_qtdOrdensAnt  = 0;
int    m_qtdPosicoes   = 0;
double m_posicaoProfit = 0;
double m_ask           = 0;
double m_bid           = 0;
double m_ask_stplev    = 0; // ask - stop level
double m_bid_stplev    = 0; // bid + stop level
double m_val_order_4_gain = 0;

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


//-- controle das inclinacoes
double   m_inclSel    = 0;
double   m_inclBuy    = 0;
double   m_inclTra    = 0;
double   m_inclBok    = 0;

string   m_apmb       = "IN" ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_sel   = "INS"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_buy   = "INB"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_strRajada  = "RJ" ; //string que identifica rajadas de abertura de novas posicoes.
string   m_comment_fixo;
string   m_comment_var;

double m_maior_sld_do_dia = 0;
double m_sld_sessao_atu   = 0;
double m_rebaixamento_atu = 0;
int    m_day              = 0;
bool   m_mudou_dia        = false;
bool   m_acionou_stop_rebaixamento_saldo = false;
int    m_spread_maximo_in_points = 0;
double m_stop_level_in_price = 0;

int    m_ganhos_consecutivos = 0;
int    m_perdas_consecutivas = 0;
long   m_tempo_posicao_atu   = 0;
long   m_tempo_posicao_ini   = 0;

int    m_stop_qtd_contrat    = 0; // EA_STOP_QTD_CONTRAT; Eh o tamanho do chunk;
int    m_stop_chunk          = 0; // EA_STOP_CHUNK; Eh o tamanho do chunk;
double m_stop_porc           = 0; // EA_STOP_PORC_L1    ; Eh a porcentagem inicial para o ganho durante o passeio;
double m_qtd_ticks_4_gain_new  = 0;
double m_qtd_ticks_4_gain_ini  = 0;
double m_qtd_ticks_4_gain_decr = 0;
double m_qtd_ticks_4_gain_bb   = 0;
double m_qtd_ticks_4_gain_raj= 0;
int    m_passo_rajada        = 0;
double m_vol_lote_ini        = 0;
double m_vol_lote_raj        = 0;

// operacao com rajada unica.
double m_raj_unica_distancia_demais_ordens = 0;
double m_raj_unica_distancia_prim_ordem    = 0;

// para acelerar a abertura da primeira ordem de fechamento a posicao
double m_val_close_position_sel = 0;
double m_vol_close_position_sel = 0;
double m_val_close_position_buy = 0;
double m_vol_close_position_buy = 0;

// controle de fechamento de posicoes
//bool  m_fechando_posicao         = false;
ulong m_ordem_fechamento_posicao = 0;

// controle de abertura de posicoes
bool  m_abrindo_posicao            = false;
ulong m_ordem_abertura_posicao_sel = 0;
ulong m_ordem_abertura_posicao_buy = 0;

// controles de apresentacao das variaveis de debug na tela...
string m_str_linhas_acima   = "";
string m_release = "[RELEASE TESTE]";

// variaveis usadas nas estrategias de entrada, visando diminuir a quantidade de alteracoes e cancelamentos com posterior criacao de ordens de entrada.
//double m_precoUltOrdemInBuy = 0;
//double m_precoUltOrdemInSel = 0;

// string com o simbolo sendo operado
string m_symb_str;

// milisegundos que devem ser aguardados antes de iniciar a operacao
int m_aguardar_para_abrir_posicao = 0;

// algumas estrategias permitem uma tolerancia do preco para entrada na posicao...
double m_shift_in_points = 0;

datetime m_time_in_seconds_ini_day = TimeCurrent();

ENUM_TIPO_ENTRADA_PERMITDA m_tipo_entrada_permitida = EA_TIPO_ENTRADA_PERMITIDA;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//CiMA m_vetMaInst  [6];
//CiMA m_vetMaTrader[6];

//testando a classe osc_canal...
osc_canal m_canal;
//C0001FuzzyModel m_mercado_modelo;
//double m_riscoVenda  = 0; 
//double m_riscoCompra = 0;

int OnInit(){

  //m_qtd_exec_oninit++;

    #ifdef COMPILE_PRODUCAO m_release = "[RELEASE PRODU]";#endif

    Print(":-| ", __FUNCTION__,m_release, " ************************************************");
    Print(":-| ", __FUNCTION__,m_release, " Iniciando : ", TimeCurrent() );
    Print(":-| ", __FUNCTION__,m_release, " MAGIC     : ", EA_MAGIC      );
    Print(":-| ", __FUNCTION__,m_release, " BUILDER   : ", __MQLBUILD__  );
    Print(":-| ", __FUNCTION__,m_release, " EXECUTAVEL: ", __PATH__      );
    Print(":-| ", __FUNCTION__,m_release, " BUILDATE  : ", __DATETIME__  );
    Print(":-| ", __FUNCTION__,m_release, " MQL       : ", __MQL__       );
    Print(":-| ", __FUNCTION__,m_release, " ************************************************");
    
    //----------------------------------------------------------------------------------------
    inicializarSimbolo(); // Primeiro a executar pois ha varios a frente que dependem do simbolo configurado
    inicializarVariaveisRecebidasPorParametro();
    inicializarPassoRajadaFixoHFT_FORMADOR_DE_MERCADO();

    m_stopLossOrdens    = m_symb.NormalizePrice(EA_STOP_TICKS_STOP_LOSS *m_tick_size);
    m_tkprof            = m_symb.NormalizePrice(EA_STOP_TICKS_TKPROF    *m_tick_size);
    
    m_trade.setSymbol  ( _Symbol );
    m_trade.setMagic   ( EA_MAGIC);
    m_trade.setStopLoss( m_stopLossOrdens);
    m_trade.setTakeProf( m_tkprof);

    m_posicao.Select( m_symb_str ); // selecao da posicao por simbolo.

    m_canal.inicializar(m_symb,EA_TAMANHO_CANAL, EA_PORC_REGIAO_OPERACIONAL_CANAL);
    m_canal.setShowCanalPrecos(EA_SHOW_CANAL_PRECOS);
    m_canal.setRegiaoBuySellUsaCanalDia(EA_CANAL_DIARIO);
    
    // estatistica de trade...    
    m_time_in_seconds_ini_day = StringToTime( TimeToString( TimeCurrent(), TIME_DATE ) );
    m_trade_estatistica.initialize();
    m_trade_estatistica.setCotacaoMoedaTarifaWDO(EA_DOLAR_TARIFA);
    
    m_spread_maximo_in_points = (int)( (EA_SPREAD_MAXIMO_EM_TICKS*m_tick_size)/m_point );
    m_stop_level_in_price     = normalizar ( m_symb.StopsLevel()*m_point + m_tick_size );
  //m_stop_level_in_price     = normalizar ( m_symb_ref.StopsLevel()*m_symb.Point() );

    m_shift_in_points         = normalizar( (EA_TOLERANCIA_ENTRADA*m_tick_size)/m_point ); // tolerancia permitida para entrada em algumas estrategias

    m_maior_sld_do_dia = m_cta.Balance(); // saldo da conta no inicio da sessao;
    m_sld_sessao_atu   = m_cta.Balance();
    m_capitalInicial   = m_cta.Balance();

    //BBCriar();

    m_comment_fixo = "LOGIN:"         + DoubleToString(m_cta.Login(),0) +
                     "  TRADEMODE:"   + m_cta.TradeModeDescription()    +
                     "  MARGINMODE:"  + m_cta.MarginModeDescription()   + 
                     " "              + m_release;
                   //"alavancagem:" + m_cta.Leverage()               + "\n" +
                   //"stopoutmode:" + m_cta.StopoutModeDescription() + "\n" +
                   //"max_ord_pend:"+ m_cta.LimitOrders()            + "\n" + // max ordens pendentes permitidas

    Comment(m_comment_fixo);

    m_trade.setVolLote ( m_symb.LotsMin() );

    //m_precoUltOrdemInBuy = 0;
    //m_precoUltOrdemInSel = 0;
  
    EventSetMillisecondTimer(EA_QTD_MILISEG_TIMER);
    Print(":-| Expert ", __FUNCTION__,":", " Criado Timer de ",EA_QTD_MILISEG_TIMER," milisegundos !!! " );
    Print(":-) Expert ", __FUNCTION__,":", " inicializado !! " );
    Print(":-| "       , __FUNCTION__,":",m_release);
    Print(":-| "       , __FUNCTION__,":",m_release);
    Print(":-| "       , __FUNCTION__,":",m_release);
    
    // melhorando a administracao do stop_loss quando o EA inicia em meio a uma posicao em andamento
    definirPasso();
    inicializarControlPanel();
    
    if( EA_LOGAR_TRADETRANSACTION ) m_pos.initLogCSV();//<TODO> RETIRE APOS TESTES
    m_pos.initialize();
    
//  if( EA_ACAO_POSICAO == HFT_ARBITRAGEM_PAR ){
//      m_par = new C0002ArbitragemPar;
//      m_par.initialize(EA_QTD_SEG_MEDIA_PRECO,EA_QTD_SEG_MEDIA_RATIO);
//      
//      m_est = m_par.getEstAtivo1(); // usando o ponteiro que jah eh atualizado pelo objeto de arbitragem.
//                                    // assim evitamos atualizar outro objeto estatistico.
//
//      m_symb_ref.Name( EA_TICKER_REF ); // inicializacao da classe CSymbolInfo do simbolo de referencia
//      m_symb_ref.Refresh            (); // propriedades do simbolo de referencia. Basta executar uma vez.
//      m_symb_ref.RefreshRates       (); // valores do tick. execute uma vez por tick.
//      
//      // aguardando a media de ratio ser totalmente calculada antes de abrir a primeira posicao
//      m_aguardar_para_abrir_posicao = EA_QTD_SEG_MEDIA_RATIO*1000;
//  }else{
        m_est = new osc_estatistic3;
        m_est.initialize(EA_EST_QTD_SEGUNDOS,false); // quantidade de segundos que serao usados no calculo da velocidade do volume e flag indicando que deve consertar ticks sem flag.
        m_est.setSymbolStr( m_symb_str );
//  }

    return(INIT_SUCCEEDED);
}


double m_len_canal_ofertas  = 0; // tamanho do canal de ofertas do book.
double m_len_barra_atual    = 0; // tamanho da barra de trades atual.
double m_volatilidade       = 0; // calculamos a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
double m_volTradePorSegMedio= 0;
double m_volTradePorSegQtd  = 1.0;
double m_volTradePorSegTot  = 0;
double m_volTradePorSeg     = 0; // volume de agressoes por segundo.

double m_volTradePorSegBuy  = 0; // volume de agressoes de compra por segundo.
double m_volTradePorSegSel  = 0; // volume de agressoes de venda  por segundo.
double m_volTradePorSegLiq  = 0;
double m_lenTradePorSeg     = 0; // tamanho do canal de ticks formado durante a acumulacao da estatistica. 

int    m_volTradePorSegDeltaPorc = 0; // % da diferenca do volume por segundo do vencedor. Se for positivo, o vencedor eh buy, se negativo eh sell. 

//ulong m_trefreshMe        = 0;
//ulong m_trefreshFeira     = 0;
//ulong m_trefreshTela      = 0;
//ulong m_trefreshRates     = 0;
//ulong m_tcontarTransacoes = 0;
//ulong m_tcloseRajada      = 0;

MqlTick m_tick_est, m_tick_est_ref;
osc_cusum m_cusum;
bool m_strikeHmais  =false; 
bool m_strikeHmenos =false; 
bool m_strikeCMais  =false; 
bool m_strikeCMenos =false;
void refreshMe(){

    //m_qtd_exec_refreshme++;
    
    m_symb.RefreshRates();
    
    // adicionando o tick ao componente estatistico...
//  if( EA_ACAO_POSICAO == HFT_ARBITRAGEM_PAR ){
//      SymbolInfoTick(EA_TICKER_REF,m_tick_est_ref);
//      SymbolInfoTick(m_symb_str   ,m_tick_est    );
//      m_par.addTick(m_tick_est    ,m_tick_est_ref);
//  }else{
        SymbolInfoTick(m_symb_str,m_tick_est);
        m_est.addTick(m_tick_est);
//  }

    m_cusum.calcC(  m_tick_est.last         , 
                    m_est.getPrecoMedTrade(), 
                    EA_KK         , //double K, 
                    EA_HH         , //double H, 
                    m_strikeHmais , 
                    m_strikeHmenos, 
                    m_strikeCMais , 
                    m_strikeCMenos);
   

    m_spread = m_tick_est.ask-m_tick_est.bid;
    
    m_volTradePorSegLiq=m_est.getVolTradeLiqPorSeg();
    m_volTradePorSegBuy=m_est.getVolTradeBuyPorSeg();
    m_volTradePorSegSel=m_est.getVolTradeSelPorSeg();
    m_lenTradePorSeg   = (m_est.getTradeHigh() - m_est.getTradeLow() )/m_tick_size; // tamanho do canal de ticks formado durante a acumulacao da estatistica. 
            
    m_trade.setStopLoss( m_stopLossOrdens );
    m_trade.setTakeProf( m_tkprof         );
    m_trade.setVolLote ( m_symb.LotsMin() );

  //m_ask     = m_symb.Ask();
  //m_bid     = m_symb.Bid();
    m_ask     = m_tick_est.ask;
    m_bid     = m_tick_est.bid;

    //m_ask_stplev = m_bid + m_stop_level_in_price; if( m_ask_stplev < m_ask ) m_ask_stplev = m_ask;
    //m_bid_stplev = m_ask - m_stop_level_in_price; if( m_bid_stplev > m_bid ) m_bid_stplev = m_bid;
    m_ask_stplev = m_ask + m_stop_level_in_price;
    m_bid_stplev = m_bid - m_stop_level_in_price;

    
    m_canal.refresh(m_ask,m_bid);
    
    // atualizando precos de abertura e fechamento da barra atual...
    //CopyRates(m_symb_str,_Period,0,2,m_rates);
    //m_high0   = m_rates[0].high;
    //m_low0    = m_rates[0].low ;
    //m_lenBar0 = m_high0-m_low0;
    //m_high1   = m_rates[1].high;
    //m_low1    = m_rates[1].low ;
    //m_lenBar1 = m_high1-m_low1;    
    // distancia desde entrada da ordem ateh o stop (quando trabalha com rajada fixa).
    //m_lenAteStop = (EA_DISTAN_PRIM_ORDEM_RAJ                     *m_tick_size)+
    //               (EA_DISTAN_DEMAIS_ORDENS_RAJ*EA_TAMANHO_RAJADA*m_tick_size);    
    
    m_qtdOrdens   = OrdersTotal();
    m_qtdPosicoes = PositionsTotal();
    
    // adminstrando posicao aberta...
    if( m_qtdPosicoes > 0 ){
        
        if ( PositionSelect  (m_symb_str) ){ // soh funciona em contas hedge
            
            if(m_tempo_posicao_ini == 0) m_tempo_posicao_ini = TimeCurrent();
            m_tempo_posicao_atu = TimeCurrent() - m_tempo_posicao_ini;
            
            m_qtdOrdensAnt = 0;

            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                setCompradoSoft();
            }else{
                setVendidoSoft();
            }
            
            m_posicaoProfit    =            PositionGetDouble (POSITION_PROFIT     )  ;
            m_precoPosicao     = normalizar(PositionGetDouble (POSITION_PRICE_OPEN ) ); // este eh o valor medio de abertura da posicao.
            m_val_order_4_gain = m_precoPosicao;                                        // que neste formato passamos para a variavel
                                                                                        // que anteriormente guardava o preco original
                                                                                        // de abertura da posicao.
            m_posicaoVolumePend      = PositionGetDouble (POSITION_VOLUME     );
            m_posicaoLotsPend        = m_posicaoVolumePend/m_lots_step         ;
            m_positionId             = PositionGetInteger(POSITION_IDENTIFIER );
          //m_positionCommentStr     = PositionGetString (POSITION_COMMENT    );
          //m_positionCommentNumeric = StringToInteger   (m_positionCommentStr);
            m_capitalLiquido         = m_cta.Equity();    
            
            
            
          //m_lucroPosicao = m_capitalLiquido - m_capitalInicial; // voltou versao em 03/02/2020 as 11:50
          //m_lucroPosicao = m_posicaoProfit; // passou a usar em 05/06/2020 jah que nessa estrategia as posicoes sao fechadas de vez. 
            m_lucroPosicao = m_capitalLiquido - m_capitalInicial; // voltou versao em 07/10/2020

            ///////////////////////////////////
            if( m_precoPosicaoAnt == 0 ){ m_precoPosicaoAnt = m_precoPosicao;}
            
            // preco da posicao mudou...
            if( m_precoPosicao   != m_precoPosicaoAnt ){
                m_precoPosicaoAnt = m_precoPosicao; // salvo no preco anterior
                m_qtd_ticks_4_gain_ini -= m_qtd_ticks_4_gain_decr ; // a cada movimentacao da posicao, reduzo a quantidade de ticks necessarios para o gain.
                Print(":-| "__FUNCTION__, " m_qtd_ticks_4_gain_ini=",m_qtd_ticks_4_gain_ini );
            } 

            definirPrecoSaidaPosicao();
            
            if( estouComprado() ){ 
                m_posicaoVolumeTot  = m_volComprasNaPosicao;
                
                //if( m_stop ){
                //    // testando acionamento do stop no calculo do preco de saida da posicao...
                //    m_precoSaidaPosicao = m_ask;
                //}else{
                //    m_precoSaidaPosicao = normalizar(m_precoPosicao +  m_qtd_ticks_4_gain_ini*m_tick_size);
                //}
            }else{
                if( estouVendido() ){ 
                    m_posicaoVolumeTot  = m_volVendasNaPosicao;
                    //if( m_stop ){
                    //    // testando acionamento do stop no calculo do preco de saida da posicao...
                    //    m_precoSaidaPosicao = m_bid;
                    //}else{
                    //    m_precoSaidaPosicao = normalizar(m_precoPosicao - m_qtd_ticks_4_gain_ini*m_tick_size);
                    //}
                }
            }
             
          //m_lucroPosicao4Gain = (m_posicaoVolumeTot *m_stop_porc);
          //m_lucroPosicao4Gain = (m_posicaoVolumeTot *m_qtd_ticks_4_gain_ini); // passou a usar em 05/06/2020
            m_lucroPosicao4Gain = (m_posicaoVolumePend*m_qtd_ticks_4_gain_ini); // passou a usar em 05/06/2020
            ///////////////////////////////////
        }else{
        
           // aqui neste bloco, estah garantido que nao ha posicao aberta...
           m_qtdPosicoes         = 0;
           m_volVendasNaPosicao  = 0;
           m_volComprasNaPosicao = 0;
           
           m_capitalInicial    =  m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
           m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI;
           m_comprado          =  false;
           m_vendido           =  false;
           m_stop              =  false;
           m_lucroPosicao      =  0;
           m_lucroPosicao4Gain =  0;
           m_posicaoVolumePend =  0; // versao 02-085
           m_posicaoLotsPend   =  0;
           m_posicaoProfit     =  0;
           m_posicaoVolumeTot  =  0;
           m_val_order_4_gain  =  0; // zerando o valor da primeira ordem da posicao...
           m_tempo_posicao_atu =  0;
           m_tempo_posicao_ini =  0;
           m_positionId        = -1;
           m_precoPosicaoAnt   = 0 ;
        }
    }else{
        // aqui neste bloco, estah garantido que nao ha posicao aberta...
        m_qtdPosicoes          = 0;
        m_volVendasNaPosicao   = 0;
        m_volComprasNaPosicao  = 0;

        m_capitalInicial       = m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
        m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI;
        m_comprado          = false;
        m_vendido           = false;
        m_stop              = false;
        m_lucroPosicao      = 0;
        m_lucroPosicao4Gain = 0;
        m_posicaoVolumePend = 0; //versao 02-085
        m_posicaoLotsPend   = 0;
        m_posicaoProfit     = 0;
        m_posicaoVolumeTot  = 0;
        m_val_order_4_gain  = 0; // zerando o valor da primeira ordem da posicao...
        m_tempo_posicao_atu = 0;
        m_tempo_posicao_ini = 0;
        m_positionId        = -1;
        m_precoPosicaoAnt   = 0 ;
        
        //Deixando o stop loss de posicao preparado. Quando posicionado, nao altera o stop loss de posicao.
        //calcStopLossPosicao();
    }

    m_sld_sessao_atu = m_cta.Balance();
    showAcao("normal");
} // refreshme()

void showAcao(string acao){
   
   if( !EA_SHOW_TELA ){ return; }
   
   Comment(
         //"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
         //"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
           " \n ticks_consertados="         ,m_est.getQtdTicksConsertados(),
           " \n m_cta.Balance="             ,m_cta.Balance          (),
           " \n m_cta.Equity="              ,m_cta.Equity           (),
           " \n m_cta.Profit="              ,m_cta.Balance() - m_cta.Equity(),
           " \n m_cta.Profit="              ,m_cta.Profit           (),
           " \n m_posicao.Profit= "         ,m_posicao.Profit       (),
           " \n m_posicao.Volume= "         ,m_posicao.Volume       (),
           " \n m_lucroPosicao4Gain="       ,m_lucroPosicao4Gain      ,
         //" \n m_passo_rajada="            ,m_passo_rajada           ,
           " \n m_tempo_posicao_atu="       ,m_tempo_posicao_atu      ,
         //" \n m_posicao.PriceOpen="       ,m_posicao.PriceOpen    (),
         //" \n m_posicao.PriceCurrent="    ,m_posicao.PriceCurrent (),
         //" \n acao="                      ,acao                     ,
           //----------------
           " \n len_canal="                 ,m_canal.getLenCanalOperacionalEmTicks(), 
           " \n regiaoSuperior="            ,m_canal.regiaoSuperior(), 
           " \n regiaoInferior="            ,m_canal.regiaoInferior(), 
           " \n precoregiaoSuperior="       ,m_canal.getPrecoRegiaoSuperior(), 
           " \n precoregiaoInferior="       ,m_canal.getPrecoRegiaoInferior(),
           //----------------
           " \n m_est.getInclinacaoHLTrade="    ,m_est.getInclinacaoHLTrade   (),
           " \n m_est.getInclinacaoHLTTradeBuy=",m_est.getInclinacaoHLTradeBuy(),
           " \n m_est.getInclinacaoHLTradeSel=" ,m_est.getInclinacaoHLTradeSel(),
           " \n FIXOS=================================================="                          ,
           " \n EA_DIST_MIN_IN_BOOK_IN_POS="              ,EA_DIST_MIN_IN_BOOK_IN_POS,
           " \n EA_LAG_RAJADA="                           ,EA_LAG_RAJADA                          ,
           " \n EA_QTD_TICKS_4_GAIN_INI="                 ,EA_QTD_TICKS_4_GAIN_INI                ,
           " \n EA_QTD_TICKS_4_GAIN_MIN="                 ,EA_QTD_TICKS_4_GAIN_MIN                ,
           " \n m_razao_lag_rajada_x_dist_entrada_book="  ,m_razao_lag_rajada_x_dist_entrada_book ,
           " \n DINAMICOS=================================================="                      ,
           " \n m_dist_min_in_book_in_pos="               ,m_dist_min_in_book_in_pos              ,
           " \n m_dist_min_in_book_out_pos="              ,m_dist_min_in_book_out_pos             ,
           " \n m_lag_rajada="                            ,m_lag_rajada                           
         //" \n SYMB=================================================="                           ,
         //" \n SessionAW="                              ,m_symb.SessionAW()                      ,
         //" \n BidHigh="                                ,m_symb.BidHigh()                        ,
         //" \n SessionOpen="                            ,m_symb.SessionOpen()
           );
}

void refreshControlPanel(){
  // refresh do painel eh no maximo uma vez por segundo...
  //if( m_date_atu.sec%2 == 0 ) return;

  if( !EA_SHOW_CONTROL_PANEL ) return;

  if( m_qtdPosicoes==0 ){ 
      m_cp.setPosicaoNula("NULL"); 
  }else{
      if (estouComprado()  ){ 
          m_cp.setPosicaoBuy ("BUY" ); 
      }else{    
          m_cp.setPosicaoSell("SELL");
      }
  }
  
  m_cp.setPasso        ((int)m_passo_rajada        );
  m_cp.setProfitPosicao(     m_lucroPosicao        );

//m_cp.setSaidaPosicao (     m_saida_posicao       );
  m_cp.setSaidaPosicao (     m_lucroPosicao4Gain   );

  m_cp.setStopLoss     (     m_stopLossPosicao     );
  m_cp.setT4g          (     m_qtd_ticks_4_gain_ini);
  m_cp.setVolPosicao   ( IntegerToString( (int)(m_posicaoLotsPend  ) ) + "/" +
                         IntegerToString( (int)(m_posicaoVolumeTot ) )
                       );
  m_cp.setPftBruto  ( m_trade_estatistica.getProfitDia        () );
  m_cp.setTarifa    ( m_trade_estatistica.getTarifaDia        () );
  m_cp.setPftContrat( m_trade_estatistica.getProfitPorContrato() );
  m_cp.setPftLiquido( m_trade_estatistica.getProfitDiaLiquido () );
  m_cp.setVol       ( m_trade_estatistica.getVolumeDia        () );


   //m_cp.setVolTradePorSegDeltaPorc( m_volTradePorSegDeltaPorc );
  ///m_cp.setVolTradePorSegDeltaPorc( m_exp.getLenCanalOperacionalEmTicks() );
   
  m_cp.setVTLiq ( m_volTradePorSegLiq, m_volTradePorSegLiqAnt );
  m_cp.setVTBuy ( m_volTradePorSegBuy      ); 
  m_cp.setVTSel ( m_volTradePorSegSel      );
  m_cp.setVTDir ( m_direcaoVelVolTrade   ,0);
  m_cp.setVTLen ( m_lenTradePorSeg         );
  m_cp.setVTDir2( m_direcaoVelVolTradeMed,0);
  m_cp.setLEN0  ( m_canal.getLenCanalOperacionalEmTicks(),0);
  m_cp.setLEN1  ( m_canal.getCoefLinear(),0);
}

bool passoAutorizado(){ 
    if( EA_PASSO_DINAMICO ){
        return m_qtd_ticks_4_gain_new >= EA_PASSO_DINAMICO_MIN && m_qtd_ticks_4_gain_new < EA_PASSO_DINAMICO_MAX;
    }
    return true;
}

//int m_passo_incremento = 0;
//void incrementarPasso(){
//
//    if( m_passo_incremento == 0) return;
//    
//  //m_qtd_ticks_4_gain_new += (int)(m_qtd_ticks_4_gain_new*m_passo_incremento);
//    m_qtd_ticks_4_gain_new += m_passo_incremento;
//      
//    m_qtd_ticks_4_gain_ini = m_qtd_ticks_4_gain_new;
//    m_qtd_ticks_4_gain_raj = m_qtd_ticks_4_gain_new;
//    m_passo_rajada         = m_qtd_ticks_4_gain_new;
//    m_stop_porc            = m_stop_porc/m_passo_incremento;
//}




int    m_dist_min_in_book_in_pos              = 0;//EA_DIST_MIN_IN_BOOK_IN_POS; //DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK  ABRINDO POSICAO
int    m_dist_min_in_book_out_pos             = 0;//EA_DIST_MIN_IN_BOOK_OUT_POS; //DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK FECHANDO POSICAO
int    m_lag_rajada                           = 0;//EA_LAG_RAJADA                          ; //LAG_RAJADA
double m_razao_lag_rajada_x_dist_entrada_book = 0;//(double)EA_DIST_MIN_IN_BOOK_IN_POS/(double)EA_LAG_RAJADA;
void definirPasso(){

   if( EA_ALVO_DINAMICO ){
   
       if( EA_TAMANHO_RAJADA==0 ) return;

       if( EA_ACAO_POSICAO == HFT_FORMADOR_DE_MERCADO ){
           m_razao_lag_rajada_x_dist_entrada_book = (double)EA_DIST_MIN_IN_BOOK_IN_POS/oneIfZero( (double)EA_LAG_RAJADA );
           m_qtd_ticks_4_gain_ini                 =      ceil( m_canal.getLenCanalOperacionalEmTicks()/(double)(EA_TAMANHO_RAJADA*2.0 +(m_razao_lag_rajada_x_dist_entrada_book)*2.0 ) );
           if(m_qtd_ticks_4_gain_ini<EA_QTD_TICKS_4_GAIN_MIN) m_qtd_ticks_4_gain_ini=EA_QTD_TICKS_4_GAIN_MIN;
           m_lag_rajada                           = (int)ceil(m_qtd_ticks_4_gain_ini);
           m_passo_rajada                         = m_lag_rajada; //nao eh usado. Eh soh pra aparecer no painel de controle.
           m_dist_min_in_book_in_pos              = (int)ceil(m_lag_rajada*m_razao_lag_rajada_x_dist_entrada_book);
           m_dist_min_in_book_out_pos             = (int)ceil(m_lag_rajada*m_razao_lag_rajada_x_dist_entrada_book); //<todo> consertar
           
       }else{
           m_qtd_ticks_4_gain_ini    = m_canal.getLenCanalOperacionalEmTicks()/(double)EA_TAMANHO_RAJADA;
                                                 
           m_passo_rajada            = (int)floor(  ( m_canal.getLenCanalOperacionalEmTicks()-
                                                      m_canal.getLenCanalOperacionalEmTicks()*
                                                      EA_PORC_REGIAO_OPERACIONAL_CANAL         )/(double)EA_TAMANHO_RAJADA
                                            );

         //m_passo_rajada                      = floor( m_qtd_ticks_4_gain_ini );
           if( m_passo_rajada == 0 ) m_passo_rajada = 1;
           m_raj_unica_distancia_demais_ordens = m_passo_rajada;
           m_raj_unica_distancia_prim_ordem    = m_passo_rajada;
           m_qtd_ticks_4_gain_decr             = m_qtd_ticks_4_gain_ini/(double)EA_TAMANHO_RAJADA;
         //m_qtd_ticks_4_gain_decr             = 0;   // testando 1 tick
           
           m_raj_unica_distancia_prim_ordem    = m_passo_rajada;
           m_raj_unica_distancia_demais_ordens = m_passo_rajada;

       }
     
   }

   if( EA_PASSO_DINAMICO ){
       m_qtd_ticks_4_gain_ini =            m_qtd_ticks_4_gain_new;
       m_qtd_ticks_4_gain_raj =            m_qtd_ticks_4_gain_new;
       m_passo_rajada         =      (int)(m_qtd_ticks_4_gain_new*EA_PASSO_DINAMICO_PORC_T4G);
       if( m_passo_rajada < EA_PASSO_DINAMICO_MIN )  m_passo_rajada = EA_PASSO_DINAMICO_MIN;
           
       m_stop_qtd_contrat = EA_PASSO_DINAMICO_STOP_QTD_CONTRAT; 
       m_stop_chunk       = EA_PASSO_DINAMICO_STOP_CHUNK;
       m_stop_porc        = m_qtd_ticks_4_gain_new*EA_PASSO_DINAMICO_STOP_REDUTOR_RISCO;
   }
}

// criando o painel de controle do expert...
bool inicializarControlPanel(){
    if(!EA_SHOW_CONTROL_PANEL) return true ;
    if(!m_cp.Create()        ) return false; // create application dialog
    if(!m_cp.Run()           ) return false; // run application
    return true;
}




    //----------------------------------------------------------------------------------------
    // tem de ser o primeiro ponto pois ha varios a frente que dependem do simbolo configurado
    //----------------------------------------------------------------------------------------
void inicializarSimbolo(){
    Print(":-| ", __FUNCTION__," ******************************** Inicializando simbolo...");
    m_symb.Name( Symbol() ); // inicializacao da classe CSymbolInfo
    m_symb_str = Symbol();
    m_symb.Refresh     (); // propriedades do simbolo. Basta executar uma vez.
    m_symb.RefreshRates(); // valores do tick. execute uma vez por tick.
    m_tick_size         = m_symb.TickSize(); //Obtem a alteracao minima de preco
    m_point             = m_symb.Point()   ;
    m_lots_step         = m_symb.LotsStep();
    Print(":-| ", __FUNCTION__," m_symb_str :", m_symb_str       );
    Print(":-| ", __FUNCTION__," m_tick_size:", m_tick_size      );
    Print(":-| ", __FUNCTION__," m_point    :", m_point          );
    Print(":-| ", __FUNCTION__," m_lots_step:", m_lots_step      );
    Print(":-| ", __FUNCTION__," ******************************** Simbolo inicializado.>");
}

double m_passo_dinamico_porc_canal_entrelaca = 0;
double m_stopLossPosicao                     = 0;

void inicializarVariaveisRecebidasPorParametro(){

    Print(":-| ", __FUNCTION__," ******************************** Inicializando variaveis diversas...");
    m_aguardar_para_abrir_posicao = EA_SLEEP_INI_OPER*1000;
    
    m_tipo_entrada_permitida = EA_TIPO_ENTRADA_PERMITIDA;

    // stop loss da posicao
    m_stopLossPosicao = EA_STOP_LOSS;
    //m_stopLossPosicao = m_exp.getStopLoss();//EA_STOP_LOSS

    // O quanto a volatilidade por segundo deve ser maior que a volatilidade por segundo media para ser considerada alta.
    // Volatilidade por segundo eh o tamanho do canal de transacoes dividido pela quantidade de segundos do indicador feira.
    //m_volat4s_alta_porc = m_exp.getVolat4sAltaPorc();// EA_VOLAT4S_ALTA_PORC;

    // quantidade de periodos usados para calcular o coeficiente de entrelacamento.
    //m_exp.setEntrelacaPeriodoCoef(EA_ENTRELACA_PERIODO_COEF);
    

    // variaveis de controle do stop...
    m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI;
    m_qtd_ticks_4_gain_raj = EA_QTD_TICKS_4_GAIN_INI;
    m_vol_lote_raj         = EA_VOL_PRIM_ORDEM_RAJ!=0?EA_VOL_PRIM_ORDEM_RAJ*m_lots_step:m_symb.LotsMin();
    m_vol_lote_ini         = EA_VOL_LOTE_INI      !=0?EA_VOL_LOTE_INI      *m_lots_step:m_symb.LotsMin();
    m_passo_rajada         = (int)EA_DISTAN_DEMAIS_ORDENS_RAJ;
    m_stop_qtd_contrat     = (int)EA_STOP_CHUNK;
    m_stop_chunk           = (int)EA_STOP_CHUNK;
    m_stop_porc            = EA_STOP_PORC_L1;
    
    // operacao com rajada unica.
    m_raj_unica_distancia_prim_ordem    = EA_DISTAN_PRIM_ORDEM_RAJ   ==0?m_qtd_ticks_4_gain_ini:EA_DISTAN_PRIM_ORDEM_RAJ   ; // se param for zero, usa EA_DISTAN_PRIM_ORDEM_RAJ
    m_raj_unica_distancia_demais_ordens = EA_DISTAN_DEMAIS_ORDENS_RAJ==0?m_qtd_ticks_4_gain_ini:EA_DISTAN_DEMAIS_ORDENS_RAJ; // se param for zero, usa EA_DISTAN_DEMAIS_ORDENS_RAJ
    m_qtd_ticks_4_gain_decr             = EA_QTD_TICKS_4_GAIN_DECR;
    m_Cmedia_direcaoVelocidadeTradeMedia.initialize(EA_EST_QTD_SEGUNDOS);
    
    Print(":-| ", __FUNCTION__," m_aguardar_para_abrir_posicao       :", m_aguardar_para_abrir_posicao      );
    Print(":-| ", __FUNCTION__," m_tipo_entrada_permitida            :", m_tipo_entrada_permitida           );
    Print(":-| ", __FUNCTION__," m_stopLossPosicao                   :", m_stopLossPosicao                  );
    Print(":-| ", __FUNCTION__," m_qtd_ticks_4_gain_ini              :", m_qtd_ticks_4_gain_ini             );
    Print(":-| ", __FUNCTION__," m_qtd_ticks_4_gain_raj              :", m_qtd_ticks_4_gain_raj             );
    Print(":-| ", __FUNCTION__," m_vol_lote_raj                      :", m_vol_lote_raj                     );
    Print(":-| ", __FUNCTION__," m_vol_lote_ini                      :", m_vol_lote_ini                     );
    Print(":-| ", __FUNCTION__," m_passo_rajada                      :", m_passo_rajada                     );
    Print(":-| ", __FUNCTION__," m_stop_qtd_contrat                  :", m_stop_qtd_contrat                 );
    Print(":-| ", __FUNCTION__," m_stop_chunk                        :", m_stop_chunk                       );
    Print(":-| ", __FUNCTION__," m_stop_porc                         :", m_stop_porc                        );
    Print(":-| ", __FUNCTION__," m_raj_unica_distancia_prim_ordem    :", m_raj_unica_distancia_prim_ordem   );
    Print(":-| ", __FUNCTION__," m_raj_unica_distancia_demais_ordens :", m_raj_unica_distancia_demais_ordens);
    Print(":-| ", __FUNCTION__," m_qtd_ticks_4_gain_decr             :", m_qtd_ticks_4_gain_decr            );
    Print(":-| ", __FUNCTION__," m_Cmedia_direcaoVelocidadeTradeMedia:", EA_EST_QTD_SEGUNDOS," seg"         );
    Print(":-| ", __FUNCTION__," ******************************** Variaveis diversas inicializadas."        );
}

void inicializarPassoRajadaFixoHFT_FORMADOR_DE_MERCADO(){
    Print(":-| ", __FUNCTION__," ******************************** Inicializando variaveis HFT_FORMADOR_DE_MERCADO...");
    m_dist_min_in_book_in_pos              = EA_DIST_MIN_IN_BOOK_IN_POS ; //DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK ABRINDO POSICAO
    m_dist_min_in_book_out_pos             = EA_DIST_MIN_IN_BOOK_OUT_POS; //DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK FECHANDO POSICAO
    m_razao_lag_rajada_x_dist_entrada_book = (double)EA_DIST_MIN_IN_BOOK_IN_POS/ oneIfZero( (double)EA_LAG_RAJADA );
    //m_qtd_ticks_4_gain_ini                 = EA_QTD_TICKS_4_GAIN_INI;
    //if(m_qtd_ticks_4_gain_ini<EA_QTD_TICKS_4_GAIN_MIN) m_qtd_ticks_4_gain_ini=EA_QTD_TICKS_4_GAIN_MIN;
    m_lag_rajada                           = EA_LAG_RAJADA;
    m_passo_rajada                         = m_lag_rajada; //nao eh usado. Eh soh pra aparecer no painel de controle.

    Print(":-| ", __FUNCTION__," m_dist_min_in_book_in_pos             :", m_dist_min_in_book_in_pos               ,": DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK ABRINDO  POSICAO");
    Print(":-| ", __FUNCTION__," m_dist_min_in_book_out_pos            :", m_dist_min_in_book_out_pos              ,": DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK FECHANDO POSICAO");
    Print(":-| ", __FUNCTION__," m_razao_lag_rajada_x_dist_entrada_book:", m_razao_lag_rajada_x_dist_entrada_book  );
    Print(":-| ", __FUNCTION__," m_lag_rajada                          :", m_lag_rajada                            );
    Print(":-| ", __FUNCTION__," m_passo_rajada                        :", m_passo_rajada                          );
    Print(":-| ", __FUNCTION__," ******************************** Variaveis HFT_FORMADOR_DE_MERCADO inicializadas.");
}


// retorna a porcentagem como um numero inteiro.
int porcentagem( double parte, double tot, int seTotZero){
    if( tot==0 ){ return seTotZero ; }
                  return (int)( (parte/tot)*100.0);
}

int m_qtd_print_debug = 0;


void fecharTudoForcado(string descr){
    m_trade.cancelarOrdens(descr);
    
    if( PositionsTotal()>0 ){
        long idPos = PositionGetInteger(POSITION_IDENTIFIER);
        m_trade.PositionClose(idPos);
    }
}

bool m_stop = false;
void fecharTudo(string descr){ fecharTudo(descr,"",EA_STOP_TICKS_TOLER_SAIDA); }
void fecharTudo(string descr,string strLog){ fecharTudo(descr,strLog,EA_STOP_TICKS_TOLER_SAIDA); }
void fecharTudo(string descr, string strLog, int qtdTicksDeslocamento){
    if( m_qtdPosicoes>0 ){
    
        //////////////////////////////////////////////////////////////////////////////////
        // testando acionamento do stop usando o preco de saida da posicao...
        //
        // soh imprime no log uma vez por stop...
        //if(m_stop==false) Print(":-| ", __FUNCTION__,"(",descr,",",strLog,",",qtdTicksDeslocamento,")");

        m_stop = true;
        definirPrecoSaidaPosicao();
        if( alterarPrecoOrdensSaidaSeNecessario() ) Print(":-| ", __FUNCTION__,"(",descr,",",strLog,",",qtdTicksDeslocamento,")");
        return;
        //
        //////////////////////////////////////////////////////////////////////////////////

        int    qtd = 1;
        string qtdStr;
        string qtdTicksdesloc = IntegerToString(qtdTicksDeslocamento);
      //while( m_qtdPosicoes > 0 ){
            qtdStr = IntegerToString(qtd++);
            Print   (":-| ", __FUNCTION__,":",qtdStr,":fecharPosicao2(",descr,",",strLog,",",qtdTicksdesloc,")");
            fecharPosicao2(descr, strLog, qtdTicksDeslocamento);
      //}
    }else{
        Print   (__FUNCTION__+":m_trade.cancelarOrdens():descr:"+descr);
        m_trade.cancelarOrdens(descr);
        if( m_stop == true ) m_stop = false;
    }
}

// se o preco de saida da posicao mudou, altera o preco das ordens de saida, a menos que o EA feche posicao por ordem de entrada e nao no breakeven...
bool alterarPrecoOrdensSaidaSeNecessario(){

    
    if( !EA_FECHA_POSICAO_NO_BREAK_EVEN && !m_stop ) return false;
    
    if( m_precoSaidaPosicao!=m_precoSaidaPosicaoAnt || m_stop ){
        m_precoSaidaPosicaoAnt = m_precoSaidaPosicao;
        m_trade.alterarValorDeOrdensNumericasPara(m_symb_str,m_precoSaidaPosicao,m_precoPosicao);
        return true;
    }
    return false;
}

void fecharPosicao2(string descr, string strLog, int qtdTicksDeslocamento=0, int deep=1){
      
      Print(":-| ", __FUNCTION__,"(",descr,",",strLog,",",qtdTicksDeslocamento,",",deep,")");
      
      //<TODO> Este item 1, eh incompativel com novo metodo de fechamento de posicao. Por enquanto
      //       deixo comentado afim de testar. Resova durante ou logo apos os testes.
      //
      //1. providenciando ordens de fechamento que porventura faltem na posicao... 
      //Print   (":-| ", __FUNCTION__+":doCloseRajada(",m_passo_rajada,",",m_vol_lote_raj,",",m_qtd_ticks_4_gain_raj,")...");
      //doCloseRajada(m_qtd_ticks_4_gain_ini);
      
      //2. cancelando rajadas que ainda nao entraram na posicao...
      Print   (":-| ", __FUNCTION__+":cancelarOrdensRajada()..."          );
      cancelarOrdensRajada();
      
      //3. trazendo ordens de fechamento a valor presente...
      Print   (":-| ", __FUNCTION__+":trazerOrdensComComentarioNumerico2valorPresente(",m_symb_str,",",qtdTicksDeslocamento,")...");
      m_trade.trazerOrdensComComentarioNumerico2valorPresente(m_symb_str,qtdTicksDeslocamento);
      
      //4. aguardando a execucao das ordens de fechamento...
      Sleep(1000); //<TODO> transforme em parametro
      
      //5. refresh pra saber a situacao atual...
      Print   (":-| ", __FUNCTION__+":refreshMe()..."          );
      refreshMe();
      
      //6. se ainda estamos posicionados, realiza todos os passos novamente...
      if( m_qtdPosicoes > 0 && deep < 5 ){ 
          Print   (":-| ",__FUNCTION__+":fecharPosicao2(",descr,",",strLog,",",qtdTicksDeslocamento,",",deep,")");
          fecharPosicao2(descr, strLog, qtdTicksDeslocamento,++deep); 
      }
      
      // pra que nao cancele ordens de fechamento de posicao...
      if( m_qtdPosicoes > 0 ) return;
      
      //7. cancelando outras ordens pendentes...
      Print   (":-| ",__FUNCTION__+":cancelarOrdens(",descr,")");
      m_trade.cancelarOrdens(descr);
}

void fecharPosicao3(string descr, string strLog, int qtdTicksDeslocamento=0, int deep=1){
      
      Print(":-| ", __FUNCTION__,"(",descr,",",strLog,",",qtdTicksDeslocamento,",",deep,")");
      
      //<TODO> Este item 1, eh incompativel com novo metodo de fechamento de posicao. Por enquanto
      //       deixo comentado afim de testar. Resova durante ou logo apos os testes.
      //
      //1. providenciando ordens de fechamento que porventura faltem na posicao... 
      //Print   (":-| ", __FUNCTION__+":doCloseRajada(",m_passo_rajada,",",m_vol_lote_raj,",",m_qtd_ticks_4_gain_raj,")...");
      //doCloseRajada(m_qtd_ticks_4_gain_ini);
      
      //2. cancelando rajadas que ainda nao entraram na posicao...
      Print   (":-| ", __FUNCTION__+":cancelarOrdensRajada()..."          );
      cancelarOrdensRajada();
      
      //3. trazendo ordens de fechamento a valor presente...
      Print   (":-| ", __FUNCTION__+":trazerOrdensComComentarioNumerico2valorPresente(",m_symb_str,",",qtdTicksDeslocamento,")...");
      m_trade.trazerOrdensComComentarioNumerico2valorPresente(m_symb_str,qtdTicksDeslocamento);
      
      //4. aguardando a execucao das ordens de fechamento...
      Sleep(1000); //<TODO> transforme em parametro
      
      //5. refresh pra saber a situacao atual...
      Print   (":-| ", __FUNCTION__+":refreshMe()..."          );
      refreshMe();
      
      //6. se ainda estamos posicionados, realiza todos os passos novamente...
      if( m_qtdPosicoes > 0 && deep < 5 ){ 
          Print   (":-| ",__FUNCTION__+":fecharPosicao3(",descr,",",strLog,",",qtdTicksDeslocamento,",",deep,")");
          fecharPosicao3(descr, strLog, qtdTicksDeslocamento,++deep);
      }

      m_trade.fecharPosicao("F3emergencia");
      
      // pra que nao cancele ordens de fechamento de posicao...
      if( m_qtdPosicoes > 0 ) return;
      
      //7. cancelando outras ordens pendentes...
      Print   (":-| ",__FUNCTION__+":cancelarOrdens(",descr,")");
      m_trade.cancelarOrdens(descr);
}



void cancelarOrdensRajada(){ 
    m_trade.cancelarOrdensComentadas(m_symb_str, m_strRajada);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
long m_sec_ontick = -1;
void OnTick(){

    // executando o ontick uma vez por segundo.
    //if( m_date_atu.sec == m_sec_ontick && m_qtd_ticks_4_gain_ini > 5 ) return;
    m_sec_ontick = m_date_atu.sec;

    refreshMe();

    if ( m_qtdPosicoes > 0 ) {
    
        // Esta opcao NAO_OPERAR nao interfere nas ordens...
        if( EA_ACAO_POSICAO == NAO_OPERAR ) return;

        m_qtdOrdensAnt = 0;

        // estah na hora de fechar as posicoes...
        if( m_eh_hora_de_fechar_posicao ){ 
            Print(__FUNCTION__, " :-| HORA DE TERMINAR A OPERACAO. FECHANDO TUDO E SAINDO...");
            fecharTudoForcado("HORA_DE_FECHAR_POSICAO"); 
            ExpertRemove(); 
        }

        // se controlarRiscoDaPosicao() retornar true, significa que acionou um stop, entao retornamos daqui.
        if( controlarRiscoDaPosicao() ){ return; }

        if( emLeilao() )return;
        
      //if( EA_ACAO_POSICAO == HFT_FORMADOR_DE_MERCADO ) definirPasso();
                                                         definirPasso();

        alterarPrecoOrdensSaidaSeNecessario();
        
        // Na estrategia HFT_FORMADOR_DE_MERCADO, mantemos a fila de ordens de entrada aberta, mesmo 
        // durante a vida de uma posicao. Assim pretendemos ganhar prioridade ao chegar no nivel zero do book.  
      //if (EA_ACAO_POSICAO == HFT_FORMADOR_DE_MERCADO) abrirPosicaoHFTPrioridadeNoBook();
                                                        abrirPosicaoHFTPrioridadeNoBook();

    }else{
        
        m_time_analisado = 0; // pra que as posicoes abertas sejam analisadas no mesmo periodo de uma posicao que jah fechou.

        definirPasso();
        // Esta opcao NAO_OPERAR nao interfere nas ordens...
        if( EA_ACAO_POSICAO == NAO_OPERAR ) return;
        
        if( m_qtdOrdens > 0 ){
           if( m_acionou_stop_rebaixamento_saldo             ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return;}

           // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
           if( EA_ACAO_POSICAO == FECHAR_POSICAO          ){ cancelarOrdens("OPCAO_FECHAR_POSICAO"         ); return; }
           if( EA_ACAO_POSICAO == FECHAR_POSICAO_POSITIVA ){ cancelarOrdens("OPCAO_FECHAR_POSICAO_POSITIVA"); return; }

           // cancela as ordens existentes e nao abre novas ordens se o spread for maior que maximo.
           if( spreadMaiorQueMaximoPermitido()            ){ cancelarOrdens( "SPREAD_ALTO_" + DoubleToString( m_spread,2 ) ); return; }

           // cancelando todas as ordens que nao sejam de abertura de posicao...
           if( m_qtdOrdensAnt != m_qtdOrdens ){
               m_trade.cancelarOrdensExcetoComTxt(m_apmb,"CANC_NOT_APMB");
               m_qtdOrdensAnt = m_qtdOrdens; // para diminuir a quantidade de pedidos de cancelamento repetidos 
           }
           
           // nao estah no intervalo de negociacao, tem ordens abertas e nao tem posicao aberta, entao cancelamos todas as ordens.
           if( !m_estah_no_intervalo_de_negociacao ){ 
              m_trade.cancelarOrdens("INTERVALO_NEGOCIACAO");
           }
        }

        // fora do intervalo de negociacao nao abrimos novas ordens...
        // <TODO> Verifique porque esta chamada estah antes da checagem de rebaixamento de saldo. Acho que deveria ficar imediatamente antes das chamadas de abertura de novas posicoes.
        if( !m_estah_no_intervalo_de_negociacao ) return;

        /////////////////////////////////////////////////////////////////////////////////////
        // mudou o dia, atualizamos o saldo da sessao...
        if( m_mudou_dia ){
            Print( __FUNCTION__, " :-| MUDOU O DIA! Zerando rebaixamento de saldo...");
            m_mudou_dia                       = false          ;
            m_acionou_stop_rebaixamento_saldo = false          ;
            m_maior_sld_do_dia                = m_cta.Balance();
            m_rebaixamento_atu                = 0              ;
            m_time_in_seconds_ini_day         = StringToTime( TimeToString( TimeCurrent(), TIME_DATE ) );
        }

        // saldo da conta subiu, atualizamos o saldo da sessao pra controle do rebaixamento maximo do dia.
        if( m_sld_sessao_atu > m_maior_sld_do_dia ){
            m_maior_sld_do_dia = m_sld_sessao_atu;
            m_rebaixamento_atu = 0;
        }else{
            m_rebaixamento_atu = m_maior_sld_do_dia - m_sld_sessao_atu; // se houver rebaixamento, esse numero fica positivo;
        }

        // saldo da conta rebaixou mais que o permitido pra sessao.
        //if ( m_rebaixamento_atu  != 0  &&
        //     EA_STOP_REBAIXAMENTO_MAX != 0  &&
        //     EA_STOP_REBAIXAMENTO_MAX  < m_rebaixamento_atu ){

        //if ( EA_STOP_REBAIXAMENTO_MAX                      != 0 &&
        //     m_trade_estatistica.getRebaixamentoSld() < -EA_STOP_REBAIXAMENTO_MAX ){

        //if( saldoRebaixouMaisQuePermitidoNoDia() ){
        //     if( !m_acionou_stop_rebaixamento_saldo ){ // eh pra nao fical escrevendo no log ateh a sessao seguinte caso rebaixe o saldo.
        //          Print(":-( Acionando STOP_REBAIXAMENTO_DE_CAPITAL. ", strPosicao() );
        //          fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL");
        //          m_acionou_stop_rebaixamento_saldo = true;
        //     }
        //   return;
        //}
        /////////////////////////////////////////////////////////////////////////////////////

        definirPasso();

        // verificando proibicoes de operar
        if (! podeAbrirProsicao() ) { 
            m_trade.cancelarOrdensExcetoComTxt("STOP","NAO_PODE_ABRIR_POSICAO"); 
            return;
        }

        switch(EA_ACAO_POSICAO){
            case HFT_OPERAR_VOLUME_CANAL   : abrirPosicaoHFTVolumeCanal       (); break;
            case HFT_FORMADOR_DE_MERCADO   : abrirPosicaoHFTPrioridadeNoBook  (); break;
          //case HFT_ARBITRAGEM_PAR        : abrirPosicaoHFTarbitragemPar     (); break;
          //case HFT_DESBALANC_BOOK        : abrirPosicaoHFTDesbalancBook     (); break;
          //case HFT_FLUXO_ORDENS          : abrirPosicaoHFTfluxoOrdens       (); break;
          //case NAO_ABRIR_POSICAO         :                                      break;
        }
    }
}//+------------------------------------------------------------------+

bool podeAbrirProsicao(){
  
  if( m_aguardar_para_abrir_posicao > 0 ) return false; // soh abre novas posicoes apos zerar a penalidade de tempo do dia...
  if( spreadMaiorQueMaximoPermitido()   ) return false;
  
  return true; //<TODO> tirar pois eh soh pra teste
}

bool saldoRebaixouMaisQuePermitidoNoDia(){ return ( EA_STOP_REBAIXAMENTO_MAX != 0 && m_trade_estatistica.getRebaixamentoSld () > EA_STOP_REBAIXAMENTO_MAX ); }
bool saldoAtingiuObjetivoDoDia         (){ return ( EA_STOP_OBJETIVO_DIA     != 0 && m_trade_estatistica.getProfitDiaLiquido() > EA_STOP_OBJETIVO_DIA     ); }

double m_precoPosicao         = 0; // valor medio de entrada da posicao
double m_precoPosicaoAnt      = 0;
double m_precoSaidaPosicao    = 0;
double m_precoSaidaPosicaoAnt = 0;

/*
void controlarRiscoDaPosicao2(){
   
   // 1. se preco de entrada da posicao nao mudou, entao nao fazemos nada...
   if(m_precoPosicao==m_precoPosicaoAnt) return;
   m_precoPosicaoAnt = m_precoPosicao;
   
   // 2. calcule o preco de saida...
   if( estouComprado() ){
       m_precoSaidaPosicao = normalizar( m_precoPosicao + m_qtd_ticks_4_gain_ini*m_tick_size );
       if( m_precoSaidaPosicao < m_precoPosicao){
           m_precoSaidaPosicao = normalizar(m_precoSaidaPosicao + m_qtd_ticks_4_gain_ini*m_tick_size);
       }
   }else{
       m_precoSaidaPosicao = normalizar( m_precoPosicao - m_qtd_ticks_4_gain_ini*m_tick_size );
       if( m_precoSaidaPosicao > m_precoPosicao){
           m_precoSaidaPosicao = normalizar(m_precoSaidaPosicao - m_qtd_ticks_4_gain_ini*m_tick_size);
       }
   }
      
   // 3. se o preco de saida eh igual ao anterior, retorne sem fazer nada...
   if(m_precoSaidaPosicao==m_precoSaidaPosicaoAnt) return;
   m_precoSaidaPosicaoAnt = m_precoSaidaPosicao;
   
   // 4. movendo ordens pendentes numericas para o preco de saida...
   m_trade.alterarValorDeOrdensNumericasPara(m_symb_str,m_precoSaidaPosicao, m_precoPosicao);
   
   return;
}
*/

void definirPrecoSaidaPosicao(){
    if( estouComprado() ){ 
        if( m_stop ){
            // testando acionamento do stop no calculo do preco de saida da posicao...
            m_precoSaidaPosicao = m_ask;
        }else{
            m_precoSaidaPosicao = normalizar(m_precoPosicao +  m_qtd_ticks_4_gain_ini*m_tick_size);
        }
    }else{
        if( estouVendido() ){ 
            if( m_stop ){
                // testando acionamento do stop no calculo do preco de saida da posicao...
                m_precoSaidaPosicao = m_bid;
            }else{
                m_precoSaidaPosicao = normalizar(m_precoPosicao - m_qtd_ticks_4_gain_ini*m_tick_size);
            }
        }
    }
}

bool controlarRiscoDaPosicao(){

     // prevenindo varias execucoes antes que as ordens de fechamento sejam executadas...
     //if( m_stop == true ) return true;

     if( saldoRebaixouMaisQuePermitidoNoDia() ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return true;}

     // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
     if( EA_ACAO_POSICAO == FECHAR_POSICAO                                 ) { fecharTudo("STOP_FECHAR_POSICAO"         ,"STOP_FECHAR_POSICAO"         ); return true; }
     if( EA_ACAO_POSICAO == FECHAR_POSICAO_POSITIVA && m_posicaoProfit > 0 ) { fecharTudo("STOP_FECHAR_POSICAO_POSITIVA","STOP_FECHAR_POSICAO_POSITIVA"); return true; }

     // STOP REGIAO CANAL ( em teste...)
  // if( ( estouComprado() && m_canal.regiaoInferior() ) ||
  //     ( estouVendido()  && m_canal.regiaoSuperior() )    ){
  //     Print(":-( ",__FUNCTION__," Acionando STOP_LOSS_REGIAO_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
  //     fecharTudo("STOP_LOSS_REGIAO_" + DoubleToString(m_lucroPosicao,0) );
  //     return true;
  // }
     
     // STOP RISCO ANALISADO            
     // sai se risco estah alto e prejuizo estah maior que a metade do stop loss
     //if( m_stopLossPosicao != 0 && m_lucroPosicao < m_stopLossPosicao/2 && m_capitalInicial != 0 ){
     //    
     //    // analisando risco da posicao...
     //    m_mercado_modelo.CalcularRisco(m_est         ,
     //                                   m_riscoVenda  ,
     //                                   m_riscoCompra );
     //    if( ( estouComprado() && m_riscoCompra > EA_RISCO_MAX_POSICAO ) ||
     //        ( estouVendido()  && m_riscoVenda  > EA_RISCO_MAX_POSICAO )    ){
     //
     //        Print(":-( ",__FUNCTION__," Acionando STOP_LOSS_RISCO_"+ DoubleToString(m_lucroPosicao,0), " m_stopLossPosicao/2:",m_stopLossPosicao/2, strPosicao() );
     //        fecharTudo("STOP_LOSS_RISCO_" + DoubleToString(m_lucroPosicao,0) );
     //        return true;
     //    }
     //}
     
     if( m_stopLossPosicao != 0 && m_lucroPosicao < m_stopLossPosicao && m_capitalInicial != 0 ){
         //Print(":-( ",__FUNCTION__," Acionando STOP_LOSS_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
         fecharTudo("STOP_LOSS_" + DoubleToString(m_lucroPosicao,0) );
         return true;
     }
     
     // fecha a posicao ativa a mais de 10 min
   //if( m_tempo_posicao_atu > EA_STOP_10MINUTOS && EA_STOP_10MINUTOS > 0 && m_posicaoProfit >= 0 ){
     if( m_tempo_posicao_atu > EA_STOP_10MINUTOS && EA_STOP_10MINUTOS > 0                         ){
         //Print(":-( ",__FUNCTION__," Acionando STOP_TEMPO_ALTO_"+ DoubleToString(m_lucroPosicao,0)," T=",m_tempo_posicao_atu," ", strPosicao() );
         m_lucroStops += m_lucroPosicao;
         fecharTudo("STOP_TEMPO_ALTO_"+ DoubleToString(m_lucroPosicao,0));
         return true;
     }

     // fecha a posicao ativa se a quantidade de contratos pendentes for maior que o permitido
     if( m_posicaoLotsPend   > EA_STOP_QTD_CONTRATOS_PENDENTES && EA_STOP_QTD_CONTRATOS_PENDENTES > 0 ){
         //Print(":-( ",__FUNCTION__," Acionando STOP_LOSS_QTD_CONTRATOS_"+ DoubleToString(m_lucroPosicao,0)," VOL=",m_posicaoLotsPend," ", strPosicao() );
         m_lucroStops += m_lucroPosicao;
         fecharTudo("STOP_QTD_CONTRATOS_"+ DoubleToString(m_lucroPosicao,0));
         return true;
     }

     return false;
}

string strPosicao(){
   return " Contr="       + DoubleToString (m_posicaoLotsPend  ,0)+ "/"+
                            DoubleToString (m_posicaoVolumeTot ,0)+
          " SPRE= "       + DoubleToString (m_symb.Spread()    ,2)+
          " VSBUY/SEL="   + DoubleToString (m_volTradePorSegBuy,0)+ "/" + DoubleToString(m_volTradePorSegSel,0)+
          " Incl="        + DoubleToString (m_inclTra          ,2)+
          //" PUP0/1="      + DoubleToString (m_desbUp0*100      ,0)+ "/" + DoubleToString(m_desbUp0*100,0)+
          " LUCRP="       + DoubleToString (m_lucroPosicao     ,2)+
          " Volat="     + DoubleToString (m_volatilidade     ,2)+
          " ASK/BID="   + DoubleToString (m_ask,_Digits)        + "/"+ DoubleToString (m_bid,_Digits)+
          " Leilao="    +                 strEmLeilao()        ;
}

bool   emLeilao   (){return (m_ask<=m_bid);}
string strEmLeilao(){ if(emLeilao()) return "SIM"; return "NAO";}


/*
//----------------------------------------------------------------------------------------------------------------------------
// Esta funcao deve ser chamada sempre qua ha uma posicao aberta.
// Ela cria rajada de ordens no sentido da posicao, bem como as ordens de fechamento da posicao baseadas nas ordens da rajada.
// passo    : aumento de preco na direcao contraria a posicao. se quiser operar sem rajada, zere este parametro (PAAAO_RAJADA).
// volLimite: volume maximo em risco
// volLote  : volume de ordem aberta na direcao contraria a posicao
// profit   : quantidade de ticks para o gain
//
// versao 02-084: closerajada antes do openrajada.
//                Para abrir logo o close da ordem de abertura da posicao.
//                Estava abrindo as rajadas antes da ordem de fechamento da posicao.
//----------------------------------------------------------------------------------------------------------------------------
bool doOpenRajada(double passo, double volLimite, double volLote, double profit){

   if(passo == 0) return true; // se quiser operar sem rajada, zere o parametro PASSO_RAJADA
   
   if( estouVendido() ){
         // se nao tem ordem pendente acima do preco atual mais o passo, abre uma...
         double precoOrdem = m_bid+(m_tick_size*passo);
         openOrdemRajadaVenda(passo,volLimite,volLote,profit,precoOrdem);
         return true;
   }else{
        if( estouComprado() ){
             // se nao tem ordem pendente abaixo do preco atual, abre uma...
             double precoOrdem = m_ask-(m_tick_size*passo);
             openOrdemRajadaCompra(passo,volLimite,volLote,profit,precoOrdem);
             return true;
        }
   }
   // nao deveria chegar aqui, a menos que esta funcao seja chamada sem uma posicao aberta.
   Print(":-( ATENCAO OPENRAJADA chamado sem posicao aberta. Verifique! ",strPosicao() );
   return false;
}


// abre rajada em posicao vendida...
bool openOrdemRajadaVenda( double passo, double volLimite, double volLote, double profit, double precoOrdem){

     // distancia entre a primeira ordem da posicao e a ordem atual...
     //int distancia =(int)( (m_val_order_4_gain==0)?0:(precoOrdem-m_val_order_4_gain) );

     if(m_val_order_4_gain==0){ 
        Print(":-( openOrdemRajadaVenda() chamado, mas valor de abertura da posicao eh ZERO. VERIFIQUE!!!");
        return false;
     }
     
     precoOrdem = normalizar( m_val_order_4_gain+(passo*m_tick_size) );
   //if(EA_VOL_MARTINGALE) volLote = volLote*2;
     if(EA_VOL_MARTINGALE) volLote = volLote+1;
     while(precoOrdem < m_ask){
   //while(precoOrdem < m_bid){
         precoOrdem = normalizar( precoOrdem + (passo*m_tick_size) );
       //if(EA_VOL_MARTINGALE) volLote = volLote*2;
         if(EA_VOL_MARTINGALE) volLote = volLote+1;
     }
     
     for(int i=0; i<EA_TAMANHO_RAJADA; i++){
         precoOrdem = normalizar(precoOrdem);
         if(  m_posicaoVolumePend <= volLimite                                                                         && // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
           //( passo==0 || distancia%(int)(passo*m_tick_size)== 0 )                                                    && // posiciona rajada em distancias multiplas do passo.
             (precoOrdem > m_val_order_4_gain || m_val_order_4_gain==0 )                                               && // vender sempre acima da primeira ordem da posicao
             !m_trade.tenhoOrdemLimitadaDeVenda ( precoOrdem                               , m_symb_str, m_strRajada ) &&
             !m_trade.tenhoOrdemLimitadaDeCompra( normalizar(precoOrdem-profit*m_tick_size), m_symb_str, m_strRajada ) // se tiver a ordem de compra pendente,
                                                                                                                       // significa que a ordem de venda foi
                                                                                                                       // executada, entao nao abrimos nova
                                                                                                                       // ordem de venda ateh que a compra,
                                                                                                                       // que eh seu fechamento, seja executada.
          ){
                #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print(":-| HFT_ORDEM OPEN_RAJADA SELL_LIMIT=",precoOrdem, ". Enviando... ",strPosicao() ); #endif
                #ifndef COMPILE_PRODUCAO if( EA_SLEEP_ATRASO!= 0 ) Sleep(EA_SLEEP_ATRASO); #endif 
                
                // essa a parte original antes da alteracao para o passo dinamico
                if( m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, volLote, m_strRajada+getStrComment() ) ){
                    if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem; }
                    //return true;
                }
         }
         precoOrdem = precoOrdem + (passo*m_tick_size);
       //if(EA_VOL_MARTINGALE) volLote = volLote*2;
         if(EA_VOL_MARTINGALE) volLote = volLote+1;
     }
     return false;
}

// abre rajada em posicao comprada...
bool openOrdemRajadaCompra( double passo, double volLimite, double volLote, double profit, double precoOrdem){

     // distancia entre a primeira ordem da posicao e a ordem atual...
     //int distancia = (int)( (m_val_order_4_gain==0)?0:(m_val_order_4_gain-precoOrdem) );

     if(m_val_order_4_gain==0){ 
        Print(":-( openOrdemRajadaCompra() chamado, mas valor de abertura da posicao eh ZERO. VERIFIQUE!!!");
        return false;
     }
     
     precoOrdem = normalizar( m_val_order_4_gain-(passo*m_tick_size) );
   //if(EA_VOL_MARTINGALE) volLote = volLote*2;
     if(EA_VOL_MARTINGALE) volLote = volLote+1;
     while(precoOrdem > m_bid){
   //while(precoOrdem > m_ask){
         precoOrdem = normalizar( precoOrdem - (passo*m_tick_size) );
       //if(EA_VOL_MARTINGALE) volLote = volLote*2;
         if(EA_VOL_MARTINGALE) volLote = volLote+1;
     }

     for(int i=0; i<EA_TAMANHO_RAJADA; i++){
         precoOrdem = normalizar(precoOrdem);
         if(  m_posicaoVolumePend <= volLimite                                                                              && // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
           //( passo==0 || distancia%(int)(passo*m_tick_size)== 0 )                                                         && // posiciona rajada em distancias multiplas do passo.
             (precoOrdem < m_val_order_4_gain || m_val_order_4_gain==0 )                                                    && // comprar sempre abaixo da primeira ordem da posicao
             !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem                                 , m_symb.Name(), m_strRajada ) &&
             !m_trade.tenhoOrdemLimitadaDeVenda ( normalizar( precoOrdem+profit*m_tick_size ), m_symb.Name(), m_strRajada ) // se tiver a ordem de venda pendente,
                                                                                                                            // significa que a ordem de compra foi
                                                                                                                            // executada, entao nao abrimos nova
                                                                                                                            // ordem de compra ateh que a venda,
                                                                                                                            // que eh seu fechamento, seja executada.
           ){
    
                #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print(":-| HFT_ORDEM OPEN_RAJADA BUY_LIMIT=",precoOrdem, ". Enviando...",strPosicao()); #endif
                #ifndef COMPILE_PRODUCAO if( EA_SLEEP_ATRASO!= 0 ) Sleep(EA_SLEEP_ATRASO); #endif 

                // essa a parte original antes da alteracao para o passo dinamico
                if( m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, volLote, m_strRajada+getStrComment() ) ){
                    if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem;}
                    //return true;
                }
         }
         precoOrdem = precoOrdem - (passo*m_tick_size);
       //if(EA_VOL_MARTINGALE) volLote = volLote*2;
         if(EA_VOL_MARTINGALE) volLote = volLote+1;
     }
 return false;
}
*/
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
//------------------------------------------------------------------------------------------------------------
bool doCloseRajada(double profit){
     if( estouVendido() ){
         return doCloseRajada3(m_qtd_ticks_4_gain_raj, true );
     }else{
         return doCloseRajada3(m_qtd_ticks_4_gain_raj, false);
     }
}

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
string m_deal_comment;
double m_deal_vol = 0;
bool doCloseRajada3(double profit, bool close_sell){

   //if( EA_FECHA_POSICAO_POR_EVENTO ) return false;
   //m_qtd_exec_closerajada3++;
   
   ulong        deal_ticket; // ticket da transacao
   int          deal_type  ; // tipo de operação comercial

   // aproveitando pra atualizar o contador de transacoes na posicao...
   m_volVendasNaPosicao  = 0;
   m_volComprasNaPosicao = 0;
   
   // Faca assim:
   // 1. Coloque vendas e compras em filas separadas.
   // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
   // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.
   
   //preenchendo o cache com ordens e transacoes da posicao atual no historico...
   if( !HistorySelectByPosition(m_positionId) ){ return false;} 

   int deals = HistoryDealsTotal();

   // abrindo ordens de compra pra fechar uma rajada de vendas...
   if(close_sell){
      CQueue  <long     > qDealBuy; // fila de transacoes de compra da posicao. Ao final do segundo laco, deve ficar vazia.
      CHashMap<long,long> hDealSel; // hash de transacoes de venda  da posicao. Ao final do segundo laco, devem ficar no map, as vendas cuja compra nao foi concretizada...
      
      for(int i=0;i<deals;i++) {  // selecionando as transacoes (entradas e saidas) para processamento...
    
         deal_ticket    =      HistoryDealGetTicket (i);
         deal_type      = (int)HistoryDealGetInteger(deal_ticket,DEAL_TYPE   );
         m_deal_vol     =      HistoryDealGetDouble (deal_ticket,DEAL_VOLUME );
       //m_deal_comment =      HistoryDealGetString (deal_ticket,DEAL_COMMENT);
       //Print("DEAL_COMMENT: I=",i, " COMMENT: ", HistoryDealGetString (deal_ticket,DEAL_COMMENT)  );
         if( i==0 ){
             m_deal_comment = HistoryDealGetString (deal_ticket,DEAL_COMMENT);
             if( m_deal_comment != "" && StringFind(m_deal_comment,"IN") < 0 ){
               //fecharTudo("STOP_CLOSERAJADA");
         //      Print(":-( ", __FUNCTION__, " POSICAO ABERTA POR UMA RAJADA OU FECHAMENTO DE RAJADA. COMMENT: ", m_deal_comment  );
               //return false;
             }
         }
          
         // 1. Colocando vendas e compras em estruturas separadas...
         switch(deal_type){
            case DEAL_TYPE_BUY : {qDealBuy.Add(deal_ticket            ); m_volComprasNaPosicao += m_deal_vol; break;}
            case DEAL_TYPE_SELL: {hDealSel.Add(deal_ticket,deal_ticket); m_volVendasNaPosicao  += m_deal_vol; break;}
         }
      }
      
    //// 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
      // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas
      //    e altere o preco se necessario.
      long ticketSel;
      int  qtd = qDealBuy.Count();
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealBuy.Dequeue();
         ticketSel   = StringToInteger( HistoryDealGetString(deal_ticket,DEAL_COMMENT) ); // obtendo o ticket de venda no comentario da ordem de compra...
         ////////////////// ini trecho versao 3 ///////////////
         //price       =                  HistoryDealGetDouble(deal_ticket,DEAL_PRICE)    ; // obtendo o preco de uma ordem cuja ordem de fechamento jah foi colocada.
         //if( price != m_precoSaidaPosicao ){
         //    m_trade.alterarOrdem(ORDER_TYPE_BUY_LIMIT,
         //                         m_precoSaidaPosicao,
         //                         HistoryDealGetDouble(deal_ticket,DEAL_VOLUME),
         //                         deal_ticket,
         //                         HistoryDealGetString(deal_ticket,DEAL_COMMENT) );
         //}
         ////////////////// fim trecho versao 3 ///////////////
         hDealSel.Remove(ticketSel); // removendo a venda da fila de vendas pendentes de abrir posicao de compra...
      }

      // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.
      // se sobrou elemento na fila, checamos se jah tem a ordem de compra correspondente. Se nao tiver, criamos.
      double val         = 0               ;
      double precoProfit = 0               ;
      string idClose                       ;
      double vol         = 0               ;

      qtd = hDealSel.Count();
      if( qtd > 0 ){
      
          long vetSel[];
          long vetSel2[];
          hDealSel.CopyTo(vetSel,vetSel2); 
      
          for(int i=0;i<qtd;i++) {
             deal_ticket = vetSel[i]; // qDealSel.Dequeue();
             idClose = IntegerToString(deal_ticket); // colocando o ticket da venda na ordem de compra. Serah usado posteriormente
                                                     // para encontrar as compras que jah foram processadas.
             if( m_qtdOrdens == 0 || !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){

                 // se nao tem ordem de fechamento da posicao, criamos uma agora:
                 // se tem ateh 3 rajadas na posicao colocamos o preco da saida igual ao preco da saida da primeira ordem da posicao.
                 //if( m_volVendasNaPosicao > 1 && m_volVendasNaPosicao <= m_stop_qtd_contrat ){
                 //    precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) - profit*m_tick_size*(m_volVendasNaPosicao) );
                 //}else{
                     //precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) - profit*m_tick_size                      );
                     precoProfit = m_precoSaidaPosicao;
                 //}
                  
                 if(precoProfit > m_ask) precoProfit = m_ask;
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 //#ifndef COMPILE_PRODUCAO if(EA_DEBUG        )Print(":-| HFT_ORDEM CLOSE_RAJADA BUY_LIMIT=",precoProfit, " ID=", idClose, "... ", strPosicao() ); #endif
                 //#ifndef COMPILE_PRODUCAO if(EA_SLEEP_ATRASO!= 0) Sleep(EA_SLEEP_ATRASO); #endif
                 m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT,precoProfit, vol, idClose);
                 //incrementarPasso();
             }
          }
      }
   // abrindo ordens de venda pra fechar uma rajada de compras...
   }else{
      CQueue  <long     > qDealSel; // fila de transacoes de venda da posicao. Ao final do segundo laco, deve ficar vazia.
      CHashMap<long,long> hDealBuy; // hash de transacoes de compra da posicao. Ao final do segundo laco, devem ficar na fila, as compras cuja venda nao foi concretizada...

      for(int i=0;i<deals;i++) {  // selecionando as transacoes (entradas e saidas) para processamento...
    
         deal_ticket    =      HistoryDealGetTicket (i);
         deal_type      = (int)HistoryDealGetInteger(deal_ticket,DEAL_TYPE   );
         m_deal_vol     =      HistoryDealGetDouble (deal_ticket,DEAL_VOLUME );
       //m_deal_comment =      HistoryDealGetString (deal_ticket,DEAL_COMMENT);
          
         if( i==0 ){
             m_deal_comment = HistoryDealGetString (deal_ticket,DEAL_COMMENT);
             if( m_deal_comment != "" && StringFind(m_deal_comment,"IN") < 0 ){
                 //fecharTudo("STOP_CLOSERAJADA");
             //    Print(":-( ", __FUNCTION__, " POSICAO ABERTA POR UMA RAJADA OU FECHAMENTO DE RAJADA. COMMENT: ", m_deal_comment  );
                 //return false;
             }
         }

         // 1. Colocando vendas e compras em estruturas separadas...
         switch(deal_type){
            case DEAL_TYPE_BUY : {hDealBuy.Add(deal_ticket,deal_ticket); m_volComprasNaPosicao += m_deal_vol; break;}
            case DEAL_TYPE_SELL: {qDealSel.Add(deal_ticket            ); m_volVendasNaPosicao  += m_deal_vol; break;}
         }
      }

      // 2. Percorra a fila de vendas e, pra cada venda encontrada, busque a compra correspondente e retire-a da fila de compras.
      int    qtd     = qDealSel.Count();
      long   ticketBuy;
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealSel.Dequeue();
         ticketBuy   = StringToInteger( HistoryDealGetString(deal_ticket,DEAL_COMMENT) ); // obtendo o ticket de compra no comentario da ordem de venda...
         ////////////////// ini trecho versao 3 ///////////////
         //price       =                  HistoryDealGetDouble(deal_ticket,DEAL_PRICE)    ; // obtendo o preco de uma ordem cuja ordem de fechamento jah foi colocada.
         //if( price != m_precoSaidaPosicao ){
         //    m_trade.alterarOrdem(ORDER_TYPE_SELL_LIMIT,
         //                         m_precoSaidaPosicao,
         //                         HistoryDealGetDouble(deal_ticket,DEAL_VOLUME),
         //                         deal_ticket,
         //                         HistoryDealGetString(deal_ticket,DEAL_COMMENT) );
         //}
         ////////////////// fim trecho versao 3 ///////////////
         hDealBuy.Remove(ticketBuy); // removendo a compra da fila de compras pendentes de abrir posicao de venda...
      }

      // 3. Se sobraram compras na fila de compras, processe-a conforme abaixo.
      // se sobrou elemento na fila, checamos se jah tem a ordem de venda correspondente. Se nao tiver, criamos.
      double val         = 0               ;
      double precoProfit = 0               ;
      string idClose                       ;
      double vol         = 0               ;

      qtd = hDealBuy.Count();
      if( qtd > 0 ){ 

          long vetBuy [];
          long vetBuy2[];
          hDealBuy.CopyTo(vetBuy,vetBuy2); 
      
          for(int i=0;i<qtd;i++) {
             deal_ticket = vetBuy[i]; // qDealBuy.Dequeue();
             idClose = IntegerToString(deal_ticket); // colocando o ticket da compra na ordem de venda. Serah usado posteriormente
                                                     // para encontrar as vendas que jah foram processadas.
             if( m_qtdOrdens == 0 || !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){

                 // se nao tem ordem de fechamento da posicao, criamos uma agora:

                 // se tem ateh 3 rajadas na posicao colocamos o preco da saida igual ao preco da saida da primeira ordem da posicao.
                 //if( m_volComprasNaPosicao > 1 && m_volComprasNaPosicao <= m_stop_qtd_contrat ){
                 //    precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) + profit*m_tick_size*(m_volComprasNaPosicao) );
                 //}else{
                   //precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) + profit*m_tick_size                         );
                     precoProfit = m_precoSaidaPosicao;
                 //}


                 if(precoProfit < m_bid) precoProfit = m_bid;
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 #ifndef COMPILE_PRODUCAO if(EA_DEBUG        ) Print(":-| HFT_ORDEM CLOSE_RAJADA SELL_LIMIT=",precoProfit, " ID=", idClose, "...", strPosicao() ); #endif
                 #ifndef COMPILE_PRODUCAO if(EA_SLEEP_ATRASO!= 0) Sleep(EA_SLEEP_ATRASO); #endif
                 m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,precoProfit, vol, idClose);
                 //incrementarPasso();
             }
          }
      }
   }

   return true;
}


//------------------------------------------------------------------------------------------------------------
// Faz      : Abre as ordens de fechamento das posicoes abertas no doOpenRajada. As posicoes de fechamento sao
//            abertas sempre que as ordens da rajada sao executadas, ou seja, sempre que vao pra posicao.
//            Aqui vamos eliminar o bug da versao doCloseRajada, que estah duplicando as ordens de fechamento
//            da primeira ordem executada no fechamento da posicao.
//
// toCloseidDeal: ticket do trade que serah fechado.
// toCloseVol   : volume do trade que serah fechado.
//------------------------------------------------------------------------------------------------------------
void doCloseFixo(ulong toCloseidDeal, double toCloseVol, ENUM_DEAL_TYPE sentidoRajada, double toClosePriceIn=0){

    double precoProfit = 0;
    
    if( sentidoRajada==DEAL_TYPE_BUY || estouComprado() ){
      
        precoProfit = normalizar(toClosePriceIn + m_qtd_ticks_4_gain_ini*m_tick_size);
        
      //if(precoProfit==0) precoProfit = m_ask;
        if(precoProfit < m_bid || precoProfit==0){
            precoProfit = m_ask;
        }
        if( precoProfit <= toClosePriceIn ) precoProfit = normalizar(toClosePriceIn + m_tick_size);

        m_trade.setAsync(true);
        m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,precoProfit, toCloseVol, IntegerToString(toCloseidDeal) );
        m_trade.setAsync(false);
        return;
    }else{
      //if(precoProfit==0) precoProfit = m_bid;
        if( sentidoRajada==DEAL_TYPE_SELL || estouVendido() ){
    
    
            precoProfit = normalizar(toClosePriceIn - m_qtd_ticks_4_gain_ini*m_tick_size);
    
            if(precoProfit > m_ask || precoProfit==0){ 
                precoProfit = m_bid; //<TODO> VERIFIQUE E TESTE
            }
            if( precoProfit >= toClosePriceIn ) precoProfit = normalizar(toClosePriceIn - m_tick_size);

            m_trade.setAsync(true);
            m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT ,precoProfit, toCloseVol, IntegerToString(toCloseidDeal) );
            m_trade.setAsync(false);
            return;
        }
    }
    
    Print(__FUNCTION__, ":-( FUI CHAMADO SEM A DIRECAO DA RAJADA!!!!! VERIFIQUE!!!!!!" );
}
//------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------
// Faz      : Abre as ordens de fechamento das posicoes abertas no doOpenRajada. As posicoes de fechamento sao
//            abertas sempre que as ordens da rajada sao executadas, ou seja, sempre que vao pra posicao.
//            Esta versao eh feita para ser executada sempre que for processado um dealAdd no evento 
//            OnTradeTransaction da primeira ordem executada no fechamento da posicao.
//
// toCloseidDeal : ticket do trade que serah fechado.
// toCloseVol    : volume do trade que serah fechado.
// sentidoRajada : sentido do trade de entrada que serah fechada por esta rajada
// toClosePriceIn: preco   do trade de entrada que serah fechado por esta ordem
// toCloseOpenPos: se true, significa que o trade a ser fechado eh o primeiro da posicao.
//------------------------------------------------------------------------------------------------------------
void doCloseRajada4(ulong toCloseidDeal, double toCloseVol, ENUM_DEAL_TYPE sentidoRajada, double toClosePriceIn, bool toCloseOpenPos){

    // para os casos em que a estrategia nao quer executar o fechamento das ordens de entrada.
    if( m_qtd_ticks_4_gain_ini==0) return;

    // Durante os stops, nao deveria haver chamadas a doCloseRajada4, uma vez que todas as ordens pendentes da posicao jah deveriam
    // estar com suas respectivas ordens de fechamento emitidas.
    // Aqui estamos testando uma forma do sistema se recuperar desta situacao... 
    //if( m_stop ){ 
    //    Print(":-( ",__FUNCTION__,"(",toCloseidDeal,",",toCloseVol,",",EnumToString(sentidoRajada),",",toClosePriceIn,",",toCloseOpenPos,")",
    //    " WARN: chamada durante STOP!! Transferindo execucao para doCloseRajada!! VERIFIQUE!!!!");
    //    doCloseRajada(0); 
    //    return; 
    //}
    
    // fechamento de posicao a xx ticks do breakeven...
    double precoProfit = m_precoSaidaPosicao; //m_precoSaidaPosicao jah eh normalizado. Nao precisa normalizar. 
    
    // fechamento de posicao a xx ticks de cada ordem de entrada...
    //if( !EA_FECHA_POSICAO_NO_BREAK_EVEN ){
    //    if( sentidoRajada==DEAL_TYPE_BUY || estouComprado() ){
    //        precoProfit = normalizar(toClosePriceIn+m_qtd_ticks_4_gain_ini);
    //    }else{
    //        precoProfit = normalizar(toClosePriceIn-m_qtd_ticks_4_gain_ini);
    //    }
    //}
    
    // Nas ordens posteriores a de abertura da posicao, o preco de saida da posicao jah deveria estar configurado.
    // Se nao estiver, ainda assim serah corrigido a frente, mas logamos afim de verificar se estah sendo frequente.
    if(m_precoSaidaPosicao==0 && !toCloseOpenPos && EA_FECHA_POSICAO_NO_BREAK_EVEN) Print(":-( ",__FUNCTION__,"(",toCloseidDeal,",",toCloseVol,",",EnumToString(sentidoRajada),",",toClosePriceIn,",",toCloseOpenPos,") WARN: m_precoSaidaPosicao==0!!!!! VERIFIQUE!!!!");

    // volume da ordem de fechamento poderah ser maior que a de abertura em funcao de condicoes da operacao (veja uso da variavel vol mais adiante).
    double vol    = toCloseVol  ;
    double newVol = toCloseVol*qtdLotesStopParcial(); 
    if( newVol>m_vol_lote_ini*qtdLotesStopParcial() ) newVol = m_vol_lote_ini*qtdLotesStopParcial();

    if( sentidoRajada==DEAL_TYPE_BUY || estouComprado() ){

        if(toCloseOpenPos || !EA_FECHA_POSICAO_NO_BREAK_EVEN) precoProfit = normalizar( toClosePriceIn + ( m_qtd_ticks_4_gain_ini+getTicksAddPorSelecaoAdversa() )*m_tick_size );

        if(precoProfit == 0             ) precoProfit = m_ask_stplev  ;// precoProfit nao informado, colocamos saida a 1 tick. 
        if(precoProfit <  m_ask         ) precoProfit = m_ask         ;// precoProfit informado abaixo do preco de mercado, colocamos saida no valor de mercado.
        if(precoProfit <  toClosePriceIn) precoProfit = toClosePriceIn;

        if(m_precoOrdem<m_ask_stplev) m_precoOrdem = m_ask_stplev;

        //Print(":-| ",__FUNCTION__,"(",toCloseidDeal,",",toCloseVol,",",EnumToString(sentidoRajada),",",toClosePriceIn,",",toCloseOpenPos,")",
        //      " INFO: m_precoSaidaPosicao=",m_precoSaidaPosicao," m_ask=",m_ask," m_bid=",m_bid, " emitindo VENDA em:",precoProfit );
     
        if( ( (lotesNaPosicaoHabilitamStopParcial() && m_posicaoVolumePend > newVol) ||
              !podeEntrarComprando               ()                                  ||
              (lucroNaPosicaoHabilitaStopParcial () && m_posicaoVolumePend > newVol)  )
          )vol = newVol;
        
        m_trade.setAsync(true);
        m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,precoProfit, vol, IntegerToString(toCloseidDeal) );
        m_trade.cancelarOrdensComComentarioNumerico( m_symb_str, ORDER_TYPE_BUY_LIMIT );
        m_trade.setAsync(false);
        
        // se incrementou a volume, cancela a maior ordem de saida (mais antiga).
        //if( vol > m_vol_lote_ini ) m_trade.cancelarMaiorOrdemDeVendaComComentarioNumerico();
        return;
    }else{
        if( sentidoRajada==DEAL_TYPE_SELL || estouVendido() ){
        
            if(toCloseOpenPos || !EA_FECHA_POSICAO_NO_BREAK_EVEN) precoProfit = normalizar( toClosePriceIn - ( m_qtd_ticks_4_gain_ini+getTicksAddPorSelecaoAdversa() )*m_tick_size );

            if(precoProfit ==0             ) precoProfit = m_bid_stplev  ;// precoProfit nao informado, colocamos saida a 1 tick. 
            if(precoProfit > m_bid         ) precoProfit = m_bid         ;// precoProfit informado acima do preco de mercado, colocamos saida no valor de mercado.
            if(precoProfit > toClosePriceIn) precoProfit = toClosePriceIn;
            
            //Print(":-| ",__FUNCTION__,"(",toCloseidDeal,",",toCloseVol,",",EnumToString(sentidoRajada),",",toClosePriceIn,",",toCloseOpenPos,")",
            //      " INFO: m_precoSaidaPosicao=",m_precoSaidaPosicao," m_ask=",m_ask," m_bid=",m_bid, " emitindo COMPRA em:",precoProfit );

            if( (  ( lotesNaPosicaoHabilitamStopParcial() && m_posicaoVolumePend > newVol ) ||
                    !podeEntrarVendendo                ()                                   ||
                   ( lucroNaPosicaoHabilitaStopParcial () && m_posicaoVolumePend > newVol )  )
              )vol = newVol;

            m_trade.setAsync(true);
            m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT ,precoProfit, vol, IntegerToString(toCloseidDeal) );
            m_trade.cancelarOrdensComComentarioNumerico( m_symb_str, ORDER_TYPE_SELL_LIMIT );
            m_trade.setAsync(false);

            // se incrementou a volume, cancela a menor ordem de saida (mais antiga).
            //if( vol > m_vol_lote_ini ) m_trade.cancelarMenorOrdemDeCompraComComentarioNumerico();
            return;
        }
    }
    
    Print(":-( ",__FUNCTION__,"(",toCloseidDeal,",",vol,",",EnumToString(sentidoRajada),",",toClosePriceIn,",",toCloseOpenPos,") ERROR: DIRECAO DA RAJADA INVALIDA!!!!! VERIFIQUE!!!!!!");
}
//------------------------------------------------------------------------------------------------------------


int qtdLotesStopParcial(){
    if( EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES  > 0 ) return (int)(1 + m_posicaoLotsPend/EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES);
    return 1;
}

bool lotesNaPosicaoHabilitamStopParcial(){
    return ( EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES > 0 && EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES < m_posicaoLotsPend );
}



bool lucroNaPosicaoHabilitaStopParcial(){
    return ( EA_STOP_PARCIAL_A_PARTIR_DE_X_GANHO > 0 && EA_STOP_PARCIAL_A_PARTIR_DE_X_GANHO < m_lucroPosicao    );
}

string getStrComment(){
  
//  if( EA_ACAO_POSICAO == HFT_ARBITRAGEM_PAR ){
//      return 
//      " a" +DoubleToString (m_par.getRatioDP()*10       ,0) + // ratio instantaneo entre o par de ativo
//      " b" +DoubleToString (m_est.getVolTradeLiqPorSeg(),0) + // Velocidade do volume por segundo.
//      " c" +DoubleToString (m_est.getAceVolLiq()        ,0) + // Aceleracao da velocidade do volume por segundo ao quadrado.
//      " d" +DoubleToString (m_est.getKyleLambda()       *10000000,0) + // risco de compra (Buy).
//      " e" +DoubleToString (m_est.getKyleLambdaHLTrade()*10000000,0) ; // risco de venda  (Sell).
//  }

    return 
    " a" +DoubleToString (m_est.getInclinacaoHLTrade(),0) + // velocidade do Preco por segundo.
    " b" +DoubleToString (m_est.getVolTradeLiqPorSeg(),0) + // Velocidade do volume por segundo.
    " c" +DoubleToString (m_est.getAceVolLiq()        ,0) + // Aceleracao da velocidade do volume por segundo ao quadrado.
    " d" +DoubleToString (m_est.getKyleLambda()       *10000000,0) + // risco de compra (Buy).
    " e" +DoubleToString (m_est.getKyleLambdaHLTrade()*10000000,0) ; // risco de venda  (Sell).

//          " a" +DoubleToString (m_est.getInclinacaoHLTrade(),0) + // velocidade do preco, calculada como a inclinacao da reta HighLow de m_est divida pela janela de acumulacao estatistica.
//          " b" +DoubleToString (m_volTradePorSegLiq         ,0) + // banda superior da bolinger.
//          " c" +DoubleToString (m_volTradePorSegBuy         ,0) + // banda media    da bolinger.
//          " d" +DoubleToString (m_volTradePorSegSel         ,0) + // desvio padrao  da bolinger em pontos.
//          " e" +IntegerToString(EA_EST_QTD_SEGUNDOS           ) ; // banda inferior da bolinger.

}

//-----------------------------------------------------------------------------------------------------------------------------
// HFT_OPERAR_VOLUME_CANAL
//
// Entrada:
// - A cada tick.
// - Compra se preco estah na regiao superior do canal.        
// - Vende  se preco estah na regiao inferior do canal.     
//
// Saida:
// - ver
// INS a34 b3 c34 d30 e300 (23 caracteres)
//-----------------------------------------------------------------------------------------------------------------------------
double m_precoOrdem  = 0.0;
void abrirPosicaoHFTVolumeCanal(){

    if( m_ask==0.0 || m_bid==0.0 ){   
        Print(__FUNCTION__," Erro abertura posicao: m_ask=",m_ask, " m_bid=",m_bid );
        
        // se tinha ordem pendente, cancela
        m_trade.cancelarOrdensComentadas(m_symb_str,m_apmb     );
        m_trade.cancelarOrdensComentadas(m_symb_str,m_strRajada);

        m_aguardar_para_abrir_posicao = EA_EST_QTD_SEGUNDOS*1000; // aguarda ateh poder abrir nova posicao
        return;
    }
    
    // tendencia de alta...
    if( m_est.getVolTradeLiqPorSeg() > 0    &&
        m_est.getAceVolLiq()         > 0    &&
        m_est.getInclinacaoHLTrade() > 0    && m_canal.regiaoSuperior()  ){
  //if( m_canal.regiaoSuperior()                                         ){
  //if( m_canal.regiaoSuperior() && m_riscoCompra < EA_RISCO_MAX_POSICAO ){
  //if(                             m_riscoCompra < EA_MAIOR_RISCO_ENTRADA ){
        
        // providenciando a ordem de entrada na posicao...
        m_precoOrdem = m_bid;

        if( !m_trade.tenhoOrdemLimitadaDeCompra( m_precoOrdem, m_symb_str, m_apmb, m_vol_lote_ini , true, m_shift_in_points, m_apmb_buy+getStrComment() ) ){
            if(m_precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , m_precoOrdem, m_vol_lote_ini, m_apmb_buy+getStrComment() );
        }        

        // cancelando ordens de venda porventura colocadas...
        if( ! m_trade.cancelarOrdensComentadasDeVenda(m_symb_str ,m_apmb     ) ) return; // se teve algum problema cancelando ordens, nao segue criando outras
        if( ! m_trade.cancelarOrdensComentadasDeVenda(m_symb_str ,m_strRajada) ) return; // se teve algum problema cancelando ordens, nao segue criando outras
        
        return;
    }else{
        
        // tendencia de baixa...
        if( m_est.getVolTradeLiqPorSeg() < 0   &&
            m_est.getAceVolLiq()         < 0   &&
            m_est.getInclinacaoHLTrade() < 0   && m_canal.regiaoInferior()  ){
      //if( m_canal.regiaoInferior()                                        ){
      //if( m_canal.regiaoInferior() && m_riscoVenda < EA_RISCO_MAX_POSICAO ){
      //if(                             m_riscoVenda < EA_MAIOR_RISCO_ENTRADA ){
        
            // providenciando a ordem de entrada na posicao...
            m_precoOrdem = m_ask;
    
            if( !m_trade.tenhoOrdemLimitadaDeVenda( m_precoOrdem, m_symb_str, m_apmb, m_vol_lote_ini , true, m_shift_in_points, m_apmb_sel+getStrComment() ) ){
                if(m_precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT , m_precoOrdem, m_vol_lote_ini, m_apmb_sel+getStrComment() );
            }

            // cancelando ordens de compra porventura colocadas...
            if( ! m_trade.cancelarOrdensComentadasDeCompra(m_symb_str, m_apmb     ) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras
            if( ! m_trade.cancelarOrdensComentadasDeCompra(m_symb_str, m_strRajada) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras    

            return;
        }
    }
    // se chegou aqui eh porque nao ha condicao para abrir posicao. Entao cancela pedidos de entrada pendentes.    
    m_trade.cancelarOrdensComentadas(m_symb_str,m_apmb     );
    m_trade.cancelarOrdensComentadas(m_symb_str,m_strRajada);
}
//-----------------------------------------------------------------------------------------------------------------------------



//---------------------------------------------------------------------------------------------------------
// Inicia ordem de abertura a pelo menos XX ticks do preco atual. Visa ter prioridade na fila do book.
// HFT_FORMADOR_DE_MERCADO
//---------------------------------------------------------------------------------------------------------
int getTicksAddPorSelecaoAdversa(){ return (int)ceil(m_posicaoLotsPend*EA_AUMENTO_LAG_POR_LOTE_PENDENTE); }// truncando pra cima
void abrirPosicaoHFTPrioridadeNoBook(){

   // cancelando ordens de saida que porventura ficaram mal posicionadas...
   if( estouSemPosicao() ){ m_trade.cancelarOrdensComComentarioNumerico(m_symb_str                      );}
   if( estouVendido   () ){ m_trade.cancelarOrdensComComentarioNumerico(m_symb_str,ORDER_TYPE_SELL_LIMIT);}
   if( estouComprado  () ){ m_trade.cancelarOrdensComComentarioNumerico(m_symb_str,ORDER_TYPE_BUY_LIMIT );}

   if( m_ask == 0.0 || m_bid == 0.0 ){   
        Print(__FUNCTION__," Erro abertura posicao :m_ask=",m_ask, " m_bid=",m_bid );
        //m_aguardar_para_abrir_posicao = EA_EST_QTD_SEGUNDOS*1000; // aguarda ateh poder abrir nova posicao
        return;
   }
   if( EA_DECISAO_ENTRADA_COMPRA_VENDA_AUTOMATICA){
     //if( m_canal.getRegiaoUltExtremoTocado() > 0 ){ m_tipo_entrada_permitida = ENTRADA_BUY; }else{ m_tipo_entrada_permitida = ENTRADA_SELL; }
       if( m_canal.getCoefLinear()>0 ){ m_tipo_entrada_permitida = ENTRADA_BUY; }else{ m_tipo_entrada_permitida = ENTRADA_SELL; }
   }
   
   // a cada contrato acumulado no estoque, aumenta xx unidades no lag entre novas ordens...
   int lag_rajada = m_lag_rajada;
   if( estouPosicionado() ) lag_rajada = m_lag_rajada + getTicksAddPorSelecaoAdversa();

   // quando o volume pendente da posicao for maior que 2 e estiver posicionado, dobramos o volume das ordens
   // de saida quando o valor da posicao estiver acima do breakeven. Isto visa diminuir o risco.
   double vol = m_vol_lote_ini;
   if( estouComprado() && (   lotesNaPosicaoHabilitamStopParcial() ||
                              !podeEntrarComprando              () ||
                              (lucroNaPosicaoHabilitaStopParcial() && m_posicaoVolumePend > vol)  )
     )vol = vol*qtdLotesStopParcial();

   //INCLUINDO ORDENS DE VENDA.
   double dist_min_entrada_book;

   // possibilidade de entrar mais rapido na saida da posicao
   if( estouComprado() ){ 
       dist_min_entrada_book = m_dist_min_in_book_out_pos; 
   }else{
       if( devoEntrarVendendo() ){
           dist_min_entrada_book = EA_DIST_MIN_IN_BOOK_IN_POS_OBRIG;
       }else{
           dist_min_entrada_book = m_dist_min_in_book_in_pos;
       }
       
       if( estouVendido() ) dist_min_entrada_book = m_dist_min_in_book_in_pos + getTicksAddPorSelecaoAdversa();
   }
   
   
 //m_precoOrdem = normalizar( m_bid + dist_min_entrada_book*m_tick_size );
   m_precoOrdem = normalizar( m_ask + dist_min_entrada_book*m_tick_size );
   if(m_precoOrdem<m_ask_stplev) m_precoOrdem = m_ask_stplev;
   
 //if( m_qtdPosicoes>0|| ( estouSemPosicao() && podeEntrarVendendo() ) ){
   if( estouVendido() || ( estouSemPosicao() && podeEntrarVendendo() ) ){ // testando a entrada em sentido unico quando estah posicionado
     //if(m_precoOrdem!=0) m_trade.preencherOrdensLimitadasDeVendaAcimaComLag (m_precoOrdem,EA_TAMANHO_RAJADA,m_symb_str,m_apmb_sel,vol,m_tick_size,lag_rajada);
       if(m_precoOrdem!=0) m_trade.preencherOrdensLimitadasDeVendaAcimaComLag2(m_precoOrdem,EA_TAMANHO_RAJADA,m_symb_str,m_apmb_sel,vol,m_tick_size,lag_rajada);
   }else{
       m_trade.cancelarOrdensComentadasDeVenda(m_symb_str ,m_apmb_sel);
   }

   vol = m_vol_lote_ini;
   if( estouVendido() && ( lotesNaPosicaoHabilitamStopParcial() ||
                          !podeEntrarVendendo                () ||
                          (lucroNaPosicaoHabilitaStopParcial () && m_posicaoVolumePend > vol)   )
     ) vol = vol*qtdLotesStopParcial();

   // INCLUINDO ORDENS DE COMPRA
   // possibilidade de entrar mais rapido na saida da posicao
   if( estouVendido() ){
       dist_min_entrada_book = m_dist_min_in_book_out_pos; 
   }else{
       if( devoEntrarComprando() ){
           dist_min_entrada_book = EA_DIST_MIN_IN_BOOK_IN_POS_OBRIG;
       }else{
           dist_min_entrada_book = m_dist_min_in_book_in_pos ;
       }
       if( estouComprado() ) dist_min_entrada_book = m_dist_min_in_book_in_pos + getTicksAddPorSelecaoAdversa();
   }
                         
                         
 //m_precoOrdem = normalizar( m_ask - dist_min_entrada_book*m_tick_size );
   m_precoOrdem = normalizar( m_bid - dist_min_entrada_book*m_tick_size );
   if(m_precoOrdem>m_bid_stplev) m_precoOrdem = m_bid_stplev;

 //if( m_qtdPosicoes>0 || ( estouSemPosicao() && podeEntrarComprando() ) ){
   if( estouComprado() || ( estouSemPosicao() && podeEntrarComprando() ) ){ // testando a entrada em sentido unico quando estah posicionado
     //if(m_precoOrdem!=0) m_trade.preencherOrdensLimitadasDeCompraAbaixoComLag (m_precoOrdem,EA_TAMANHO_RAJADA,m_symb_str,m_apmb_buy,vol,m_tick_size,lag_rajada);
       if(m_precoOrdem!=0) m_trade.preencherOrdensLimitadasDeCompraAbaixoComLag2(m_precoOrdem,EA_TAMANHO_RAJADA,m_symb_str,m_apmb_buy,vol,m_tick_size,lag_rajada);
   }else{
     m_trade.cancelarOrdensComentadasDeCompra(m_symb_str ,m_apmb_buy);
   }

}
//---------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------
// Inicia ordem de abertura a pelo menos XX desvios padrao na correlacao entre paraes de ativos.      
// HFT_ARBITRAGEM_PAR
//---------------------------------------------------------------------------------------------------------
/*
void abrirPosicaoHFTarbitragemPar(){

    if( m_ask==0.0 || m_bid==0.0 ){   
        Print(__FUNCTION__," Erro abertura posicao :m_ask=",m_ask, " m_bid=",m_bid );
        
        // se tinha ordem pendente, cancela
        m_trade.cancelarOrdensComentadas(m_symb_str,m_apmb     );
        m_trade.cancelarOrdensComentadas(m_symb_str,m_strRajada);

        m_aguardar_para_abrir_posicao = EA_EST_QTD_SEGUNDOS*1000; // aguarda ateh poder abrir nova posicao
        return;
    }
    
    // ativo estah barato em ralacao ao seu par...
    if( m_par.getRatioDP() <= -EA_QTD_DP_FIRE_ORDEM ){
        
        // providenciando a ordem de entrada na posicao...
        m_precoOrdem = m_bid;

        if( !m_trade.tenhoOrdemLimitadaDeCompra( m_precoOrdem, m_symb_str, m_apmb, m_vol_lote_ini , true, m_shift_in_points, m_apmb_buy+getStrComment() ) ){
            if(m_precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , m_precoOrdem, m_vol_lote_ini, m_apmb_buy+getStrComment() );
        }        

        // cancelando ordens de venda porventura colocadas...
        if( ! m_trade.cancelarOrdensComentadasDeVenda(m_symb_str ,m_apmb     ) ) return; // se teve algum problema cancelando ordens, nao segue criando outras
        if( ! m_trade.cancelarOrdensComentadasDeVenda(m_symb_str ,m_strRajada) ) return; // se teve algum problema cancelando ordens, nao segue criando outras
        return;
    }else{
        
        // ativo estah caro em relacao ao seu par...
        if( m_par.getRatioDP() >= EA_QTD_DP_FIRE_ORDEM ){
        
            // providenciando a ordem de entrada na posicao...
            m_precoOrdem = m_ask;
    
            if( !m_trade.tenhoOrdemLimitadaDeVenda( m_precoOrdem, m_symb_str, m_apmb, m_vol_lote_ini , true, m_shift_in_points, m_apmb_sel+getStrComment() ) ){
                if(m_precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT , m_precoOrdem, m_vol_lote_ini, m_apmb_sel+getStrComment() );
            }

            // cancelando ordens de compra porventura colocadas...
            if( ! m_trade.cancelarOrdensComentadasDeCompra(m_symb_str, m_apmb     ) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras
            if( ! m_trade.cancelarOrdensComentadasDeCompra(m_symb_str, m_strRajada) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras    
            return;
        }
    }    
    // se chegou aqui eh porque nao ha condicao para abrir posicao. Entao cancela pedidos de entrada pendentes.
    m_trade.cancelarOrdensComentadas(m_symb_str,m_apmb     );
    m_trade.cancelarOrdensComentadas(m_symb_str,m_strRajada);
}
*/
//---------------------------------------------------------------------------------------------------------


//
// A cada mudanda de periodo faz:
// Posicao vendido : Coloca ordem limitada de venda  no preco maximo do periodo anterior ou no preco atual (o maior)
// Posicao comprado: Coloca ordem limitada de compra no preco minimo do periodo anterior ou no preco atual (o menor)
//
//int m_min_analisado = 0;
datetime m_time_analisado = TimeCurrent();
MqlRates m_rates1_tmp[1];
void preencherFilaOrdens(){

    //m_qtd_exec_filaordens++;

    // obtendo a barra anterior...
    int copiados = CopyRates(m_symb_str,_Period,1,1,m_rates1_tmp);
    if( copiados <= 0 ){
        Print( ":-( ", __FUNCTION__, ": Erro CopyRates():", GetLastError(), " copiados:",copiados);
        return;
    }

    // se jah analisou, volta e aguarda a proximo periodo
    if( m_rates1_tmp[0].time == m_time_analisado ) return;
    ArrayPrint(m_rates1_tmp);

    //if( m_date_atu.min == m_min_analisado || m_date_atu.sec < 2 ) return;
    Print( "Analisando minuto: ", TimeCurrent(), "..." );

    // obtendo a barra anterior...
    //int copiados = CopyRates(m_symb_str,_Period,1,1,m_rates1_tmp);
    //Print(":-| Copiados: ", copiados );
    //ArrayPrint(m_rates1_tmp);

  //double precoOrdem = 0;
    double distancia  = (EA_DISTAN_DEMAIS_ORDENS_RAJ*m_tick_size);
    double shift      = 0;
    // Posicao vendido : Coloca ordem limitada de venda  no preco maximo do periodo anterior ou no preco atual (o maior)
    if( estouVendido() ){
    
    //  // uma ordem no preco atual...
    //  m_precoOrdem = normalizar( m_ask + distancia );
    ////if( m_precoOrdem < m_ask ){ m_precoOrdem = m_ask; }
    //  if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        double pshift = m_ask+distancia;
        double dlow   = 0;
        double dhigh  = m_rates1_tmp[0].high  - m_rates1_tmp[0].low;
        double dopen  = m_rates1_tmp[0].open  - m_rates1_tmp[0].low;
        double dclose = m_rates1_tmp[0].close - m_rates1_tmp[0].low;

        double plow   = pshift + dlow  ;
        double phigh  = pshift + dhigh ;
        double popen  = pshift + dopen ;
        double pclose = pshift + dclose;

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // testando colocacao uma ordem rajada pelo valor maximo e com volume EA_INCREM_VOL_RAJ (EX: 4) 
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        m_precoOrdem = normalizar( phigh );
        if( m_precoOrdem < m_ask ){ m_precoOrdem = m_ask; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem, m_vol_lote_ini*EA_INCREM_VOL_RAJ, m_strRajada+getStrComment() );
        m_time_analisado = m_rates1_tmp[0].time;
        return;
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////        

        // outra ordem na maxima da barra anterior...
      //m_precoOrdem = normalizar( m_rates1_tmp[0].high + distancia );
        m_precoOrdem = normalizar( phigh );
        if( m_precoOrdem < m_ask ){ m_precoOrdem = m_ask; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        ////////////////////////////////////////////////////////////////////////
        // NOVOS EM TESTE (saiu o preco atual)
        ////////////////////////////////////////////////////////////////////////
        // outra ordem na minima da barra anterior...
      //m_precoOrdem = normalizar( m_rates1_tmp[0].low + distancia );
        m_precoOrdem = normalizar( plow );
        if( m_precoOrdem < m_ask ){ m_precoOrdem = m_ask; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        // outra ordem na abertura da barra anterior...
      //m_precoOrdem = normalizar( m_rates1_tmp[0].open + distancia );
        m_precoOrdem = normalizar( popen );
        if( m_precoOrdem < m_ask ){ m_precoOrdem = m_ask; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        // outra ordem no fechamento da barra anterior...
      //m_precoOrdem = normalizar( m_rates1_tmp[0].close + distancia );
        m_precoOrdem = normalizar( pclose );
        if( m_precoOrdem < m_ask ){ m_precoOrdem = m_ask; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );
        ////////////////////////////////////////////////////////////////////////
        
        m_time_analisado = m_rates1_tmp[0].time;
    }

    // Posicao comprado: Coloca ordem limitada de compra no preco minimo do periodo anterior ou no preco atual (o menor)
    if( estouComprado() ){

   //   // uma ordem no preco atual...
   //   m_precoOrdem = normalizar( m_bid - distancia );
   // //if( m_precoOrdem > m_bid ){ m_precoOrdem = m_bid; }
   //   if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        double pshift = m_bid-distancia;
        double dhigh  = 0                                          ;
        double dlow   = m_rates1_tmp[0].high  - m_rates1_tmp[0].low;
        double dopen  = m_rates1_tmp[0].open  - m_rates1_tmp[0].low;
        double dclose = m_rates1_tmp[0].close - m_rates1_tmp[0].low;

        double phigh  = pshift - dhigh;
        double plow   = pshift - dlow  ;
        double popen  = pshift - dopen ;
        double pclose = pshift - dclose;

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // testando colocacao uma ordem rajada pelo valor minimo e com volume EA_INCREM_VOL_RAJ (ex:4) 
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        m_precoOrdem = normalizar( plow );
        if( m_precoOrdem > m_bid ){ m_precoOrdem = m_bid; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem, m_vol_lote_ini*EA_INCREM_VOL_RAJ, m_strRajada+getStrComment() );
        m_time_analisado = m_rates1_tmp[0].time;
        return;
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////


        // outra ordem no minimo da barra anterior...
      //m_precoOrdem = normalizar( m_rates1_tmp[0].low - distancia );
        m_precoOrdem = normalizar( plow );
        if( m_precoOrdem > m_bid ){ m_precoOrdem = m_bid; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        
        ////////////////////////////////////////////////////////////////////////
        // NOVOS EM TESTE
        ////////////////////////////////////////////////////////////////////////
        // outra ordem na maxima da barra anterior...
      //m_precoOrdem = normalizar( m_rates1_tmp[0].high - distancia );
        m_precoOrdem = normalizar( phigh );
        if( m_precoOrdem > m_bid ){ m_precoOrdem = m_bid; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        // outra ordem na abertura da barra anterior...
      //m_precoOrdem = normalizar( m_rates1_tmp[0].open - distancia );
        m_precoOrdem = normalizar( popen );
        if( m_precoOrdem > m_bid ){ m_precoOrdem = m_bid; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        // outra ordem no fechamento da barra anterior...
      //m_precoOrdem = normalizar( m_rates1_tmp[0].close - distancia );
        m_precoOrdem = normalizar( pclose );
        if( m_precoOrdem > m_bid ){ m_precoOrdem = m_bid; }
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );
        
        
        m_time_analisado = m_rates1_tmp[0].time;
    }


    //doCloseRajada(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_ini);

    //m_trade.alterarValorDeOrdensNumericasPara(m_symb_str,m_precoSaidaPosicao,m_precoPosicao);

}

void preencherFilaOrdensFixa(){

    //m_qtd_exec_filaordens++;

    //double precoOrdem         = 0;
    double passoRajada          = (m_raj_unica_distancia_demais_ordens*m_tick_size);
    double passoRajadaPrimOrdem = (m_raj_unica_distancia_prim_ordem   *m_tick_size);
    double shift                = 0;
    // Posicao vendido : Coloca rajada de ordens limitadas de venda
    if( estouVendido() ){
    
        m_precoOrdem = normalizar( m_precoPosicao+passoRajadaPrimOrdem );
        if( m_precoOrdem < m_ask ){ m_precoOrdem = m_ask; }
        m_trade.setAsync(true);
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendenteRajada( ORDER_TYPE_SELL_LIMIT             , // tipo de ordens
                                                                  m_precoOrdem                      , // preco da primeira ordem
                                                                  m_vol_lote_raj                    , // volume da primeira ordem da rajada
                                                                  m_strRajada+getStrComment()       , // comentario da ordens
                                                                  passoRajada                       , // distancia entre ordens da rajada
                                                                  EA_INCREM_VOL_RAJ                 , // multiplica pelo volume a cada ordem da rajada
                                                                  EA_INCREM_DISTAN_DEMAIS_ORDENS_RAJ, // multiplica pela distancia a cada ordem da rajada
                                                                  EA_TAMANHO_RAJADA                 , // quantidade de ordens da rajada
                                                                  EA_STOP_NA_RAJADA                 , // se true, a ultima ordem da rajada eh um stop loss 
                                                                  EA_PORC_STOP_NA_RAJADA            
                                                                 // testando ordens a favor da posicao...
                                                                 //,m_precoSaidaPosicao
                                                                 //,m_tick_size
                                                                  );// 
        m_trade.setAsync(false);
        //m_time_analisado = m_rates1_tmp[0].time;
        return;
    }

    // Posicao comprado: Coloca rajadas de ordens limitadas de compra
    if( estouComprado() ){

        m_precoOrdem = normalizar( m_precoPosicao-passoRajadaPrimOrdem );
        if( m_precoOrdem > m_bid ){ m_precoOrdem = m_bid; }
        m_trade.setAsync(true);
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendenteRajada( ORDER_TYPE_BUY_LIMIT              , // tipo de ordens
                                                                  m_precoOrdem                      , // preco da primeira ordem
                                                                  m_vol_lote_raj                    , // volume da primeira ordem da rajada
                                                                  m_strRajada+getStrComment()       , // comentario da ordens
                                                                 -passoRajada                       , // distancia entre ordens da rajada
                                                                  EA_INCREM_VOL_RAJ                 , // multiplica pelo volume a cada ordem da rajada
                                                                  EA_INCREM_DISTAN_DEMAIS_ORDENS_RAJ, // multiplica pela distancia a cada ordem da rajada
                                                                  EA_TAMANHO_RAJADA                 , // quantidade de ordens da rajada
                                                                  EA_STOP_NA_RAJADA                 , // se true, a ultima ordem da rajada eh um stop loss
                                                                  EA_PORC_STOP_NA_RAJADA            
                                                                 // testando ordens a favor da posicao...
                                                                 //,m_precoSaidaPosicao
                                                                 //,m_tick_size
                                                                  );// 
        m_trade.setAsync(false);
        //m_time_analisado = m_rates1_tmp[0].time;
        return;
    }
}

bool estouVendido (ENUM_DEAL_TYPE toCloseTypeDeal){ return toCloseTypeDeal==DEAL_TYPE_SELL; }
bool estouComprado(ENUM_DEAL_TYPE toCloseTypeDeal){ return toCloseTypeDeal==DEAL_TYPE_BUY ; }
void preencherFilaOrdensFixaAssincrona(ENUM_DEAL_TYPE toCloseTypeDeal, double toClosePriceIn){

    //double precoOrdem         = 0;
    double passoRajada          = (m_raj_unica_distancia_demais_ordens*m_tick_size);
    double passoRajadaPrimOrdem = (m_raj_unica_distancia_prim_ordem   *m_tick_size);
    double shift                = 0;
    // Posicao vendido : Coloca rajada de ordens limitadas de venda
    if( estouVendido(toCloseTypeDeal) ){
    
        m_precoOrdem = normalizar( toClosePriceIn+passoRajadaPrimOrdem );
        if( m_precoOrdem < m_ask ){ m_precoOrdem = m_ask; }
        m_trade.setAsync(true);
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendenteRajada( ORDER_TYPE_SELL_LIMIT             , // tipo de ordens
                                                                  m_precoOrdem                      , // preco da primeira ordem
                                                                  m_vol_lote_raj                    , // volume da primeira ordem da rajada
                                                                  m_strRajada+getStrComment()       , // comentario da ordens
                                                                  passoRajada                       , // distancia entre ordens da rajada
                                                                  EA_INCREM_VOL_RAJ                 , // multiplica pelo volume a cada ordem da rajada
                                                                  EA_INCREM_DISTAN_DEMAIS_ORDENS_RAJ, // multiplica pela distancia a cada ordem da rajada
                                                                  EA_TAMANHO_RAJADA                 , // quantidade de ordens da rajada
                                                                  EA_STOP_NA_RAJADA                 , // se true, a ultima ordem da rajada eh um stop loss 
                                                                  EA_PORC_STOP_NA_RAJADA            
                                                                 // testando ordens a favor da posicao...
                                                                 //,m_precoSaidaPosicao
                                                                 //,m_tick_size
                                                                  );// 
        m_trade.setAsync(false);
        //m_time_analisado = m_rates1_tmp[0].time;
        return;
    }

    // Posicao comprado: Coloca rajadas de ordens limitadas de compra
    if( estouComprado(toCloseTypeDeal) ){

        m_precoOrdem = normalizar( toClosePriceIn-passoRajadaPrimOrdem );
        if( m_precoOrdem > m_bid ){ m_precoOrdem = m_bid; }
        m_trade.setAsync(true);
        if( m_precoOrdem != 0 )m_trade.enviarOrdemPendenteRajada( ORDER_TYPE_BUY_LIMIT              , // tipo de ordens
                                                                  m_precoOrdem                      , // preco da primeira ordem
                                                                  m_vol_lote_raj                    , // volume da primeira ordem da rajada
                                                                  m_strRajada+getStrComment()       , // comentario da ordens
                                                                 -passoRajada                       , // distancia entre ordens da rajada
                                                                  EA_INCREM_VOL_RAJ                 , // multiplica pelo volume a cada ordem da rajada
                                                                  EA_INCREM_DISTAN_DEMAIS_ORDENS_RAJ, // multiplica pela distancia a cada ordem da rajada
                                                                  EA_TAMANHO_RAJADA                 , // quantidade de ordens da rajada
                                                                  EA_STOP_NA_RAJADA                 , // se true, a ultima ordem da rajada eh um stop loss
                                                                  EA_PORC_STOP_NA_RAJADA            
                                                                 // testando ordens a favor da posicao...
                                                                 //,m_precoSaidaPosicao
                                                                 //,m_tick_size
                                                                  );// 
        m_trade.setAsync(false);
        //m_time_analisado = m_rates1_tmp[0].time;
        return;
    }
}

//bool taxaVolPermiteAbrirPosicao (){return EA_VOLSEG_MAX_ENTRADA_POSIC==0 || m_volTradePorSeg <= EA_VOLSEG_MAX_ENTRADA_POSIC ;}
//bool volatilidadeEstahAlta    (){return m_volatilidade       > EA_VOLAT_ALTA                                  && EA_VOLAT_ALTA       != 0;}
//bool volatilidade4segEstahAlta(){return m_volatilidade_4_seg > m_volatilidade_4_seg_media*m_volat4s_alta_porc && m_volat4s_alta_porc != 0;}
//bool volat4sExigeStop         (){return m_volatilidade_4_seg > m_volatilidade_4_seg_media*m_volat4s_stop_porc && m_volat4s_stop_porc != 0;}
//bool volat4sPermiteAbrirPosicao(){ return m_volatilidade_4_seg <= EA_VOLAT4S_MIN ||  EA_VOLAT4S_MIN == 0; }
bool spreadMaiorQueMaximoPermitido(){ return m_spread > m_spread_maximo_in_points && m_spread_maximo_in_points != 0; }

bool m_fastClose     = true;
bool m_traillingStop = false;
void setFastClose()    { m_fastClose=true ; m_traillingStop=false;}
void setTraillingStop(){ m_fastClose=false; m_traillingStop=true ;}

double normalizar(double preco){  return m_symb.NormalizePrice(preco); }

//void fecharPosicao (string comentario){ m_trade.fecharQualquerPosicao (comentario); setSemPosicao(); }
void cancelarOrdens(string comentario){ m_trade.cancelarOrdens(comentario); setSemPosicao(); }

void setCompradoSoft(){ m_comprado = true ; m_vendido = false; }
void setVendidoSoft() { m_comprado = false; m_vendido = true ; }
void setComprado()    { m_comprado = true ; m_vendido = false; m_tstop = 0;}
void setVendido()     { m_comprado = false; m_vendido = true ; m_tstop = 0;}
void setSemPosicao()  { m_comprado = false; m_vendido = false; m_tstop = 0;}

bool podeEntrarComprando(){ return m_tipo_entrada_permitida==ENTRADA_BUY  || m_tipo_entrada_permitida==ENTRADA_TODAS; }
bool podeEntrarVendendo (){ return m_tipo_entrada_permitida==ENTRADA_SELL || m_tipo_entrada_permitida==ENTRADA_TODAS; }

bool devoEntrarComprando(){ return m_tipo_entrada_permitida==ENTRADA_BUY ; }
bool devoEntrarVendendo (){ return m_tipo_entrada_permitida==ENTRADA_SELL; }

bool estouComprado   (){ return m_comprado; }
bool estouVendido    (){ return m_vendido ; }
bool estouSemPosicao (){ return !estouComprado() && !estouVendido() ; }
bool estouPosicionado(){ return  estouComprado() ||  estouVendido() ; }

string status(){
   string obs =
         //" preco="       + m_tick.ask                         +
         //" bid="         + m_tick.bid                         +
         //" spread="      + (m_tick.ask-m_tick.bid)            +
           " last="        + DoubleToString( m_tick_est.last )
         //" time="        + m_tick.time
         ;
   return obs;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {

                                            Print(m_name,":-| Expert ", m_name, " Iniciando metodo OnDeinit..." );
    Print(__FUNCTION__," :-| PROFIT BRUTO  :",m_trade_estatistica.getProfitDia       () );
    Print(__FUNCTION__," :-| TARIFAS       :",m_trade_estatistica.getTarifaDia       () );
    Print(__FUNCTION__," :-| PROFIT LIQUIDO:",m_trade_estatistica.getProfitDiaLiquido() );
                                            
    //BBDeleFromChart();                      Print(m_name,":-| Expert ", m_name, " Indicador GMMA retirado do grafico:", GetLastError() );
    //BBRelease();                            Print(m_name,":-| Expert ", m_name, " Manipuladores GMMA liberados:", GetLastError() );
    //delLineMinPreco();                    Print(m_name,":-| Expert ", m_name, " Linha de preco minimo elimnada." );
    //delLineMaxPreco();                    Print(m_name,":-| Expert ", m_name, " Linha de preco maximo elimnada." );
    //delLineTimeDesdeEntrelaca();          Print(m_name,":-| Expert ", m_name, " Linha horizontal entrelacamento eliminada." );
    //delLineMaiorPrecoCompra();            Print(m_name,":-| Expert ", m_name, " Linha horizontal regiao de compra." );
    //delLineMenorPrecoVenda();             Print(m_name,":-| Expert ", m_name, " Linha horizontal regiao de venda."  );
    EventKillTimer();                     Print(m_name,":-| Expert ", m_name, " Timer destruido." );
    delete(m_est);                        Print(__FUNCTION__,":-| m_est deletado:", GetLastError() );
  //delete(m_par);                        Print(__FUNCTION__,":-| m_par deletado:", GetLastError() );
    
  //m_feira.DeleteFromChart(0,0);         Print(m_name," :-| Expert ", m_name, " Indicador feira retirado do grafico." );
  //IndicatorRelease( m_feira.Handle() ); Print(m_name," :-| Expert ", m_name, " Manipulador do indicador feira liberado." );
    MarketBookRelease(m_symb_str);        Print(m_name," :-| Expert ", m_name, " Manipulador do Book liberado." );
    //IndicatorRelease( m_icci.Handle()  ); Print(m_name," :-| Expert ", m_name, " Manipulador do indicador cci   liberado." );
    //IndicatorRelease( m_ibb.Handle()    );
    
    if( EA_SHOW_CONTROL_PANEL ) { m_cp.Destroy(reason); Print(m_name,":-| Expert ", m_name, " Painel de controle destruido." ); }
    
    Comment("");                          Print(m_name," :-| Expert ", m_name, " Comentarios na tela apagados." );
                                          Print(m_name," :-) Expert ", m_name, " OnDeinit finalizado!" );
    return;
}

double OnTester(){ 
    m_trade_estatistica.print_posicoes(0, m_time_in_seconds_atu); 
    return m_trade_estatistica.getProfitDiaLiquido(); // profit do dia no relatorio de performance
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


string strFuncNormal(string str){ return ":-| " + str + " "; }

void printHeartBit(){ if(m_date_ant.min != m_date_atu.min) Print(":-| HeartBit! m_stop:", m_stop); }

//----------------------------------------------------------------------------------------------------
// 
// 1. Atualizando as variaveis de tempo atual m_time_in_seconds e m_date.
// 2. Executa funcoes que dependem das variaveis m_time_in_seconds ou m_date atualizadas e 
//    suas respectivas anteriores atualizas.
// 3. Atualizando variaveis de comparacao de data anterior e atual m_time_in_seconds_ant e m_date_ant.
//
//----------------------------------------------------------------------------------------------------
bool        m_estah_no_intervalo_de_negociacao = false;
bool        m_eh_hora_de_fechar_posicao        = false;
datetime    m_time_in_seconds_atu              = TimeCurrent();
datetime    m_time_in_seconds_ant              = m_time_in_seconds_atu;
MqlDateTime m_date_atu;
MqlDateTime m_date_ant;
//----------------------------------------------------------------------------------------------------
void OnTimer(){

    //m_qtd_exec_ontimer++;
    
    // 1. Atualizando as variaveis de tempo atual m_time_in_seconds e m_date...
    m_time_in_seconds_atu = TimeCurrent();
    TimeToStruct(m_time_in_seconds_atu,m_date_atu);
    //Print("Apos passo 1:", 
    //      " m_time_in_seconds_ant:",TimeToString(m_time_in_seconds_ant,TIME_DATE|TIME_MINUTES|TIME_SECONDS),
    //      " m_date_ant.sec:"       ,m_date_ant.sec                    );
    //Print("Apos passo 1:", 
    //      " m_time_in_seconds_atu:",TimeToString(m_time_in_seconds_atu,TIME_DATE|TIME_MINUTES|TIME_SECONDS),
    //      " m_date_atu.sec:"       ,m_date_atu.sec                    );
          
    
    // 2. executando funcoes que dependem das valiaveis m_time_in_seconds ou m_date atualizadas...
    m_estah_no_intervalo_de_negociacao = estah_no_intervalo_de_negociacao(); // verificando intervalo de negociacao...
    m_eh_hora_de_fechar_posicao        = eh_hora_de_fechar_posicao       (); // verificando se as posicoes devem ser fechadas...
    
  //calcularAceleracaoVelTradeDeltaPorc();                                   // calculando aceleracao da %Delta da velocidade do volume de trade...
  //calcRun(EA_MINUTOS_RUN,m_passo_rajada);                                  // calculando o indice de runs baseado no passo atual
  //calcRun(m_passo_rajada);                                                 // calculando o indice de runs baseado no passo atual
    controlarTimerParaAbrirPosicao();
    verificarMudancaDeSegundo();
  //calcularDirecaoVelocidadeDoVolume(); <TODO>: verificar se este metodo pode ser melhor que o uso estatistica2

    //calcCoefEntrelacamentoMedio();
    //calcOpenMaxMinDia();

    printHeartBit();
    
    // 3. atualizando variaveis de comparacao de data anterior e atual m_time_in_seconds_ant e m_date_ant.
    //    a partir deste ponto, as atuais e anteriores ficam iguais.
    m_time_in_seconds_ant = m_time_in_seconds_atu;
    m_date_ant            = m_date_atu;

    //Print("Apos passo 3:",
    //      " m_time_in_seconds_ant:",TimeToString(m_time_in_seconds_ant,TIME_DATE|TIME_MINUTES|TIME_SECONDS),
    //      " m_date_ant.sec:"       ,m_date_ant.sec                    );
    //Print("Apos passo 3:", 
    //      " m_time_in_seconds_atu:",TimeToString(m_time_in_seconds_atu,TIME_DATE|TIME_MINUTES|TIME_SECONDS),
    //      " m_date_atu.sec:"       ,m_date_atu.sec                    );
   
    //if (EA_SHOW_TELA         ) m_trade_estatistica.calcRelacaoVolumeProfit(m_time_in_seconds_ini_day, m_time_in_seconds_atu);
      if (EA_SHOW_CONTROL_PANEL) {
          m_trade_estatistica.refresh(m_time_in_seconds_ini_day, m_time_in_seconds_atu);
          refreshControlPanel();
      }
       
}
//----------------------------------------------------------------------------------------------------


// demarcacao da mudanca de segundo.
bool m_mudou_segundo = false;
void verificarMudancaDeSegundo(){
   if(m_date_ant.sec != m_date_atu.sec){m_mudou_segundo=true; return;}
   m_mudou_segundo = false;
}

// se a velocidade liquida do volume está aumentando, então a direção eh positiva e espera-se que o preco suba.
// se a velocidade liquida do volume está dimunuindo, então a direção eh negativa e espera-se que o preco caia.
// esta medida eh verifica a cada xx milisegundos definidos no timer do programa.
double m_direcaoVelVolTrade   = 0;
double m_volTradePorSegLiqAnt = 0;
void calcularDirecaoVelocidadeDoVolume(){
   if( !m_mudou_segundo ) return;
   m_direcaoVelVolTrade   = m_volTradePorSegLiq - m_volTradePorSegLiqAnt;
   m_volTradePorSegLiqAnt = m_volTradePorSegLiq;
   calcularDirecaoMediaVelocidadeTrade();
}



//----------------------------------------------------------------------------------------------------
// 1. Mantem a velocidade media da direcao do trade.
//----------------------------------------------------------------------------------------------------
//int    m_vet_direcao_vel_trade_ind =  0;
//double m_vet_direcao_vel_trade_tot =  0;
//int    m_vet_direcao_vel_trade_len = 60;
//double m_vet_direcao_vel_trade[60]     ;
double m_direcaoVelVolTradeMed     =  0;
osc_media m_Cmedia_direcaoVelocidadeTradeMedia;
//----------------------------------------------------------------------------------------------------
void calcularDirecaoMediaVelocidadeTrade(){
       
   //  m_vet_direcao_vel_trade_tot += m_direcaoVelVolTrade;                                   // adicionando o valor atual a media
   //  m_vet_direcao_vel_trade_tot -= m_vet_direcao_vel_trade[m_vet_direcao_vel_trade_ind];   // retirando o que estava na posicao atual do vetor
   //  m_vet_direcao_vel_trade[m_vet_direcao_vel_trade_ind] = m_direcaoVelVolTrade        ;   // e colocando o ultimo valor calculado
   //  if( ++m_vet_direcao_vel_trade_ind == m_vet_direcao_vel_trade_len ){ m_vet_direcao_vel_trade_ind=0; }// atualizando o indice
       
   //  m_direcaoVelVolTradeMed = m_vet_direcao_vel_trade_tot/(double)m_vet_direcao_vel_trade_len;       
       m_direcaoVelVolTradeMed = m_Cmedia_direcaoVelocidadeTradeMedia.add(m_direcaoVelVolTrade);       
}
//----------------------------------------------------------------------------------------------------


//----------------------------------------------------------------------------------------------------
// 1. Faz o shift das velocidades de volume registradas e despreza a mais antiga
// 2. Substitui a ultima velocidade pela mais atual
// 3. Recalcula a aceleracao da velocidade do volume
//----------------------------------------------------------------------------------------------------
int    m_vet_vel_volume_len = 60;
double m_vet_vel_volume[60];
int    m_acelVolTradePorSegDeltaPorc = 0;
//----------------------------------------------------------------------------------------------------
void calcularAceleracaoVelTradeDeltaPorc(){
   //if( m_time_in_seconds_atu != m_time_in_seconds_ant ){
       
       // fazendo shift para tras e desprezando a posicao mais antiga(indice zero)...
       for(int i=0; i<m_vet_vel_volume_len-1; i++){
           m_vet_vel_volume[i] = m_vet_vel_volume[i+1];
       }
       
       // atualizando a ultima posicao do vetor com a velocidade atual...
       m_vet_vel_volume[m_vet_vel_volume_len-1] = m_volTradePorSegDeltaPorc;
       
       // recalculando a aceleracao do volume... deltaVelocidade/deltaTempo (usando a formula da fisica)...
       m_acelVolTradePorSegDeltaPorc = ( (m_volTradePorSegDeltaPorc - (int)m_vet_vel_volume[0])/m_vet_vel_volume_len )*10;
   //}
}
//----------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------
bool estah_no_intervalo_de_negociacao(){

    //if( m_date_atu.hour == 16 && m_date_atu.min == 1){
    //   Print("Break Point!!!!");
    //}

    // informando a mudanca do dia (usada no controle do rebaixamento de saldo maximo da sessao).
    if( m_date_ant.day != m_date_atu.day ){ m_mudou_dia = true; m_time_in_seconds_ini_day = StringToTime( TimeToString( TimeCurrent(), TIME_DATE )); }

    // restricao para nao operar no inicio nem no final do dia...
    if(m_date_atu.hour <   EA_HR_INI_OPERACAO     ) {  return false; } // operacao antes de 9:00 distorce os testes.
    if(m_date_atu.hour >=  EA_HR_FIM_OPERACAO + 1 ) {  return false; } // operacao apos    18:00 distorce os testes.

    if(m_date_atu.hour == EA_HR_INI_OPERACAO && m_date_atu.min < EA_MI_INI_OPERACAO ) { return false; } // operacao antes de 9:10 distorce os testes.
    if(m_date_atu.hour == EA_HR_FIM_OPERACAO && m_date_atu.min > EA_MI_FIM_OPERACAO ) { return false; } // operacao apos    17:50 distorce os testes.

    //if( m_date_atu.year==2020 &&
    //    m_date_atu.mon ==2    &&
    //    m_date_atu.day ==26   &&
    //    m_date_atu.hour==13   &&
    //    m_date_atu.min < 30    ) { return false; } // para permitir teste na quarta-feira de cinzas.

    return true;
}

// a partir deste horario fecha todas as posicoes abertas.
bool eh_hora_de_fechar_posicao(){

    if( m_date_atu.hour >  EA_HR_FECHAR_POSICAO ){ return true; } 

    if( m_date_atu.hour >= EA_HR_FECHAR_POSICAO && 
        m_date_atu.min  >= EA_MI_FECHAR_POSICAO ){ return true; }

    return false;
}
//----------------------------------------------------------------------------------------------------


// controle da permissao para abrir posicoes em funcao de um tempo de penalidade.
// novas posicoes soh podem ser abertas se a penalidade(m_aguardar_para_abrir_posicao) estiver zerada.
void controlarTimerParaAbrirPosicao(){
    if( m_aguardar_para_abrir_posicao > 0 ){
        m_aguardar_para_abrir_posicao -= EA_QTD_MILISEG_TIMER;
    }    
    //if( m_aguardar_para_abrir_posicao < 0 ) m_aguardar_para_abrir_posicao = 0;
}



//string m_strRun = "";
void OnChartEvent(const int    id     , 
                  const long   &lparam, 
                  const double &dparam, 
                  const string &sparam){

    // servico de calculo de runs...
    //if(id==SVC_RUN+CHARTEVENT_CUSTOM){ m_strRun = "\n\n" + sparam; }
    
    // painel de controle...
    if( EA_SHOW_CONTROL_PANEL ) m_cp.ChartEvent(id,lparam,dparam,sparam);
    
//--- uma tecla foi pressionada 
   if(id==CHARTEVENT_KEYDOWN) processarAcionamentoDeTecla( (int)lparam );
}

#define KEY_R  82
void processarAcionamentoDeTecla(int tecla){
    switch( tecla ){
        case KEY_R: Print("KEY_R foi pressionada:",tecla,":",TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0?"shift":"nao" );
           if( TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0 ){
               Print("Atencao: Revertendo posicao...");
           }
           break;
     
      default:    Print("TECLA nnao listada:" ,tecla,":",TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0?"shift":"nao" ); 
    } 
    ChartRedraw(); 
     
}


//+-----------------------------------------------------------+
//|                                                           |
//+-----------------------------------------------------------+
osc_position m_pos;
//void OnTrade(){ m_pos.onTrade(); }

//+-----------------------------------------------------------+
//|                                                           |
//+-----------------------------------------------------------+
void OnTradeTransaction( const MqlTradeTransaction& tran,    // transacao
                         const MqlTradeRequest&     req ,    // request
                         const MqlTradeResult&      res   ){ // result

    bool           closer          = false;  // true: trade eh um fechamento de posicao
    bool           toClose         = false;  // true: trade deve ser fechado
    ulong          toCloseidDeal   = 0    ;  // se toClose=true este serah o ticket  do trade a ser fechado
    double         toCloseVol      = 0    ;  // se toClose=true este serah o volume  do trade a ser fechado
    ENUM_DEAL_TYPE toCloseTypeDeal        ;  // se toClose=true este serah o sentido do trade a ser fechado, conforme ENUM_DEAL_TYPE
    double         toClosePriceIn         ;  // se toClose=true este serah o preco   do trade a ser fechado
    bool           toCloseOpenPos  = false;  // se toClose=true esta indicarah se a posicao foi aberta agora (primeiraOrdem)
        
    m_pos.onTradeTransaction(tran,req,res,closer,toClose,toCloseidDeal,toCloseVol,toCloseTypeDeal,toClosePriceIn, toCloseOpenPos);
    
    if( EA_LOGAR_TRADETRANSACTION ) m_pos.logarInCSV(tran,req,res);
    
    if( EA_ACAO_POSICAO == NAO_OPERAR ) return;

    if( toClose==true ){

        // contando volume total da posicao...
        if( toCloseTypeDeal == DEAL_TYPE_BUY ){
            m_volComprasNaPosicao += (toCloseVol/m_lots_step);
        }else{
            if( toCloseTypeDeal == DEAL_TYPE_SELL ){
                m_volVendasNaPosicao += (toCloseVol/m_lots_step);
            }
        }

        // acionando o fechamento das ordens da posicao...
        doCloseRajada4(toCloseidDeal,toCloseVol,toCloseTypeDeal,toClosePriceIn,toCloseOpenPos);
        //doCloseFixo(toCloseidDeal,toCloseVol,toCloseTypeDeal,toClosePriceIn);
        
        // se eh a primeira ordem da posicao, incluimos a rajada logo após a primeira ordem de fechamento da posicao.
        // execeto na estrategia de prioridade, pois a mesma nao tem rajada.
      //if( toCloseOpenPos == true && EA_ACAO_POSICAO != HFT_FORMADOR_DE_MERCADO){
      //if( toCloseOpenPos == true ){
      //    preencherFilaOrdensFixaAssincrona(toCloseTypeDeal,toClosePriceIn);
      //}
    }else{
        // Aqui eh fechamento de posicao.
        if(closer){
            if( EA_ACAO_POSICAO == HFT_FORMADOR_DE_MERCADO ){
            // Se a posicao estah sendo fechada por uma ordem INX, cancele a ordem de fechamento original(comentario numerico) com preco
            // mais afastado (maior pra posicoes compradas e menor pra posicoes vendidas).
                string comment;
                if( m_pos.getComment(tran.order,comment) ){                
                    if( StringFind(comment,m_apmb) > -1 ){
                        // eh uma ordem INX, entao cancele uma ordem numerica mais afastada
                        if( estouComprado() ){
                            m_trade.cancelarMaiorOrdemDeVendaComComentarioNumerico();
                        }else{
                            if( estouVendido() ){
                                m_trade.cancelarMenorOrdemDeCompraComComentarioNumerico();
                            }
                        }
                    }
                }
            }
        }
    }
    //if( EA_ACAO_POSICAO == HFT_FORMADOR_DE_MERCADO ) abrirPosicaoHFTPrioridadeNoBook();
}
