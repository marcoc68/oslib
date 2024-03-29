﻿//+-------------------------------------------------------------------------------------------------------------------------+
//|                                       osc-exp-minion-01-001.mqh                                                         |
//|                                         Copyright 2019, OS Corp.                                                        |
//|                                                http://www.os.org                                                        |
//|                                                                                                                         |
//| Versao 01.001                                                                                                           |
//| 1. Classe com funcionalidades a serem executadas em EAs.                                                                |
//|                                                                                                                         |
//|    01-001 Primeira versão. Baseada no expert advisor 02-p6.                                                             |
//|                                                                                                                         |
//|    2. Para usar esta classe, faca assim:                                                                                |
//|    - Inclua seu arquivo com os parametros e a definicao da classe <oslib\osc\exp\osc-exp-minion-01-001-input-param.mqh> |
//|      Este arquivo define                                                                                                |
//|      - Parametros que serao recebidos pelo EA afim de calibrar a classe osc_minion_expert.                              |
//|      - Uma instancia da classe osc_minion_expert com nome de variavel "m_exp".                                          |
//|      - O metodo atualizarParametros() que passa os parametros recebidos pelo EA para dentro da classe osc_minion_expert.|
//|                                                                                                                         |
//|    - Para compilacao de producao, defina a variavel [#define COMPILE_PRODUCAO]. Sem esta definicao, a classe gerarah    |
//|      logs e atrasos na execucao de ordens. Se tornarah mais lenta para piorar as condicoes de operacao em teste.        |
//|      Apesar de mais lenta, poderah gravar detalhes de debug no log do terminal.                                         |
//|                                                                                                                         |
//|    - No metodo OnInit do EA, execute o metodo atualizarParametros() que estah definido no arquivo                       |
//|      <oslib\osc\exp\osc-exp-minion-01-001-input-param.mqh>. Este metodo passarah seus parametros pra dentro de m_exp.   |
//|                                                                                                                         |
//+-------------------------------------------------------------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

//#include <Indicators\Trend.mqh>
//#include <Indicators\Volumes.mqh>
//#include <Indicators\Oscilators.mqh>
#include <Generic\Queue.mqh>
#include <Generic\HashMap.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

#include <oslib\os-lib.mq5>
#include <oslib\osc-ind-minion-feira.mqh>
#include <oslib\osc-estatistic2.mqh>
#include <oslib\osc\osc-minion-trade-03.mqh>
#include <oslib\osc\osc-minion-trade-estatistica.mqh>
//#include <oslib\osc\cp\osc-pc-p6.mqh>                // painel de controle
#include <oslib\svc\osc-svc.mqh>
#include <oslib\svc\run\cls-run.mqh>

//#define SLEEP_PADRAO  50
//#define COMPILE_PRODUCAO

//enum ENUM_TIPO_ENTRADA_PERMITDA{
//     ENTRADA_NULA              , //ENTRADA_NULA  Nao permite abrir posicoes.
//     ENTRADA_BUY               , //ENTRADA_BUY   Soh abre posicoes de compra.
//     ENTRADA_SELL              , //ENTRADA_SELL  Soh abre posocoes de venda.
//     ENTRADA_TODAS               //ENTRADA_TODAS Abre qualquer tipo de posicao.
//};

/*
enum ENUM_TIPO_OPERACAO{
       NAO_OPERAR                           , //NAO_OPERAR EA não abre nem fecha posições, fica apenas atualizando os indicadores.
       FECHAR_POSICAO                       , //FECHAR_POSICAO EA fecha a posição aberta. Usar em caso de emergencia.
       FECHAR_POSICAO_POSITIVA              , //FECHAR_POSICAO_POSITIVA Igual a anterior, mas aguarda o saldo da posição ficar positivo pra fechar.
//     NAO_ABRIR_POSICAO                    , //NAO_ABRIR_POSICAO Pode ser usado para entrar manualmente e deixar o EA sair.
//     CONTRA_TEND_DURANTE_COMPROMETIMENTO  , //CONTRA_TEND_DURANTE_COMPROMETIMENTO Abre posicao, na direcao contraria, se o preco atingir a media de precos do book. Ex: abre posicao de venda de preco atingir a media de ofertas ask.
//     CONTRA_TEND_APOS_COMPROMETIMENTO     , //CONTRA_TEND_APOS_COMPROMETIMENTO Igual ao anterior, mas após o preco romper a media de ofertas do book.
//     CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR , //CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR Abre posicao contraria quando o preço passa o máximo ou mínimo da vela anterior.
//     HFT_DISTANCIA_PRECO                  , //DISTANCIA_PRECO Abre posicao contraria, se o preco se afastar X ticks do preço atual.
//     HFT_MAX_MIN_VOLAT                    , //MAX_MIN_VOLAT Abre posicao contraria, se o preco ultrapassar o preco maximo ou minimo do ultimo minuto.
//     HFT_TEND_CCI                         , //TEND_CCI Abre posicao a favor da tendencia, de acordo com o indicador CCI.
//     HFT_NA_TENDENCIA                     , //NA_TENDENCIA Abre posicao a favor da tendencia em funcao da inclinacao do preco medio.
       HFT_DESBALANC_BOOK                   , //DESBALANC_BOOK Abre posicao segundo desbalancemaneto das primeiras filas do book.
       HFT_DESBALANC_BOOKNS                 , //DESBALANC_BOOKNS Abre posicao segundo desbalancemaneto das primeiras filas do book.
//     HFT_NORTE_SUL                        , //NORTE_SUL Coloca as ordens de entrata e saida em paralelo.
//     HFT_MEDIA_TRADE                      , //MEDIA_TRADE
//     HFT_ARBITRAGEM_VOLUME                , //ARBITRAGEM_VOLUME
//     HFT_DISTANCIA_DA_MEDIA               , //DISTANCIA_DA_MEDIA: abre posicao a qtd_ticks_4_gain da media de trade (29/01/2020)
//     HFT_HIBRIDO_MAX_MIN_VOL_X_DISTANCIA_PRECO, //HIBRIDO_MAX_MIN_VOL_X_DISTANCIA_PRECO
       HFT_FLUXO_ORDENS                       //HFT_FLUXO_ORDENS, abre posicao se probabilidade de subir/descer for mais que parametro
//     HFT_REGIAO_CANAL_ENTRELACA           , //REGIAO_CANAL_ENTRELACA Abre posicao contraria, se o preco ultrapassar o preco maximo ou minimo do ultimo minuto.
//     HFT_PRIORIDADE_NO_BOOK               , //PRIORIDADE_NO_BOOK
//     HFT_BB_NA_TENDENCIA
};
*/
enum ENUM_TIPO_OPERACAO{
     NAO_OPERAR                           , //NAO_OPERAR EA não abre nem fecha posições, fica apenas atualizando os indicadores.
     FECHAR_POSICAO                       , //FECHAR_POSICAO EA fecha a posição aberta. Usar em caso de emergencia.
     FECHAR_POSICAO_POSITIVA              , //FECHAR_POSICAO_POSITIVA Igual a anterior, mas aguarda o saldo da posição ficar positivo pra fechar.
     NAO_ABRIR_POSICAO                    , //NAO_ABRIR_POSICAO Pode ser usado para entrar manualmente e deixar o EA sair.
     HFT_FLUXO_ORDENS                     ,  //HFT_FLUXO_ORDENS, abre posicao se probabilidade de subir/descer for mais que parametro
     HFT_DESBALANC_BOOK                   , //DESBALANC_BOOK Abre posicao segundo desbalancemaneto das primeiras filas do book.
     HFT_DESBALANC_BOOKNS                 , //DESBALANC_BOOKNS Abre posicao segundo desbalancemaneto das primeiras filas do book.
     HFT_PRIORIDADE_NO_BOOK               , //PRIORIDADE_NO_BOOK  P7-001
     HFT_PRIORIDADE_NO_BOOK2              , //PRIORIDADE_NO_BOOK2 P7-001
     HFT_ANALISE_PERIODO_ANTERIOR           //ANALISE_PERIODO_ANTERIOR P7-002
};

//---------------------------------------------------------------------------------------------
//input group "Gerais"
//#define MEA_ACAO_POSICAO FECHAR_POSICAO  //MEA_ABRIR_POSICAO:Forma de operacao do EA.
//#define MEA_SPREAD_MAXIMO_EM_TICKS   4   //EA_SPREAD_MAXIMO em ticks. Se for maior que o maximo, nao abre novas posicoes.
//
//input group "Volume por Segundo"
//input int EA_VOLSEG_MAX_ENTRADA_POSIC = 150; //VOLSEG_MAX_ENTRADA_POSIC: vol/seg maximo para entrar na posicao.

//input group "Volume Aporte"
//input int MEA_VOL_LOTE_INI   =     1;     //VOL_LOTE_INI_L1:Vol do lote a ser usado na abertura de posicao qd vol/seg eh L1.
//input int MEA_VOL_LOTE_RAJ   =     1;     //VOL_LOTE_RAJ_L1:Vol do lote a ser usado qd vol/seg eh L1.
//INPUT INT MEA_VOL_MARTINGALE =     false; //MARTINGALE: dobra a quantidade de ticks a cada passo.

//input group "Rajada"
//#define MEA_TAMANHO_RAJADA   3    //TAMANHO_RAJADA;

//input group "Passo Fixo"
//#define MEA_PASSO_RAJ                3 //PASSO_RAJ_L1:Incremento de preco, em tick, na direcao contraria a posicao;
//#define MEA_QTD_TICKS_4_GAIN_INI     3 //QTD_TICKS_4_GAIN_INI_L1:Qtd ticks para o gain qd vol/seg eh level 1;
//#define MEA_QTD_TICKS_4_GAIN_RAJ     3 //QTD_TICKS_4_GAIN_RAJ_L1:Qtd ticks para o gain qd vol/seg eh level 1;

//-------------------------------------------------------------------------------------------
//input group "Passo dinamico"
//#define MEA_PASSO_DINAMICO                      true //PASSO_DINAMICO:tamanho do passo muda em funcao da volatilidade
//#define MEA_PASSO_DINAMICO_PORC_T4G             1    //PASSO_DINAMICO_PORC_TFG: % do TFG para definir o passo.
//#define MEA_PASSO_DINAMICO_MIN                  1    //PASSO_DINAMICO_MIN:menor passo possivel.
//#define MEA_PASSO_DINAMICO_MAX                  15   //PASSO_DINAMICO_MAX:maior passo possivel.
//#define MEA_PASSO_DINAMICO_PORC_CANAL_ENTRELACA 0.02 //PASSO_DINAMICO_PORC_CANAL_ENTRELACA
//#define MEA_PASSO_DINAMICO_STOP_QTD_CONTRAT     3    //PASSO_DINAMICO_STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
//#define MEA_PASSO_DINAMICO_STOP_CHUNK           2    //PASSO_DINAMICO_STOP_CHUNK:tamanho do chunk.
//#define MEA_PASSO_DINAMICO_STOP_PORC_CANAL      1    //PASSO_DINAMICO_STOP_PORC_CANAL:porcentagem do canal, usada para calcular o stop_loss dinamico.
//#define MEA_PASSO_DINAMICO_STOP_REDUTOR_RISCO   1    //PASSO_DINAMICO_STOP_REDUTOR_RISCO:porcentagem sobre o tamanho do passo para iniciar saida da posicao.

//input group "Stops"
//#define MEA_STOP_TIPO_CONTROLE_RISCO 1     //TIPO_CONTROLE_RISCO, se 1, controle normal. Se 2, controle por proximidade do breakeven.
//#define MEA_STOP_TICKS_STOP_LOSS     15    //TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
//#define MEA_STOP_TICKS_TKPROF        30    //TICKS_TKPROF:Quantidade de ticks usados no take profit;
//#define MEA_STOP_REBAIXAMENTO_MAX    300   //REBAIXAMENTO_MAX:preencha com positivo.
//#define MEA_STOP_OBJETIVO_DIA        250   //OBJETIVO_DIA:para se saldo alcancar objetivo do dia.
//#define MEA_STOP_LOSS          -1200  //STOP_LOSS:Valor maximo de perda aceitavel;
//#define MEA_STOP_QTD_CONTRAT    10    //STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
//#define MEA_STOP_PORC_L1        1     //STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
//#define MEA_STOP_10MINUTOS           0     //10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
//#define MEA_STOP_TICKS_TOLER_SAIDA   1     //TICKS_TOLER_SAIDA: qtd de ticks a aguardar nas saidas stop;

//input group "Entrelacamento"
//#define MEA_ENTRELACA_PERIODO_COEF 6   //ENTRELACA_PERIODO_COEF: periodo p/calc coef entrelacamento.
//#define MEA_ENTRELACA_COEF_MIN     0.40//ENTRELACA_COEF_MIN em porcentagem.
//#define MEA_ENTRELACA_CANAL_MAX    30  //ENTRELACA_CANAL_MAX: tamanho maximo em ticks do canal de entrelacamento.
//#define MEA_ENTRELACA_CANAL_STOP   35  //ENTRELACA_CANAL_STOP:StopLoss se canal maior que este parametro.

//input group "Regiao de compra e venda"
//#define MEA_REGIAO_BUY_SELL       0.3   //REGIAO_BUY_SELL: regiao de compra e venda nas extremidades do canal de entrelacamento.
//#define MEA_USA_REGIAO_CANAL_DIA  false //USA_REGIAO_CANAL_DIA: usa a regiao do canal diario (true) ou canal de entrelacamento(false) para calcular regiao de compra venda.

//input group "volatilidade e inclinacoes"
//#define MEA_VOLAT_ALTA                1.5 //VOLAT_ALTA:Volatilidade a considerar alta(%). Calculada a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
//#define MEA_VOLAT4S_ALTA_PORC         1.0 //VOLAT4S_ALTA_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media abrir posicao.
//#define MEA_VOLAT4S_STOP_PORC         1.5 //VOLAT4S_STOP_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media para stopar.
//#define MEA_VOLAT4S_MIN               1.5 //VOLAT4S_MIN:Acima deste valor, nao abre posicao.
//#define MEA_INCL_ALTA                 0.9 //INCL_ALTA:Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
//#define MEA_INCL_MIN                  0.1 //INCL_MIN:Inclinacao minima para entrar no trade.
//#define MEA_MIN_DELTA_VOL             10  //MIN_DELTA_VOL:%delta vol minimo para entrar na posicao
//#define MEA_MIN_DELTA_VOL_ACELERACAO  1   //MIN_DELTA_VOL_ACELERACAO:Aceleracao minima da %delta vol para entrar na posicao

//input group "entrada na posicao"
//#define MEA_TOLERANCIA_ENTRADA        1   //TOLERANCIA_ENTRADA: algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao 

//input group "show_tela"
//#define MEA_SHOW_TELA                        false //SHOW_TELA:mostra valor de variaveis na tela;
//#define MEA_SHOW_TELA_LINHAS_ACIMA           0     //SHOW_TELA_LINHAS_ACIMA:permite impressao na parte inferior da tela;
//#define MEA_SHOW_STR_PERMISSAO_ABRIR_POSICAO false //SHOW_STR_PERMISSAO_ABRIR_POSICAO:condicoes p/abrir posicao;

//input group "diversos"
//#define MEA_DEBUG             false     //DEBUG:se true, grava informacoes de debug no log do EA.
//#define MEA_MAGIC             200102005 //MAGIC: Numero magico desse EA. yymmvvvvv.

////input group "estrategia distancia do preco"
////#define MEA_TICKS_ENTRADA_DIST_PRECO 1 //TICKS_ENTRADA_DIST_PRECO:Usado na entrada tipo HFT_DISTANCIA_PRECO. Distancia do preco para entrar na proxima posicao; .
////
////input group "estrategia distancia da media"
////#define MEA_TICKS_ENTRADA_DIST_MEDIA 2 //TICKS_ENTRADA_DIST_MEDIA:Usado na entrada tipo HFT_DISTANCIA_DA_MEDIA. Distancia da media para entrar na proxima posicao; .
////
////input group "estrategia HFT_FLUXO_ORDENS"
////#define MEA_PROB_UPDW                0.8 //PROB_UPDW:probabilidade do preco subir ou descer em funcao do fluxo de ordens;
//
//#define MEA_DOLAR_TARIFA             5.0 //DOLAR_TARIFA:usado para calcular a tarifa do dolar.
//
//input group "estrategia desbalanceamento"
//#define MEA_DESBALAN_UP0             0.8  //DESBALAN_UP0:Desbalanceamento na primeira fila do book para comprar na estrategia de desbalanceamento.
//#define MEA_DESBALAN_DW0             0.2  //DESBALAN_DW0:Desbalanceamento na primeira fila do book para vender  na estrategia de desbalanceamento.
//#define MEA_DESBALAN_UP1             0.7  //DESBALAN_UP1:Desbalanceamento na segunda fila do book para comprar na estrategia de desbalanceamento.
//#define MEA_DESBALAN_DW1             0.3  //DESBALAN_DW1:Desbalanceamento na segunda fila do book para vender  na estrategia de desbalanceamento.
//#define MEA_DESBALAN_UP2             0.65 //DESBALAN_UP2:Desbalanceamento na terceira fila do book para comprar na estrategia de desbalanceamento.
//#define MEA_DESBALAN_DW2             0.35 //DESBALAN_DW2:Desbalanceamento na terceira fila do book para vender  na estrategia de desbalanceamento.
//#define MEA_DESBALAN_UP3             0.6  //DESBALAN_UP3:Desbalanceamento na quarta fila do book para comprar na estrategia de desbalanceamento.
//#define MEA_DESBALAN_DW3             0.4  //DESBALAN_DW3:Desbalanceamento na quarta fila do book para vender  na estrategia de desbalanceamento.

//input group "estrategia HFT_PRIORIDADE_NO_BOOK"
//#define MEA_TICKS_ENTRADA_BOOK   4     //TICKS_ENTRADA_BOOK:fila do book onde iniciam as ordens.

//#define MEA_MAX_VOL_EM_RISCO   200        //EA01_MAX_VOL_EM_RISCO:Qtd max de contratos em risco; Sao os contratos pendentes da posicao.
//#define MEA04_DX_TRAILLING_STOP  1.0        //MEA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop

//---------------------------------------------------------------------------------------------
// configurando a banda de bollinguer...
//input group "indicador banda de bollinguer"
//#define BB_QTD_PERIODOS           21             //BB_QTD_PERIODOS.
//#define BB_DESVIOS                2              //BB_DESVIOS.
//#define BB_APLIED_PRICE           PRICE_WEIGHTED //BB_APLIED_PRICE.
//#define EA_LIMITE_ENTRADA_BBM     10             //LIMITE_ENTRADA_BBM
//#define EA_TIPO_ENTRADA_PERMITIDA ENTRADA_TODAS //TIPO_ENTRADA_PERMITIDA Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
//---------------------------------------------------------------------------------------------
// configurando a feira...
//input group "indicador feira"
//#define FEIRA07_GERAR_SQL_LOG    false  // Se true grava comandos sql no log para insert do book em tabela postgres.
//#define FEIRA01_DEBUG             false  // se true, grava informacoes de debug no log.
//#define FEIRA04_QTD_BAR_PROC_HIST 0      // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
//#define FEIRA05_BOOK_OUT          0      // Porcentagem das extremidades dos precos do book que serão desprezados.
//#define FEIRA99_ADD_IND_2_CHART   true   // Se true apresenta o idicador feira no grafico.

//#define MEA_EST_QTD_SEGUNDOS      60     // Quantidade de segundos que serao acumulads para calcular as medias.
//#define MEA_EST_PROCESSAR_BOOK    true   // MEA_EST_PROCESSAR_BOOK:se true, processa o book de ofertas.



//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
//input group "horario de operacao"
//#define MEA_HR_INI_OPERACAO   09 // Hora   de inicio da operacao;
//#define MEA_MI_INI_OPERACAO   30 // Minuto de inicio da operacao;
//#define MEA_HR_FIM_OPERACAO   18 // Hora   de fim    da operacao;
//#define MEA_MI_FIM_OPERACAO   50 // Minuto de fim    da operacao;
//---------------------------------------------------------------------------------------------
//
// group "sleep e timer"
//#define MEA_SLEEP_INI_OPER    60  //SLEEP_INI_OPER Aguarda estes segundos para iniciar abertura de posicoes.
//#define MEA_SLEEP_ATRASO      0   //SLEEP_TESTE_ONLINE atraso em milisegundos antes de enviar ordens.
//#define MEA_QTD_MILISEG_TIMER 250 //QTD_MILISEG_TIMER Tempo de acionamento do timer.
//---------------------------------------------------------------------------------------------

class osc_minion_expert{

private:
    osc_estatistic2 m_est;
    
    MqlDateTime   m_date;
    string        m_name;
    CSymbolInfo   m_symb                          ;
    CPositionInfo m_posicao                       ;
    CAccountInfo  m_cta                           ;
    double        m_tick_size                     ;// alteracao minima de preco.
    double        m_stopLossOrdens                ;// stop loss;
    double        m_tkprof                        ;// take profit;
    double        m_distMediasBook                ;// Distancia entre as medias Ask e Bid do book.
    
    osc_minion_trade             m_trade;
    osc_minion_trade_estatistica m_trade_estatistica;
  //osc_control_panel_p6         m_cp;
  //osc_ind_minion_feira*        m_feira;
    
    //int BB_SUPERIOR    ;
    //int BB_INFERIOR    ;
    //int BB_MEDIA       ;
    //int BB_DESCONHECIDA;
    
    //int m_ult_toque    ; // indica em que banda foi o ultimo toque do preco.
    //int m_pri_toque    ; // indica em que banda estah o primeiro toque de preco; A operacao eh aberta no primeiro toque na banda;
    //int m_ult_oper     ; // indica em que banda foi a ultima operacao;
    
    bool   m_comprado           ;
    bool   m_vendido            ;
  //double m_precoPosicao       ; // valor medio de entrada da posicao
    double m_posicaoVolumePend  ; // volume pendente pra fechar a posicao atual
    double m_posicaoVolumeTot   ; // volume total de contratos da posicao, inclusive os que jah foram fechados
    long   m_positionId         ;
    double m_volComprasNaPosicao; // quantidade de compras na posicao atual;
    double m_volVendasNaPosicao ; // quantidade de vendas  na posicao atual;
    double m_capitalInicial     ; // capital justamente antes de iniciar uma posicao
    double m_capitalLiquido     ; // capital atual durante a posicao.
    double m_lucroPosicao       ; // lucro da posicao atual
    double m_lucroPosicao4Gain  ; // lucro para o gain caso a quantidade de contratos tenha ultrapassado o valor limite.
    double m_lucroStops         ; // lucro acumulado durante stops de quantidade
    
    double m_tstop                 ;
    string m_positionCommentStr    ;
    long   m_positionCommentNumeric;
    
    //--- variaveis atualizadas pela funcao refreshMe...
    int    m_qtdOrdens         ;
    int    m_qtdPosicoes       ;
    double m_posicaoProfit     ;
    double m_ask               ;
    double m_bid               ;
    double m_val_order_4_gain  ;
    double m_max_barra_anterior;
    double m_min_barra_anterior;
    
    //--precos medios do book e do timesAndTrades
    double m_pmBid ;
    double m_pmAsk ;
    double m_pmBok ;
    double m_pmBuy ;
    double m_pmSel ;
    double m_pmTra ;
    
    // precos no periodo
    double m_phigh ; //-- preco maximo no periodo
    double m_plow  ; //-- preco minimo no periodo
    
    
    double m_comprometimento_up0;
    double m_comprometimento_dw0;
    
    //-- controle das inclinacoes
    double   m_inclSel    ;
    double   m_inclBuy    ;
    double   m_inclTra    ;
    double   m_inclBok    ;
  //double   m_inclEntrada; // inclinacao usada na entrada da operacao.
    
    string   m_apmb       ;//= "IN" ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
    string   m_apmb_sel   ;//= "INS"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
    string   m_apmb_buy   ;//= "INB"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
    string   m_apmb_ns    ;//= "INN"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
    string   m_strRajada  ;//= "RJ" ; //string que identifica rajadas de abertura de novas posicoes.
    MqlRates m_rates[];
    
    string   m_comment_fixo;
    string   m_comment_var ;
    
    double m_razaoVolReal;
    double m_razaoVolTick;
    
    double m_maior_sld_do_dia ;
    double m_sld_sessao_atu   ;
    double m_rebaixamento_atu ;
    int    m_day              ;
    bool   m_mudou_dia        ;
    bool   m_acionou_stop_rebaixamento_saldo;
    int    m_spread_maximo_in_points;
    
    int    m_ganhos_consecutivos;
    int    m_perdas_consecutivas;
    long   m_tempo_posicao_atu  ;
    long   m_tempo_posicao_ini  ;
    
