﻿//+------------------------------------------------------------------+
//|                            ose-minion-02-486-rajada-HFT-1min.mq5 |
//|                                         Copyright 2019, OS Corp. |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao 2.486                                                     |
//| 1. Fork da versao 2.388 feito em 09/01/2020.                     |
//|                                                                  |
//| 02-486 Parametro para gravar sql no log                          |
//| 02-486 Usa indicar feira 0307                                    |
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
#property version   "2.486"

#include <Indicators\Trend.mqh>
#include <Indicators\Volumes.mqh>
#include <Indicators\Oscilators.mqh>
#include <Generic\Queue.mqh>
#include <Generic\HashMap.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

#include <..\Projects\projetcts\os-ea\ClassMinion-02-com-estatistica.mqh>
#include <oslib\osc\osc-minion-trade-03.mqh>
#include <oslib\osc-ind-minion-feira.mqh>
#include <oslib\os-lib.mq5>


#define SLEEP_PADRAO  50
#define COMPILE_PRODUCAO

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
     CONTRA_TEND_DURANTE_COMPROMETIMENTO  , //CONTRA_TEND_DURANTE_COMPROMETIMENTO Abre posicao, na direcao contraria, se o preco atingir a media de precos do book. Ex: abre posicao de venda de preco atingir a media de ofertas ask.
     CONTRA_TEND_APOS_COMPROMETIMENTO     , //CONTRA_TEND_APOS_COMPROMETIMENTO Igual ao anterior, mas após o preco romper a media de ofertas do book.
     CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR , //CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR Abre posicao contraria quando o preço passa o máximo ou mínimo da vela anterior.
     HFT_DISTANCIA_PRECO                  , //HFT_DISTANCIA_PRECO Abre posicao contraria, se o preco se afastar X ticks do preço atual.
     HFT_MAX_MIN_VOLAT                    , //HFT_MAX_MIN_VOLAT Abre posicao contraria, se o preco ultrapassar o preco maximo ou minimo do ultimo minuto.
     HFT_TEND_CCI                         , //HFT_TEND_CCI Abre posicao a favor da tendencia, de acordo com o indicador CCI.
     HFT_NA_TENDENCIA                     , //HFT_NA_TENDENCIA Abre posicao a favor da tendencia em funcao da inclinacao do preco medio.
     HFT_DESBALANC_BOOK                   , //HFT_DESBALANC_BOOK Abre posicao segundo desbalancemaneto das primeiras filas do book.
     HFT_DESBALANC_BOOKNS                 , //HFT_DESBALANC_BOOKNS Abre posicao segundo desbalancemaneto das primeiras filas do book.
     HFT_NORTE_SUL                        , //HFT_NORTE_SUL Coloca as ordens de entrata e saida em paralelo.
     HFT_MEDIA_TRADE                      , //HFT_MEDIA_TRADE
     HFT_ARBITRAGEM_VOLUME                , //HFT_ARBITRAGEM_VOLUME
     HFT_DISTANCIA_DA_MEDIA                 //HFT_DISTANCIA_DA_MEDIA: abre posicao a qtd_ticks_4_gain da media de trade (29/01/2020)
};

//---------------------------------------------------------------------------------------------
input group "gerais"
input ENUM_TIPO_OPERACAO EA07_ABRIR_POSICAO = FECHAR_POSICAO ; //EA07_ABRIR_POSICAO:Forma de operacao do EA.
input double EA_SPREAD_MAXIMO       =  4        ; //EA_SPREAD_MAXIMO em ticks. Se for maior que o maximo, nao abre novas posicoes.
//
input group "volume por segundo"
input int    EA_VOLSEG_L1           =  50      ; //VOLSEG_L1  : Vol de contratos por segundo L1.
input int    EA_VOLSEG_L2           =  100     ; //VOLSEG_L2  : Vol de contratos por segundo L2.
input int    EA_VOLSEG_L3           =  150     ; //VOLSEG_L3  : Vol de contratos por segundo L3.
input int    EA_VOLSEG_L4           =  200     ; //VOLSEG_L4  : Vol de contratos por segundo L4
input int    EA_VOLSEG_L5           =  250     ; //VOLSEG_L5  : Vol de contratos por segundo L5
input int    EA_VOLSEG_ALTO         =  400     ; //VOLSEG_ALTO: Vol de contratos por segundo que eh considerado alto.
input int    EA_VOLSEG_MAX_ENTRADA_POSIC = 150;//EA_VOLSEG_MAX_ENTRADA_POSIC: vol/seg maximo para entrar na posicao.
//
input group "qtd ticks para o gain na ENTRADA"
input int    EA_QTD_TICKS_4_GAIN_INI_L1   =  3      ; //QTD_TICKS_4_GAIN_INI_L1:Qtd ticks para o gain qd vol/seg eh level 1;
input int    EA_QTD_TICKS_4_GAIN_INI_L2   =  3      ; //QTD_TICKS_4_GAIN_INI_L2:Qtd ticks para o gain qd vol/seg eh level 2;
input int    EA_QTD_TICKS_4_GAIN_INI_L3   =  3      ; //QTD_TICKS_4_GAIN_INI_L3:Qtd ticks para o gain qd vol/seg eh level 3;
input int    EA_QTD_TICKS_4_GAIN_INI_L4   =  3      ; //QTD_TICKS_4_GAIN_INI_L4:Qtd ticks para o gain qd vol/seg eh level 4;
input int    EA_QTD_TICKS_4_GAIN_INI_L5   =  3      ; //QTD_TICKS_4_GAIN_INI_L5:Qtd ticks para o gain qd vol/seg eh level 5;
input int    EA_QTD_TICKS_4_GAIN_INI_ALTO =  3      ; //QTD_TICKS_4_GAIN_INI_ALTO:Qtd ticks para o gain qd vol/seg eh maior que level 5;
//
input group "qtd ticks para o gain na RAJADA"
input int    EA_QTD_TICKS_4_GAIN_RAJ_L1   =  3      ; //QTD_TICKS_4_GAIN_RAJ_L1:Qtd ticks para o gain qd vol/seg eh level 1;
input int    EA_QTD_TICKS_4_GAIN_RAJ_L2   =  3      ; //QTD_TICKS_4_GAIN_RAJ_L2:Qtd ticks para o gain qd vol/seg eh level 2;
input int    EA_QTD_TICKS_4_GAIN_RAJ_L3   =  3      ; //QTD_TICKS_4_GAIN_RAJ_L3:Qtd ticks para o gain qd vol/seg eh level 3;
input int    EA_QTD_TICKS_4_GAIN_RAJ_L4   =  3      ; //QTD_TICKS_4_GAIN_RAJ_L4:Qtd ticks para o gain qd vol/seg eh level 4;
input int    EA_QTD_TICKS_4_GAIN_RAJ_L5   =  3      ; //QTD_TICKS_4_GAIN_RAJ_L5:Qtd ticks para o gain qd vol/seg eh level 5;
input int    EA_QTD_TICKS_4_GAIN_RAJ_ALTO =  3      ; //QTD_TICKS_4_GAIN_RAJ_ALTO:Qtd ticks para o gain qd vol/seg eh maior que level 5;
//
input group "volume lote entrada"
input double EA_VOL_LOTE_INI_L1   =  1        ; //VOL_LOTE_INI_L1:Vol do lote a ser usado na abertura de posicao qd vol/seg eh L1.
input double EA_VOL_LOTE_INI_L2   =  1        ; //VOL_LOTE_INI_L2:Vol do lote a ser usado na abertura de posicao qd vol/seg eh L2.
input double EA_VOL_LOTE_INI_L3   =  1        ; //VOL_LOTE_INI_L3:Vol do lote a ser usado na abertura de posicao qd vol/seg eh L3.
input double EA_VOL_LOTE_INI_L4   =  1        ; //VOL_LOTE_INI_L4:Vol do lote a ser usado na abertura de posicao qd vol/seg eh L4.
input double EA_VOL_LOTE_INI_L5   =  1        ; //VOL_LOTE_INI_L5:Vol do lote a ser usado na abertura de posicao qd vol/seg eh L5.
input double EA_VOL_LOTE_INI_ALTO =  1        ; //VOL_LOTE_INI_ALTO:Vol do lote a ser usado na abertura de posicao qd vol/seg eh maior que L5.
//
input group "volume lote rajada"
input double EA_VOL_LOTE_RAJ_L1         = 1   ; //VOL_LOTE_RAJ_L1:Vol do lote a ser usado qd vol/seg eh L1.
input double EA_VOL_LOTE_RAJ_L2         = 1   ; //VOL_LOTE_RAJ_L2:Vol do lote a ser usado qd vol/seg eh L2.
input double EA_VOL_LOTE_RAJ_L3         = 1   ; //VOL_LOTE_RAJ_L3:Vol do lote a ser usado qd vol/seg eh L3.
input double EA_VOL_LOTE_RAJ_L4         = 1   ; //VOL_LOTE_RAJ_L4:Vol do lote a ser usado qd vol/seg eh L4.
input double EA_VOL_LOTE_RAJ_L5         = 1   ; //VOL_LOTE_RAJ_L5:Vol do lote a ser usado qd vol/seg eh L5.
input double EA_VOL_LOTE_RAJ_ALTO       = 1   ; //VOL_LOTE_ALTO:Vol do lote a ser usado qd vol/seg eh maior que L5.
//
input group "passo rajada"
input double EA_PASSO_RAJ_L1   =  3       ; //PASSO_RAJ_L1:Incremento de preco, em tick, na direcao contraria a posicao;
input double EA_PASSO_RAJ_L2   =  3       ; //PASSO_RAJ_L2:Incremento de preco, em tick, na direcao contraria a posicao;
input double EA_PASSO_RAJ_L3   =  3       ; //PASSO_RAJ_L3:Incremento de preco, em tick, na direcao contraria a posicao;
input double EA_PASSO_RAJ_L4   =  3       ; //PASSO_RAJ_L4:Incremento de preco, em tick, na direcao contraria a posicao;
input double EA_PASSO_RAJ_L5   =  3       ; //PASSO_RAJ_L5:Incremento de preco, em tick, na direcao contraria a posicao;
input double EA_PASSO_RAJ_ALTO =  3       ; //PASSO_RAJ_ALTO:Incremento de preco, em tick, na direcao contraria a posicao qd vol/seg eh level 5;
//
input group "stops"
input int    EA_TICKS_STOP_LOSS   =  15   ; //TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
input int    EA_TICKS_TKPROF      =  30   ; //TICKS_TKPROF:Quantidade de ticks usados no take profit;
input double EA_REBAIXAMENTO_MAX  =  0    ; //REBAIXAMENTO_MAX:Rebaixamento maximo de saldo aceitavel desde a entrada na sessao.
input double EA07_STOP_LOSS       = -1200 ; //STOP_LOSS:Valor maximo de perda aceitavel;
input double EA_STOP_QTD_CONTRAT  =  10   ; //STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
input double EA_STOP_PORC_CONTRAT =  0    ; //STOP_PORC_CONTRAT:Porcentagen de contratos pendentes em relacao aos contratos totais para fechar a posicao.
input double EA_STOP_PORC_L1      =  1    ; //STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
input double EA_STOP_L2           =  -150 ; //STOP_L2:Se contratos pendentes maior que EA_STOP_QTD_CONTRAT*2, fecha posicao se profit for maior que o informado;
input double EA_STOP_L3           =  -300 ; //STOP_L3:Se contratos pendentes maior que EA_STOP_QTD_CONTRAT*3, fecha posicao se profit for maior que o informado;
input double EA_STOP_L4           =  -600 ; //STOP_L4:Se contratos pendentes maior que EA_STOP_QTD_CONTRAT*4, fecha posicao se profit for maior que o informado;
input long   EA_10MINUTOS         =  0    ; //10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
//
input group "volatilidade e inclinacoes"
input double EA_VOLAT_ALTA               = 1.5 ;//VOLAT_ALTA:Volatilidade a considerar alta(%).
input double EA_INCL_ALTA                = 0.9 ;//INCL_ALTA:Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
input double EA_INCL_MIN                 = 0.1 ;//INCL_MIN:Inclinacao minima para entrar no trade.
input int    EA_MIN_DELTA_VOL            = 10  ;//MIN_DELTA_VOL:%delta vol minimo para entrar na posicao
input int    EA_MIN_DELTA_VOL_ACELERACAO = 1   ;//MIN_DELTA_VOL_ACELERACAO:Aceleracao minima da %delta vol para entrar na posicao
input int    EA_QTD_SEG_TIMER            = 250 ;//QTD_SEG_TIMER:Tempo de acionamento do timer.
//
input group "show_tela"
input bool   EA_SHOW_TELA              =  false; //SHOW_TELA:mostra valor de variaveis na tela;
input uint   EA_SHOW_TELA_LINHAS_ACIMA =  0    ; //SHOW_TELA_LINHAS_ACIMA:permite impressao na parte inferior da tela;
//
input group "diversos"
input bool   EA_DEBUG             =  false; //DEBUG:se true, grava informacoes de debug no log do EA.
input bool   EA_CLOSE_RAJADA2     =  true ; //CLOSE_RAJADA2: close rajada mais rapido.
input int    EA08_MAGIC           =  200102486; //Numero magico desse EA. yymmvvvvv.
input int    SLEEP_ATRASO         =  0        ; //SLEEP_TESTE_ONLINE.

//
input group "estrategia distancia do preco"
input int    EA_TICKS_ENTRADA_DIST_PRECO =  1 ;//TICKS_ENTRADA_DIST_PRECO:Usado na entrada tipo HFT_DISTANCIA_PRECO. Distancia do preco para entrar na proxima posicao; .
//
input group "estrategia distancia da media"
input int    EA_TICKS_ENTRADA_DIST_MEDIA =  2 ;//TICKS_ENTRADA_DIST_MEDIA:Usado na entrada tipo HFT_DISTANCIA_DA_MEDIA. Distancia da media para entrar na proxima posicao; .
//
input group "estrategia desbalanceamento"
input double EA_DESBALAN_UP0             =  0.8; //EA_DESBALAN_UP0:Desbalanceamento na primeira fila do book para comprar na estrategia de desbalanceamento.
input double EA_DESBALAN_DW0             =  0.2; //EA_DESBALAN_DW0:Desbalanceamento na primeira fila do book para vender  na estrategia de desbalanceamento.
input double EA_DESBALAN_UP1             =  0.7; //EA_DESBALAN_UP1:Desbalanceamento na segunda  fila do book para comprar na estrategia de desbalanceamento.
input double EA_DESBALAN_DW1             =  0.3; //EA_DESBALAN_DW1:Desbalanceamento na segunda  fila do book para vender  na estrategia de desbalanceamento.

//input double EA09_VOLAT_BAIXA       =  0.2      ; //Volatilidade a considerar baixa(%).
//input double EA09_VOLAT_MEDIA       =  0.7      ; //Volatilidade a considerar media(%).
//input double EA09_INCL_MAX_IN       =  0.5      ; //EA09_INCL_MAX_IN:Inclinacao max p/ entrar no trade.
//input double EA04_DX_TRAILLING_STOP =  1.0      ; //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
//input double EA10_DX1               =  0.2      ; //EA10_DX1:Tamanho do DX em relacao a banda em %;
//input double EA01_MAX_VOL_EM_RISCO  =  200      ; //EA01_MAX_VOL_EM_RISCO:Qtd max de contratos em risco; Sao os contratos pendentes da posicao.

#define EA01_MAX_VOL_EM_RISCO   200        //EA01_MAX_VOL_EM_RISCO:Qtd max de contratos em risco; Sao os contratos pendentes da posicao.
//#define EA_DEBUG              false nn   //EA_DEBUG:se true, grava informacoes de debug no log do EA.
#define EA04_DX_TRAILLING_STOP  1.0        //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
#define EA10_DX1                0.2        //EA10_DX1:Tamanho do DX em relacao a banda em %;


//---------------------------------------------------------------------------------------------
// configurando a banda de bollinguer...
input group "indicador banda de bollinguer"
input int                BB_QTD_PERIODOS      = 8             ; //BB_QTD_PERIODOS.
input int                BB_DESVIOS           = 2             ; //BB_DESVIOS.
input ENUM_APPLIED_PRICE BB_APLIED_PRICE      = PRICE_WEIGHTED; //BB_APLIED_PRICE.
input ENUM_TIPO_ENTRADA_PERMITDA EA_TIPO_ENTRADA_PERMITIDA = ENTRADA_TODAS;//TIPO_ENTRADA_PERMITIDA Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
//---------------------------------------------------------------------------------------------
// configurando a feira...
input group "indicador feira"
//input bool   FEIRA01_DEBUG             = false ; // se true, grava informacoes de debug no log.
input bool     FEIRA02_GERAR_VOLUME      = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input bool     FEIRA03_GERAR_OFERTAS     = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
//input int    FEIRA04_QTD_BAR_PROC_HIST = 0     ; // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
//input double FEIRA05_BOOK_OUT          = 0     ; // Porcentagem das extremidades dos precos do book que serão desprezados.
input int      FEIRA06_QTD_SEGUNDOS      = 60    ; // Quantidade de segundos que serao acumulads para calcular as medias.
input bool     FEIRA07_GERAR_SQL_LOG     = false ; // Se true grava comandos sql no log para insert do book em tabela postgres.
//input bool   FEIRA99_ADD_IND_2_CHART   = true  ; // Se true apresenta o idicador feira no grafico.

#define FEIRA01_DEBUG             false  // se true, grava informacoes de debug no log.
#define FEIRA04_QTD_BAR_PROC_HIST 0      // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
#define FEIRA05_BOOK_OUT          0      // Porcentagem das extremidades dos precos do book que serão desprezados.
#define FEIRA99_ADD_IND_2_CHART   true   // Se true apresenta o idicador feira no grafico.

