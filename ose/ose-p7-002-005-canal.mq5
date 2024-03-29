﻿//+------------------------------------------------------------------+
//|                                         ose-p7-002-005-canal.mq5 |
//|                                          Copyright 2019, OS Corp |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao 3.p7-002-005                                              |
//| 1. Opera baseado no canal operacional.                           |
//|    Assume que nos extremos do canal haverah continuidade da      |
//|    rendencia, portanto vende na regiao inferior e compra na      |
//|    regiao superior.                                              |
//|                                                                  |
//|    Aciona StopLoss se estiver comprado e preco atingir o canal   |
//|           inferior e vice-versa.                                 |
//|                                                                  |
//|                                                                  |
//| 2. Parametros importantes:                                       |
//|    - quantidade de barras usadas na formacao do canal operacional|
//|    - tamanho, em porcentagem, das regioes operacionais do canal  |
//|                                                                  |
//|                                                                  |
//| 24/08/2020: doCloseRajada3 foi melhorado para nao seguir adiante |
//|             caso o historico da posicao nao seja encontrado.     |
//+------------------------------------------------------------------+

#define COMPILE_PRODUCAO

#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "1.2"

#include <Generic\Queue.mqh>
#include <Generic\HashMap.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//#include <Indicators\Trend.mqh>

//#include <oslib\os-lib.mq5>
//#include <oslib\osc-ind-minion-feira.mqh>
#include <oslib\osc-estatistic2.mqh>
#include <oslib\osc\osc-minion-trade-03.mqh>
#include <oslib\osc\osc-minion-trade-estatistica.mqh>
#include <oslib\osc\osc-media.mqh>

//#include <oslib\svc\osc-svc.mqh>
//#include <oslib\svc\run\cls-run.mqh>

#include <oslib\osc\cp\osc-pc-p7-002-004-vel-vol.mqh> //painel de controle
#include <oslib\osc\osc-canal.mqh> // canais



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
     HFT_CANAL_OPER                         //HFT_CANAL_OPER, abre posicao nas extremidades do canal operacional
};



//---------------------------------------------------------------------------------------------
  input group "Gerais"
  input ENUM_TIPO_OPERACAO EA_ACAO_POSICAO = FECHAR_POSICAO ; //EA_ACAO_POSICAO:Forma de operacao do EA.
  input double             EA_SPREAD_MAXIMO_EM_TICKS   =  4 ; //EA_SPREAD_MAXIMO_EM_TICKS. Se for maior que o maximo, nao abre novas posicoes.
//
//input group "Volume por Segundo"
//input int    EA_VOLSEG_MAX_ENTRADA_POSIC = 150;//VOLSEG_MAX_ENTRADA_POSIC: vol/seg maximo para entrar na posicao.
//

  //input group "velocidade do volume"
  #define EA_EST_QTD_SEGUNDOS 21   //EST_QTD_SEGUNDOS qtd seg para calc velocidade do volume 

  input group "canal operacional"
  input int    EA_TAMANHO_CANAL                 = 5   ; //TAMANHO_CANAL operacional
  input double EA_PORC_REGIAO_OPERACIONAL_CANAL = 0.25; //PORC_REGIAO_OPERACIONAL_CANAL regiao de operacao
   
  input group "entrada na posicao"
  input int    EA_TOLERANCIA_ENTRADA       = 1 ; //TOLERANCIA_ENTRADA: algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao 
  input double EA_VOL_LOTE_INI             = 1 ; //VOL_LOTE_INI:Vol do lote na abertura de posicao qd vol/seg eh L1.
  input double EA_QTD_TICKS_4_GAIN_INI     = 3 ; //TICKS_4_GAIN_INI Qtd ticks para o gain qd vol/seg eh level 1;
  input double EA_QTD_TICKS_4_GAIN_DECR    = 0 ; //TICKS_4_GAIN_DECR Qtd ticks a ser decrementado em tfg a cada aumento de volume de posicao;
  input double EA_QTD_TICKS_4_GAIN_MIN     = 3 ; //QTD_TICKS_4_GAIN_MIN menor alvo inicial possivel;
//input int    EA_PERIODO_CALC_TENDENCIA   = 3 ;//PERIODO_CALC_TENDENCIA para o calculo da tendencia
  input bool   EA_ALVO_DINAMICO            = false;//ALVO_DINAMICO alvo igual dp/TAMANHO_RAJADA

  //input ENUM_TIMEFRAMES    EA_BB_PERIODO       = PERIOD_CURRENT; // BB_PERIODO
  //input int                EA_BB_QTD_PERIODOS  = 10            ; // BB_QTD_PERIODOS
  //input double             EA_BB_DESVIO_PADRAO = 1.5           ; // BB_DESVIO_PADRAO
  //input ENUM_APPLIED_PRICE EA_BB_APPLIED       = PRICE_WEIGHTED; // BB_APPLIED

  #define      EA_QTD_TICKS_4_GAIN_RAJ       25    //QTD_TICKS_4_GAIN_RAJ Qtd ticks para o gain qd vol/seg eh level 1;

  input group "Rajada"
  input bool   EA_RAJADA_UNICA                    = true; //RAJADA_UNICA se verdadeiro, cria uma raja unica na abertura da posicao. 
  input int    EA_TAMANHO_RAJADA                  = 4  ; //TAMANHO_RAJADA;
  input double EA_VOL_PRIM_ORDEM_RAJ              = 2  ; //VOL_PRIM_ORDEM_RAJ:Vol da primeira ordem da rajada.
  input double EA_INCREM_VOL_RAJ                  = 1  ; //INCREM_VOL_RAJ aumento(x) de volume a cada ordem da rajada;
  input double EA_DISTAN_PRIM_ORDEM_RAJ           = 0  ; //DISTAN_PRIM_ORDEM_RAJ Distancia em ticks desde abertura da posicao ateh prim ordem rajada;
  input double EA_DISTAN_DEMAIS_ORDENS_RAJ        = 0  ; //DISTAN_DEMAIS_ORDENS_RAJ Distancia entre as demais ordens da rajada;
  input double EA_INCREM_DISTAN_DEMAIS_ORDENS_RAJ = 1    ; //INCREM_DISTAN_DEMAIS_ORDENS_RAJ aumento (x) distancia ordens rajada;
  input bool   EA_STOP_NA_RAJADA                  = false; //STOP_NA_RAJADA
  input double EA_PORC_STOP_NA_RAJADA             = 0    ; //PORC_STOP_NA_RAJADA

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
  input double EA_STOP_LOSS              = -1200 ; //STOP_LOSS:Valor maximo de perda aceitavel;
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
input ulong  EA_MAGIC             =  20082107002005; //MAGIC: Numero magico desse EA. yy-mm-vv-vvv-vvv.
////
//input group "estrategia HFT_FLUXO_ORDENS"
//input double EA_PROB_UPDW                =  0.8 ;//PROB_UPDW:probabilidade do preco subir ou descer em funcao do fluxo de ordens;
////
input double EA_DOLAR_TARIFA             =  6.0 ;//DOLAR_TARIFA:usado para calcular a tarifa do dolar.
////

//#define EA_MAX_VOL_EM_RISCO     200        //EA_MAX_VOL_EM_RISCO:Qtd max de contratos em risco; Sao os contratos pendentes da posicao.
//#define EA04_DX_TRAILLING_STOP  1.0        //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
//#define EA10_DX1                0.2        //EA10_DX1:Tamanho do DX em relacao a banda em %;

//input ENUM_TIPO_ENTRADA_PERMITDA EA_TIPO_ENTRADA_PERMITIDA = ENTRADA_TODAS;//TIPO_ENTRADA_PERMITIDA Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
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
input int    EA_MI_INI_OPERACAO   = 30; // Minuto de inicio da operacao;
input int    EA_HR_FIM_OPERACAO   = 18; // Hora   de fim    da operacao;
input int    EA_MI_FIM_OPERACAO   = 50; // Minuto de fim    da operacao;
input int    EA_HR_FECHAR_POSICAO = 17; // HR_FECHAR_POSICAO fecha todas as posicoes;
input int    EA_MI_FECHAR_POSICAO = 50; // MI_FECHAR_POSICAO fecha todas as posicoes;
//---------------------------------------------------------------------------------------------
//
// group "sleep e timer"
input int    EA_SLEEP_INI_OPER =  10 ;//SLEEP_INI_OPER:Aguarda estes segundos para iniciar abertura de posicoes.
input int    EA_QTD_MILISEG_TIMER  =  250;//QTD_SEG_TIMER:Tempo de acionamento do timer.