    int    m_stop_qtd_contrat    ; // MEA_STOP_QTD_CONTRAT; Eh o tamanho do chunk;
    int    m_stop_chunk          ; // EA_STOP_CHUNK; Eh o tamanho do chunk;
    double m_stop_porc           ; // MEA_STOP_PORC_L1    ; Eh a porcentagem inicial para o ganho durante o passeio;
    int    m_qtd_ticks_4_gain_new;
    int    m_qtd_ticks_4_gain_ini;
    int    m_qtd_ticks_4_gain_raj;
    int    m_passo_rajada        ;
    double m_vol_lote_ini        ;
    double m_vol_lote_raj        ;
    
    // para acelerar a abertura da primeira ordem de fechamento a posicao
    double m_val_close_position_sel;
    double m_vol_close_position_sel;
    double m_val_close_position_buy;
    double m_vol_close_position_buy;
    
    // controle de fechamento de posicoes
    bool  m_fechando_posicao        ;
    ulong m_ordem_fechamento_posicao;
    
    // controle de abertura de posicoes
    bool  m_abrindo_posicao           ;
    ulong m_ordem_abertura_posicao_sel;
    ulong m_ordem_abertura_posicao_buy;
    
    // controles de apresentacao das variaveis de debug na tela...
    string m_str_linhas_acima ;
    string m_release          ;
    
    // variaveis usadas nas estrategias de entrada, visando diminuir a quantidade de alteracoes e cancelamentos com posterior criacao de ordens de entrada.
    double m_precoUltOrdemInBuy;
    double m_precoUltOrdemInSel;
    
    // string com o simbolo sendo operado
    string m_symb_str;
    
    // milisegundos que devem ser aguardados antes de iniciar a operacao
    int m_aguardar_para_abrir_posicao;
    
    // algumas estrategias permitem uma tolerancia do preco para entrada na posicao...
    double m_shift;
    
    datetime m_time_in_seconds_ini_day;

    double m_len_canal_ofertas       ; // tamanho do canal de oefertas do book.
    double m_len_barra_atual         ; // tamanho da barra de trades atual.
    double m_volatilidade            ; // calculamos a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
    double m_volatilidade_4_seg      ; // volatilidade por segundo.
    double m_volatilidade_4_seg_media; // volatilidade por segundo media.
    double m_volatilidade_4_seg_qtd  ; // qtd   de registros da volatilidade por segundo. Usado para calcular a volatilidade por segundo media.
    double m_volatilidade_4_seg_tot  ; // soma dos registros da volatilidade por segundo. Usado para calcular a volatilidade por segundo media.
    
    double m_volTradePorSegMedio    ;
    double m_volTradePorSegQtd      ;
    double m_volTradePorSegTot      ;
    double m_volTradePorSeg         ; // volume de agressoes por segundo.
    double m_volTradePorSegBuy      ; // volume de agressoes de compra por segundo.
    double m_volTradePorSegSel      ; // volume de agressoes de venda  por segundo.
    int    m_volTradePorSegDeltaPorc; // % da diferenca do volume por segundo do vencedor. Se for positivo, o vencedor eh buy, se negativo eh sell. 
    double m_desbUp0                ;
    double m_desbUp1                ;
    double m_desbUp2                ;
    double m_desbUp3                ;
    
    ulong m_trefreshMe       ;
    ulong m_trefreshFeira    ;
    ulong m_trefreshCCI      ;
    ulong m_trefreshTela     ;
    ulong m_trefreshRates    ;
    ulong m_tcontarTransacoes;
    ulong m_tcloseRajada     ;
    
    bool m_estou_posicionado ;

//  double m_probAskDescer   ;
//  double m_probAskSubir    ;
//  double m_probBidDescer   ;
//  double m_probBidSubir    ;
    
    MqlTick m_tick_est;
    
    int m_passo_incremento;

    double m_passo_dinamico_porc_canal_entrelaca;
    double m_volat4s_alta_porc                  ;
    double m_volat4s_stop_porc                  ;
    double m_stopLossPosicao                    ;

    int m_qtd_print_debug;
    int m_tamanhoBook    ;

    double m_precoPosicao        ; // valor medio de entrada da posicao
    double m_precoPosicaoAnt     ;
    double m_precoSaidaPosicao   ;
    double m_precoSaidaPosicaoAnt;
    double m_saida_posicao       ;

    string m_deal_comment;
    double m_deal_vol    ;

    bool m_fastClose     ;
    bool m_traillingStop ;

    //----------------------------------------------------------------------------------------------------
    // variaveis usadas no onTimer().
    //----------------------------------------------------------------------------------------------------
    bool        m_estah_no_intervalo_de_negociacao;
    datetime    m_time_in_seconds_atu             ;
    datetime    m_time_in_seconds_ant             ;
    MqlDateTime m_date_atu                        ;
    MqlDateTime m_date_ant                        ;
    //----------------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas no metodo calcularAceleracaoVelTradeDeltaPorc();
    // 1. Faz o shift das velocidades de volume registradas e despreza a mais antiga
    // 2. Substitui a ultima velocidade pela mais atual
    // 3. Recalcula a aceleracao da velocidade do volume
    //----------------------------------------------------------------------------------------------------
    int    m_vet_vel_volume_len         ;
    double m_vet_vel_volume[60]         ;
    int    m_acelVolTradePorSegDeltaPorc;
    //----------------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas no metodo calcRun(int pLenChunk);
    //----------------------------------------------------------------------------------------------------
    string m_strRun         ;
    double m_indRunMais1Ant ;
    double m_indRunMenos1Ant;
    double m_indRunAnt      ;
    
    double m_indRunMais1  ;
    double m_indRunMenos1 ;
    double m_indRun       ;
    
    double m_indVarRunMais1 ;
    double m_indVarRunMenos1;
    double m_indVarRun      ;
    
    int    m_qtd_periodos_run;
    //----------------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas para apresentar as linhas de apresentacao do canal;
    //----------------------------------------------------------------------------------------------------
    string m_str_line_max_price               ;
    string m_str_line_min_price               ;
    string m_str_line_maior_preco_compra      ;
    string m_str_line_menor_preco_venda       ;
    string m_str_line_time_desde_entrelaca    ;
    bool   m_line_min_preco_criada            ;
    bool   m_line_max_preco_criada            ;
    bool   m_line_maior_preco_compra_criada   ;
    bool   m_line_menor_preco_venda_criada    ;
    bool   m_line_time_desde_entrelaca_criada ;

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas no metodo calcDistPrecoMaxMin();
    //----------------------------------------------------------------------------------------------------
    double m_dxPrecoMaxEmTicks               ; // distancia, em ticks, entre o preco maximo usado no calculo do entrelacamento e o preco atual;
    double m_dxPrecoMinEmTicks               ; // distancia, em ticks, entre o preco minimo usado no calculo do entrelacamento e o preco atual;
    double m_regiaoPrecoCompra               ;
    double m_regiaoPrecoVenda                ;
    double m_porcRegiaoOperacao              ; //0.20;
    double m_maxDistanciaEntrelacaParaOperar ; //1000;
    double m_stpDistanciaEntrelacamento      ;
    double m_maiorPrecoDeCompra              ;
    double m_menorPrecoDeVenda               ;
    //----------------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas no metodo calcOpenMaxMinDia();
    //----------------------------------------------------------------------------------------------------
    MqlRates m_ratesDia[1];
    double   m_direcaoDia ; //indica se o dia eh de alta ou baixa...
    //----------------------------------------------------------------------------------------------------

    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas no metodo calcCoefEntrelacamentoMedio();
    //|-------------------------------------------------------------------------------------
    double   m_coefEntrelaca                  ;
    double   m_coefEntrelacaInv               ;
    int      m_qtdPeriodoCoefEntrelaca        ;
    MqlRates m_ratesEntrelaca[]               ;
    double   m_maxPrecoCanal                  ;
    double   m_minPrecoCanal                  ;
    double   m_len_canal_operacional_em_ticks ;
    datetime m_time_desde_entrelaca           ;
    double   m_direcao_entre                  ; // indica se a barra total do entrelacamento eh de alta ou baixa...
    double   m_entrelacaMinParaOperar         ; // parametro inicial em 0.45
    //----------------------------------------------------------------------------------------------------

    // variaveis usadas no metodo traillingstop()
    double m_dx1;
    double ea_dx_trailling_stop; // % do DX1 para fazer o trailling stop
    
    // variaveis usadas no metodo showtela
    bool MEA_SHOW_TELA                       ;
    int  MEA_SHOW_TELA_LINHAS_ACIMA          ;
    bool MEA_SHOW_STR_PERMISSAO_ABRIR_POSICAO;
    bool MEA_SHOW_CANAL_PRECOS               ;

    // variaveis usadas para calcular o profit da posicao do mini-dolar.
    double MEA_DOLAR_TARIFA;

    // variaveis usadas para limitar a quantidade de ordens pendentes.
    int MEA_MAX_VOL_EM_RISCO;
    
    // variaveis usadas para controlar a classe estatistica2.
    int  MEA_EST_QTD_SEGUNDOS;
    bool MEA_EST_PROCESSAR_BOOK;
    
    // variaveis usadas para controlar os horarios de inicio e fim de operacao.
    int MEA_HR_INI_OPERACAO;
    int MEA_MI_INI_OPERACAO;
    int MEA_HR_FIM_OPERACAO;
    int MEA_MI_FIM_OPERACAO;
    
    // variaveis usadas controlar a permissao de abertura de posicoes logo apos a inicializacao do EA.
    int MEA_SLEEP_INI_OPER; // em segundos.
    
    // variaveis usadas para atrasar as operacoes visando piorar as condicoes de teste.
    int MEA_SLEEP_ATRASO;
    
    // variaveis usadas para definir o tempo de acionamento do timer. Em milisegundos.
    int MEA_QTD_MILISEG_TIMER;
    
    // variaveis usadas para controlar o fechamento de posicao.
    ENUM_TIPO_OPERACAO MEA_ACAO_POSICAO;
    
    // variaveis usadas para controlar o spread maximo permitido para abrir posicoes
    int MEA_SPREAD_MAXIMO_EM_TICKS;
    
    // variaveis usadas para controlar o volume maximo permitido para abrir posicoes
    int MEA_VOLSEG_MAX_ENTRADA_POSIC;
    
    // variaveis usadas para definir os volumes da entrada na posicao e das rajadas.
    double MEA_VOL_LOTE_INI; // 1     VOL_LOTE_INI:Vol do lote a ser usado na abertura de posicao.
    double MEA_VOL_LOTE_RAJ; // 1     VOL_LOTE_RAJ:Vol do lote a ser usado nas rajadas.
    bool   MEA_VOL_MARTINGALE  ; // false MARTINGALE  :soma 1 a quantidade de ticks a cada passo de rajada.
    
    // variaveis usadas para definir o tamanho das rajadas.
    int ea_tamanho_rajada;

    // variaveis usadas para definir o passo fixo de rajada.
    int MEA_PASSO_RAJ;
    int MEA_QTD_TICKS_4_GAIN_INI;
    int MEA_QTD_TICKS_4_GAIN_RAJ;

    // variaveis usadas para definir o passo dinamico.
    bool   MEA_PASSO_DINAMICO                      ; // true //PASSO_DINAMICO:tamanho do passo muda em funcao da volatilidade
    double MEA_PASSO_DINAMICO_PORC_T4G             ; // 1    //PASSO_DINAMICO_PORC_TFG: % do TFG para definir o passo.
    int    MEA_PASSO_DINAMICO_MIN                  ; // 1    //PASSO_DINAMICO_MIN:menor passo possivel.
    int    MEA_PASSO_DINAMICO_MAX                  ; // 15   //PASSO_DINAMICO_MAX:maior passo possivel.
    double MEA_PASSO_DINAMICO_PORC_CANAL_ENTRELACA ; // 0.02 //PASSO_DINAMICO_PORC_CANAL_ENTRELACA
    int    MEA_PASSO_DINAMICO_STOP_QTD_CONTRAT     ; // 3    //PASSO_DINAMICO_STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
    int    MEA_PASSO_DINAMICO_STOP_CHUNK           ; // 2    //PASSO_DINAMICO_STOP_CHUNK:tamanho do chunk.
    double MEA_PASSO_DINAMICO_STOP_PORC_CANAL      ; // 1    //PASSO_DINAMICO_STOP_PORC_CANAL:porcentagem do canal, usada para calcular o stop_loss dinamico.
    double MEA_PASSO_DINAMICO_STOP_REDUTOR_RISCO   ; // 1    //PASSO_DINAMICO_STOP_REDUTOR_RISCO:porcentagem sobre o tamanho do passo para iniciar saida da posicao.
    
    // variaveis usadas para controlar os stops.
    int    MEA_STOP_TIPO_CONTROLE_RISCO; //  1     //TIPO_CONTROLE_RISCO, se 1, controle normal. Se 2, controle por proximidade do breakeven.
    int    MEA_STOP_TICKS_STOP_LOSS    ; //  15    //TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
    int    MEA_STOP_TICKS_TKPROF       ; //  30    //TICKS_TKPROF:Quantidade de ticks usados no take profit;
    int    MEA_STOP_REBAIXAMENTO_MAX   ; //  300   //REBAIXAMENTO_MAX:preencha com positivo.
    int    MEA_STOP_OBJETIVO_DIA       ; //  250   //OBJETIVO_DIA:para se saldo alcancar objetivo do dia.
    int    MEA_STOP_LOSS          ; // -1200  //STOP_LOSS:Valor maximo de perda aceitavel;
    int    MEA_STOP_QTD_CONTRAT   ; //  10    //STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
    double MEA_STOP_PORC_L1       ; //  1     //STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
    int    MEA_STOP_10MINUTOS          ; //  0     //10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
    int    MEA_STOP_TICKS_TOLER_SAIDA  ; //  1     //TICKS_TOLER_SAIDA: qtd de ticks a aguardar nas saidas stop;

    // variaveis usadas para controlar o coficiente de "Entrelacamento"
    int    MEA_ENTRELACA_PERIODO_COEF; // 6   //ENTRELACA_PERIODO_COEF: periodo p/calc coef entrelacamento.
    double MEA_ENTRELACA_COEF_MIN    ; // 0.40//ENTRELACA_COEF_MIN em porcentagem.
    int    MEA_ENTRELACA_CANAL_MAX   ; // 30  //ENTRELACA_CANAL_MAX: tamanho maximo em ticks do canal de entrelacamento.
    int    MEA_ENTRELACA_CANAL_STOP  ; // 35  //ENTRELACA_CANAL_STOP:StopLoss se canal maior que este parametro.

    // variaveis usadas para controlar a "Regiao de compra e venda"
    double MEA_REGIAO_BUY_SELL     ; //  0.3   //REGIAO_BUY_SELL: regiao de compra e venda nas extremidades do canal de entrelacamento.
    bool   MEA_USA_REGIAO_CANAL_DIA; //  false //USA_REGIAO_CANAL_DIA: usa a regiao do canal diario (true) ou canal de entrelacamento(false) para calcular regiao de compra venda.

    // variaveis usadas para controlar a "volatilidade e inclinacoes"
    double MEA_VOLAT_ALTA              ; // 1.5 VOLAT_ALTA:Volatilidade a considerar alta(%). Calculada a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
    double MEA_VOLAT4S_ALTA_PORC       ; // 1.0 VOLAT4S_ALTA_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media abrir posicao.
    double MEA_VOLAT4S_STOP_PORC       ; // 1.5 VOLAT4S_STOP_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media para stopar.
    double MEA_VOLAT4S_MIN             ; // 1.5 VOLAT4S_MIN:Acima deste valor, nao abre posicao.
    double MEA_INCL_ALTA               ; // 0.9 INCL_ALTA:Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
    double MEA_INCL_MIN                ; // 0.1 INCL_MIN:Inclinacao minima para entrar no trade.
    int    MEA_MIN_DELTA_VOL           ; // 10  MIN_DELTA_VOL:%delta vol minimo para entrar na posicao
    int    MEA_MIN_DELTA_VOL_ACELERACAO; // 1   MIN_DELTA_VOL_ACELERACAO:Aceleracao minima da %delta vol para entrar na posicao

    // variaveis usadas para controlar a "entrada na posicao"
    int    MEA_TOLERANCIA_ENTRADA      ; //  1   TOLERANCIA_ENTRADA: algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao 

    // variaveis diversas
    bool MEA_DEBUG                     ; // false     DEBUG:se true, grava informacoes de debug no log do EA.
    long MEA_MAGIC                     ; // 200102005 MAGIC: Numero magico desse EA. yymmvvvvv.

public:
    int  oninit          ();
    void refreshMe       ();
    void definirPasso    ();
    void incrementarPasso();
    bool passoAutorizado (); 
    void inicializarVariaveisRecebidasPorParametro();
    
    int  porcentagem( double parte, double tot, int seTotZero);
    
    void fecharTudo    (string descr                                           );
    void fecharTudo    (string descr, string strLog, int qtdTicksDeslocamento=0);
    void fecharPosicao2(string descr, string strLog, int qtdTicksDeslocamento=0);    
    void cancelarOrdensRajada();
    
  //void   onBookEvent(const string &symbol);
    void   onTick                  ();
    bool   podeAbrirProsicao       ();
    string strPermissaoAbrirPosicao();

    bool   saldoRebaixouMaisQuePermitidoNoDia(){ return ( MEA_STOP_REBAIXAMENTO_MAX != 0 && m_trade_estatistica.getRebaixamentoSld () > MEA_STOP_REBAIXAMENTO_MAX ); }
    bool   saldoAtingiuObjetivoDoDia         (){ return ( MEA_STOP_OBJETIVO_DIA     != 0 && m_trade_estatistica.getProfitDiaLiquido() > MEA_STOP_OBJETIVO_DIA     ); }
    void   controlarRiscoDaPosicao2();
    bool   controlarRiscoDaPosicao ();
    double calcSaidaPosicao(double volumePosicao );
    
    string strPosicao();    
    bool   emLeilao(){return (m_ask<=m_bid);}
    string strEmLeilao(){ if(emLeilao()) return "SIM"; return "NAO";}
    
    bool   doOpenRajada         ( double passo, double volLimite, double volLote, double profit                   );
    bool   openOrdemRajadaVenda ( double passo, double volLimite, double volLote, double profit, double precoOrdem);
    bool   openOrdemRajadaCompra( double passo, double volLimite, double volLote, double profit, double precoOrdem);

    void   doCloseRajada        ( double passo,                   double volLote, double profit                 );
    bool   doCloseRajada2       ( double passo,                   double volLote, double profit, bool close_sell);

  //void calcStopLossPosicao(){ if( MEA_PASSO_DINAMICO ){ m_stopLossPosicao = (m_len_canal_operacional_em_ticks*m_tick_size)*-1; } }
    void calcStopLossPosicao(){ if( MEA_PASSO_DINAMICO ){ m_stopLossPosicao = (m_len_canal_operacional_em_ticks*MEA_PASSO_DINAMICO_STOP_PORC_CANAL)*-1; } }

    string getStrCommentEntrelac();
    string getStrCommentFluxo();
    string getStrCommentBook();
    string getStrComment();

  //bool taxaVolumeEstahL1          (){return EA_VOLSEG_L1                >0 && m_volTradePorSeg <= EA_VOLSEG_L1                                     ;}
  //bool taxaVolumeEstahL2          (){return EA_VOLSEG_L2                >0 && m_volTradePorSeg <= EA_VOLSEG_L2   && m_volTradePorSeg > EA_VOLSEG_L1;}
  //bool taxaVolumeEstahL3          (){return EA_VOLSEG_L3                >0 && m_volTradePorSeg <= EA_VOLSEG_L3   && m_volTradePorSeg > EA_VOLSEG_L2;}
  //bool taxaVolumeEstahL4          (){return EA_VOLSEG_L4                >0 && m_volTradePorSeg <= EA_VOLSEG_L4   && m_volTradePorSeg > EA_VOLSEG_L3;}
  //bool taxaVolumeEstahL5          (){return EA_VOLSEG_L5                >0 && m_volTradePorSeg <= EA_VOLSEG_L5   && m_volTradePorSeg > EA_VOLSEG_L4;}
  //bool taxaVolumeEstahAlta        (){return EA_VOLSEG_ALTO              >0 && m_volTradePorSeg >  EA_VOLSEG_ALTO                                   ;}
    bool taxaVolPermiteAbrirPosicao (){return MEA_VOLSEG_MAX_ENTRADA_POSIC==0 || m_volTradePorSeg <= MEA_VOLSEG_MAX_ENTRADA_POSIC                      ;}
    
    bool volatilidadeEstahAlta      (){return m_volatilidade       > MEA_VOLAT_ALTA                                  && MEA_VOLAT_ALTA       != 0;}
    bool volatilidade4segEstahAlta  (){return m_volatilidade_4_seg > m_volatilidade_4_seg_media*m_volat4s_alta_porc && m_volat4s_alta_porc != 0;}
    bool volat4sExigeStop           (){return m_volatilidade_4_seg > m_volatilidade_4_seg_media*m_volat4s_stop_porc && m_volat4s_stop_porc != 0;}

    bool volat4sPermiteAbrirPosicao   (){ return m_volatilidade_4_seg <= MEA_VOLAT4S_MIN ||  MEA_VOLAT4S_MIN == 0; }
    bool spreadMaiorQueMaximoPermitido(){ return m_symb.Spread() > m_spread_maximo_in_points && m_spread_maximo_in_points != 0; }
    
    void setFastClose()    { m_fastClose=true ; m_traillingStop=false; }//m_inclEntrada = m_inclTra;}
    void setTraillingStop(){ m_fastClose=false; m_traillingStop=true ;}
    
    bool doTraillingStop();
    bool doTraillingStop2();
    
    double normalizar(double preco){  return m_symb.NormalizePrice(preco); }
    
//    bool precoPosicaoAbaixoDaMedia(){ return m_precoPosicao < m_ibb.Base(0) ;}
//    bool precoPosicaoAcimaDaMedia (){ return m_precoPosicao > m_ibb.Base(0) ;}
//    
//    bool precoNaMedia             (){ return m_symb.Last() < m_ibb.Base(0) + m_tick_size &&
//                                             m_symb.Last() > m_ibb.Base(0) - m_tick_size    ;}
//    
//    bool precoNaBandaInferior     (){ return m_symb.Ask() < m_ibb.Lower(0) + m_tick_size &&
//                                             m_symb.Ask() > m_ibb.Lower(0) - m_tick_size    ;}
//    
//    bool precoAbaixoBandaInferior (){ return m_symb.Ask() < m_ibb.Lower(0) + m_tick_size;}
//    
//    bool precoNaBandaSuperior     (){ return m_symb.Bid() < m_ibb.Upper(0) + m_tick_size &&
//                                             m_symb.Bid() > m_ibb.Upper(0) - m_tick_size    ;}
//    
//    bool precoAcimaBandaSuperior  (){ return m_symb.Bid() > m_ibb.Upper(0) - m_tick_size;}
    
    void fecharPosicao (string comentario){ m_trade.fecharQualquerPosicao (comentario); setSemPosicao(); }
    void cancelarOrdens(string comentario){ m_trade.cancelarOrdens        (comentario); setSemPosicao(); }
    
    void setCompradoSoft(){ m_comprado = true ; m_vendido = false; }
    void setVendidoSoft() { m_comprado = false; m_vendido = true ; }
    void setComprado()    { m_comprado = true ; m_vendido = false; m_tstop = 0;}
    void setVendido()     { m_comprado = false; m_vendido = true ; m_tstop = 0;}
    void setSemPosicao()  { m_comprado = false; m_vendido = false; m_tstop = 0;}
    
    bool estouComprado(){ return m_comprado; }
    bool estouVendido (){ return m_vendido ; }

    string status();

    void   onDeinit(const int reason);
    double onTester(){ m_trade_estatistica.print_posicoes(0, m_time_in_seconds_atu); return 0; }
    void   onTradex();
    void   onTimer();
    
    string strFuncNormal(string str){ return ":-| " + str + " "; }
    void   printHeartBit()          { if(m_date_ant.min != m_date_atu.min) Print(":-| HeartBit!"); }

    //----------------------------------------------------------------------------------------------------
    // 1. Faz o shift das velocidades de volume registradas e despreza a mais antiga
    // 2. Substitui a ultima velocidade pela mais atual
    // 3. Recalcula a aceleracao da velocidade do volume
    //----------------------------------------------------------------------------------------------------
    void calcularAceleracaoVelTradeDeltaPorc();
    //----------------------------------------------------------------------------------------------------
    
    bool estah_no_intervalo_de_negociacao();
    void controlarTimerParaAbrirPosicao();
    void onChartEvent(const int    id     , 
                      const long   &lparam, 
                      const double &dparam, 
                      const string &sparam);