//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
input group "horario de operacao"
input int    HR_INI_OPERACAO   = 09; // Hora   de inicio da operacao;
input int    MI_INI_OPERACAO   = 30; // Minuto de inicio da operacao;
input int    HR_FIM_OPERACAO   = 18; // Hora   de fim    da operacao;
input int    MI_FIM_OPERACAO   = 50; // Minuto de fim    da operacao;
//---------------------------------------------------------------------------------------------

CiBands*      m_ibb;
CiCCI*        m_icci;
CiAD*         m_iad;
CiMFI*        m_imfi;
CiMA*         m_ima;

MqlDateTime   m_date;
string        m_name = "MINION-02-388-RAJADA-HFT-1MIN";
CSymbolInfo   m_symb                          ;
CPositionInfo m_posicao                       ;
CAccountInfo  m_cta                           ;
double        m_tick_size                     ;// alteracao minima de preco.
double        m_stopLoss                      ;// stop loss;
double        m_tkprof                        ;// take profit;
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
double m_posicaoVolumePend   = 0; // volume pendente pra fechar a posicao atual
double m_posicaoVolumeTot    = 0; // volume total de contratos da posicao, inclusive os que jah foram fechados
long   m_positionId          = 0;
double m_volComprasNaPosicao = 0; // quantidade de compras na posicao atual;
double m_volVendasNaPosicao  = 0; // quantidade de vendas  na posicao atual;
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
double m_medDelta      = 0;//normalizar( m_ibb.Base(1)  ); // preco medio das bandas de bollinguer no periodo anterior
double m_inf           = 0;//normalizar( m_ibb.Lower(0) ); // preco da banda de bollinger inferior
double m_infDelta      = 0;//normalizar( m_ibb.Lower(0) ); // preco da banda de bollinger inferior
double m_sup           = 0;//normalizar( m_ibb.Upper(0) ); // preco da banda de bollinger superior
double m_supDelta      = 0;//normalizar( m_ibb.Upper(0) ); // preco da banda de bollinger superior
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

string   m_apmb       = "IN" ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_sel   = "INS"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_buy   = "INB"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_ns    = "INN"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_strRajada  = "RJ" ; //string que identifica rajadas de abertura de novas posicoes.
MqlRates m_rates[];

string   m_comment_fixo;
string   m_comment_var;

double m_razaoVolReal = 0;
double m_razaoVolTick = 0;

int    m_qtd_erros        = 0;
double m_maior_sld_do_dia = 0;
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

int    m_qtd_ticks_4_gain_ini= 0;
int    m_qtd_ticks_4_gain_raj= 0;
double m_passo_rajada        = 0;
double m_vol_lote_ini        = 0;
double m_vol_lote_raj        = 0;

// para acelerar a abertura da primeira ordem de fechamento a posicao
double m_val_close_position_sel = 0;
double m_vol_close_position_sel = 0;
double m_val_close_position_buy = 0;
double m_vol_close_position_buy = 0;

// controle de fechamento de posicoes
bool  m_fechando_posicao         = false;
ulong m_ordem_fechamento_posicao = 0;

// controle de abertura de posicoes
bool  m_abrindo_posicao            = false;
ulong m_ordem_abertura_posicao_sel = 0;
ulong m_ordem_abertura_posicao_buy = 0;

// controles de apresentacao das variaveis de debug na tela...
string m_str_linhas_acima   = "";
string m_release = "[RELEASE TESTE]";

// variaveis usadas nas estrategias de entrada, visando diminuir a quantidade de alteracoes e cancelamentos com posterior criacao de ordens de entrada.
double m_precoUltOrdemInBuy = 0;
double m_precoUltOrdemInSel = 0;