//input int    EA_SLEEP_ATRASO   =  0  ;//SLEEP_TESTE_ONLINE:atraso em milisegundos antes de enviar ordens.

//---------------------------------------------------------------------------------------------

//osc_estatistic2 m_est;

MqlDateTime       m_date;
string            m_name = "OSE-P7-002-003-BB";
CSymbolInfo       m_symb                      ;
CPositionInfo     m_posicao                   ;
CAccountInfo      m_cta                       ;

double        m_tick_size                     ;// alteracao minima de preco.
double        m_stopLossOrdens                ;// stop loss;
double        m_tkprof                        ;// take profit;
double        m_distMediasBook                ;// Distancia entre as medias Ask e Bid do book.

osc_minion_trade             m_trade            ; // operacao com ordens
osc_minion_trade_estatistica m_trade_estatistica; // estatistica de trades
osc_estatistic2              m_est              ; // estatistica de ticks
osc_control_panel_p7_002_003 m_cp               ; // painel de controle

bool   m_comprado            =  false;
bool   m_vendido             =  false;
double m_posicaoVolumePend   =  0; // volume pendente pra fechar a posicao atual
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
string m_positionCommentStr     = "0";
long   m_positionCommentNumeric =  0 ;


// barras atual e anterior...
MqlRates m_rates[];
double m_high0      = 0;
double m_low0       = 0;
double m_high1      = 0;
double m_low1       = 0;
double m_lenBar0    = 0;
double m_lenBar1    = 0;
double m_lenAteStop = 0;

//--- variaveis atualizadas pela funcao refreshMe...
int    m_qtdOrdens     = 0;
int    m_qtdOrdensAnt  = 0;
int    m_qtdPosicoes   = 0;
double m_posicaoProfit = 0;
double m_ask           = 0;
double m_bid           = 0;
double m_ask1          = 0;
double m_bid1          = 0;
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

int    m_ganhos_consecutivos = 0;
int    m_perdas_consecutivas = 0;
long   m_tempo_posicao_atu   = 0;
long   m_tempo_posicao_ini   = 0;

int    m_stop_qtd_contrat    = 0; // EA_STOP_QTD_CONTRAT; Eh o tamanho do chunk;
int    m_stop_chunk          = 0; // EA_STOP_CHUNK; Eh o tamanho do chunk;
double m_stop_porc           = 0; // EA_STOP_PORC_L1    ; Eh a porcentagem inicial para o ganho durante o passeio;
double    m_qtd_ticks_4_gain_new  = 0;
double    m_qtd_ticks_4_gain_ini  = 0;
double    m_qtd_ticks_4_gain_decr = 0;
double    m_qtd_ticks_4_gain_bb   = 0;
int    m_qtd_ticks_4_gain_raj= 0;
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
double m_symb_lots_min;

// milisegundos que devem ser aguardados antes de iniciar a operacao
int m_aguardar_para_abrir_posicao = 0;

// algumas estrategias permitem uma tolerancia do preco para entrada na posicao...
double m_shift = 0;

datetime m_time_in_seconds_ini_day = TimeCurrent();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
ulong m_qtd_exec_abrirposicao   = 0;
ulong m_qtd_exec_oninit         = 0;
ulong m_qtd_exec_ontick         = 0;
ulong m_qtd_exec_ontimer        = 0;
ulong m_qtd_exec_refreshme      = 0;
ulong m_qtd_exec_closerajada3   = 0;
ulong m_qtd_exec_ctrl_risco_pos = 0;
ulong m_qtd_exec_filaordens     = 0;
string m_acao;

//CiMA m_vetMaInst  [6];
//CiMA m_vetMaTrader[6];

//testando a classe osc_canal...
osc_canal m_canal;


int OnInit(){

    m_qtd_exec_oninit++;

    #ifdef COMPILE_PRODUCAO m_release = "[RELEASE PRODU]";#endif

    Print(":-| ", __FUNCTION__,m_release, " ************************************************");
    Print(":-| ", __FUNCTION__,m_release, " Iniciando : ", TimeCurrent() );
    Print(":-| ", __FUNCTION__,m_release, " MAGIC     : ", EA_MAGIC      );
    Print(":-| ", __FUNCTION__,m_release, " BUILDER   : ", __MQLBUILD__  );
    Print(":-| ", __FUNCTION__,m_release, " EXECUTAVEL: ", __PATH__      );
    Print(":-| ", __FUNCTION__,m_release, " BUILDATE  : ", __DATETIME__  );
    Print(":-| ", __FUNCTION__,m_release, " MQL       : ", __MQL__       );
    Print(":-| ", __FUNCTION__,m_release, " ************************************************");
    
    inicializarVariaveisRecebidasPorParametro();
    
    ArraySetAsSeries(m_rates,true);

    m_symb.Name( Symbol() ); // inicializacao da classe CSymbolInfo
    m_symb_str = Symbol();
    m_symb.Refresh     (); // propriedades do simbolo. Basta executar uma vez.
    m_symb.RefreshRates(); // valores do tick. execute uma vez por tick.
    m_tick_size         = m_symb.TickSize(); //Obtem a alteracao minima de preco
    m_stopLossOrdens    = m_symb.NormalizePrice(EA_STOP_TICKS_STOP_LOSS *m_tick_size);
    m_tkprof            = m_symb.NormalizePrice(EA_STOP_TICKS_TKPROF    *m_tick_size);
    m_symb_lots_min     = m_symb.LotsMin();
    m_trade.setMagic   (EA_MAGIC);
    m_trade.setStopLoss(m_stopLossOrdens);
    m_trade.setTakeProf(m_tkprof);

    m_posicao.Select( m_symb_str ); // selecao da posicao por simbolo.

    m_canal.inicializar(m_tick_size,EA_TAMANHO_CANAL, EA_PORC_REGIAO_OPERACIONAL_CANAL);
    m_canal.setShowCanalPrecos(EA_SHOW_CANAL_PRECOS);
    
    // estatistica de trade...    
    m_time_in_seconds_ini_day = StringToTime( TimeToString( TimeCurrent(), TIME_DATE ) );
    m_trade_estatistica.initialize();
    m_trade_estatistica.setCotacaoMoedaTarifaWDO(EA_DOLAR_TARIFA);
    
    m_est.initialize(EA_EST_QTD_SEGUNDOS,true); // quantidade de segundos que serao usados no calculo da velocidade do volume e flag indicando que deve consertar ticks sem flag.
    m_est.setSymbolStr( m_symb_str );

    m_spread_maximo_in_points = (int)(EA_SPREAD_MAXIMO_EM_TICKS*m_tick_size);

    m_shift                   = normalizar(EA_TOLERANCIA_ENTRADA*m_tick_size); // tolerancia permitida para entrada em algumas estrategias

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

    m_trade.setVolLote ( m_symb_lots_min );

    //m_precoUltOrdemInBuy = 0;
    //m_precoUltOrdemInSel = 0;
  
    EventSetMillisecondTimer(EA_QTD_MILISEG_TIMER);
    Print(":-| Expert ", __FUNCTION__,":", " Criado Timer de ",EA_QTD_MILISEG_TIMER," milisegundos !!! " );
    Print(":-) Expert ", __FUNCTION__,":", " inicializado !! " );
    Print(":-| ", __FUNCTION__,":",m_release);
    Print(":-| ", __FUNCTION__,":",m_release);
    Print(":-| ", __FUNCTION__,":",m_release);
    
    // melhorando a administracao do stop_loss quando o EA inicia em meio a uma posicao em andamento
    definirPasso();
    inicializarControlPanel();
    
    return(0);
}


double m_len_canal_ofertas  = 0; // tamanho do canal de oefertas do book.
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

ulong m_trefreshMe        = 0;
ulong m_trefreshFeira     = 0;
ulong m_trefreshTela      = 0;
ulong m_trefreshRates     = 0;
ulong m_tcontarTransacoes = 0;
ulong m_tcloseRajada      = 0;