    void calcRun(int pLenChunk);

    //----------------------------------------------------------------------------------------------------
    // 0. metodos usados para apresentar as linhas de apresentacao do canal;
    //----------------------------------------------------------------------------------------------------
    void drawLineMaxPreco          ();
    void drawLineMinPreco          ();
    void drawLineMaiorPrecoCompra  ();
    void drawLineMenorPrecoVenda   ();
    void drawLineTimeDesdeEntrelaca();
    void delLineMinPreco           ();
    void delLineMaxPreco           ();
    void delLineTimeDesdeEntrelaca ();
    void delLineMaiorPrecoCompra   ();
    void delLineMenorPrecoVenda    ();
    //----------------------------------------------------------------------------------------------------

    void calcDistPrecoMaxMin                ();
    void calcMaiorPrecoDeCompraVenda        ();
    bool regiaoPrecoPermiteCompra           (){return m_regiaoPrecoCompra              <= m_porcRegiaoOperacao              || m_porcRegiaoOperacao             ==0;}
    bool regiaoPrecoPermiteVenda            (){return m_regiaoPrecoVenda               <= m_porcRegiaoOperacao              || m_porcRegiaoOperacao             ==0;}
    bool distaciaEntrelacamentoPermiteOperar(){return m_len_canal_operacional_em_ticks <= m_maxDistanciaEntrelacaParaOperar || m_maxDistanciaEntrelacaParaOperar==0;}
    bool distaciaEntrelacamentoDeveStopar   (){return m_len_canal_operacional_em_ticks >  m_stpDistanciaEntrelacamento      && m_stpDistanciaEntrelacamento     !=0;}
    bool entrelacamentoDeBaixa              (){return m_direcao_entre < 0;}
    bool entrelacamentoDeAlta               (){return m_direcao_entre > 0;}

    //|-------------------------------------------------------------------------------------
    //| O coeficiente de entrelacamento eh a porcentagem de intersecao do preco da barra
    //| atual em relacao a barra anterior.
    //| Esta funcao retorna o coeficiente de entrelacacamento medio dos ultimos x periodos 
    //|-------------------------------------------------------------------------------------
    void   calcCoefEntrelacamentoMedio();
    void   calcOpenMaxMinDia();
    bool   entrelacamentoPermiteAbrirPosicao(){ return m_coefEntrelaca >= m_entrelacaMinParaOperar || m_entrelacaMinParaOperar == 0; }
    double calcCoefEntrelacamento(double minAnt, double maxAnt, double minAtu, double maxAtu);

    void initialize();
    void showTela();
    
    void setShowTela            (bool               v){ MEA_SHOW_TELA                       =v;} bool   getShowTela            (){return MEA_SHOW_TELA                       ;}
    void setShowTelaLinhasAcima (int                v){ MEA_SHOW_TELA_LINHAS_ACIMA          =v;} int    getShowTelaLinhasAcima (){return MEA_SHOW_TELA_LINHAS_ACIMA          ;}
    void setShowTelaPermOpenPos (bool               v){ MEA_SHOW_STR_PERMISSAO_ABRIR_POSICAO=v;} bool   getShowTelaPermOpenPos (){return MEA_SHOW_STR_PERMISSAO_ABRIR_POSICAO;}
    void setShowCanalPrecos     (bool               v){ MEA_SHOW_CANAL_PRECOS               =v;} bool   getShowCanalPrecos     (){return MEA_SHOW_CANAL_PRECOS               ;}
    
    
    
    void setDolarTarifa         (double             v){ MEA_DOLAR_TARIFA                    =v;} double getDolarTarifa         (){return MEA_DOLAR_TARIFA                    ;}
    void setMaxVolEmRisco       (int                v){ MEA_MAX_VOL_EM_RISCO                =v;} int    getMaxVolEmRisco       (){return MEA_MAX_VOL_EM_RISCO                ;}
    void setDxTraillingStop     (double             v){ ea_dx_trailling_stop                =v;} double getDxTraillingStop     (){return ea_dx_trailling_stop                ;}

    void setEstQtdSegundos      (int                v){ MEA_EST_QTD_SEGUNDOS        =v;} int                getEstQtdSegundos     (){return MEA_EST_QTD_SEGUNDOS        ;}
    void setEstProcessarBook    (bool               v){ MEA_EST_PROCESSAR_BOOK      =v;} bool               getEstProcessarBook   (){return MEA_EST_PROCESSAR_BOOK      ;}
    void setHrIniOperacao       (int                v){ MEA_HR_INI_OPERACAO         =v;} int                getHrIniOperacao      (){return MEA_HR_INI_OPERACAO         ;}
    void setMiIniOperacao       (int                v){ MEA_MI_INI_OPERACAO         =v;} int                getMiIniOperacao      (){return MEA_MI_INI_OPERACAO         ;}
    void setHrFimOperacao       (int                v){ MEA_HR_FIM_OPERACAO         =v;} int                getHrFimOperacao      (){return MEA_HR_FIM_OPERACAO         ;}
    void setMiFimOperacao       (int                v){ MEA_MI_FIM_OPERACAO         =v;} int                getMiFimOperacao      (){return MEA_MI_FIM_OPERACAO         ;}
    void setSleepIniOper        (int                v){ MEA_SLEEP_INI_OPER          =v;} int                getSleepIniOper       (){return MEA_SLEEP_INI_OPER          ;}
    void setSleepAtraso         (int                v){ MEA_SLEEP_ATRASO            =v;} int                getSleepAtraso        (){return MEA_SLEEP_ATRASO            ;}
    void setQtdMiliSegTimer     (int                v){ MEA_QTD_MILISEG_TIMER       =v;} int                getQtdMiliSegTimer    (){return MEA_QTD_MILISEG_TIMER       ;}
    void setAcaoPosicao         (ENUM_TIPO_OPERACAO v){ MEA_ACAO_POSICAO            =v;} ENUM_TIPO_OPERACAO getAcaoPosicao        (){return MEA_ACAO_POSICAO            ;}
    void setSpreadMaximoEmTicks (int                v){ MEA_SPREAD_MAXIMO_EM_TICKS  =v;} int                getSpreadMaximoEmTicks(){return MEA_SPREAD_MAXIMO_EM_TICKS  ;}
    void setVolSegMaxEntradaPos (int                v){ MEA_VOLSEG_MAX_ENTRADA_POSIC=v;} int                getVolSegMaxEntradaPos(){return MEA_VOLSEG_MAX_ENTRADA_POSIC;}
 
    void setVolLoteIni          (double             v){MEA_VOL_LOTE_INI             =v;} double getVolLoteIni      (){return MEA_VOL_LOTE_INI        ;}
    void setVolLoteRaj          (double             v){MEA_VOL_LOTE_RAJ             =v;} double getVolLoteRaj      (){return MEA_VOL_LOTE_RAJ        ;}
    void setVolMartingale       (bool               v){MEA_VOL_MARTINGALE           =v;} bool   getVolMartingale   (){return MEA_VOL_MARTINGALE      ;}
    void setTamanhoRajada       (int                v){ea_tamanho_rajada            =v;} int    getTamanhoRajada   (){return ea_tamanho_rajada       ;}
    void setPassoRajada         (int                v){MEA_PASSO_RAJ                =v;} int    getPassoRajada     (){return MEA_PASSO_RAJ           ;}
    void setQtdTicks4GainIni    (int                v){MEA_QTD_TICKS_4_GAIN_INI     =v;} int    getQtdTicks4GainIni(){return MEA_QTD_TICKS_4_GAIN_INI;}
    void setQtdTicks4GainRaj    (int                v){MEA_QTD_TICKS_4_GAIN_RAJ     =v;} int    getQtdTicks4GainRaj(){return MEA_QTD_TICKS_4_GAIN_RAJ;}

   // variaveis usadas para controlar o passo dinamico.
    void   setPassoDinamico                   (bool   v){MEA_PASSO_DINAMICO                      =v;} // true; //PASSO_DINAMICO:tamanho do passo muda em funcao da volatilidade
    void   setPassoDinamicoPorcT4G            (double v){MEA_PASSO_DINAMICO_PORC_T4G             =v;} // 1   ; //PASSO_DINAMICO_PORC_TFG: % do TFG para definir o passo.
    void   setPassoDinamicoMin                (int    v){MEA_PASSO_DINAMICO_MIN                  =v;} // 1   ; //PASSO_DINAMICO_MIN:menor passo possivel.
    void   setPassoDinamicoMax                (int    v){MEA_PASSO_DINAMICO_MAX                  =v;} // 15  ; //PASSO_DINAMICO_MAX:maior passo possivel.
    void   setPassoDinamicoPorcCanalEntrelaca (double v){MEA_PASSO_DINAMICO_PORC_CANAL_ENTRELACA =v;} // 0.02; //PASSO_DINAMICO_PORC_CANAL_ENTRELACA
    void   setPassoDinamicoStopQtdContrat     (int    v){MEA_PASSO_DINAMICO_STOP_QTD_CONTRAT     =v;} // 3   ; //PASSO_DINAMICO_STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
    void   setPassoDinamicoStopChunk          (int    v){MEA_PASSO_DINAMICO_STOP_CHUNK           =v;} // 2   ; //PASSO_DINAMICO_STOP_CHUNK:tamanho do chunk.
    void   setPassoDinamicoStopPorcCanal      (double v){MEA_PASSO_DINAMICO_STOP_PORC_CANAL      =v;} // 1   ; //PASSO_DINAMICO_STOP_PORC_CANAL:porcentagem do canal, usada para calcular o stop_loss dinamico.
    void   setPassoDinamicoStopRedutorRisco   (double v){MEA_PASSO_DINAMICO_STOP_REDUTOR_RISCO   =v;} // 1   ; //PASSO_DINAMICO_STOP_REDUTOR_RISCO:porcentagem sobre o tamanho do passo para iniciar saida da posicao.

    bool   getPassoDinamico                   () {return MEA_PASSO_DINAMICO                        ;} // true; //PASSO_DINAMICO:tamanho do passo muda em funcao da volatilidade
    double getPassoDinamicoPorcT4G            () {return MEA_PASSO_DINAMICO_PORC_T4G               ;} // 1   ; //PASSO_DINAMICO_PORC_TFG: % do TFG para definir o passo.
    int    getPassoDinamicoMin                () {return MEA_PASSO_DINAMICO_MIN                    ;} // 1   ; //PASSO_DINAMICO_MIN:menor passo possivel.
    int    getPassoDinamicoMax                () {return MEA_PASSO_DINAMICO_MAX                    ;} // 15  ; //PASSO_DINAMICO_MAX:maior passo possivel.
    double getPassoDinamicoPorcCanalEntrelaca () {return MEA_PASSO_DINAMICO_PORC_CANAL_ENTRELACA   ;} // 0.02; //PASSO_DINAMICO_PORC_CANAL_ENTRELACA
    int    getPassoDinamicoStopQtdContrat     () {return MEA_PASSO_DINAMICO_STOP_QTD_CONTRAT       ;} // 3   ; //PASSO_DINAMICO_STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
    int    getPassoDinamicoStopChunk          () {return MEA_PASSO_DINAMICO_STOP_CHUNK             ;} // 2   ; //PASSO_DINAMICO_STOP_CHUNK:tamanho do chunk.
    double getPassoDinamicoStopPorcCanal      () {return MEA_PASSO_DINAMICO_STOP_PORC_CANAL        ;} // 1   ; //PASSO_DINAMICO_STOP_PORC_CANAL:porcentagem do canal, usada para calcular o stop_loss dinamico.
    double getPassoDinamicoStopRedutorRisco   () {return MEA_PASSO_DINAMICO_STOP_REDUTOR_RISCO     ;} // 1   ; //PASSO_DINAMICO_STOP_REDUTOR_RISCO:porcentagem sobre o tamanho do passo para iniciar saida da posicao.

    // variaveis usadas para controlar os stops.
    void setStopTipoControleRisco  (int    v){MEA_STOP_TIPO_CONTROLE_RISCO=v;} int    getStopTipoControleRisco (){return MEA_STOP_TIPO_CONTROLE_RISCO;}//  1    TIPO_CONTROLE_RISCO, se 1, controle normal. Se 2, controle por proximidade do breakeven.
    void setStopTicksStopLoss      (int    v){MEA_STOP_TICKS_STOP_LOSS    =v;} int    getStopTicksStopLoss     (){return MEA_STOP_TICKS_STOP_LOSS    ;}//  15   TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
    void setStopTicksTkProf        (int    v){MEA_STOP_TICKS_TKPROF       =v;} int    getStopTicksTkProf       (){return MEA_STOP_TICKS_TKPROF       ;}//  30   TICKS_TKPROF:Quantidade de ticks usados no take profit;
    void setStopRebaixamentoMaxDia (int    v){MEA_STOP_REBAIXAMENTO_MAX   =v;} int    getStopRebaixamentoMaxDia(){return MEA_STOP_REBAIXAMENTO_MAX   ;}//  300  REBAIXAMENTO_MAX:preencha com positivo.
    void setStopObjetivoDia        (int    v){MEA_STOP_OBJETIVO_DIA       =v;} int    getStopObjetivoDia       (){return MEA_STOP_OBJETIVO_DIA       ;}//  250  OBJETIVO_DIA:para se saldo alcancar objetivo do dia.
    void setStopLoss               (int    v){MEA_STOP_LOSS               =v;} int    getStopLoss              (){return MEA_STOP_LOSS               ;}// -1200 STOP_LOSS:Valor maximo de perda aceitavel;
    void setStopQtdContrat         (int    v){MEA_STOP_QTD_CONTRAT        =v;} int    getStopQtdContrat        (){return MEA_STOP_QTD_CONTRAT        ;}//  10   STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
    void setStopPorcL1             (double v){MEA_STOP_PORC_L1            =v;} double getStopPorcL1            (){return MEA_STOP_PORC_L1            ;}//  1    STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
    void setStopMinutos            (int    v){MEA_STOP_10MINUTOS          =v;} int    getStopMinutos           (){return MEA_STOP_10MINUTOS          ;}//  0    10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
    void setStopTicksTolerSaida    (int    v){MEA_STOP_TICKS_TOLER_SAIDA  =v;} int    getStopTicksTolerSaida   (){return MEA_STOP_TICKS_TOLER_SAIDA  ;}//  1    TICKS_TOLER_SAIDA: qtd de ticks a aguardar nas saidas stop;
    
    // variaveis usadas para controlar o coficiente de "Entrelacamento"
    void setEntrelacaPeriodoCoef    (int    v){MEA_ENTRELACA_PERIODO_COEF  =v;} // 6   //ENTRELACA_PERIODO_COEF: periodo p/calc coef entrelacamento.
    void setEntrelacaCoefMin        (double v){MEA_ENTRELACA_COEF_MIN      =v;} // 0.40//ENTRELACA_COEF_MIN em porcentagem.
    void setEntrelacaCanalMax       (int    v){MEA_ENTRELACA_CANAL_MAX     =v;} // 30  //ENTRELACA_CANAL_MAX: tamanho maximo em ticks do canal de entrelacamento.
    void setEntrelacaCanalStop      (int    v){MEA_ENTRELACA_CANAL_STOP    =v;} // 35  //ENTRELACA_CANAL_STOP:StopLoss se canal maior que este parametro.
 
    // variaveis usadas para controlar a "Regiao de compra e venda"
    void setRegiaoBuySell           (double v){MEA_REGIAO_BUY_SELL         =v;} //  0.3   //REGIAO_BUY_SELL: regiao de compra e venda nas extremidades do canal de entrelacamento.
    void setRegiaoBuySellUsaCanalDia(bool   v){MEA_USA_REGIAO_CANAL_DIA    =v;} //  false //USA_REGIAO_CANAL_DIA: usa a regiao do canal diario (true) ou canal de entrelacamento(false) para calcular regiao de compra venda.
    
    // variaveis usadas para controlar a "volatilidade e inclinacoes"
    void   setVolatAlta             (double v){MEA_VOLAT_ALTA              =v;} // 1.5 //VOLAT_ALTA:Volatilidade a considerar alta(%). Calculada a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
    void   setVolat4sAltaPorc       (double v){MEA_VOLAT4S_ALTA_PORC       =v;} // 1.0 //VOLAT4S_ALTA_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media abrir posicao.
    void   setVolat4sStopPorc       (double v){MEA_VOLAT4S_STOP_PORC       =v;} // 1.5 //VOLAT4S_STOP_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media para stopar.
    void   setVolat4sMin            (double v){MEA_VOLAT4S_MIN             =v;} // 1.5 //VOLAT4S_MIN:Acima deste valor, nao abre posicao.
    void   setInclAlta              (double v){MEA_INCL_ALTA               =v;} // 0.9 //INCL_ALTA:Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
    void   setInclMin               (double v){MEA_INCL_MIN                =v;} // 0.1 //INCL_MIN:Inclinacao minima para entrar no trade.
    void   setMinDeltaVol           (int    v){MEA_MIN_DELTA_VOL           =v;} // 10  //MIN_DELTA_VOL:%delta vol minimo para entrar na posicao
    void   setMinDeltaVolAceleracao (int    v){MEA_MIN_DELTA_VOL_ACELERACAO=v;} // 1   //MIN_DELTA_VOL_ACELERACAO:Aceleracao minima da %delta vol para entrar na posicao
    
    double getVolatAlta             () {return MEA_VOLAT_ALTA                ;} // 1.5 //VOLAT_ALTA:Volatilidade a considerar alta(%). Calculada a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
    double getVolat4sAltaPorc       () {return MEA_VOLAT4S_ALTA_PORC         ;} // 1.0 //VOLAT4S_ALTA_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media abrir posicao.
    double getVolat4sStopPorc       () {return MEA_VOLAT4S_STOP_PORC         ;} // 1.5 //VOLAT4S_STOP_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media para stopar.
    double getVolat4sMin            () {return MEA_VOLAT4S_MIN               ;} // 1.5 //VOLAT4S_MIN:Acima deste valor, nao abre posicao.
    double getInclAlta              () {return MEA_INCL_ALTA                 ;} // 0.9 //INCL_ALTA:Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
    double getInclMin               () {return MEA_INCL_MIN                  ;} // 0.1 //INCL_MIN:Inclinacao minima para entrar no trade.
    int    getMinDeltaVol           () {return MEA_MIN_DELTA_VOL             ;} // 10  //MIN_DELTA_VOL:%delta vol minimo para entrar na posicao
    int    getMinDeltaVolAceleracao () {return MEA_MIN_DELTA_VOL_ACELERACAO  ;} // 1   //MIN_DELTA_VOL_ACELERACAO:Aceleracao minima da %delta vol para entrar na posicao

    // variaveis usadas para controlar a "entrada na posicao"
    void setToleranciaEntrada(int v){   MEA_TOLERANCIA_ENTRADA=v;} // 1 TOLERANCIA_ENTRADA algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao 
    int  getToleranciaEntrada(){ return MEA_TOLERANCIA_ENTRADA  ;} // 1 TOLERANCIA_ENTRADA algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao 
    
    // variaveis diversas
    void setDebug(bool v){MEA_DEBUG=v;} bool getDebug(){return MEA_DEBUG;}// false     DEBUG se true, grava informacoes de debug no log do EA.
    void setMagic(long v){MEA_MAGIC=v;} long getMagic(){return MEA_MAGIC;}// 200102005 MAGIC Numero magico desse EA. yymmvvvvv.

    double getMaxPrecoCanal             (){return m_maxPrecoCanal                 ;}
    double getMinPrecoCanal             (){return m_minPrecoCanal                 ;}
    double getLenCanalOperacionalEmTicks(){return m_len_canal_operacional_em_ticks;}
    double getCoefEntrelaca             (){return m_coefEntrelaca                 ;}
    
    
};