string m_symb_str;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){

    
    #ifdef COMPILE_PRODUCAO m_release = "[RELEASE PRODU]";#endif

    Print("***** Iniciando " + m_name + ":" + IntegerToString(EA08_MAGIC) + " as " + TimeToString( TimeCurrent() ) +"... ******");
    Print(":-| ", m_release);
    Print(":-| ", m_release);
    Print(":-| ", m_release);

    // definindo local da tela onde serao mostradas as variaveis de debug...
    m_str_linhas_acima   = "";
    for( uint i=0; i<EA_SHOW_TELA_LINHAS_ACIMA; i++){
       StringAdd(m_str_linhas_acima,"\n");
    }

    m_symb.Name                  ( Symbol() );
    m_symb_str         = Symbol();
    m_symb.Refresh               (); // propriedades do simbolo. Basta executar uma vez.
    m_symb.RefreshRates          (); // valores do tick. execute uma vez por tick.
    m_tick_size        = m_symb.TickSize(); //Obtem a alteracao minima de preco
    //m_qtd_ticks_4_gain = EA_QTD_TICKS_4_GAIN_L5;
    //m_shift            = m_symb.NormalizePrice(m_qtd_ticks_4_gain*m_tick_size);
    m_stopLoss         = m_symb.NormalizePrice(EA_TICKS_STOP_LOSS *m_tick_size);
    m_tkprof           = m_symb.NormalizePrice(EA_TICKS_TKPROF    *m_tick_size);
    m_trade.setMagic   (EA08_MAGIC);
    m_trade.setStopLoss(m_stopLoss);
    m_trade.setTakeProf(m_tkprof); 
    ArraySetAsSeries(m_rates,true);

    //m_spread_maximo = EA_SPREAD_MAXIMO;
    m_spread_maximo    = EA_SPREAD_MAXIMO*m_tick_size;
    //m_passo_rajada   = EA_PASSO_RAJ;

    m_maior_sld_do_dia = m_cta.Balance(); // saldo da conta no inicio da sessao;
    m_sld_sessao_atu = m_cta.Balance();
    m_capitalInicial = m_cta.Balance();

    m_comment_fixo = "LOGIN:"         + DoubleToString(m_cta.Login(),0) +
                     "  TRADEMODE:"   + m_cta.TradeModeDescription()    +
                     "  MARGINMODE:"  + m_cta.MarginModeDescription()   + 
                     " "              + m_release;
                   //"alavancagem:" + m_cta.Leverage()               + "\n" +
                   //"stopoutmode:" + m_cta.StopoutModeDescription() + "\n" +
                   //"max_ord_pend:"+ m_cta.LimitOrders()            + "\n" + // max ordens pendentes permitidas
    Comment(m_comment_fixo);

    m_trade.setVolLote ( m_symb.LotsMin() );

    // inicializando a banda de bolinguer...
    m_ibb = new CiBands();
    if ( !m_ibb.Create(_Symbol         , //string           string,        // Symbol
                       PERIOD_CURRENT  , //Period
                       BB_QTD_PERIODOS , //int              ma_period,     // Averaging period
                       0               , //int              ma_shift,      // Horizontal shift
                       BB_DESVIOS      , //double           deviation      // Desvio
                       PRICE_WEIGHTED    //int              applied        // (máximo + mínimo)/2 (see ENUM_APPLIED_PRICE)
                      )
        ){
        Print(m_name,": Erro inicializando o indicador BB :-(");
        return(1);
    }

    // inicializando CCI...
    m_icci = new CiCCI();
    if ( !m_icci.Create( _Symbol          , //string          string,        // Symbol
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
    if(  !m_feira.Create(  m_symb_str,   PERIOD_CURRENT           ,
                                         FEIRA01_DEBUG            ,
                                         FEIRA02_GERAR_VOLUME     ,
                                         FEIRA03_GERAR_OFERTAS    ,
                                         FEIRA04_QTD_BAR_PROC_HIST,
                                         FEIRA05_BOOK_OUT         ,
                                         FEIRA06_QTD_SEGUNDOS     ,
                                         FEIRA07_GERAR_SQL_LOG    ,
                                         IFEIRA_VERSAO_0307       )   ){
        Print(m_name," :-( Erro inicializando o indicador FEIRA!", GetLastError() );
        return(1);
    }

    // adicionando FEIRA ao grafico...
    if( FEIRA99_ADD_IND_2_CHART ){ m_feira.AddToChart(0,0); }
    m_feira.Refresh();


    //Print(m_name,":-| Aguardando 5 seg apos colocar o indicador feira no grafico... " );
    //Sleep (5000);

  
    EventSetMillisecondTimer(EA_QTD_SEG_TIMER);
    Print(m_name,":-| Expert ", m_name, " Criado Timer de ",EA_QTD_SEG_TIMER," milisegundos !!! " );
    Print(m_name,":-) Expert ", m_name, " inicializado !! " );
    Print(":-| ", m_release);
    Print(":-| ", m_release);
    Print(":-| ", m_release);
    
    return(0);
}

double m_len_canal_ofertas = 0; // tamanho do canal de oefertas do book.
double m_len_barra_atual   = 0; // tamanho da barra de trades atual.
double m_volatilidade      = 0; // calculamos a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
double m_volTradePorSeg    = 0; // volume de agressoes por segundo.
double m_volTradePorSegBuy = 0; // volume de agressoes de compra por segundo.
double m_volTradePorSegSel = 0; // volume de agressoes de venda  por segundo.
int    m_volTradePorSegDeltaPorc = 0; // % da diferenca do volume por segundo do vencedor. Se for positivo, o vencedor eh buy, se negativo eh sell. 
double m_desbUp0           = 0;
double m_desbUp1           = 0;

ulong m_trefreshMe        = 0;
ulong m_trefreshFeira     = 0;
ulong m_trefreshCCI       = 0;
ulong m_trefreshTela      = 0;
ulong m_trefreshRates     = 0;
ulong m_tcontarTransacoes = 0;
ulong m_tcloseRajada      = 0;

bool m_estou_posicionado = false;
void refreshMe(){
    
    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshMe    = GetMicrosecondCount(); #endif
    m_posicao.Select( m_symb_str );
    
    
    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshRates = GetMicrosecondCount(); #endif
    m_symb.RefreshRates();
    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshRates = GetMicrosecondCount()-m_trefreshRates; #endif
    
    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshFeira = GetMicrosecondCount(); #endif
    m_feira.Refresh();
    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshFeira = GetMicrosecondCount()-m_trefreshFeira; #endif

      m_ibb.Refresh (-1);
    //m_ima.Refresh (-1);
    
    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshCCI = GetMicrosecondCount();#endif
    //m_icci.Refresh(-1);
    #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshCCI = GetMicrosecondCount()-m_trefreshCCI;#endif
    
    //m_iad.Refresh (-1);
    //m_imfi.Refresh(-1);


    m_trade.setStopLoss( m_stopLoss       );
    m_trade.setTakeProf( m_tkprof         );
    m_trade.setVolLote ( m_symb.LotsMin() );

    m_ask     = m_symb.Ask();
    m_bid     = m_symb.Bid();
    m_desbUp0 = m_feira.getDesbUP0(0);
    m_desbUp1 = m_feira.getDesbUP1(0);


    // atualizando maximo, min e tamnaho das barras anterior de preco atual e anterior...
    CopyRates(m_symb_str,_Period,0,2,m_rates);
    m_max_barra_anterior = m_rates[1].high;
    m_min_barra_anterior = m_rates[1].low ;

    m_med      =       m_ibb.Base (0);//normalizar( m_ibb.Base(0)  ); // preco medio das bandas de bollinguer
    m_medDelta = m_med-m_ibb.Base (1);//normalizar( m_ibb.Base(0)  ); // preco medio das bandas de bollinguer
    m_inf      =       m_ibb.Lower(0);//normalizar( m_ibb.Lower(0) ); // preco  da banda de bollinger inferior
    m_infDelta = m_inf-m_ibb.Lower(1);//normalizar( m_ibb.Lower(0) ); // desvio da banda de bollinger inferior. Se negativo, o angulo eh pra baixo.
    m_sup      =       m_ibb.Upper(0);//normalizar( m_ibb.Upper(0) ); // preco  da banda de bollinger superior
    m_supDelta = m_sup-m_ibb.Upper(1);//normalizar( m_ibb.Upper(0) ); // desvio da banda de bollinger superior. Se positivo, o angulo eh pra cima.
    m_bdx      = MathAbs( m_sup-m_med    ); // distancia entre as bandas de bollinger e a media, sem sinal;
    m_dx1      = EA10_DX1*m_bdx; //normalizar( EA10_DX1*m_bdx); // normalmente 20% da distancia entre a media e uma das bandas.

    m_qtdOrdens           = OrdersTotal();
    m_qtdPosicoes         = PositionsTotal();
    //m_volComprasNaPosicao = 0;
    //m_volVendasNaPosicao  = 0;


    // adminstrando posicao aberta...
    if( m_qtdPosicoes > 0 ){
        
      //m_posicaoProfit = 0;
        if ( PositionSelect  (m_symb_str) ){ // soh funciona em contas hedge
      //if ( m_posicao.Select(m_symb.Name()) ){ // soh funciona em contas hedge

            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                setCompradoSoft();
            }else{
                setVendidoSoft();
            }
            
            
            // primeiro refresh apos abertura da posicao...
            if( !m_estou_posicionado && !m_fechando_posicao ){
            
                //<TODO> chame o closerajada aqui para que nao seja atrasado pelo cancelamento de ordens apmb.
                //doCloseRajada(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_ini);
            
                // se tem posicao aberta, cancelamos as ordens apmb que porventura tenham ficado abertas
                m_trade.cancelarOrdensComentadas(m_apmb);//<TODO: DESCOMENTE e transforme em parametro>
                m_estou_posicionado = true;
                
                // <TODO>: se estah fechando posicao, verifique se ha uma ordem stop dentro da posicao. se tiver, desmarque a flag de fechamento da posicao...
                //if( m_fechando_posicao == true ){
                //    if(EA_DEBUG)Print( __FUNCTION__,":-| Cancelando status de fechamento de posicao, pois nao ha posicao aberta! ticket da ordem de fechamento=", m_ordem_fechamento_posicao );
                //    m_fechando_posicao         = false;
                //    m_ordem_fechamento_posicao = 0;
                //}
                
                // deu ruim...
                //if( m_fechando_posicao ){
                //    #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print( __FUNCTION__,":-| Cancelando status de fechamento de posicao, pois nao ha posicao aberta! ticket da ordem de fechamento=", m_ordem_fechamento_posicao );#endif
                //    m_fechando_posicao         = false;
                //    m_ordem_fechamento_posicao = 0;
                //}
            }
            
            m_posicaoProfit          = PositionGetDouble (POSITION_PROFIT     );
            m_precoPosicao           = PositionGetDouble (POSITION_PRICE_OPEN ); // este eh o valor medio de abertura da posicao.
            if(m_val_order_4_gain==0) m_val_order_4_gain = m_precoPosicao;       // este eh o valor de fato de abertura da posicao.
            
            m_posicaoVolumePend      = PositionGetDouble (POSITION_VOLUME     );
            m_positionId             = PositionGetInteger(POSITION_IDENTIFIER );
            m_positionCommentStr     = PositionGetString (POSITION_COMMENT    );
            m_positionCommentNumeric = StringToInteger   (m_positionCommentStr);
            m_capitalLiquido         = m_cta.Equity();
            m_lucroPosicao           = m_capitalLiquido - m_capitalInicial;

            // se o comentario da posicao for numerico, precisamos saber pois trata-se de um engano e deveremos fechar a posicao e todas as ordens.
            //if( !MathIsValidNumber(m_positionCommentNumeric) ) m_positionCommentNumeric = 0;

            //m_tcontarTransacoes = GetMicrosecondCount();
            //contarTransacoesDaPosicao();
            //m_tcontarTransacoes = GetMicrosecondCount()-m_tcontarTransacoes;

            if( estouComprado() ) m_posicaoVolumeTot = m_volComprasNaPosicao;
            if( estouVendido () ) m_posicaoVolumeTot = m_volVendasNaPosicao ;
            m_lucroPosicao4Gain = (m_posicaoVolumeTot*EA_STOP_PORC_L1);

            //<TODO> passar este tratamento para o OnTimer
            //if( m_tempo_posicao_ini == 0 ) m_tempo_posicao_ini = TimeCurrent();
            //m_tempo_posicao_atu = TimeCurrent() - m_tempo_posicao_ini;

            if( m_abrindo_posicao ){
                #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print(__FUNCTION__, ":-| Cancelando status de abertura de posicao, pois ha posicao aberta! tktSell=", m_ordem_abertura_posicao_sel, " tktBuy=", m_ordem_abertura_posicao_buy ); #endif
                m_abrindo_posicao            = false;
                m_ordem_abertura_posicao_sel = 0;
                m_ordem_abertura_posicao_buy = 0;
            }
            
            // variaveis usadas para diminuir a quantidade de alteracoes e cancelamentos com posterior criacao de ordens de entrada.
            m_precoUltOrdemInBuy = 0;
            m_precoUltOrdemInSel = 0;

        }else{
        
           // aqui neste bloco, estah garantido que nao ha posicao aberta...
           m_qtdPosicoes       = 0;
           m_capitalInicial    = m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
           m_comprado          = false;
           m_vendido           = false;
           m_estou_posicionado = false;
           m_lucroPosicao      = 0;
           m_lucroPosicao4Gain = 0;
           m_posicaoVolumePend = 0; //versao 02-085
           m_posicaoProfit     = 0;
           m_posicaoVolumeTot  = 0;
           m_val_order_4_gain  = 0; // zerando o valor da primeira ordem da posicao...
           m_tempo_posicao_atu = 0;
           m_tempo_posicao_ini = 0;
        }

        if( m_fechando_posicao && m_qtdOrdens == 0){
            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print( __FUNCTION__,":-| Cancelando status de fechamento de posicao, pois nao ha posicao aberta! ticket da ordem de fechamento=", m_ordem_fechamento_posicao );#endif
            m_fechando_posicao         = false;
            m_ordem_fechamento_posicao = 0;
        }

    }else{
        // aqui neste bloco, estah garantido que nao ha posicao aberta...
        m_capitalInicial  = m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
        m_comprado          = false;
        m_vendido           = false;
        m_estou_posicionado = false;
        m_lucroPosicao      = 0;
        m_lucroPosicao4Gain = 0;
        m_posicaoVolumePend = 0; //versao 02-085
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

        if( m_fechando_posicao && m_qtdOrdens==0){
            if(EA_DEBUG)Print( __FUNCTION__,":-| Cancelando status de fechamento de posicao, pois nao ha posicao aberta! ticket da ordem de fechamento=", m_ordem_fechamento_posicao );
            m_fechando_posicao         = false;
            m_ordem_fechamento_posicao = 0;
        }
    }

   //-- precos medios do book
   m_pmBid =  m_feira.getPrecoMedioBid(0);
   m_pmAsk =  m_feira.getPrecoMedioAsk(0);
   m_pmBok =  m_feira.getPrecoMedioBok(0);
   m_pmSel =  m_feira.getPrecoMedioSel(0);
   m_pmBuy =  m_feira.getPrecoMedioBuy(0);
   m_pmTra =  m_feira.getPrecoMedioTra(0);

   // canal de ofertas no book...
   m_len_canal_ofertas = m_pmAsk - m_pmBid;

   //-- precos no periodo
   m_phigh           = m_feira.getPrecoHigh(0);
   m_plow            = m_feira.getPrecoLow(0);
   m_len_barra_atual = m_phigh - m_plow;

   // calculamos a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
   if( m_len_canal_ofertas > 0 ) m_volatilidade = m_len_barra_atual / m_len_canal_ofertas;

   // ticks por segundo. medida de volatilidade e da forca das agressoes de compra evenda...
   m_volTradePorSeg          = m_feira.getVolTrade   (0)/FEIRA06_QTD_SEGUNDOS; 
   m_volTradePorSegBuy       = m_feira.getVolTradeBuy(0)/FEIRA06_QTD_SEGUNDOS; 
   m_volTradePorSegSel       = m_feira.getVolTradeSel(0)/FEIRA06_QTD_SEGUNDOS; 
   m_volTradePorSegDeltaPorc = m_volTradePorSeg==0?0:((m_volTradePorSegBuy - m_volTradePorSegSel)/m_volTradePorSeg)*100;

   // aceleracoes de volume
   //double m_aceVolTradePorSeg = 0;
   //m_aceVolTradePorSeg = m_volTradePorSeg - m_feira.getVolTrade(1)/FEIRA06_QTD_SEGUNDOS

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

   //-- diminuindo ou aumentando a quantidade de ticks para o ganho, o volume dos lotes e o passo das rajadas, em funcao da volatilidade.
   //-- Esperase que a quantidade de ticks para o gain seja maior com o aumento da volatilidade e
   //-- o volume seja maior quando a volatilidade for menor.
   //--
   if(       taxaVolumeEstahL1() ){
       m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI_L1;
       m_qtd_ticks_4_gain_raj = EA_QTD_TICKS_4_GAIN_RAJ_L1;
       m_vol_lote_raj     = EA_VOL_LOTE_RAJ_L1;
       m_vol_lote_ini     = EA_VOL_LOTE_INI_L1;
       m_passo_rajada     = EA_PASSO_RAJ_L1;

   }else if (taxaVolumeEstahL2() ){
       m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI_L2;
       m_qtd_ticks_4_gain_raj = EA_QTD_TICKS_4_GAIN_RAJ_L2;
       m_vol_lote_raj     = EA_VOL_LOTE_RAJ_L2;
       m_vol_lote_ini     = EA_VOL_LOTE_INI_L2;
       m_passo_rajada     = EA_PASSO_RAJ_L2;
   }else if (taxaVolumeEstahL3() ){
       m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI_L3;
       m_qtd_ticks_4_gain_raj = EA_QTD_TICKS_4_GAIN_RAJ_L3;
       m_vol_lote_raj     = EA_VOL_LOTE_RAJ_L3;
       m_vol_lote_ini     = EA_VOL_LOTE_INI_L3;
       m_passo_rajada     = EA_PASSO_RAJ_L3;
   }else if (taxaVolumeEstahL4() ){
       m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI_L4;
       m_qtd_ticks_4_gain_raj = EA_QTD_TICKS_4_GAIN_RAJ_L4;
       m_vol_lote_raj     = EA_VOL_LOTE_RAJ_L4;
       m_vol_lote_ini     = EA_VOL_LOTE_INI_L4;
       m_passo_rajada     = EA_PASSO_RAJ_L4;
   }else if (taxaVolumeEstahL5() ){
       m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI_L5;
       m_qtd_ticks_4_gain_raj = EA_QTD_TICKS_4_GAIN_RAJ_L5;
       m_vol_lote_raj     = EA_VOL_LOTE_RAJ_L5;
       m_vol_lote_ini     = EA_VOL_LOTE_INI_L5;
       m_passo_rajada     = EA_PASSO_RAJ_L5;
   }else{
       m_qtd_ticks_4_gain_ini = EA_QTD_TICKS_4_GAIN_INI_ALTO;
       m_qtd_ticks_4_gain_raj = EA_QTD_TICKS_4_GAIN_RAJ_ALTO;
       m_vol_lote_raj     = EA_VOL_LOTE_RAJ_ALTO;
       m_vol_lote_ini     = EA_VOL_LOTE_INI_ALTO;
       m_passo_rajada     = EA_PASSO_RAJ_ALTO;
   }

   m_sld_sessao_atu = m_cta.Balance();
   
      
   if (EA_SHOW_TELA){
       #ifndef COMPILE_PRODUCAO if( EA_DEBUG ) m_trefreshTela = GetMicrosecondCount(); #endif
       m_comment_var = " FECHANDO_POSICAO:" + m_fechando_posicao + " [POSICIONADO:"  + m_estou_posicionado + "] " +(m_qtdPosicoes==0?"SEM POSICAO":estouComprado()?"COMPRADO":"VENDIDO") +
                          m_str_linhas_acima +
                       " CTA SLD:"      + DoubleToString(m_cta.Balance()    ,2      ) +
                       " CAPLIQ: "      + DoubleToString(m_cta.Equity()     ,2      ) +
                       " VAL_GAIN:"     + DoubleToString(m_val_order_4_gain ,_Digits) +
                                            
                      "\n" + "[POSICIONADO:"  + m_estou_posicionado + "] " +(m_qtdPosicoes==0?"SEM POSICAO":estouComprado()?"COMPRADO":"VENDIDO") +
                       
                       " m_posicaoProfit: " + DoubleToString(m_posicaoProfit,2)+
                       " PROFIT:"           + DoubleToString(m_cta.Profit(),2) +
                       

                       "\nQTD_OFERTAS: "   + IntegerToString(m_symb.SessionDeals()        )+
                       "  OPEN:"           + DoubleToString (m_symb.SessionOpen (),_Digits)+
                       "  VWAP:"           + DoubleToString (m_symb.SessionAW   (),_Digits)+
                       "  DATA:"           + TimeToString   (TimeCurrent()                )+
                       "  MIN:"            + TimeToString   (TimeCurrent(),TIME_MINUTES   )+
                       "  SEG:"            + TimeToString   (TimeCurrent(),TIME_SECONDS   )+
                       "  TEMPO_POSICAO:"  + IntegerToString(m_tempo_posicao_atu)          +
                       "  VOLTOT: "        + DoubleToString (m_feira.getVolTrade(0),2)     +

                       //"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"+
                       //"\n\n\n\n\n\n\n\n\n\n"+

                       //"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"+
                //       "\nABRIR_POSICAO:"    +                EA07_ABRIR_POSICAO             +
                //       "  MAX_VOL_EM_RISCO:" + DoubleToString(EA01_MAX_VOL_EM_RISCO,_Digits) +
                //       "  MAX_REBAIX_SLD:"   + DoubleToString(EA_REBAIXAMENTO_MAX  ,0      ) +
                //       "  TICKS_STOP_LOSS:"  + DoubleToString(EA_TICKS_STOP_LOSS ,0      ) +
                //       "  TICK_SIZE:"        + DoubleToString(m_symb.TickSize() ,_Digits     ) +
                //       "  TICK_VALUE:"       + DoubleToString(m_symb.TickValue(),_Digits     ) +
                //       "  POINT:"            + DoubleToString(m_symb.Point()    ,_Digits     ) +

                       "\n\nPRFT/4GAIN/LOSS: " + DoubleToString(m_lucroPosicao     ,0      ) +"/"+
                                                 DoubleToString(m_lucroPosicao4Gain,0      ) +"/"+
                                                 DoubleToString(EA07_STOP_LOSS     ,_Digits) +
                       " V PEN/TOT: "          + DoubleToString(m_posicaoVolumePend,_Digits) + "/"+
                                                 DoubleToString(m_posicaoVolumeTot ,_Digits) +
                       " RSLD ATU/MAX/MSD: "   + DoubleToString(m_rebaixamento_atu,2) + "/" +
                                                 DoubleToString(EA_REBAIXAMENTO_MAX,0 ) + "/" +
                                                 DoubleToString(m_maior_sld_do_dia, 2)+
                       "\nposPft/ctaPft: "     + DoubleToString(m_posicaoProfit,2)+ "/" +
                                                 DoubleToString(m_cta.Profit(),2) +
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

                       "\nVSEG/BUY/SEL/ALTO/MAX:" + DoubleToString (m_volTradePorSeg   ,0           ) + "/" + 
                                                    DoubleToString (m_volTradePorSegBuy,0           ) + "/" + 
                                                    DoubleToString (m_volTradePorSegSel,0           ) + "/" + 
                                                    IntegerToString(EA_VOLSEG_ALTO                  ) + "/" +
                                                    IntegerToString(EA_VOLSEG_MAX_ENTRADA_POSIC     ) +
                       //
                       //" DBOK:"              + DoubleToString (m_desbUp0*100,0) +
                       " VOLAT/MAX:" + DoubleToString(m_volatilidade        ,2           ) + "/" + DoubleToString (EA_VOLAT_ALTA ,2) +
                       " SPREAD/MAX:"+ DoubleToString(m_symb.Spread()       ,_Digits     ) +
                       "/"           + DoubleToString(m_spread_maximo       ,_Digits     ) +
                       "  INCLI/MAX:"+ DoubleToString(m_inclTra             ,2           ) + "/" + DoubleToString(EA_INCL_ALTA   ,2) +
                       //" CCI ANT/ATU/DIF: " + DoubleToString(m_icci.Main(1),2)+"/"+
                       //                       DoubleToString(m_icci.Main(0),2)+"/"+
                       //                       DoubleToString((m_icci.Main(0)-m_icci.Main(1)),2)+
                       //
                       //
                       "\n" + "DELTAVEL/ACED:"+IntegerToString(m_volTradePorSegDeltaPorc    ) +"/"+
                                               IntegerToString(m_acelVolTradePorSegDeltaPorc) +   strPosicao();



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
       #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_trefreshTela = GetMicrosecondCount()-m_trefreshTela;#endif
   }
   
   #ifndef COMPILE_PRODUCAO 
       if(EA_DEBUG){
           m_trefreshMe = GetMicrosecondCount()-m_trefreshMe;   
    
           if( m_qtd_print_debug++ % 10 == 0 ){
               Print(":-| DEBUG_TIMER:"                       ,
                     " m_tcloseRajada="     ,m_tcloseRajada   ,
                     " m_trefreshMe="       ,m_trefreshMe     ,
                     " m_trefreshFeira="    ,m_trefreshFeira  ,
                   //" m_trefreshCCI="      ,m_trefreshCCI    ,
                     " m_trefreshTela="     ,m_trefreshTela   ,
                     " m_trefreshRates="    ,m_trefreshRates  );
                   //" m_tcontarTransacoes=",m_tcontarTransacoes 
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
int m_qtd_print_debug = 0;

/*
//
// conta as transacoes da posicao atual; Estas transacoes ficam atualizadas
// nas variaveis m_volComprasNaPosicao e m_volVendasNaPosicao;
//
void contarTransacoesDaPosicao(){
   HistorySelectByPosition(m_positionId)     ; // recuperando ordens e transacoes da posicao atual no historico...
   int            deals = HistoryDealsTotal(); // quantidade de ordens na posicao
   ulong          deal_ticket;
   ENUM_DEAL_TYPE deal_type;
   double         deal_vol; // versao 02-086

   m_volComprasNaPosicao = 0;
   m_volVendasNaPosicao  = 0;

   for(int i=0;i<deals;i++) {  // selecionando as transacoes (entradas e saidas) para processamento...

      deal_ticket =                 HistoryDealGetTicket (i);
      deal_type   = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket,DEAL_TYPE);
      deal_vol    =                 HistoryDealGetDouble (deal_ticket,DEAL_VOLUME);

      switch(deal_type){
         case DEAL_TYPE_SELL: m_volVendasNaPosicao  += deal_vol; break;
         case DEAL_TYPE_BUY : m_volComprasNaPosicao += deal_vol; break;
      }
   }
}
*/
void fecharTudo(string descr){ fecharTudo(descr,""); }

void fecharTudo(string descr, string strLog){
      // se tem posicao ou ordem aberta, fecha, exceto as stops.
      if( m_qtdOrdens > 0 ){
          #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| HFT_FECHAR_TUDO_ORDENS: ", strLog, strPosicao()); #endif
          m_val_close_position_sel = 0;
          m_vol_close_position_sel = 0;
          m_val_close_position_buy = 0;
          m_vol_close_position_buy = 0;
          m_trade.cancelarOrdensExcetoComTxt("STOP",descr);
      }

      if( m_qtdPosicoes > 0 ){
          m_fechando_posicao = true;
          #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| HFT_FECHAR_TUDO_POSICAO: ", strLog, strPosicao()); #endif
          m_ordem_fechamento_posicao = m_trade.fecharPosicaoCtaNetting(_Symbol,descr);
          if( m_ordem_fechamento_posicao <= 0){
             m_fechando_posicao = false;
          }
          Sleep(500); // tentativa de remediar fechamentos de posicao duplicados...
      }
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
    refreshMe();

    // Esta opcao NAO_OPERAR nao interfere nas ordens...
    if( EA07_ABRIR_POSICAO == NAO_OPERAR ) return;

    //if(m_fechando_posicao){
    //   fecharTudo("FECHANDO_POSICAO");
    //   return;
    //}

    if ( m_qtdPosicoes > 0 ) {

         if(m_fechando_posicao){ fecharTudo("STOP_FECHANDO_POSIC"); return; }

         // abrindo ordens pra fechar a posicao...
         doCloseRajada(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_raj );

         // se controlarRiscoDaPosicao() retornar true, significa que acionou um stop, entao retornamos daqui.
         if( controlarRiscoDaPosicao() ){ return; }

         if( emLeilao() )return;
         doOpenRajada (m_passo_rajada, EA01_MAX_VOL_EM_RISCO, m_vol_lote_raj , m_qtd_ticks_4_gain_raj); // abrindo rajada...
         //doCloseRajada(EA_PASSO_RAJ, EA05_VOLUME_LOTE_RAJ , m_qtd_ticks_4_gain, false            ); // acionando saida rapida...
    }else{

        if( m_qtdOrdens > 0 ){
           if( m_acionou_stop_rebaixamento_saldo             ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return;}

           // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
           if( EA07_ABRIR_POSICAO == FECHAR_POSICAO          ){ fecharTudo("OPCAO_FECHAR_POSICAO"         , "OPCAO_FECHAR_POSICAO"         ); return; }
           if( EA07_ABRIR_POSICAO == FECHAR_POSICAO_POSITIVA ){ fecharTudo("OPCAO_FECHAR_POSICAO_POSITIVA", "OPCAO_FECHAR_POSICAO_POSITIVA"); return; }

           // cancela as ordens existentes e nao abre novas ordens se o spread for maior que maximo.
           if( m_symb.Spread() > m_spread_maximo             ){ fecharTudo("SPREAD_ALTO", "SPREAD_ALTO"); return; }

           // cancelando todas as ordens que nao sejam de abertura de posicao...
           m_trade.cancelarOrdensExcetoComTxt(m_apmb,"CANC_NOT_APMB");

           //apmb(nunca fechar), vazio(nunca fechar), numero(sempre fechar, pois soh pode ter ordem com comentario numerico se tiver posicao aberta)...
           //m_trade.cancelarOrdensComComentarioNumerico(_Symbol); // sao as ordens de fechamento de rajada.

           // se tiver ordens RAJADA sem posicao aberta fecha elas...
           //m_trade.cancelarOrdensComentadas(m_strRajada);

           // Parada apos os cancelamentos visando evitar atropelos...
           //Sleep(SLEEP_PADRAO);

           // se tiver ordem sem stop, coloca agora...
           //m_trade.colocarStopEmTodasAsOrdens(m_stopLoss);
        }

        // nao abrir posicao se o indicador feira estiver com problemas...
        //if( m_pmTra == 0 ){
        //    m_qtd_erros++;
        //    if(m_qtd_erros>1000){
        //        Print(":-( MEDIA_TRADE ",DoubleToString(m_pmTra,2),". Indicador feira com preco medio do trade zerado... VERIFIQUE!", strPosicao());
        //        m_qtd_erros=0;
        //    }
        //}

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
        }

        // saldo da conta subiu, atualizamos o saldo da sessao pra controle do rebaixamento maximo do dia.
        if( m_sld_sessao_atu > m_maior_sld_do_dia ){
            m_maior_sld_do_dia = m_sld_sessao_atu;
            m_rebaixamento_atu = 0;
        }else{
            m_rebaixamento_atu = m_maior_sld_do_dia - m_sld_sessao_atu; // se houver rebaixamento, esse numero fica positivo;
        }

        // saldo da conta rebaixou mais que o permitido pra sessao.
        if ( m_rebaixamento_atu  != 0  &&
             EA_REBAIXAMENTO_MAX != 0  &&
             EA_REBAIXAMENTO_MAX  < m_rebaixamento_atu ){

             if( !m_acionou_stop_rebaixamento_saldo ){ // eh pra nao fical escrevendo no log ateh a sessao seguinte caso rebaixe o saldo.
                  Print(":-( Acionando STOP_REBAIXAMENTO_DE_CAPITAL. ", strPosicao() );
                  fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL");
                  m_acionou_stop_rebaixamento_saldo = true;
             }
             return;
        }
        /////////////////////////////////////////////////////////////////////////////////////
        
        // verificando proibicoes de operar
        if(  m_fechando_posicao             ||
             volatilidadeEstahAlta()        ||
            !taxaVolPermiteAbrirPosicao()   ||
            emLeilao()                      || //<TODO> voltar e descomentar
            spreadMaiorQueMaximoPermitido() ){ 
            m_trade.cancelarOrdensExcetoComTxt("STOP","NAO_PODE_ABRIR_POSICAO"); 
            m_val_close_position_sel = 0;
            m_vol_close_position_sel = 0;
            m_val_close_position_buy = 0;
            m_vol_close_position_buy = 0;
            return;
        }

        switch(EA07_ABRIR_POSICAO){
          case CONTRA_TEND_DURANTE_COMPROMETIMENTO : abrirPosicaoDuranteComprometimentoInstitucional(); break;
          case CONTRA_TEND_APOS_COMPROMETIMENTO    : abrirPosicaoAposComprometimentoInstitucional   (); break;
          case CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR: abrirPosicaoAposMaxMinBarraAnterior            (); break;
          case HFT_DISTANCIA_PRECO                 : abrirPosicaoHFTdistanciaDoPreco                (); break;
          case HFT_MAX_MIN_VOLAT                   : abrirPosMaxMinVolatContraTend                  (); break;
          case HFT_TEND_CCI                        : abrirPosicaoCCINaTendencia                     (); break;
          case HFT_NA_TENDENCIA                    : abrirPosicaoHFTnaTendencia                     (); break;
          case HFT_NORTE_SUL                       : abrirPosicaoHFTnorteSul                        (); break;
          case HFT_DESBALANC_BOOK                  : abrirPosicaoHFTDesbalancBook                   (); break;
          case HFT_DESBALANC_BOOKNS                : abrirPosicaoHFTDesbalancBookNorteSul           (); break;
          case HFT_MEDIA_TRADE                     : abrirPosicaoHFTNaMediaTrade                    (); break;
          case HFT_ARBITRAGEM_VOLUME               : abrirPosicaoArbitragemVolume                   (); break;
        //case NAO_ABRIR_POSICAO                   :                                                    break;
        }
        return;
    }
    return;

}//+------------------------------------------------------------------+


bool controlarRiscoDaPosicao(){
     if( m_acionou_stop_rebaixamento_saldo ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return true;}

     // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
     if( EA07_ABRIR_POSICAO == FECHAR_POSICAO                                 ) { fecharTudo("STOP_FECHAR_POSICAO"         ,"STOP_FECHAR_POSICAO"         ); return true; }
     if( EA07_ABRIR_POSICAO == FECHAR_POSICAO_POSITIVA && m_posicaoProfit > 0 ) { fecharTudo("STOP_FECHAR_POSICAO_POSITIVA","STOP_FECHAR_POSICAO_POSITIVA"); return true; }


     // se tem posicao aberta, cancelamos as ordens apmb que porventura tenham ficado abertas
     // comentado aqui e colocado dentro de refreshme para que execute uma unica vez apos a abertura de cada posicao.
     //m_trade.cancelarOrdensComentadas(m_apmb);//<TODO: DESCOMENTE e transforme em parametro>

     if( m_lucroPosicao  < EA07_STOP_LOSS && m_capitalInicial != 0 ){
         #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print(":-( Acionando STOP_LOSS. ", strPosicao() ); #endif
         fecharTudo("STOP_LOSS_" + DoubleToString(m_lucroPosicao,0) );
         return true;
     }
     //+----------------------------------------------------------------------------------------
     //+ Controle de STOPs em funcao das quantidades totais e pendentes de contratos na posicao.
     //+----------------------------------------------------------------------------------------
     if( m_capitalInicial   != 0                   && // deixe isso aqui, senao dah merda na inicializacao, hehe
         m_posicaoVolumeTot  > EA_STOP_QTD_CONTRAT &&
         m_posicaoVolumePend > 0                    ){
         
             // stop se a porcentagem de contratos pendentes for muito alta em relacao a quantidade de contratos totais.
             if( m_posicaoVolumePend/m_posicaoVolumeTot > EA_STOP_PORC_CONTRAT && EA_STOP_PORC_CONTRAT > 0){
                 #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print(":-( Acionando STOP_QTD_PORC_CONTRATOS.", strPosicao() ); #endif
                 m_lucroStops += m_lucroPosicao;
                 fecharTudo("STOP_QTD_%_CONTRATOS");
                 return true;
             }

             
             //+----------------------------------------------------------------------------------------------------
             //+ CONTROLE DOS STOP LOSS INTERMEDIARIOS
             //+----------------------------------------------------------------------------------------------------
             // 2. LOSS: se a quantidade de contratos pendentes estah maior que 2x o inicio do stop, fecha posicao se o loss eh maior que EA_STOP_L2;
             if( m_posicaoVolumePend >= EA_STOP_QTD_CONTRAT*2 &&
                 m_posicaoVolumePend <  EA_STOP_QTD_CONTRAT*3 &&
                 m_lucroPosicao      > EA_STOP_L2               ){ 
                 Print(":-| Acionando STOP_LO_L2.", strPosicao() );
                 m_lucroStops += m_lucroPosicao;
                 fecharTudo("STOP_LO_L2_" + DoubleToString(m_lucroPosicao,0));
                 return true;
             }
             // 3. LOSS: se a quantidade de contratos pendentes estah maior que 3x o inicio do stop, fecha posicao se o loss eh maior que EA_STOP_L3;
             if( m_posicaoVolumePend >= EA_STOP_QTD_CONTRAT*3 &&
                 m_posicaoVolumePend <  EA_STOP_QTD_CONTRAT*4 &&
                 m_lucroPosicao      >  EA_STOP_L3               ){
                 Print(":-( Acionando STOP_LO_LEVEL3.", strPosicao() );
                 m_lucroStops += m_lucroPosicao;
                 fecharTudo("STOP_LO_L3_" + DoubleToString(m_lucroPosicao,0) );
                 return true;
             }
             // 4. LOSS: se a quantidade de contratos pendentes estah maior que 4x o inicio do stop, fecha posicao se o loss eh maior que EA_STOP_L4;
             if( m_posicaoVolumePend >  EA_STOP_QTD_CONTRAT*4 &&
                 m_lucroPosicao      >  EA_STOP_L4               ){
                 Print(":-( Acionando STOP_LOSS_LEVEL4.", strPosicao() );
                 m_lucroStops += m_lucroPosicao;
                 fecharTudo("STOP_LO_L4_"+ DoubleToString(m_lucroPosicao,0) );
                 return true;
             }
             //+----------------------------------------------------------------------------------------------------


             //+----------------------------------------------------------------------------------------------------
             //+ CONTROLE DOS STOP GAIN INTERMEDIARIOS
             //+----------------------------------------------------------------------------------------------------
             // 1.1 GAIN: quantidade de contratos totais eh maior que 1x o inicio do controle de stops, aplica a % do gain informada em STOP_PORC_L1;
             if( m_lucroPosicao > m_lucroPosicao4Gain     ){ // (m_posicaoVolumeTot*EA_STOP_PORC_L1) (v1))
                 Print(":-| Acionando STOP_GAIN_L1.", strPosicao() );
                 m_lucroStops += m_lucroPosicao;
                 fecharTudo("STOP_GA_L1_" + DoubleToString(m_lucroPosicao,0) );
                 return true;
             }
             // 2.1 GAIN: se a quantidade de contratos totais estah maior que 2x o inicio do controle de stops, abate 25% do gain L1;
             if( m_posicaoVolumeTot >= EA_STOP_QTD_CONTRAT*2 &&
                 m_posicaoVolumeTot <  EA_STOP_QTD_CONTRAT*3 &&
                 m_lucroPosicao     > m_lucroPosicao4Gain*0.75 ){                   
                 Print(":-| Acionando STOP_GA_L2.", strPosicao() );
                 m_lucroStops += m_lucroPosicao;
                 fecharTudo("STOP_GA_L2_" + DoubleToString(m_lucroPosicao,0));
                 return true;
             }
             // 3.1 GAIN: se a quantidade de contratos totais estah maior que 3x o inicio do stop gain, abate 50% do gain L1;
             if( m_posicaoVolumeTot >= EA_STOP_QTD_CONTRAT*3 &&
                 m_posicaoVolumeTot <  EA_STOP_QTD_CONTRAT*4 &&
                 m_lucroPosicao     > m_lucroPosicao4Gain*0.5  ){
                 Print(":-| Acionando STOP_GA_L3.", strPosicao() );
                 m_lucroStops += m_lucroPosicao;
                 fecharTudo("STOP_GA_L3_" + DoubleToString(m_lucroPosicao,0)); 
                 return true;
             }
             // 4.1 GAIN: se a quantidade de contratos totais estah maior que 4x o inicio do stop gain, abate 75% do gain L1;
             if( m_posicaoVolumeTot >= EA_STOP_QTD_CONTRAT*4 &&
                 m_posicaoVolumeTot <  EA_STOP_QTD_CONTRAT*5 &&
                 m_lucroPosicao     > m_lucroPosicao4Gain*0.25 ){        
                 Print(":-| Acionando STOP_GA_L4.", strPosicao() );
                 m_lucroStops += m_lucroPosicao;
                 fecharTudo("STOP_GA_L4_" + DoubleToString(m_lucroPosicao,0)); //abrindo mao de 50% do gain L1...
                 return true;
             }
             // 5.1 GAIN: se a quantidade de contratos totais estah maior que 5x o inicio do stop gain, abate 100% do gain L1;
             if( m_posicaoVolumeTot > EA_STOP_QTD_CONTRAT*5 &&
                 m_lucroPosicao     > 0                    ){
                 Print(":-| Acionando STOP_GA_L5.", strPosicao() );
                 m_lucroStops += m_lucroPosicao;
                 fecharTudo("STOP_GA_L5_" + DoubleToString(m_lucroPosicao,0)); //abrindo mao do gain L1...
                 return true;
             }
             //+----------------------------------------------------------------------------------------------------
     } // FIM DO CONTROLE DE STOPS

     // fecha a posicao ativa a mais de 10 min
     if( m_tempo_posicao_atu > EA_10MINUTOS && EA_10MINUTOS > 0 ){
         Print(":-( Acionando STOP_LOSS_TEMPO_ALTO. T=",m_tempo_posicao_atu," ", strPosicao() );
         m_lucroStops += m_lucroPosicao;
         fecharTudo("STOP_LO_TEMPO_ALTO");
         return true;
     }

     // testando...
     //if( taxaVolumeEstahAlta() ){
     //    fecharTudo("STOP_TAXA_VOLUME_ALTA","STOP_TAXA_VOLUME_ALTA"); return;
     //}
     return false;
}

bool spreadMaiorQueMaximoPermitido(){ return m_symb.Spread() > m_spread_maximo; }

bool movimentoEmDirecaoDesfavoravel(){
   return ( ( estouComprado() &&  m_icci.Main(0) < m_icci.Main(1) ) ||
            ( estouVendido () &&  m_icci.Main(0) > m_icci.Main(1) )  );
   //return ( estouComprado() && m_inclTra < -EA_INCL_MIN && m_icci.Main(0) < m_icci.Main(1) ||
   //         estouVendido () && m_inclTra >  EA_INCL_MIN && m_icci.Main(0) > m_icci.Main(1)   );
}


string strPosicao(){
   return " Contr="       + DoubleToString (m_posicaoVolumePend,0)+ "/"+
                            DoubleToString (m_posicaoVolumeTot ,0)+
          " SPRE= "       + DoubleToString (m_symb.Spread()    ,2)+
          " VSBUY/SEL="   + DoubleToString (m_volTradePorSegBuy,0)+ "/" + DoubleToString(m_volTradePorSegSel,0)+
          " Incl="        + DoubleToString (m_inclTra          ,2)+
          " PUP0/1="      + DoubleToString (m_desbUp0*100      ,0)+ "/" + DoubleToString(m_desbUp0*100,0)+
        //" CCI[DIF]="  + DoubleToString ( ( m_icci.Main(0)-m_icci.Main(1) )  ,2)+
          " LUCRP="     + DoubleToString (m_lucroPosicao     ,2)+
          " T4GI="       + IntegerToString(m_qtd_ticks_4_gain_ini   )+
          " T4GR="       + IntegerToString(m_qtd_ticks_4_gain_raj   )+
        //" MVDESF="    + IntegerToString(movimentoEmDirecaoDesfavoravel())+
          " Volat="     + DoubleToString (m_volatilidade     ,2)+
          " DBBI="      + DoubleToString (m_infDelta         ,2)+
          " DBBM="      + DoubleToString (m_medDelta         ,2)+
          " DBBS="      + DoubleToString (m_supDelta         ,2)+
        //" BB[1]="     + DoubleToString (m_medAnt           ,2)+
        //" BB[0]="     + DoubleToString (m_med              ,2)+
        //" CCI[1]="    + DoubleToString (m_icci.Main(1)     ,2)+
        //" CCI[0]="    + DoubleToString (m_icci.Main(0)     ,2)+
          " CAPINI="    + DoubleToString (m_capitalInicial   ,2)+
          " CAPLIQ="    + DoubleToString (m_capitalLiquido   ,2)+
          " LUCRSTOPS=" + DoubleToString (m_lucroStops       ,2)+
          " Proft="     + DoubleToString (m_posicaoProfit    ,2)+
          " CAP="       + DoubleToString (m_cta.Equity   ()  ,2)+
          " SLD="       + DoubleToString (m_cta.Balance  ()  ,2)+
          " MSLDDIA="   + DoubleToString (m_maior_sld_do_dia ,2)+
          " RSLD="      + DoubleToString (m_rebaixamento_atu)   +
          " ASK/BID="   + DoubleToString (m_ask,_Digits)        + "/"+ DoubleToString (m_bid,_Digits)+
          " PMTRADE="   + DoubleToString (m_pmTra            ,2)+
          " ORDPEN="    + IntegerToString(m_qtdOrdens          )+
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
         // se nao tem ordem pendente acima do preco atual mais o passo, abre uma...
         if(passo == 0) return true;
         double precoOrdem = m_bid+(m_tick_size*passo);
         openOrdemRajadaVenda(passo,volLimite,volLote,profit,precoOrdem);
         return true;
   }else{
        if( estouComprado() ){
             // se nao tem ordem pendente abaixo do preco atual, abre uma...
             if(passo == 0) return true;
             double precoOrdem = m_ask-(m_tick_size*passo);
             openOrdemRajadaCompra(passo,volLimite,volLote,profit,precoOrdem);
             return true;
        }
   }
   // nao deveria chegar aqui, a menos que esta funcao seja chamada sem uma posicao aberta.
   Print(":-( ATENCAO OPENRAJADA chamado sem posicao aberta. Verifique! ",strPosicao() );
   return false;
}

bool openOrdemRajadaVenda( double passo, double volLimite, double volLote, double profit, double precoOrdem){

     // distancia entre a primeira ordem da posicao e a ordem atual...
     //int distancia =(int)( (m_val_order_4_gain==0)?0:(precoOrdem-m_val_order_4_gain) );

     if(m_val_order_4_gain==0){ 
        Print(":-( openOrdemRajadaVenda() chamado, mas valor de abertura da posicao eh ZERO. VERIFIQUE!!!");
        return false;
     }
     
     precoOrdem = m_val_order_4_gain+(passo*m_tick_size);
     while(precoOrdem < m_ask){
         precoOrdem = precoOrdem + (passo*m_tick_size);
     }
     
     for(int i=1; i<2; i++){
         precoOrdem = normalizar(precoOrdem);
         if(  m_posicaoVolumePend <= volLimite                                                             && // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
           //( passo==0 || distancia%(int)(passo*m_tick_size)== 0 )                                        && // posiciona rajada em distancias multiplas do passo.
             (precoOrdem > m_val_order_4_gain || m_val_order_4_gain==0 )                                   && // vender sempre acima da primeira ordem da posicao
             !m_trade.tenhoOrdemLimitadaDeVenda ( precoOrdem                   , m_symb.Name(), m_strRajada ) &&
             !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem-profit*m_tick_size, m_symb.Name(), m_strRajada ) // se tiver a ordem de compra pendente,
                                                                                                           // significa que a ordem de venda foi
                                                                                                           // executada, entao nao abrimos nova
                                                                                                           // ordem de venda ateh que a compra,
                                                                                                           // que eh seu fechamento, seja executada.
           ){
                #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print(":-| HFT_ORDEM OPEN_RAJADA SELL_LIMIT=",precoOrdem, ". Enviando... ",strPosicao() ); #endif
                #ifndef COMPILE_PRODUCAO if( SLEEP_ATRASO!= 0 ) Sleep(SLEEP_ATRASO); #endif 
                if( m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, volLote, m_strRajada+getStrComment() ) ){
                    if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem; }
                    //return true;
                }
         }
         precoOrdem = precoOrdem + (passo*m_tick_size);
         
     }
     return false;
}