double m_probAskDescer = 0;
double m_probAskSubir  = 0;
double m_probBidDescer = 0;
double m_probBidSubir  = 0;

MqlTick m_tick_est;
void refreshMe(){

    //m_qtd_exec_refreshme++;
    
    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshRates = GetMicrosecondCount(); #endif
    m_symb.RefreshRates();
    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshRates = GetMicrosecondCount()-m_trefreshRates; #endif
    
    // adicionando o tick ao componente estatistico...
    SymbolInfoTick(m_symb_str,m_tick_est);      
    m_est.addTick(m_tick_est);
    
    m_volTradePorSegLiq=m_est.getVolTradeLiqPorSeg();
    m_volTradePorSegBuy=m_est.getVolTradeBuyPorSeg();
    m_volTradePorSegSel=m_est.getVolTradeSelPorSeg();
    m_lenTradePorSeg   = (m_est.getTradeHigh() - m_est.getTradeLow() )/m_tick_size; // tamanho do canal de ticks formado durante a acumulacao da estatistica. 
            
    m_trade.setStopLoss( m_stopLossOrdens );
    m_trade.setTakeProf( m_tkprof         );
    m_trade.setVolLote ( m_symb_lots_min  );

    m_ask     = m_symb.Ask();
    m_bid     = m_symb.Bid();
    m_ask1    = normalizar(m_ask+m_tick_size);
    m_bid1    = normalizar(m_bid-m_tick_size);
    
    m_canal.refresh(m_ask,m_bid);
    
    // atualizando precos de abertura e fechamento da barra atual...
    CopyRates(m_symb_str,_Period,0,2,m_rates);
    m_high0   = m_rates[0].high;
    m_low0    = m_rates[0].low ;
    m_lenBar0 = m_high0-m_low0;
    m_high1   = m_rates[1].high;
    m_low1    = m_rates[1].low ;
    m_lenBar1 = m_high1-m_low1;
    // distancia desde entrada da ordem ateh o stop (quando trabalha com rajada fixa).
    m_lenAteStop = (EA_DISTAN_PRIM_ORDEM_RAJ                     *m_tick_size)+
                   (EA_DISTAN_DEMAIS_ORDENS_RAJ*EA_TAMANHO_RAJADA*m_tick_size);    
    
    
    m_qtdOrdens   = OrdersTotal();
    m_qtdPosicoes = PositionsTotal();
    
    // adminstrando posicao aberta...
    if( m_qtdPosicoes > 0 ){
        
        if ( PositionSelect  (m_symb_str) ){ // soh funciona em contas hedge
            
            if(m_tempo_posicao_ini == 0) m_tempo_posicao_ini = TimeCurrent();
            m_tempo_posicao_atu = TimeCurrent() - m_tempo_posicao_ini;
            
            //m_pri_book_pode_abrir_pos = true; // para controlar a estrategia de prioridade no book;

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
            m_positionId             = PositionGetInteger(POSITION_IDENTIFIER );
            m_positionCommentStr     = PositionGetString (POSITION_COMMENT    );
            m_positionCommentNumeric = StringToInteger   (m_positionCommentStr);
            m_capitalLiquido         = m_cta.Equity();
            
            
          //m_lucroPosicao = m_capitalLiquido - m_capitalInicial; // voltou versao em 03/02/2020 as 11:50
            m_lucroPosicao = m_posicaoProfit; // passou a usar em 05/06/2020 jah que nessa estrategia as posicoes sao fechadas de vez. 

            ///////////////////////////////////
            if( m_precoPosicaoAnt == 0 ){ m_precoPosicaoAnt = m_precoPosicao;}
            
            // preco da posicao mudou...
            if( m_precoPosicao != m_precoPosicaoAnt ){
                m_precoPosicaoAnt = m_precoPosicao; // salvo no preco anterior
                m_qtd_ticks_4_gain_ini -= m_qtd_ticks_4_gain_decr ; // a cada movimentacao da posicao, reduzo a quantidade de ticks necessarios para o gain.
                Print(":-| "__FUNCTION__, " m_qtd_ticks_4_gain_ini=",m_qtd_ticks_4_gain_ini );
            } 

            if( estouComprado() ){ 
                m_posicaoVolumeTot  = m_volComprasNaPosicao;
                if( EA_STOP_10MINUTOS > 0 && m_tempo_posicao_atu > EA_STOP_10MINUTOS/2 ){
                    m_precoSaidaPosicao = normalizar(m_precoPosicao +  (m_qtd_ticks_4_gain_ini*m_tick_size)/2 );
                }else{
                    m_precoSaidaPosicao = normalizar(m_precoPosicao +  m_qtd_ticks_4_gain_ini*m_tick_size);
                }
            }else{
                if( estouVendido() ){ 
                    m_posicaoVolumeTot  = m_volVendasNaPosicao ;
                    if( EA_STOP_10MINUTOS > 0 && m_tempo_posicao_atu > EA_STOP_10MINUTOS/2 ){
                        m_precoSaidaPosicao = normalizar(m_precoPosicao - (m_qtd_ticks_4_gain_ini*m_tick_size)/2 );
                    }else{
                        m_precoSaidaPosicao = normalizar(m_precoPosicao - m_qtd_ticks_4_gain_ini*m_tick_size);
                    }
                }
            }

             
          //m_lucroPosicao4Gain = (m_posicaoVolumeTot *m_stop_porc);
          //m_lucroPosicao4Gain = (m_posicaoVolumeTot *m_qtd_ticks_4_gain_ini); // passou a usar em 05/06/2020
            m_lucroPosicao4Gain = (m_posicaoVolumePend*m_qtd_ticks_4_gain_ini); // passou a usar em 05/06/2020
            ///////////////////////////////////

            //if( m_abrindo_posicao ){
            //    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print(__FUNCTION__, ":-| Cancelando status de abertura de posicao, pois ha posicao aberta! tktSell=", m_ordem_abertura_posicao_sel, " tktBuy=", m_ordem_abertura_posicao_buy ); #endif
            //    m_abrindo_posicao            = false;
            //    m_ordem_abertura_posicao_sel = 0;
            //    m_ordem_abertura_posicao_buy = 0;
            //}
        }else{
        
           // aqui neste bloco, estah garantido que nao ha posicao aberta...
           m_qtdPosicoes       =  0;
           m_capitalInicial    =  m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
           m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI;
           m_comprado          =  false;
           m_vendido           =  false;
           m_lucroPosicao      =  0;
           m_lucroPosicao4Gain =  0;
           m_posicaoVolumePend =  0; //versao 02-085
           m_posicaoProfit     =  0;
           m_posicaoVolumeTot  =  0;
           m_val_order_4_gain  =  0; // zerando o valor da primeira ordem da posicao...
           m_tempo_posicao_atu =  0;
           m_tempo_posicao_ini =  0;
           m_positionId        = -1;
           m_precoPosicaoAnt   = 0 ;
        }

        ///if( m_fechando_posicao && m_qtdOrdens == 0){
        ///    #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print( __FUNCTION__,":-| Cancelando status de fechamento de posicao, pois nao ha posicao aberta! ticket da ordem de fechamento=", m_ordem_fechamento_posicao );#endif
        ///    m_fechando_posicao         = false;
        ///    m_ordem_fechamento_posicao = 0;
        ///}

    }else{
        // aqui neste bloco, estah garantido que nao ha posicao aberta...
        m_qtdPosicoes          = 0;
        m_capitalInicial       = m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
        m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI;
        m_comprado          = false;
        m_vendido           = false;
        m_lucroPosicao      = 0;
        m_lucroPosicao4Gain = 0;
        m_posicaoVolumePend = 0; //versao 02-085
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

    //m_volTradePorSegTot       += m_volTradePorSeg;
    //m_volTradePorSegMedio      = m_volTradePorSegTot/m_volTradePorSegQtd++;

    m_sld_sessao_atu = m_cta.Balance();
    #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao("normal", true); #endif
      
   #ifndef COMPILE_PRODUCAO 
       if(EA_DEBUG){
           m_trefreshMe = GetMicrosecondCount()-m_trefreshMe;   
    
           if( m_qtd_print_debug++ % 10 == 0 ){
               Print(":-| DEBUG_TIMER:"                       ,
                     " m_tcloseRajada="     ,m_tcloseRajada   ,
                     " m_trefreshMe="       ,m_trefreshMe     ,
                     " m_trefreshFeira="    ,m_trefreshFeira  ,
                     " m_trefreshTela="     ,m_trefreshTela   ,
                     " m_trefreshRates="    ,m_trefreshRates  );
           }
           m_trefreshMe        = 0;
           m_trefreshFeira     = 0;
           m_trefreshCCI       = 0;
           m_trefreshTela      = 0;
           m_trefreshRates     = 0;
           m_tcontarTransacoes = 0;
           m_tcloseRajada      = 0;
       }
   #endif
           
}

void showAcao(string acao, bool debug=false){
   return;
   //if( !debug ){ return; }
   Comment(
         //"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
         //"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
           " \n ticks_consertados="        ,m_est.getQtdTicksConsertados(),
           " \n m_cta.Balance="            ,m_cta.Balance          (),
           " \n m_cta.Equity="             ,m_cta.Equity           (),
           " \n m_cta.Profit="             ,m_cta.Profit           (),
           " \n m_posicao.PriceOpen="      ,m_posicao.PriceOpen    (),
           " \n m_posicao.PriceCurrent="   ,m_posicao.PriceCurrent (),
           " \n m_posicao.Profit= "        ,m_posicao.Profit       (),
           " \n m_posicao.Volume= "        ,m_posicao.Volume       (),
           " \n m_lucroPosicao4Gain="      ,m_lucroPosicao4Gain      ,
           " \n m_passo_rajada="           ,m_passo_rajada           ,
           " \n m_tempo_posicao_atu="      ,m_tempo_posicao_atu      ,
           " \n m_qtd_exec_oninit="        ,m_qtd_exec_oninit        ,
           " \n m_qtd_exec_ontick="        ,m_qtd_exec_ontick        ,
           " \n m_qtd_exec_ontimer="       ,m_qtd_exec_ontimer       ,
           " \n m_qtd_exec_refreshme="     ,m_qtd_exec_refreshme     ,
           " \n m_qtd_exec_closerajada3="  ,m_qtd_exec_closerajada3  ,
           " \n m_qtd_exec_ctrl_risco_pos=",m_qtd_exec_ctrl_risco_pos,
           " \n m_qtd_exec_filaordens="    ,m_qtd_exec_filaordens    ,
           " \n m_qtd_exec_abrirposicao="  ,m_qtd_exec_abrirposicao  ,
           " \n acao="                     ,acao                     ,
           " \n len_canal="                ,m_canal.getLenCanalOperacionalEmTicks(), 
           " \n regiaoSuperior="           ,m_canal.regiaoSuperior(), 
           " \n regiaoInferior="           ,m_canal.regiaoInferior(), 
           " \n precoregiaoSuperior="      ,m_canal.getPrecoRegiaoSuperior(), 
           " \n precoregiaoInferior="      ,m_canal.getPrecoRegiaoInferior() 
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
  m_cp.setVolPosicao   ( DoubleToString (m_posicaoVolumePend,0) + "/"+
                         DoubleToString (m_posicaoVolumeTot ,0)
                       );
  m_cp.setPftBruto  ( m_trade_estatistica.getProfitDia        () );
  m_cp.setTarifa    ( m_trade_estatistica.getTarifaDia        () );
  m_cp.setPftContrat( m_trade_estatistica.getProfitPorContrato() );
  m_cp.setPftLiquido( m_trade_estatistica.getProfitDiaLiquido () );
  m_cp.setVol       ( m_trade_estatistica.getVolumeDia        () );


   //m_cp.setVolTradePorSegDeltaPorc( m_volTradePorSegDeltaPorc );
  ///m_cp.setVolTradePorSegDeltaPorc( m_exp.getLenCanalOperacionalEmTicks() );
   
  m_cp.setVTLiq( m_volTradePorSegLiq, m_volTradePorSegLiqAnt );
  m_cp.setVTBuy( m_volTradePorSegBuy      ); 
  m_cp.setVTSel( m_volTradePorSegSel      );
  m_cp.setVTDir( m_direcaoVelVolTrade   ,0);
  m_cp.setVTLen( m_lenTradePorSeg         );
  m_cp.setVTDir2(m_direcaoVelVolTradeMed,0);
  m_cp.setLEN0  (m_lenBar0,m_lenAteStop);
  m_cp.setLEN1  (m_lenBar1,m_lenAteStop);

}

bool passoAutorizado(){ 
    if( EA_PASSO_DINAMICO ){
        return m_qtd_ticks_4_gain_new >= EA_PASSO_DINAMICO_MIN && m_qtd_ticks_4_gain_new < EA_PASSO_DINAMICO_MAX;
    }
    return true;
}

int m_passo_incremento = 0;
void incrementarPasso(){

    if( m_passo_incremento == 0) return;
    
  //m_qtd_ticks_4_gain_new += (int)(m_qtd_ticks_4_gain_new*m_passo_incremento);
    m_qtd_ticks_4_gain_new += m_passo_incremento;
      
    m_qtd_ticks_4_gain_ini = m_qtd_ticks_4_gain_new;
    m_qtd_ticks_4_gain_raj = m_qtd_ticks_4_gain_new;
    m_passo_rajada         = m_qtd_ticks_4_gain_new;
    m_stop_porc            = m_stop_porc/m_passo_incremento;
}

void definirPasso(){

   if( EA_ALVO_DINAMICO ){

       m_qtd_ticks_4_gain_ini    = m_canal.getLenCanalOperacionalEmTicks()/(double)EA_TAMANHO_RAJADA;
                                             
       m_passo_rajada            = floor(  ( m_canal.getLenCanalOperacionalEmTicks()-
                                             m_canal.getLenCanalOperacionalEmTicks()*
                                             EA_PORC_REGIAO_OPERACIONAL_CANAL         )/(double)EA_TAMANHO_RAJADA
                                        );
     
     //m_passo_rajada                      = floor( m_qtd_ticks_4_gain_ini );
       if( m_passo_rajada == 0 ) m_passo_rajada = 1;
       m_raj_unica_distancia_demais_ordens = m_passo_rajada;
       m_raj_unica_distancia_prim_ordem    = m_passo_rajada;
       m_qtd_ticks_4_gain_decr             = m_qtd_ticks_4_gain_ini/(double)EA_TAMANHO_RAJADA;
       
       m_raj_unica_distancia_prim_ordem    = m_passo_rajada;
       m_raj_unica_distancia_demais_ordens = m_passo_rajada;

       //m_qtd_ticks_4_gain_ini              = m_qtd_ticks_4_gain_bb;
       //m_raj_unica_distancia_demais_ordens = m_qtd_ticks_4_gain_bb;
       //m_raj_unica_distancia_prim_ordem    = m_qtd_ticks_4_gain_bb;
       //m_passo_rajada                      = m_qtd_ticks_4_gain_bb;
     //m_qtd_ticks_4_gain_decr             = m_qtd_ticks_4_gain_bb/(double)(EA_TAMANHO_RAJADA*2.0); // decrementa ateh a metade do t4g.
   }

   if( EA_PASSO_DINAMICO ){
       //m_qtd_ticks_4_gain_new = (int)m_volatilidade_4_seg_media; // testando o passo dinamico com a valatilidade por segundo
       //m_qtd_ticks_4_gain_new = (int)(m_passo_dinamico_porc_canal_entrelaca *  m_len_canal_operacional_em_ticks      ); //<TODO> revise o calculo do passo aqui.
       
       //if( m_qtd_ticks_4_gain_new<EA_PASSO_DINAMICO_MIN ){m_qtd_ticks_4_gain_new=EA_PASSO_DINAMICO_MIN;}
       //if( m_qtd_ticks_4_gain_new>EA_PASSO_DINAMICO_MAX ){m_qtd_ticks_4_gain_new=EA_PASSO_DINAMICO_MAX;}
                                   
       m_qtd_ticks_4_gain_ini =            m_qtd_ticks_4_gain_new;
       m_qtd_ticks_4_gain_raj =            m_qtd_ticks_4_gain_new;
       m_passo_rajada         =      (int)(m_qtd_ticks_4_gain_new*EA_PASSO_DINAMICO_PORC_T4G);
       if( m_passo_rajada < EA_PASSO_DINAMICO_MIN )  m_passo_rajada = EA_PASSO_DINAMICO_MIN;
           
       //EA_STOP_QTD_CONTRAT
       //EA_STOP_PORC_L1
       m_stop_qtd_contrat = EA_PASSO_DINAMICO_STOP_QTD_CONTRAT; 
       m_stop_chunk       = EA_PASSO_DINAMICO_STOP_CHUNK;
       m_stop_porc        = m_qtd_ticks_4_gain_new*EA_PASSO_DINAMICO_STOP_REDUTOR_RISCO;
   }
}

// criando o painel de controle do expert...
bool inicializarControlPanel(){
    if( !EA_SHOW_CONTROL_PANEL ) return true;
    if(!m_cp.Create()                                           ) return(false); // create application dialog
    if(!m_cp.Run()                                              ) return(false); // run application
    return true;
}

double m_passo_dinamico_porc_canal_entrelaca = 0;
//double m_volat4s_alta_porc                   = 0;
//double m_volat4s_stop_porc                   = 0;
double m_stopLossPosicao                     = 0;

void inicializarVariaveisRecebidasPorParametro(){

    m_aguardar_para_abrir_posicao = EA_SLEEP_INI_OPER*1000;

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
    m_qtd_ticks_4_gain_raj = EA_QTD_TICKS_4_GAIN_RAJ;
    m_vol_lote_raj         = EA_VOL_PRIM_ORDEM_RAJ;
    m_vol_lote_ini         = EA_VOL_LOTE_INI;
    m_passo_rajada         = (int)EA_DISTAN_DEMAIS_ORDENS_RAJ;
    m_stop_qtd_contrat     = (int)EA_STOP_CHUNK;
    m_stop_chunk           = (int)EA_STOP_CHUNK;
    m_stop_porc            = EA_STOP_PORC_L1;
    
    // operacao com rajada unica.
    m_raj_unica_distancia_prim_ordem    = EA_DISTAN_PRIM_ORDEM_RAJ   ==0?m_qtd_ticks_4_gain_ini:EA_DISTAN_PRIM_ORDEM_RAJ   ; // se param for zero, usa EA_DISTAN_PRIM_ORDEM_RAJ
    m_raj_unica_distancia_demais_ordens = EA_DISTAN_DEMAIS_ORDENS_RAJ==0?m_qtd_ticks_4_gain_ini:EA_DISTAN_DEMAIS_ORDENS_RAJ; // se param for zero, usa EA_DISTAN_DEMAIS_ORDENS_RAJ
    m_qtd_ticks_4_gain_decr             = EA_QTD_TICKS_4_GAIN_DECR;
    m_Cmedia_direcaoVelocidadeTradeMedia.initialize(EA_EST_QTD_SEGUNDOS);
    
}

// retorna a porcentagem como um numero inteiro.
int porcentagem( double parte, double tot, int seTotZero){
    if( tot==0 ){ return seTotZero ; }
                  return (int)( (parte/tot)*100.0);
}

int m_qtd_print_debug = 0;

void fecharTudo(string descr){ fecharTudo(descr,"",EA_STOP_TICKS_TOLER_SAIDA); }
void fecharTudo(string descr,string strLog){ fecharTudo(descr,strLog,EA_STOP_TICKS_TOLER_SAIDA); }
void fecharTudo(string descr, string strLog, int qtdTicksDeslocamento){
    if( m_qtdPosicoes>0){
        int    qtd = 1;
        string qtdStr;
        string qtdTicksdesloc = IntegerToString(qtdTicksDeslocamento);
        while( m_qtdPosicoes > 0 ){
            qtdStr = IntegerToString(qtd++);
            Print   (":-| ", __FUNCTION__,":",qtdStr,":fecharPosicao2(",descr,",",strLog,",",qtdTicksdesloc,")");
            #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(        __FUNCTION__+":"+qtdStr+":fecharPosicao2("+descr+","+strLog+","+qtdTicksdesloc+")"); #endif
            fecharPosicao2(descr, strLog, qtdTicksDeslocamento);
        }
    }else{
        Print   (__FUNCTION__+":m_trade.cancelarOrdens():descr:"+descr);
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.cancelarOrdens():descr:"+descr); #endif
        m_trade.cancelarOrdens(descr);
    }
}

void fecharPosicao2(string descr, string strLog, int qtdTicksDeslocamento=0, int deep=1){
      
      Print(":-| ", __FUNCTION__,"(",descr,",",strLog,",",qtdTicksDeslocamento,",",deep,")");
      
      //1. providenciando ordens de fechamento que porventura faltem na posicao... 
      #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(        __FUNCTION__+":doCloseRajada():descr:"+descr); #endif
      Print   (":-| ", __FUNCTION__+":doCloseRajada(",m_passo_rajada,",",m_vol_lote_raj,",",m_qtd_ticks_4_gain_raj,")...");
      doCloseRajada(m_qtd_ticks_4_gain_ini);
      
      //2. cancelando rajadas que ainda nao entraram na posicao...
      #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(        __FUNCTION__+":cancelarOrdensRajada():descr:"+descr); #endif
      Print   (":-| ", __FUNCTION__+":cancelarOrdensRajada()..."          );
      cancelarOrdensRajada();
      
      //3. trazendo ordens de fechamento a valor presente...
      #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(        __FUNCTION__+":trazerOrdensComComentarioNumerico2valorPresente():descr:"+descr); #endif
      Print   (":-| ", __FUNCTION__+":trazerOrdensComComentarioNumerico2valorPresente(",m_symb_str,",",qtdTicksDeslocamento,")...");
      m_trade.trazerOrdensComComentarioNumerico2valorPresente(m_symb_str,qtdTicksDeslocamento);
      
      //4. aguardando a execucao das ordens de fechamento...
      Sleep(1000); //<TODO> transforme em parametro
      
      //5. refresh pra saber a situacao atual...
      #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(        __FUNCTION__+":refreshMe():descr:"+descr); #endif
      Print   (":-| ", __FUNCTION__+":refreshMe()..."          );
      refreshMe();
      
      //6. se ainda estamos posicionados, realiza todos os passos novamente...
      if( m_qtdPosicoes > 0 && deep < 5 ){ 
          #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(       __FUNCTION__+":fecharPosicao2():descr:"+descr); #endif
          Print   (":-| ",__FUNCTION__+":fecharPosicao2(",descr,",",strLog,",",qtdTicksDeslocamento,",",deep,")");
          fecharPosicao2(descr, strLog, qtdTicksDeslocamento,++deep); 
      }
      
      // pra que nao cancele ordens de fechamento de posicao...
      if( m_qtdPosicoes > 0 ) return;
      
      //7. cancelando outras ordens pendentes...
      #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(       __FUNCTION__+":cancelarOrdens("+descr+")"); #endif
      Print   (":-| ",__FUNCTION__+":cancelarOrdens(",descr,")");
      m_trade.cancelarOrdens(descr);
}

void cancelarOrdensRajada(){ 
    #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":cancelarOrdensComentadas()"); #endif
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

    m_qtd_exec_ontick++;
    
    #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":refreshme()"); #endif
    refreshMe();


    if ( m_qtdPosicoes > 0 ) {
    
        // Esta opcao NAO_OPERAR nao interfere nas ordens...
        if( EA_ACAO_POSICAO == NAO_OPERAR ) return;

         m_qtdOrdensAnt = 0;

         // estah na hora de fechar as posicoes...
         if( m_eh_hora_de_fechar_posicao ){ fecharTudo("HORA_DE_FECHAR_POSICAO"); return; }

         // se controlarRiscoDaPosicao() retornar true, significa que acionou um stop, entao retornamos daqui.
         #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":controlarRiscoDaPosicao()"); #endif
         if( controlarRiscoDaPosicao() ){ return; }

         if( emLeilao() )return;

         #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__ + ":doCloseRajada()"); #endif
         doCloseRajada(m_qtd_ticks_4_gain_ini);

         //input EA_RAJADA_FIXA = true; // se verdadeiro, cria uma raja unica na abertura da posicao. 
         #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":preencherFilaOrdens()"); #endif
         if( EA_RAJADA_UNICA ){             
             if( m_qtdOrdens < 2 ){
                 // no inicio da posicao, coloca uma unica rajada fixa de ordens para manutencao da mesma. 
                 preencherFilaOrdensFixa(); 
             }
         }else{
             // a cada barra processada, coloca uma ordem na rajada.
             preencherFilaOrdens();
         }

         #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__ + ":alterarValorDeOrdensNumericasPara()"); #endif
         if(m_precoSaidaPosicao!=m_precoSaidaPosicaoAnt){
             m_precoSaidaPosicaoAnt = m_precoSaidaPosicao;
             m_trade.alterarValorDeOrdensNumericasPara(m_symb_str,m_precoSaidaPosicao,m_precoPosicao);
         }
         
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
           if( spreadMaiorQueMaximoPermitido()            ){ cancelarOrdens( "SPREAD_ALTO_" + IntegerToString( m_symb.Spread() ) ); return; }

           // cancelando todas as ordens que nao sejam de abertura de posicao...
           if( m_qtdOrdensAnt != m_qtdOrdens ){
               #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":cancelarOrdensExcetoComTxt(CANC_NOT_APMB)"); #endif
               m_trade.cancelarOrdensExcetoComTxt(m_apmb,"CANC_NOT_APMB");
               m_qtdOrdensAnt = m_qtdOrdens; // para diminuir a quantidade de pedidos de cancelamento repetidos 
           }
           
           //// quando nao abre posicao, deve cancelar tambem as ordens com string m_apmb, pois o open rajada usa esta string.
           //if( EA_ACAO_POSICAO == NAO_ABRIR_POSICAO ){
           //    m_trade.cancelarOrdensComentadas(m_symb_str, m_apmb);
           //}

           // nao estah no intervalo de negociacao, tem ordens abertas e nao tem posicao aberta, entao cancelamos todas as ordens.
           if( !m_estah_no_intervalo_de_negociacao ){ 
              #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":cancelarOrdens(INTERVALO_NEGOCIACAO)"); #endif
              m_trade.cancelarOrdens("INTERVALO_NEGOCIACAO");
                //fecharTudo("INTERVALO_NEGOCIACAO"); // <TODO> tirar apos calibrar os testes
           }
        }

        // fora do intervalo de negociacao nao abrimos novas ordens...
        // <TODO> Verifique porque esta chamada estah antes da checagem de rebaixamento de saldo. Acho que deveria ficar imediatamente antes das chamadas de abertura de novas posicoes.
        if( !m_estah_no_intervalo_de_negociacao ) return;

        /////////////////////////////////////////////////////////////////////////////////////
        // mudou o dia, atualizamos o saldo da sessao...
        if( m_mudou_dia ){
            Print( ":-| MUDOU O DIA! Zerando rebaixamento de saldo...");
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

        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":definirPasso()"); #endif
        definirPasso();

        // verificando proibicoes de operar
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":podeAbrirProsicao()"); #endif
        if (! podeAbrirProsicao() ) { 
            #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":cancelarOrdensExcetoComTxt(STOP,NAO_PODE_ABRIR_POSICAO)"); #endif
            m_trade.cancelarOrdensExcetoComTxt("STOP","NAO_PODE_ABRIR_POSICAO"); 
            return;
        }

        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":switch(EA_ACAO_POSICAO)"); #endif
        switch(EA_ACAO_POSICAO){
            case HFT_CANAL_OPER            : abrirPosicaoHFTCanalOperacional(); break;
          //case HFT_PRIORIDADE_NO_BOOK    : abrirPosicaoHFTPrioridadeNoBook  (); break;
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

bool controlarRiscoDaPosicao(){

     if( saldoRebaixouMaisQuePermitidoNoDia() ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return true;}

     // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
     if( EA_ACAO_POSICAO == FECHAR_POSICAO                                 ) { fecharTudo("STOP_FECHAR_POSICAO"         ,"STOP_FECHAR_POSICAO"         ); return true; }
     if( EA_ACAO_POSICAO == FECHAR_POSICAO_POSITIVA && m_posicaoProfit > 0 ) { fecharTudo("STOP_FECHAR_POSICAO_POSITIVA","STOP_FECHAR_POSICAO_POSITIVA"); return true; }

     // STOP REGIAO CANAL ( em teste...)
     if( ( estouComprado() && m_canal.regiaoInferior() ) ||
         ( estouVendido()  && m_canal.regiaoSuperior() )    ){
         Print(":-( ",__FUNCTION__," Acionando STOP_LOSS_REGIAO_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
         fecharTudo("STOP_LOSS_REGIAO_" + DoubleToString(m_lucroPosicao,0) );
         return true;
     }
     
     if( m_stopLossPosicao != 0 && m_lucroPosicao < m_stopLossPosicao && m_capitalInicial != 0 ){
         Print(":-( ",__FUNCTION__," Acionando STOP_LOSS_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
         fecharTudo("STOP_LOSS_" + DoubleToString(m_lucroPosicao,0) );
         return true;
     }
     
     // fecha a posicao ativa a mais de 10 min
   //if( m_tempo_posicao_atu > EA_STOP_10MINUTOS && EA_STOP_10MINUTOS > 0 && m_posicaoProfit >= 0 ){
     if( m_tempo_posicao_atu > EA_STOP_10MINUTOS && EA_STOP_10MINUTOS > 0                         ){
         Print(":-( ",__FUNCTION__," Acionando STOP_TEMPO_ALTO_"+ DoubleToString(m_lucroPosicao,0)," T=",m_tempo_posicao_atu," ", strPosicao() );
         m_lucroStops += m_lucroPosicao;
         fecharTudo("STOP_TEMPO_ALTO_"+ DoubleToString(m_lucroPosicao,0));
         return true;
     }

     // fecha a posicao ativa se a quantidade de contratos pendentes for maior que o permitido
     if( m_posicaoVolumePend > EA_STOP_QTD_CONTRATOS_PENDENTES && EA_STOP_QTD_CONTRATOS_PENDENTES > 0 ){
         Print(":-( ",__FUNCTION__," Acionando STOP_LOSS_QTD_CONTRATOS_"+ DoubleToString(m_lucroPosicao,0)," VOL=",m_posicaoVolumePend," ", strPosicao() );
         m_lucroStops += m_lucroPosicao;
         fecharTudo("STOP_QTD_CONTRATOS_"+ DoubleToString(m_lucroPosicao,0));
         return true;
     }

     return false;
}

string strPosicao(){
   return " Contr="       + DoubleToString (m_posicaoVolumePend,0)+ "/"+
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
             !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem                                 , m_symb_str, m_strRajada ) &&
             !m_trade.tenhoOrdemLimitadaDeVenda ( normalizar( precoOrdem+profit*m_tick_size ), m_symb_str, m_strRajada ) // se tiver a ordem de venda pendente,
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
     #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_tcloseRajada=GetMicrosecondCount();#endif
     if( estouVendido() ){
         return doCloseRajada3(m_qtd_ticks_4_gain_raj, true );
     }else{
         return doCloseRajada3(m_qtd_ticks_4_gain_raj, false);
     }
     #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_tcloseRajada=GetMicrosecondCount()-m_tcloseRajada;#endif
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
   m_qtd_exec_closerajada3++;
   
   ulong        deal_ticket; // ticket da transacao
   int          deal_type  ; // tipo de operação comercial

   // aproveitando pra atualizar o contador de transacoes na posicao...
   m_volVendasNaPosicao  = 0;
   m_volComprasNaPosicao = 0;
   
   // Faca assim:
   // 1. Coloque vendas e compras em filas separadas.
   // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
   // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.
   #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+"("+IntegerToString(m_qtd_exec_closerajada3)+")->HistorySelectByPosition()" ); #endif
   
   //preenchendo o cache com ordens e transacoes da posicao atual no historico...
   if( !HistorySelectByPosition(m_positionId) ){ return false;} 

   #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+"("+IntegerToString(m_qtd_exec_closerajada3)+")->HistoryDealsTotal()" ); #endif
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
                 #ifndef COMPILE_PRODUCAO if(EA_DEBUG        )Print(":-| HFT_ORDEM CLOSE_RAJADA BUY_LIMIT=",precoProfit, " ID=", idClose, "... ", strPosicao() ); #endif
                 #ifndef COMPILE_PRODUCAO if(EA_SLEEP_ATRASO!= 0) Sleep(EA_SLEEP_ATRASO); #endif
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

string getStrComment(){
  return 
          " a" +DoubleToString (m_est.getInclinacaoHLTrade(),0) + // velocidade do Preco por segundo.
          " b" +DoubleToString (m_est.getVolTradeLiqPorSeg(),0) + // Velocidade do volume por segundo.
          " c" +DoubleToString (m_est.getAceVolLiq()        ,0) + // Aceleracao da velocidade do volume por segundo ao quadrado.
          " d" +DoubleToString (m_est.getKyleLambda()       *1000000,0) + // risco de compra (Buy).
          " e" +DoubleToString (m_est.getKyleLambdaHLTrade()*1000000,0) ; // risco de venda  (Sell).
/*
          " a" +DoubleToString (m_lenTradePorSeg     ,0) + // tamanho, em ticks, da barra de acumulacao de ticks para estatistica.
          " b" +DoubleToString (m_volTradePorSegLiq  ,0) + // banda superior da bolinger.
          " c" +DoubleToString (m_volTradePorSegBuy  ,0) + // banda media    da bolinger.
          " d" +DoubleToString (m_volTradePorSegSel  ,0) + // desvio padrao  da bolinger em pontos.
          " e" +IntegerToString(EA_EST_QTD_SEGUNDOS    ) ; // banda inferior da bolinger.
*/
}

//-----------------------------------------------------------------------------------------------------------------------------
// HFT_CANAL_OPER
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
void abrirPosicaoHFTCanalOperacional(){

    //m_qtd_exec_abrirposicao++;    
    //double precoOrdem  = 0.0;
    //m_min_analisado    = 0;
   
    if( m_ask==0.0 || m_bid==0.0                                                                                     ){   
        Print(__FUNCTION__," Erro :m_bid=",m_ask, " m_bid=",m_bid );
        m_aguardar_para_abrir_posicao = EA_EST_QTD_SEGUNDOS*1000; // aguarda ateh poder abrir nova posicao
        
        // se tinha ordem pendente, cancela
        m_trade.cancelarOrdensComentadas(m_symb_str,m_apmb     );
        m_trade.cancelarOrdensComentadas(m_symb_str,m_strRajada);
        
        return;
    }
    
    // tendencia de alta...
    if( m_canal.regiaoSuperior() ){
        
        // providenciando a ordem de entrada na posicao...
        m_precoOrdem = m_bid;

        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__ + ":m_trade.tenhoOrdemLimitadaDeCompra()"); #endif
        if( !m_trade.tenhoOrdemLimitadaDeCompra( m_precoOrdem, m_symb_str, m_apmb, m_vol_lote_ini , true, m_tick_size*m_shift, m_apmb_buy+getStrComment() ) ){
            #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__ + ":m_trade.enviarOrdemPendente()"); #endif
            if(m_precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , m_precoOrdem, m_vol_lote_ini, m_apmb_buy+getStrComment() );
        }        

        // cancelando ordens de venda porventura colocadas...
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.cancelarOrdensComentadasDeVenda("+","+m_symb_str+","+m_apmb     +")"); #endif
        if( ! m_trade.cancelarOrdensComentadasDeVenda(m_symb_str ,m_apmb     ) ) return; // se teve algum problema cancelando ordens, nao segue criando outras
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.cancelarOrdensComentadasDeVenda("+","+m_symb_str+","+m_strRajada+")"); #endif
        if( ! m_trade.cancelarOrdensComentadasDeVenda(m_symb_str ,m_strRajada) ) return; // se teve algum problema cancelando ordens, nao segue criando outras
        
        return;
    }else{
        
        // tendencia de baixa...
        if( m_canal.regiaoInferior() ){
        
            // providenciando a ordem de entrada na posicao...
            m_precoOrdem = m_ask;
    
            #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__ + ":m_trade.tenhoOrdemLimitadaDeVenda()"); #endif
            if( !m_trade.tenhoOrdemLimitadaDeVenda( m_precoOrdem, m_symb_str, m_apmb, m_vol_lote_ini , true, m_tick_size*m_shift, m_apmb_sel+getStrComment() ) ){
                #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__ + ":m_trade.enviarOrdemPendente()"); #endif
                if(m_precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT , m_precoOrdem, m_vol_lote_ini, m_apmb_sel+getStrComment() );
            }
            return;

            // cancelando ordens de compra porventura colocadas...
            #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.cancelarOrdensComentadasDeCompra("+","+m_symb_str+","+m_apmb     +")"); #endif
            if( ! m_trade.cancelarOrdensComentadasDeCompra(m_symb_str, m_apmb     ) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras
            #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.cancelarOrdensComentadasDeCompra("+","+m_symb_str+","+m_strRajada+")"); #endif
            if( ! m_trade.cancelarOrdensComentadasDeCompra(m_symb_str, m_strRajada) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras    
        }
    }
    // se chegou aqui eh porque nao ha condicao para abrir posicao. Entao cancela pedidos de entrada pendentes.    
    m_trade.cancelarOrdensComentadas(m_symb_str,m_apmb     );
    m_trade.cancelarOrdensComentadas(m_symb_str,m_strRajada);
}
//-----------------------------------------------------------------------------------------------------------------------------

//
// A cada mudanda de periodo faz:
// Posicao vendido : Coloca ordem limitada de venda  no preco maximo do periodo anterior ou no preco atual (o maior)
// Posicao comprado: Coloca ordem limitada de compra no preco minimo do periodo anterior ou no preco atual (o menor)
//
//int m_min_analisado = 0;
datetime m_time_analisado = TimeCurrent();
MqlRates m_rates1_tmp[1];
void preencherFilaOrdens(){

    m_qtd_exec_filaordens++;

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

    double precoOrdem = 0;
    double distancia  = (EA_DISTAN_DEMAIS_ORDENS_RAJ*m_tick_size);
    double shift      = 0;
    // Posicao vendido : Coloca ordem limitada de venda  no preco maximo do periodo anterior ou no preco atual (o maior)
    if( estouVendido() ){
    
    //  // uma ordem no preco atual...
    //  precoOrdem = normalizar( m_ask + distancia );
    ////if( precoOrdem < m_ask ){ precoOrdem = m_ask; }
    //  showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()");
    //  if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

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
        precoOrdem = normalizar( phigh );
        if( precoOrdem < m_ask ){ precoOrdem = m_ask; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , precoOrdem, m_vol_lote_ini*EA_INCREM_VOL_RAJ, m_strRajada+getStrComment() );
        m_time_analisado = m_rates1_tmp[0].time;
        return;
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////        

        // outra ordem na maxima da barra anterior...
      //precoOrdem = normalizar( m_rates1_tmp[0].high + distancia );
        precoOrdem = normalizar( phigh );
        if( precoOrdem < m_ask ){ precoOrdem = m_ask; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        ////////////////////////////////////////////////////////////////////////
        // NOVOS EM TESTE (saiu o preco atual)
        ////////////////////////////////////////////////////////////////////////
        // outra ordem na minima da barra anterior...
      //precoOrdem = normalizar( m_rates1_tmp[0].low + distancia );
        precoOrdem = normalizar( plow );
        if( precoOrdem < m_ask ){ precoOrdem = m_ask; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        // outra ordem na abertura da barra anterior...
      //precoOrdem = normalizar( m_rates1_tmp[0].open + distancia );
        precoOrdem = normalizar( popen );
        if( precoOrdem < m_ask ){ precoOrdem = m_ask; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        // outra ordem no fechamento da barra anterior...
      //precoOrdem = normalizar( m_rates1_tmp[0].close + distancia );
        precoOrdem = normalizar( pclose );
        if( precoOrdem < m_ask ){ precoOrdem = m_ask; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );
        ////////////////////////////////////////////////////////////////////////
        
        m_time_analisado = m_rates1_tmp[0].time;
    }

    // Posicao comprado: Coloca ordem limitada de compra no preco minimo do periodo anterior ou no preco atual (o menor)
    if( estouComprado() ){

   //   // uma ordem no preco atual...
   //   precoOrdem = normalizar( m_bid - distancia );
   // //if( precoOrdem > m_bid ){ precoOrdem = m_bid; }
   //   showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()");
   //   if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

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
        precoOrdem = normalizar( plow );
        if( precoOrdem > m_bid ){ precoOrdem = m_bid; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini*EA_INCREM_VOL_RAJ, m_strRajada+getStrComment() );
        m_time_analisado = m_rates1_tmp[0].time;
        return;
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////


        // outra ordem no minimo da barra anterior...
      //precoOrdem = normalizar( m_rates1_tmp[0].low - distancia );
        precoOrdem = normalizar( plow );
        if( precoOrdem > m_bid ){ precoOrdem = m_bid; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        
        ////////////////////////////////////////////////////////////////////////
        // NOVOS EM TESTE
        ////////////////////////////////////////////////////////////////////////
        // outra ordem na maxima da barra anterior...
      //precoOrdem = normalizar( m_rates1_tmp[0].high - distancia );
        precoOrdem = normalizar( phigh );
        if( precoOrdem > m_bid ){ precoOrdem = m_bid; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        // outra ordem na abertura da barra anterior...
      //precoOrdem = normalizar( m_rates1_tmp[0].open - distancia );
        precoOrdem = normalizar( popen );
        if( precoOrdem > m_bid ){ precoOrdem = m_bid; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );

        // outra ordem no fechamento da barra anterior...
      //precoOrdem = normalizar( m_rates1_tmp[0].close - distancia );
        precoOrdem = normalizar( pclose );
        if( precoOrdem > m_bid ){ precoOrdem = m_bid; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, m_strRajada+getStrComment() );
        
        
        m_time_analisado = m_rates1_tmp[0].time;
    }


    //showAcao(__FUNCTION__ + ":doCloseRajada()");
    //doCloseRajada(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_ini);

    //showAcao(__FUNCTION__ + ":alterarValorDeOrdensNumericasPara()");
    //m_trade.alterarValorDeOrdensNumericasPara(m_symb_str,m_precoSaidaPosicao,m_precoPosicao);

}

void preencherFilaOrdensFixa(){

    m_qtd_exec_filaordens++;

    double precoOrdem           = 0;
    double passoRajada          = (m_raj_unica_distancia_demais_ordens*m_tick_size);
    double passoRajadaPrimOrdem = (m_raj_unica_distancia_prim_ordem   *m_tick_size);
    double shift                = 0;
    // Posicao vendido : Coloca rajada de ordens limitadas de venda
    if( estouVendido() ){
    
        precoOrdem = normalizar( m_precoPosicao+passoRajadaPrimOrdem );
        if( precoOrdem < m_ask ){ precoOrdem = m_ask; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendenteRajada( ORDER_TYPE_SELL_LIMIT , precoOrdem, m_vol_lote_raj, m_strRajada+getStrComment(),passoRajada,EA_INCREM_VOL_RAJ,EA_INCREM_DISTAN_DEMAIS_ORDENS_RAJ, EA_TAMANHO_RAJADA, EA_STOP_NA_RAJADA, EA_PORC_STOP_NA_RAJADA );
        //m_time_analisado = m_rates1_tmp[0].time;
        return;
    }

    // Posicao comprado: Coloca rajadas de ordens limitadas de compra
    if( estouComprado() ){

        precoOrdem = normalizar( m_precoPosicao-passoRajadaPrimOrdem );
        if( precoOrdem > m_bid ){ precoOrdem = m_bid; }
        #ifdef DEBUG_SHOW_ACAO if(EA_DEBUG) showAcao(__FUNCTION__+":m_trade.enviarOrdemPendente()"); #endif
        if( precoOrdem != 0 )m_trade.enviarOrdemPendenteRajada( ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_raj, m_strRajada+getStrComment(),-passoRajada,EA_INCREM_VOL_RAJ,EA_INCREM_DISTAN_DEMAIS_ORDENS_RAJ, EA_TAMANHO_RAJADA, EA_STOP_NA_RAJADA, EA_PORC_STOP_NA_RAJADA );
        //m_time_analisado = m_rates1_tmp[0].time;
        return;
    }
}

//bool taxaVolPermiteAbrirPosicao (){return EA_VOLSEG_MAX_ENTRADA_POSIC==0 || m_volTradePorSeg <= EA_VOLSEG_MAX_ENTRADA_POSIC ;}
//bool volatilidadeEstahAlta    (){return m_volatilidade       > EA_VOLAT_ALTA                                  && EA_VOLAT_ALTA       != 0;}
//bool volatilidade4segEstahAlta(){return m_volatilidade_4_seg > m_volatilidade_4_seg_media*m_volat4s_alta_porc && m_volat4s_alta_porc != 0;}
//bool volat4sExigeStop         (){return m_volatilidade_4_seg > m_volatilidade_4_seg_media*m_volat4s_stop_porc && m_volat4s_stop_porc != 0;}
//bool volat4sPermiteAbrirPosicao(){ return m_volatilidade_4_seg <= EA_VOLAT4S_MIN ||  EA_VOLAT4S_MIN == 0; }
bool spreadMaiorQueMaximoPermitido(){ return m_symb.Spread() > m_spread_maximo_in_points && m_spread_maximo_in_points != 0; }

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

                                            Print(m_name,":-| Expert ", m_name, " Iniciando metodo OnDeinit..." );
    //BBDeleFromChart();                      Print(m_name,":-| Expert ", m_name, " Indicador GMMA retirado do grafico:", GetLastError() );
    //BBRelease();                            Print(m_name,":-| Expert ", m_name, " Manipuladores GMMA liberados:", GetLastError() );
    //delLineMinPreco();                    Print(m_name,":-| Expert ", m_name, " Linha de preco minimo elimnada." );
    //delLineMaxPreco();                    Print(m_name,":-| Expert ", m_name, " Linha de preco maximo elimnada." );
    //delLineTimeDesdeEntrelaca();          Print(m_name,":-| Expert ", m_name, " Linha horizontal entrelacamento eliminada." );
    //delLineMaiorPrecoCompra();            Print(m_name,":-| Expert ", m_name, " Linha horizontal regiao de compra." );
    //delLineMenorPrecoVenda();             Print(m_name,":-| Expert ", m_name, " Linha horizontal regiao de venda."  );
    EventKillTimer();                     Print(m_name,":-| Expert ", m_name, " Timer destruido." );
    
    
  //m_feira.DeleteFromChart(0,0);         Print(m_name,":-| Expert ", m_name, " Indicador feira retirado do grafico." );
  //IndicatorRelease( m_feira.Handle() ); Print(m_name,":-| Expert ", m_name, " Manipulador do indicador feira liberado." );
    MarketBookRelease(m_symb_str);        Print(m_name,":-| Expert ", m_name, " Manipulador do Book liberado." );
    //IndicatorRelease( m_icci.Handle()  ); Print(m_name,":-| Expert ", m_name, " Manipulador do indicador cci   liberado." );
    //IndicatorRelease( m_ibb.Handle()    );
    
    if( EA_SHOW_CONTROL_PANEL ) { m_cp.Destroy(reason); Print(m_name,":-| Expert ", m_name, " Painel de controle destruido." ); }
    
    Comment("");                          Print(m_name,":-| Expert ", m_name, " Comentarios na tela apagados." );
                                          Print(m_name,":-) Expert ", m_name, " OnDeinit finalizado!" );
    return;
}

double OnTester(){ m_trade_estatistica.print_posicoes(0, m_time_in_seconds_atu); return 0; }


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

void printHeartBit(){ if(m_date_ant.min != m_date_atu.min) Print(":-| HeartBit!"); }

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

    m_qtd_exec_ontimer++;
    
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
  //calcularDirecaoVelocidadeDoVolume();
  //refreshControlPanel();

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
    //if (EA_SHOW_CONTROL_PANEL) m_trade_estatistica.refresh(m_time_in_seconds_ini_day, m_time_in_seconds_atu);
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
    
    if( m_aguardar_para_abrir_posicao < 0 ) m_aguardar_para_abrir_posicao = 0;    
}

string m_strRun = "";
void OnChartEvent(const int    id     , 
                  const long   &lparam, 
                  const double &dparam, 
                  const string &sparam){

    // servico de calculo de runs...
    //if(id==SVC_RUN+CHARTEVENT_CUSTOM){ m_strRun = "\n\n" + sparam; }
    
    // painel de controle...
    if( EA_SHOW_CONTROL_PANEL ) m_cp.ChartEvent(id,lparam,dparam,sparam);

}