void osc_minion_expert::initialize(){
    m_name = "MINION-02-P5-HFT";
    
    //BB_SUPERIOR     =  1;
    //BB_INFERIOR     = -1;
    //BB_MEDIA        =  0;
    //BB_DESCONHECIDA =  2;
    
    //m_ult_toque     = BB_DESCONHECIDA; // indica em que banda foi o ultimo toque do preco.
    //m_pri_toque     = BB_DESCONHECIDA; // indica em que banda estah o primeiro toque de preco; A operacao eh aberta no primeiro toque na banda;
    //m_ult_oper      = BB_DESCONHECIDA; // indica em que banda foi a ultima operacao;
    
    m_comprado        = false;
    m_vendido         = false;
    
    //double m_precoPosicao        = 0 ; // valor medio de entrada da posicao
    m_posicaoVolumePend   =  0; // volume pendente pra fechar a posicao atual
    m_posicaoVolumeTot    =  0; // volume total de contratos da posicao, inclusive os que jah foram fechados
    m_positionId          = -1;
    m_volComprasNaPosicao =  0; // quantidade de compras na posicao atual;
    m_volVendasNaPosicao  =  0; // quantidade de vendas  na posicao atual;
    m_capitalInicial      =  0; // capital justamente antes de iniciar uma posicao
    m_capitalLiquido      =  0; // capital atual durante a posicao.
    m_lucroPosicao        =  0; // lucro da posicao atual
    m_lucroPosicao4Gain   =  0; // lucro para o gain caso a quantidade de contratos tenha ultrapassado o valor limite.
    m_lucroStops          =  0; // lucro acumulado durante stops de quantidade
    
    m_tstop                  = 0  ;
    m_positionCommentStr     = "0";
    m_positionCommentNumeric = 0  ;
    
    //--- variaveis atualizadas pela funcao refreshMe...
    m_qtdOrdens          = 0;
    m_qtdPosicoes        = 0;
    m_posicaoProfit      = 0;
    m_ask                = 0;
    m_bid                = 0;
    m_val_order_4_gain   = 0;
    m_max_barra_anterior = 0;
    m_min_barra_anterior = 0;
    
    //--precos medios do book e do timesAndTrades
    m_pmBid = 0;
    m_pmAsk = 0;
    m_pmBok = 0;
    m_pmBuy = 0;
    m_pmSel = 0;
    m_pmTra = 0;
    
    // precos no periodo
    m_phigh  = 0; //-- preco maximo no periodo
    m_plow   = 0; //-- preco minimo no periodo
    
    
    //m_comprometimento_up = 0;
    //m_comprometimento_dw = 0;
    
    //-- controle das inclinacoes
    m_inclSel    = 0;
    m_inclBuy    = 0;
    m_inclTra    = 0;
    m_inclBok    = 0;
    //m_inclEntrada= 0; // inclinacao usada na entrada da operacao.
    
    m_apmb       = "IN" ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
    m_apmb_sel   = "INS"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
    m_apmb_buy   = "INB"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
    m_apmb_ns    = "INN"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
    m_strRajada  = "RJ" ; //string que identifica rajadas de abertura de novas posicoes.
    
    m_razaoVolReal = 0;
    m_razaoVolTick = 0;
    
    m_maior_sld_do_dia                = 0;
    m_sld_sessao_atu                  = 0;
    m_rebaixamento_atu                = 0;
    m_day                             = 0;
    m_mudou_dia                       = false;
    m_acionou_stop_rebaixamento_saldo = false;
    m_spread_maximo_in_points         = 0;
    
    m_ganhos_consecutivos = 0;
    m_perdas_consecutivas = 0;
    m_tempo_posicao_atu   = 0;
    m_tempo_posicao_ini   = 0;
    
    m_stop_qtd_contrat    = 0; // MEA_STOP_QTD_CONTRAT; Eh o tamanho do chunk;
    m_stop_chunk          = 0; // EA_STOP_CHUNK; Eh o tamanho do chunk;
    m_stop_porc           = 0; // MEA_STOP_PORC_L1    ; Eh a porcentagem inicial para o ganho durante o passeio;
    m_qtd_ticks_4_gain_new= 0;
    m_qtd_ticks_4_gain_ini= 0;
    m_qtd_ticks_4_gain_raj= 0;
    m_passo_rajada        = 0;
    m_vol_lote_ini        = 0;
    m_vol_lote_raj        = 0;
    
    // para acelerar a abertura da primeira ordem de fechamento a posicao
    m_val_close_position_sel = 0;
    m_vol_close_position_sel = 0;
    m_val_close_position_buy = 0;
    m_vol_close_position_buy = 0;
    
    // controle de fechamento de posicoes
    m_fechando_posicao         = false;
    m_ordem_fechamento_posicao = 0;
    
    // controle de abertura de posicoes
    m_abrindo_posicao            = false;
    m_ordem_abertura_posicao_sel = 0;
    m_ordem_abertura_posicao_buy = 0;
    
    // controles de apresentacao das variaveis de debug na tela...
    m_str_linhas_acima   = "";
    m_release = "[RELEASE TESTE]";
    
    // variaveis usadas nas estrategias de entrada, visando diminuir a quantidade de alteracoes e cancelamentos com posterior criacao de ordens de entrada.
    m_precoUltOrdemInBuy = 0;
    m_precoUltOrdemInSel = 0;
    
    // milisegundos que devem ser aguardados antes de iniciar a operacao
    m_aguardar_para_abrir_posicao = 0;
    
    // algumas estrategias permitem uma tolerancia do preco para entrada na posicao...
    m_shift = 0;
    
    m_time_in_seconds_ini_day = TimeCurrent();

    m_len_canal_ofertas        = 0; // tamanho do canal de oefertas do book.
    m_len_barra_atual          = 0; // tamanho da barra de trades atual.
    m_volatilidade             = 0; // calculamos a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
    m_volatilidade_4_seg       = 0; // volatilidade por segundo.
    m_volatilidade_4_seg_media = 0; // volatilidade por segundo media.
    m_volatilidade_4_seg_qtd   = 0; // qtd   de registros da volatilidade por segundo. Usado para calcular a volatilidade por segundo media.
    m_volatilidade_4_seg_tot   = 0; // soma dos registros da volatilidade por segundo. Usado para calcular a volatilidade por segundo media.
    
    m_volTradePorSegMedio     = 0;
    m_volTradePorSegQtd       = 1.0;
    m_volTradePorSegTot       = 0;
    m_volTradePorSeg          = 0; // volume de agressoes por segundo.
    m_volTradePorSegBuy       = 0; // volume de agressoes de compra por segundo.
    m_volTradePorSegSel       = 0; // volume de agressoes de venda  por segundo.
    m_volTradePorSegDeltaPorc = 0; // % da diferenca do volume por segundo do vencedor. Se for positivo, o vencedor eh buy, se negativo eh sell. 
    m_desbUp0                 = 0;
    m_desbUp1                 = 0;
    m_desbUp2                 = 0;
    m_desbUp3                 = 0;
    
    m_trefreshMe        = 0;
    m_trefreshFeira     = 0;
    m_trefreshCCI       = 0;
    m_trefreshTela      = 0;
    m_trefreshRates     = 0;
    m_tcontarTransacoes = 0;
    m_tcloseRajada      = 0;
    
    m_estou_posicionado = false;
//  m_probAskDescer     = 0;
//  m_probAskSubir      = 0;
//  m_probBidDescer     = 0;
//  m_probBidSubir      = 0;
    
    m_passo_incremento                    = 0;
    m_passo_dinamico_porc_canal_entrelaca = 0;
    m_volat4s_alta_porc                   = 0;
    m_volat4s_stop_porc                   = 0;
    m_stopLossPosicao                     = 0;

    m_qtd_print_debug = 0;
    m_tamanhoBook     = 0;

    m_precoPosicao         = 0; // valor medio de entrada da posicao
    m_precoPosicaoAnt      = 0;
    m_precoSaidaPosicao    = 0;
    m_precoSaidaPosicaoAnt = 0;
    m_saida_posicao        = 0;

    m_deal_vol      = 0;

    m_fastClose     = true;
    m_traillingStop = false;

    //----------------------------------------------------------------------------------------------------
    // variaveis usadas no onTimer().
    //----------------------------------------------------------------------------------------------------
    m_estah_no_intervalo_de_negociacao = false;
    m_time_in_seconds_atu              = TimeCurrent();
    m_time_in_seconds_ant              = m_time_in_seconds_atu;
    //----------------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas no metodo calcularAceleracaoVelTradeDeltaPorc();
    // 1. Faz o shift das velocidades de volume registradas e despreza a mais antiga
    // 2. Substitui a ultima velocidade pela mais atual
    // 3. Recalcula a aceleracao da velocidade do volume
    //----------------------------------------------------------------------------------------------------
    m_vet_vel_volume_len          = 60;
    m_acelVolTradePorSegDeltaPorc = 0;
    //----------------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas no metodo calcRun(int pLenChunk);
    //----------------------------------------------------------------------------------------------------
    m_strRun           = "";
    m_indRunMais1Ant   = 0;
    m_indRunMenos1Ant  = 0;
    m_indRunAnt        = 0;
    
    m_indRunMais1      = 0;
    m_indRunMenos1     = 0;
    m_indRun           = 0;
    
    m_indVarRunMais1   = 0;
    m_indVarRunMenos1  = 0;
    m_indVarRun        = 0;
    
    m_qtd_periodos_run = 0;
    //----------------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas para apresentar as linhas de apresentacao do canal;
    //----------------------------------------------------------------------------------------------------
    m_str_line_max_price               = "line_max_price";
    m_str_line_min_price               = "line_min_price";
    m_str_line_maior_preco_compra      = "str_line_maior_preco_compra";
    m_str_line_menor_preco_venda       = "str_line_menor_preco_venda";
    m_str_line_time_desde_entrelaca    = "line_time_desde_entrelaca";
    m_line_min_preco_criada            = false;
    m_line_max_preco_criada            = false;
    m_line_maior_preco_compra_criada   = false;
    m_line_menor_preco_venda_criada    = false;
    m_line_time_desde_entrelaca_criada = false;

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas no metodo calcDistPrecoMaxMin();
    //----------------------------------------------------------------------------------------------------
    m_dxPrecoMaxEmTicks               = 0; // distancia, em ticks, entre o preco maximo usado no calculo do entrelacamento e o preco atual;
    m_dxPrecoMinEmTicks               = 0; // distancia, em ticks, entre o preco minimo usado no calculo do entrelacamento e o preco atual;
    m_regiaoPrecoCompra               = 0;
    m_regiaoPrecoVenda                = 0;
    m_porcRegiaoOperacao              = 0; //0.20;
    m_maxDistanciaEntrelacaParaOperar = 0; //1000;
    m_stpDistanciaEntrelacamento      = 0;
    m_maiorPrecoDeCompra              = 0;
    m_menorPrecoDeVenda               = 0;
    //----------------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------------------
    // 0. variaveis usadas no metodo calcOpenMaxMinDia();
    //----------------------------------------------------------------------------------------------------
    m_direcaoDia = 0; //indica se o dia eh de alta ou baixa...
    //----------------------------------------------------------------------------------------------------

    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas no metodo calcCoefEntrelacamentoMedio();
    //|-------------------------------------------------------------------------------------
    m_coefEntrelaca                  = 0;
    m_coefEntrelacaInv               = 0;
    m_qtdPeriodoCoefEntrelaca        = 0;
    m_maxPrecoCanal                  = 0;
    m_minPrecoCanal                  = 0;
    m_len_canal_operacional_em_ticks = 0;
    m_time_desde_entrelaca           = 0;
    m_direcao_entre                  = 0; // indica se a barra total do entrelacamento eh de alta ou baixa...
    m_entrelacaMinParaOperar         = 0; // parametro inicial em 0.45
    //----------------------------------------------------------------------------------------------------
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas no metodo traillingstop();
    //|-------------------------------------------------------------------------------------
    m_dx1=0;
    ea_dx_trailling_stop=1.0; // % do DX1 para fazer o trailling stop
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas no metodo showtela();
    //|-------------------------------------------------------------------------------------
    MEA_SHOW_TELA              = false;
    MEA_SHOW_TELA_LINHAS_ACIMA = 0;
    MEA_SHOW_CANAL_PRECOS      = false;      
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para calcular o profit da posicao do mini-dolar.
    //|-------------------------------------------------------------------------------------
    MEA_DOLAR_TARIFA = 5;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para limitar a quantidade de ordens pendentes.
    //|-------------------------------------------------------------------------------------
    MEA_MAX_VOL_EM_RISCO = 200;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar a classe estatistica2.
    //|-------------------------------------------------------------------------------------
    MEA_EST_QTD_SEGUNDOS   = 21;
    MEA_EST_PROCESSAR_BOOK = true;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar horario de inicio e fim da operacao.
    //|-------------------------------------------------------------------------------------
    MEA_HR_INI_OPERACAO = 09; MEA_MI_INI_OPERACAO = 30;
    MEA_HR_FIM_OPERACAO = 17; MEA_MI_FIM_OPERACAO = 00;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar a permissao de abertura de posicao logo apos a inicializacao do EA. 
    //|-------------------------------------------------------------------------------------
    MEA_SLEEP_INI_OPER = 21; // em segundos.
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para atrasar as operacoes visando piorar as condicoes de teste.
    //|-------------------------------------------------------------------------------------
    MEA_SLEEP_ATRASO = 0; // em milisegundos;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para definir o tempo de acionamento do timer. Em milisegundos.
    //|-------------------------------------------------------------------------------------
    MEA_QTD_MILISEG_TIMER = 250; // em milisegundos;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar o fechamento de posicao e a permissao para operar.
    //|-------------------------------------------------------------------------------------
    MEA_ACAO_POSICAO = FECHAR_POSICAO;

    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar o fechamento de posicao e a permissao para operar.
    //|-------------------------------------------------------------------------------------
    MEA_SPREAD_MAXIMO_EM_TICKS = 4;

    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar o volume maximo permitido para abrir posicoes
    //|-------------------------------------------------------------------------------------
    MEA_VOLSEG_MAX_ENTRADA_POSIC = 150;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para definir os volumes da entrada na posicao e das rajadas.
    //|-------------------------------------------------------------------------------------
    MEA_VOL_LOTE_INI = 1.0;
    MEA_VOL_LOTE_RAJ = 1.0;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para definir o tamanho das rajadas.
    //|-------------------------------------------------------------------------------------
    ea_tamanho_rajada = 3;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para definir o passo de rajada fixo.
    //|-------------------------------------------------------------------------------------
    MEA_PASSO_RAJ            = 3;
    MEA_QTD_TICKS_4_GAIN_INI = 3;
    MEA_QTD_TICKS_4_GAIN_RAJ = 3;
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para definir o passo dinamico.
    //|-------------------------------------------------------------------------------------
    MEA_PASSO_DINAMICO                      = true; //PASSO_DINAMICO:tamanho do passo muda em funcao da volatilidade
    MEA_PASSO_DINAMICO_PORC_T4G             = 1   ; //PASSO_DINAMICO_PORC_TFG: % do TFG para definir o passo.
    MEA_PASSO_DINAMICO_MIN                  = 1   ; //PASSO_DINAMICO_MIN:menor passo possivel.
    MEA_PASSO_DINAMICO_MAX                  = 15  ; //PASSO_DINAMICO_MAX:maior passo possivel.
    MEA_PASSO_DINAMICO_PORC_CANAL_ENTRELACA = 0.02; //PASSO_DINAMICO_PORC_CANAL_ENTRELACA
    MEA_PASSO_DINAMICO_STOP_QTD_CONTRAT     = 3   ; //PASSO_DINAMICO_STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
    MEA_PASSO_DINAMICO_STOP_CHUNK           = 2   ; //PASSO_DINAMICO_STOP_CHUNK:tamanho do chunk.
    MEA_PASSO_DINAMICO_STOP_PORC_CANAL      = 1   ; //PASSO_DINAMICO_STOP_PORC_CANAL:porcentagem do canal, usada para calcular o stop_loss dinamico.
    MEA_PASSO_DINAMICO_STOP_REDUTOR_RISCO   = 1   ; //PASSO_DINAMICO_STOP_REDUTOR_RISCO:porcentagem sobre o tamanho do passo para iniciar saida da posicao.

    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar os stops.
    //|-------------------------------------------------------------------------------------
    MEA_STOP_TIPO_CONTROLE_RISCO =  1    ; //TIPO_CONTROLE_RISCO, se 1, controle normal. Se 2, controle por proximidade do breakeven.
    MEA_STOP_TICKS_STOP_LOSS     =  15   ; //TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
    MEA_STOP_TICKS_TKPROF        =  30   ; //TICKS_TKPROF:Quantidade de ticks usados no take profit;
    MEA_STOP_REBAIXAMENTO_MAX    =  300  ; //REBAIXAMENTO_MAX:preencha com positivo.
    MEA_STOP_OBJETIVO_DIA        =  250  ; //OBJETIVO_DIA:para se saldo alcancar objetivo do dia.
    MEA_STOP_LOSS           = -1200 ; //STOP_LOSS:Valor maximo de perda aceitavel;
    MEA_STOP_QTD_CONTRAT    =  10   ; //STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
    MEA_STOP_PORC_L1        =  1    ; //STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
    MEA_STOP_10MINUTOS           =  0    ; //10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
    MEA_STOP_TICKS_TOLER_SAIDA   =  1    ; //TICKS_TOLER_SAIDA: qtd de ticks a aguardar nas saidas stop;
    MEA_VOL_MARTINGALE          =  false; //MARTINGALE: dobra a quantidade de ticks a cada passo.
    
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar o coficiente de "Entrelacamento"
    //|-------------------------------------------------------------------------------------
    MEA_ENTRELACA_PERIODO_COEF = 6   ; //ENTRELACA_PERIODO_COEF: periodo p/calc coef entrelacamento.
    MEA_ENTRELACA_COEF_MIN     = 0.40; //ENTRELACA_COEF_MIN em porcentagem.
    MEA_ENTRELACA_CANAL_MAX    = 30  ; //ENTRELACA_CANAL_MAX: tamanho maximo em ticks do canal de entrelacamento.
    MEA_ENTRELACA_CANAL_STOP   = 35  ; //ENTRELACA_CANAL_STOP:StopLoss se canal maior que este parametro.
  
    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar a "Regiao de compra e venda"
    //|-------------------------------------------------------------------------------------
    MEA_REGIAO_BUY_SELL      = 0.3  ; //REGIAO_BUY_SELL: regiao de compra e venda nas extremidades do canal de entrelacamento.
    MEA_USA_REGIAO_CANAL_DIA = false; //USA_REGIAO_CANAL_DIA: usa a regiao do canal diario (true) ou canal de entrelacamento(false) para calcular regiao de compra venda.

    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas para controlar a "volatilidade e inclinacoes"
    //|-------------------------------------------------------------------------------------
    MEA_VOLAT_ALTA               = 1.5; //VOLAT_ALTA:Volatilidade a considerar alta(%). Calculada a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
    MEA_VOLAT4S_ALTA_PORC        = 1.0; //VOLAT4S_ALTA_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media abrir posicao.
    MEA_VOLAT4S_STOP_PORC        = 1.5; //VOLAT4S_STOP_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media para stopar.
    MEA_VOLAT4S_MIN              = 1.5; //VOLAT4S_MIN:Acima deste valor, nao abre posicao.
    MEA_INCL_ALTA                = 0.9; //INCL_ALTA:Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
    MEA_INCL_MIN                 = 0.1; //INCL_MIN:Inclinacao minima para entrar no trade.
    MEA_MIN_DELTA_VOL            = 10 ; //MIN_DELTA_VOL:%delta vol minimo para entrar na posicao
    MEA_MIN_DELTA_VOL_ACELERACAO = 1  ; //MIN_DELTA_VOL_ACELERACAO:Aceleracao minima da %delta vol para entrar na posicao
    
    // variaveis usadas para controlar a "entrada na posicao"
    MEA_TOLERANCIA_ENTRADA       = 1;   //TOLERANCIA_ENTRADA: algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao 
    
    // variaveis diversas
    MEA_DEBUG                    = false       ; //DEBUG se true, grava informacoes de debug no log do EA.
    MEA_MAGIC                    = 202007001001; //MAGIC Numero magico desse EA. yymmvvvvv.

}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int osc_minion_expert::oninit(){
    #ifdef COMPILE_PRODUCAO m_release = "[RELEASE PRODU]";#endif

    Print("***** Iniciando " + __FUNCTION__ + ":" + IntegerToString(MEA_MAGIC) + " as " + TimeToString( TimeCurrent() ) +"... ******");
    Print(":-| ", __FUNCTION__,":",m_release);
    Print(":-| ", __FUNCTION__,":",m_release);
    Print(":-| ", __FUNCTION__,":",m_release);

    inicializarVariaveisRecebidasPorParametro();
    
    // definindo local da tela onde serao mostradas as variaveis de debug...
    m_str_linhas_acima   = "";
    for( int i=0; i<MEA_SHOW_TELA_LINHAS_ACIMA; i++ ){
       StringAdd(m_str_linhas_acima,"\n");
    }

    m_symb.Name( Symbol() ); // inicializacao da classe CSymbolInfo
    m_symb_str         = Symbol();
    m_symb.Refresh               (); // propriedades do simbolo. Basta executar uma vez.
    m_symb.RefreshRates          (); // valores do tick. execute uma vez por tick.
    m_tick_size        = m_symb.TickSize(); //Obtem a alteracao minima de preco
    //m_qtd_ticks_4_gain = EA_QTD_TICKS_4_GAIN_L5;
    m_stopLossOrdens   = m_symb.NormalizePrice(MEA_STOP_TICKS_STOP_LOSS *m_tick_size);
    m_tkprof           = m_symb.NormalizePrice(MEA_STOP_TICKS_TKPROF    *m_tick_size);
    m_trade.setMagic   (MEA_MAGIC);
    m_trade.setStopLoss(m_stopLossOrdens);
    m_trade.setTakeProf(m_tkprof); 
    ArraySetAsSeries(m_rates,true);
    
    //if(MEA_EST_PROCESSAR_BOOK) MarketBookAdd   ( m_symb_str );

    // estatistica de trade...    
    m_time_in_seconds_ini_day = StringToTime( TimeToString( TimeCurrent(), TIME_DATE ) );
    m_trade_estatistica.initialize();
    m_trade_estatistica.setCotacaoMoedaTarifaWDO(MEA_DOLAR_TARIFA);
    
    m_est.initialize(MEA_EST_QTD_SEGUNDOS); // quantidade de segundos que serao usados no calculo das medias.
    m_est.setSymbolStr( m_symb_str );

    m_spread_maximo_in_points = (int)(MEA_SPREAD_MAXIMO_EM_TICKS*m_tick_size);

    m_shift                   = normalizar(MEA_TOLERANCIA_ENTRADA*m_tick_size); // tolerancia permitida para entrada em algumas estrategias

    m_maior_sld_do_dia = m_cta.Balance(); // saldo da conta no inicio da sessao;
    m_sld_sessao_atu   = m_cta.Balance();
    m_capitalInicial   = m_cta.Balance();

    m_comment_fixo = "LOGIN:"         + DoubleToString(m_cta.Login(),0) +
                     "  TRADEMODE:"   + m_cta.TradeModeDescription()    +
                     "  MARGINMODE:"  + m_cta.MarginModeDescription()   + 
                     " "              + m_release;
                   //"alavancagem:" + m_cta.Leverage()               + "\n" +
                   //"stopoutmode:" + m_cta.StopoutModeDescription() + "\n" +
                   //"max_ord_pend:"+ m_cta.LimitOrders()            + "\n" + // max ordens pendentes permitidas
    Comment(m_comment_fixo);

    m_trade.setVolLote ( m_symb.LotsMin() );

    m_precoUltOrdemInBuy = 0;
    m_precoUltOrdemInSel = 0;
  
    //EventSetMillisecondTimer(MEA_QTD_MILISEG_TIMER);
    //Print(":-| CLASSE ", __FUNCTION__,":", " Criado Timer de ",MEA_QTD_MILISEG_TIMER," milisegundos !!! " );
    Print(":-) CLASSE ", __FUNCTION__,":", " inicializado !! " );
    Print(":-| ", __FUNCTION__,":", m_release);
    Print(":-| ", __FUNCTION__,":", m_release);
    Print(":-| ", __FUNCTION__,":", m_release);
    
    // melhorando a administracao do stop_loss quando o EA inicia em meio a uma posicao em andamento
    calcCoefEntrelacamentoMedio();
    //calcOpenMaxMinDia();
    definirPasso();
    calcStopLossPosicao();
    
    return(0);
}