bool openOrdemRajadaCompra( double passo, double volLimite, double volLote, double profit, double precoOrdem){

     // distancia entre a primeira ordem da posicao e a ordem atual...
     //int distancia = (int)( (m_val_order_4_gain==0)?0:(m_val_order_4_gain-precoOrdem) );

     if(m_val_order_4_gain==0){ 
        Print(":-( openOrdemRajadaCompra() chamado, mas valor de abertura da posicao eh ZERO. VERIFIQUE!!!");
        return false;
     }
     
     precoOrdem = m_val_order_4_gain-(passo*m_tick_size);
     while(precoOrdem > m_bid){
         precoOrdem = precoOrdem - (passo*m_tick_size);
     }

     for(int i=1; i<2; i++){
         precoOrdem = normalizar(precoOrdem);
         if(  m_posicaoVolumePend <= volLimite                                                             && // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
           //( passo==0 || distancia%(int)(passo*m_tick_size)== 0 )                                        && // posiciona rajada em distancias multiplas do passo.
             (precoOrdem < m_val_order_4_gain || m_val_order_4_gain==0 )                                   && // comprar sempre abaixo da primeira ordem da posicao
             !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem                   , m_symb.Name(), m_strRajada ) &&
             !m_trade.tenhoOrdemLimitadaDeVenda ( precoOrdem+profit*m_tick_size, m_symb.Name(), m_strRajada ) // se tiver a ordem de venda pendente,
                                                                                                           // significa que a ordem de compra foi
                                                                                                           // executada, entao nao abrimos nova
                                                                                                           // ordem de compra ateh que a venda,
                                                                                                           // que eh seu fechamento, seja executada.
           ){
    
                #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print(":-| HFT_ORDEM OPEN_RAJADA BUY_LIMIT=",precoOrdem, ". Enviando...",strPosicao()); #endif
                #ifndef COMPILE_PRODUCAO if( SLEEP_ATRASO!= 0 ) Sleep(SLEEP_ATRASO); #endif 
                if( m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, volLote, m_strRajada+getStrComment() ) ){
                    if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem;}
                    //return true;
                }
         }
         precoOrdem = precoOrdem - (passo*m_tick_size);
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
//------------------------------------------------------------------------------------------------------------
bool doCloseRajada(double passo, double volLote, double profit ){
     #ifndef COMPILE_PRODUCAO if(EA_DEBUG) m_tcloseRajada=GetMicrosecondCount();#endif
     if( estouVendido() ){
         return doCloseRajada(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_raj, true );
     }else{
         return doCloseRajada(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_raj, false);
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
double m_deal_vol = 0;
bool doCloseRajada(double passo, double volLote, double profit, bool close_sell){
   //if(volLote == 0) return true;

   // testando docloserajada2...
   if(EA_CLOSE_RAJADA2) return doCloseRajada2(passo, volLote, profit, close_sell);

   //--------------------------------------------------------------
   // para que a abertura da primeira ordem de fechamento da posicao
   // seja processada mais rapidamente que as demais.
   //--------------------------------------------------------------
   //if( m_val_close_position_sel > 0 && close_sell ){
   //    m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT,m_val_close_position_sel, m_vol_close_position_sel, PositionGetTicket(0) );
   //    m_val_close_position_sel = 0;
   //    m_vol_close_position_sel = 0;
   //    m_val_close_position_buy = 0;
   //    m_vol_close_position_buy = 0;
   //    return true;
   //}else if (m_val_close_position_buy > 0 && !close_sell){
   //          m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,m_val_close_position_buy, m_vol_close_position_buy, PositionGetTicket(0) );
   //          m_val_close_position_buy = 0;
   //          m_vol_close_position_buy = 0;
   //          m_val_close_position_sel = 0;
   //          m_vol_close_position_sel = 0;
   //          return true;
   //}
   //--------------------------------------------------------------

   // agora vamos processar as transacoes...
   ulong        deal_ticket; // ticket da transacao
   int          deal_type  ; // tipo de operação comercial
   CQueue<long> qDealSel   ; // fila de transacoes de venda  da posicao. Ao final do segundo laco, devem ficar na fila, as vendas cuja compra nao foi concretizada...
   CQueue<long> qDealBuy   ; // fila de transacoes de compra da posicao. Ao final do segundo laco, deve ficar vazia.

   // aproveitando pra atualizar o contador de transacoes na posicao...
   m_volVendasNaPosicao  = 0;
   m_volComprasNaPosicao = 0;
   
   // Faca assim:
   // 1. Coloque vendas e compras em filas separadas
   // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
   // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.

   HistorySelectByPosition(m_positionId); //preenchendo o cache com ordens e transacoes da posicao atual no historico...
   int deals = HistoryDealsTotal();
   for(int i=0;i<deals;i++) {  // selecionando as transacoes (entradas e saidas) para processamento...

      deal_ticket    =      HistoryDealGetTicket (i);
      deal_type      = (int)HistoryDealGetInteger(deal_ticket,DEAL_TYPE   );
      m_deal_vol     =      HistoryDealGetDouble (deal_ticket,DEAL_VOLUME );
      
      // 1. Colocando vendas e compras em filas separadas...
      switch(deal_type){
       case DEAL_TYPE_SELL: {qDealSel.Enqueue(deal_ticket); m_volVendasNaPosicao  += m_deal_vol; break;}
       case DEAL_TYPE_BUY : {qDealBuy.Enqueue(deal_ticket); m_volComprasNaPosicao += m_deal_vol; break;}
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
             if( m_qtdOrdens == 0 || !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){

                 // se nao tem ordem de fechamento da posicao, criamos uma agora:
                 precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) - profit*m_tick_size );
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print(":-| HFT_ORDEM CLOSE_RAJADA BUY_LIMIT=",precoProfit, " ID=", idClose, "... ", strPosicao() ); #endif
                 #ifndef COMPILE_PRODUCAO if(SLEEP_ATRASO!= 0) Sleep(SLEEP_ATRASO); #endif
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
             if( m_qtdOrdens == 0 || !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){
                 // se nao tem ordem de fechamento da posicao, criamos uma agora:
                 precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) + profit*m_tick_size );
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 #ifndef COMPILE_PRODUCAO if(EA_DEBUG        ) Print(":-| HFT_ORDEM CLOSE_RAJADA SELL_LIMIT=",precoProfit, " ID=", idClose, "...", strPosicao() ); #endif
                 #ifndef COMPILE_PRODUCAO if(SLEEP_ATRASO!= 0) Sleep(SLEEP_ATRASO); #endif
                 m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,precoProfit, vol, idClose);
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
// passo    : aumento de preco na direcao contraria a posicao
// volLote  : volume de ordem aberta na direcao contraria a posicao
// profit   : quantidade de ticks para o gain
// close_seel: true se estah fechando uma rajada de vendas e false se quer fechar uma rajada de compras.
//------------------------------------------------------------------------------------------------------------
string m_deal_comment;
bool doCloseRajada2(double passo, double volLote, double profit, bool close_sell){

   ulong        deal_ticket; // ticket da transacao
   int          deal_type  ; // tipo de operação comercial
 //CQueue<long> qDealSel   ; // fila de transacoes de venda  da posicao. Ao final do segundo laco, devem ficar na fila, as vendas cuja compra nao foi concretizada...
 //CQueue<long> qDealBuy   ; // fila de transacoes de compra da posicao. Ao final do segundo laco, deve ficar vazia.

 //CHashMap<long,string> hDealSel; // hash de transacoes de venda  da posicao. Ao final do segundo laco, devem ficar na fila, as vendas cuja compra nao foi concretizada...
 //CHashMap<long,string> hDealBuy; // hash de transacoes de compra da posicao. Ao final do segundo laco, deve ficar vazia.

   // aproveitando pra atualizar o contador de transacoes na posicao...
   m_volVendasNaPosicao  = 0;
   m_volComprasNaPosicao = 0;
   
   // Faca assim:
   // 1. Coloque vendas e compras em filas separadas.
   // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
   // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.
   HistorySelectByPosition(m_positionId); //preenchendo o cache com ordens e transacoes da posicao atual no historico...
   int deals = HistoryDealsTotal();

   // abrindo ordens de compra pra fechar uma rajada de vendas...
   if(close_sell){
      CQueue  <long     > qDealBuy; // fila de transacoes de compra da posicao. Ao final do segundo laco, deve ficar vazia.
      CHashMap<long,long> hDealSel; // hash de transacoes de venda  da posicao. Ao final do segundo laco, devem ficar na fila, as vendas cuja compra nao foi concretizada...
      
      for(int i=0;i<deals;i++) {  // selecionando as transacoes (entradas e saidas) para processamento...
    
         deal_ticket    =      HistoryDealGetTicket (i);
         deal_type      = (int)HistoryDealGetInteger(deal_ticket,DEAL_TYPE   );
         m_deal_vol     =      HistoryDealGetDouble (deal_ticket,DEAL_VOLUME );
       //m_deal_comment =      HistoryDealGetString (deal_ticket,DEAL_COMMENT);
          
         // 1. Colocando vendas e compras em estruturas separadas...
         switch(deal_type){
            case DEAL_TYPE_BUY : {qDealBuy.Add(deal_ticket            ); m_volComprasNaPosicao += m_deal_vol; break;}
            case DEAL_TYPE_SELL: {hDealSel.Add(deal_ticket,deal_ticket); m_volVendasNaPosicao  += m_deal_vol; break;}
         }
      }
      
      // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
      long ticketSel;
      int  qtd = qDealBuy.Count();
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealBuy.Dequeue();
         ticketSel   = StringToInteger( HistoryDealGetString(deal_ticket,DEAL_COMMENT) ); // obtendo o ticket de venda no comentario da ordem de compra...
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
                 precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) - profit*m_tick_size );
                 if(precoProfit > m_ask ) precoProfit = m_ask;
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 #ifndef COMPILE_PRODUCAO if(EA_DEBUG        )Print(":-| HFT_ORDEM CLOSE_RAJADA BUY_LIMIT=",precoProfit, " ID=", idClose, "... ", strPosicao() ); #endif
                 #ifndef COMPILE_PRODUCAO if(SLEEP_ATRASO!= 0) Sleep(SLEEP_ATRASO); #endif
                 m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT,precoProfit, vol, idClose);
                 
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
          
         // 1. Colocando vendas e estruturas separadas...
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
                 precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) + profit*m_tick_size );
                 if(precoProfit < m_bid) precoProfit = m_bid;
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 #ifndef COMPILE_PRODUCAO if(EA_DEBUG        ) Print(":-| HFT_ORDEM CLOSE_RAJADA SELL_LIMIT=",precoProfit, " ID=", idClose, "...", strPosicao() ); #endif
                 #ifndef COMPILE_PRODUCAO if(SLEEP_ATRASO!= 0) Sleep(SLEEP_ATRASO); #endif
                 m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,precoProfit, vol, idClose);
             }
          }
      }
   }

   return true;
}



// coloca duas ordens
void abrirPosicaoHFTnorteSul(){

   double vol           = m_vol_lote_ini;
   double precoOrdem    = 0;
   double inclinacaoMin = 0.1;
   double shift         = 1;


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
               #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print("HFT_VENDA_NS=",precoOrdem,". Criando ordem de VENDA.", strPosicao()," ..."); #endif
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_ns );

               // colocando a compra
               precoOrdem = m_bid;
             //precoOrdem = m_bid-m_tick_size;
             //precoOrdem = m_bid-m_tick_size*2;
               #ifndef COMPILE_PRODUCAO if(EA_DEBUG) Print("HFT_COMPRA_NS=",precoOrdem,". Criando ordem de COMPRA.", strPosicao()," ..."); #endif
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, m_apmb_ns );
       }else{
               // colocando a compra
               precoOrdem = m_bid;
             //precoOrdem = m_bid-m_tick_size;
             //precoOrdem = m_bid-m_tick_size*2;
               #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("HFT_COMPRA_NS=",precoOrdem,". Criando ordem de COMPRA.", strPosicao()," ..."); #endif
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, m_apmb_ns );

               // colocando a venda
               precoOrdem = m_ask;
             //precoOrdem = m_ask+m_tick_size;
             //precoOrdem = m_ask+m_tick_size*2;
               #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("HFT_VENDA_NS=",precoOrdem,". Criando ordem de VENDA.", strPosicao()," ..."); #endif
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
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, m_strRajada );
     }else{
             precoOrdem = m_bid-m_tick_size;
             Print("HFT_COMPRA_NS=",precoOrdem,". Criando ordem de COMPRA.", strPosicao()," ...");
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, m_apmb );

             precoOrdem = m_bid;
             Print("HFT_VENDA_NS=",precoOrdem,". Criando ordem de VENDA.", strPosicao()," ...");
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_strRajada );
     }
*/

}

// HFT_DISTANCIA_PRECO
// Abre e mantem as ordens limitadas de abertura de posicao.
// Condicoes:
// Compra abaixo da media de compra(barato) e vende acima da media de compra(caro);
// Ordens limitadas sao colocadas EA_TICKS_ENTRADA_DIST_PRECO (geralmente zero, 1 ou 2 ticks) de distancia do preco atual.
// Nao abre posicao durante o pregao.
// Nao abre posicao se a volatilidade estiver alta.
// Nao chame este metodo se houver posicao aberta.
// Correcoes na versao 02-084
// - Passa a considerar o ask pra comprar e o bid pra vender (estava invertido).
// - Passa a proteger a compra pra que o gain nao ultrapasse a media de agressoes (estava protegendo somente a venda).
// - Corrige a impressao do ordem de compra (estava colocando o valor errado).
void abrirPosicaoHFTdistanciaDoPreco(){

   double vol           = m_vol_lote_ini;
   double precoOrdem    = 0;
   double shift         = 0;

   if( EA_TIPO_ENTRADA_PERMITIDA == ENTRADA_SELL || EA_TIPO_ENTRADA_PERMITIDA == ENTRADA_TODAS ){

   //if( m_inclTra <= -EA_INCL_MIN && m_volTradePorSegDeltaPorc < EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO ){
   //if( m_inclTra <= -EA_INCL_MIN && m_volTradePorSegDeltaPorc < 0                && m_acelVolTradePorSegDeltaPorc > 0                           ){
   //if( m_inclTra <= -EA_INCL_MIN                                                                                                                ){

        //m_trade.cancelarOrdensComentadas(m_apmb_buy);
  
        // se preco acima da media da banda de bollinguer e as extremidades abrindo, nao deixa vender...
        //if( //m_ask      > m_med   && //preco acima da media da banda de bollinguer
        //    m_medDelta > 0       && //inclinacao da       media    pra cima 
        //    m_supDelta > 0       && //inclinacao da banda superior pra cima
        //    m_infDelta < 0        ){//inclinacao da banda inferior pra baixo
        
      //if( m_medDelta < -15 && m_infDelta < 0        ){//inclinacao da       media    pra baixo 
        if( ( m_volTradePorSegDeltaPorc < -EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc >  EA_MIN_DELTA_VOL_ACELERACAO ) ||
            ( m_volTradePorSegDeltaPorc >  EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc < -EA_MIN_DELTA_VOL_ACELERACAO )  ){
            // Vende EA_TICKS_ENTRADA_DIST_PRECO ticks acima do preco atual.
            precoOrdem = m_bid+(m_tick_size*EA_TICKS_ENTRADA_DIST_PRECO);
   
            // vendendo acima da media...
            if( precoOrdem < m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini) ){
              //precoOrdem = m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini);
                precoOrdem = m_pmTra + (m_tick_size                       ); // pra teste
            }
            precoOrdem = normalizar(precoOrdem); //correcao aplicada em 17/01/2020
            if( precoOrdem != m_precoUltOrdemInSel ){    
                m_precoUltOrdemInSel = precoOrdem;
                //if( precoOrdem > m_pmAsk ){ precoOrdem = m_pmAsk; }
        
                //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
                if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*shift, m_apmb_sel+getStrComment() ) ){
                     #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| HFT_VENDA BID=",m_bid,". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao(),"..."); #endif
                     if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_sel+getStrComment() );
                }
            }
        }else{
            m_trade.cancelarOrdensComentadas(m_apmb_sel);
        }
        
   }  // fim do "if" do tipos de entrada permitida "sell"...
   //}else{

   if( EA_TIPO_ENTRADA_PERMITIDA == ENTRADA_BUY || EA_TIPO_ENTRADA_PERMITIDA == ENTRADA_TODAS ){
       //if( m_inclTra >= EA_INCL_MIN && m_volTradePorSegDeltaPorc > EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO){
       //if( m_inclTra >= EA_INCL_MIN && m_volTradePorSegDeltaPorc > 0                && m_acelVolTradePorSegDeltaPorc > 0                          ){
       //if( m_inclTra >= EA_INCL_MIN                                                                                                               ){
           //m_trade.cancelarOrdensComentadas(m_apmb_sel);

             // se preco abaixo da media da banda de bollinguer e as extremidades abrindo, nao deixa comprar...
             //if( //m_bid      < m_med   && //preco abaixo da media da banda de bollinguer
             //    m_medDelta < 0       && //inclinacao da       media    pra baixo 
             //    m_supDelta > 0       && //inclinacao da banda superior pra cima
             //    m_infDelta < 0        ){//inclinacao da banda inferior pra baixo
             
           //if( m_medDelta > 15 && m_supDelta > 0   ){//inclinacao da media pra cima                 
             if( ( m_volTradePorSegDeltaPorc >  EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc >  EA_MIN_DELTA_VOL_ACELERACAO ) ||
                 ( m_volTradePorSegDeltaPorc < -EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc < -EA_MIN_DELTA_VOL_ACELERACAO ) ){
                 //Compra EA_TICKS_ENTRADA_DIST_PRECO abaixo do preco atual.
                 precoOrdem = m_ask-(m_tick_size*EA_TICKS_ENTRADA_DIST_PRECO);
        
                 // comprando abaixo da media (barato)...
                 if( precoOrdem > m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini ) ){
                   //precoOrdem = m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini );
                     precoOrdem = m_pmTra - (m_tick_size                        );
                 }
                 precoOrdem = normalizar(precoOrdem); //correcao aplicada em 17/01/2020
                 if( precoOrdem != m_precoUltOrdemInBuy ){    
                     m_precoUltOrdemInBuy = precoOrdem;
                     //if( precoOrdem < m_pmBid ){ precoOrdem = m_pmBid; }
            
                     //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
                     if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*shift, m_apmb_buy+getStrComment() ) ){
                          #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| HFT_COMPRA ASK=",m_ask,". Criando ordem de COMPRA a ",  precoOrdem, " ", strPosicao(),"..."); #endif
                          if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb_buy+getStrComment() );
                     }
                 }
             }else{
                 m_trade.cancelarOrdensComentadas(m_apmb_buy);
             }
   } // fim do "if" controle do tipo de entrada permitida "compra"...
   //}
}