void osc_minion_expert::refreshMe(){
    
    #ifndef COMPILE_PRODUCAO if(MEA_DEBUG) m_trefreshMe    = GetMicrosecondCount(); #endif
    m_posicao.Select( m_symb_str );
    
    
    #ifndef COMPILE_PRODUCAO if(MEA_DEBUG) m_trefreshRates = GetMicrosecondCount(); #endif
    m_symb.RefreshRates();
    #ifndef COMPILE_PRODUCAO if(MEA_DEBUG) m_trefreshRates = GetMicrosecondCount()-m_trefreshRates; #endif
    
    // adicionando o tick ao componente estatistico...
    SymbolInfoTick(m_symb_str,m_tick_est);      
    m_est.addTick(m_tick_est);
    
    //m_probAskDescer = m_est.getPrbAskDescer();
    //m_probAskSubir  = m_est.getPrbAskSubir ();
    //m_probBidDescer = m_est.getPrbBidDescer();
    //m_probBidSubir  = m_est.getPrbBidSubir ();
    
    m_trade.setStopLoss( m_stopLossOrdens );
    m_trade.setTakeProf( m_tkprof         );
    m_trade.setVolLote ( m_symb.LotsMin() );

    m_ask     = m_symb.Ask();
    m_bid     = m_symb.Bid();
    m_desbUp0 = m_est.getDesbalanceamentoUP0();// m_feira.getDesbUP0(0);
    m_desbUp1 = m_est.getDesbalanceamentoUP1();// m_feira.getDesbUP1(0);
    m_desbUp2 = m_est.getDesbalanceamentoUP2();// m_feira.getDesbUP1(0);
    m_desbUp3 = m_est.getDesbalanceamentoUP3();// m_feira.getDesbUP1(0);
    
    //calcCoefEntrelacamentoMedio();
    //calcOpenMaxMinDia();
      calcDistPrecoMaxMin();

    // atualizando maximo, min e tamnaho das barras anterior de preco atual e anterior...
    CopyRates(m_symb_str,_Period,0,2,m_rates);
    m_max_barra_anterior = m_rates[1].high;
    m_min_barra_anterior = m_rates[1].low ;

    m_qtdOrdens   = OrdersTotal();
    m_qtdPosicoes = PositionsTotal();

    // adminstrando posicao aberta...
    if( m_qtdPosicoes > 0 ){
        
        if ( PositionSelect  (m_symb_str) ){ // soh funciona em contas hedge

            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                setCompradoSoft();
            }else{
                setVendidoSoft();
            }

            // primeiro refresh apos abertura da posicao...
            if( !m_estou_posicionado && !m_fechando_posicao && MEA_ACAO_POSICAO != NAO_OPERAR ){

                //<TODO> chame o closerajada aqui para que nao seja atrasado pelo cancelamento de ordens apmb.
                //doCloseRajada(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_ini);

                // se tem posicao aberta, cancelamos as ordens apmb que porventura tenham ficado abertas
                m_trade.cancelarOrdensComentadas(m_symb_str,m_apmb);//<TODO: DESCOMENTE e transforme em parametro>
                m_estou_posicionado = true;
            }
            
            m_posicaoProfit          = PositionGetDouble (POSITION_PROFIT     );
            m_precoPosicao           = PositionGetDouble (POSITION_PRICE_OPEN ); // este eh o valor medio de abertura da posicao.
            if(m_val_order_4_gain==0) m_val_order_4_gain = m_precoPosicao;       // este eh o valor de fato de abertura da posicao.
            
            m_posicaoVolumePend      = PositionGetDouble (POSITION_VOLUME     );
            m_positionId             = PositionGetInteger(POSITION_IDENTIFIER );
            m_positionCommentStr     = PositionGetString (POSITION_COMMENT    );
            m_positionCommentNumeric = StringToInteger   (m_positionCommentStr);
            m_capitalLiquido         = m_cta.Equity();
            
            m_lucroPosicao           = m_capitalLiquido - m_capitalInicial; // voltou versao em 03/02/2020 as 11:50
          //m_lucroPosicao = m_posicaoProfit;

            ///////////////////////////////////
            if( estouComprado() ){ 
                m_posicaoVolumeTot = m_volComprasNaPosicao;
            }else{
                if( estouVendido() ){ 
                    m_posicaoVolumeTot = m_volVendasNaPosicao ;
                }
             }
            m_lucroPosicao4Gain = (m_posicaoVolumeTot*m_stop_porc);
            ///////////////////////////////////
            

            if( m_abrindo_posicao ){
                #ifndef COMPILE_PRODUCAO if(MEA_DEBUG) Print(__FUNCTION__, ":-| Cancelando status de abertura de posicao, pois ha posicao aberta! tktSell=", m_ordem_abertura_posicao_sel, " tktBuy=", m_ordem_abertura_posicao_buy ); #endif
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
           m_positionId        = -1;
           m_lucroPosicao4Gain = 0;
        }

        if( m_fechando_posicao && m_qtdOrdens == 0){
            #ifndef COMPILE_PRODUCAO if(MEA_DEBUG)Print( __FUNCTION__,":-| Cancelando status de fechamento de posicao, pois nao ha posicao aberta! ticket da ordem de fechamento=", m_ordem_fechamento_posicao );#endif
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
        m_positionId        = -1;
        m_lucroPosicao4Gain = 0;


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
            if(MEA_DEBUG)Print( __FUNCTION__,":-| Cancelando status de fechamento de posicao, pois nao ha posicao aberta! ticket da ordem de fechamento=", m_ordem_fechamento_posicao );
            m_fechando_posicao         = false;
            m_ordem_fechamento_posicao = 0;
        }
        
        // Deixando o stop loss de posicao preparado. Quando posicionado, nao altera o stop loss de posicao.
        calcStopLossPosicao();
    }

   //-- precos medios do book
   m_pmBid = m_est.getPrecoMedBookBid ();// m_feira.getPrecoMedioBid(0);
   m_pmAsk = m_est.getPrecoMedBookAsk ();// m_feira.getPrecoMedioAsk(0);
   m_pmBok = m_est.getPrecoMedBook    ();// m_feira.getPrecoMedioBok(0);
   m_pmSel = m_est.getPrecoMedTradeSel();// m_feira.getPrecoMedioSel(0);
   m_pmBuy = m_est.getPrecoMedTradeBuy();// m_feira.getPrecoMedioBuy(0);
   m_pmTra = m_est.getPrecoMedTrade   ();// m_feira.getPrecoMedioTra(0);

   // canal de ofertas no book...
   m_len_canal_ofertas = m_pmAsk - m_pmBid;

   //-- precos no periodo
   m_phigh           = m_est.getTradeHigh();// m_feira.getPrecoHigh(0);
   m_plow            = m_est.getTradeLow ();// m_feira.getPrecoLow(0);
   m_len_barra_atual = m_phigh - m_plow;

   // calculamos a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
   if( m_len_canal_ofertas > 0 ) m_volatilidade = m_len_barra_atual / m_len_canal_ofertas;
   
   // calcumado a volatilidade por segundo e a volatilidade por segundo media
   m_volatilidade_4_seg = m_len_barra_atual/MEA_EST_QTD_SEGUNDOS;
   m_volatilidade_4_seg_qtd++;
   m_volatilidade_4_seg_tot  += m_volatilidade_4_seg;
   m_volatilidade_4_seg_media = m_volatilidade_4_seg_tot/m_volatilidade_4_seg_qtd;
   
   // ticks por segundo. medida de volatilidade e da forca das agressoes de compra evenda...
   m_volTradePorSeg          = m_est.getVolTradeTotPorSeg()                     ; 
   m_volTradePorSegBuy       = m_est.getVolTradeBuyPorSeg()                     ;
   m_volTradePorSegSel       = m_est.getVolTradeSelPorSeg()                     ;
   m_volTradePorSegDeltaPorc = m_volTradePorSeg==0?0:(int)( ((m_volTradePorSegBuy - m_volTradePorSegSel)/m_volTradePorSeg)*100.0 );

   m_volTradePorSegTot       += m_volTradePorSeg;
   m_volTradePorSegMedio      = m_volTradePorSegTot/m_volTradePorSegQtd++;

   // aceleracoes de volume

   //--inclinacoes dos precos medios de compra e venda...
   m_inclSel    = m_est.getInclinacaoTradeSel();// m_feira.getInclinacaoSel(0);
   m_inclBuy    = m_est.getInclinacaoTradeBuy();// m_feira.getInclinacaoBuy(0);
   m_inclTra    = m_est.getInclinacaoTrade   ();// m_feira.getInclinacaoTra(0);
   m_inclBok    = m_est.getInclinacaoBook    ();// m_feira.getInclinacaoBok(0);


   //-- Informa a maxima ou minima da vela anterior caso tenha havido comprometimento institucional naquela vela.
   //m_comprometimento_up = m_feira.getSinalCompromissoUp(1);
   //m_comprometimento_dw = m_feira.getSinalCompromissoDw(1);

   m_sld_sessao_atu = m_cta.Balance();

   showTela();
   
   #ifndef COMPILE_PRODUCAO 
       if(MEA_DEBUG){
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


void osc_minion_expert::showTela(){
   if (MEA_SHOW_TELA){
       
       #ifndef COMPILE_PRODUCAO if( MEA_DEBUG ) m_trefreshTela = GetMicrosecondCount(); #endif
                       // primeira linha
       m_comment_var = " [FECHANDO_POSICAO:" + IntegerToString(m_fechando_posicao) +"]"+(m_qtdPosicoes==0?"[SEM POSICAO]":estouComprado()?"[COMPRADO]":"[VENDIDO]") +
                         " ULTORDENS["   +DoubleToString (m_precoUltOrdemInBuy,Digits())+ "," + 
                                          DoubleToString (m_precoUltOrdemInSel,Digits())+ "]" +  // so pra debug
                         " PODEABRIRPOS["+IntegerToString(podeAbrirProsicao()          )+ "]" + 
                         " 1TICK["       +DoubleToString (m_tick_size         ,Digits())+ "]" +  
                         " 1PONTO["      +DoubleToString (Point()             ,Digits())+ "]" +
                   "\n" +" menorpv["     +DoubleToString (m_menorPrecoDeVenda ,2       )+ "]" +
                         " maiorpc["     +DoubleToString (m_maiorPrecoDeCompra,2       )+ "]" +
                   "\n" +" maxpc  ["     +DoubleToString (m_maxPrecoCanal     ,2       )+ "]" +
                         " minpc  ["     +DoubleToString (m_minPrecoCanal     ,2       )+ "]" +
                   "\n" +" %regiao["     +DoubleToString (m_porcRegiaoOperacao,2       )+ "]" +
                         
                          //---------------------------
//                        " \nPAS/PAD " + DoubleToString(m_probAskSubir *100.0,0) + "/" + 
//                                        DoubleToString(m_probAskDescer*100.0,0) +
                          "  \nDXVELBIDASK/ACEDX:"+IntegerToString(m_volTradePorSegDeltaPorc    ) +"/"+
                                                   IntegerToString(m_acelVolTradePorSegDeltaPorc) +
                                          
                     //   " \nPBS/PBD " + DoubleToString(m_probBidSubir *100.0,0) + "/" + 
                     //                   DoubleToString(m_probBidDescer*100.0,0) +
                     //
                     //   " \nFA/FB "   + DoubleToString(m_est.getFluxoAsk()          ,0) + "/" + 
                     //                   DoubleToString(m_est.getFluxoBid()          ,0) +
                      //    " \n------"   +
                      //    " \npUP3: "   + DoubleToString( m_desbUp3*100  ,0) +((m_desbUp3>=MEA_DESBALAN_UP3 && MEA_DESBALAN_UP3>0)?" *":"") +
                      //    " \npUP2: "   + DoubleToString( m_desbUp2*100  ,0) +((m_desbUp2>=MEA_DESBALAN_UP2 && MEA_DESBALAN_UP2>0)?" *":"") +
                      //    " \npUP1: "   + DoubleToString( m_desbUp1*100  ,0) +((m_desbUp1>=MEA_DESBALAN_UP1 && MEA_DESBALAN_UP1>0)?" *":"") +
                      //    " \npUP0: "   + DoubleToString( m_desbUp0*100  ,0) +((m_desbUp0>=MEA_DESBALAN_UP0 && MEA_DESBALAN_UP0>0)?" *":"") +
                      //    " \n------"   +
                      //    " \npDW0: "   + DoubleToString( m_desbUp0*100  ,0) +((m_desbUp0<=MEA_DESBALAN_DW0 && MEA_DESBALAN_DW0>0)?" *":"") +
                      //    " \npDW1: "   + DoubleToString( m_desbUp1*100  ,0) +((m_desbUp1<=MEA_DESBALAN_DW1 && MEA_DESBALAN_DW1>0)?" *":"") +
                      //    " \npDW2: "   + DoubleToString( m_desbUp2*100  ,0) +((m_desbUp2<=MEA_DESBALAN_DW2 && MEA_DESBALAN_DW2>0)?" *":"") +
                      //    " \npDW3: "   + DoubleToString( m_desbUp3*100  ,0) +((m_desbUp3<=MEA_DESBALAN_DW3 && MEA_DESBALAN_DW3>0)?" *":"") +
                      //    " \n------"   +
                          //---------------------------

                          " \nENTRELAC/LENCANAL  REGIAO_COMPRA/VND  LENBARRAEST: " + DoubleToString(m_coefEntrelaca*100             ,0       )+ "/" +
                                                                                     DoubleToString(m_len_canal_operacional_em_ticks,0       )+ "   " +
                                                                                     DoubleToString(m_regiaoPrecoCompra*100         ,0       )+ "/" +
                                                                                     DoubleToString(m_regiaoPrecoVenda *100         ,0       )+ "   " +
                                                                                     DoubleToString(m_len_barra_atual/m_tick_size   ,Digits())+
                                                                        
                          " \nVLT/V4S/V4SM/  TFG " + DoubleToString(m_volatilidade            ,2)+ "/"    +
                                                     DoubleToString(m_volatilidade_4_seg      ,2)+ "/"    +
                                                     DoubleToString(m_volatilidade_4_seg_media,2)+ "/   " +
                                                    IntegerToString(m_qtd_ticks_4_gain_ini      )+
                          
                          " \nVO4S/VO4SM " + DoubleToString(m_volTradePorSeg            ,2)+ "/"    +
                                             DoubleToString(m_volTradePorSegMedio       ,2)+ 
                          
                          " \nProbAcer/PayOut/Kelly " +
                                               DoubleToString(m_trade_estatistica.getProbAcerto        () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getPayOut            () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getCoefKelly         () ,2)+

                          " \nPFT PD/TD/PC/PL/VOL WDO " +
                                               DoubleToString(m_trade_estatistica.getProfitDiaWDO        () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getTarifaDiaWDO        () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getProfitPorContratoWDO() ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getProfitDiaLiquidoWDO () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getVolumeDiaWDO        () ,2)+
                          " \nPFT PD/TD/PC/PL/VOL WIN " +
                                               DoubleToString(m_trade_estatistica.getProfitDiaWIN        () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getTarifaDiaWIN        () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getProfitPorContratoWIN() ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getProfitDiaLiquidoWIN () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getVolumeDiaWIN        () ,2)+
                          " \nPFT PD/TD/PC/PL/VOL XXX " +
                                               DoubleToString(m_trade_estatistica.getProfitDia        () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getTarifaDia        () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getProfitPorContrato() ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getProfitDiaLiquido () ,2)+"/" +
                                               DoubleToString(m_trade_estatistica.getVolumeDia        () ,2)+
                          m_str_linhas_acima +
                       //" CTA SLD:"      + DoubleToString(m_cta.Balance()    ,2      ) +
                       //" CAPLIQ: "      + DoubleToString(m_cta.Equity()     ,2      ) +
                       //" VAL_GAIN:"     + DoubleToString(m_val_order_4_gain ,_Digits) +
                                            
                     //"\n" + "[POSICIONADO:"  + m_estou_posicionado + "] " +(m_qtdPosicoes==0?"SEM POSICAO":estouComprado()?"COMPRADO":"VENDIDO") +
                     //" m_posicaoProfit: " + DoubleToString(m_posicaoProfit,2)+
                     //" PROFIT:"           + DoubleToString(m_cta.Profit(),2) +
                       
                       // segunda linha
                     "\n\nPAS/PFT/OUT/LOS: " + IntegerToString(m_passo_rajada         ) +"/"+
                                                DoubleToString(m_lucroPosicao ,0      ) +"/"+
                                                DoubleToString(m_saida_posicao,0      ) +"/"+
                                              //DoubleToString(m_lucroPosicao4Gain,0      ) +"/"+
                                                DoubleToString(m_stopLossPosicao     ,0) +
                       " VOL: "               +IntegerToString(porcentagem(m_posicaoVolumePend,m_posicaoVolumeTot,0) ) + "% " +
                                                DoubleToString(m_posicaoVolumePend,_Digits) + "/"+
                                                DoubleToString(m_posicaoVolumeTot ,_Digits) +
                       " RSLD: "             +  DoubleToString(m_trade_estatistica.getRebaixamentoSld() ,2) + "/" +
                       //" RSLD ATU/MAX/MSD: " +  DoubleToString(m_rebaixamento_atu ,2 ) + "/" +
                                                  DoubleToString(MEA_STOP_REBAIXAMENTO_MAX,0 ) + "/" +
                       //                         DoubleToString(m_maior_sld_do_dia ,2 ) +
                       " IRUN: "             + DoubleToString(m_indRunMenos1*100.0 ,0) + "/" +
                                               DoubleToString(m_indRun      *100.0 ,0) + "/" +
                                               DoubleToString(m_indRunMais1 *100.0 ,0) + "   "
                                             
                                             + DoubleToString(m_indVarRunMenos1*100.0 ,0) + "/" +
                                               DoubleToString(m_indVarRun      *100.0 ,0) + "/" +
                                               DoubleToString(m_indVarRunMais1 *100.0 ,0) +

                      // terceira linha
                       "\nQTD_OFERTAS: "  + IntegerToString(m_symb.SessionDeals()        )+
                       " OPEN:"           + DoubleToString (m_symb.SessionOpen (),_Digits)+
                       " VWAP:"           + DoubleToString (m_symb.SessionAW   (),_Digits)+
                     //" DATA:"           + TimeToString   (TimeCurrent()                )+
                       " HORA"            + TimeToString   (TimeCurrent(),TIME_SECONDS   )+
                       " TEMPO_POSICAO:"  + IntegerToString(m_tempo_posicao_atu)          +
                       " VOLTOT: "        + DoubleToString (m_est.getVolTrade(),2)        + //DoubleToString (m_feira.getVolTrade(0),2)     +


                //       "\nABRIR_POSICAO:"    +                MEA_ABRIR_POSICAO             +
                //       "  MAX_VOL_EM_RISCO:" + DoubleToString(MEA_MAX_VOL_EM_RISCO,_Digits) +
                //       "  MAX_REBAIX_SLD:"   + DoubleToString(MEA_STOP_REBAIXAMENTO_MAX  ,0      ) +
                //       "  TICKS_STOP_LOSS:"  + DoubleToString(MEA_STOP_TICKS_STOP_LOSS ,0      ) +
                //       "  TICK_SIZE:"        + DoubleToString(m_symb.TickSize() ,_Digits     ) +
                //       "  TICK_VALUE:"       + DoubleToString(m_symb.TickValue(),_Digits     ) +
                //       "  POINT:"            + DoubleToString(m_symb.Point()    ,_Digits     ) +

                       //quarta linha (tiramos)
                       //"\nposPft/ctaPft: "     + DoubleToString(m_posicaoProfit,2)+ "/" +
                       //                          DoubleToString(m_cta.Profit(),2) +
                       
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

                       // quarta linha
                       "\nVSEG/BUY/SEL/MAX:" + DoubleToString (m_volTradePorSeg   ,0           ) + "/" + 
                                                    DoubleToString (m_volTradePorSegBuy,0           ) + "/" + 
                                                    DoubleToString (m_volTradePorSegSel,0           ) + "/" + 
                                                  //IntegerToString(EA_VOLSEG_ALTO                  ) + "/" +
                                                    IntegerToString(MEA_VOLSEG_MAX_ENTRADA_POSIC     ) +
                       //
                       //" DBOK:"              + DoubleToString (m_desbUp0*100,0) +
                       " VOLAT/MAX:" + DoubleToString(m_volatilidade        ,2           ) + "/" + DoubleToString (MEA_VOLAT_ALTA ,2) +
                       " SPREAD/MAX:"+ DoubleToString(m_symb.Spread()       ,_Digits     ) +
                       "/"          + IntegerToString(m_spread_maximo_in_points          ) +
                       "  INCLI/MAX:"+ DoubleToString(m_inclTra             ,2           ) + "/" + DoubleToString(MEA_INCL_ALTA   ,2) +
                       //" CCI ANT/ATU/DIF: " + DoubleToString(m_icci.Main(1),2)+"/"+
                       //                       DoubleToString(m_icci.Main(0),2)+"/"+
                       //                       DoubleToString((m_icci.Main(0)-m_icci.Main(1)),2)+
                       //
                       // quinta linha
                       "\n" + "DELTAVEL/ACED:"+IntegerToString(m_volTradePorSegDeltaPorc    ) +"/"+
                                               IntegerToString(m_acelVolTradePorSegDeltaPorc) +   
                       "\n" + strPosicao() +
                       "\n" + strPermissaoAbrirPosicao();

       Comment(m_comment_fixo + m_comment_var + m_strRun);
       //refreshControlPanel();
       //MessageBox( "mensagem de teste",     // texto da mensagem 
       //            "Log"                    // cabeçalho da caixa 
       //            //int     flags=0        // define o conjunto de botões na caixa 
       //          );
       #ifndef COMPILE_PRODUCAO if(MEA_DEBUG) m_trefreshTela = GetMicrosecondCount()-m_trefreshTela;#endif
   }
}


bool osc_minion_expert::passoAutorizado(){ 
    if( MEA_PASSO_DINAMICO ){
        return m_qtd_ticks_4_gain_new >= MEA_PASSO_DINAMICO_MIN && m_qtd_ticks_4_gain_new < MEA_PASSO_DINAMICO_MAX;
    }
    return true;
}

void osc_minion_expert::incrementarPasso(){
    if( m_passo_incremento == 0) return;
    
  //m_qtd_ticks_4_gain_new += (int)(m_qtd_ticks_4_gain_new*m_passo_incremento);
    m_qtd_ticks_4_gain_new += m_passo_incremento;
      
    m_qtd_ticks_4_gain_ini = m_qtd_ticks_4_gain_new;
    m_qtd_ticks_4_gain_raj = m_qtd_ticks_4_gain_new;
    m_passo_rajada         = m_qtd_ticks_4_gain_new;
    m_stop_porc            = m_stop_porc/m_passo_incremento;
}

void osc_minion_expert::definirPasso(){
   if( MEA_PASSO_DINAMICO ){
       //m_qtd_ticks_4_gain_new = (int)m_volatilidade_4_seg_media; // testando o passo dinamico com a valatilidade por segundo
       //<TODO> revise o calculo do passo.
       m_qtd_ticks_4_gain_new = (int)(m_passo_dinamico_porc_canal_entrelaca *  m_len_canal_operacional_em_ticks      ); //<TODO> revise o calculo do passo aqui.
     //m_qtd_ticks_4_gain_new = (int)(m_passo_dinamico_porc_canal_entrelaca * (m_len_barra_atual     / m_tick_size)  ); //<TODO> revise o calculo do passo aqui.
       
       //if( m_qtd_ticks_4_gain_new<MEA_PASSO_DINAMICO_MIN ){m_qtd_ticks_4_gain_new=MEA_PASSO_DINAMICO_MIN;}
       //if( m_qtd_ticks_4_gain_new>MEA_PASSO_DINAMICO_MAX ){m_qtd_ticks_4_gain_new=MEA_PASSO_DINAMICO_MAX;}
                                   
       m_qtd_ticks_4_gain_ini =            m_qtd_ticks_4_gain_new;
       m_qtd_ticks_4_gain_raj =            m_qtd_ticks_4_gain_new;
       m_passo_rajada         =      (int)(m_qtd_ticks_4_gain_new*MEA_PASSO_DINAMICO_PORC_T4G);
       if( m_passo_rajada < MEA_PASSO_DINAMICO_MIN )  m_passo_rajada = MEA_PASSO_DINAMICO_MIN;
           
       //MEA_STOP_QTD_CONTRAT
       //MEA_STOP_PORC_L1
       m_stop_qtd_contrat = MEA_PASSO_DINAMICO_STOP_QTD_CONTRAT; 
       m_stop_chunk       = MEA_PASSO_DINAMICO_STOP_CHUNK;
       m_stop_porc        = m_qtd_ticks_4_gain_new*MEA_PASSO_DINAMICO_STOP_REDUTOR_RISCO;
       /*
       switch(m_qtd_ticks_4_gain_new){
           case  1: {m_stop_qtd_contrat = 24; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 24 ticks por chunk; passeio de 240 ticks;
           case  2: {m_stop_qtd_contrat = 12; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 24 ticks por chunk; passeio de 240 ticks;
           case  3: {m_stop_qtd_contrat = 8 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 24 ticks por chunk; passeio de 240 ticks;
           case  4: {m_stop_qtd_contrat = 6 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 24 ticks por chunk; passeio de 240 ticks;
           case  5: {m_stop_qtd_contrat = 5 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 25 ticks por chunk; passeio de 250 ticks;
           case  6: {m_stop_qtd_contrat = 4 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 24 ticks por chunk; passeio de 240 ticks;
           case  7: {m_stop_qtd_contrat = 4 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 28 ticks por chunk; passeio de 280 ticks;
           case  8: {m_stop_qtd_contrat = 3 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 24 ticks por chunk; passeio de 240 ticks;
           case  9: {m_stop_qtd_contrat = 3 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 27 ticks por chunk; passeio de 240 ticks;
           case 10: {m_stop_qtd_contrat = 2 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 20 ticks por chunk; passeio de 240 ticks;
           case 11: {m_stop_qtd_contrat = 2 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 22 ticks por chunk; passeio de 240 ticks;
           case 12: {m_stop_qtd_contrat = 2 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 24 ticks por chunk; passeio de 240 ticks;
           case 13: {m_stop_qtd_contrat = 2 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 26 ticks por chunk; passeio de 240 ticks;
           case 14: {m_stop_qtd_contrat = 2 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 28 ticks por chunk; passeio de 240 ticks;
           case 15: {m_stop_qtd_contrat = 2 ; m_stop_porc = m_qtd_ticks_4_gain_new; break;} // 30 ticks por chunk; passeio de 240 ticks;
       }
       */
   }
}

void osc_minion_expert::inicializarVariaveisRecebidasPorParametro(){

    // stop loss da posicao
    m_stopLossPosicao = MEA_STOP_LOSS;

    // O quanto a volatilidade por segundo deve ser maior que a volatilidade por segundo media para ser considerada alta.
    // Volatilidade por segundo eh o tamanho do canal de transacoes dividido pela quantidade de segundos do indicador feira.
    m_volat4s_alta_porc = MEA_VOLAT4S_ALTA_PORC;

    // O quanto a volatilidade por segundo deve ser maior que a volatilidade por segundo media para acionar o stop.
    // Volatilidade por segundo eh o tamanho do canal de transacoes dividido pela quantidade de segundos do indicador feira.
    m_volat4s_stop_porc = MEA_VOLAT4S_STOP_PORC;

    // porcentagem do canal de entrelacamento usada para definir o passo quando em modo de passo dinamico. 
    m_passo_dinamico_porc_canal_entrelaca = MEA_PASSO_DINAMICO_PORC_CANAL_ENTRELACA;

    // quantidade de periodos usados para calcular o coeficiente de entrelacamento.
    m_qtdPeriodoCoefEntrelaca = MEA_ENTRELACA_PERIODO_COEF;
    
    // coeficiente de entrecamento minimo para permitir entrada na operacao.
    m_entrelacaMinParaOperar  = MEA_ENTRELACA_COEF_MIN;
    
    // regiao nas extremidades do canal de entrelacamento com boa probabilidade do preco retornar para o interior do canal.
    // tambem definida como regiao de compra ou venda.
    // definida em % do canal. ex: 0.2 significa que a estrategia:
    //                             vende  se o preco estah ateh 20% abaixo do topo do canal  
    //                             compra se o preco estah ateh 20% acima  do topo do canal  
    m_porcRegiaoOperacao = MEA_REGIAO_BUY_SELL;
    
    // tamanho maximo em ticks do canal de entrelacamento.
    m_maxDistanciaEntrelacaParaOperar = MEA_ENTRELACA_CANAL_MAX; 
    
    // se o canal de entrelamento ficar maior que esta distancia em ticks, eh acionado o stop loss.
    m_stpDistanciaEntrelacamento      = MEA_ENTRELACA_CANAL_STOP; 

    // aguarda esta quantidade de segundos antes de abrir as primeiras posicoes. Isto possibilita:
    // 1. que os indicadores estejam estabilizados antes da abertura da primeira posicao.
    // 2. que as transferencias de operacao para os VPSs sejam mais suaves.
    m_aguardar_para_abrir_posicao = MEA_SLEEP_INI_OPER*1000;

    // variaveis de controle do stop...
    m_qtd_ticks_4_gain_ini = MEA_QTD_TICKS_4_GAIN_INI;
    m_qtd_ticks_4_gain_raj = MEA_QTD_TICKS_4_GAIN_RAJ;
    m_vol_lote_raj         = MEA_VOL_LOTE_RAJ;
    m_vol_lote_ini         = MEA_VOL_LOTE_INI;
    m_passo_rajada         = MEA_PASSO_RAJ;
    m_stop_qtd_contrat     = MEA_STOP_QTD_CONTRAT;
    m_stop_chunk           = MEA_STOP_QTD_CONTRAT;
    m_stop_porc            = MEA_STOP_PORC_L1;
}

// retorna a porcentagem como um numero inteiro.
int osc_minion_expert::porcentagem( double parte, double tot, int seTotZero){
    if( tot==0 ){ return seTotZero ; }
                  return (int)( (parte/tot)*100.0);
}

void osc_minion_expert::fecharTudo(string descr){ fecharTudo(descr,""); }
void osc_minion_expert::fecharTudo(string descr, string strLog, int qtdTicksDeslocamento=0){
    if( m_qtdPosicoes>0 ){
        fecharPosicao2(descr, strLog, qtdTicksDeslocamento);
    }
    if( m_qtdPosicoes == 0 ){
        m_trade.cancelarOrdens(descr);
        m_precoUltOrdemInBuy = 0;
        m_precoUltOrdemInSel = 0;
    }
}

void osc_minion_expert::fecharPosicao2(string descr, string strLog, int qtdTicksDeslocamento=0){
      
      //1. providenciando ordens de fechamento que porventura faltem na posicao... 
      doCloseRajada(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_raj);
      
      //3. trazendo ordens de fechamento a valor presente...
      m_trade.trazerOrdensComComentarioNumerico2valorPresente(m_symb_str,MEA_STOP_TICKS_TOLER_SAIDA);

      //2. cancelando rajadas que ainda nao entraram na posicao...
      cancelarOrdensRajada();
      
      //3. trazendo ordens de fechamento a valor presente...
      //m_trade.trazerOrdensComComentarioNumerico2valorPresente(m_symb_str,MEA_STOP_TICKS_TOLER_SAIDA);
      
      //4. aguardando a execucao das ordens de fechamento...
      Sleep(50); //<TODO> transforme em parametro
      
      //5. refresh pra saber a situacao atual...
      refreshMe();
       
      //6. se ainda estamos posicionados, realiza todos os passos novamente...
      if( m_qtdPosicoes > 0 ){ fecharPosicao2(descr, strLog, qtdTicksDeslocamento); }
      
      //7. cancelando outras ordens pendentes...
      m_trade.cancelarOrdens(descr);
      m_precoUltOrdemInBuy = 0;
      m_precoUltOrdemInSel = 0;
      
      // Nao conseguiu fechar a posicao. Pode ser que falte ordem de fechamento.
      // Neste caso, chamamos o close rajada para providenciar a ordem de fechamento se necessario.
      // Em seguida, trazemos as ordens de fechamento a valor presente
}

void osc_minion_expert::cancelarOrdensRajada(){ m_trade.cancelarOrdensComentadas(m_symb_str, m_strRajada);}

//void osc_minion_expert::onBookEvent(const string &symbol){
//   //Print("OnbookEvent disparado!!! Symbol=", symbol, " m_symb_str=",m_symb_str);
//   if(symbol!=m_symb_str) return; // garantindo que nao estamos processando o book de outro simbolo,
//   
//   MqlBookInfo book[];
//   MarketBookGet(symbol, book);
//   //ArrayPrint(book);
//   //if(m_tamanhoBook==0){ m_tamanhoBook=ArraySize(book); }
//   
//   m_tamanhoBook=ArraySize(book);
//   if(m_tamanhoBook == 0) { Print(":-( ",__FUNCTION__, " ERRO tamanho do book zero=",m_tamanhoBook ); return;}
//   
//   m_est.addBook( m_time_in_seconds_atu, book, m_tamanhoBook, 0, m_tick_size );
//   m_probAskDescer = m_est.getPrbAskDescer();
//   m_probAskSubir  = m_est.getPrbAskSubir ();
//   m_probBidDescer = m_est.getPrbBidDescer();
//   m_probBidSubir  = m_est.getPrbBidSubir ();
//}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void osc_minion_expert::onTick(){
    refreshMe();

    // Esta opcao NAO_OPERAR nao interfere nas ordens...
    if( MEA_ACAO_POSICAO == NAO_OPERAR ) return;

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
         
         doOpenRajada(m_passo_rajada, MEA_MAX_VOL_EM_RISCO, m_vol_lote_raj , m_qtd_ticks_4_gain_raj); // abrindo rajada...
         
         //doCloseRajada(MEA_PASSO_RAJ, EA05_VOLUME_LOTE_RAJ , m_qtd_ticks_4_gain, false            ); // acionando saida rapida...
    }else{
        
        if( m_qtdOrdens > 0 ){
           if( m_acionou_stop_rebaixamento_saldo             ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return;}

           // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
           if( MEA_ACAO_POSICAO == FECHAR_POSICAO          ){ fecharTudo("OPCAO_FECHAR_POSICAO"         , "OPCAO_FECHAR_POSICAO"         ); return; }
           if( MEA_ACAO_POSICAO == FECHAR_POSICAO_POSITIVA ){ fecharTudo("OPCAO_FECHAR_POSICAO_POSITIVA", "OPCAO_FECHAR_POSICAO_POSITIVA"); return; }

           // cancela as ordens existentes e nao abre novas ordens se o spread for maior que maximo.
           if( spreadMaiorQueMaximoPermitido()               ){ fecharTudo("SPREAD_ALTO_" + DoubleToString(m_symb.Spread()), "SPREAD_ALTO_"+DoubleToString(m_symb.Spread())); return; }

           // cancelando todas as ordens que nao sejam de abertura de posicao...
           // trecho comentado em 03/02/2020. Como os cancelamentos sao por alteracao das ordens, nao precisa mais esta verificacao.
           m_trade.cancelarOrdensExcetoComTxt(m_apmb,"CANC_NOT_APMB"); 

           // nao estah no intervalo de negociacao, tem ordens abertas e nao tem posicao aberta, entao cancelamos todas as ordens.
           if( !m_estah_no_intervalo_de_negociacao ){ m_trade.cancelarOrdens("INTERVALO_NEGOCIACAO");}
           //apmb(nunca fechar), vazio(nunca fechar), numero(sempre fechar, pois soh pode ter ordem com comentario numerico se tiver posicao aberta)...
           //m_trade.cancelarOrdensComComentarioNumerico(_Symbol); // sao as ordens de fechamento de rajada.

           // se tiver ordens RAJADA sem posicao aberta fecha elas...
           //m_trade.cancelarOrdensComentadas(m_strRajada);

           // Parada apos os cancelamentos visando evitar atropelos...
           //Sleep(SLEEP_PADRAO);

           // se tiver ordem sem stop, coloca agora...
           //m_trade.colocarStopEmTodasAsOrdens(m_stopLossOrdens);
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
        //     MEA_STOP_REBAIXAMENTO_MAX != 0  &&
        //     MEA_STOP_REBAIXAMENTO_MAX  < m_rebaixamento_atu ){

        //if ( MEA_STOP_REBAIXAMENTO_MAX                      != 0 &&
        //     m_trade_estatistica.getRebaixamentoSld() < -MEA_STOP_REBAIXAMENTO_MAX ){

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
            m_precoUltOrdemInBuy = 0;
            m_precoUltOrdemInSel = 0;

            m_val_close_position_sel = 0;
            m_vol_close_position_sel = 0;
            m_val_close_position_buy = 0;
            m_vol_close_position_buy = 0;
            return;
        }

        // soh abre novas posicoes apos zerar a penalidade...
        if( m_aguardar_para_abrir_posicao > 0 ) return;

        //switch(MEA_ACAO_POSICAO){
        //  case CONTRA_TEND_DURANTE_COMPROMETIMENTO      : abrirPosicaoDuranteComprometimentoInstitucional(); break;
        //  case CONTRA_TEND_APOS_COMPROMETIMENTO         : abrirPosicaoAposComprometimentoInstitucional   (); break;
        //  case CONTRA_TEND_APOS_ROMPIMENTO_ANTERIOR     : abrirPosicaoAposMaxMinBarraAnterior            (); break;
        //  case HFT_DISTANCIA_PRECO                      : abrirPosicaoHFTdistanciaDoPreco                (); break;
        //  case HFT_MAX_MIN_VOLAT                        : abrirPosMaxMinVolatContraTend                  (); break;
        ////case HFT_TEND_CCI                             : abrirPosicaoCCINaTendencia                     (); break;
        //  case HFT_NA_TENDENCIA                         : abrirPosicaoHFTnaTendencia                     (); break;
        //  case HFT_NORTE_SUL                            : abrirPosicaoHFTnorteSul                        (); break;
        //  case HFT_DESBALANC_BOOK                       : abrirPosicaoHFTDesbalancBook                   (); break;
        //  case HFT_DESBALANC_BOOKNS                     : abrirPosicaoHFTDesbalancBookNorteSul           (); break;
        //  case HFT_MEDIA_TRADE                          : abrirPosicaoHFTNaMediaTrade                    (); break;
        //  case HFT_ARBITRAGEM_VOLUME                    : abrirPosicaoArbitragemVolume                   (); break;
        //  case HFT_HIBRIDO_MAX_MIN_VOL_X_DISTANCIA_PRECO:abrirPosHibridaMaxMinVolatDistanciaPreco        (); break;
        //  case HFT_BB_NA_TENDENCIA                      : abrirPosicaoNaBBNaTendencia                    (); break;
        //  case HFT_DISTANCIA_DA_MEDIA                   : abrirPosicaoHFTdistanciaDaMedia                (); break;
        //  case HFT_FLUXO_ORDENS                         : abrirPosicaoHFTfluxoOrdens                     (); break;
        //  case HFT_REGIAO_CANAL_ENTRELACA               : abrirPosRegiaoCanalEntrelaca                   (); break;
        //  case HFT_PRIORIDADE_NO_BOOK                   : abrirPosicaoHFTPrioridadeNoBook                (); break;
        ////case NAO_ABRIR_POSICAO                   :                                                    break;
        //}
        return;
    }
    return;

}//+------------------------------------------------------------------+