// HFT_DISTANCIA_DA_MEDIA (nova estrategia implanatada em 29/01/2020)
// Abre e mantem as ordens limitadas de abertura de posicao.
// Condicoes:
// Compra abaixo da media de compra(barato) e vende acima da media de compra(caro);
// Ordens limitadas sao colocadas EA_TICKS_FOR_GAIN de distancia da media.
void abrirPosicaoHFTdistanciaDaMedia(){

   double vol           = m_vol_lote_ini;
   double precoOrdem    = 0;
   double shift         = 0;

   if( EA_TIPO_ENTRADA_PERMITIDA == ENTRADA_SELL || EA_TIPO_ENTRADA_PERMITIDA == ENTRADA_TODAS ){

        
            precoOrdem = m_ask;
   
            // vendendo acima da media...
            if( precoOrdem < m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini) ){
                precoOrdem = m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini);
            }
            precoOrdem = normalizar(precoOrdem); 
            if( precoOrdem != m_precoUltOrdemInSel ){    
                m_precoUltOrdemInSel = precoOrdem;
        
                //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
                if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*shift, m_apmb_sel+getStrComment() ) ){
                     #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| HFT_VENDA BID=",m_bid,". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao(),"..."); #endif
                     if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_sel+getStrComment() );
                }
            }
        
   }  // fim do "if" do tipos de entrada permitida "sell"...

   if( EA_TIPO_ENTRADA_PERMITIDA == ENTRADA_BUY || EA_TIPO_ENTRADA_PERMITIDA == ENTRADA_TODAS ){
             
         precoOrdem = m_bid;

         // comprando abaixo da media (barato)...
         if( precoOrdem > m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini ) ){
             precoOrdem = m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini );
         }
         precoOrdem = normalizar(precoOrdem); 
         if( precoOrdem != m_precoUltOrdemInBuy ){    
             m_precoUltOrdemInBuy = precoOrdem;

             //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
             if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*shift, m_apmb_buy+getStrComment() ) ){
                  #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| HFT_COMPRA ASK=",m_ask,". Criando ordem de COMPRA a ",  precoOrdem, " ", strPosicao(),"..."); #endif
                  if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb_buy+getStrComment() );
             }
         }
   } // fim do "if" controle do tipo de entrada permitida "compra"...
   //}
}

//------------------------------------------------------------------------------------------------------------
// HFT_NA_TENDENCIA
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

   double vol         = m_vol_lote_ini;
   double precoOrdem  = 0;
   double incl_limite = 0.08;

     //Se a volatilidade estah alta, cancela as ordens de abertura de posicao.
     //if ( volatilidadeEstahAlta() ){ m_trade.cancelarOrdensComentadas(m_apmb); return; }

     // Vendendo na inclinacao negativa...
   //if( m_feira.getSinalInclinacaoDw(0) > 0 && m_volTradePorSegDeltaPorc < 10 && m_bid < m_med + m_dx1 ){
   //if( m_feira.getSinalInclinacaoDw(0) > 0                                   && m_bid < m_med + m_dx1 ){
   //if( m_feira.getSinalInclinacaoDw(0) > 0 && m_medDelta<0                   && m_ask < m_med + m_dx1 ){
   //if( m_feira.getSinalInclinacaoDw(0) > 0 && m_medDelta<0                   && m_ask < m_med + m_dx1 && m_supDelta>0 && m_infDelta<0){
   //if(                                        m_medDelta<0                   && m_ask < m_med + m_dx1 && m_supDelta>0 && m_infDelta<0){
   //if(                                        m_medDelta<0                                                            && m_infDelta<0){
     if( (m_medDelta<-1 && m_ask < m_med && m_infDelta<-2) ||
         (m_medDelta<-1 && m_ask > m_med && m_supDelta<-2)    ){
     
         m_trade.cancelarOrdensComentadas(m_apmb_buy);
         
         precoOrdem = m_phigh;
         if(precoOrdem > m_pmAsk) precoOrdem = m_pmAsk;
         if( precoOrdem < m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini)  ){
             precoOrdem = m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini);
         }
         precoOrdem = normalizar(precoOrdem);
       /*
       precoOrdem = m_ask;
       //if( precoOrdem < m_pmTra - (m_tick_size*m_qtd_ticks_4_gain) ){
         //if( precoOrdem < m_pmTra                                    ){
         //    precoOrdem = normalizar( m_pmTra + (m_tick_size*m_qtd_ticks_4_gain) );
         //  //precoOrdem = normalizar( m_pmTra                                    );
         //}
         if( precoOrdem > m_pmAsk ){
             precoOrdem = normalizar( m_pmAsk );
         }
       */
         //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
         if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
             #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("HFT_ORDEM OPEN_POS BID=",m_bid,". Criando ord VENDA a ",  precoOrdem, strPosicao());#endif
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_sel+getStrComment() );
         }
         
         return;
     }else{
         m_trade.cancelarOrdensComentadas(m_apmb_sel);
     }

     // Comprando na inclinacao positiva e gain abaixo ou igual a media de precos...
   //if( m_feira.getSinalInclinacaoUp(0)>0 && m_volTradePorSegDeltaPorc > -10 && m_ask > m_med - m_dx1                                 ){ //(estrategia 1)
   //if( m_feira.getSinalInclinacaoUp(0)>0                                    && m_ask > m_med - m_dx1                                 ){ //(estrategia 2)
   //if( m_feira.getSinalInclinacaoUp(0)>0 && m_medDelta>0                    && m_bid > m_med - m_dx1                                 ){ //(estrategia 3)
   //if( m_feira.getSinalInclinacaoUp(0)>0 && m_medDelta>0                    && m_bid > m_med - m_dx1 && m_supDelta>0 && m_infDelta<0 ){ //(estrategia 4)
   //if(                                      m_medDelta>0                    && m_bid > m_med - m_dx1 && m_supDelta>0 && m_infDelta<0 ){ //(estrategia 4)
   //if(                                      m_medDelta>0                                             && m_supDelta>0                 ){ //(estrategia 6)
     if( (m_medDelta>1 && m_bid > m_med && m_supDelta>2) ||
         (m_medDelta>1 && m_bid < m_med && m_infDelta>2) ){ //(estrategia 7)


         m_trade.cancelarOrdensComentadas(m_apmb_sel);
                  
         precoOrdem = m_plow;
         if(precoOrdem < m_pmBid) precoOrdem = m_pmBid;
         if( precoOrdem > m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini)  ){
             precoOrdem = m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini);
         }
         precoOrdem = normalizar(precoOrdem);
         
         /*
         precoOrdem = normalizar(m_bid);
       //if( precoOrdem > m_pmTra - (m_tick_size*m_qtd_ticks_4_gain) ){
           //if( precoOrdem > m_pmTra                                    ){
           //    precoOrdem = normalizar( m_pmTra - (m_tick_size*m_qtd_ticks_4_gain) );
           //  //precoOrdem = normalizar( m_pmTra                                    );
           //}
           if( precoOrdem > m_pmBid                                    ){
               precoOrdem = normalizar( m_pmBid );
           }
          */
          
         //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
         if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
             #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("HFT_ORDEM OPEN_POS ASK=",m_ask,". Criando ord COMPRA a ",  precoOrdem, strPosicao() ," ... profit=", m_posicaoProfit);#endif
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb_buy+getStrComment() );
         }
         
         return;
     }else{
         m_trade.cancelarOrdensComentadas(m_apmb_buy);
     }

}
//------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------
// Estrategia testada em 29/11/2019 retornou
//CONTRA_TEND_DURANTE_COMPROMETIMENTO
void abrirPosicaoDuranteComprometimentoInstitucional(){
    double vol        = m_vol_lote_ini;
    double precoOrdem = 0;
    double shift = m_tick_size;
  //double shift = 0


    precoOrdem = normalizar(m_pmAsk); // venda no preco medio de compra
    //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
    if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, shift ) ){
         if(precoOrdem!=0) {
            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_ASK=",m_pmAsk,". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao(),"...");#endif
            m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
         }else{
            m_qtd_erros++;
            if(m_qtd_erros>1000){
                Print(":-( MEDIA_ASK=",m_pmAsk,".  Preco zerado ao criar ordem de VENDA a ",  precoOrdem, "... VERIFIQUE!", strPosicao());
                m_qtd_erros=0;
            }
         }
    }

    precoOrdem = normalizar(m_pmBid); // copmpra no preco medio de venda
    //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
    if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, shift ) ){
         if(precoOrdem!=0){
            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_BID ",m_pmBid,".  Criando ordem de COMPRA a ",  precoOrdem, " ", strPosicao(), "...");#endif
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

   double vol        = m_vol_lote_ini;
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
             #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("COMPROMISSO_UP=",m_comprometimento_up,".  Criando ordem de VENDA a ",  precoOrdem, "...");#endif
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
             #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("COMPROMISSO_DW=",m_comprometimento_dw,".  Criando ordem de COMPRA a ",  precoOrdem, "...");#endif
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
        }
   }


   // se nao tem comprometimento, cancela as ordens abertas.
   if (!tem_comprometimento) m_trade.cancelarOrdensComentadas(m_apmb);
}
//----------------------------------------------------------------------------------------------------------------------------------
// Abre e mantem as ordens de abertura de posicao. Nao chame este metodo se houver posicao aberta.
void abrirPosicaoAposMaxMinBarraAnterior(){

   double vol        = m_vol_lote_ini;
   double precoOrdem = 0;

     //Nao abrir posicao se volatilidade for alta.
     //se a volatilidade estah alta, cancela as ordens de abertura de posicao.
     if ( volatilidadeEstahAlta() ) { m_trade.cancelarOrdensComentadas(m_apmb); return; }

     //Vende se o preco ficar maior que a maxima da vela anterior.
     if( m_ask >= m_max_barra_anterior ){
         precoOrdem = m_ask; // se o ask jah passou a maxima da barra anterior, entramos com o preco ask.
     }else{
         precoOrdem = m_max_barra_anterior; // se ask nao passou a maxima da barra anterior, entramos na maxima da barra anterior
     }

     //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
     if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size ) ){
          #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("MAX_BARRA_ANT=",m_max_barra_anterior,".  Criando ordem de VENDA a ",  precoOrdem, " Volatilidade=",m_volatilidade," ...");#endif
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
          #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("MIN_BARRA_ANT=",m_min_barra_anterior,".  Criando ordem de COMPRA a ",  precoOrdem, " Volatilidade=",m_volatilidade, " ...");#endif
          if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
     }

}
// Abre posicao apos rompimento do max ou min da volatilidade...
// ESta opcao nao se importa se a volatilidade estiver alta
void abrirPosicaoCCINaTendencia(){
   double vol        = m_vol_lote_ini;
   double precoOrdem = 0;
 //double shift      = m_tick_size*3;
   double inclinacao_min = EA_INCL_MIN;

    if ( !taxaVolumeEstahL2() ) return;


   precoOrdem = m_bid;

   if( precoOrdem <= m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini ) ){
 //if( precoOrdem < m_pmTra                                     ){
     //precoOrdem = m_pmTra + (m_tick_size*m_qtd_ticks_4_gain);
     //precoOrdem = m_pmTra;

       // cci acima de 100 e cci apontando pra baixo...
       if( (m_icci.Main(0) >    0            &&
            m_icci.Main(0) <  m_icci.Main(1) &&
            m_icci.Main(1) <= m_icci.Main(2) && // comentado na cci-v6
            m_inclTra      <  -inclinacao_min ) ||
            m_icci.Main(0) > 200                 ){ // CCI  pra baixo;

           //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
           if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb_sel, vol , true, m_tick_size ) ){

                 if(precoOrdem!=0) {
                    #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_TRADE=",DoubleToString(m_pmTra,2),". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao(),"...");#endif
                    m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_sel);
                 }
           }
       }else{
           m_trade.cancelarOrdensComentadas(m_apmb_sel);
       }
   }


   precoOrdem = m_ask;

   if( precoOrdem >= m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini ) ){
 //if( precoOrdem > m_pmTra                                     ){
     //precoOrdem = m_pmTra - (m_tick_size*m_qtd_ticks_4_gain );
     //precoOrdem = m_pmTra                                    ;

       // cci abaixo de -100 e cci apotando pra cima...
       if( (m_icci.Main(0) <  0              &&
            m_icci.Main(0) >  m_icci.Main(1) &&
            m_icci.Main(1) >= m_icci.Main(2) &&
            m_inclTra      > inclinacao_min   ) ||
            m_icci.Main(0) < -200                ){ // CCI  pra cima;
           //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
           if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb_buy, vol , true, m_tick_size ) ){

                 if(precoOrdem!=0){
                    #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_TRADE ",DoubleToString(m_pmTra,2),".  Criando ordem de COMPRA a ",  precoOrdem, " ", strPosicao(), "...");#endif
                    m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb_buy);
                 }
           }
       }else{
           m_trade.cancelarOrdensComentadas(m_apmb_buy);
       }
   }
}

//HFT_MAX_MIN_VOLAT
//Abre posicao apos rompimento do max ou min da volatilidade...
// Condicoes compra:
// - preco abaixo da media de trade
// - preco igual ao minimo no historico de 1 min (um tick de tolerancia)
// - mercado comprador: - % deltaVolumeTrade positivo e maior que EA_MIN_DELTA_VOL
// -                    - aceleracao % deltaVolumeTrade positiva e maior que EA_MIN_DELTA_VOL_ACELERACAO
// Condicoes compra:
// - preco acima da media de trade
// - preco igual ao maximo no historico de 1 min (um tick de tolerancia)
// - mercado vendedor: - % deltaVolumeTrade negativo e menor que EA_MIN_DELTA_VOL
// -                   - aceleracao % deltaVolumeTrade positiva e maior que EA_MIN_DELTA_VOL_ACELERACAO
//
void abrirPosMaxMinVolatContraTend(){
    double precoOrdem = 0;
   
   // mercado estah comprador, entao cancelamos ordens de venda pendentes e abrimos as de compra....
   if( ( m_volTradePorSegDeltaPorc > EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO )
         ||
       ( m_volTradePorSegDeltaPorc     <  0   &&
         m_volTradePorSegDeltaPorc     > -20  &&
         m_acelVolTradePorSegDeltaPorc < -EA_MIN_DELTA_VOL_ACELERACAO  )// mercado vendedor, mas desacelerando...
      ){

       m_trade.cancelarOrdensComentadas(m_apmb_sel);

       precoOrdem = m_plow; // compra no topo inferior do canal de volatilidade
       if( precoOrdem > m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini) ){
           precoOrdem = normalizar( m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini) );
       }
       //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
       if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb_buy, m_vol_lote_ini , true, m_tick_size ) ){
            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_TRADE ",DoubleToString(m_pmTra,2),".  Criando ordem de COMPRA a ",  precoOrdem," ", strPosicao());#endif
            if( SLEEP_ATRASO!= 0 ) Sleep(SLEEP_ATRASO);
            if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, m_apmb_buy + getStrComment() );
            m_val_close_position_buy = precoOrdem + (m_tick_size*m_qtd_ticks_4_gain_ini);
            m_vol_close_position_buy = m_vol_lote_ini;
       }
   }else


   // mercado estah vendedor, entao cancelamos ordens de compra pendentes e abrimos as venda....
   if( (m_volTradePorSegDeltaPorc < -EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO)
         ||
       ( m_volTradePorSegDeltaPorc     >  0   &&
         m_volTradePorSegDeltaPorc     <  20  &&
         m_acelVolTradePorSegDeltaPorc < -EA_MIN_DELTA_VOL_ACELERACAO )// mercado comprador, mas desacelerando...
    ){
       
       m_trade.cancelarOrdensComentadas(m_apmb_buy);

       precoOrdem = m_phigh; // venda no topo superior do canal de volatilidade
       if( precoOrdem < m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini ) ){
           precoOrdem = normalizar( m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini ) );
       }
       
       //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
       if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb_sel, m_vol_lote_ini , true, m_tick_size ) ){
            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_TRADE=",DoubleToString(m_pmTra,2),". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao() );#endif
            if( SLEEP_ATRASO!= 0 ) Sleep(SLEEP_ATRASO);
            if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, m_vol_lote_ini, m_apmb_sel + getStrComment() );
            m_val_close_position_sel = precoOrdem - (m_tick_size*m_qtd_ticks_4_gain_ini);
            m_vol_close_position_sel = m_vol_lote_ini;        
       }
   }
   else{
         m_trade.cancelarOrdensComentadas(m_apmb);
   }
   /*
   else{
   
    // mercado sem direcao definida, entao podemos manter pedidos nas duas direcoes.
    
       precoOrdem = m_plow; // compra no topo inferior do canal de volatilidade
       if( precoOrdem > m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini) ){
           precoOrdem = normalizar( m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini) );
       }
       //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
       if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb_buy, m_vol_lote_ini , true, m_tick_size ) ){
            if(EA_DEBUG)Print(":-| MEDIA_TRADE ",DoubleToString(m_pmTra,2),".  Criando ordem de COMPRA a ",  precoOrdem," ", strPosicao());
            if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, m_apmb_buy + getStrComment() );
            m_val_close_position_buy = precoOrdem + (m_tick_size*m_qtd_ticks_4_gain_ini);
            m_vol_close_position_buy = m_vol_lote_ini;
       }

       precoOrdem = m_phigh; // venda no topo superior do canal de volatilidade
       if( precoOrdem < m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini ) ){
           precoOrdem = normalizar( m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini ) );
       }
       
       //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
       if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb_sel, m_vol_lote_ini , true, m_tick_size ) ){
            if(EA_DEBUG)Print(":-| MEDIA_TRADE=",DoubleToString(m_pmTra,2),". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao() );
            if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, m_vol_lote_ini, m_apmb_sel + getStrComment() );
            m_val_close_position_sel = precoOrdem - (m_tick_size*m_qtd_ticks_4_gain_ini);
            m_vol_close_position_sel = m_vol_lote_ini;        
       }
   }
   */
}