bool osc_minion_expert::podeAbrirProsicao(){

  return ( !m_fechando_posicao                   &&
           //!volatilidadeEstahAlta()            &&
            entrelacamentoPermiteAbrirPosicao()  &&
            distaciaEntrelacamentoPermiteOperar()&&
           !volatilidade4segEstahAlta()          &&
            volat4sPermiteAbrirPosicao()         && // acima desta volatilidade por segundo, nao abre posicao
            taxaVolPermiteAbrirPosicao()         &&
           !emLeilao()                           && //<TODO> voltar e descomentar
           !spreadMaiorQueMaximoPermitido()      &&
           !saldoRebaixouMaisQuePermitidoNoDia() &&
           !saldoAtingiuObjetivoDoDia()          &&
            passoAutorizado()                     // passo deve estar na faixa de passos autorizados para abrir posicao
          );
}

string osc_minion_expert::strPermissaoAbrirPosicao(){

   if( !MEA_SHOW_STR_PERMISSAO_ABRIR_POSICAO ){ return "";}
   return 
   "!m_fechando_posicao                  " + IntegerToString(!m_fechando_posicao                   )+ "\n" +
 //"!volatilidadeEstahAlta               " + IntegerToString(!volatilidadeEstahAlta()              )+ "\n" +
   " entrelacamentoPermiteAbrirPosicao   " + IntegerToString( entrelacamentoPermiteAbrirPosicao()  )+ "\n" +
   " distaciaEntrelacamentoPermiteOperar " + IntegerToString( distaciaEntrelacamentoPermiteOperar())+ "\n" +
   "!volatilidade4segEstahAlta           " + IntegerToString(!volatilidade4segEstahAlta()          )+ "\n" +
   " volat4sPermiteAbrirPosicao          " + IntegerToString( volat4sPermiteAbrirPosicao()         )+ "\n" + // acima desta volatilidade por segundo, nao abre posicao
   " taxaVolPermiteAbrirPosicao          " + IntegerToString( taxaVolPermiteAbrirPosicao()         )+ "\n" +
   "!emLeilao                            " + IntegerToString(!emLeilao()                           )+ "\n" + //<TODO> voltar e descomentar
   "!spreadMaiorQueMaximoPermitido       " + IntegerToString(!spreadMaiorQueMaximoPermitido()      )+ "\n" +
   "!saldoRebaixouMaisQuePermitidoNoDia  " + IntegerToString(!saldoRebaixouMaisQuePermitidoNoDia() )+ "\n" +
   "!saldoAtingiuObjetivoDoDia           " + IntegerToString(!saldoAtingiuObjetivoDoDia()          )+ "\n" +
   " passoAutorizado                     " + IntegerToString(passoAutorizado()                     )         // passo deve estar na faixa de passos autorizados para abrir posicao
   ;
}

void osc_minion_expert::controlarRiscoDaPosicao2(){
   
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
   //if( estouComprado() ){
   //    //mova ordens de venda, acima do preco de saida para o preco de saida.
   //    //m_trade.baixarValorDeOrdensNumericasDeVendaPara(m_precoSaidaPosicao);
   //}else{
   //    //mova ordens de compra, abaixo do preco de saida para o preco de saida.
   //    //m_trade.subirValorDeOrdensNumericasDeCompraPara(m_precoSaidaPosicao);
   //}
   
   return;
}

double osc_minion_expert::calcSaidaPosicao(double volumePosicao ){
    if( volumePosicao < m_stop_qtd_contrat) return  volumePosicao*m_qtd_ticks_4_gain_ini;
    if( volumePosicao < m_stop_chunk* 2.0 ) return  m_lucroPosicao4Gain* 0.95;
    if( volumePosicao < m_stop_chunk* 3.0 ) return  m_lucroPosicao4Gain* 0.9 ;
    if( volumePosicao < m_stop_chunk* 4.0 ) return  m_lucroPosicao4Gain* 0.85;
    if( volumePosicao < m_stop_chunk* 5.0 ) return  m_lucroPosicao4Gain* 0.8 ;
    if( volumePosicao < m_stop_chunk* 6.0 ) return  m_lucroPosicao4Gain* 0.75;
    if( volumePosicao < m_stop_chunk* 7.0 ) return  m_lucroPosicao4Gain* 0.7 ;
    if( volumePosicao < m_stop_chunk* 8.0 ) return  m_lucroPosicao4Gain* 0.65;
    if( volumePosicao < m_stop_chunk* 9.0 ) return  m_lucroPosicao4Gain* 0.6 ;
    if( volumePosicao < m_stop_chunk*10.0 ) return  m_lucroPosicao4Gain* 0.55;
    if( volumePosicao < m_stop_chunk*11.0 ) return  m_lucroPosicao4Gain* 0.5 ;
    if( volumePosicao < m_stop_chunk*12.0 ) return  m_lucroPosicao4Gain* 0.45;
    if( volumePosicao < m_stop_chunk*13.0 ) return  m_lucroPosicao4Gain* 0.4 ;
    if( volumePosicao < m_stop_chunk*14.0 ) return  m_lucroPosicao4Gain* 0.35;
    if( volumePosicao < m_stop_chunk*15.0 ) return  m_lucroPosicao4Gain* 0.3 ;
    if( volumePosicao < m_stop_chunk*16.0 ) return  m_lucroPosicao4Gain* 0.25;
    if( volumePosicao < m_stop_chunk*17.0 ) return  m_lucroPosicao4Gain* 0.2 ;
    if( volumePosicao < m_stop_chunk*18.0 ) return  m_lucroPosicao4Gain* 0.15;
    if( volumePosicao < m_stop_chunk*19.0 ) return  m_lucroPosicao4Gain* 0.1 ;
    if( volumePosicao < m_stop_chunk*20.0 ) return  m_lucroPosicao4Gain* 0.05;
    if( volumePosicao < m_stop_chunk*21.0 ) return  m_lucroPosicao4Gain* 0.0 ;
    if( volumePosicao < m_stop_chunk*22.0 ) return  m_lucroPosicao4Gain*-0.05;
    if( volumePosicao < m_stop_chunk*23.0 ) return  m_lucroPosicao4Gain*-0.1 ;
    if( volumePosicao < m_stop_chunk*24.0 ) return  m_lucroPosicao4Gain*-0.15;
    if( volumePosicao < m_stop_chunk*25.0 ) return  m_lucroPosicao4Gain*-0.2 ;
    if( volumePosicao < m_stop_chunk*26.0 ) return  m_lucroPosicao4Gain*-0.25;
    if( volumePosicao < m_stop_chunk*27.0 ) return  m_lucroPosicao4Gain*-0.3 ;
    if( volumePosicao < m_stop_chunk*28.0 ) return  m_lucroPosicao4Gain*-0.35;
    if( volumePosicao < m_stop_chunk*29.0 ) return  m_lucroPosicao4Gain*-0.4 ;
    if( volumePosicao < m_stop_chunk*30.0 ) return  m_lucroPosicao4Gain*-0.45;
    if( volumePosicao < m_stop_chunk*31.0 ) return  m_lucroPosicao4Gain*-0.5 ;
    if( volumePosicao < m_stop_chunk*32.0 ) return  m_lucroPosicao4Gain*-0.55;
    if( volumePosicao < m_stop_chunk*33.0 ) return  m_lucroPosicao4Gain*-0.6 ;
    if( volumePosicao < m_stop_chunk*34.0 ) return  m_lucroPosicao4Gain*-0.65;
    if( volumePosicao < m_stop_chunk*35.0 ) return  m_lucroPosicao4Gain*-0.7 ;
    if( volumePosicao < m_stop_chunk*36.0 ) return  m_lucroPosicao4Gain*-0.75;
    if( volumePosicao < m_stop_chunk*37.0 ) return  m_lucroPosicao4Gain*-0.8 ;
    if( volumePosicao < m_stop_chunk*38.0 ) return  m_lucroPosicao4Gain*-0.85;
    if( volumePosicao < m_stop_chunk*39.0 ) return  m_lucroPosicao4Gain*-0.9 ;
    if( volumePosicao < m_stop_chunk*40.0 ) return  m_lucroPosicao4Gain*-1.0 ;
    if( volumePosicao < m_stop_chunk*41.0 ) return  m_lucroPosicao4Gain*-1.05;
    if( volumePosicao < m_stop_chunk*24.0 ) return  m_lucroPosicao4Gain*-1.1 ;
    if( volumePosicao < m_stop_chunk*25.0 ) return  m_lucroPosicao4Gain*-1.15;
    if( volumePosicao < m_stop_chunk*26.0 ) return  m_lucroPosicao4Gain*-1.2 ;
    if( volumePosicao < m_stop_chunk*27.0 ) return  m_lucroPosicao4Gain*-1.25;
    if( volumePosicao < m_stop_chunk*28.0 ) return  m_lucroPosicao4Gain*-1.3 ;
    if( volumePosicao < m_stop_chunk*29.0 ) return  m_lucroPosicao4Gain*-1.35;
    if( volumePosicao < m_stop_chunk*30.0 ) return  m_lucroPosicao4Gain*-1.4 ;
    if( volumePosicao < m_stop_chunk*31.0 ) return  m_lucroPosicao4Gain*-1.45;
    if( volumePosicao < m_stop_chunk*32.0 ) return  m_lucroPosicao4Gain*-1.5 ;
    if( volumePosicao < m_stop_chunk*33.0 ) return  m_lucroPosicao4Gain*-1.55;
    if( volumePosicao < m_stop_chunk*34.0 ) return  m_lucroPosicao4Gain*-1.6 ;
    if( volumePosicao < m_stop_chunk*35.0 ) return  m_lucroPosicao4Gain*-1.65;
    if( volumePosicao < m_stop_chunk*36.0 ) return  m_lucroPosicao4Gain*-1.8 ;
    if( volumePosicao < m_stop_chunk*37.0 ) return  m_lucroPosicao4Gain*-1.85;
    if( volumePosicao < m_stop_chunk*38.0 ) return  m_lucroPosicao4Gain*-1.9 ;
    if( volumePosicao < m_stop_chunk*39.0 ) return  m_lucroPosicao4Gain*-1.9 ;
    if( volumePosicao < m_stop_chunk*40.0 ) return  m_lucroPosicao4Gain*-1.95;
    if( volumePosicao < m_stop_chunk*41.0 ) return  m_lucroPosicao4Gain*-2.0 ;
  //if( volumePosicao < m_stop_chunk*31.0 ) return  m_lucroPosicao4Gain*-2.1;
                                            return  m_lucroPosicao4Gain*-2.05;
}

bool osc_minion_expert::controlarRiscoDaPosicao(){

      m_saida_posicao = calcSaidaPosicao(m_posicaoVolumeTot);

   //if( volat4sExigeStop() ){ fecharTudo("STOP_V4S_ALTA"); return true;}
     if( distaciaEntrelacamentoDeveStopar() ){ fecharTudo("STOP_TCE"); return true;}

     if( saldoRebaixouMaisQuePermitidoNoDia() ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return true;}
   //if( m_acionou_stop_rebaixamento_saldo    ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return true;}

     // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
     if( MEA_ACAO_POSICAO == FECHAR_POSICAO                                 ) { fecharTudo("STOP_FECHAR_POSICAO"         ,"STOP_FECHAR_POSICAO"         ); return true; }
     if( MEA_ACAO_POSICAO == FECHAR_POSICAO_POSITIVA && m_posicaoProfit > 0 ) { fecharTudo("STOP_FECHAR_POSICAO_POSITIVA","STOP_FECHAR_POSICAO_POSITIVA"); return true; }


     // se tem posicao aberta, cancelamos as ordens apmb que porventura tenham ficado abertas
     // comentado aqui e colocado dentro de refreshme para que execute uma unica vez apos a abertura de cada posicao.
     //m_trade.cancelarOrdensComentadas(m_apmb);//<TODO: DESCOMENTE e transforme em parametro>

     if( m_lucroPosicao < m_stopLossPosicao && m_capitalInicial != 0 ){
         Print(":-( Acionando STOP_LOSS_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
         fecharTudo("STOP_LOSS_" + DoubleToString(m_lucroPosicao,0) );
         return true;
     }
     //+----------------------------------------------------------------------------------------
     //+ Controle de STOPs em funcao das quantidades totais e pendentes de contratos na posicao.
     //+----------------------------------------------------------------------------------------
     if( m_capitalInicial   != 0                   && // deixe isso aqui, senao dah merda na inicializacao, hehe
         m_posicaoVolumeTot  >= m_stop_qtd_contrat &&
         m_posicaoVolumePend > 0                    ){
         
             // stop se a porcentagem de contratos pendentes for muito alta em relacao a quantidade de contratos totais.
             //if( m_posicaoVolumePend/m_posicaoVolumeTot > EA_STOP_PORC_CONTRAT && EA_STOP_PORC_CONTRAT > 0){
             //    Print(":-( Acionando STOP_QTD_PORC_CONTRATOS_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
             //    m_lucroStops += m_lucroPosicao;
             //    fecharTudo("STOP_QTD_%_CONTRATOS_"+ DoubleToString(m_lucroPosicao,0),1);
             //    return true;
             //}

             
             //+----------------------------------------------------------------------------------------------------
             //+ CONTROLE DOS STOP LOSS INTERMEDIARIOS
             //+----------------------------------------------------------------------------------------------------
             // 2. LOSS: se a quantidade de contratos pendentes estah maior que 2x o inicio do stop, fecha posicao se o loss eh maior que EA_STOP_L2;
             //if( m_posicaoVolumePend >= m_stop_qtd_contrat*2 &&
             //    m_posicaoVolumePend <  m_stop_qtd_contrat*3 &&
             //    m_lucroPosicao      > EA_STOP_L2               ){ 
             //    Print(":-| Acionando STOP_LO_L2_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
             //    m_lucroStops += m_lucroPosicao;
             //    fecharTudo("STOP_LO_L2_" + DoubleToString(m_lucroPosicao,0));
             //    return true;
             //}
             // 3. LOSS: se a quantidade de contratos pendentes estah maior que 3x o inicio do stop, fecha posicao se o loss eh maior que EA_STOP_L3;
             //if( m_posicaoVolumePend >= m_stop_qtd_contrat*3 &&
             //    m_posicaoVolumePend <  m_stop_qtd_contrat*4 &&
             //    m_lucroPosicao      >  EA_STOP_L3               ){
             //    Print(":-( Acionando STOP_LO_LEVEL3_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
             //    m_lucroStops += m_lucroPosicao;
             //    fecharTudo("STOP_LO_L3_" + DoubleToString(m_lucroPosicao,0) );
             //    return true;
             //}
             // 4. LOSS: se a quantidade de contratos pendentes estah maior que 4x o inicio do stop, fecha posicao se o loss eh maior que EA_STOP_L4;
             //if( m_posicaoVolumePend >  m_stop_qtd_contrat*4 &&
             //    m_lucroPosicao      >  EA_STOP_L4               ){
             //    Print(":-( Acionando STOP_LOSS_LEVEL4_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
             //    m_lucroStops += m_lucroPosicao;
             //    fecharTudo("STOP_LO_L4_"+ DoubleToString(m_lucroPosicao,0) );
             //    return true;
             //}
             //+----------------------------------------------------------------------------------------------------

             //+----------------------------------------------------------------------------------------------------
             //+ CONTROLE DOS STOP GAIN INTERMEDIARIOS
             //+----------------------------------------------------------------------------------------------------
             
             if( MEA_STOP_TIPO_CONTROLE_RISCO == 2 ){
                       controlarRiscoDaPosicao2();
             }else{
             //m_saida_posicao = calcSaidaPosicao(m_posicaoVolumeTot);
               if ( m_lucroPosicao > m_saida_posicao ){
                    Print(":-| Acionando STOP_GLX_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                    m_lucroStops += m_lucroPosicao;
                    fecharTudo("STOP_GLX_"+ DoubleToString(m_lucroPosicao,0),
                               "STOP_GLX_"+ DoubleToString(m_lucroPosicao,0), 
                               1 );
                    return true;
               }               
             }
             
             // testando stop por entrelacamento...
             //if( m_coefEntrelaca < 0.35 && m_lucroPosicao > -250 ){
             //if( m_coefEntrelaca < 0.4                             ){
             //       Print(":-| Acionando STOP_ENT_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
             //       m_lucroStops += m_lucroPosicao;
             //       fecharTudo("STOP_ENT_" + DoubleToString(m_lucroPosicao,0), 1 );
             //       return true;
             //}
             
             /*
             else{
             
                 // 1.1 GAIN: quantidade de contratos totais eh maior que 1x o inicio do controle de stops, aplica a % do gain informada em STOP_PORC_L1;
                 if( m_lucroPosicao > m_lucroPosicao4Gain     ){ 
                     Print(":-| Acionando STOP_GAIN_L1_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_GA_L1_" + DoubleToString(m_lucroPosicao,0), 1 );
                     return true;
                 }
                 // 2.1 GAIN: se a quantidade de contratos totais estah maior que 2x o inicio do controle de stops, abate 20% do gain L1;
                 if( m_posicaoVolumeTot >= m_stop_qtd_contrat*2 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*3 &&
                     m_lucroPosicao     > m_lucroPosicao4Gain*0.8 ){                   
                     Print(":-| Acionando STOP_GA_L2_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_GA_L2_" + DoubleToString(m_lucroPosicao,0), 1);
                     return true;
                 }
                 // 3.1 GAIN: se a quantidade de contratos totais estah maior que 3x o inicio do controle de stops, abate 40% do gain L1;
                 if( m_posicaoVolumeTot >= m_stop_qtd_contrat*3 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*4 &&
                     m_lucroPosicao     > m_lucroPosicao4Gain*0.6  ){
                     Print(":-| Acionando STOP_GA_L3_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_GA_L3_" + DoubleToString(m_lucroPosicao,0), 1); 
                     return true;
                 }
                 // 4.1 GAIN: se a quantidade de contratos totais estah maior que 4x o inicio do controle de stops, abate 60% do gain L1;
                 if( m_posicaoVolumeTot >= m_stop_qtd_contrat*4 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*5 &&
                     m_lucroPosicao     > m_lucroPosicao4Gain*0.4 ){        
                     Print(":-| Acionando STOP_GA_L4_"+ DoubleToString(m_lucroPosicao,0), strPosicao(), 1 );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_GA_L4_" + DoubleToString(m_lucroPosicao,0),1);
                     return true;
                 }
                 // 5.1 GAIN: se a quantidade de contratos totais estah maior que 5x o inicio do controle de stops, abate 80% do gain L1;
                 if( m_posicaoVolumeTot >= m_stop_qtd_contrat*5 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*6 &&
                     m_lucroPosicao     > m_lucroPosicao4Gain*0.2 ){        
                     Print(":-| Acionando STOP_GA_L5_"+ DoubleToString(m_lucroPosicao,0), strPosicao(), 1 );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_GA_L5_" + DoubleToString(m_lucroPosicao,0),1);
                     return true;
                 }
                 // 6.1 GAIN: se a quantidade de contratos totais estah maior que 6x o inicio do controle de stops, abate 100% do gain L1;
                 if( m_posicaoVolumeTot > m_stop_qtd_contrat*6 &&
                     m_lucroPosicao     > 0                       ){
                     Print(":-| Acionando STOP_GA_L6_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_GA_L6_" + DoubleToString(m_lucroPosicao,0),1);
                     return true;
                 }
                 // 7.1 LOSS: se a quantidade de contratos totais estah maior que 7x o inicio do controle de stops, aceita 20% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*7 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*8 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain*0.2 ){
                     Print(":-| Acionando STOP_LO_L7_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L7_" + DoubleToString(m_lucroPosicao,0),1);
                     return true;
                 }
                 // 8.1 LOSS: se a quantidade de contratos totais estah maior que 8x o inicio do controle de stops, aceita 40% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*8 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*9 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain*0.4 ){
                     Print(":-| Acionando STOP_LO_L8_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L8_" + DoubleToString(m_lucroPosicao,0),1);
                     return true;
                 }
                 // 9.1 LOSS: se a quantidade de contratos totais estah maior que 9x o inicio do controle de stops, aceita 60% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*9 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*10 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain*0.6 ){
                     Print(":-| Acionando STOP_LO_L9_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L9_" + DoubleToString(m_lucroPosicao,0),1);
                     return true;
                 }
                 // 10.1 LOSS: se a quantidade de contratos totais estah maior que 10x o inicio do controle de stops, aceita 80% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*10 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*11 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain*0.8 ){
                     Print(":-| Acionando STOP_LO_L10_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L10_" + DoubleToString(m_lucroPosicao,0),1);
                     return true;
                 }
                 // 11.1 LOSS: se a quantidade de contratos totais estah maior que 11x o inicio do controle de stops, aceita 100% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*11 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*12 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain   ){
                     Print(":-| Acionando STOP_LO_L11_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L11_" + DoubleToString(m_lucroPosicao,0),1);
                     return true;
                 }
                 // 12.1 LOSS: se a quantidade de contratos totais estah maior que 12x o inicio do controle de stops, aceita 120% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*12 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*13 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain*1.20   ){
                     Print(":-| Acionando STOP_LO_L12_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L12_" + DoubleToString(m_lucroPosicao,0),1); //abrindo mao do gain L1...
                     return true;
                 }
                 // 13.1 LOSS: se a quantidade de contratos totais estah maior que 13x o inicio do controle de stops, aceita 140% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*13 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*14 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain*1.40   ){
                     Print(":-| Acionando STOP_LO_L13_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L13_" + DoubleToString(m_lucroPosicao,0),1); //abrindo mao do gain L1...
                     return true;
                 }
                 // 14.1 LOSS: se a quantidade de contratos totais estah maior que 14x o inicio do controle de stops, aceita 160% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*14 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*15 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain*1.60   ){
                     Print(":-| Acionando STOP_LO_L14_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L14_" + DoubleToString(m_lucroPosicao,0),1); //abrindo mao do gain L1...
                     return true;
                 }
                 // 15.1 LOSS: se a quantidade de contratos totais estah maior que 15x o inicio do controle de stops, aceita 180% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*15 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*16 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain*1.80   ){
                     Print(":-| Acionando STOP_LO_L15_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L15_" + DoubleToString(m_lucroPosicao,0),1); //abrindo mao do gain L1...
                     return true;
                 }
                 // 16.1 LOSS: se a quantidade de contratos totais estah maior que 16x o inicio do controle de stops, aceita 200% do gain L1(negativo) como perda;
                 if( m_posicaoVolumeTot >  m_stop_qtd_contrat*16 &&
                     m_posicaoVolumeTot <  m_stop_qtd_contrat*17 &&
                     m_lucroPosicao     > -m_lucroPosicao4Gain*2.00   ){
                     Print(":-| Acionando STOP_LO_L16_"+ DoubleToString(m_lucroPosicao,0), strPosicao() );
                     m_lucroStops += m_lucroPosicao;
                     fecharTudo("STOP_LO_L16_" + DoubleToString(m_lucroPosicao,0),1); //abrindo mao do gain L1...
                     return true;
                 }
             }
             */
             
             //+----------------------------------------------------------------------------------------------------
     } // FIM DO CONTROLE DE STOPS

     // fecha a posicao ativa a mais de 10 min
     if( m_tempo_posicao_atu > MEA_STOP_10MINUTOS && MEA_STOP_10MINUTOS > 0 ){
         Print(":-( Acionando STOP_LOSS_TEMPO_ALTO_"+ DoubleToString(m_lucroPosicao,0)," T=",m_tempo_posicao_atu," ", strPosicao() );
         m_lucroStops += m_lucroPosicao;
         fecharTudo("STOP_LO_TEMPO_ALTO_"+ DoubleToString(m_lucroPosicao,0));
         return true;
     }

     // testando...
     //if( taxaVolumeEstahAlta() ){
     //    fecharTudo("STOP_TAXA_VOLUME_ALTA","STOP_TAXA_VOLUME_ALTA"); return;
     //}
     return false;
}

string osc_minion_expert::strPosicao(){
   return " Contr="       + DoubleToString (m_posicaoVolumePend,0)+ "/"+
                            DoubleToString (m_posicaoVolumeTot ,0)+
          " SPRE= "       + DoubleToString (m_symb.Spread()    ,2)+
          " VSBUY/SEL="   + DoubleToString (m_volTradePorSegBuy,0)+ "/" + DoubleToString(m_volTradePorSegSel,0)+
          " Incl="        + DoubleToString (m_inclTra          ,2)+
          //" PUP0/1="      + DoubleToString (m_desbUp0*100      ,0)+ "/" + DoubleToString(m_desbUp0*100,0)+
        //" CCI[DIF]="  + DoubleToString ( ( m_icci.Main(0)-m_icci.Main(1) )  ,2)+
          " LUCRP="     + DoubleToString (m_lucroPosicao     ,2)+
        //" T4GI="       + IntegerToString(m_qtd_ticks_4_gain_ini   )+
        //" T4GR="       + IntegerToString(m_qtd_ticks_4_gain_raj   )+
        //" MVDESF="    + IntegerToString(movimentoEmDirecaoDesfavoravel())+
          " Volat="     + DoubleToString (m_volatilidade     ,2)+
          //" CAPINI="    + DoubleToString (m_capitalInicial   ,2)+
          //" CAPLIQ="    + DoubleToString (m_capitalLiquido   ,2)+
          //" LUCRSTOPS=" + DoubleToString (m_lucroStops       ,2)+
          //" Proft="     + DoubleToString (m_posicaoProfit    ,2)+
        //" CAP="       + DoubleToString (m_cta.Equity   ()  ,2)+
        //" SLD="       + DoubleToString (m_cta.Balance  ()  ,2)+
        //" MSLDDIA="   + DoubleToString (m_maior_sld_do_dia ,2)+
        //" RSLD="      + DoubleToString (m_rebaixamento_atu)   +
          " ASK/BID="   + DoubleToString (m_ask,_Digits)        + "/"+ DoubleToString (m_bid,_Digits)+
        //" PMTRADE="   + DoubleToString (m_pmTra            ,2)+
        //" ORDPEN="    + IntegerToString(m_qtdOrdens          )+
          " Leilao="    +                 strEmLeilao()        ;
}

//----------------------------------------------------------------------------------------------------------------------------
// Esta funcao deve ser chamada sempre qua ha uma posicao aberta.
// Ela cria rajada de ordens no sentido da posicao, bem como as ordens de fechamento da posicao baseadas nas ordens da rajada.
// passo    : aumento de preco na direcao contraria a posicao
// volLimite: volume maximo em risco. Maior qtd de ordens pendentes permitida.
// volLote  : volume de ordem aberta na direcao contraria a posicao
// profit   : quantidade de ticks para o gain
//
// versao 02-084: closerajada antes do openrajada.
//                Para abrir logo o close da ordem de abertura da posicao.
//                Estava abrindo as rajadas antes da ordem de fechamento da posicao.
//----------------------------------------------------------------------------------------------------------------------------
bool osc_minion_expert::doOpenRajada(double passo, double volLimite, double volLote, double profit){

   if(passo == 0) return true;
   
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
bool osc_minion_expert::openOrdemRajadaVenda( double passo, double volLimite, double volLote, double profit, double precoOrdem){

     // distancia entre a primeira ordem da posicao e a ordem atual...
     //int distancia =(int)( (m_val_order_4_gain==0)?0:(precoOrdem-m_val_order_4_gain) );

     if(m_val_order_4_gain==0){ 
        Print(":-( openOrdemRajadaVenda() chamado, mas valor de abertura da posicao eh ZERO. VERIFIQUE!!!");
        return false;
     }
     
     precoOrdem = normalizar( m_val_order_4_gain+(passo*m_tick_size) );
   //if(MEA_VOL_MARTINGALE) volLote = volLote*2;
     if(MEA_VOL_MARTINGALE) volLote = volLote+1;
     while(precoOrdem < m_ask){
   //while(precoOrdem < m_bid){
         precoOrdem = normalizar( precoOrdem + (passo*m_tick_size) );
       //if(MEA_VOL_MARTINGALE) volLote = volLote*2;
         if(MEA_VOL_MARTINGALE) volLote = volLote+1;
     }
     
     for(int i=0; i<ea_tamanho_rajada; i++){
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
                #ifndef COMPILE_PRODUCAO if(MEA_DEBUG) Print(":-| HFT_ORDEM OPEN_RAJADA SELL_LIMIT=",precoOrdem, ". Enviando... ",strPosicao() ); #endif
                #ifndef COMPILE_PRODUCAO if(MEA_SLEEP_ATRASO!= 0) Sleep(MEA_SLEEP_ATRASO); #endif 
                
                // essa a parte original antes da alteracao para o passo dinamico
                if( m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, volLote, m_strRajada+getStrComment() ) ){
                    if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem; }
                    //return true;
                }
         }
         precoOrdem = precoOrdem + (passo*m_tick_size);
       //if(MEA_VOL_MARTINGALE) volLote = volLote*2;
         if(MEA_VOL_MARTINGALE) volLote = volLote+1;
     }
     return false;
}

// abre rajada em posicao comprada...
bool osc_minion_expert::openOrdemRajadaCompra( double passo, double volLimite, double volLote, double profit, double precoOrdem){

     // distancia entre a primeira ordem da posicao e a ordem atual...
     //int distancia = (int)( (m_val_order_4_gain==0)?0:(m_val_order_4_gain-precoOrdem) );

     if(m_val_order_4_gain==0){ 
        Print(":-( openOrdemRajadaCompra() chamado, mas valor de abertura da posicao eh ZERO. VERIFIQUE!!!");
        return false;
     }
     
     precoOrdem = normalizar( m_val_order_4_gain-(passo*m_tick_size) );
   //if(MEA_VOL_MARTINGALE) volLote = volLote*2;
     if(MEA_VOL_MARTINGALE) volLote = volLote+1;
     while(precoOrdem > m_bid){
   //while(precoOrdem > m_ask){
         precoOrdem = normalizar( precoOrdem - (passo*m_tick_size) );
       //if(MEA_VOL_MARTINGALE) volLote = volLote*2;
         if(MEA_VOL_MARTINGALE) volLote = volLote+1;
     }

     for(int i=0; i<ea_tamanho_rajada; i++){
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
    
                #ifndef COMPILE_PRODUCAO if(MEA_DEBUG) Print(":-| HFT_ORDEM OPEN_RAJADA BUY_LIMIT=",precoOrdem, ". Enviando...",strPosicao()); #endif
                #ifndef COMPILE_PRODUCAO if( MEA_SLEEP_ATRASO!= 0 ) Sleep(MEA_SLEEP_ATRASO); #endif 

                // essa a parte original antes da alteracao para o passo dinamico
                if( m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, volLote, m_strRajada+getStrComment() ) ){
                    if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem;}
                    //return true;
                }
         }
         precoOrdem = precoOrdem - (passo*m_tick_size);
       //if(MEA_VOL_MARTINGALE) volLote = volLote*2;
         if(MEA_VOL_MARTINGALE) volLote = volLote+1;
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
void osc_minion_expert::doCloseRajada(double passo, double volLote, double profit ){
     #ifndef COMPILE_PRODUCAO if(MEA_DEBUG) m_tcloseRajada=GetMicrosecondCount();#endif
     if( estouVendido() ){
         doCloseRajada2(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_raj, true );
     }else{
         doCloseRajada2(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_raj, false);
     }
     #ifndef COMPILE_PRODUCAO if(MEA_DEBUG) m_tcloseRajada=GetMicrosecondCount()-m_tcloseRajada;#endif
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
bool osc_minion_expert::doCloseRajada2(double passo, double volLote, double profit, bool close_sell){

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
       //Print("DEAL_COMMENT: I=",i, " COMMENT: ", HistoryDealGetString (deal_ticket,DEAL_COMMENT)  );
         if( i==0 ){
             m_deal_comment = HistoryDealGetString (deal_ticket,DEAL_COMMENT);
             if( m_deal_comment != "" && StringFind(m_deal_comment,"IN") < 0 ){
                 fecharPosicao("STOP_RAJADA");
                 Print("STOP_RAJADA DEAL_COMMENT: I=",i, " COMMENT: ", HistoryDealGetString (deal_ticket,DEAL_COMMENT)  );
                 return false;
             }
         }
          
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
                 // se tem ateh 3 rajadas na posicao colocamos o preco da saida igual ao preco da saida da primeira ordem da posicao.
                 //if( m_volVendasNaPosicao > 1 && m_volVendasNaPosicao <= m_stop_qtd_contrat ){
                 //    precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) - profit*m_tick_size*(m_volVendasNaPosicao) );
                 //}else{
                     precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) - profit*m_tick_size                      );
                 //}
                  
                 if(precoProfit > m_ask) precoProfit = m_ask;
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 #ifndef COMPILE_PRODUCAO if(MEA_DEBUG        )Print(":-| HFT_ORDEM CLOSE_RAJADA BUY_LIMIT=",precoProfit, " ID=", idClose, "... ", strPosicao() ); #endif
                 #ifndef COMPILE_PRODUCAO if(MEA_SLEEP_ATRASO!= 0) Sleep(MEA_SLEEP_ATRASO); #endif
                 m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT,precoProfit, vol, idClose);
                 incrementarPasso();
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
                 fecharPosicao("STOP_RAJADA");
                 Print("STOP_RAJADA DEAL_COMMENT: I=",i, " COMMENT: ", HistoryDealGetString (deal_ticket,DEAL_COMMENT)  );
                 return false;
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
                     precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) + profit*m_tick_size                         );
                 //}

                 if(precoProfit < m_bid) precoProfit = m_bid;
                 vol         = HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
                 //if( HistoryDealGetString(deal_ticket,DEAL_COMMENT) == m_apmb ) vol = vol*2;
                 #ifndef COMPILE_PRODUCAO if(MEA_DEBUG        ) Print(":-| HFT_ORDEM CLOSE_RAJADA SELL_LIMIT=",precoProfit, " ID=", idClose, "...", strPosicao() ); #endif
                 #ifndef COMPILE_PRODUCAO if(MEA_SLEEP_ATRASO!= 0) Sleep(MEA_SLEEP_ATRASO); #endif
                 m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,precoProfit, vol, idClose);
                 incrementarPasso();
             }
          }
      }
   }
   return true;
}


string osc_minion_expert::getStrComment(){
  if( MEA_ACAO_POSICAO == HFT_DESBALANC_BOOK   || 
      MEA_ACAO_POSICAO == HFT_DESBALANC_BOOKNS   ){
      return getStrCommentBook();
  }else if(MEA_ACAO_POSICAO==HFT_FLUXO_ORDENS){
      return getStrCommentFluxo();
  }else{
      return getStrCommentEntrelac();
      return 
              " v" +DoubleToString (m_volTradePorSeg                ,0) + // volume de contratos/ticks negociados por segundo
              " d" +IntegerToString(m_volTradePorSegDeltaPorc         ) + //               % delta dos contratos/ticks negociados por segundo.
              " a" +IntegerToString(m_acelVolTradePorSegDeltaPorc     ) + // aceleracao da % delta dos contratos/ticks negociados por segundo.
            //" t" +DoubleToString (m_volatilidade*10               ,0) + // volatilidade
              " t" +DoubleToString (m_volatilidade_4_seg            ,0) + // volatilidade medida por segundo
              " i" +DoubleToString (m_inclTra*10                    ,0) + // inclinacao das agressoes
              " b" +DoubleToString (m_desbUp0*100                   ,0) + // desbalanceamento book na primeira fila
              " b" +DoubleToString (m_desbUp1*100                   ,0) ; // desbalanceamento book na segunda fila
  }
}

string osc_minion_expert::getStrCommentBook(){
  return getStrCommentEntrelac();
  return 
          " v" +DoubleToString (m_volTradePorSeg                ,0) + // volume de contratos/ticks negociados por segundo
          " d" +IntegerToString(m_volTradePorSegDeltaPorc         ) + //               % delta dos contratos/ticks negociados por segundo.
          " a" +IntegerToString(m_acelVolTradePorSegDeltaPorc     ) + // aceleracao da % delta dos contratos/ticks negociados por segundo.
          " b" +DoubleToString (m_desbUp0*100                   ,0) + // desbalanceamento book na primeira fila
          " b" +DoubleToString (m_desbUp1*100                   ,0) + // desbalanceamento book na segunda fila
        //" t" +DoubleToString (m_volatilidade*10               ,0) ; // volatilidade
          " t" +DoubleToString (m_volatilidade_4_seg            ,0) ; // volatilidade medida por segundo
}

string osc_minion_expert::getStrCommentFluxo(){
  return getStrCommentEntrelac();
  return 
        //" v" +DoubleToString (m_volTradePorSeg                ,0) + // volume de contratos/ticks negociados por segundo
        //" t" +DoubleToString (m_volatilidade*10               ,0) + // volatilidade
          " t" +DoubleToString (m_volatilidade_4_seg            ,0) + // volatilidade medida por segundo
          " d" +IntegerToString(m_volTradePorSegDeltaPorc         ) + // % delta dos contratos/ticks negociados por segundo.
          " a" +IntegerToString(m_acelVolTradePorSegDeltaPorc     ) + // aceleracao da % delta dos contratos/ticks negociados por segundo.
//        " s" +DoubleToString (m_probAskSubir*100.0            ,0) + // probabildade do preco subir.
//      //" w" +DoubleToString (m_probAskDescer*100.0           ,0) + // probabildade do preco descer.
          " c" +DoubleToString (m_coefEntrelaca*100             ,0) + // coeficiente de entrelacamento
        //" f" +DoubleToString (m_est.getFluxoAsk()             ,0) + // fluxo na parte Ask do Book
          " g" +DoubleToString (m_est.getFluxoBid()             ,0) ; // fluxo na parte Bid do Book
}

string osc_minion_expert::getStrCommentEntrelac(){
  return 
          " v" +DoubleToString (m_volatilidade_4_seg_media      ,0) + // volatilidade medida por segundo media.
          " p" +DoubleToString (m_est.getPrbAskSubir ()*100     ,0) + // probabildade do preco subir.
          " e" +DoubleToString (m_coefEntrelaca*100             ,0) + // coeficiente de entrelacamento.
          " d" +DoubleToString (m_len_canal_operacional_em_ticks,0) + // tamanho do canal operacional.
          " c" +DoubleToString (m_regiaoPrecoCompra*100         ,0) ; // distancia dos extremos do canal de entrelacamento em porcentagem.
}