// HFT_ARBITRAGEM_VOLUME
// Abre posicao na arbitragem de volume.
// Se preco acima  da media de trade e volume de vendas  eh maior que volume de compras, vende .
// Se preco abaixo da media de trade e volume de compras eh maior que volume de vendas , compra.
// ESta opcao nao se importa se a volatilidade estiver alta
void abrirPosicaoArbitragemVolume(){
    double precoOrdem = 0;

   
   // mercado estah comprador, entao cancelamos ordens de venda pendentes e abrimos as de compra....
   if( m_volTradePorSegDeltaPorc > EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO ){

       m_trade.cancelarOrdensComentadas(m_apmb_sel);

       // comprando abaixo da media...
       //precoOrdem = normalizar( m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini) );
       precoOrdem = m_bid;
       //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
       if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb_buy, m_vol_lote_ini , true, m_tick_size ) ){
            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_TRADE ",DoubleToString(m_pmTra,2),".  Criando ordem de COMPRA a ",  precoOrdem," ", strPosicao());#endif
            if( SLEEP_ATRASO!= 0 ) Sleep(SLEEP_ATRASO);
            if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, m_apmb_buy + getStrComment() );
            m_val_close_position_buy = precoOrdem + (m_tick_size*m_qtd_ticks_4_gain_ini);
            m_vol_close_position_buy = m_vol_lote_ini;
       }
   }else

   // mercado estah vendedor, entao cancelamos ordens de compra pendentes e abrimos as venda....
   if( m_volTradePorSegDeltaPorc < -EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO ){
       
       m_trade.cancelarOrdensComentadas(m_apmb_buy);

       // vendendo acima da media...
       //precoOrdem = normalizar( m_pmTra + (m_tick_size*m_qtd_ticks_4_gain ) );
       precoOrdem = m_ask;
       //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
       if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb_sel, m_vol_lote_ini , true, m_tick_size ) ){
            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_TRADE=",DoubleToString(m_pmTra,2),". Criando ordem de VENDA a ",  precoOrdem, " ", strPosicao() );#endif
            if( SLEEP_ATRASO!= 0 ) Sleep(SLEEP_ATRASO);
            if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, m_vol_lote_ini, m_apmb_sel + getStrComment() );
            m_val_close_position_sel = precoOrdem - (m_tick_size*m_qtd_ticks_4_gain_ini);
            m_vol_close_position_sel = m_vol_lote_ini;        
       }
   }
   else{
         m_trade.cancelarOrdensComentadas(m_apmb);
   }
}

string getStrComment(){
  if( EA07_ABRIR_POSICAO == HFT_DESBALANC_BOOK   || 
      EA07_ABRIR_POSICAO == HFT_DESBALANC_BOOKNS   ){
      return getStrCommentBook();
  }else{
      return 
              " v" +DoubleToString (m_volTradePorSeg                ,0) + // volume de contratos/ticks negociados por segundo
              " d" +IntegerToString(m_volTradePorSegDeltaPorc         ) + //               % delta dos contratos/ticks negociados por segundo.
              " a" +IntegerToString(m_acelVolTradePorSegDeltaPorc     ) + // aceleracao da % delta dos contratos/ticks negociados por segundo.
              " t" +DoubleToString (m_volatilidade*10               ,0) + // volatilidade
              " i" +DoubleToString (m_inclTra*10                    ,0) + // inclinacao das agressoes
              " b" +DoubleToString (m_desbUp0*100                   ,0) + // desbalanceamento book na primeira fila
              " b" +DoubleToString (m_desbUp1*100                   ,0) ; // desbalanceamento book na segunda fila
  }
}
string getStrCommentBook(){
  return 
          " v" +DoubleToString (m_volTradePorSeg                ,0) + // volume de contratos/ticks negociados por segundo
          " d" +IntegerToString(m_volTradePorSegDeltaPorc         ) + //               % delta dos contratos/ticks negociados por segundo.
          " a" +IntegerToString(m_acelVolTradePorSegDeltaPorc     ) + // aceleracao da % delta dos contratos/ticks negociados por segundo.
          " b" +DoubleToString (m_desbUp0*100                   ,0) + // desbalanceamento book na primeira fila
          " b" +DoubleToString (m_desbUp1*100                   ,0) + // desbalanceamento book na segunda fila
          " t" +DoubleToString (m_volatilidade*10               ,0) ; // volatilidade
}

// Abre posicao se houver desbalanceamento de ofertas nas primeiras filas do book...
// Esta opcao nao se importa se a volatilidade estiver alta
// HFT_DESBALANC_BOOK
void abrirPosicaoHFTDesbalancBook(){
   double precoOrdem = 0;

 //precoOrdem = m_ask+m_tick_size; // <TODO>para piorar as condicoes de entrada no teste. Em producao, tem de tirar o +5
   precoOrdem = m_ask;
   if( m_desbUp0 < EA_DESBALAN_DW0  && m_desbUp0 != 0      && // 80% de chance do o preco cair
 //if( m_desbUp1 < EA_DESBALAN_DW0  && m_desbUp1 != 0      && // 80% de chance do o preco cair
 //    m_volTradePorSegDeltaPorc < EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO  && // volume de vendas superior.
       precoOrdem >= m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini ) ){  // vendendo acima da media de trade
   //                                                           ){

       if( precoOrdem != m_precoUltOrdemInSel ){
           m_precoUltOrdemInSel = precoOrdem;
           //verificando se tem ordens sell abertas (usando 0 tick de tolerancia)...
           if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, m_vol_lote_ini , true, 0 ) ){
    
                #ifndef COMPILE_PRODUCAO if(EA_DEBUG        )Print(":-| MEDIA_TRADE=",DoubleToString(m_pmTra,2),". Criando VENDA a ",  precoOrdem, " ", strPosicao() );#endif
                #ifndef COMPILE_PRODUCAO if(SLEEP_ATRASO!= 0) Sleep(SLEEP_ATRASO);#endif
                if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, m_vol_lote_ini, m_apmb_sel+getStrCommentBook());
                //m_val_close_position_sel = precoOrdem - (m_tick_size*m_qtd_ticks_4_gain_ini);
                //m_vol_close_position_sel = m_vol_lote_ini;
           }
       }
   }else{

     //precoOrdem = m_bid-m_tick_size; // <TODO>para piorar as condicoes de entrada no teste. Em producao, tem de tirar o -5
       precoOrdem = m_bid;
       if( m_desbUp0 > EA_DESBALAN_UP0 && m_desbUp0 != 0            && // 80% de chance do preco subir
     //if( m_desbUp1 > EA_DESBALAN_UP0 && m_desbUp1 != 0            && // 80% de chance do preco subir
    //     m_volTradePorSegDeltaPorc > EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO && // volume de compras superior.
           precoOrdem <= m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini ) ){  // comprando abaixo da media de trade
         //                                                         ){

           if( precoOrdem != m_precoUltOrdemInBuy ){
               m_precoUltOrdemInBuy = precoOrdem;
               //verificando se tem ordens buy abertas (usando 0 tick de tolerância)...
               if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, m_vol_lote_ini , true, 0 ) ){
                    #ifndef COMPILE_PRODUCAO if(EA_DEBUG        )Print(":-| MEDIA_TRADE ",DoubleToString(m_pmTra,2),".  Criando COMPRA a ",  precoOrdem," ", strPosicao());#endif
                    #ifndef COMPILE_PRODUCAO if(SLEEP_ATRASO!= 0) Sleep(SLEEP_ATRASO);#endif
                    if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, m_apmb_buy+getStrCommentBook());
                    //m_val_close_position_buy = precoOrdem + (m_tick_size*m_qtd_ticks_4_gain_ini);
                    //m_vol_close_position_buy = m_vol_lote_ini;
               }
           }
       // nao cancelar por enquanto. entendo que esta ordem pode ganhar prioridade se o preco voltar
       // para o lado contrario do desbalanceamento.
       //}else{
       //     m_trade.cancelarOrdensComentadas(m_apmb);
       //     m_val_close_position_sel = 0;
       //     m_vol_close_position_sel = 0;
       //     m_val_close_position_buy = 0;
       //     m_vol_close_position_buy = 0;
       }
   }
}

void abrirPosicaoHFTDesbalancBookNorteSul(){
   double precoOrdem = 0;
   bool sincro = false;

   precoOrdem = m_ask;
   if( m_desbUp0  < EA_DESBALAN_DW0  && m_desbUp0 != 0      && // 80% de chance do o preco cair
       m_volTradePorSegDeltaPorc < EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO && // volume de vendas superior...       
       precoOrdem > m_pmTra + (m_tick_size*m_qtd_ticks_4_gain_ini ) ){  // vendendo acima da media de trade

       //verificando se tem ordens sell abertas (usando 0 tick de tolerancia)...
       if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), "OPCL", m_vol_lote_ini , true, 0 ) ){

            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_TRADE=",DoubleToString(m_pmTra,2),". Criando VENDA a ",  precoOrdem, " ", strPosicao() );#endif
            if( precoOrdem!=0 ){
                sincro = m_trade.getAsync();
                m_trade.setAsync(true);
                if( m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, m_vol_lote_ini, "OPCL") ){
                    m_val_close_position_sel = precoOrdem - (m_tick_size*m_qtd_ticks_4_gain_ini);
                    m_vol_close_position_sel = m_vol_lote_ini;                   
                    m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, m_val_close_position_sel, m_vol_lote_ini, "OPCL");               
                }
                m_trade.setAsync(sincro);
            }
       }
   }else{
       precoOrdem = m_bid;
       if( m_desbUp0  > EA_DESBALAN_UP0 && m_desbUp0 != 0            && // 80% de chance do preco subir
           m_volTradePorSegDeltaPorc > EA_MIN_DELTA_VOL && m_acelVolTradePorSegDeltaPorc > EA_MIN_DELTA_VOL_ACELERACAO && // volume de compras superior...       
           precoOrdem < m_pmTra - (m_tick_size*m_qtd_ticks_4_gain_ini ) ){  // comprando abaixo da media de trade

           //verificando se tem ordens buy abertas (usando 0 tick de tolerância)...
           if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), "OPCL", m_vol_lote_ini , true, 0 ) ){
                
                #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(":-| MEDIA_TRADE ",DoubleToString(m_pmTra,2),".  Criando COMPRA a ",  precoOrdem," ", strPosicao());#endif
                
                if(precoOrdem!=0) {
                    sincro = m_trade.getAsync();
                    m_trade.setAsync(true);                    
                    if( m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, m_vol_lote_ini, "OPCL") ){
                        m_val_close_position_buy = precoOrdem + (m_tick_size*m_qtd_ticks_4_gain_ini);
                        m_vol_close_position_buy = m_vol_lote_ini;
                        m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT , m_val_close_position_buy, m_vol_lote_ini, "OPCL");
                    }
                    m_trade.setAsync(sincro);
                }
           }
       // nao cancelar por enquanto. entendo que esta ordem pode ganhar prioridade se o preco voltar
       // para o lado contrario do desbalanceamento.
       //}else{
       //     m_trade.cancelarOrdensComentadas(m_apmb);
       //     m_val_close_position_sel = 0;
       //     m_vol_close_position_sel = 0;
       //     m_val_close_position_buy = 0;
       //     m_vol_close_position_buy = 0;
       }
   }
}

//
// coloca duas ordens, sendo uma acima da media e outra abaixo da media.
// nao usa rajada.
//
void abrirPosicaoHFTNaMediaTrade(){

   double vol           = m_vol_lote_ini;
   double precoOrdem    = 0;
   double inclinacaoMin = 0.1;
   double shift         = 1;



     // entrada quando ask estah acima acima da media de trades e bid estah abaixo da media de trade.
     if(//m_qtdOrdens==0 && 
        ( (m_ask >= m_pmTra && m_ask <= m_pmTra+15) || (m_bid <= m_pmTra && m_bid >= m_pmTra-15) ) ){

       
       // processando em paralelo
       m_trade.setAsync(true);

       if( m_inclTra < 0 ) {
               // colocando a venda
               precoOrdem = m_ask;
             //precoOrdem = m_ask+m_tick_size;
             //precoOrdem = m_ask+m_tick_size*2;
               #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("HFT_VENDA_NS=",precoOrdem,". Criando ordem de VENDA.", strPosicao()," ...");#endif
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_ns );

               // colocando a compra
               precoOrdem = m_bid;
             //precoOrdem = m_bid-m_tick_size;
             //precoOrdem = m_bid-m_tick_size*2;
               #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("HFT_COMPRA_NS=",precoOrdem,". Criando ordem de COMPRA.", strPosicao()," ...");#endif
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, m_apmb_ns );
       }else{
               // colocando a compra
               precoOrdem = m_bid;
             //precoOrdem = m_bid-m_tick_size;
             //precoOrdem = m_bid-m_tick_size*2;
               #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("HFT_COMPRA_NS=",precoOrdem,". Criando ordem de COMPRA.", strPosicao()," ...");#endif
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, m_apmb_ns );

               // colocando a venda
               precoOrdem = m_ask;
             //precoOrdem = m_ask+m_tick_size;
             //precoOrdem = m_ask+m_tick_size*2;
               #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("HFT_VENDA_NS=",precoOrdem,". Criando ordem de VENDA.", strPosicao()," ...");#endif
               if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb_ns );
       }

       m_trade.setAsync(false);
    }
}

bool taxaVolumeEstahL1          (){return EA_VOLSEG_L1               >0 && m_volTradePorSeg <= EA_VOLSEG_L1   ;}
bool taxaVolumeEstahL2          (){return EA_VOLSEG_L2               >0 && m_volTradePorSeg <= EA_VOLSEG_L2   && m_volTradePorSeg > EA_VOLSEG_L1;}
bool taxaVolumeEstahL3          (){return EA_VOLSEG_L3               >0 && m_volTradePorSeg <= EA_VOLSEG_L3   && m_volTradePorSeg > EA_VOLSEG_L2;}
bool taxaVolumeEstahL4          (){return EA_VOLSEG_L4               >0 && m_volTradePorSeg <= EA_VOLSEG_L4   && m_volTradePorSeg > EA_VOLSEG_L3;}
bool taxaVolumeEstahL5          (){return EA_VOLSEG_L5               >0 && m_volTradePorSeg <= EA_VOLSEG_L5   && m_volTradePorSeg > EA_VOLSEG_L4;}
bool taxaVolPermiteAbrirPosicao (){return EA_VOLSEG_MAX_ENTRADA_POSIC>0 && m_volTradePorSeg <= EA_VOLSEG_MAX_ENTRADA_POSIC ;}
bool taxaVolumeEstahAlta        (){return EA_VOLSEG_ALTO             >0 && m_volTradePorSeg >  EA_VOLSEG_ALTO              ;}

bool volatilidadeEstahAlta      (){return m_volatilidade   >  EA_VOLAT_ALTA    ;}
bool volatilidadeEstahAltaDemais(){return m_volatilidade   >  EA_VOLAT_ALTA+0.3;}

//bool volatilidadeEstahBaixa   (){return m_volatilidade      < EA09_VOLAT_BAIXA     ;}
//bool volatilidadeEstahMedia   (){return m_volatilidade      >  m_volBaixa && m_volatilidade <  m_volBaixa ;}








bool m_fastClose     = true;
bool m_traillingStop = false;
void setFastClose()    { m_fastClose=true ; m_traillingStop=false; m_inclEntrada = m_inclTra;}
void setTraillingStop(){ m_fastClose=false; m_traillingStop=true ;}




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
           #ifndef COMPILE_PRODUCAO 
               if(EA_DEBUG)Print(m_name,":COMPRADO: [OPEN "   ,m_precoPosicao,
                                        "][LENSTOP ",lenstop       ,
                                        "][SL "     ,sl            ,
                                        "][BID "    ,bid            ,
                                        "][m_tstop ",m_tstop,
                                        "][profit " ,m_posicaoProfit,
                                        "][sldstop ",m_tstop-m_precoPosicao,"]")
           ;#endif
           //if( !HLineMove(0,m_line_tstop,m_tstop) ){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
           //ChartRedraw(0);
      }
   }else{
      if( estouVendido() ){
         //sl = last + dxsl;
         sl = ask + lenstop;
         if ( m_tstop > sl || m_tstop == 0 ) {
              m_tstop = sl;
              #ifndef COMPILE_PRODUCAO 
                  if(EA_DEBUG)Print(m_name,":VENDIDO: [OPEN ",m_precoPosicao,
                                           "][LENSTOP ",lenstop,
                                           "][SL "     ,sl            ,
                                           "][ASK "    ,ask            ,
                                           "][m_tstop ",m_tstop,
                                           "][profit ",m_posicaoProfit,
                                           "][sldstop ",m_precoPosicao-m_tstop,"]");
              #endif
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
       #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("TSTOP COMPRADO: bid:"+DoubleToString(bid,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );#endif
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       //HLineDelete(0,m_line_tstop);
       //ChartRedraw(0);

       return true;
   }
   if( ( estouVendido() && m_tstop != 0 ) &&
       ( ( ask > m_tstop && ask < m_precoPosicao ) )
     ){
       #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("TSTOP VENDIDO: ask:"+DoubleToString(ask,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );#endif
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
           #ifndef COMPILE_PRODUCAO
               if(EA_DEBUG)Print(m_name,":COMPRADO2: [OPEN "   ,m_precoPosicao,
                                      "][LENSTOP ",lenstop       ,
                                      "][SL "     ,sl            ,
                                      "][BID "    ,bid            ,
                                      "][m_tstop ",m_tstop,
                                      "][profit " ,m_posicaoProfit,
                                      "][sldstop ",m_tstop-m_precoPosicao,"]");
          #endif
      }
   }else{
      if( m_trade.estouVendido() ){
         sl = ask + lenstop + m_symb.Spread();
         if ( m_tstop > sl || m_tstop == 0 ) {
              m_tstop = sl;
              #ifndef COMPILE_PRODUCAO
                  if(EA_DEBUG)Print(m_name,":VENDIDO2: [OPEN ",m_precoPosicao,
                                        "][LENSTOP ",lenstop,
                                        "][SL "     ,sl            ,
                                        "][ASK "    ,ask            ,
                                        "][m_tstop ",m_tstop,
                                        "][profit " ,m_posicaoProfit,
                                        "][sldstop ",m_precoPosicao-m_tstop,"]");
              #endif
         }
      }
   }

   // acionando o trailling stop...
   if( ( estouComprado() && m_tstop != 0        )  &&
       ( ( bid < m_tstop && ask > m_precoPosicao ) )
     ){
       #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("TSTOP2 COMPRADO2: bid:"+DoubleToString(bid,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );#endif
       fecharPosicao("TRLSTP2");

       return true;
   }
   if( ( estouVendido() && m_tstop != 0 ) &&
       ( ( ask > m_tstop && ask < m_precoPosicao ) )
     ){
       #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print("TSTOP2 VENDIDO2: ask:"+DoubleToString(ask,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" ); #endif
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
                                          Print(m_name,":-| Expert ", m_name, " Iniciando metodo OnDeinit..." );
    EventKillTimer();                     Print(m_name,":-| Expert ", m_name, " Timer destruido." );
    m_feira.DeleteFromChart(0,0);         Print(m_name,":-| Expert ", m_name, " Indicador feira retirado do grafico." );
    IndicatorRelease( m_feira.Handle() ); Print(m_name,":-| Expert ", m_name, " Manipulador do indicador feira liberado." );
    IndicatorRelease( m_icci.Handle()  ); Print(m_name,":-| Expert ", m_name, " Manipulador do indicador cci   liberado." );
    //IndicatorRelease( m_ibb.Handle()    );
                                          Print(m_name,":-) Expert ", m_name, " OnDeinit finalizado!" );
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
//|                                                           |
//+-----------------------------------------------------------+
void OnTradex(){

      if( m_fechando_posicao && m_ordem_fechamento_posicao > 0 ){

              if( HistoryOrderSelect(m_ordem_fechamento_posicao) ){

                     ENUM_ORDER_STATE order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
                     if( order_state == ORDER_STATE_FILLED   ||    //Ordem executada completamente
                         order_state == ORDER_STATE_REJECTED ||    //Ordem rejeitada
                         order_state == ORDER_STATE_EXPIRED  ||    //Ordem expirada
                         order_state == ORDER_STATE_CANCELED ){    //Ordem cancelada pelo cliente

                         #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print( ":-| Ordem de fechamento de posicao CONCLUIDA! ticket=", m_ordem_fechamento_posicao, " status=", EnumToString(order_state), strPosicao() );#endif
                         m_fechando_posicao         = false;
                         m_ordem_fechamento_posicao = 0;
                     }else{
                         #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print( ":-| Ordem de fechamento de posicao PENDENTE! ticket=", m_ordem_fechamento_posicao, " status=", EnumToString(order_state), strPosicao() );#endif
                     }
              }else{
                     #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print( ":-| Ordem de fechamento de posicao NAO ENCONTRADA! ticket=", m_ordem_fechamento_posicao, strPosicao() );#endif
                     m_fechando_posicao         = false;
                     m_ordem_fechamento_posicao = 0;
              }
      }
}

string strFuncNormal(string str){ return ":-| " + str + " "; }

//+-----------------------------------------------------------+
//|                                                           |
//+-----------------------------------------------------------+
void OnTradeTransactionXXX( const MqlTradeTransaction& tran,    // transacao
                            const MqlTradeRequest&     req ,    // request
                            const MqlTradeResult&      res   ){ // result
/*
    // colocacao das ordens de abertura de posicao...
    if( m_qtdPosicoes==0 && (m_abrindo_posicao == false || m_ordem_abertura_posicao_sel==0 || m_ordem_abertura_posicao_buy==0) ){
        // pode ser detectado em TRADE_TRANSACTION_REQUEST
        if( tran.type == TRADE_TRANSACTION_REQUEST ){
        
            //ordem de abertura de posicao vendida...
            if( StringFind( req.comment, m_apmb_sel ) > -1 ){
                m_ordem_abertura_posicao_sel = res.order;
                m_abrindo_posicao            = true;
                if(EA_DEBUG)Print(strFuncNormal(__FUNCTION__+" CTRLPOS"), "OPENED_ORD SEL=", m_ordem_abertura_posicao_sel, " mudei status para ABRINDO_POSICAO.");
            //ordem de abertura de posicao comprada...
            }else if( StringFind( req.comment, m_apmb_buy ) > -1 ){
                m_ordem_abertura_posicao_buy = res.order;
                m_abrindo_posicao            = true;
                if(EA_DEBUG)Print(strFuncNormal(__FUNCTION__+" CTRLPOS"), "OPENED_ORD BUY=", m_ordem_abertura_posicao_buy, " mudei status para ABRINDO_POSICAO.");
            }
        // tambem pode ser detectado em TRADE_TRANSACTION_ORDER_ADD
        }else if(tran.type == TRADE_TRANSACTION_ORDER_ADD){
            //ordem de abertura de posicao vendida...
            if( tran.order_type==ORDER_TYPE_SELL_LIMIT ){
                m_ordem_abertura_posicao_sel = tran.order;
                m_abrindo_posicao            = true;
                if(EA_DEBUG)Print(strFuncNormal(__FUNCTION__+" CTRLPOS"), "OPENED_ORD SEL=", m_ordem_abertura_posicao_sel, " mudei status para ABRINDO_POSICAO.");
            //ordem de abertura de posicao comprada...
            }else if( tran.order_type==ORDER_TYPE_BUY_LIMIT ){
                m_ordem_abertura_posicao_buy = tran.order;
                m_abrindo_posicao            = true;
                if(EA_DEBUG)Print(strFuncNormal(__FUNCTION__+" CTRLPOS"), "OPENED_ORD BUY=", m_ordem_abertura_posicao_buy, " mudei status para ABRINDO_POSICAO.");
            }
        }
    }else
*/    
    // execucao das ordens de abertura de posicao...
    if( m_qtdPosicoes==0 && tran.type == TRADE_TRANSACTION_DEAL_ADD){
        if( tran.order == m_ordem_abertura_posicao_sel ){
            // fechar a venda.
            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(strFuncNormal(__FUNCTION__+" CTRLPOS"),"OPENED_POS SEL! Chamando closeRajada para fechar a posicao!");#endif
            doCloseRajada(m_passo_rajada,1,m_qtd_ticks_4_gain_ini,true );
        }else if( tran.order == m_ordem_abertura_posicao_buy ){
            // fechar a compra.
            #ifndef COMPILE_PRODUCAO if(EA_DEBUG)Print(strFuncNormal(__FUNCTION__+" CTRLPOS"),"OPENED_POS BUY! Chamando closeRajada para fechar a posicao!");#endif
            doCloseRajada(m_passo_rajada,1,m_qtd_ticks_4_gain_ini,false);
        }
    }
    
/*    
    // cancelamento das ordens de abertura de posicao...
    else if( tran.type == TRADE_TRANSACTION_ORDER_DELETE ){
    
       if( tran.order_state==ORDER_STATE_CANCELED ){
           if( tran.order==m_ordem_abertura_posicao_buy ){
               m_ordem_abertura_posicao_buy = 0;
               if(EA_DEBUG)Print(strFuncNormal(__FUNCTION__+" CTRLPOS"),"CANCELED_ORD BUY=",tran.order);
           }else if( tran.order==m_ordem_abertura_posicao_sel ){
               m_ordem_abertura_posicao_sel = 0; 
               if(EA_DEBUG)Print(strFuncNormal(__FUNCTION__+" CTRLPOS"),"CANCELED_ORD SEL=",tran.order);
           }
       }    
    }
*/        
/*    
    // tem uma ordem de fechamento de posicao pendente...
    if( m_fechando_posicao == true && m_ordem_fechamento_posicao > 0 ){

        if( tran.order == m_ordem_fechamento_posicao ){
            if(       tran.type == TRADE_TRANSACTION_ORDER_DELETE ){
                if(EA_DEBUG)Print( strFuncNormal(__FUNCTION__+" CTRLPOS"),"ORD close position DEL! tkt=", m_ordem_fechamento_posicao, "tktdeal=", tran.deal," state=", EnumToString(tran.order_state), " volDeal=",tran.volume, strPosicao() );
                m_fechando_posicao         = false;
                m_ordem_fechamento_posicao = 0;
            }else if( tran.type == TRADE_TRANSACTION_ORDER_ADD    ){
                if(EA_DEBUG)Print( strFuncNormal(__FUNCTION__+" CTRLPOS"),"ORD close position ADD! tkt=" , m_ordem_fechamento_posicao,                       " state=", EnumToString(tran.order_state), " volOrd=" ,tran.volume, strPosicao() );
            }else if( tran.type == TRADE_TRANSACTION_DEAL_ADD     ){
                if(EA_DEBUG)Print( strFuncNormal(__FUNCTION__+" CTRLPOS"),"ORD close position EXEC! tkt=", m_ordem_fechamento_posicao, "tktdeal=", tran.deal," state=", EnumToString(tran.order_state), " volDeal=",tran.volume, strPosicao() );
            }
        }    
    }
*/
/*
    if(EA_DEBUG)Print( strFuncNormal(__FUNCTION__)                           ,
           "TRAN"                                                ,
           " type="           ,EnumToString(tran.type           ),
           " vol="            ,             tran.volume          ,
           " deal="           ,             tran.deal            ,
           " deal_type="      ,EnumToString(tran.deal_type      ),
           " order="          ,             tran.order           ,
           " order_state="    ,EnumToString(tran.order_state    ),
           " order_type="     ,EnumToString(tran.order_type     ),
           " position="       ,             tran.position        ,
           " price="          ,             tran.price           ,
           " price_sl="       ,             tran.price_sl        ,
           " price_tp="       ,             tran.price_tp        ,
           " price_trigger="  ,             tran.price_trigger   ,
           " symbol="         ,             tran.symbol          ,
           " time_expiration=",             tran.time_expiration ,
           " time_type="      ,EnumToString(tran.time_type      ));

    if( tran.type == TRADE_TRANSACTION_REQUEST ){
        if(EA_DEBUG)Print(  strFuncNormal(__FUNCTION__)                    ,
                "REQ"                                          ,
                " type="        ,EnumToString(req.type        ),
                " action="      ,EnumToString(req.action      ),
                " vol="         ,             req.volume       ,
                " comment="     ,             req.comment      ,
                " expiration="  ,             req.expiration   ,
                " magic="       ,             req.magic        ,
                " order="       ,             req.order        ,
                " position="    ,             req.position     ,
              //" position_by=" ,             req.position_by  ,
                " price="       ,             req.price        ,
                " sl="          ,             req.sl           ,
                " stoplimit="   ,             req.stoplimit    ,
                " symbol="      ,             req.symbol       ,
                " tp="          ,             req.tp           ,
                " type_filling=",EnumToString(req.type_filling),
                " type_time="   ,             req.type_time    ,
                " deviation="   ,             req.deviation    );
    
        if(EA_DEBUG)Print( strFuncNormal(__FUNCTION__)                ,
               "RES"                                      ,
               " ask="             ,  res.ask             ,
               " bid="             ,  res.bid             ,
               " vol="             ,  res.volume          ,
               " comment="         ,  res.comment         ,
               " deal="            ,  res.deal            ,
               " order="           ,  res.order           ,
               " price="           ,  res.price           ,
               " request_id="      ,  res.request_id      ,
               " retcode="         ,  res.retcode         ,
               " retcode_external=",  res.retcode_external);
    }
    */
    //printf( strFuncNormal(__FUNCTION__)+"ACCOUNT_BALANCE=%G ACCOUNT_EQUITY=%G", AccountInfoDouble(ACCOUNT_BALANCE),
    //                                                    AccountInfoDouble(ACCOUNT_EQUITY ) );
            
    //printf( "ACCOUNT_CREDIT  = %G", AccountInfoDouble(ACCOUNT_CREDIT ) );
    //printf( "ACCOUNT_PROFIT  = %G", AccountInfoDouble(ACCOUNT_PROFIT ) );
    //printf( "ACCOUNT_EQUITY  = %G", AccountInfoDouble(ACCOUNT_EQUITY ) );
}


//----------------------------------------------------------------------------------------------------
// 
// 1. Atualizando as variaveis de tempo atual m_time_in_seconds e m_date.
// 2. Executa funcoes que dependem das variaveis m_time_in_seconds ou m_date atualizadas e 
//    suas respectivas anteriores atualizas.
// 3. Atualizando variaveis de comparacao de data anterior e atual m_time_in_seconds_ant e m_date_ant.
//
//----------------------------------------------------------------------------------------------------
bool        m_estah_no_intervalo_de_negociacao = false;
datetime    m_time_in_seconds_atu = TimeCurrent();
datetime    m_time_in_seconds_ant = m_time_in_seconds_atu;
MqlDateTime m_date_atu;
MqlDateTime m_date_ant;
//----------------------------------------------------------------------------------------------------
void OnTimer(){
    
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
    calcularAceleracaoVelTradeDeltaPorc();                                   // calculando aceleracao da %Delta da velocidade do volume de trade...
    
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
       m_acelVolTradePorSegDeltaPorc = ( (m_volTradePorSegDeltaPorc - m_vet_vel_volume[0])/m_vet_vel_volume_len )*10;
   //}
}
//----------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------
bool estah_no_intervalo_de_negociacao(){

    // informando a mudanca do dia (usada no controle do rebaixamento de saldo maximo da sessao).
    if( m_date_ant.day != m_date_atu.day ){ m_mudou_dia = true; }

    // restricao para nao operar no inicio nem no final do dia...
    if(m_date_atu.hour <   HR_INI_OPERACAO     ) {  return false; } // operacao antes de 9:00 distorce os testes.
    if(m_date_atu.hour >=  HR_FIM_OPERACAO + 1 ) {  return false; } // operacao apos    18:00 distorce os testes.

    if(m_date_atu.hour == HR_INI_OPERACAO && m_date_atu.min < MI_INI_OPERACAO ) { return false; } // operacao antes de 9:10 distorce os testes.
    if(m_date_atu.hour == HR_FIM_OPERACAO && m_date_atu.min > MI_FIM_OPERACAO ) { return false; } // operacao apos    17:50 distorce os testes.

    return true;
}
//----------------------------------------------------------------------------------------------------

/* BACKUP
bool estah_no_intervalo_de_negociacao(){

    TimeToStruct(TimeCurrent(),m_date);

    // informando a mudanca do dia (usada no controle do rebaixamento de saldo maximo da sessao).
    if( m_day != m_date.day ){ m_day = m_date.day; m_mudou_dia = true; }

    // restricao para nao operar no inicio nem no final do dia...
    if(m_date.hour <   HR_INI_OPERACAO     ) {  return false; } // operacao antes de 9:00 distorce os testes.
    if(m_date.hour >=  HR_FIM_OPERACAO + 1 ) {  return false; } // operacao apos    18:00 distorce os testes.

    if(m_date.hour == HR_INI_OPERACAO && m_date.min < MI_INI_OPERACAO ) { return false; } // operacao antes de 9:10 distorce os testes.
    if(m_date.hour == HR_FIM_OPERACAO && m_date.min > MI_FIM_OPERACAO ) { return false; } // operacao apos    17:50 distorce os testes.

    return true;
}
*/