bool osc_minion_expert::doTraillingStop(){

   double last = m_symb.Last();// m_minion.last(); // preco do ultimo tick;
   double bid  = m_symb.Bid ();
   double ask  = m_symb.Ask ();

   double lenstop  = m_dx1 * ea_dx_trailling_stop;
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
               if(MEA_DEBUG)Print(m_name,":COMPRADO: [OPEN "   ,m_precoPosicao,
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
                  if(MEA_DEBUG)Print(m_name,":VENDIDO: [OPEN ",m_precoPosicao,
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
       #ifndef COMPILE_PRODUCAO if(MEA_DEBUG)Print("TSTOP COMPRADO: bid:"+DoubleToString(bid,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );#endif
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       //HLineDelete(0,m_line_tstop);
       //ChartRedraw(0);

       return true;
   }
   if( ( estouVendido() && m_tstop != 0 ) &&
       ( ( ask > m_tstop && ask < m_precoPosicao ) )
     ){
       #ifndef COMPILE_PRODUCAO if(MEA_DEBUG)Print("TSTOP VENDIDO: ask:"+DoubleToString(ask,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );#endif
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       //HLineDelete(0,m_line_tstop);
       //ChartRedraw(0);

       return true;
   }
   return false;
}

bool osc_minion_expert::doTraillingStop2(){

   //m_symb.Refresh();
   //m_ibb.Refresh(-1);

   double last = m_symb.Last();// m_minion.last(); // preco do ultimo tick;
   double bid  = m_symb.Bid ();
   double ask  = m_symb.Ask ();

   double lenstop       = m_dx1 * ea_dx_trailling_stop;
   double sl            = 0;
   double posicaoProfit = 0;

   if( lenstop < 30 ) lenstop = 30;

   // calculando o trailling stop...
   if( m_trade.estouComprado() ){
       sl = bid - lenstop - m_symb.Spread(); // SL eh fixo
       //tstop = sl;         // tstop varia assim que o lucro passar sl

      if ( m_tstop < sl || m_tstop == 0 ) {
           m_tstop = sl;
           #ifndef COMPILE_PRODUCAO
               if(MEA_DEBUG)Print(m_name,":COMPRADO2: [OPEN "   ,m_precoPosicao,
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
                  if(MEA_DEBUG)Print(m_name,":VENDIDO2: [OPEN ",m_precoPosicao,
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
       #ifndef COMPILE_PRODUCAO if(MEA_DEBUG)Print("TSTOP2 COMPRADO2: bid:"+DoubleToString(bid,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );#endif
       fecharPosicao("TRLSTP2");

       return true;
   }
   if( ( estouVendido() && m_tstop != 0 ) &&
       ( ( ask > m_tstop && ask < m_precoPosicao ) )
     ){
       #ifndef COMPILE_PRODUCAO if(MEA_DEBUG)Print("TSTOP2 VENDIDO2: ask:"+DoubleToString(ask,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" ); #endif
       fecharPosicao("TRLSTP2");

       return true;
   }
   return false;
}


string osc_minion_expert::status(){
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
void osc_minion_expert::onDeinit(const int reason)  {
                                          Print(m_name,":-| Expert ", m_name, " Iniciando metodo OnDeinit..." );
    delLineMinPreco();                    Print(m_name,":-| Expert ", m_name, " Linha de preco minimo elimnada." );
    delLineMaxPreco();                    Print(m_name,":-| Expert ", m_name, " Linha de preco maximo elimnada." );
    delLineTimeDesdeEntrelaca();          Print(m_name,":-| Expert ", m_name, " Linha horizontal entrelacamento eliminada." );
    delLineMaiorPrecoCompra();            Print(m_name,":-| Expert ", m_name, " Linha horizontal regiao de compra." );
    delLineMenorPrecoVenda();             Print(m_name,":-| Expert ", m_name, " Linha horizontal regiao de venda."  );
    EventKillTimer();                     Print(m_name,":-| Expert ", m_name, " Timer destruido." );
    
    
  //m_feira.DeleteFromChart(0,0);         Print(m_name,":-| Expert ", m_name, " Indicador feira retirado do grafico." );
  //IndicatorRelease( m_feira.Handle() ); Print(m_name,":-| Expert ", m_name, " Manipulador do indicador feira liberado." );
    MarketBookRelease(m_symb_str);        Print(m_name,":-| Expert ", m_name, " Manipulador do Book liberado." );
    //IndicatorRelease( m_icci.Handle()  ); Print(m_name,":-| Expert ", m_name, " Manipulador do indicador cci   liberado." );
    //IndicatorRelease( m_ibb.Handle()    );
    //m_cp.Destroy(reason);                 Print(m_name,":-| Expert ", m_name, " Painel de controle destruido." );
    Comment("");                          Print(m_name,":-| Expert ", m_name, " Comentarios na tela apagados." );
                                          Print(m_name,":-) Expert ", m_name, " OnDeinit finalizado!" );
    return;
}

//+-----------------------------------------------------------+
//|                                                           |
//+-----------------------------------------------------------+
void osc_minion_expert::onTradex(){

      if( m_fechando_posicao && m_ordem_fechamento_posicao > 0 ){

              if( HistoryOrderSelect(m_ordem_fechamento_posicao) ){

                     ENUM_ORDER_STATE order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
                     if( order_state == ORDER_STATE_FILLED   ||    //Ordem executada completamente
                         order_state == ORDER_STATE_REJECTED ||    //Ordem rejeitada
                         order_state == ORDER_STATE_EXPIRED  ||    //Ordem expirada
                         order_state == ORDER_STATE_CANCELED ){    //Ordem cancelada pelo cliente

                         #ifndef COMPILE_PRODUCAO if(MEA_DEBUG)Print( ":-| Ordem de fechamento de posicao CONCLUIDA! ticket=", m_ordem_fechamento_posicao, " status=", EnumToString(order_state), strPosicao() );#endif
                         m_fechando_posicao         = false;
                         m_ordem_fechamento_posicao = 0;
                     }else{
                         #ifndef COMPILE_PRODUCAO if(MEA_DEBUG)Print( ":-| Ordem de fechamento de posicao PENDENTE! ticket=", m_ordem_fechamento_posicao, " status=", EnumToString(order_state), strPosicao() );#endif
                     }
              }else{
                     #ifndef COMPILE_PRODUCAO if(MEA_DEBUG)Print( ":-| Ordem de fechamento de posicao NAO ENCONTRADA! ticket=", m_ordem_fechamento_posicao, strPosicao() );#endif
                     m_fechando_posicao         = false;
                     m_ordem_fechamento_posicao = 0;
              }
      }
}

//----------------------------------------------------------------------------------------------------
// 
// 1. Atualizando as variaveis de tempo atual m_time_in_seconds e m_date.
// 2. Executa funcoes que dependem das variaveis m_time_in_seconds ou m_date atualizadas e 
//    suas respectivas anteriores atualizas.
// 3. Atualizando variaveis de comparacao de data anterior e atual m_time_in_seconds_ant e m_date_ant.
//
//----------------------------------------------------------------------------------------------------
void osc_minion_expert::onTimer(){
    
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
  //calcRun(EA_MINUTOS_RUN,m_passo_rajada);                                  // calculando o indice de runs baseado no passo atual
  //calcRun(m_passo_rajada);                                                 // calculando o indice de runs baseado no passo atual
  //refreshControlPanel();
    controlarTimerParaAbrirPosicao();

    calcCoefEntrelacamentoMedio();
    calcOpenMaxMinDia();

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
   
   //if (MEA_SHOW_TELA) m_trade_estatistica.calcRelacaoVolumeProfit(m_time_in_seconds_ini_day, m_time_in_seconds_atu);
                       m_trade_estatistica.refresh(m_time_in_seconds_ini_day, m_time_in_seconds_atu);
       
}
//----------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------
// 1. Faz o shift das velocidades de volume registradas e despreza a mais antiga
// 2. Substitui a ultima velocidade pela mais atual
// 3. Recalcula a aceleracao da velocidade do volume
//----------------------------------------------------------------------------------------------------
//int    m_vet_vel_volume_len = 60;
//double m_vet_vel_volume[60];
//int    m_acelVolTradePorSegDeltaPorc = 0;
//----------------------------------------------------------------------------------------------------
void osc_minion_expert::calcularAceleracaoVelTradeDeltaPorc(){
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
bool osc_minion_expert::estah_no_intervalo_de_negociacao(){

    //if( m_date_atu.hour == 16 && m_date_atu.min == 1){
    //   Print("Break Point!!!!");
    //}

    // informando a mudanca do dia (usada no controle do rebaixamento de saldo maximo da sessao).
    if( m_date_ant.day != m_date_atu.day ){ m_mudou_dia = true; m_time_in_seconds_ini_day = StringToTime( TimeToString( TimeCurrent(), TIME_DATE )); }

    // restricao para nao operar no inicio nem no final do dia...
    if(m_date_atu.hour <   MEA_HR_INI_OPERACAO     ) {  return false; } // operacao antes de 9:00 distorce os testes.
    if(m_date_atu.hour >=  MEA_HR_FIM_OPERACAO + 1 ) {  return false; } // operacao apos    18:00 distorce os testes.

    if(m_date_atu.hour == MEA_HR_INI_OPERACAO && m_date_atu.min < MEA_MI_INI_OPERACAO ) { return false; } // operacao antes de 9:10 distorce os testes.
    if(m_date_atu.hour == MEA_HR_FIM_OPERACAO && m_date_atu.min > MEA_MI_FIM_OPERACAO ) { return false; } // operacao apos    17:50 distorce os testes.

    //if( m_date_atu.year==2020 &&
    //    m_date_atu.mon ==2    &&
    //    m_date_atu.day ==26   &&
    //    m_date_atu.hour==13   &&
    //    m_date_atu.min < 30    ) { return false; } // para permitir teste na quarta-feira de cinzas.
    return true;
}
//----------------------------------------------------------------------------------------------------


// controle da permissao para abrir posicoes em funcao de um tempo de penalidade.
// novas posicoes soh podem ser abertas se a penalidade(m_aguardar_para_abrir_posicao) estiver zerada.
void osc_minion_expert::controlarTimerParaAbrirPosicao(){
    if( m_aguardar_para_abrir_posicao > 0 ){ m_aguardar_para_abrir_posicao -= MEA_QTD_MILISEG_TIMER; }
    if( m_aguardar_para_abrir_posicao < 0 ){ m_aguardar_para_abrir_posicao  = 0                   ; }    
}

void osc_minion_expert::onChartEvent(const int    id     , 
                  const long   &lparam, 
                  const double &dparam, 
                  const string &sparam){

    // servico de calculo de runs...
    if(id==SVC_RUN+CHARTEVENT_CUSTOM){ m_strRun = "\n\n" + sparam; }
}

void osc_minion_expert::calcRun(int pLenChunk){
    
    OscRun cRun;
    //MqlTick ticks[]; //vetor de ticks que serao processados;
    double  price[]; //vetor de precos (obtidos do historico de ticks);
    int     run1 []; //vetor de runs positivas;
    int     run2 []; //vetor de runs negativas;
   
  //Print("Buscando ticks para calculo do indice run...");
    //int qtdTicks = CopyTicksRange(m_symb_str,ticks,COPY_TICKS_INFO,TimeCurrent()*1000 - (60000*pQtdMinutos), TimeCurrent()*1000 );
      int qtdTicks = m_est.copyPriceTo(price);

    cRun.calcRuns(price,qtdTicks,pLenChunk,m_tick_size,run1,run2);
    m_indRun = cRun.calcIndice(run1,run2);
    
    cRun.calcRuns(price,qtdTicks,pLenChunk-1,m_tick_size,run1,run2);
    m_indRunMenos1 = cRun.calcIndice(run1,run2);

    cRun.calcRuns(price,qtdTicks,pLenChunk+1,m_tick_size,run1,run2);
    m_indRunMais1 = cRun.calcIndice(run1,run2);

    m_indVarRun       = m_indRunAnt      -m_indRun      ;
    m_indVarRunMenos1 = m_indRunMenos1Ant-m_indRunMenos1;
    m_indVarRunMais1  = m_indRunMais1Ant -m_indRunMais1 ;

    m_indRunAnt       = m_indRun      ;
    m_indRunMenos1Ant = m_indRunMenos1;
    m_indRunMais1Ant  = m_indRunMais1 ;

    // Printando as runs a cada 50 execucoes do OnTimer...
    if( m_qtd_periodos_run++ < 50 ){ return; }
    m_qtd_periodos_run = 0;
    Print("Informados ",qtdTicks, ". Copiados ", ArraySize(price) );

}    

string m_str_line_max_price             = "line_max_price";
string m_str_line_min_price             = "line_min_price";
string m_str_line_maior_preco_compra    = "str_line_maior_preco_compra";
string m_str_line_menor_preco_venda     = "str_line_menor_preco_venda";
string m_str_line_time_desde_entrelaca  = "line_time_desde_entrelaca";
bool m_line_min_preco_criada            = false;
bool m_line_max_preco_criada            = false;
bool m_line_maior_preco_compra_criada   = false;
bool m_line_menor_preco_venda_criada    = false;
bool m_line_time_desde_entrelaca_criada = false;

void osc_minion_expert::drawLineMaxPreco(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_max_preco_criada ){ 
            HLineMove(0,m_str_line_max_price,m_maxPrecoCanal);
        }else{
            HLineCreate(0,m_str_line_max_price,0,m_maxPrecoCanal,clrMediumBlue,STYLE_SOLID,1,false,true,false,0);
            m_line_max_preco_criada = true;
        }
        ChartRedraw(0);
    }
    //Print("MEA_SHOW_CANAL_PRECOS=",MEA_SHOW_CANAL_PRECOS);
}

void osc_minion_expert::drawLineMinPreco(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_min_preco_criada ){ 
            HLineMove(0,m_str_line_min_price,m_minPrecoCanal);
        }else{
            HLineCreate(0,m_str_line_min_price,0,m_minPrecoCanal,clrRed,STYLE_SOLID,1,false,true,false,0);
            m_line_min_preco_criada = true;
        }
        ChartRedraw(0);
    }
}

void osc_minion_expert::drawLineMaiorPrecoCompra(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_maior_preco_compra_criada ){ 
            HLineMove(0,m_str_line_maior_preco_compra,m_maiorPrecoDeCompra);
        }else{
            HLineCreate(0,m_str_line_maior_preco_compra,0,m_maiorPrecoDeCompra,clrDarkGray,STYLE_DOT,1,false,true,false,0);
            m_line_maior_preco_compra_criada = true;
        }
        ChartRedraw(0);
    }
}

void osc_minion_expert::drawLineMenorPrecoVenda(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_menor_preco_venda_criada ){ 
            HLineMove(0,m_str_line_menor_preco_venda,m_menorPrecoDeVenda);
        }else{
            HLineCreate(0,m_str_line_menor_preco_venda,0,m_menorPrecoDeVenda,clrDarkGray,STYLE_DOT,1,false,true,false,0);
            m_line_menor_preco_venda_criada = true;
        }
        ChartRedraw(0);
    }
}

void osc_minion_expert::drawLineTimeDesdeEntrelaca(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_time_desde_entrelaca_criada ){ 
            VLineMove(0,m_str_line_time_desde_entrelaca,m_time_desde_entrelaca); 
        }else{
            VLineCreate(0,m_str_line_time_desde_entrelaca,0,m_time_desde_entrelaca,clrSteelBlue,STYLE_SOLID,1,false,true,false,0);
            m_line_time_desde_entrelaca_criada = true;
        }
        ChartRedraw(0);
    }
}

void osc_minion_expert::delLineMinPreco          (){HLineDelete(0,m_str_line_min_price           ); m_line_min_preco_criada            = false;}
void osc_minion_expert::delLineMaxPreco          (){HLineDelete(0,m_str_line_max_price           ); m_line_max_preco_criada            = false;}
void osc_minion_expert::delLineTimeDesdeEntrelaca(){VLineDelete(0,m_str_line_time_desde_entrelaca); m_line_time_desde_entrelaca_criada = false;}
void osc_minion_expert::delLineMaiorPrecoCompra  (){HLineDelete(0,m_str_line_maior_preco_compra  ); m_line_maior_preco_compra_criada   = false;}
void osc_minion_expert::delLineMenorPrecoVenda   (){HLineDelete(0,m_str_line_menor_preco_venda   ); m_line_menor_preco_venda_criada    = false;}


void osc_minion_expert::calcDistPrecoMaxMin(){
    if(MEA_USA_REGIAO_CANAL_DIA){
        m_dxPrecoMaxEmTicks = (m_maxPrecoCanal - m_bid     )/m_tick_size;
        m_dxPrecoMinEmTicks = (m_bid      - m_minPrecoCanal)/m_tick_size;
    }else{
        m_dxPrecoMaxEmTicks = (m_maxPrecoCanal - m_bid     )/m_tick_size;
        m_dxPrecoMinEmTicks = (m_bid      - m_minPrecoCanal)/m_tick_size;
    }

    if( m_len_canal_operacional_em_ticks != 0 ){
        m_regiaoPrecoCompra = (m_dxPrecoMinEmTicks / m_len_canal_operacional_em_ticks);
        m_regiaoPrecoVenda  = 1-m_regiaoPrecoCompra                        ;
    }
}

void osc_minion_expert::calcMaiorPrecoDeCompraVenda(){
    double newMaiorPrecoDeCompra = 0;
    double newMenorPrecoDeVenda  = 0;

    m_len_canal_operacional_em_ticks = (m_maxPrecoCanal - m_minPrecoCanal)/m_tick_size;
    
//  if( MEA_USA_REGIAO_CANAL_DIA ){
        // usando a regiao do canal do dia de operacao
        newMaiorPrecoDeCompra = m_minPrecoCanal + (m_len_canal_operacional_em_ticks*m_porcRegiaoOperacao*m_tick_size);
        newMenorPrecoDeVenda  = m_maxPrecoCanal - (m_len_canal_operacional_em_ticks*m_porcRegiaoOperacao*m_tick_size);
//  }else{
//      // usando a regiao do canal de entrelacamento 
//      maiorPrecoDeCompra = m_minPrecoCanal + (m_len_canal_operacional_em_ticks*m_porcRegiaoOperacao*m_tick_size); 
//      menorPrecoDeVenda  = m_maxPrecoCanal - (m_len_canal_operacional_em_ticks*m_porcRegiaoOperacao*m_tick_size);
//  }
        
    if( newMaiorPrecoDeCompra != m_maiorPrecoDeCompra ){
        m_maiorPrecoDeCompra = newMaiorPrecoDeCompra; 
        drawLineMaiorPrecoCompra();
    }
        
    if( newMenorPrecoDeVenda != m_menorPrecoDeVenda   ){
        m_menorPrecoDeVenda  = newMenorPrecoDeVenda;
        drawLineMenorPrecoVenda();
    }
}

// obtendo a barras de preco do dia
void osc_minion_expert::calcOpenMaxMinDia(){ 
    CopyRates(m_symb_str,PERIOD_D1,0,1,m_ratesDia);
    //ArraySetAsSeries(m_ratesDia,true); // array tem tamanho igual a 1. Nao necessita este metodo.
    if( m_ratesDia[0].high != m_maxPrecoCanal ){ 
        m_maxPrecoCanal = m_ratesDia[0].high; 
        drawLineMaxPreco(); 

        //m_len_canal_operacional_em_ticks = (m_maxPrecoCanal - m_minPrecoCanal)/m_tick_size;
        calcMaiorPrecoDeCompraVenda(); 
        m_direcaoDia   = m_ratesDia[0].close - m_ratesDia[0].open; // se for negativo eh dia de baixa.
    }
    
    if( m_ratesDia[0].low  != m_minPrecoCanal ){ 
        m_minPrecoCanal = m_ratesDia[0].low ; 
        drawLineMinPreco(); 
        //m_len_canal_operacional_em_ticks = (m_maxPrecoCanal - m_minPrecoCanal)/m_tick_size;
        calcMaiorPrecoDeCompraVenda(); 
        m_direcaoDia   = m_ratesDia[0].close - m_ratesDia[0].open; // se for negativo eh dia de baixa.
    }
    
}

//|-------------------------------------------------------------------------------------
//| O coeficiente de entrelacamento eh a porcentagem de intersecao do preco da barra
//| atual em relacao a barra anterior.
//|
//| Esta funcao retorna o coeficiente de entrelacacamento medio dos ultimos x periodos 
//|-------------------------------------------------------------------------------------
void osc_minion_expert::calcCoefEntrelacamentoMedio(){
 
    // calculando a cada segundo impar...
    //if( m_date_ant.sec   == m_date_atu.sec ||   // espera mudar o segundo para calcular
    //    m_date_atu.sec%2 == 0                ){ // calcula sempre no segundo impar
    //    return; 
    //}
    
    //Print("MEA_USA_REGIAO_CANAL_DIA=",MEA_USA_REGIAO_CANAL_DIA);
    if( MEA_USA_REGIAO_CANAL_DIA ) return;
    
    double totCoef    = 0;
    int    peso       = m_qtdPeriodoCoefEntrelaca;
    int    totPeso    = 0;
    int    starPos    = 0;
   
    // obtendo as ultimas barras de preco
    //Print("m_symb_str=",m_symb_str,
    //      " _Period=",_Period,
    //      " starPos=",starPos,
    //      " m_qtdPeriodoCoefEntrelaca=",m_qtdPeriodoCoefEntrelaca);
    
    //if( m_qtdPeriodoCoefEntrelaca == 0 ){ Print(":-( ", __FUNCTION__,": m_qtdPeriodoCoefEntrelaca estah zerado. Nao eh possivel calcular o coeficiente de entrelacamento medio!! VERIFIQUE!!!" ); return;}
    
    CopyRates(m_symb_str,_Period,starPos,m_qtdPeriodoCoefEntrelaca,m_ratesEntrelaca);
    ArraySetAsSeries(m_ratesEntrelaca,true);

    double   maxPreco             = m_ratesEntrelaca[0].high;
    double   minPreco             = m_ratesEntrelaca[0].low ;
    datetime time_desde_entrelaca = m_ratesEntrelaca[m_qtdPeriodoCoefEntrelaca-1].time;

    // calculando direcao nas barras de entrelacamento. resultado positivo eh alta, negativo eh baixa.
    m_direcao_entre = m_ratesEntrelaca[0].close - m_ratesEntrelaca[m_qtdPeriodoCoefEntrelaca-1].open;
    
    for( int i=0; i<m_qtdPeriodoCoefEntrelaca-1; i++){
        totCoef += calcCoefEntrelacamento( m_ratesEntrelaca[i+1].low, m_ratesEntrelaca[i+1].high, 
                                           m_ratesEntrelaca[i]  .low, m_ratesEntrelaca[i]  .high )*peso;

        totPeso += peso;
        peso--;
        
        if( m_ratesEntrelaca[i+1].high > maxPreco){ maxPreco = m_ratesEntrelaca[i+1].high; }
        if( m_ratesEntrelaca[i+1].low  < minPreco){ minPreco = m_ratesEntrelaca[i+1].low ; }            
    }
    
    m_coefEntrelaca = totCoef/totPeso;
    
    // atualizando a distancia usada no calculo do entrelacamento...
    if( maxPreco != m_maxPrecoCanal || minPreco != m_minPrecoCanal ) m_len_canal_operacional_em_ticks = (maxPreco-minPreco)/m_tick_size;
    
    if( maxPreco != m_maxPrecoCanal ){ m_maxPrecoCanal = maxPreco; drawLineMaxPreco(); calcMaiorPrecoDeCompraVenda(); }
    if( minPreco != m_minPrecoCanal ){ m_minPrecoCanal = minPreco; drawLineMinPreco(); calcMaiorPrecoDeCompraVenda(); }

    if( m_time_desde_entrelaca != time_desde_entrelaca ){ m_time_desde_entrelaca = time_desde_entrelaca; drawLineTimeDesdeEntrelaca(); }   
}



//|--------------------------------------------------------------------------------
//| O coeficiente de entrelacamento eh a porcentagem de intersecao do preco da barra
//| atual em relacao a barra anterior. 
//|
//| Ant   ----------
//| Atu        -------
//| Int        xxxxx
//|
//| Ant    ----------
//| Atu  -------
//| Int    xxxxx
//|
//| Ant    ----------
//| Atu     -------
//| Int     xxxxxxx
//|
//| Ant    ----------
//| Atu               -------
//| Int             
//|
//| Ant    ----------
//| Atu ---
//| Int    
//|
//|--------------------------------------------------------------------------------
double osc_minion_expert::calcCoefEntrelacamento(double minAnt, double maxAnt, double minAtu, double maxAtu){
   
   double pontosEntre = 0;
   
   // minimo da barra atual estah na barra anterior...
   if( minAtu >= minAnt && minAtu <= maxAnt ){
   
       if( maxAtu > maxAnt ){ 
           // ---------|
           //     ---------|
           //     xxxxx
           pontosEntre = maxAnt - minAtu;
       }else{
           // ---------
           //     -----
           //     xxxxx
           pontosEntre = maxAtu - minAtu;
       }
   }else{
       // maximo da barra atual estah na barra anterior...
       if( maxAtu >= minAnt && maxAtu <= maxAnt ){
       
           if( minAtu < minAnt ){ 
               //         ---------
               //     ---------
               //         xxxxx
               pontosEntre = maxAtu - minAnt;
           }else{
               // ---------
               // -----
               // xxxxx
               pontosEntre = maxAtu - minAtu;
           }
       }
   }
   
   // encontrando os maiores maximos e minimos
   double max = (maxAnt>maxAtu)?maxAnt:maxAtu;
   double min = (minAnt<minAtu)?minAnt:minAtu;
   
   
 //if(maxAtu-minAtu == 0) return 0;
   if(max-min == 0) return 0;
   
 //return pontosEntre/(maxAtu-minAtu);   
   return pontosEntre/(max-min);   
}