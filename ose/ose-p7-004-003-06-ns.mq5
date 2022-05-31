//+------------------------------------------------------------------+
//|                                         ose-p7-004-003-06-ns.mq5 |
//|                                          Copyright 2021, OS Corp |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao p7-004                                                    |
//| 1. Superficie de operacao usando OntradeTransaction para         |
//|    a abertura ou inclusao de ordens em uma posicao e disparar    |
//|    as ordens de fechamento. Reflete diretamente no closerajada,  |
//|    que eh mais lento devido a pesquisa das ordens de uma posicao |
//|    no historico de ordens.                                       |
//|                                                                  |
//|    Fechamento de posicoes por stop passa a ser pelo valor de     |
//|    m_precoSaidaPosicao, visando sua simplificacao.               |
//|                                                                  |
//| Versao p7-004-003                                                |
//|    Superficie para operacao com spread (norte-sul)               |
//|                                                                  |
//| Versao p7-004-003-00                                             |
//|    21/05/2021                                                    |
//|   -Versao inicial criada a partir da 004-002-00                  |
//|    Essa versao eh feita para entrada manual.                     |
//|    Cria ordens no sentido oposto a cada deal.                    |
//|                                                                  |
//|    - Tecla F: coloca o EA modo fechar-todas-as-posicoes, embora  |
//|      feche apenas a posicao do ativo 1.                          |
//|                                                                  |
//|    - Tecla SHIFT+F: coloca novamente o EA no modo de aceitar     |
//|      novas ordens.                                               |
//|                                                                  |
//| Versao p7-004-003-01                                             |
//|    - Corrigido BUG:                                              |
//|      - Operar o segundo ativo ainda que nao haja posicao no      |
//|        primeiro.                                                 |
//|                                                                  |
//|    - Melhorias                                                   |
//|      - Opcao para nao calcular regressao linear.                 |
//|      - Opcao para nao calcular CUSUM.                            |
//|      - Cancela ordens de entrada com volume maior que o param.   |
//|      - Cancela ordens de entrada duplicadas.                     |
//|                                                                  |
//|    - pretente corrigir bugs:                                     |
//|      - Tecla para fechar a posicao do segundo ativo.             |
//|      - Ter stop separado por ativo (ver se eh melhor)            |
//|                                                                  |
//| Versao p7-004-003-03                                             |
//|    - Primeiro uso de floresta aleatoria.                         |
//|      - coleta de regressao linear com RDF, mas nao a usa.        |
//|                                                                  |
//| Versao p7-004-003-04                                             |
//|    - Aprimorado para entrada manual.                             |
//|                                                                  |
//| Versao p7-004-003-05                                             |
//|    - Primeiro uso de rede neural.                                |
//|                                                                  |
//| Versao p7-004-003-06                                             |
//|    - Aprimorando uso do book. Nao usa a rede neural.             |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#define COMPILE_PRODUCAO

#property copyright "Copyright 2021, OS Corp."
#property link      "http://www.os.org"
#property version   "4.003"

//#include <Generic\Queue.mqh>
//#include <Generic\HashMap.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//#include <Indicators\Trend.mqh>

//#include <oslib\os-lib.mq5>
#include <oslib\osc-tick-util.mqh>
#include <oslib\osc\est\osc-estatistic3.mqh>
//#include <oslib\osc\est\C0002ArbitragemPar.mqh>
#include <oslib\osc\est\C00021Pairs.mqh>
#include <oslib\osc\osc-minion-trade-03.mqh>
#include <oslib\osc\osc-minion-trade-estatistica.mqh>
#include <oslib\osc\osc-media.mqh>
#include <oslib\osc\trade\osc_position.mqh>
#include <oslib\osc\exp\C0004GerentePosicao.mqh>
#include <oslib\osc\exp\C0601StrategyDeepImbalance.mqh>
#include <oslib\osc\osc-pivo-points.mqh>
#include <oslib\osc\est\C0007ModelRDF.mqh>
#include <oslib\osc\est\C00100NetPerceptronBook.mqh>

//#include <oslib\svc\osc-svc.mqh>
//#include <oslib\svc\run\cls-run.mqh>

#include <oslib\osc\cp\osc-pc-p7-002-004-vel-vol.mqh> //painel de controle
#include <oslib\osc\osc-canal.mqh> //canais
//#include <oslib\osc\est\C0001FuzzyModel.mqh> // modelo para medir risco de entrar em uma operar
#include <oslib\osc\data\osc-cusum.mqh> // implemantacao do algoritmo cumulative sum.
#include <oslib\osc\data\osc-book.mqh> // implemantacao do algoritmo de gerenciamento do book.

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
     NAO_ABRIR_POSICAO                    , //NAO_ABRIR_POSICAO Entre manualmente e deixar o EA sair.
     //HFT_OPERAR_VOLUME_CANAL            , //HFT_OPERAR_VOLUME_CANAL
     HFT_OPERAR_CANAL_EM_PAR              , //HFT_OPERAR_CANAL_EM_PAR compra na regiao inferior e venda na regiao superior
     HFT_FORMADOR_DE_MERCADO              , //HFT_FORMADOR_DE_MERCADO
     HFT_ARBITRAGEM_PAR                   , //HFT_ARBITRAGEM_PAR
     HFT_DESBALANC_BOOK                   , //HFT_DESBALANC_BOOK
     HFT_OPERAR_VELOC_VOL_RDF             , //HFT_OPERAR_VELOC_VOL_RDF
     HFT_OPERAR_VELOC_VOL_NET             , //HFT_OPERAR_VELOC_VOL_NET
};

//---------------------------------------------------------------------------------------------
  input group "Gerais"
//input ENUM_TIPO_OPERACAO         EA_ACAO_POSICAO            = FECHAR_POSICAO          ; //EA_ACAO_POSICAO:Forma de operacao do EA.
  input ENUM_TIPO_OPERACAO         EA_ACAO_POSICAO            = HFT_FORMADOR_DE_MERCADO ; // EA_ACAO_POSICAO:Forma de operacao do EA.
//input ENUM_TIPO_OPERACAO         EA_ACAO_POSICAO            = HFT_OPERAR_CANAL_EM_PAR ; //*EA_ACAO_POSICAO:Forma de operacao do EA.
//input ENUM_TIPO_OPERACAO         EA_ACAO_POSICAO            = HFT_OPERAR_VELOC_VOL_RDF; //*EA_ACAO_POSICAO:Forma de operacao do EA.
//input ENUM_TIPO_OPERACAO         EA_ACAO_POSICAO            = HFT_OPERAR_VELOC_VOL_NET; //*EA_ACAO_POSICAO:Forma de operacao do EA.
//input ENUM_TIPO_OPERACAO         EA_ACAO_POSICAO            = HFT_DESBALANC_BOOK      ; //*EA_ACAO_POSICAO:Forma de operacao do EA.
//input ENUM_TIPO_OPERACAO         EA_ACAO_POSICAO            = NAO_ABRIR_POSICAO       ; //*EA_ACAO_POSICAO:Forma de operacao do EA.
//input ENUM_TIPO_ENTRADA_PERMITDA EA_TIPO_ENTRADA_PERMITIDA_1  = ENTRADA_BUY             ; //*TIPO_ENTRADA_PERMITIDA Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
//input ENUM_TIPO_ENTRADA_PERMITDA EA_TIPO_ENTRADA_PERMITIDA_1  = ENTRADA_TODAS         ; //*TIPO_ENTRADA_PERMITIDA Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
//input ENUM_TIPO_ENTRADA_PERMITDA EA_TIPO_ENTRADA_PERMITIDA_2  = ENTRADA_TODAS         ; //*TIPO_ENTRADA_PERMITIDA Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
  input ENUM_TIPO_ENTRADA_PERMITDA EA_TIPO_ENTRADA_PERMITIDA_1  = ENTRADA_TODAS         ; //*TIPO_ENTRADA_PERMITIDA1 Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
  input ENUM_TIPO_ENTRADA_PERMITDA EA_TIPO_ENTRADA_PERMITIDA_2  = ENTRADA_TODAS         ; //*TIPO_ENTRADA_PERMITIDA2 Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
  input double                     EA_SPREAD_MAXIMO_EM_TICKS  =  20                     ; //*EA_SPREAD_MAXIMO_EM_TICKS. Se for maior que o maximo, nao abre novas posicoes.
  input uint                       EA_ONTICK_A_CADA_X_MILIS   =  0                      ; //*ONTICK_A_CADA_X_MILIS se zero, executa a cada tick
  input int                        SLEEP_TESTE                =  0000                   ; //*ERROOOOOOOOOOOOO SLEEP_TESTE nao pode em producao
  input bool                       TESTE_OFFLINE              =  false                  ; //*ERROOOOOOOOOOOOO TESTE_OFFLINE nao pode em producao
  input bool                       EA_NET_REGISTRA_PERF       =  false                   ; //*NET_REGISTRA_PERF se a grava performance em banco de dados
  input bool                       EA_REGISTRA_BOOK           =  true                   ; //*REGISTRA_BOOK se a grava book em banco de dados
  
//
//input group "Volume por Segundo"
//input int    EA_VOLSEG_MAX_ENTRADA_POSIC = 150;//VOLSEG_MAX_ENTRADA_POSIC: vol/seg maximo para entrar na posicao.
//

  input group "pairs trading"
//input string EA_TICKER_REF               = "WINM21" ; //*TICKER_REF
//input string EA_TICKER_REF               = "WDON21" ; //*TICKER_REF
  input string EA_TICKER_REF               = "WDOQ21" ; //*TICKER_REF
//input string EA_TICKER_REF               = "WDO@" ; //*TICKER_REF
//input int    EA_QTD_SEG_MEDIA_PRECO      = 900      ; // QTD_SEG_MEDIA_PRECO
  #define      EA_QTD_PERIODO_MEDIA_SPREAD   15         //*QTD_PERIODO_MEDIA_SPREAD
  input bool   EA_NEGOCIAR_ATIVO_1         = true     ; // NEGOCIAR_ATIVO_1
  input bool   EA_NEGOCIAR_ATIVO_2         = false    ; // NEGOCIAR_ATIVO_2
  #define      EA_QTD_DP_FIRE_ORDEM          1.5        // QTD_DP_FIRE_ORDEM
  #define      EA_QTD_DP_CLOSE_ORDEM         0.5        // QTD_DP_CLOSE_ORDEM

  #define EA_EST_QTD_SEGUNDOS             60     //EST_QTD_SEGUNDOS 0(qtd seg do timeframe) >0(qtd seg)
  #define EA_EST_POR_EVENTO               false  //EST_POR_EVENTO true: acumula por tick. false: por segundo.
  #define EA_EST_NORMALIZAR_TICK_2_TRADE  false  //EST_NORMALIZAR_TICK_2_TRADE.
  //input group "coleta estatistica"
  //input int    EA_EST_QTD_SEGUNDOS            = 60    ; //EST_QTD_SEGUNDOS 0(qtd seg do timeframe) >0(qtd seg)
  //input bool   EA_EST_POR_EVENTO              = false ; //EST_POR_EVENTO true: acumula por tick. false: por segundo.
  //input bool   EA_EST_NORMALIZAR_TICK_2_TRADE = false ; //EST_NORMALIZAR_TICK_2_TRADE.

  #define EA_DBNAME      "oslib7"//EA_DBNAME nome do banco de dados que guardarah o historico coletados dos books

  //input group "=== book imbalance geral ==="
  //#define    EA_PROCESSAR_BOOK     true   //PROCESSAR_BOOK true: obtem dados do book.
  input bool   EA_PROCESSAR_BOOK   = true; //PROCESSAR_BOOK true: obtem dados do book.

  #define EA_BOOK_DEEP1       9      //BOOK_DEEP1 profundidade book imbalance
  #define EA_BOOK_QUEU_IN1    2       //BOOK_QUEU_IN1 fila pra considerar a ordem executada
  #define EA_BOOK_IMBALANCE1  0.1     //BOOK_IMBALANCE1 limiar para definir direcao do movimento
  //input group "=== book imbalance 1 ==="
  //input int    EA_BOOK_DEEP1       = 3   ; //BOOK_DEEP1 profundidade book imbalance
  //input uint   EA_BOOK_QUEU_IN1    = 2   ; //BOOK_QUEU_IN1 fila pra considerar a ordem executada
  //                                         // 1 significa que se a ordem estiver na fila 1 do book, serah executada com certeza
  //                                         // portanto, um algoritimo de cancelamento deve cancelar na fila 2 ou superior, pois
  //                                         // na fila 1, dificilmente conseguirah cancelar. Estamos testando 1 para win.
  //input double EA_BOOK_IMBALANCE1  = 0.1 ; //BOOK_IMBALANCE1 limiar para definir direcao do movimento

  #define EA_BOOK_DEEP2        8   //BOOK_DEEP2 profundidade book imbalance
  #define EA_BOOK_QUEU_IN2     1   //BOOK_QUEU_IN2 fila pra considerar a ordem executada
  #define EA_BOOK_IMBALANCE2   0.1 //BOOK_IMBALANCE2 limiar para definir direcao do movimento
  //input double EA_BOOK_IMBALANCE2  = 0.1 ; //BOOK_IMBALANCE2 limiar para definir direcao do movimento
  //input group "=== book imbalance 2 ==="
  //input int    EA_BOOK_DEEP2       = 3   ; //BOOK_DEEP2 profundidade book imbalance
  //input uint   EA_BOOK_QUEU_IN2    = 1   ; //BOOK_QUEU_IN2 fila pra considerar a ordem executada
  //                                         // 1 significa que se a ordem estiver na fila 1 do book, serah executada com certeza
  //                                         // portanto, um algoritimo de cancelamento deve cancelar na fila 2 ou superior, pois
  //                                         // na fila 1, dificilmente conseguirah cancelar. Estamos testando 0 para wdo.
  //input double EA_BOOK_IMBALANCE2  = 0.1 ; //BOOK_IMBALANCE2 limiar para definir direcao do movimento

  input group "=== canal operacional ==="
  #define      EA_CANAL_DIARIO                   false //CANAL_DIARIO operacional
  input int    EA_TAMANHO_CANAL                  = 03; //TAMANHO_CANAL operacional em periodos
  input double EA_PORC_REGIAO_OPERACIONAL_CANAL  = 0.20;//PORC_REGIAO_OPERACIONAL_CANAL regiao de operacao

  //input group "Entrada CUSUM"
  #define          EA_CALCULAR_CUSUM false //CALCULAR_CUSUM
  #define          EA_KK               5   //K passo do preco para uma acumulacao direcional;
  #define          EA_HH               50  //H soma de acumulacoes (K) na mesma direcao para caracterizar a tendencia.
  #define          EA_QTD_TICKS_CUSUM  0   //QTD_TICKS_CUSUM a cada XX ticks, avalia a soma cumulativa.

//input group "Entrada volatilidade e inclinacoes"
//input double EA_VOLAT_ALTA                = 1.5 ;//VOLAT_ALTA:Volatilidade a considerar alta(%). Calculada a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
//input double EA_VOLAT4S_ALTA_PORC         = 1.0 ;//VOLAT4S_ALTA_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media abrir posicao.
//input double EA_VOLAT4S_STOP_PORC         = 1.5 ;//VOLAT4S_STOP_PORC:Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media para stopar.
//input double EA_VOLAT4S_MIN               = 1.5 ;//VOLAT4S_MIN:Acima deste valor, nao abre posicao.
//input double EA_VOLAT4S_MAX               = 2.0 ;//VOLAT4S_MAX:Acima deste valor, fecha a posicao.
//input double EA_INCL_ALTA                 = 0.9 ;//INCL_ALTA:Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
  #define      EA_ESTIMAR_POR_REGRESSAO_LINEAR false // ESTIMAR_POR_REGRESSAO_LINEAR
  #define      EA_INCL_MIN                    0.015  //INCL_MIN:Inclinacao minima para entrar no trade.
  #define      EA_R2_MIN_ENTRADA_POS          0.2    //R2_MIN_ENTRADA_POS:r2 min para confiar na entrada.
//input double EA_DELTA_PRECO_MIN_ENTRADA_POS = 1 ;//DELTA_PRECO_MIN_ENTRADA:delta preco entrada pos.
//input double EA_DELTA_PRECO_MIN_SAIDA_POS   = 3 ;//DELTA_PRECO_MIN_SAIDA:delta preco saida pos.
//input int    EA_MIN_DELTA_VOL             = 10  ;//MIN_DELTA_VOL:%delta vol minimo para entrar na posicao
//input int    EA_MIN_DELTA_VOL_ACELERACAO  = 1   ;//MIN_DELTA_VOL_ACELERACAO:Aceleracao minima da %delta vol para entrar na posicao
  input bool   EA_CALC_REGRESSAO_RDF        = false;// CALC_REGRESSAO_DRF se true, calcula regressao RDF
  input bool   EA_CALC_REGRESSAO_NET        = true ;// CALC_REGRESSAO_NET se true, calcula regressao NET
  input int    EA_MAT_RDF_TAMANHO           = 20  ;// MAT_RDF_TAMANHO      tamanho da matriz RDF
  #define      EA_MAT_RDF_TAMANHO_NOVA        50   // MAT_RDF_TAMANHO_NOVA tamanho da matriz RDF nova

  input group "=== RAJADA e Formador de Mercado ==="
  input int    EA_TAMANHO_RAJADA                          = 3    ;//TAMANHO_RAJADA;
  #define      EA_DIST_MIN_IN_BOOK_IN_POS                   1     //DIST_MIN_IN_BOOK_IN_POS abrindo posicao
  #define      EA_DIST_MIN_IN_BOOK_IN_POS_OBRIG             1     //int DIST_MIN_IN_BOOK_IN_POS_OBRIG
  #define      EA_DIST_MIN_IN_BOOK_OUT_POS                  1     //DIST_MIN_IN_BOOK_OUT_POS fechando posicao
  input bool   EA_LAG_DINAMICO                            = true ;//LAG_DINAMICO
//input double EA_COEF_RISCO_LAG_DINAMICO                 = 0.272;//COEF_RISCO_LAG usado no calculo do lag dinamico. quanto maior, maior o lag.
  input double EA_COEF_RISCO_LAG_DINAMICO                 = 0.5  ;//COEF_RISCO_LAG usado no calculo do lag dinamico. quanto maior, maior o lag.
  input int    EA_LAG_RAJADA1                             = 4    ;//LAG_RAJADA1
  input int    EA_LAG_RAJADA2                             = 3    ;//LAG_RAJADA2
  #define      EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES          20    //int STOP_PARCIAL_A_PARTIR_DE_X_LOTES
  #define      EA_STOP_PARCIAL_A_PARTIR_DE_X_GANHO          10    //int STOP_PARCIAL_A_PARTIR_DE_X_GANHO
  input bool   EA_DECISAO_ENTRADA_COMPRA_VENDA_AUTOMATICA = false;//DECISAO_ENTRADA_COMPRA_VENDA_AUTOMATICA
  #define      EA_FECHA_POSICAO_NO_BREAK_EVEN               false //FECHA_POSICAO_NO_BREAK_EVEN
  #define      EA_AUMENTO_LAG_QTD_FASE1                     3     //EA_AUMENTO_LAG_QTD_FASE1
  #define      EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_1      0.0   //*AUMENTO_LAG_POR_LOTE_PENDENTE_1
  #define      EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_2      0.5   //*AUMENTO_LAG_POR_LOTE_PENDENTE_2
  #define      EA_AUMENTO_LAG_POR_LOTE_PENDENTE             0.00  //AUMENTO_LAG_POR_LOTE_PENDENTE_nao_se_usa
  #define      EA_OFFSET_DINAMICO                           false //OFFSET_DINAMICO
  #define      EA_DIVISOR_OFFSET                            0.5   //DIVISOR_OFFSET 0.5 (divide offset por 2)

  input group "entrada na posicao"
  #define      EA_TOLERANCIA_ENTRADA         0      //*TOLERANCIA_ENTRADA: algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao
  input int    EA_VOL_LOTE_INI_1           = 1    ; //*VOL_LOTE_INI:Vol do lote na abertura de posicao qd vol/seg eh L1.
  input int    EA_VOL_LOTE_INI_2           = 1    ; //*VOL_LOTE_INI:Vol do lote na abertura de posicao qd vol/seg eh L1.
  input double EA_QTD_TICKS_4_GAIN_INI_1   = 2    ; //*TICKS_4_GAIN_INI_1 Qtd ticks para o gain qd vol/seg eh level 1;
  input double EA_QTD_TICKS_4_GAIN_INI_2   = 3    ; //*TICKS_4_GAIN_INI_2 Qtd ticks para o gain qd vol/seg eh level 1;
  #define      EA_QTD_TICKS_4_GAIN_DECR      0      // TICKS_4_GAIN_DECR Qtd ticks a ser decrementado em tfg a cada aumento de volume de posicao;
  #define      EA_QTD_TICKS_4_GAIN_MIN_1     1      //*QTD_TICKS_4_GAIN_MIN_1 menor alvo inicial possivel;
  #define      EA_QTD_TICKS_4_GAIN_MIN_2     1      //*QTD_TICKS_4_GAIN_MIN_2 menor alvo inicial possivel;
  #define      EA_PORC_CANAL_T4G_1           0.15   //*PORC_CANAL_T4G_1 t4g1 como porc do canal operacional
  #define      EA_PORC_CANAL_T4G_2           0.15   //*PORC_CANAL_T4G_2 t4g2 como porc do canal operacional
  #define      EA_ALVO_DINAMICO              false  // ALVO_DINAMICO alvo igual dp/TAMANHO_RAJADA

  input group "saida posicao"
  input int    EA_REDUZ_T4G_A_CADA_X_SEG = 0    ; //*REDUZ_T4G_A_CADA_X_SEG: ex se 5, reduz 1 t4g a cada 5 segundos na posicao.


  //input group "Rajada"
  #define      EA_RAJADA_UNICA                      true   //RAJADA_UNICA se verdadeiro, cria uma raja unica na abertura da posicao.
//input int    EA_TAMANHO_RAJADA                  = 5     ;//TAMANHO_RAJADA;
  #define      EA_VOL_PRIM_ORDEM_RAJ                1      //double VOL_PRIM_ORDEM_RAJ:Vol da primeira ordem da rajada.
  #define      EA_INCREM_VOL_RAJ                    1      //double INCREM_VOL_RAJ aumento(x) de volume a cada ordem da rajada;
  #define      EA_DISTAN_PRIM_ORDEM_RAJ             1      //double DISTAN_PRIM_ORDEM_RAJ Distancia em ticks desde abertura da posicao ateh prim ordem rajada;
  #define      EA_DISTAN_DEMAIS_ORDENS_RAJ          1      //double DISTAN_DEMAIS_ORDENS_RAJ Distancia entre as demais ordens da rajada;
  #define      EA_INCREM_DISTAN_DEMAIS_ORDENS_RAJ   1      //double INCREM_DISTAN_DEMAIS_ORDENS_RAJ aumento (x) distancia ordens rajada;
  #define      EA_STOP_NA_RAJADA                    false  //STOP_NA_RAJADA
  #define      EA_PORC_STOP_NA_RAJADA               0      //double PORC_STOP_NA_RAJADA
  #define      EA_FECHA_POSICAO_POR_EVENTO          true   //FECHA_POSICAO_POR_EVENTO
  #define      EA_LOGAR_TRADETRANSACTION            false  //LOGAR_TRADETRANSACTION

//
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
  //input group "STOP PARCIAL"
  #define EA_STOP_PARCIAL_ATIVAR                   false //*STOP_PARCIAL_ATIVAR
  #define EA_STOP_PARCIAL_FIRE_VOLUME_TOT          6     //*STOP_PARCIAL_FIRE_VOLUME_TOT
  #define EA_STOP_PARCIAL_FIRE_PORC_LUCRO_POSICAO  0.8   //*STOP_PARCIAL_FIRE_PORC_LUCRO_POSICAO

  input group "STOP LOSS"
//input int    EA_STOP_TIPO_CONTROLE_RISCO = 1   ; // STOP_TIPO_CONTROLE_RISCO, se 1, controle normal. Se 2, controle por proximidade do breakeven.
  input int    EA_STOP_TICKS_STOP_LOSS   =  0    ; // STOP_TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
  input int    EA_STOP_TICKS_TKPROF      =  0    ; // STOP_TICKS_TKPROF:Quantidade de ticks usados no take profit;
  input double EA_STOP_REBAIXAMENTO_MAX  =  0    ; // STOP_REBAIXAMENTO_MAX:preencha com positivo.
  input double EA_STOP_OBJETIVO_DIA      =  0    ; // STOP_OBJETIVO_DIA:para se saldo alcancar objetivo do dia.
  input double EA_STOP_LOSS              = -100  ; //*STOP_LOSS:Valor maximo de perda aceitavel;
  input int    EA_STOP_TICKS_TOLER_SAIDA =  1    ; // STOP_TICKS_TOLER_SAIDA: qtd de ticks a aguardar nas saidas stop;
  #define      EA_STOP_CUSUM                false  // STOP_CUSUM: true, cusum dispara stop.
  input int    EA_MAX_TMP_FECHAM_POSICAO =  2    ; // MAX_TMP_FECHAM_POSICAO depois desse tempo, forca o fechamento da posicao

  #define      EA_STOP_CHUNK                10     //STOP_CHUNK:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
  #define      EA_STOP_PORC_L1              1      //STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
  #define      EA_STOP_10MINUTOS            0      //STOP_10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
  #define      EA_STOP_QTD_CONTRATOS_PENDENTES 0   //STOP_QTD_CONTRATOS_PENDENTES fecha posic se qtd contrat maior que este
//
  input group "show_tela"
  input bool   EA_SHOW_CONTROL_PANEL               = false ;//*SHOW_CONTROL_PANEL mostra painel de controle;
  input bool   EA_SHOW_TELA                        = true ;//*SHOW_TELA:mostra valor de variaveis na tela;
  input bool   EA_SHOW_CANAL_PRECOS                = true  ;//*SHOW_CANAL_PRECOS:mostra linhas do canal de precos;
  #define      EA_SHOW_TELA_LINHAS_ACIMA             0      // SHOW_TELA_LINHAS_ACIMA:permite impressao na parte inferior da tela;
//input bool   EA_SHOW_STR_PERMISSAO_ABRIR_POSICAO = false; // SHOW_STR_PERMISSAO_ABRIR_POSICAO:condicoes p/abrir posicao;

//
////
//input group "diversos"
//input bool   EA_DEBUG           =  false         ; //DEBUG:se true, grava informacoes de debug no log do EA.
input ulong  EA_MAGIC             =  21060700400305; //MAGIC: Numero magico desse EA. yy-mm-vv-vvv-vvv-vv.
////
//input group "estrategia HFT_FLUXO_ORDENS"
//input double EA_PROB_UPDW                =  0.8 ;//PROB_UPDW:probabilidade do preco subir ou descer em funcao do fluxo de ordens;
////
#define      EA_DOLAR_TARIFA                  6.0  //double DOLAR_TARIFA:usado para calcular a tarifa do dolar.
////

//#define EA_MAX_VOL_EM_RISCO     200        //EA_MAX_VOL_EM_RISCO:Qtd max de contratos em risco; Sao os contratos pendentes da posicao.
//#define EA04_DX_TRAILLING_STOP  1.0        //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
//#define EA10_DX1                0.2        //EA10_DX1:Tamanho do DX em relacao a banda em %;
//---------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
input group "horario de operacao"
input int    EA_HR_INI_OPERACAO   = 09; // *Hora   de inicio da operacao;
input int    EA_MI_INI_OPERACAO   = 05; // *Minuto de inicio da operacao;
input int    EA_HR_FIM_OPERACAO   = 17; // *Hora   de fim    da operacao;
input int    EA_MI_FIM_OPERACAO   = 55; // *Minuto de fim    da operacao;
input int    EA_HR_FECHAR_POSICAO = 17; // *HR_FECHAR_POSICAO fecha todas as posicoes;
input int    EA_MI_FECHAR_POSICAO = 57; // *MI_FECHAR_POSICAO fecha todas as posicoes;
//---------------------------------------------------------------------------------------------
//
// group "sleep e timer"
input int    EA_SLEEP_INI_OPER     =  05  ;//*SLEEP_INI_OPER:Aguarda estes segundos para iniciar abertura de posicoes.
input int    EA_QTD_MILISEG_TIMER  =  500 ;//*QTD_MILISEG_TIMER:Tempo de acionamento do timer.

//input int    EA_SLEEP_ATRASO   =  0  ;//SLEEP_TESTE_ONLINE:atraso em milisegundos antes de enviar ordens.

//---------------------------------------------------------------------------------------------

//osc_estatistic2 m_est;
ENUM_TIPO_OPERACAO         m_acao_posicao     = NAO_OPERAR;
ENUM_TIPO_OPERACAO         m_acao_posicao_ant = NAO_OPERAR;
MqlDateTime                m_date;
string                     m_name = "OSE-P7-004-003-06-ns"; // operacao manual assistida por robo
osc_db                     m_db                      ;
CSymbolInfo                m_symb1   , m_symb2       ;
CPositionInfo              m_posicao1, m_posicao2    ;
CAccountInfo               m_cta                     ;
C004GerentePosicao         m_gerentePos1             ;
C004GerentePosicao         m_gerentePos2             ;
C0601StrategyDeepImbalance m_C0601_1                 ;// estrategia de desbalanceamento do book para o ativo 1;
C0601StrategyDeepImbalance m_C0601_2                 ;// estrategia de desbalanceamento do book para o ativo 2;

double        m_tick_size1                    ;// alteracao minima do preco em pontos para o simbolo 1.
double        m_tick_size2                    ;// alteracao minima do preco em pontos para o simbolo 2.
double        m_tick_value1                   ;// valor do tick na moeda do ativo 1.
double        m_tick_value2                   ;// valor do tick na moeda do ativo 2.
double        m_lots_min                      ;// tamaho do menor lote aceitavel pelo simbolo.
double        m_lots_step1                    ;// alteracao minima de volume para o ativo 1.
double        m_lots_step2                    ;// alteracao minima de volume para o ativo 2.
double        m_spread                        ;// spread.
double        m_point1                        ;// um ponto do ativo 1.
double        m_point2                        ;// um ponto do ativo 2.
double        m_point_value1                  ;// valor de um ponto na moeda do ativo 1.
double        m_point_value2                  ;// valor de um ponto na moeda do ativo 2.
double        m_stopLossOrdens                ;// stop loss;
double        m_tkprof                        ;// take profit;
double        m_distMediasBook                ;// Distancia entre as medias Ask e Bid do book.

osc_minion_trade             m_trade1           ; // operacao com ordens
osc_minion_trade             m_trade2           ; // operacao com ordens
osc_minion_trade_estatistica m_trade_estatistica; // estatistica de trades
osc_estatistic3*             m_est              ; // estatistica de ticks
osc_control_panel_p7_002_004 m_cp               ; // painel de controle
osc_position                 m_pos              ; // processamento do OnTradeTransaction
osc_tick_util                m_tick_util1       ; // para simular ticks de trade em bolsas que nao informam last/volume.
osc_tick_util                m_tick_util2       ; // para simular ticks de trade em bolsas que nao informam last/volume.
osc_book                     m_book1            ;
osc_book                     m_book2            ;
C00021Pairs*                 m_par              ;
C0007ModelRDF                m_rdf              ;
C00100NetPerceptronBook      m_net1             ;

double                       m_predict_NET1 = 0;

bool   m_comprado              =  false;
bool   m_vendido               =  false;

double m_breakeven            = 0; // breakeven sem normalizar
double m_precoPosicao         = 0; // valor medio de entrada da posicao (breakeven normalizado)
double m_precoPosicaoAnt      = 0;
double m_precoSaidaPosicao    = 0;
double m_precoSaidaPosicaoAnt = 0;

double m_posicaoVolumePend     =  0; // volume pendente pra fechar a posicao atual
double m_posicaoLotsPend       =  0; // lotes pendentes pra fechar a posicao atual
double m_posicaoVolumeTot      =  0; // volume total de contratos da posicao, inclusive os que jah foram fechados
long   m_positionId            = -1;
double m_volComprasNaPosicao   =  0; // quantidade de compras na posicao atual;
double m_volVendasNaPosicao    =  0; // quantidade de vendas  na posicao atual;
double m_capitalInicial        =  0; // capital justamente antes de iniciar uma posicao
double m_capitalLiquido        =  0; // capital atual durante a posicao.
double m_lucroPosicao          =  0; // lucro da posicao atual
double m_lucroPosicaoParcial   =  0; // lucro na posicao atual (apenas sobre os lotes remanescentes)
double m_lucroPosicaoRealizado =  0; // lucro realizado na posicao
double m_lucroPosicao4Gain     =  0; // lucro para o gain caso a quantidade de contratos tenha ultrapassado o valor limite.
double m_lucroStops            =  0; // lucro acumulado durante stops de quantidade

double m_tstop                 =  0 ;

//--- variaveis atualizadas pela funcao refreshMe...
int    m_qtdOrdens     = 0;
int    m_qtdPosicoest  = 0; // quantidade total de posicoes
int    m_qtdPosicoes1  = 0;
int    m_qtdPosicoes2  = 0;
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

string   m_apmb_man   = "INM"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb       = "IN" ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_sel   = "INS"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_buy   = "INB"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_strRajada  = "RJ" ; //string que identifica rajadas de abertura de novas posicoes.
string   m_comment_fixo;
string   m_comment_var;

double m_maior_sld_do_dia = 0;
double m_sld_sessao_atu   = 0;
double m_rebaixamento_atu = 0;
bool   m_mudou_dia        = false;
bool   m_acionou_stop_rebaixamento_saldo = false;
int    m_spread_maximo_in_points = 0;
double m_stop_level_in_price = 0;

long   m_tempo_posicao_atu   = 0;
long   m_tempo_posicao_ini   = 0;

int    m_stop_qtd_contrat    = 0; // EA_STOP_QTD_CONTRAT; Eh o tamanho do chunk;
int    m_stop_chunk          = 0; // EA_STOP_CHUNK; Eh o tamanho do chunk;
double m_stop_porc           = 0; // EA_STOP_PORC_L1    ; Eh a porcentagem inicial para o ganho durante o passeio;
double m_qtd_ticks_4_gain_new  = 0;
double m_qtd_ticks_4_gain_ini_1  = 0;
double m_qtd_ticks_4_gain_ini_2  = 0;
double m_qtd_ticks_4_gain_decr = 0;
double m_qtd_ticks_4_gain_raj= 0;
int    m_passo_rajada        = 0;
double m_vol_lote_ini1       = 0;
double m_vol_lote_ini2       = 0;
double m_vol_lote_raj        = 0;

// operacao com rajada unica.
double m_raj_unica_distancia_demais_ordens = 0;
double m_raj_unica_distancia_prim_ordem    = 0;

// controles de apresentacao das variaveis de debug na tela...
string m_str_linhas_acima   = "";
string m_release = "[RELEASE TESTE]";

// variaveis usadas nas estrategias de entrada, visando diminuir a quantidade de alteracoes e cancelamentos com posterior criacao de ordens de entrada.
//double m_precoUltOrdemInBuy = 0;
//double m_precoUltOrdemInSel = 0;

// string com o simbolo sendo operado
string m_symb_str1;
string m_symb_str2;

// milisegundos que devem ser aguardados antes de iniciar a operacao
int m_aguardar_para_abrir_posicao = 0;

// algumas estrategias permitem uma tolerancia do preco para entrada na posicao...
double m_shift_in_points = 0;

datetime m_time_in_seconds_ini_day = TimeCurrent();

ENUM_TIPO_ENTRADA_PERMITDA m_tipo_entrada_permitida1 = EA_TIPO_ENTRADA_PERMITIDA_1;
ENUM_TIPO_ENTRADA_PERMITDA m_tipo_entrada_permitida2 = EA_TIPO_ENTRADA_PERMITIDA_2;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//testando a classe osc_canal...
osc_canal m_canal1;
osc_canal m_canal2;
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
    m_acao_posicao = EA_ACAO_POSICAO;

    configurar_db();
    inicializarSimbolos(); // Primeiro a executar pois ha varios a frente que dependem do simbolo configurado
    inicializarBookEvent();
    inicializarVariaveisRecebidasPorParametro(); // depende de inicializarSimbolos()
    inicializarPassoRajadaFixoHFT_FORMADOR_DE_MERCADO();

    m_stopLossOrdens    = m_symb1.NormalizePrice(EA_STOP_TICKS_STOP_LOSS *m_tick_size1);
    m_tkprof            = m_symb1.NormalizePrice(EA_STOP_TICKS_TKPROF    *m_tick_size1);

    m_trade1.setSymbol  ( _Symbol );
    m_trade1.setMagic   ( EA_MAGIC);
    m_trade1.setStopLoss( m_stopLossOrdens);
    m_trade1.setTakeProf( m_tkprof);
    m_trade1.setVolLote ( m_symb1.LotsMin() );

    m_posicao1.Select( m_symb_str1 ); // selecao da posicao por simbolo.
    m_gerentePos1.inicializar(m_symb_str1,EA_MAGIC,EA_LAG_RAJADA1,EA_TAMANHO_RAJADA,EA_REDUZ_T4G_A_CADA_X_SEG);
  //m_gerentePos1.setSpread(m_lag_rajada1*m_tick_size1);
    m_gerentePos1.setSpread(             m_tick_size1);
  //m_gerentePos1.setT4gMin((int)EA_QTD_TICKS_4_GAIN_MIN_1 );
    m_gerentePos1.setT4gMin((int)EA_QTD_TICKS_4_GAIN_INI_1 );

    m_canal1.inicializar(m_symb1, EA_TAMANHO_CANAL, EA_PORC_REGIAO_OPERACIONAL_CANAL);
    m_canal1.setShowCanalPrecos(EA_SHOW_CANAL_PRECOS);
    m_canal1.setRegiaoBuySellUsaCanalDia(EA_CANAL_DIARIO);

    m_canal2.inicializar(m_symb2, EA_TAMANHO_CANAL, EA_PORC_REGIAO_OPERACIONAL_CANAL);
    m_canal2.setShowCanalPrecos(false);
    m_canal2.setRegiaoBuySellUsaCanalDia(EA_CANAL_DIARIO);

    // estatistica de trade...
    m_time_in_seconds_ini_day = StringToTime( TimeToString( TimeCurrent(), TIME_DATE ) );
    m_trade_estatistica.initialize();
    m_trade_estatistica.setCotacaoMoedaTarifaWDO(EA_DOLAR_TARIFA);

    m_spread_maximo_in_points = (int)( (EA_SPREAD_MAXIMO_EM_TICKS*m_tick_size1)/m_point1 );
  //m_stop_level_in_price     = normalizar1( m_symb1.StopsLevel()*m_point1 + m_tick_size1 );
    m_stop_level_in_price     = normalizar1( m_symb1.StopsLevel()*m_point1               );
  //m_stop_level_in_price     = normalizar1( m_symb2.StopsLevel()*m_symb1.Point()    );

    m_shift_in_points         = normalizar1( (EA_TOLERANCIA_ENTRADA*m_tick_size1)/m_point1 ); // tolerancia permitida para entrada em algumas estrategias

    m_maior_sld_do_dia = (m_maior_sld_do_dia==0)?m_cta.Balance():m_maior_sld_do_dia; // saldo da conta no inicio da sessao;
    m_sld_sessao_atu   = (m_sld_sessao_atu  ==0)?m_cta.Balance():m_sld_sessao_atu  ;
    m_capitalInicial   = (m_capitalInicial  ==0)?m_cta.Balance():m_capitalInicial  ;

    //BBCriar();

    m_comment_fixo = "LOGIN:"         + DoubleToString(m_cta.Login(),0) +
                     "  TRADEMODE:"   + m_cta.TradeModeDescription()    +
                     "  MARGINMODE:"  + m_cta.MarginModeDescription()   +
                     " "              + m_release;
                   //"alavancagem:" + m_cta.Leverage()               + "\n" +
                   //"stopoutmode:" + m_cta.StopoutModeDescription() + "\n" +
                   //"max_ord_pend:"+ m_cta.LimitOrders()            + "\n" + // max ordens pendentes permitidas

    Comment(m_comment_fixo);


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
    m_cusum.setAcumularAcadaXTicks(EA_QTD_TICKS_CUSUM);

    if( EA_LOGAR_TRADETRANSACTION ) m_pos.initLogCSV();//<TODO> RETIRE APOS TESTES
    m_pos.initialize();

    m_par = new C00021Pairs;
    m_par.initialize( EA_QTD_PERIODO_MEDIA_SPREAD*PeriodSeconds() );


//  if( m_acao_posicao == HFT_ARBITRAGEM_PAR ){
//      m_par = new C0002ArbitragemPar;
//      m_par.initialize(EA_QTD_SEG_MEDIA_PRECO,EA_QTD_SEG_MEDIA_RATIO);
//
//      m_est = m_par.getEstAtivo1(); // usando o ponteiro que jah eh atualizado pelo objeto de arbitragem.
//                                    // assim evitamos atualizar outro objeto estatistico.
//
        m_symb_str2 = EA_TICKER_REF;
        m_symb2.Name( m_symb_str2   ); // inicializacao da classe CSymbolInfo do simbolo de referencia
        m_symb2.Refresh            (); // propriedades do simbolo de referencia. Basta executar uma vez.
        m_symb2.RefreshRates       (); // valores do tick. execute uma vez por tick.

        m_trade2.setSymbol  ( m_symb_str2 );
        m_trade2.setMagic   ( EA_MAGIC+1);
        m_trade2.setStopLoss( m_stopLossOrdens);
        m_trade2.setTakeProf( m_tkprof);
        m_trade2.setVolLote ( m_symb2.LotsMin() );

        m_posicao2.Select( m_symb_str2 ); // selecao da posicao por simbolo.
        m_gerentePos2.inicializar(m_symb_str2,EA_MAGIC+1,EA_LAG_RAJADA2,EA_TAMANHO_RAJADA,EA_REDUZ_T4G_A_CADA_X_SEG);
      //m_gerentePos2.setSpread  (m_lag_rajada1*m_tick_size2);
        m_gerentePos2.setSpread  (             m_tick_size2);
      //m_gerentePos2.setT4gMin  ((int)EA_QTD_TICKS_4_GAIN_MIN_2 );
        m_gerentePos2.setT4gMin  ((int)EA_QTD_TICKS_4_GAIN_INI_2 );


        m_C0601_1.inicializar( GetPointer(m_book1),GetPointer(m_gerentePos1),EA_TAMANHO_RAJADA,EA_LAG_RAJADA1,EA_BOOK_QUEU_IN1 );
        m_C0601_2.inicializar( GetPointer(m_book2),GetPointer(m_gerentePos2),EA_TAMANHO_RAJADA,EA_LAG_RAJADA2,EA_BOOK_QUEU_IN2 );

//
//      // aguardando a media de ratio ser totalmente calculada antes de abrir a primeira posicao
//      m_aguardar_para_abrir_posicao = EA_QTD_SEG_MEDIA_RATIO*1000;
//  }else{
        m_est = new osc_estatistic3;

        int qtdSegCalcMedia = 0;
        if(EA_EST_QTD_SEGUNDOS==0) qtdSegCalcMedia = PeriodSeconds()    ;
        if(EA_EST_QTD_SEGUNDOS >0) qtdSegCalcMedia = EA_EST_QTD_SEGUNDOS;
        m_est.initialize(qtdSegCalcMedia,false,EA_EST_POR_EVENTO); // quantidade de segundos que serao usados no calculo da velocidade do volume e flag indicando que deve consertar ticks sem flag.

        m_est.setSymbolStr( m_symb_str1 );
        m_tick_util1.setTickSize(m_symb1.TickSize(), m_symb1.Digits() );
        m_tick_util2.setTickSize(m_symb2.TickSize(), m_symb2.Digits() );


//      MqlTick ticks[];
//    //datetime to   =  TimeCurrent();
//    //datetime from = (TimeCurrent()-600)*1000 ; // minutos atras
//      int qtdTicks = CopyTicks(m_symb_str1, ticks, COPY_TICKS_ALL, 0, EA_EST_QTD_SEGUNDOS);
//      if(qtdTicks>0) Print(__FUNCTION__,":-| Procesando ", qtdTicks, " historicos... Mais antigo eh:", ticks[0].time );
//      for(int i=0; i<qtdTicks; i++){
//          normalizar2trade(ticks[i]);
//          m_est.addTick(ticks[i]);
//      }
//      if(qtdTicks>0) Print(__FUNCTION__,":-| ",qtdTicks, " historicos processados... Mais novo eh:", ticks[qtdTicks-1].time );

        MqlTick ticks1[];
        MqlTick ticks2[];
        int qtdTicks1 = 0;
        int qtdTicks2 = 0;
      //datetime from = m_time_in_seconds_ini_day ; // inicio do dia
        datetime to   = TimeCurrent()             ; // agora
        datetime from = to - m_par.getQtdSegMedia();

      //int qtdTicks = CopyTicks(m_symb_str1, ticks    , COPY_TICKS_ALL, 0, EA_EST_QTD_SEGUNDOS);
        qtdTicks1 = CopyTicksRange( m_symb_str1    , //const string     symbol_name,          // nome do símbolo
                                    ticks1        , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                    COPY_TICKS_ALL, //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                    from*1000     , //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                    to*1000         //ulong            to_msc=0              // data ate a qual são solicitados os ticks
                                  );
        Print( __FUNCTION__,": Ticks copiados do ativo ",m_symb_str1,":",qtdTicks1);
        if( qtdTicks1>0 ){
            qtdTicks2 = CopyTicksRange( EA_TICKER_REF , //const string     symbol_name,          // nome do símbolo
                                        ticks2        , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                        COPY_TICKS_ALL, //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                        from*1000     , //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                        to*1000         //ulong            to_msc=0              // data ate a qual são solicitados os ticks
                                      );
            Print( __FUNCTION__,": Ticks copiados do ativo ",EA_TICKER_REF,":",qtdTicks2);

            if(qtdTicks2>0){

                datetime dt1 = m_time_in_seconds_ini_day;
                datetime dt2 = m_time_in_seconds_ini_day;
                m_tick_util1.normalizar2trade(ticks1[0]);
                m_tick_util1.normalizar2trade(ticks2[0]);
                m_par.calcSpread(ticks1[0],ticks2[0]);

                for(int i=1,j=1; i<qtdTicks1; i++){

                    if( ticks1[i].time > dt1 ){
                        //ticks2 deve ficar posicionado na data do ticks1 ou um anterior
                        while( j<qtdTicks2 && ticks2[j].time <= ticks1[i].time ){j++;}
                        if( --j >= 0 ){
                            normalizar2trade1(ticks1[i]);
                            normalizar2trade2(ticks2[j]);
                            m_par.calcSpread(ticks1[i],ticks2[j]);
                            m_est.addTick(ticks1[i]);
                        }else{j++;}
                    }
                }
            }
            if(qtdTicks1>0) Print(__FUNCTION__,":-| ",qtdTicks1, " historicos ",m_symb_str1  ," processados... Mais novo eh:", ticks1[qtdTicks1-1].time );
            if(qtdTicks2>0) Print(__FUNCTION__,":-| ",qtdTicks2, " historicos ",EA_TICKER_REF," processados... Mais novo eh:", ticks2[qtdTicks2-1].time );

            Print(__FUNCTION__,":-| Spread par1/par2=",m_par.getSpread() );
            Print(__FUNCTION__,":-| Slope  par1/par2=",m_par.regLinFit() );

        }
//  }
    Print(__FUNCTION__, " Criando rede m_net1...");
    m_net1.configurarRede(9, 6, 3, 1, 25, m_est, EA_NET_REGISTRA_PERF, m_symb_str1+"N");
  //m_net1.configurarRede(12, 3,    1, 250, m_est, EA_NET_REGISTRA_PERF, m_symb_str1);
  //m_net1.configurarTreinamento(050); // mil casos no conjunto de treinamento
  //m_net1.setEstatistica(m_est);
    calcLenBarraMedia();

    return(INIT_SUCCEEDED);
}

void configurar_db(){ m_db.create_or_open_mydb(EA_DBNAME); }

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

MqlTick   m_tick1; // tick do ativo do grafico (se for pairs trading eh o ativo 1)
MqlTick   m_tick2; // tick do ativo 2 quando pairs trading estah ativado

osc_cusum m_cusum;
bool m_strikeHmais  =false;
bool m_strikeHmenos =false;
bool m_strikeCMais  =false;
bool m_strikeCMenos =false;

double m_precoEstim  = 0;
//double m_precoEstim2 = 0;
//double m_b0         = 0;
//double m_b1         = 0;
double m_r2         = 0;
//double m_r22        = 0;
int    m_qtd_ticks_desde_ult_comp_reg_lin = 0;
void refreshMe(){

    //m_qtd_exec_refreshme++;

    //m_symb1.RefreshRates(); // testando nao fazer refreshRates e usar m_tick1 para os dados de tick...

    // adicionando o tick ao componente estatistico...
    SymbolInfoTick(m_symb_str1,m_tick1);
    m_ask     = m_tick1.ask;
    m_bid     = m_tick1.bid;
    m_spread  = m_tick1.ask-m_tick1.bid;
    normalizar2trade1();
    m_est.addTick(m_tick1);

    if( EA_NEGOCIAR_ATIVO_2 || m_acao_posicao == HFT_ARBITRAGEM_PAR ){
        SymbolInfoTick(EA_TICKER_REF,m_tick2);
        normalizar2trade2();
    }
  
    if( m_acao_posicao == HFT_ARBITRAGEM_PAR ){
        m_par.calcSpread(m_tick1,m_tick2) ;
    }
  

    //m_est.estimarProxAgressao(m_precoEstim,m_b0,m_b1,m_r2);
    //m_precoEstim = (m_precoEstim-m_tick1.last)/m_tick_size1;

    if( EA_ESTIMAR_POR_REGRESSAO_LINEAR ){
        // recompilando a regressao linear a cada XX ticks...
        if( ++m_qtd_ticks_desde_ult_comp_reg_lin > 500 ){
            m_est.regLinCompile(m_r2);
            m_qtd_ticks_desde_ult_comp_reg_lin = 0;
        }
        m_precoEstim = m_est.regLinPredict();
        m_precoEstim = (m_precoEstim-m_tick1.last)/m_tick_size1;
    }

    if( EA_CALCULAR_CUSUM ){
        m_cusum.calcC(  m_tick1.last         ,
                        m_est.getPrecoMedTrade(),
                        EA_KK         , //double K,
                        EA_HH         , //double H,
                        m_strikeHmais ,
                        m_strikeHmenos,
                        m_strikeCMais ,
                        m_strikeCMenos);
    }

    m_volTradePorSegLiq=m_est.getVolTradeLiqPorSeg();
    m_volTradePorSegBuy=m_est.getVolTradeBuyPorSeg();
    m_volTradePorSegSel=m_est.getVolTradeSelPorSeg();
    m_lenTradePorSeg   = (m_est.getTradeHigh() - m_est.getTradeLow() )/m_tick_size1; // tamanho do canal de ticks formado durante a acumulacao da estatistica.

    m_trade1.setStopLoss( m_stopLossOrdens );
    m_trade1.setTakeProf( m_tkprof         );
    m_trade1.setVolLote ( m_lots_min       );

    //m_ask_stplev = m_bid + m_stop_level_in_price; if( m_ask_stplev < m_ask ) m_ask_stplev = m_ask;
    //m_bid_stplev = m_ask - m_stop_level_in_price; if( m_bid_stplev > m_bid ) m_bid_stplev = m_bid;
    m_ask_stplev = m_ask + m_stop_level_in_price;
    m_bid_stplev = m_bid - m_stop_level_in_price;

    if( EA_NEGOCIAR_ATIVO_1) m_canal1.refresh(      m_ask,      m_bid);
    if( EA_NEGOCIAR_ATIVO_2) m_canal2.refresh(m_tick2.ask,m_tick2.bid);

    //<TODO> definir local correto apos teste inicial
    definirT4GPorcentagemCanal();

    // atualizando precos de abertura e fechamento da barra atual...
    //CopyRates(m_symb_str1,_Period,0,2,m_rates);
    //m_high0   = m_rates[0].high;
    //m_low0    = m_rates[0].low ;
    //m_lenBar0 = m_high0-m_low0;
    //m_high1   = m_rates[1].high;
    //m_low1    = m_rates[1].low ;
    //m_lenBar1 = m_high1-m_low1;
    // distancia desde entrada da ordem ateh o stop (quando trabalha com rajada fixa).
    //m_lenAteStop = (EA_DISTAN_PRIM_ORDEM_RAJ                     *m_tick_size1)+
    //               (EA_DISTAN_DEMAIS_ORDENS_RAJ*EA_TAMANHO_RAJADA*m_tick_size1);

    m_sld_sessao_atu = m_cta.Balance (); // saldo da conta exceto as ordens em aberto nas posicoes...
    m_qtdOrdens      = OrdersTotal   ();
    m_qtdPosicoest   = PositionsTotal();
    m_qtdPosicoes1   = 0;
    m_qtdPosicoes2   = 0;

    if( m_qtdPosicoest > 0 && PositionSelect(m_symb_str2) ){ m_qtdPosicoes1 = 1; }

    // adminstrando posicao aberta...
    if( m_qtdPosicoest > 0 && PositionSelect(m_symb_str1) ){
        m_qtdPosicoes1 = 1;

      //if ( PositionSelect  (m_symb_str1) ){ // soh funciona em contas hedge

            // atualizando o tempo de vida da posicao...
            if(m_tempo_posicao_ini == 0) m_tempo_posicao_ini = TimeCurrent();
            m_tempo_posicao_atu = TimeCurrent() - m_tempo_posicao_ini;

            // atualizando id da posicao...
            m_positionId             = PositionGetInteger(POSITION_IDENTIFIER );

            // atualizando se estamos comprados ou vendidos...
            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){ setCompradoSoft(); }else{ setVendidoSoft(); }

            // atualizando volume da posicao...
            m_posicaoVolumePend      = PositionGetDouble (POSITION_VOLUME     );
            m_posicaoLotsPend        = m_posicaoVolumePend/m_lots_step1         ;

            // obtendo o breakeven...
            m_breakeven        =            PositionGetDouble (POSITION_PRICE_OPEN )  ;
            m_precoPosicao     = normalizar1(PositionGetDouble (POSITION_PRICE_OPEN ) ); // este eh o valor medio de abertura da posicao.
            m_val_order_4_gain = m_precoPosicao;                                        // que neste formato passamos para a variavel
                                                                                        // que anteriormente guardava o preco original
                                                                                        // de abertura da posicao.

            ///////////////////////////////////
            if( m_precoPosicaoAnt == 0 ){ m_precoPosicaoAnt = m_precoPosicao;}

            // preco da posicao (breakeven) mudou...
            if( m_precoPosicao != m_precoPosicaoAnt ){

                if( (estouComprado1() && m_precoPosicao > m_precoPosicaoAnt) ||
                    (estouVendido1 () && m_precoPosicao < m_precoPosicaoAnt)  ){
                    m_qtd_ticks_4_gain_ini_1 -= m_qtd_ticks_4_gain_decr ; // a cada movimentacao da posicao, reduzo a quantidade de ticks necessarios para o gain.
                    Print(":-| "__FUNCTION__, " m_qtd_ticks_4_gain_ini_1=",m_qtd_ticks_4_gain_ini_1 );
                }
                m_precoPosicaoAnt = m_precoPosicao; // salvo no preco anterior

            }

            definirPrecoSaidaPosicao(); // deve ser chamado apos a definicao de m_qtd_ticks_4_gain_ini_1 acima

            if( estouComprado1() ){
                m_posicaoVolumeTot    = m_volComprasNaPosicao;
              //m_lucroPosicaoParcial = (m_bid-m_breakeven)*m_posicaoLotsPend*m_point_value1              ;
                m_lucroPosicaoParcial = (m_bid-m_breakeven)*m_posicaoLotsPend*m_point_value1*(m_lots_step1); // 16/02/21 correcao valor do lote

            }else{
                if( estouVendido1() ){
                    m_posicaoVolumeTot    = m_volVendasNaPosicao;
                  //m_lucroPosicaoParcial = (m_breakeven-m_ask)*m_posicaoLotsPend*m_point_value1;
                    m_lucroPosicaoParcial = (m_breakeven-m_ask)*m_posicaoLotsPend*m_point_value1*(m_lots_step1); // 16/02/21 correcao valor do lote
                }
            }

            m_posicaoProfit  = PositionGetDouble (POSITION_PROFIT); // lucro nao realizado da posicao...
            m_capitalLiquido = m_cta.Equity(); // saldo da conta considerando o lucro nao realizado da posicao.
            m_lucroPosicaoRealizado = m_sld_sessao_atu - m_capitalInicial; // atualizado com a saida de lotes da posicao

          //m_lucroPosicao = m_capitalLiquido - m_capitalInicial; // voltou versao em 03/02/2020 as 11:50
          //m_lucroPosicao = m_posicaoProfit; // passou a usar em 05/06/2020 jah que nessa estrategia as posicoes sao fechadas de vez.
          //m_lucroPosicao = m_capitalLiquido - m_capitalInicial; // voltou versao em 07/10/2020
            m_lucroPosicao = m_lucroPosicaoRealizado + m_lucroPosicaoParcial; // 22/10/2020 testando calculo de lucro da posicao...

          //m_lucroPosicao4Gain = (m_posicaoVolumeTot *m_stop_porc);
            m_lucroPosicao4Gain = (m_posicaoVolumeTot *m_qtd_ticks_4_gain_ini_1)*(m_lots_step1); // 16/02/21 correcao valor do lote
          //m_lucroPosicao4Gain = (m_posicaoVolumeTot *m_qtd_ticks_4_gain_ini_1); // passou a usar em 05/06/2020
          //m_lucroPosicao4Gain = (m_posicaoVolumePend*m_qtd_ticks_4_gain_ini_1); // passou a usar em 05/06/2020

            ///////////////////////////////////
//      }else{
//
//         // aqui neste bloco, estah garantido que nao ha posicao aberta...
//         m_qtdPosicoes1         = 0;
//         m_volVendasNaPosicao  = 0;
//         m_volComprasNaPosicao = 0;
//
//         m_capitalInicial    =  m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
//         m_qtd_ticks_4_gain_ini_1 = EA_QTD_TICKS_4_GAIN_INI_1;
//         m_comprado          =  false;
//         m_vendido           =  false;
//         m_stop              =  false;
//         m_lucroPosicao      =  0;
//         m_lucroPosicaoParcial = 0;
//         m_lucroPosicaoRealizado = 0;
//         m_lucroPosicao4Gain =  0;
//         m_posicaoVolumePend =  0; // versao 02-085
//         m_posicaoLotsPend   =  0;
//         m_posicaoProfit     =  0;
//         m_posicaoVolumeTot  =  0;
//         m_val_order_4_gain  =  0; // zerando o valor da primeira ordem da posicao...
//         m_tempo_posicao_atu =  0;
//         m_tempo_posicao_ini =  0;
//         m_positionId        = -1;
//         m_precoPosicaoAnt   = 0 ;
//      }
    }else{
        // aqui neste bloco, estah garantido que nao ha posicao aberta...
        m_qtdPosicoes1         = 0;
        m_volVendasNaPosicao   = 0;
        m_volComprasNaPosicao  = 0;

        m_capitalInicial       = m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
        //m_qtd_ticks_4_gain_ini_1 = EA_QTD_TICKS_4_GAIN_INI_1;
        setOffSetFormadorDeMercado(m_offset_em_ticks);
        m_comprado          = false;
        m_vendido           = false;
        m_stop              = false;
        m_acionado_trailling_stop = false;
        m_lucroPosicao          = 0;
        m_lucroPosicaoParcial   = 0;
        m_lucroPosicaoRealizado = 0;
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
        m_time_ini_fechamento_pos = 0;

        //Deixando o stop loss de posicao preparado. Quando posicionado, nao altera o stop loss de posicao.
        //calcStopLossPosicao();
    }

    showAcao2("normal");
} // refreshme()

string astIfNeg(double val){ return astIfNeg(val,0); }
string astIfNeg(double val, int digits){
    if( val < 0 ) return DoubleToString(val,digits) + " *";
                  return DoubleToString(val,digits);
}


void showAcao(string acao){

   if( !EA_SHOW_TELA ){ return; }

   Comment(
         //"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
         //"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
         //" \n ticks_consertados="         ,m_est.getQtdTicksConsertados(),
         //" \n m_cta.Balance="             ,m_cta.Balance          (),
         //" \n m_cta.Equity="              ,m_cta.Equity           (),
         //" \n m_cta.Profit="              ,m_cta.Profit           (),
           " LUCRO E LOTES ==="                          ,
           " \n lucro Conf/Tot="              +astIfNeg(m_lucroPosicaoRealizado,2) + " / " +
                                               astIfNeg(m_lucroPosicao         ,2) + "  lucroPos4Gain=" +astIfNeg(m_lucroPosicao4Gain    ,2),

         //" \n lucroPosPend="              +astIfNeg(m_lucroPosicaoParcial  ,2),
         //" \n m_posicao1.Profit="          ,m_posicao1.Profit       (),
         //" \n m_posicao1.Volume="          ,m_posicao1.Volume       (),
           " \n LOTS Pend/Tot/addSelAdv="   +astIfNeg(m_posicaoLotsPend ,0)+ "/"+
                                             astIfNeg(m_posicaoVolumeTot,0)+ "/"+
                                             DoubleToString(getTicksAddPorSelecaoAdversa1(),0)+
           //================
           " \n INCLINACAO ===" +
           " \n InclTrade/InclPair="            +astIfNeg(m_est.getInclinacaoTrade  (),4)+ " / " +
                                                 astIfNeg(m_par.regLinSlope         (),8)+
           //================
           " \n DIVERSOS ==="                          ,
         //" \n m_ask="                     ,m_ask                    ,
         //" \n m_bid="                     ,m_bid                    ,
           " \n tempo_posicao="             ,m_tempo_posicao_atu       ,
         " ---  LenVetAcumTrade="           ,m_est.getLenVetAcumTrade(),
         //" \n m_posicao1.PriceOpen="       ,m_posicao1.PriceOpen    (),
         //" \n m_posicao1.PriceCurrent="    ,m_posicao1.PriceCurrent (),
         //" \n acao="                      ,acao                     ,
           //----------------
           " \n len_canal_em_ticks_1="       + astIfNeg(m_canal1.getLenCanalOperacionalEmTicks() )+
           " \n regiaoSup/Inf_1="            + astIfNeg(m_canal1.regiaoSuperior()                )+ " / " +
                                               astIfNeg(m_canal1.regiaoInferior()                )+
           "    precoregiaoSup/Inf_1="       + astIfNeg(m_canal1.getPrecoRegiaoSuperior(), 3     )+ " / " +
                                               astIfNeg(m_canal1.getPrecoRegiaoInferior(), 3     )+
           //----------------
           " \n len_canal_em_ticks_2="       + astIfNeg(m_canal2.getLenCanalOperacionalEmTicks() )+
           " \n regiaoSup/Inf_2="            + astIfNeg(m_canal2.regiaoSuperior()                )+ " / " +
                                               astIfNeg(m_canal2.regiaoInferior()                )+
           "    precoregiaoSup/Inf_2="       + astIfNeg(m_canal2.getPrecoRegiaoSuperior(), 3     )+ " / " +
                                               astIfNeg(m_canal2.getPrecoRegiaoInferior(), 3     )+
           //----------------
         //" \n m_est.getInclinacaoHLTrade="    ,m_est.getInclinacaoHLTrade   (),
         //" \n m_est.getInclinacaoHLTTradeBuy=",m_est.getInclinacaoHLTradeBuy(),
         //" \n m_est.getInclinacaoHLTradeSel=" ,m_est.getInclinacaoHLTradeSel(),
           " \n PARAMETROS FIXOS/DINAMICOS ===" +
           " \n DIST_IN_POS/OUT_POS="      +astIfNeg(EA_DIST_MIN_IN_BOOK_IN_POS ) + " / " + astIfNeg(m_dist_min_in_book_in_pos  ,0) + " --- " +
                                            astIfNeg(EA_DIST_MIN_IN_BOOK_OUT_POS) + " / " + astIfNeg(m_dist_min_in_book_out_pos ,0) +
           " \n LAG_RAJADA="               +astIfNeg(EA_LAG_RAJADA1              ) + " / " + astIfNeg(m_lag_rajada1               ,0) +
           " \n TICKS_4_GAIN_INI---MIN="   +astIfNeg(m_qtd_ticks_4_gain_ini_1, 2) + " / " + astIfNeg(m_qtd_ticks_4_gain_ini_2   ,2) + " --- " +
                                            astIfNeg(EA_QTD_TICKS_4_GAIN_MIN_1,2) + " / " + astIfNeg(EA_QTD_TICKS_4_GAIN_MIN_2  ,2) +
         //" \n m_razao_lag_rajada_x_dist_entrada_book="  ,m_razao_lag_rajada_x_dist_entrada_book ,
         //" \n m_offset/m_offset_em_ticks="              ,astIfNeg(m_offset         ,_Digits) + " / " +
         //                                                astIfNeg(m_offset_em_ticks,_Digits) +
        // " \n CUSUM ==="                          ,
        // " \n K/H="                              ,EA_KK, " / " ,EA_HH                     ,
        // " \n VC+/C+/H+/Q+ = "                   +astIfNeg(m_cusum.getCmais (),_Digits),"/",m_strikeCMais ,"/",m_strikeHmais ,"/",(m_cusum.getCmais ()>m_cusum.getCmenos()),
        // " \n VC- /C- /H- /Q-  = "               +astIfNeg(m_cusum.getCmenos(),_Digits),"/",m_strikeCMenos,"/",m_strikeHmenos,"/",(m_cusum.getCmenos()>m_cusum.getCmais ()),
           //" \n LDP/LO2/LEP="                      ,DoubleToString(m_est.getDPTradeLogRet() ,6)+"/"+
           //                                         DoubleToString(m_est.getVarTradeLogRet(),6)+"/"+
           //                                         DoubleToString(m_est.getDPTradeLogRet()/oneIfZero(sqrt(m_est.getVolTotTot())),6),
           " \n INCLINACAO REGRESSAO E PRECO MEDIO ===" +
         //" \n InclinacaoHLTrade="             ,astIfNeg(m_est.getInclinacaoHLTrade(),2)+
           " \n InclTrade/InclPair="            ,astIfNeg(m_est.getInclinacaoTrade  (),4)+ " / " +
                                                 astIfNeg(m_par.regLinSlope         (),8)+
         //" \n DxMedTradeMedBuy="              ,astIfNeg(m_est.getPrecoMedTrade()-m_est.getPrecoMedTradeBuy(),2)+
         //" \n DxMedTradeMedSel="              ,astIfNeg(m_est.getPrecoMedTrade()-m_est.getPrecoMedTradeSel(),2)+
         //" \n m_precoAtual="                  +astIfNeg(m_tick1.last,_Digits)+
         //" \n ESTIM="                         +astIfNeg(m_precoEstim   ,_Digits)+
         //" \n m_b0/m_b1="                     +astIfNeg(m_b0,2)+"/"+astIfNeg(m_b1,4)+
         //" \n R2="                            +astIfNeg(m_r2           ,4)+
         //" \n getInclinacaoTrade="            +astIfNeg(m_est.getInclinacaoTrade  (),4)+
           " \n VOLATILIDADE ===" +
           " \n O2/DP/DPLR/DPPT="                  +astIfNeg(m_est.getVarTrade     (),2)+" / " +
                                                    astIfNeg(m_est.getDPTrade      (),2)+" / " +
                                                    astIfNeg(m_est.getDPTradeLogRet(),5)+" / " +
                                                    astIfNeg(m_par.getSpreadStd    (),5)+
       //  " \n ENTRADA  E SAIDA ==="+
       //  " \n COMPRA abrir/fechar= "   +cusumOrientaCompra()+ " / " +cusumOrientaFecharPosicaoComprada()+
       //  " \n VENDA  abrir/fechar= "   +cusumOrientaVenda ()+ " / "  +cusumOrientaFecharPosicaoVendida ()+
           //" \n SAIDA ==="+
           //" \n cusumOrientaFecharCompra=" +cusumOrientaFecharPosicaoComprada()+
           //" \n cusumOrientaFecharVenda="  +cusumOrientaFecharPosicaoVendida ()+
           " \n INCLINACAO ===" +
           " \n InclTrade/InclPair="            ,astIfNeg(m_est.getInclinacaoTrade  (),4)+ " / " +
                                                 astIfNeg(m_par.regLinSlope         (),8)+
           " \n DIVERSOS ==="+
           " \n lenBarraMediaEmTicks="     +astIfNeg(m_lenBarraMediaEmTicks,_Digits) +
           " \n DEEP IMBALANCE ==="+
           " \n BOOK DEEP1/DEEP2 = "    +astIfNeg(EA_BOOK_DEEP1) + "/" +
                                         astIfNeg(EA_BOOK_DEEP2) +
           " \n IMBAL LIMIAR1/LIMIAR2 = "  +astIfNeg(EA_BOOK_IMBALANCE1,2) + "/" +
                                            astIfNeg(EA_BOOK_IMBALANCE2,2) +
           " \n BOOK IMBAL1/IMBAL2 = "     +astIfNeg(m_book1.getImbalance(),3 ) + "/" +
                                            astIfNeg(m_book2.getImbalance(),3 ) +
           " \n RECOMENDACAO IMBAL1/IMBAL2 = " + m_book1.getDirecaoImbalanceStr() + "/" +
                                                 m_book2.getDirecaoImbalanceStr()

         //" \n getDxMedTradeBook="        ,astIfNeg(m_est.getDxMedTradeBook(),2)+

           );
}


void showAcao2(string acao){

   if( !EA_SHOW_TELA ){ return; }

   Comment(
           "LenVetAcumTrade 1="           ,m_est.getLenVetAcumTrade(),
           //----------------
           //" \n len_canal_em_ticks_1="       + astIfNeg(m_canal1.getLenCanalOperacionalEmTicks() )+
           //" \n regiaoSup/Inf_1="            + astIfNeg(m_canal1.regiaoSuperior()                )+ " / " +
           //                                    astIfNeg(m_canal1.regiaoInferior()                )+
           //----------------
           //" \n len_canal_em_ticks_2="       + astIfNeg(m_canal2.getLenCanalOperacionalEmTicks() )+
           //" \n regiaoSup/Inf_2="            + astIfNeg(m_canal2.regiaoSuperior()                )+ " / " +
           //                                    astIfNeg(m_canal2.regiaoInferior()                )+
           //"    precoregiaoSup/Inf_2="       + astIfNeg(m_canal2.getPrecoRegiaoSuperior(), 3     )+ " / " +
           //                                    astIfNeg(m_canal2.getPrecoRegiaoInferior(), 3     )+
           //----------------
        // " \n PARAMETROS FIXOS/DINAMICOS ===" +
        // " \n CUSUM ==="                          ,
        // " \n K/H="                              ,EA_KK, " / " ,EA_HH                     ,
        // " \n VC+/C+/H+/Q+ = "                   +astIfNeg(m_cusum.getCmais (),_Digits),"/",m_strikeCMais ,"/",m_strikeHmais ,"/",(m_cusum.getCmais ()>m_cusum.getCmenos()),
        // " \n VC- /C- /H- /Q-  = "               +astIfNeg(m_cusum.getCmenos(),_Digits),"/",m_strikeCMenos,"/",m_strikeHmenos,"/",(m_cusum.getCmenos()>m_cusum.getCmais ()),
           //" \n LDP/LO2/LEP="                      ,DoubleToString(m_est.getDPTradeLogRet() ,6)+"/"+
           //                                         DoubleToString(m_est.getVarTradeLogRet(),6)+"/"+
           //                                         DoubleToString(m_est.getDPTradeLogRet()/oneIfZero(sqrt(m_est.getVolTotTot())),6),
           " \n INCLINACAO REGRESSAO E PRECO MEDIO ===" +
           " \n InclinacaoHLTrade="             ,astIfNeg(m_est.getInclinacaoHLTrade(),2)+
           " \n InclTrade/InclPair="            ,astIfNeg(m_est.getInclinacaoTrade  (),4)+ " / " +
                                                 astIfNeg(m_par.regLinSlope         (),8)+
         " \n DxMedTradeMedBuy="                ,astIfNeg(m_est.getPrecoMedTrade()-m_est.getPrecoMedTradeBuy(),2)+
         " \n DxMedTradeMedSel="                ,astIfNeg(m_est.getPrecoMedTrade()-m_est.getPrecoMedTradeSel(),2)+
         "\n m_est.getVolTradeBuyPorSeg/acel: ", astIfNeg(m_est.getVolTradeBuyPorSeg(),2)+ " / " + astIfNeg(m_est.getAceVolBuy(),2)+
         "\n m_est.getVolTradeSelPorSeg/acel: ", astIfNeg(m_est.getVolTradeSelPorSeg(),2)+ " / " + astIfNeg(m_est.getAceVolSel(),2)+
         "\n m_est.getVolTradeLiqPorSeg/acel: ", astIfNeg(m_est.getVolTradeLiqPorSeg(),2)+ " / " + astIfNeg(m_est.getAceVolLiq(),2)+
         "\n m_est.getVolTradeTotPorSeg/acel: ", astIfNeg(m_est.getVolTradeTotPorSeg(),2)+ " / " + astIfNeg(m_est.getAceVol   (),2)+
         "\n m_predict_NET1                 : ", astIfNeg(m_predict_NET1              ,2)+
         "\n m_book1.IWFV/TLFV/IMB/SINAL    : ", astIfNeg(m_book1.getIWFV       (EA_BOOK_DEEP1)    ,0)+ " / " + 
                                                 astIfNeg(m_book1.getTLFV       (EA_BOOK_DEEP1)    ,0)+ " / " + 
                                                 astIfNeg(m_book1.getImbalance  (EA_BOOK_DEEP1)*100,0)+ " / " +  
                                                 astIfNeg(        calcSinalBook1(EA_BOOK_DEEP1)    ,0)        +
         //"\n m_predict_RDF1                 : ", astIfNeg(m_predict_RDF1             ,2)+
         //"\n m_pos_mat_RDF/TOT              : ", astIfNeg(m_pos_mat_RDF              ,0)+ "/" + astIfNeg(EA_MAT_RDF_TAMANHO     ,0) +
         //"\n m_pos_mat_RDF/TOT (nova)       : ", astIfNeg(m_pos_mat_RDF_nova         ,0)+ "/" + astIfNeg(EA_MAT_RDF_TAMANHO_NOVA,0) +
         
         
         //" \n m_precoAtual="                  +astIfNeg(m_tick1.last,_Digits)+
         //" \n ESTIM="                         +astIfNeg(m_precoEstim   ,_Digits)+
         //" \n m_b0/m_b1="                     +astIfNeg(m_b0,2)+"/"+astIfNeg(m_b1,4)+
         //" \n R2="                            +astIfNeg(m_r2           ,4)+
         //" \n getInclinacaoTrade="            +astIfNeg(m_est.getInclinacaoTrade  (),4)+
           " \n VOLATILIDADE ===" +
           " \n O2/DP/DPLR/DPPT="                  +astIfNeg(m_est.getVarTrade     (),2)+" / " +
                                                    astIfNeg(m_est.getDPTrade      (),2)+" / " +
                                                    astIfNeg(m_est.getDPTradeLogRet(),5)+" / " +
                                                    astIfNeg(m_par.getSpreadStd    (),5)+
       //  " \n ENTRADA  E SAIDA ==="+
       //  " \n COMPRA abrir/fechar= "   +cusumOrientaCompra()+ " / " +cusumOrientaFecharPosicaoComprada()+
       //  " \n VENDA  abrir/fechar= "   +cusumOrientaVenda ()+ " / "  +cusumOrientaFecharPosicaoVendida ()+
           //" \n SAIDA ==="+
           //" \n cusumOrientaFecharCompra=" +cusumOrientaFecharPosicaoComprada()+
           //" \n cusumOrientaFecharVenda="  +cusumOrientaFecharPosicaoVendida ()+
           " \n INCLINACAO ===" +
           " \n InclTrade/InclPair="            ,astIfNeg(m_est.getInclinacaoTrade  (),4)+ " / " +
                                                 astIfNeg(m_par.regLinSlope         (),8)+
           "\n DIVERSOS ==="+
           "\n lenBarraMediaEmTicks="     +astIfNeg(m_lenBarraMediaEmTicks,_Digits)+
           "\n m_lag_rajada/dinamico1:" + astIfNeg(m_lag_rajada1,0)+"/"+astIfNeg(m_lag_rajada_dinamico1,0)+
           "\n m_lag_rajada/dinamico2:" + astIfNeg(m_lag_rajada2,0)+"/"+astIfNeg(m_lag_rajada_dinamico2,0)+
           "\n m_tipo_entrada_permitida1/2:" + EnumToString(m_tipo_entrada_permitida1)+"/"+EnumToString(m_tipo_entrada_permitida2) +

           " \n TICKS_4_GAIN_INI---MIN="   +astIfNeg(m_qtd_ticks_4_gain_ini_1, 2) + " / " + astIfNeg(m_qtd_ticks_4_gain_ini_2   ,2) + " --- " +
                                            astIfNeg(EA_QTD_TICKS_4_GAIN_MIN_1,2) + " / " + astIfNeg(EA_QTD_TICKS_4_GAIN_MIN_2  ,2) 
           );
}


void refreshControlPanel(){
  // refresh do painel eh no maximo uma vez por segundo...
  //if( m_date_atu.sec%2 == 0 ) return;

  if( !EA_SHOW_CONTROL_PANEL ) return;

  if( m_qtdPosicoes1==0 ){
      m_cp.setPosicaoNula("NULL");
  }else{
      if (estouComprado1()  ){
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
  m_cp.setT4g          (     m_qtd_ticks_4_gain_ini_1);
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
  m_cp.setLEN0  ( m_canal1.getLenCanalOperacionalEmTicks(),0);
  m_cp.setLEN1  ( m_canal1.getCoefLinear(),0);
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
//    m_qtd_ticks_4_gain_ini_1 = m_qtd_ticks_4_gain_new;
//    m_qtd_ticks_4_gain_raj = m_qtd_ticks_4_gain_new;
//    m_passo_rajada         = m_qtd_ticks_4_gain_new;
//    m_stop_porc            = m_stop_porc/m_passo_incremento;
//}




int    m_dist_min_in_book_in_pos              = 0;//EA_DIST_MIN_IN_BOOK_IN_POS; //DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK  ABRINDO POSICAO
int    m_dist_min_in_book_out_pos             = 0;//EA_DIST_MIN_IN_BOOK_OUT_POS; //DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK FECHANDO POSICAO
int    m_lag_rajada1                          = 0;//EA_LAG_RAJADA1                          ; //LAG_RAJADA
int    m_lag_rajada2                          = 0;//EA_LAG_RAJADA2                          ; //LAG_RAJADA
int    m_lag_rajada_dinamico1                 = 0;
int    m_lag_rajada_dinamico2                 = 0;


// calcula o lag em funcao do volume e de um coeficiente de risco recebidos
// exemplo de lag quando o coeficiente 0.5
   // vol                     lag_calculado
   // 1   1                 = 1
   // 2   1       + 0.5     = 1.5
   // 3   1.5     + 0.75    = 2.25
   // 4   2.25    + 1,125   = 3.375
   // 5   3.375   + 1,345   = 5.0475
   // 6   5.0475  + 2,52375 = 7.57125
   // 7   7.57125 + 

int calcLag(int vol, int lag_ini, double coef_risco){
    double lag = lag_ini;
    for(int i=0; i<vol; i++){ lag = lag+lag*coef_risco; }
    return (int)round(lag);
}

double m_razao_lag_rajada_x_dist_entrada_book = 0;//(double)EA_DIST_MIN_IN_BOOK_IN_POS/(double)EA_LAG_RAJADA1;
void definirPasso(){

   m_posicao1.Select(m_symb_str1);
   double vol1 = m_posicao1.Volume();
 //if(vol1==0) vol1 = 1;
 //m_lag_rajada_dinamico1 = (int)(vol1) * m_lag_rajada1 * 1;
   m_lag_rajada_dinamico1 = calcLag((int)vol1,m_lag_rajada1,EA_COEF_RISCO_LAG_DINAMICO);
   
   m_posicao2.Select(m_symb_str2);
   double vol2 = m_posicao2.Volume();
 //if(vol2==0) vol2 = 1;
 //m_lag_rajada_dinamico2 = (int)(vol2) * m_lag_rajada2 * 1;
   m_lag_rajada_dinamico2 = calcLag((int)vol2,m_lag_rajada2,EA_COEF_RISCO_LAG_DINAMICO);
   
   //Print("m_posicao1/2.Volume()   :",(int)vol1             ,"/", (int)vol2             );
   //Print("m_lag_rajada_dinamico1/2:",m_lag_rajada_dinamico1,"/", m_lag_rajada_dinamico2);

   if( EA_ALVO_DINAMICO ){

       if( EA_TAMANHO_RAJADA==0 ) return;

       if( m_acao_posicao == HFT_FORMADOR_DE_MERCADO ){
           m_razao_lag_rajada_x_dist_entrada_book = (double)EA_DIST_MIN_IN_BOOK_IN_POS/oneIfZero( (double)EA_LAG_RAJADA1 );
           m_qtd_ticks_4_gain_ini_1                 =      ceil( m_canal1.getLenCanalOperacionalEmTicks()/(double)(EA_TAMANHO_RAJADA*2.0 +(m_razao_lag_rajada_x_dist_entrada_book)*2.0 ) );
           if(m_qtd_ticks_4_gain_ini_1<EA_QTD_TICKS_4_GAIN_MIN_1) m_qtd_ticks_4_gain_ini_1=EA_QTD_TICKS_4_GAIN_MIN_1;
           m_lag_rajada1                           = (int)ceil(m_qtd_ticks_4_gain_ini_1);
           m_passo_rajada                         = m_lag_rajada1; //nao eh usado. Eh soh pra aparecer no painel de controle.
           m_dist_min_in_book_in_pos              = (int)ceil(m_lag_rajada1*m_razao_lag_rajada_x_dist_entrada_book);
           m_dist_min_in_book_out_pos             = (int)ceil(m_lag_rajada1*m_razao_lag_rajada_x_dist_entrada_book); //<todo> consertar

       }else{
           m_qtd_ticks_4_gain_ini_1    = m_canal1.getLenCanalOperacionalEmTicks()/(double)EA_TAMANHO_RAJADA;

           m_passo_rajada            = (int)floor(  ( m_canal1.getLenCanalOperacionalEmTicks()-
                                                      m_canal1.getLenCanalOperacionalEmTicks()*
                                                      EA_PORC_REGIAO_OPERACIONAL_CANAL         )/(double)EA_TAMANHO_RAJADA
                                            );

         //m_passo_rajada                      = floor( m_qtd_ticks_4_gain_ini_1 );
           if( m_passo_rajada == 0 ) m_passo_rajada = 1;
           m_raj_unica_distancia_demais_ordens = m_passo_rajada;
           m_raj_unica_distancia_prim_ordem    = m_passo_rajada;
           m_qtd_ticks_4_gain_decr             = m_qtd_ticks_4_gain_ini_1/(double)EA_TAMANHO_RAJADA;
         //m_qtd_ticks_4_gain_decr             = 0;   // testando 1 tick

           m_raj_unica_distancia_prim_ordem    = m_passo_rajada;
           m_raj_unica_distancia_demais_ordens = m_passo_rajada;

       }

   }

   if( EA_PASSO_DINAMICO ){
       m_qtd_ticks_4_gain_ini_1 =            m_qtd_ticks_4_gain_new;
       m_qtd_ticks_4_gain_raj   =            m_qtd_ticks_4_gain_new;
       m_passo_rajada           =      (int)(m_qtd_ticks_4_gain_new*EA_PASSO_DINAMICO_PORC_T4G);
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


bool m_tem_book;
void inicializarBookEvent(){
     inicializarBookEvent(m_symb_str1);
     inicializarBookEvent(m_symb_str2);
     m_book1.initialize(m_symb_str1,EA_BOOK_DEEP1,EA_BOOK_IMBALANCE1); m_book1.set_db(m_db); m_book1.set_registrar_db(EA_REGISTRA_BOOK);
     m_book2.initialize(m_symb_str2,EA_BOOK_DEEP2,EA_BOOK_IMBALANCE2); m_book2.set_db(m_db); m_book2.set_registrar_db(EA_REGISTRA_BOOK);
}

void inicializarBookEvent(string symb_str){
    if( !EA_PROCESSAR_BOOK ) return;
    Print(":-| ", __FUNCTION__," ******************************** Inicializando bookevent para o ticker",symb_str,"...");
    m_tem_book = MarketBookAdd( symb_str );
    Print(":-| ", __FUNCTION__,":",symb_str,": m_tem_book   :", m_tem_book );
    Print(":-| ", __FUNCTION__," ******************************** BookEvent inicializado.");
}

    //----------------------------------------------------------------------------------------
    // tem de ser o primeiro ponto pois ha varios a frente que dependem do simbolo configurado
    //----------------------------------------------------------------------------------------
void inicializarSimbolos(){
    Print(":-| ", __FUNCTION__," ******************************** Inicializando simbolo 1...");
    m_symb1.Name( Symbol() ); // inicializacao da classe CSymbolInfo
    m_symb_str1 = Symbol();
    m_symb1.Refresh     (); // propriedades do simbolo. Basta executar uma vez.
    m_symb1.RefreshRates(); // valores do tick. execute uma vez por tick.
    m_tick_size1        = m_symb1.TickSize(); //Obtem a alteracao minima de preco
    m_tick_value1       = m_symb1.TickValue(); // valor do tick na moeda do ativo;
    m_point1            = m_symb1.Point()   ;
    m_point_value1      = NormalizeDouble(m_tick_value1/m_tick_size1, 2); // valor do ponto na moeda do ativo
    m_lots_step1        = m_symb1.LotsStep();
    m_lots_min          = m_symb1.LotsMin() ;
    Print(":-| ", __FUNCTION__," m_symb_str1   :", m_symb_str1      );
    Print(":-| ", __FUNCTION__," m_tick_size1  :", m_tick_size1     );
    Print(":-| ", __FUNCTION__," m_tick_value1 :", m_tick_value1    );
    Print(":-| ", __FUNCTION__," m_point1      :", m_point1          );
    Print(":-| ", __FUNCTION__," m_point_value1:", m_point_value1   );
    Print(":-| ", __FUNCTION__," m_lots_min    :", m_lots_min       );
    Print(":-| ", __FUNCTION__," m_lots_step1  :", m_lots_step1     );
    Print(":-| ", __FUNCTION__," ******************************** Simbolo 1 inicializado.> \n");

    Print(":-| ", __FUNCTION__," ******************************** Inicializando simbolo 2...");
    m_symb2.Name( EA_TICKER_REF); // inicializacao da classe CSymbolInfo
    m_symb_str2 = EA_TICKER_REF;
    m_symb2.Refresh     (); // propriedades do simbolo. Basta executar uma vez.
    m_symb2.RefreshRates(); // valores do tick. execute uma vez por tick.
    m_tick_size2        = m_symb2.TickSize (); //Obtem a alteracao minima de preco
    m_tick_value2       = m_symb2.TickValue(); // valor do tick na moeda do ativo;
    m_point2            = m_symb2.Point()   ;
    m_point_value2      = NormalizeDouble(m_tick_value2/m_tick_size2, 2 ); // valor do ponto na moeda do ativo
    m_lots_step2        = m_symb2.LotsStep();
  //m_lots_min          = m_symb1.LotsMin() ;
    Print(":-| ", __FUNCTION__," m_symb_str2   :", m_symb_str2      );
    Print(":-| ", __FUNCTION__," m_tick_size2  :", m_tick_size2     );
  //Print(":-| ", __FUNCTION__," m_tick_value1 :", m_tick_value1    );
    Print(":-| ", __FUNCTION__," m_point2      :", m_point2         );
    Print(":-| ", __FUNCTION__," m_point_value2:", m_point_value2   );
  //Print(":-| ", __FUNCTION__," m_lots_min    :", m_lots_min       );
    Print(":-| ", __FUNCTION__," m_lots_step2  :", m_lots_step2     );
    Print(":-| ", __FUNCTION__," ******************************** Simbolo 2 inicializado.>");

}

double m_passo_dinamico_porc_canal_entrelaca = 0;
double m_stopLossPosicao                     = 0;

void inicializarVariaveisRecebidasPorParametro(){

    Print(":-| ", __FUNCTION__," ******************************** Inicializando variaveis diversas...");
    m_aguardar_para_abrir_posicao = EA_SLEEP_INI_OPER*1000;

    m_tipo_entrada_permitida1 = EA_TIPO_ENTRADA_PERMITIDA_1;
    m_tipo_entrada_permitida2 = EA_TIPO_ENTRADA_PERMITIDA_2;

    // stop loss da posicao
    m_stopLossPosicao = EA_STOP_LOSS;
    //m_stopLossPosicao = m_exp.getStopLoss();//EA_STOP_LOSS

    // O quanto a volatilidade por segundo deve ser maior que a volatilidade por segundo media para ser considerada alta.
    // Volatilidade por segundo eh o tamanho do canal de transacoes dividido pela quantidade de segundos do indicador feira.
    //m_volat4s_alta_porc = m_exp.getVolat4sAltaPorc();// EA_VOLAT4S_ALTA_PORC;

    // quantidade de periodos usados para calcular o coeficiente de entrelacamento.
    //m_exp.setEntrelacaPeriodoCoef(EA_ENTRELACA_PERIODO_COEF);


    // variaveis de controle do stop...
    m_qtd_ticks_4_gain_ini_1 = EA_QTD_TICKS_4_GAIN_INI_1;
    m_qtd_ticks_4_gain_ini_2 = EA_QTD_TICKS_4_GAIN_INI_2;
    m_qtd_ticks_4_gain_raj = EA_QTD_TICKS_4_GAIN_INI_1;
    m_vol_lote_raj         = EA_VOL_PRIM_ORDEM_RAJ!=0?EA_VOL_PRIM_ORDEM_RAJ*m_lots_step1:m_symb1.LotsMin();
    m_vol_lote_ini1        = EA_VOL_LOTE_INI_1    !=0?EA_VOL_LOTE_INI_1    *m_lots_step1:m_symb1.LotsMin();
    m_vol_lote_ini2        = EA_VOL_LOTE_INI_2    !=0?EA_VOL_LOTE_INI_2    *m_lots_step2:m_symb2.LotsMin();
    m_passo_rajada         = (int)EA_DISTAN_DEMAIS_ORDENS_RAJ;
    m_stop_qtd_contrat     = (int)EA_STOP_CHUNK;
    m_stop_chunk           = (int)EA_STOP_CHUNK;
    m_stop_porc            = EA_STOP_PORC_L1;

    // operacao com rajada unica.
    m_raj_unica_distancia_prim_ordem    = EA_DISTAN_PRIM_ORDEM_RAJ   ==0?m_qtd_ticks_4_gain_ini_1:EA_DISTAN_PRIM_ORDEM_RAJ   ; // se param for zero, usa EA_DISTAN_PRIM_ORDEM_RAJ
    m_raj_unica_distancia_demais_ordens = EA_DISTAN_DEMAIS_ORDENS_RAJ==0?m_qtd_ticks_4_gain_ini_1:EA_DISTAN_DEMAIS_ORDENS_RAJ; // se param for zero, usa EA_DISTAN_DEMAIS_ORDENS_RAJ
    m_qtd_ticks_4_gain_decr             = EA_QTD_TICKS_4_GAIN_DECR;
    m_Cmedia_direcaoVelocidadeTradeMedia.initialize(EA_EST_QTD_SEGUNDOS);
    m_volat_media.initialize(EA_EST_QTD_SEGUNDOS);

    Print(":-| ", __FUNCTION__," m_aguardar_para_abrir_posicao       :", m_aguardar_para_abrir_posicao          );
    Print(":-| ", __FUNCTION__," m_tipo_entrada_permitida1           :", EnumToString(m_tipo_entrada_permitida1));
    Print(":-| ", __FUNCTION__," m_tipo_entrada_permitida2           :", EnumToString(m_tipo_entrada_permitida2));
    Print(":-| ", __FUNCTION__," m_stopLossPosicao                   :", m_stopLossPosicao                      );
    Print(":-| ", __FUNCTION__," m_qtd_ticks_4_gain_ini_1            :", m_qtd_ticks_4_gain_ini_1           );
    Print(":-| ", __FUNCTION__," m_qtd_ticks_4_gain_ini_2            :", m_qtd_ticks_4_gain_ini_2           );
    Print(":-| ", __FUNCTION__," m_qtd_ticks_4_gain_raj              :", m_qtd_ticks_4_gain_raj             );
    Print(":-| ", __FUNCTION__," m_vol_lote_raj                      :", m_vol_lote_raj                     );
    Print(":-| ", __FUNCTION__," m_vol_lote_ini1                     :", m_vol_lote_ini1                    );
    Print(":-| ", __FUNCTION__," m_vol_lote_ini2                     :", m_vol_lote_ini2                    );
    Print(":-| ", __FUNCTION__," m_passo_rajada                      :", m_passo_rajada                     );
    Print(":-| ", __FUNCTION__," m_stop_qtd_contrat                  :", m_stop_qtd_contrat                 );
    Print(":-| ", __FUNCTION__," m_stop_chunk                        :", m_stop_chunk                       );
    Print(":-| ", __FUNCTION__," m_stop_porc                         :", m_stop_porc                        );
    Print(":-| ", __FUNCTION__," m_raj_unica_distancia_prim_ordem    :", m_raj_unica_distancia_prim_ordem   );
    Print(":-| ", __FUNCTION__," m_raj_unica_distancia_demais_ordens :", m_raj_unica_distancia_demais_ordens);
    Print(":-| ", __FUNCTION__," m_qtd_ticks_4_gain_decr             :", m_qtd_ticks_4_gain_decr            );
    Print(":-| ", __FUNCTION__," m_Cmedia_direcaoVelocidadeTradeMedia:", EA_EST_QTD_SEGUNDOS," seg"         );
    Print(":-| ", __FUNCTION__," m_volat_media                       :", EA_EST_QTD_SEGUNDOS," seg"         );
    Print(":-| ", __FUNCTION__," SLEEP_TESTE                         :", SLEEP_TESTE        ," miliseg"     );
    Print(":-| ", __FUNCTION__," ******************************** Variaveis diversas inicializadas."        );
}

void inicializarPassoRajadaFixoHFT_FORMADOR_DE_MERCADO(){
    Print(":-| ", __FUNCTION__," ******************************** Inicializando variaveis HFT_FORMADOR_DE_MERCADO...");
    m_dist_min_in_book_in_pos              = EA_DIST_MIN_IN_BOOK_IN_POS ; //DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK ABRINDO POSICAO
    m_dist_min_in_book_out_pos             = EA_DIST_MIN_IN_BOOK_OUT_POS; //DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK FECHANDO POSICAO
    m_razao_lag_rajada_x_dist_entrada_book = (double)EA_DIST_MIN_IN_BOOK_IN_POS/ oneIfZero( (double)EA_LAG_RAJADA1 );
    //m_qtd_ticks_4_gain_ini_1                 = EA_QTD_TICKS_4_GAIN_INI_1;
    //if(m_qtd_ticks_4_gain_ini_1<EA_QTD_TICKS_4_GAIN_MIN_1) m_qtd_ticks_4_gain_ini_1=EA_QTD_TICKS_4_GAIN_MIN_1;
    m_lag_rajada1                           = EA_LAG_RAJADA1;
    m_lag_rajada2                           = EA_LAG_RAJADA2;
    m_passo_rajada                         = m_lag_rajada1; //nao eh usado. Eh soh pra aparecer no painel de controle.

    Print(":-| ", __FUNCTION__," m_dist_min_in_book_in_pos             :", m_dist_min_in_book_in_pos               ,": DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK ABRINDO  POSICAO");
    Print(":-| ", __FUNCTION__," m_dist_min_in_book_out_pos            :", m_dist_min_in_book_out_pos              ,": DISTANCIA_MINIMA_PARA_ENTRAR_NO_BOOK FECHANDO POSICAO");
    Print(":-| ", __FUNCTION__," m_razao_lag_rajada_x_dist_entrada_book:", m_razao_lag_rajada_x_dist_entrada_book  );
    Print(":-| ", __FUNCTION__," m_lag_rajada1                         :", m_lag_rajada1                            );
    Print(":-| ", __FUNCTION__," m_lag_rajada2                         :", m_lag_rajada2                            );
    Print(":-| ", __FUNCTION__," m_passo_rajada                        :", m_passo_rajada                          );
    Print(":-| ", __FUNCTION__," ******************************** Variaveis HFT_FORMADOR_DE_MERCADO inicializadas.");
}


double m_offset_ant = EA_QTD_TICKS_4_GAIN_INI_1;
void setOffSetFormadorDeMercado( double offset ){
   if( EA_OFFSET_DINAMICO ){



     //offset = normalizar1(offset/(m_tick_size1+m_tick_size1/5) ); // mais uma divisao do offset. <todo> Verifique como diminuir o risco
     //offset =           (offset/(m_tick_size1              ) ); // mais uma divisao do offset. <todo> Verifique como diminuir o risco
       if( offset < EA_QTD_TICKS_4_GAIN_MIN_1 ) offset = EA_QTD_TICKS_4_GAIN_MIN_1;

       //if( offset == m_offset_ant ) return;

       m_qtd_ticks_4_gain_ini_1   =       offset;
       m_dist_min_in_book_in_pos  = (int) offset/3;
       m_dist_min_in_book_out_pos = (int) offset/3;
       m_lag_rajada1              = (int) offset/3;
       m_passo_rajada             = (int) offset/3;

       m_offset_ant = offset;
   }else{
       m_qtd_ticks_4_gain_ini_1 = EA_QTD_TICKS_4_GAIN_INI_1;
       m_qtd_ticks_4_gain_ini_2 = EA_QTD_TICKS_4_GAIN_INI_2;
   }

   //<TODO> definir local correto apos teste inicial
   definirT4GPorcentagemCanal();

}

// definie um T4G em funcao do tamanho do canal operacional.
void definirT4GPorcentagemCanal(){
    if(!EA_ALVO_DINAMICO) return;
    definirT4GPorcentagemCanal1();
    if( EA_NEGOCIAR_ATIVO_2 ){ definirT4GPorcentagemCanal2(); }

}

void definirT4GPorcentagemCanal1(){
    m_qtd_ticks_4_gain_ini_1 = m_canal1.getLenCanalOperacionalEmTicks()*EA_PORC_CANAL_T4G_1;

    //garantindo que o t4g nao ficarah menor que o minimo...
    if( m_qtd_ticks_4_gain_ini_1 < EA_QTD_TICKS_4_GAIN_MIN_1 ) m_qtd_ticks_4_gain_ini_1 = EA_QTD_TICKS_4_GAIN_MIN_1;
}
void definirT4GPorcentagemCanal2(){
    m_qtd_ticks_4_gain_ini_2 = m_canal2.getLenCanalOperacionalEmTicks()*EA_PORC_CANAL_T4G_2;

    //garantindo que o t4g nao ficarah menor que o minimo...
    if( m_qtd_ticks_4_gain_ini_2 < EA_QTD_TICKS_4_GAIN_MIN_2 ) m_qtd_ticks_4_gain_ini_2 = EA_QTD_TICKS_4_GAIN_MIN_2;
}


// retorna a porcentagem como um numero inteiro.
int porcentagem( double parte, double tot, int seTotZero){
    if( tot==0 ){ return seTotZero ; }
                  return (int)( (parte/tot)*100.0);
}

int m_qtd_print_debug = 0;


void fecharTudoForcado(string descr){
    m_trade1.cancelarOrdens(descr);

    if( PositionsTotal()>0 ){
        long idPos = PositionGetInteger(POSITION_IDENTIFIER);
        m_trade1.PositionClose(idPos);
    }
}

bool m_stop = false;
datetime m_time_ini_fechamento_pos = 0;
void fecharTudo(string descr){ fecharTudo(descr,"",EA_STOP_TICKS_TOLER_SAIDA); }
void fecharTudo(string descr,string strLog){ fecharTudo(descr,strLog,EA_STOP_TICKS_TOLER_SAIDA); }
void fecharTudo(string descr, string strLog, int qtdTicksDeslocamento){
    if( m_qtdPosicoes1>0 ){

        //////////////////////////////////////////////////////////////////////////////////
        // testando acionamento do stop usando o preco de saida da posicao...
        //
        // soh imprime no log uma vez por stop...
        //if(m_stop==false) Print(":-| ", __FUNCTION__,"(",descr,",",strLog,",",qtdTicksDeslocamento,")");

        m_stop = true;
        definirPrecoSaidaPosicao();
        if( alterarPrecoOrdensSaidaSeNecessario() ) Print(":-| ", __FUNCTION__,"(",descr,",",strLog,",",qtdTicksDeslocamento,")");

        if( m_time_ini_fechamento_pos==0) m_time_ini_fechamento_pos = TimeCurrent();
        if( (TimeCurrent()-m_time_ini_fechamento_pos) > EA_MAX_TMP_FECHAM_POSICAO ){
            Print(":-| ", __FUNCTION__,"(",descr,",",strLog,",",qtdTicksDeslocamento,") Forcando fechamento de posicao pois demorou mais de ",EA_MAX_TMP_FECHAM_POSICAO,"seg");
            m_trade1.PositionClose(m_symb_str1);
        }
        return;
        //
        //////////////////////////////////////////////////////////////////////////////////

        int    qtd = 1;
        string qtdStr;
        string qtdTicksdesloc = IntegerToString(qtdTicksDeslocamento);
      //while( m_qtdPosicoes1 > 0 ){
            qtdStr = IntegerToString(qtd++);
            Print   (":-| ", __FUNCTION__,":",qtdStr,":fecharPosicao2(",descr,",",strLog,",",qtdTicksdesloc,")");
            fecharPosicao2(descr, strLog, qtdTicksDeslocamento);
      //}
    }else{
        Print   (__FUNCTION__+":m_trade1.cancelarOrdens():descr:"+descr);
        m_trade1.cancelarOrdens(descr);
        if( m_stop == true ) m_stop = false;
    }
}

// se o preco de saida da posicao mudou, altera o preco das ordens de saida, a menos que o EA feche posicao por ordem de entrada e nao no breakeven...
bool alterarPrecoOrdensSaidaSeNecessario(){

    if( !EA_FECHA_POSICAO_NO_BREAK_EVEN && !m_stop ) return false;

    if( m_precoSaidaPosicao!=m_precoSaidaPosicaoAnt || m_stop ){
        m_precoSaidaPosicaoAnt = m_precoSaidaPosicao;
        m_trade1.alterarValorDeOrdensNumericasPara(m_symb_str1,m_precoSaidaPosicao,m_precoPosicao);
        m_trade1.trazerOrdensFechamentoPosicaoPara(m_precoSaidaPosicao);
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
      //doCloseRajada(m_qtd_ticks_4_gain_ini_1);

      //2. cancelando rajadas que ainda nao entraram na posicao...
      Print   (":-| ", __FUNCTION__+":cancelarOrdensRajada()..."          );
      cancelarOrdensRajada();

      //3. trazendo ordens de fechamento a valor presente...
      Print   (":-| ", __FUNCTION__+":trazerOrdensComComentarioNumerico2valorPresente(",m_symb_str1,",",qtdTicksDeslocamento,")...");
      m_trade1.trazerOrdensComComentarioNumerico2valorPresente(m_symb_str1,qtdTicksDeslocamento);

      //4. aguardando a execucao das ordens de fechamento...
      Sleep(1000); //<TODO> transforme em parametro

      //5. refresh pra saber a situacao atual...
      Print   (":-| ", __FUNCTION__+":refreshMe()..."          );
      refreshMe();

      //6. se ainda estamos posicionados, realiza todos os passos novamente...
      if( m_qtdPosicoes1 > 0 && deep < 2 ){
          Print   (":-| ",__FUNCTION__+":fecharPosicao2(",descr,",",strLog,",",qtdTicksDeslocamento,",",deep,")");
          fecharPosicao2(descr, strLog, qtdTicksDeslocamento,++deep);
      }

      // pra que nao cancele ordens de fechamento de posicao...
      if( m_qtdPosicoes1 > 0 ){
          m_trade1.PositionClose(m_symb_str1);
          Sleep(2000);
      }
      //7. cancelando outras ordens pendentes...
      Print   (":-| ",__FUNCTION__+":cancelarOrdens(",descr,")");
      m_trade1.cancelarOrdens(descr);
}

void fecharPosicao3(string descr, string strLog, int qtdTicksDeslocamento=0, int deep=1){

      Print(":-| ", __FUNCTION__,"(",descr,",",strLog,",",qtdTicksDeslocamento,",",deep,")");

      //<TODO> Este item 1, eh incompativel com novo metodo de fechamento de posicao. Por enquanto
      //       deixo comentado afim de testar. Resova durante ou logo apos os testes.
      //
      //1. providenciando ordens de fechamento que porventura faltem na posicao...
      //Print   (":-| ", __FUNCTION__+":doCloseRajada(",m_passo_rajada,",",m_vol_lote_raj,",",m_qtd_ticks_4_gain_raj,")...");
      //doCloseRajada(m_qtd_ticks_4_gain_ini_1);

      //2. cancelando rajadas que ainda nao entraram na posicao...
      Print   (":-| ", __FUNCTION__+":cancelarOrdensRajada()..."          );
      cancelarOrdensRajada();

      //3. trazendo ordens de fechamento a valor presente...
      Print   (":-| ", __FUNCTION__+":trazerOrdensComComentarioNumerico2valorPresente(",m_symb_str1,",",qtdTicksDeslocamento,")...");
      m_trade1.trazerOrdensComComentarioNumerico2valorPresente(m_symb_str1,qtdTicksDeslocamento);

      //4. aguardando a execucao das ordens de fechamento...
      Sleep(1000); //<TODO> transforme em parametro

      //5. refresh pra saber a situacao atual...
      Print   (":-| ", __FUNCTION__+":refreshMe()..."          );
      refreshMe();

      //6. se ainda estamos posicionados, realiza todos os passos novamente...
      if( m_qtdPosicoes1 > 0 && deep < 5 ){
          Print   (":-| ",__FUNCTION__+":fecharPosicao3(",descr,",",strLog,",",qtdTicksDeslocamento,",",deep,")");
          fecharPosicao3(descr, strLog, qtdTicksDeslocamento,++deep);
      }

      m_trade1.fecharPosicao("F3emergencia");

      // pra que nao cancele ordens de fechamento de posicao...
      if( m_qtdPosicoes1 > 0 ) return;

      //7. cancelando outras ordens pendentes...
      Print   (":-| ",__FUNCTION__+":cancelarOrdens(",descr,")");
      m_trade1.cancelarOrdens(descr);
}

void cancelarOrdensRajada(){
    m_trade1.cancelarOrdensComentadas(m_symb_str1, m_strRajada);
}

uint m_milisec_ontick     = 0;
uint m_milisec_ontick_ant = 0;
bool podeExecutarOnTick(){

    // se nao ha restricao, nao perca tempo...
    if( EA_ONTICK_A_CADA_X_MILIS == 0 ) return true;

    // se chegou aqui eh porque tem restricao...
    m_milisec_ontick = GetTickCount();
    if( m_milisec_ontick < m_milisec_ontick_ant + EA_ONTICK_A_CADA_X_MILIS ) { Print(__FUNCTION__," nao pode executar ontick!");   return false;}
    m_milisec_ontick_ant = m_milisec_ontick;
    return true;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick(){ onTick(); }

void onTick(){

    // verificando restricao de tempo pra executar ontick()...
    if( !podeExecutarOnTick() ) return;
    
    onBookEvent(m_symb_str1);

    //refreshMe();
    // elimina ordens de saida a mais na posicao...
    if( m_estah_no_intervalo_de_negociacao && m_acao_posicao != NAO_OPERAR ){
        //consertarOrdensSaidaPosicao();
        //consertarOrdensEntradaPosicao();
    }
    
    refreshMe();

    if ( m_qtdPosicoes1 > 0 ) {

        // Esta opcao NAO_OPERAR nao interfere nas ordens...
        if( m_acao_posicao == NAO_OPERAR    ){ return; }

        //m_qtdOrdensAnt = 0;

        // estah na hora de fechar as posicoes...
        if( m_eh_hora_de_fechar_posicao ){
            Print(__FUNCTION__, " :-| HORA DE TERMINAR A OPERACAO. FECHANDO TUDO E SAINDO...");
            fecharTudoForcado("HORA_DE_FECHAR_POSICAO");
            ExpertRemove();
        }

        // se controlarRiscoDaPosicao() retornar true, significa que acionou um stop, entao retornamos daqui.
        if( controlarRiscoDaPosicao() ){ return; }

        if( emLeilao() )return;

        // Na estrategia HFT_FORMADOR_DE_MERCADO, a distancia entre as ordens(passo) pode mudar
        // durante o tempo de vida da posicao.
        definirPasso();

        alterarPrecoOrdensSaidaSeNecessario();

        // Na estrategia HFT_FORMADOR_DE_MERCADO, mantemos a fila de ordens de entrada aberta, mesmo
        // durante a vida de uma posicao. Assim pretendemos ganhar prioridade ao chegar no nivel zero do book.
        // gerenciarPosicaoHFTFormadorDeMercado();

    }else{

        m_time_analisado = 0; // pra que as posicoes abertas sejam analisadas no mesmo periodo de uma posicao que jah fechou.

        definirPasso();
        
        // Esta opcao NAO_OPERAR nao interfere nas ordens...
        if( m_acao_posicao == NAO_OPERAR ) return;

        if( m_qtdOrdens > 0 ){
           if( m_acionou_stop_rebaixamento_saldo             ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return;}

           // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
           if( m_acao_posicao == FECHAR_POSICAO          ){ cancelarOrdens("OPCAO_FECHAR_POSICAO"         ); return; }

           // cancela as ordens existentes e nao abre novas ordens se o spread for maior que maximo.
           if( spreadMaiorQueMaximoPermitido()            ){ cancelarOrdens( "SPREAD_ALTO_" + DoubleToString( m_spread,2 ) ); return; }

           // cancelando todas as ordens que nao sejam de abertura de posicao...
           //if( m_qtdOrdensAnt != m_qtdOrdens ){
           //    m_trade1.cancelarOrdensExcetoComTxt(m_apmb,"CANC_NOT_APMB");
           //    m_qtdOrdensAnt = m_qtdOrdens; // para diminuir a quantidade de pedidos de cancelamento repetidos
           //}

           // nao estah no intervalo de negociacao, tem ordens abertas e nao tem posicao aberta, entao cancelamos todas as ordens.
           if( !m_estah_no_intervalo_de_negociacao ){
              Print(m_date_atu.hour,"h ", m_date_atu.min,"min ", m_date_atu.sec,"seg");
              m_trade1.cancelarOrdens("INTERVALO_NEGOCIACAO");
              m_trade2.cancelarOrdens("INTERVALO_NEGOCIACAO");
           }
        }

        // fora do intervalo de negociacao nao abrimos novas ordens...
        // <TODO> Verifique porque esta chamada estah antes da checagem de rebaixamento de saldo. Acho que deveria ficar imediatamente antes das chamadas de abertura de novas posicoes.
        if( !m_estah_no_intervalo_de_negociacao ) return;

        gerenciarRebaixamentoDeSaldoDoDia();

        definirPasso();

        // verificando proibicoes de operar
        if (! podeAbrirProsicao() ) {
            m_trade1.cancelarOrdensExcetoComTxt("STOP","NAO_PODE_ABRIR_POSICAO");
            return;
        }

    }

    executarEstrategia();

}//+------------------------------------------------------------------+
void executarEstrategia(){
    if( !m_estah_no_intervalo_de_negociacao ) return;
    switch(m_acao_posicao){
      //case HFT_OPERAR_VOLUME_CANAL   : abrirPosicaoHFTVolumeCanal       ();                            break;
        case HFT_OPERAR_CANAL_EM_PAR   : abrirPosicaoHFTPairsTradingCanal (); manterFilaOrdensEntrada(); break;
        case HFT_FORMADOR_DE_MERCADO   : abrirPosicaoHFTFormadorDeMercado ();                            break;
        case HFT_ARBITRAGEM_PAR        : abrirPosicaoHFTarbitragemPar     ();                            break;
        case HFT_DESBALANC_BOOK        : gerenciarPosicaoHFTDesbalancBook ();                            break;
        //case HFT_OPERAR_VELOC_VOL_RDF  : abrirPosicaoVelocVolumeRDF       (); manterFilaOrdensEntrada(); break;
        //case HFT_OPERAR_VELOC_VOL_NET  : abrirPosicaoVelocVolumeNET       (); manterFilaOrdensEntrada(); break;
        
      //case HFT_FLUXO_ORDENS          : abrirPosicaoHFTfluxoOrdens       ();                            break;
        case NAO_ABRIR_POSICAO         : naoAbrirPosicao                  ();                            break;
    }
}

void naoAbrirPosicao(){
    manterFilaOrdensEntrada();
}

// mantem fila de ordens de entrada para cada ativo com posicao aberta.
void manterFilaOrdensEntrada(){
    //if (m_qtdPosicoes1 == 0) return;
    
    double vol1 = m_vol_lote_ini1; //m_lots_step1;
    double vol2 = m_vol_lote_ini2; //m_lots_step2;
    
    ulong ticket;
    double precoOrdem = 0;
    
    int lag_rajada1 = m_lag_rajada1;
    int lag_rajada2 = m_lag_rajada2;
    if( EA_LAG_DINAMICO ){
        lag_rajada1 = m_lag_rajada_dinamico1;
        lag_rajada2 = m_lag_rajada_dinamico2;
    }

    // descubra o preco da menor ordem de venda do ativo e mantenha uma rajada de vendas acima desse preco 
    if( estouVendido1() ){
        m_trade1.cancelarOrdensDuplicadas(ORDER_TYPE_SELL_LIMIT);
        m_trade1.cancelarOrdensComVolumeAcimaDe(ORDER_TYPE_SELL_LIMIT,vol1);
        precoOrdem = m_trade1.buscarMenorOrdemLimitadaDeVenda(ticket);
      //if(precoOrdem==0) precoOrdem = normalizar1(m_tick1.ask + m_qtd_ticks_4_gain_ini_1*m_tick_size1);
      //if(precoOrdem==0) precoOrdem = normalizar1(m_tick1.ask +                          m_tick_size1);
        if(precoOrdem==0) precoOrdem = normalizar1(m_tick1.ask + lag_rajada1             *m_tick_size1);
        if(precoOrdem!=0) {sleepTeste(); m_trade1.preencherOrdensLimitadasDeVendaAcimaComLag(precoOrdem,EA_TAMANHO_RAJADA,m_symb_str1,m_apmb_sel,vol1,m_tick_size1,lag_rajada1);}
    }
    if( estouVendido2() ){
        m_trade2.cancelarOrdensDuplicadas(ORDER_TYPE_SELL_LIMIT);
        m_trade2.cancelarOrdensComVolumeAcimaDe(ORDER_TYPE_SELL_LIMIT,vol2);
        precoOrdem = m_trade2.buscarMenorOrdemLimitadaDeVenda(ticket);
      //if(precoOrdem==0) precoOrdem = normalizar2(m_tick2.ask + m_qtd_ticks_4_gain_ini_2*m_tick_size2);
      //if(precoOrdem==0) precoOrdem = normalizar2(m_tick2.ask +                          m_tick_size2);
        if(precoOrdem==0) precoOrdem = normalizar2(m_tick2.ask + m_lag_rajada2           *m_tick_size2);
        if(precoOrdem!=0) {sleepTeste(); m_trade2.preencherOrdensLimitadasDeVendaAcimaComLag(precoOrdem,EA_TAMANHO_RAJADA,m_symb_str2,m_apmb_sel,vol2,m_tick_size2,lag_rajada2);}
    }
   
    // descubra o preco da maior ordem de compra do ativo e mantenha uma rajada de compra abaixo desse preco 
    if( estouComprado1() ){
        m_trade1.cancelarOrdensDuplicadas(ORDER_TYPE_BUY_LIMIT);
        m_trade1.cancelarOrdensComVolumeAcimaDe(ORDER_TYPE_BUY_LIMIT,vol1);
        precoOrdem = m_trade1.buscarMaiorOrdemLimitadaDeCompra(ticket);
      //if(precoOrdem==0) precoOrdem = normalizar1(m_tick1.bid - m_qtd_ticks_4_gain_ini_1*m_tick_size1);
      //if(precoOrdem==0) precoOrdem = normalizar1(m_tick1.bid -                          m_tick_size1);
        if(precoOrdem==0) precoOrdem = normalizar1(m_tick1.bid - lag_rajada1             *m_tick_size1);
        if(precoOrdem!=0) {sleepTeste(); m_trade1.preencherOrdensLimitadasDeCompraAbaixoComLag2(precoOrdem,EA_TAMANHO_RAJADA,m_symb_str1,m_apmb_buy,vol1,m_tick_size1,lag_rajada1);}
    }
    if( estouComprado2() ){
        m_trade2.cancelarOrdensDuplicadas(ORDER_TYPE_BUY_LIMIT);
        m_trade2.cancelarOrdensComVolumeAcimaDe(ORDER_TYPE_BUY_LIMIT,vol2);
        precoOrdem = m_trade2.buscarMaiorOrdemLimitadaDeCompra(ticket);
      //if(precoOrdem==0) precoOrdem = normalizar2(m_tick2.bid - m_qtd_ticks_4_gain_ini_2*m_tick_size2);
      //if(precoOrdem==0) precoOrdem = normalizar2(m_tick2.bid -                          m_tick_size2);
        if(precoOrdem==0) precoOrdem = normalizar2(m_tick2.bid - lag_rajada2             *m_tick_size2);
        if(precoOrdem!=0) {sleepTeste(); m_trade2.preencherOrdensLimitadasDeCompraAbaixoComLag2(precoOrdem,EA_TAMANHO_RAJADA,m_symb_str2,m_apmb_buy,vol2,m_tick_size2,lag_rajada2);}
    }
}

bool podeAbrirProsicao(){

  if( m_aguardar_para_abrir_posicao > 0 ){ print("m_aguardar_para_abrir_posicao",m_aguardar_para_abrir_posicao);return false;} // soh abre novas posicoes apos zerar a penalidade de tempo do dia...
  if( spreadMaiorQueMaximoPermitido()   ){ print("spreadMaiorQueMaximoPermitido"                              );return false;}

  return true; //<TODO> tirar pois eh soh pra teste
}

bool saldoRebaixouMaisQuePermitidoNoDia(){ return ( EA_STOP_REBAIXAMENTO_MAX != 0 && m_trade_estatistica.getRebaixamentoSld () > EA_STOP_REBAIXAMENTO_MAX ); }
bool saldoAtingiuObjetivoDoDia         (){ return ( EA_STOP_OBJETIVO_DIA     != 0 && m_trade_estatistica.getProfitDiaLiquido() > EA_STOP_OBJETIVO_DIA     ); }

/*
void controlarRiscoDaPosicao2(){

   // 1. se preco de entrada da posicao nao mudou, entao nao fazemos nada...
   if(m_precoPosicao==m_precoPosicaoAnt) return;
   m_precoPosicaoAnt = m_precoPosicao;

   // 2. calcule o preco de saida...
   if( estouComprado1() ){
       m_precoSaidaPosicao = normalizar1( m_precoPosicao + m_qtd_ticks_4_gain_ini_1*m_tick_size1 );
       if( m_precoSaidaPosicao < m_precoPosicao){
           m_precoSaidaPosicao = normalizar1(m_precoSaidaPosicao + m_qtd_ticks_4_gain_ini_1*m_tick_size1);
       }
   }else{
       m_precoSaidaPosicao = normalizar1( m_precoPosicao - m_qtd_ticks_4_gain_ini_1*m_tick_size1 );
       if( m_precoSaidaPosicao > m_precoPosicao){
           m_precoSaidaPosicao = normalizar1(m_precoSaidaPosicao - m_qtd_ticks_4_gain_ini_1*m_tick_size1);
       }
   }

   // 3. se o preco de saida eh igual ao anterior, retorne sem fazer nada...
   if(m_precoSaidaPosicao==m_precoSaidaPosicaoAnt) return;
   m_precoSaidaPosicaoAnt = m_precoSaidaPosicao;

   // 4. movendo ordens pendentes numericas para o preco de saida...
   m_trade1.alterarValorDeOrdensNumericasPara(m_symb_str1,m_precoSaidaPosicao, m_precoPosicao);

   return;
}
*/

void definirPrecoSaidaPosicao(){
    if( estouComprado1() ){
        if( m_stop ){
            // testando acionamento do stop no calculo do preco de saida da posicao...
            m_precoSaidaPosicao = m_bid + EA_STOP_TICKS_TOLER_SAIDA;
        }else{
            m_precoSaidaPosicao = normalizar1(m_precoPosicao +  m_qtd_ticks_4_gain_ini_1*m_tick_size1);
        }

    }else{
        if( estouVendido1() ){
            if( m_stop ){
                // testando acionamento do stop no calculo do preco de saida da posicao...
                m_precoSaidaPosicao = m_ask - EA_STOP_TICKS_TOLER_SAIDA;
            }else{
                m_precoSaidaPosicao = normalizar1(m_precoPosicao - m_qtd_ticks_4_gain_ini_1*m_tick_size1);
            }
        }
    }
}

bool stopGainParcialV3(){ return (m_lucroPosicao4Gain != 0 && m_lucroPosicaoParcial >= m_lucroPosicao4Gain); }
bool stopGainParcialV4(){ return false; }
bool stopGainParcialV5(){
    //if( m_lucroPosicao >= m_lucroPosicao4Gain*(2.0/3.0)                              ) m_acionado_trailling_stop=true;
    //if( m_lucroPosicao <= m_lucroPosicao4Gain*(1.0/2.0) && m_lucroPosicao>=0 && m_acionado_trailling_stop ) return true;
    if( m_lucroPosicao >  m_lucroPosicao4Gain ) return true;

    if( EA_STOP_PARCIAL_ATIVAR                                   &&
      //m_tempo_posicao_atu > EA_STOP_PARCIAL_FIRE_TEMPO_POSICAO &&
        m_posicaoVolumeTot >= EA_STOP_PARCIAL_FIRE_VOLUME_TOT    &&
        m_lucroPosicao      >= m_lucroPosicao4Gain*(EA_STOP_PARCIAL_FIRE_PORC_LUCRO_POSICAO) ){
        return true;
    }

    return false;
}
bool stopGainParcialSimples(){

    if( EA_STOP_PARCIAL_ATIVAR                                   &&
        //m_tempo_posicao_atu > EA_STOP_PARCIAL_FIRE_TEMPO_POSICAO &&
        m_posicaoVolumeTot >= EA_STOP_PARCIAL_FIRE_VOLUME_TOT    &&
        m_lucroPosicao >= m_lucroPosicao4Gain*(EA_STOP_PARCIAL_FIRE_PORC_LUCRO_POSICAO) ){
        return true;
    }

    return false;
}

bool m_acionado_trailling_stop = false;

bool controlarRiscoDaPosicao(){

     // prevenindo varias execucoes antes que as ordens de fechamento sejam executadas...
     //if( m_stop == true ) return true;

     //if( saldoRebaixouMaisQuePermitidoNoDia() ){ fecharTudo("STOP_REBAIXAMENTO_DE_CAPITAL"); return true;}

     // Esta opcao FECHAR_POSICAO fecha todas as posicoes e ordens...
     if( m_acao_posicao == FECHAR_POSICAO                                 ) { fecharTudo("STOP_FECHAR_POSICAO"         ,"STOP_FECHAR_POSICAO"         ); return true; }
     if( m_acao_posicao == FECHAR_POSICAO_POSITIVA && m_posicaoProfit > 0 ) { fecharTudo("STOP_FECHAR_POSICAO_POSITIVA","STOP_FECHAR_POSICAO_POSITIVA"); return true; }

     if( stopGainParcial() ){
         fecharTudo("STOP_GAIN_PARCIAL_" + DoubleToString(m_lucroPosicao,2)+ "_" + DoubleToString(m_lucroPosicaoParcial,2));
         return true;
     }

     //if( m_lucroPosicao4Gain != 0 && m_lucroPosicao > m_lucroPosicao4Gain && m_capitalInicial != 0 ){
     //    fecharTudo("STOP_GAIN_" + DoubleToString(m_lucroPosicao,2)+ "_" + DoubleToString(m_lucroPosicaoParcial,2));
     //    return true;
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
     if( m_posicaoLotsPend  > EA_STOP_QTD_CONTRATOS_PENDENTES && EA_STOP_QTD_CONTRATOS_PENDENTES > 0 ){
         //Print(":-( ",__FUNCTION__," Acionando STOP_LOSS_QTD_CONTRATOS_"+ DoubleToString(m_lucroPosicao,0)," VOL=",m_posicaoLotsPend," ", strPosicao() );
         m_lucroStops += m_lucroPosicao;
         fecharTudo("STOP_QTD_CONTRATOS_"+ DoubleToString(m_lucroPosicao,0));
         return true;
     }

     // fecha a posicao ativa se houve mudanca de direcao na posicao cusum...
     //if( fecharPosicaoHFTCusum() ){
     //    m_lucroStops += m_lucroPosicao;
     //    fecharTudo("STOP_CUSUM_"+ DoubleToString(m_lucroPosicao,0));
     //    return true;
     //}//else{
         // testando cancelamento do fechamento da posicao.
         // nos casos em que nao consegue fechar, se estiver em situacao favoravel, mantem a posicao
         //m_stop = false;
     //}

     // fecha a posicao lucrativa se (estah comprado e preco de saida(bid) estah abaixo da media) ou
     //                           se (estah vendido  e preco de saida(ask) estah acima  da media)

//     if( m_lucroPosicao > (m_lucroPosicao4Gain/1.5) && m_lucroPosicao4Gain != 0 ){
//         //if( ( estouComprado1() && m_bid < m_est.getPrecoMedTrade() ) ||
//         //    ( estouVendido1 () && m_ask > m_est.getPrecoMedTrade() )
//         // ){
//             m_lucroStops += m_lucroPosicao;
//             fecharTudo("STOP_CUSUM2_"+ DoubleToString(m_lucroPosicao,0));
//             return true;
//         //}
//     }

     return false;
}

string strPosicao(){
   return " Contr="       + DoubleToString (m_posicaoLotsPend  ,0)+ "/"+
                            DoubleToString (m_posicaoVolumeTot ,0)+
          " SPRE= "       + DoubleToString (m_symb1.Spread()    ,2)+
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


//------------------------------------------------------------------------------------------------------------
// Faz: recebe um valor de ordem executa e dispara uma ordem na direcao oposta a ordem executada. Ou seja, se 
//      a ordem executada (typeDeal) foi uma compra, dispara uma venda e vice-versa.
//------------------------------------------------------------------------------------------------------------
void doCloseOposite( double toClosePriceIn, double vol, string symbol, ENUM_DEAL_TYPE typeDeal ){
    Print(__FUNCTION__,"(",toClosePriceIn,",",vol,",",symbol,",", EnumToString(typeDeal),")", ",tg4=",m_qtd_ticks_4_gain_ini_1 );

    if(m_stop) return;
    
    if( EA_NEGOCIAR_ATIVO_1 ){
        double t4g = m_qtd_ticks_4_gain_ini_1;
      //if( t4g < m_lag_rajada_dinamico1/2) t4g = m_lag_rajada_dinamico1/2;
        if( symbol==m_symb_str1 ){ m_gerentePos1.doCloseOposite(toClosePriceIn, t4g, vol, m_tick1,SLEEP_TESTE, typeDeal); return; }
    }
    
    if( EA_NEGOCIAR_ATIVO_2 ){
        double t4g = m_qtd_ticks_4_gain_ini_2;
      //if(t4g<m_lag_rajada_dinamico2/2) t4g = m_lag_rajada_dinamico2/2;
        if( symbol==m_symb_str2 ){ m_gerentePos2.doCloseOposite(toClosePriceIn, t4g, vol, m_tick2,SLEEP_TESTE, typeDeal); return; }
    }

}

//------------------------------------------------------------------------------------------------------------
// Faz: recebe um valor de ordem executa e dispara uma ordem de venda acima e outra de compra abaixo.
//------------------------------------------------------------------------------------------------------------
void doCloseRajada4Simples( double toClosePriceIn, double vol, string symbol ){
  //Print(__FUNCTION__,"(",toClosePriceIn,",",vol,",",symbol,")" );

    if(m_stop) return;

    // saida na media do book
    // lag rajada eh em ticks... mantemos um soh para os dois ativos...
    //if( m_est.getPrecoMedBookAsk() > m_est.getPrecoMedBookBid() ){
    //    m_lag_rajada1 = (int)(  ( ( m_est.getPrecoMedBookAsk() - m_est.getPrecoMedBookBid() )/2.0 )/m_tick_size1  );
    //}


    if( symbol==m_symb_str1 ){
        int pos_type = 0;
        if( estouPosicionado1() ){
            if( estouComprado1() ){ pos_type  = +1;
            }else{
                if( estouVendido1() ){pos_type = -1;}
            }
        }
        doCloseRajada4Simples(toClosePriceIn,vol,m_gerentePos1, m_tick1, getTicksAddPorSelecaoAdversa1(),pos_type, m_qtd_ticks_4_gain_ini_1);
        return;
    }

    if( symbol==m_symb_str2 ){
        int pos_type = 0;
        if( estouPosicionado2() ){
            if( estouComprado2() ){ pos_type = +1;
            }else{
                if( estouVendido2() ){ pos_type = -1; }
            }
        }

        doCloseRajada4Simples(toClosePriceIn,vol,m_gerentePos2, m_tick2, getTicksAddPorSelecaoAdversa2(), pos_type,m_qtd_ticks_4_gain_ini_2);
        return;
    }
}

void doCloseRajada4Simples( double toClosePriceIn, double vol, C004GerentePosicao& gerentePos, MqlTick& tick, double ticksAdd, int pos_type, double t4g ){

  //Print(__FUNCTION__,"(",toClosePriceIn,",",vol,",","m_gerentePos2",",","m_tick2",",",getTicksAddPorSelecaoAdversa2(),",",pos_type,",",t4g,")" );

//  if( estouSemPosicao1() ){
      //sleepTeste(); gerentePos.fireNorteSulRajada( toClosePriceIn, vol,                               (int)(t4g         +ticksAdd),tick, SLEEP_TESTE,pos_type );
      //sleepTeste(); gerentePos.fireNorteSulRajada( toClosePriceIn, vol,                               (int)(m_lag_rajada1+ticksAdd),tick, SLEEP_TESTE,pos_type );
        sleepTeste(); gerentePos.fireNorteSulRajada( toClosePriceIn, vol, (int)(t4g         +ticksAdd), (int)(m_lag_rajada1+ticksAdd),tick, SLEEP_TESTE,pos_type );
        return;
//  }

//  if( estouComprado1() ){
//      sleepTeste(); gerentePos.fireNorteSul( toClosePriceIn,m_lag_rajada1+ticksAdd, tick,SLEEP_TESTE, pos_type );
//      return;
//  }
//
//  if( estouVendido1() ){
//      sleepTeste(); gerentePos.fireNorteSul( toClosePriceIn,m_lag_rajada1+ticksAdd, tick,SLEEP_TESTE, pos_type );
//      return;
//  }

//  return;
}


int qtdLotesStopParcial(){
    if( EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES  > 0 ) return (int)(1 + m_posicaoLotsPend/EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES);
    return (int)m_vol_lote_ini1;
}

bool lotesNaPosicaoHabilitamStopParcial(){
    return ( EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES > 0 && EA_STOP_PARCIAL_A_PARTIR_DE_X_LOTES < m_posicaoLotsPend );
}

bool lucroNaPosicaoHabilitaStopParcial(){
    return ( EA_STOP_PARCIAL_A_PARTIR_DE_X_GANHO > 0 && EA_STOP_PARCIAL_A_PARTIR_DE_X_GANHO < m_lucroPosicao    );
}

string getStrComment(){

  if( m_acao_posicao == HFT_ARBITRAGEM_PAR ){
      return
      " a" +DoubleToString (m_par.getSpread()*10        ,0) + // ratio instantaneo entre o par de ativo
      " b" +DoubleToString (m_est.getVolTradeLiqPorSeg(),0) + // Velocidade do volume por segundo.
      " c" +DoubleToString (m_est.getAceVolLiq()        ,0) + // Aceleracao da velocidade do volume por segundo ao quadrado.
      " d" +DoubleToString (m_est.getKyleLambda()       *10000000,0) + // risco de compra (Buy).
      " e" +DoubleToString (m_est.getKyleLambdaHLTrade()*10000000,0) ; // risco de venda  (Sell).
  }

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



bool sleepTeste(){

    if(SLEEP_TESTE>0){
        long mili = GetTickCount();
        Sleep(SLEEP_TESTE);
        mili = GetTickCount() - mili;
        //if( mili < SLEEP_TESTE ) print("SLEEP_REAL menor que parametro",mili);
                               //Print("SLEEP_REAL:",mili, " m_stop:",m_stop);
        return true;
    }
    return false;
}

bool bidAskEstaoIntegros(){
    if( m_ask == 0.0 || m_bid == 0.0 ){
        Print(__FUNCTION__," Erro :m_ask=",m_ask, " m_bid=",m_bid );
        return false;
    }
    if( m_ask < m_bid ){
        Print(__FUNCTION__," Erro :m_ask=",m_ask, " m_bid=",m_bid );
        return false;
    }
    return true;
}

bool bidAskEstaoIntegros(const double bid, const double ask){
    if( ask == 0.0 || bid == 0.0 ){
        Print(__FUNCTION__," Erro :ask=",ask, " bid=",bid );
        return false;
    }
    if( ask < bid ){
        Print(__FUNCTION__," Erro :ask=",ask, " bid=",bid );
        return false;
    }
    return true;
}

bool fecharPosicaoHFTCusumSimples(){

    //return false;
    if( !EA_DECISAO_ENTRADA_COMPRA_VENDA_AUTOMATICA ) return false;
    if( !EA_STOP_CUSUM                              ) return false;

    if( estouVendido1() ) {
        if ( cusumOrientaFecharPosicaoVendida() ) return true;
    }else{
        if( estouComprado1() ){
            if( cusumOrientaFecharPosicaoComprada()  ) return true;
        }
    }
    return false;
}


//void abrirPosicaoHFTFormadorDeMercado    (){     abrirPosicaoHFTFormadorDeMercadoCusumV3();}
//void gerenciarPosicaoHFTFormadorDeMercado(){ gerenciarPosicaoHFTFormadorDeMercadoCusumV4();}
//void abrirPosicaoHFTFormadorDeMercado    (){     abrirPosicaoHFTFormadorDeMercadoSimplesNaMediaDoTrade();}
//void abrirPosicaoHFTFormadorDeMercado    (){     abrirPosicaoHFTFormadorDeMercadoSimplesNaMediaDoBook();}
  void abrirPosicaoHFTFormadorDeMercado    (){     abrirPosicaoHFTFormadorDeMercadoSinaisDoBook();}
  
//void gerenciarPosicaoHFTFormadorDeMercado(){     abrirPosicaoHFTFormadorDeMercadoV5     ();}
bool fecharPosicaoHFTCusum               (){ return fecharPosicaoHFTCusumSimples          ();}
bool stopGainParcial                     (){ return stopGainParcialSimples                ();}
bool cusumOrientaCompra                  (){ return cusumOrientaCompraSimples             ();}
bool cusumOrientaVenda                   (){ return cusumOrientaVendaSimples              ();}
bool cusumOrientaFecharPosicaoVendida    (){ return cusumOrientaFecharPosicaoVendidaSimples ();}
bool cusumOrientaFecharPosicaoComprada   (){ return cusumOrientaFecharPosicaoCompradaSimples();}
//void doCloseRajada4(ulong toCloseidDeal, double toCloseVol, ENUM_DEAL_TYPE sentidoRajada, double toClosePriceIn, bool toCloseOpenPos){
//     doCloseRajada4Simples( toClosePriceIn );
     //doCloseRajada4V5(toCloseidDeal, toCloseVol, sentidoRajada, toClosePriceIn,toCloseOpenPos);
//}

bool cusumOrientaCompraV3(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos);}
bool cusumOrientaVendaV3 (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais );}

bool cusumOrientaCompraV4(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos);}
bool cusumOrientaVendaV4 (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais );}

//versao 1
//bool cusumOrientaCompraV5(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos && m_est.getInclinacaoTrade() >  0.02) && m_bid < m_est.getPrecoMedBookAsk();}
//bool cusumOrientaVendaV5 (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais  && m_est.getInclinacaoTrade() < -0.02) && m_ask > m_est.getPrecoMedBookBid();}

// versao 2 com inclinacao e preco medio do trade
//bool cusumOrientaCompraV5(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos && m_est.getInclinacaoTrade() >  EA_INCL_MIN) /*&& m_bid <= m_est.getPrecoMedTrade()*/ && m_est.getPrecoMedTrade() > m_est.getPrecoMedTradeSel() && m_est.getPrecoMedTrade() > m_est.getPrecoMedTradeBuy(); }
//bool cusumOrientaVendaV5 (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais  && m_est.getInclinacaoTrade() < -EA_INCL_MIN) /*&& m_ask >= m_est.getPrecoMedTrade()*/ && m_est.getPrecoMedTrade() < m_est.getPrecoMedTradeSel() && m_est.getPrecoMedTrade() < m_est.getPrecoMedTradeBuy(); }

// versao 3 com inclinacao da regressao linear
//bool cusumOrientaCompraV5(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos && m_b1 >  EA_INCL_MIN) && m_r2 > 0.7; }
//bool cusumOrientaVendaV5 (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais  && m_b1 < -EA_INCL_MIN) && m_r2 > 0.7; }

//bool cusumOrientaCompraV5(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos && m_b1 >  EA_INCL_MIN) && m_r2 > 0.7 /*&& m_bid <= m_est.getPrecoMedTrade()*/ && m_est.getPrecoMedTrade() > m_est.getPrecoMedTradeSel() && m_est.getPrecoMedTrade() > m_est.getPrecoMedTradeBuy(); }
//bool cusumOrientaVendaV5 (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais  && m_b1 < -EA_INCL_MIN) && m_r2 > 0.7 /*&& m_ask >= m_est.getPrecoMedTrade()*/ && m_est.getPrecoMedTrade() < m_est.getPrecoMedTradeSel() && m_est.getPrecoMedTrade() < m_est.getPrecoMedTradeBuy(); }

// versao 4 com estimativa da regressao linear
//bool cusumOrientaCompraV5(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos) && m_precoEstim >  1 && m_b1 > 0 && m_r2 > 0.5; }
//bool cusumOrientaVendaV5 (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais ) && m_precoEstim < -1 && m_b1 < 0 && m_r2 > 0.5; }

// versao 5 com estimativa da regressao linear
//bool cusumOrientaCompraV5(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos) && m_est.getInclinacaoTrade() >  EA_INCL_MIN && m_precoEstim >  EA_DELTA_PRECO_MIN_ENTRADA_POS && m_r2 > EA_R2_MIN_ENTRADA_POS; }
//bool cusumOrientaVendaV5 (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais ) && m_est.getInclinacaoTrade() < -EA_INCL_MIN && m_precoEstim < -EA_DELTA_PRECO_MIN_ENTRADA_POS && m_r2 > EA_R2_MIN_ENTRADA_POS; }

// versao 6 com estimativa da regressao linear
//bool cusumOrientaCompraV5(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos) && m_est.getInclinacaoTrade() >  EA_INCL_MIN && m_r2 > EA_R2_MIN_ENTRADA_POS && !cusumOrientaFecharPosicaoCompradaV5(); }
//bool cusumOrientaVendaV5 (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais ) && m_est.getInclinacaoTrade() < -EA_INCL_MIN && m_r2 > EA_R2_MIN_ENTRADA_POS && !cusumOrientaFecharPosicaoVendidaV5 (); }

bool cusumOrientaCompraSimples(){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos); }
bool cusumOrientaVendaSimples (){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais ); }

bool cusumOrientaFecharPosicaoVendidaV3 (){ return (m_strikeCMais  && !m_strikeCMenos);}
bool cusumOrientaFecharPosicaoCompradaV3(){ return (m_strikeCMenos && !m_strikeCMais );}

bool cusumOrientaFecharPosicaoVendidaV4 (){ return (m_strikeCMais  || !m_strikeCMenos);}
bool cusumOrientaFecharPosicaoCompradaV4(){ return (m_strikeCMenos || !m_strikeCMais );}

//bool cusumOrientaFecharPosicaoVendidaV5 (){ return (m_strikeCMais  || !m_strikeCMenos);}
//bool cusumOrientaFecharPosicaoCompradaV5(){ return (m_strikeCMenos || !m_strikeCMais );}
//bool cusumOrientaFecharPosicaoVendidaV5 (){ return cusumOrientaCompraV5();}
//bool cusumOrientaFecharPosicaoCompradaV5(){ return cusumOrientaVendaV5 ();}

//bool cusumOrientaFecharPosicaoVendidaV5 (){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos && m_est.getInclinacaoTrade() >  EA_INCL_MIN/2.0) && m_est.getPrecoMedTrade() > m_est.getPrecoMedTradeSel() && m_est.getPrecoMedTrade() > m_est.getPrecoMedTradeBuy();}
//bool cusumOrientaFecharPosicaoCompradaV5(){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais  && m_est.getInclinacaoTrade() < -EA_INCL_MIN/2.0) && m_est.getPrecoMedTrade() < m_est.getPrecoMedTradeSel() && m_est.getPrecoMedTrade() < m_est.getPrecoMedTradeBuy();}

//bool cusumOrientaFecharPosicaoVendidaV5 (){ return (m_strikeCMais  && m_strikeHmais  && !m_strikeCMenos && m_b1 >  EA_INCL_MIN);}
//bool cusumOrientaFecharPosicaoCompradaV5(){ return (m_strikeCMenos && m_strikeHmenos && !m_strikeCMais  && m_b1 < -EA_INCL_MIN);}

//bool cusumOrientaFecharPosicaoVendidaV5 (){ return (                                                       m_b1 >  EA_INCL_MIN + 0.001);}
//bool cusumOrientaFecharPosicaoCompradaV5(){ return (                                                       m_b1 < -EA_INCL_MIN - 0.001);}

//versao 4 (com inclinacao)
//bool cusumOrientaFecharPosicaoVendidaV5 (){ return ( m_precoEstim >  2 && m_b1 > 0);}
//bool cusumOrientaFecharPosicaoCompradaV5(){ return ( m_precoEstim < -2 && m_b1 < 0);}

//versao 5 (sem inclinacao)
//bool cusumOrientaFecharPosicaoVendidaV5 (){ return ( (m_precoEstim >  EA_DELTA_PRECO_MIN_SAIDA_POS && m_r2 > EA_R2_MIN_ENTRADA_POS) || m_strikeCMais  || !m_strikeCMenos );}
//bool cusumOrientaFecharPosicaoCompradaV5(){ return ( (m_precoEstim < -EA_DELTA_PRECO_MIN_SAIDA_POS && m_r2 > EA_R2_MIN_ENTRADA_POS) || m_strikeCMenos || !m_strikeCMais  );}
//bool cusumOrientaFecharPosicaoVendidaV5 (){ return ( (m_precoEstim >  EA_DELTA_PRECO_MIN_SAIDA_POS && m_r2 > EA_R2_MIN_ENTRADA_POS) || (m_strikeCMais   && m_est.getInclinacaoTrade() >  EA_INCL_MIN/2.0) );}
//bool cusumOrientaFecharPosicaoCompradaV5(){ return ( (m_precoEstim < -EA_DELTA_PRECO_MIN_SAIDA_POS && m_r2 > EA_R2_MIN_ENTRADA_POS) || (m_strikeCMenos  && m_est.getInclinacaoTrade() < -EA_INCL_MIN/2.0) );}

//  bool cusumOrientaFecharPosicaoVendidaSimples (){ return false;}
//  bool cusumOrientaFecharPosicaoCompradaSimples(){ return false;}
  bool cusumOrientaFecharPosicaoVendidaSimples (){ return cusumOrientaCompraSimples() && m_est.getInclinacaoTrade() >  EA_INCL_MIN;}
  bool cusumOrientaFecharPosicaoCompradaSimples(){ return cusumOrientaVendaSimples()  && m_est.getInclinacaoTrade() < -EA_INCL_MIN;}

void cancelarOrdensComComentarioNumerico()                    {             m_trade1.cancelarOrdensComComentarioNumerico(m_symb_str1     );}
void cancelarOrdensComComentarioNumerico(ENUM_ORDER_TYPE type){             m_trade1.cancelarOrdensComComentarioNumerico(m_symb_str1,type);}
void cancelarOrdensComentadas(string comm)                    {             m_trade1.cancelarOrdensComentadas           (m_symb_str1,comm);}
void cancelarOrdens          (ENUM_ORDER_TYPE tipo)           {             m_trade1.cancelarOrdens                     (tipo           );}

void cancelarOrdensDeCompraAbaixoDe(double price){m_trade1.cancelarOrdensDeCompraMenoresQue(price);}
void cancelarOrdensDeVendaAcimaDe  (double price){m_trade1.cancelarOrdensDeVendaMaioresQue (price);}

void cancelarOrdensDeCompraDuplicadas(){m_trade1.cancelarOrdensDuplicadas(ORDER_TYPE_BUY_LIMIT );}
void cancelarOrdensDeVendaDuplicadas (){m_trade1.cancelarOrdensDuplicadas(ORDER_TYPE_SELL_LIMIT);}

// para cada posicao aberta, verifica se tem mais ordens ou menos ordens de saida do que o volume na posicao...
void consertarOrdensEntradaPosicao(){

    // verificando a posicao 1...
    if( estouPosicionado1() ){

        // comprado na posicao 1...
        if(estouComprado1()){
            int volIn = m_trade1.contarOrdensLimitadasDeCompra(m_symb_str1,m_apmb);
            if(volIn>1){
                //Print(__FUNCTION__,":VRIFPOS1IN:COMPRADO:VOLIN:",volIn,":acionando:","m_trade1.cancelarMenorOrdemDoTipo(ORDER_TYPE_BUY_LIMIT)...");
                m_trade1.cancelarMenorOrdemDoTipo(ORDER_TYPE_BUY_LIMIT);
            }

        // vendido na posicao 1....
        }else{
            int volIn = m_trade1.contarOrdensLimitadasDeVenda(m_symb_str1,m_apmb);
            if(volIn>1){
                //Print(__FUNCTION__,":VRIFPOS1IN:VENDIDO:VOLIN:",volIn,":acionando m_trade1.cancelarMaiorOrdemDoTipo(ORDER_TYPE_SEL_LIMIT)...");
                m_trade1.cancelarMaiorOrdemDoTipo(ORDER_TYPE_SELL_LIMIT);
            }
        }

    }

    // verificando a posicao 2...
    if( estouPosicionado2() ){


        // comprado na posicao 2...
        if(estouComprado2()){
            int volIn = m_trade2.contarOrdensLimitadasDeCompra(m_symb_str2,m_apmb);
            if(volIn>1){
                //Print(__FUNCTION__,":VRIFPOS2IN:COMPRADO:VOLIN:",volIn,":acionando:","m_trade2.cancelarMenorOrdemDoTipo(ORDER_TYPE_BUY_LIMIT)...");
                m_trade2.cancelarMenorOrdemDoTipo(ORDER_TYPE_BUY_LIMIT);
            }

        // vendido na posicao 2....
        }else{
            int volIn = m_trade2.contarOrdensLimitadasDeVenda(m_symb_str2,m_apmb);
            if(volIn>1){
                //Print(__FUNCTION__,":VRIFPOS2IN:VENDIDO:VOLIN:",volIn,":acionando:","m_trade2.cancelarMaiorOrdemDoTipo(ORDER_TYPE_SELL_LIMIT)...");
                m_trade2.cancelarMaiorOrdemDoTipo(ORDER_TYPE_SELL_LIMIT);
            }
        }
    }

}


void consertarOrdensSaidaPosicao(){
    eliminarOrdensDeSaidaSobrantes();
    trazerOrdensAfastadasParaProximoDoBreakEven();
}

// Traz ordens de saida a mais de 2 TICKTS_4_GAIN do breakeven, para TICKTS_4_GAIN+1 do breakeven.
// Se jah houver ordem de saida no novo psicionamento, vai afastando 1 ticket de forma que as ordens fiquem
// conforme a sequencia abaixo:
//
// EXEMPLO BREAKEVEN DA VENDA NO 1000 COM 3 TICKETS_4_GAIN E 4 ORDENS DE SAIDA. CADA TICKET VALENDO 05 UNIDADES.
//
//  1000 4 VENDAS (BREAKEVEN)
//   995
//   990
//   985 1 COMPRA
//   980 1 COMPRA
//   975 1 COMPRA
//   970 1 COMPRA daqui ateh o breakeven, eh a regiao de aproximacao.
//   965 a partir daqui eh a regiao de afastamento.
//
void trazerOrdensAfastadasParaProximoDoBreakEven(){
    m_gerentePos1.trazerOrdensAfastadasParaProximoDoBreakEven(m_qtd_ticks_4_gain_ini_1);
    m_gerentePos2.trazerOrdensAfastadasParaProximoDoBreakEven(m_qtd_ticks_4_gain_ini_2);
    //1. obtenha o valor do breakeven
    //double break_even_p1 = m_posicao1.PriceCurrent();
    //2. obtenha o valor de t4g e calcule qual deve ser a posicao da ordem de saida mais próxima do breakeven
    //3. obtenha a quantidade de ordens de saida pendentes e calcule qual deve ser a posicao da ordem mais afastada do breakeven
    //4. As duas posicoes acima delimitam a regiao de aproximacao. Depois dela, eh a regiao de afastamento.
    //5. faca um loop sobre as ordens de saida.
    //5.1 para cada ordem na regiao de afastamento, coloque-a em uma posicao livre na regiao de aproximacao
}

// para cada posicao aberta, verifica se tem mais ordens ou menos ordens de saida do que o volume na posicao...
void eliminarOrdensDeSaidaSobrantes(){

    // verificando a posicao 1...
    if( estouPosicionado1() ){
        int volPos = (int)m_posicaoLotsPend;

        // comprado na posicao 1...
        if(estouComprado1()){
            int volOut = m_trade1.contarOrdensLimitadasDeVenda(m_symb_str1,m_apmb);
            if(volOut>volPos){
                //Print(__FUNCTION__,":VRIFPOS1:COMPRADO:VOLOUT:",volOut,":VOLPOS:",volPos,":acionando:","m_trade1.cancelarMaiorOrdemDoTipo(ORDER_TYPE_SELL_LIMIT)...");
                m_trade1.cancelarMaiorOrdemDoTipo(ORDER_TYPE_SELL_LIMIT);
            }

        // vendido na posicao 1....
        }else{
            int volOut = m_trade1.contarOrdensLimitadasDeCompra(m_symb_str1,m_apmb);
            if(volOut>volPos){
                //Print(__FUNCTION__,":VRIFPOS1:VENDIDO:VOLOUT:",volOut,":VOLPOS:",volPos,":acionando m_trade1.cancelarMenorOrdemDoTipo(ORDER_TYPE_BUY_LIMIT)...");
                m_trade1.cancelarMenorOrdemDoTipo(ORDER_TYPE_BUY_LIMIT);
            }
        }
    }

    // verificando a posicao 2...
    if( estouPosicionado2() ){
        calcVolPosicao2();
        int volPos = (int)m_posicaoLotsPend2;

        // comprado na posicao 2...
        if(estouComprado2()){
            int volOut = m_trade2.contarOrdensLimitadasDeVenda(m_symb_str2,m_apmb);
            if(volOut>volPos){
                //Print(__FUNCTION__,":VRIFPOS2:COMPRADO:VOLOUT:",volOut,":VOLPOS:",volPos,":acionando:","m_trade2.cancelarMaiorOrdemDoTipo(ORDER_TYPE_SELL_LIMIT)...");
                m_trade2.cancelarMaiorOrdemDoTipo(ORDER_TYPE_SELL_LIMIT);
            }

        // vendido na posicao 2....
        }else{
            int volOut = m_trade2.contarOrdensLimitadasDeCompra(m_symb_str2,m_apmb);
            if(volOut>volPos){
                //Print(__FUNCTION__,":VRIFPOS2:VENDIDO:VOLOUT:",volOut,":VOLPOS:",volPos,":acionando:","m_trade2.cancelarMenorOrdemDoTipo(ORDER_TYPE_BUY_LIMIT)...");
                m_trade2.cancelarMenorOrdemDoTipo(ORDER_TYPE_BUY_LIMIT);
            }
        }
    }

}

double m_posicaoVolumePend2 = 0;
double m_posicaoLotsPend2   = 0;
double calcVolPosicao2(){
    if( estouPosicionado2() ){
        m_posicaoVolumePend2 = PositionGetDouble(POSITION_VOLUME);
        m_posicaoLotsPend2   = m_posicaoVolumePend2/m_lots_step2;
        return m_posicaoLotsPend2;
    }
    m_posicaoVolumePend2 = 0;
    m_posicaoLotsPend2   = 0;
    return 0;
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
double m_precoOrdem1  = 0.0;
void abrirPosicaoHFTVolumeCanal(){

    if( m_ask==0.0 || m_bid==0.0 ){
        Print(__FUNCTION__," Erro abertura posicao: m_ask=",m_ask, " m_bid=",m_bid );

        // se tinha ordem pendente, cancela
        m_trade1.cancelarOrdensComentadas(m_symb_str1,m_apmb     );
        m_trade1.cancelarOrdensComentadas(m_symb_str1,m_strRajada);

        m_aguardar_para_abrir_posicao = EA_EST_QTD_SEGUNDOS*1000; // aguarda ateh poder abrir nova posicao
        return;
    }

    // tendencia de alta...
    if( m_est.getVolTradeLiqPorSeg() > 0    &&
        m_est.getAceVolLiq()         > 0    &&
        m_est.getInclinacaoHLTrade() > 0    && m_canal1.regiaoSuperior()  ){
  //if( m_canal1.regiaoSuperior()                                         ){
  //if( m_canal1.regiaoSuperior() && m_riscoCompra < EA_RISCO_MAX_POSICAO ){
  //if(                             m_riscoCompra < EA_MAIOR_RISCO_ENTRADA ){

        // providenciando a ordem de entrada na posicao...
        m_precoOrdem1 = m_bid;

        if( !m_trade1.tenhoOrdemLimitadaDeCompra( m_precoOrdem1, m_symb_str1, m_apmb, m_vol_lote_ini1 , true, m_shift_in_points, m_apmb_buy+getStrComment() ) ){
            if(m_precoOrdem1!=0) m_trade1.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_apmb_buy+getStrComment() );
        }

        // cancelando ordens de venda porventura colocadas...
        if( ! m_trade1.cancelarOrdensComentadasDeVenda(m_symb_str1 ,m_apmb     ) ) return; // se teve algum problema cancelando ordens, nao segue criando outras
        if( ! m_trade1.cancelarOrdensComentadasDeVenda(m_symb_str1 ,m_strRajada) ) return; // se teve algum problema cancelando ordens, nao segue criando outras

        return;
    }else{

        // tendencia de baixa...
        if( m_est.getVolTradeLiqPorSeg() < 0   &&
            m_est.getAceVolLiq()         < 0   &&
            m_est.getInclinacaoHLTrade() < 0   && m_canal1.regiaoInferior()  ){
      //if( m_canal1.regiaoInferior()                                        ){
      //if( m_canal1.regiaoInferior() && m_riscoVenda < EA_RISCO_MAX_POSICAO ){
      //if(                             m_riscoVenda < EA_MAIOR_RISCO_ENTRADA ){

            // providenciando a ordem de entrada na posicao...
            m_precoOrdem1 = m_ask;

            if( !m_trade1.tenhoOrdemLimitadaDeVenda( m_precoOrdem1, m_symb_str1, m_apmb, m_vol_lote_ini1 , true, m_shift_in_points, m_apmb_sel+getStrComment() ) ){
                if(m_precoOrdem1!=0) m_trade1.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_apmb_sel+getStrComment() );
            }

            // cancelando ordens de compra porventura colocadas...
            if( ! m_trade1.cancelarOrdensComentadasDeCompra(m_symb_str1, m_apmb     ) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras
            if( ! m_trade1.cancelarOrdensComentadasDeCompra(m_symb_str1, m_strRajada) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras

            return;
        }
    }
    // se chegou aqui eh porque nao ha condicao para abrir posicao. Entao cancela pedidos de entrada pendentes.
    m_trade1.cancelarOrdensComentadas(m_symb_str1,m_apmb     );
    m_trade1.cancelarOrdensComentadas(m_symb_str1,m_strRajada);
}
//-----------------------------------------------------------------------------------------------------------------------------



// Abre posicao se houver desbalanceamento de ofertas nas primeiras filas do book...
// Esta opcao nao se importa se a volatilidade estiver alta
// HFT_DESBALANC_BOOK
void gerenciarPosicaoHFTDesbalancBook(){
   if(EA_NEGOCIAR_ATIVO_1) m_C0601_1.gerenciarPosicao();
   if(EA_NEGOCIAR_ATIVO_2) m_C0601_2.gerenciarPosicao();

   //gerenciarPosicaoHFTDesbalancBook(m_symb_str1,m_book1,m_tick1,m_gerentePos1,m_trade1);
   //gerenciarPosicaoHFTDesbalancBook(m_symb_str2,m_book2,m_tick2,m_gerentePos2,m_trade2);
}

/*
// Abre posicao se houver desbalanceamento de ofertas nas primeiras filas do book...
// Esta opcao nao se importa se a volatilidade estiver alta
// HFT_DESBALANC_BOOK
void gerenciarPosicaoHFTDesbalancBook(string& symb_str, osc_book& book, MqlTick& tick, C004GerentePosicao& gerPos, osc_minion_trade& trade){

    if( gerPos.positioned() ){
        //1. se tiver ordens de saida no lado espesso do book, feche a posicao...

        // aqui, as ordens de saida estao no lado ralo do book, entao saio pra respeitar
        // as ordens de saida colocadas pelo firenortesul (que estao no lado ralo do book)
        if( gerPos.getSignal() > 0 && book.getDirecaoImbalance() > 0 ) return;
        if( gerPos.getSignal() < 0 && book.getDirecaoImbalance() < 0 ) return;

        // se chegou ateh aqui, eh porque as ordens de saida estao no lado espesso do book,
        // entao fecho a posicao.
        gerPos.fecharPosicao();

    }else{
        // 1. cancelando ordens de entrada no lado ralo do book...
        //    Por enquanto cancela assim que chega na fila 2 porque a fila 1 concorre com robos muito rapidos...
        if( book.getDirecaoImbalance() > 0 ) trade.cancelarOrdensMenoresQue( ORDER_TYPE_SELL_LIMIT, book.getAsk(2), true );
        if( book.getDirecaoImbalance() < 0 ) trade.cancelarOrdensMaioresQue( ORDER_TYPE_BUY_LIMIT , book.getBid(2), true );

        // 2. colocando ordens de entrada longe do preco a fim de chegarem com prioridade na fila 1...
        gerPos.preencherOrdensLimitadasDeCompraAbaixoComLag2(book.getBid(EA_BOOK_DEEP),EA_TAMANHO_RAJADA,m_apmb_buy,EA_LAG_RAJADA1);
        gerPos.preencherOrdensLimitadasDeVendaAcimaComLag2  (book.getAsk(EA_BOOK_DEEP),EA_TAMANHO_RAJADA,m_apmb_sel,EA_LAG_RAJADA1);
    }
}
*/

//-----------------------------------------------------------------------------------------------------------------------------
// HFT_OPERAR_CANAL_EM_PAR
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
void abrirPosicaoHFTPairsTradingCanal(){

    //if( !bidAskEstaoIntegros() ){
    //    m_trade1.cancelarOrdensComentadas( m_symb_str1, m_apmb );
    //    m_trade2.cancelarOrdensComentadas( m_symb_str2, m_apmb );
    //    return;
    //}

    double vol1    = m_vol_lote_ini1;
    double vol2    = m_vol_lote_ini2;
    double room1   = m_tick_size1*EA_TOLERANCIA_ENTRADA;
    double room2   = m_tick_size2*EA_TOLERANCIA_ENTRADA;
    double shift   = 0.0; //5.0; // soh pra teste. retire assim que acabar
    ulong  ticket1,ticket2;


    if( EA_NEGOCIAR_ATIVO_1 && estouSemPosicao1() ){
        // COMPRA PAR 1
        if( podeEntrarComprando1() ){
            m_precoOrdem1 = m_canal1.getPrecoRegiaoInferior() - m_qtd_ticks_4_gain_ini_1*m_tick_size1;
            if( m_precoOrdem1 < m_canal1.getMinPrecoCanal() ) m_precoOrdem1 = m_canal1.getMinPrecoCanal();
            if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de compra1 ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_precoOrdem1, room1, vol1);
        }else{
          //m_trade1.cancelarOrdens(ORDER_TYPE_BUY_LIMIT,m_apmb);
            m_trade1.cancelarOrdens(ORDER_TYPE_BUY_LIMIT);
        }

        // VENDA PAR 1
        if( podeEntrarVendendo1() ){
            m_precoOrdem1 = m_canal1.getPrecoRegiaoSuperior() + m_qtd_ticks_4_gain_ini_1*m_tick_size1;
            if( m_precoOrdem1 > m_canal1.getMaxPrecoCanal() ) m_precoOrdem1 = m_canal1.getMaxPrecoCanal();
            if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de venda1 ZERADO! VERIFIQUE!", 
                                                    "\nm_canal1.getPrecoRegiaoSuperior():",m_canal1.getPrecoRegiaoSuperior(),
                                                    "\nm_canal1.getMaxPrecoCanal()      :",m_canal1.getMaxPrecoCanal(),
                                                    "\nm_qtd_ticks_4_gain_ini_1         :",m_qtd_ticks_4_gain_ini_1,
                                                    "\nm_tick_size1                     :",m_tick_size1
                                                    ); return;}
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_precoOrdem1, room1, vol1);
        }else{
          //m_trade1.cancelarOrdens(ORDER_TYPE_SELL_LIMIT,m_apmb);
            m_trade1.cancelarOrdens(ORDER_TYPE_SELL_LIMIT);
        }
    }

    if( EA_NEGOCIAR_ATIVO_2 && estouSemPosicao2()){
        // COMPRA PAR 2
        if( podeEntrarComprando2() ){
            m_precoOrdem2 = m_canal2.getPrecoRegiaoInferior() - m_qtd_ticks_4_gain_ini_2*m_tick_size2;
            if( m_precoOrdem2 < m_canal2.getMinPrecoCanal() ) m_precoOrdem2 = m_canal2.getMinPrecoCanal();
            if(m_precoOrdem2==0){Print(__FUNCTION__,":Preco Ordem de compra2 ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket2 = m_trade2.manterOrdemLimitadaEntornoDe(m_symb_str2, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_precoOrdem2, room2, vol2);
        }else{
          //m_trade2.cancelarOrdens(ORDER_TYPE_BUY_LIMIT,m_apmb);
            m_trade2.cancelarOrdens(ORDER_TYPE_BUY_LIMIT);
        }

        // VENDA PAR 2
        if( podeEntrarVendendo2() ){
            m_precoOrdem2 = m_canal2.getPrecoRegiaoSuperior() + m_qtd_ticks_4_gain_ini_2*m_tick_size2;
            if( m_precoOrdem2 > m_canal2.getMaxPrecoCanal() ) m_precoOrdem2 = m_canal2.getMaxPrecoCanal();
            if(m_precoOrdem2==0){Print(__FUNCTION__,":Preco Ordem de venda2 ZERADO! VERIFIQUE!",
                                                    "\nm_canal2.getPrecoRegiaoSuperior():",m_canal2.getPrecoRegiaoSuperior(),
                                                    "\nm_canal2.getMaxPrecoCanal()      :",m_canal2.getMaxPrecoCanal(),
                                                    "\nm_qtd_ticks_4_gain_ini_2         :",m_qtd_ticks_4_gain_ini_2,
                                                    "\nm_tick_size2                     :",m_tick_size2
                                                     ); return;}
            sleepTeste(); ticket2 = m_trade2.manterOrdemLimitadaEntornoDe(m_symb_str2, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_precoOrdem2, room2, vol2);
        }else{
          //m_trade2.cancelarOrdens(ORDER_TYPE_SELL_LIMIT,m_apmb);
            m_trade2.cancelarOrdens(ORDER_TYPE_SELL_LIMIT);
        }
    }
}
//-----------------------------------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------------------------------------
// HFT_OPERAR_CANAL_EM_PAR
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
bool velVolRDFOrientaCompra1(){ return m_predict_RDF1 >  1; }
bool velVolRDFOrientaVenda1 (){ return m_predict_RDF1 < -1; }
/*
void abrirPosicaoVelocVolumeRDF(){

    //if( !bidAskEstaoIntegros() ){
    //    m_trade1.cancelarOrdensComentadas( m_symb_str1, m_apmb );
    //    m_trade2.cancelarOrdensComentadas( m_symb_str2, m_apmb );
    //    return;
    //}

    double vol1    = m_vol_lote_ini1;
    double vol2    = m_vol_lote_ini2;
    double room1   = m_tick_size1*EA_TOLERANCIA_ENTRADA;
    double room2   = m_tick_size2*EA_TOLERANCIA_ENTRADA;
    double shift   = 0.0; //5.0; // soh pra teste. retire assim que acabar
    ulong  ticket1,ticket2;


    if( EA_NEGOCIAR_ATIVO_1 && estouSemPosicao1() ){
        
        // COMPRA PAR 1
        if( podeEntrarComprando1() && velVolRDFOrientaCompra1() && m_tick1.bid <= m_canal1.getPrecoRegiaoInferior() ){
            m_precoOrdem1 = m_tick1.bid;
            if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de compra1 ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_precoOrdem1, room1, vol1);
        }else{
            m_trade1.cancelarOrdens(ORDER_TYPE_BUY_LIMIT);
        }

        // VENDA PAR 1
        if( podeEntrarVendendo1() && velVolRDFOrientaVenda1() && m_tick1.ask >= m_canal1.getPrecoRegiaoSuperior() ){
            m_precoOrdem1 = m_tick1.ask;
            if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de venda1 ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_precoOrdem1, room1, vol1);
        }else{
            m_trade1.cancelarOrdens(ORDER_TYPE_SELL_LIMIT);
        }
    }

    if( EA_NEGOCIAR_ATIVO_2 && estouSemPosicao2()){
        // COMPRA PAR 2
        if( podeEntrarComprando2() ){
        
            m_precoOrdem2 = m_canal2.getPrecoRegiaoInferior() - m_qtd_ticks_4_gain_ini_2*m_tick_size2;
            if( m_precoOrdem2 < m_canal2.getMinPrecoCanal() ) m_precoOrdem2 = m_canal2.getMinPrecoCanal();
            if(m_precoOrdem2==0){Print(__FUNCTION__,":Preco Ordem de compra2 ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket2 = m_trade2.manterOrdemLimitadaEntornoDe(m_symb_str2, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_precoOrdem2, room2, vol2);
        
        }else{
            m_trade2.cancelarOrdens(ORDER_TYPE_BUY_LIMIT);
        }

        // VENDA PAR 2
        if( podeEntrarVendendo2() ){
            m_precoOrdem2 = m_canal2.getPrecoRegiaoSuperior() + m_qtd_ticks_4_gain_ini_2*m_tick_size2;
            if( m_precoOrdem2 > m_canal2.getMaxPrecoCanal() ) m_precoOrdem2 = m_canal2.getMaxPrecoCanal();
            if(m_precoOrdem2==0){Print(__FUNCTION__,":Preco Ordem de venda2 ZERADO! VERIFIQUE!",
                                                    "\nm_canal2.getPrecoRegiaoSuperior():",m_canal2.getPrecoRegiaoSuperior(),
                                                    "\nm_canal2.getMaxPrecoCanal()      :",m_canal2.getMaxPrecoCanal(),
                                                    "\nm_qtd_ticks_4_gain_ini_2         :",m_qtd_ticks_4_gain_ini_2,
                                                    "\nm_tick_size2                     :",m_tick_size2
                                                     ); return;}
            sleepTeste(); ticket2 = m_trade2.manterOrdemLimitadaEntornoDe(m_symb_str2, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_precoOrdem2, room2, vol2);
        }else{
            m_trade2.cancelarOrdens(ORDER_TYPE_SELL_LIMIT);
        }
    }
}
//-----------------------------------------------------------------------------------------------------------------------------
*/
//-----------------------------------------------------------------------------------------------------------------------------
// HFT_OPERAR_CANAL_EM_PAR
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
bool velVolNETOrientaCompra1(){ return m_predict_NET1 >  0.5; }
bool velVolNETOrientaVenda1 (){ return m_predict_NET1 < -0.5; }
/*
void abrirPosicaoVelocVolumeNET(){

    //if( !bidAskEstaoIntegros() ){
    //    m_trade1.cancelarOrdensComentadas( m_symb_str1, m_apmb );
    //    m_trade2.cancelarOrdensComentadas( m_symb_str2, m_apmb );
    //    return;
    //}

    double vol1    = m_vol_lote_ini1;
    double vol2    = m_vol_lote_ini2;
    double room1   = m_tick_size1*EA_TOLERANCIA_ENTRADA;
    double room2   = m_tick_size2*EA_TOLERANCIA_ENTRADA;
    double shift   = 0.0; //5.0; // soh pra teste. retire assim que acabar
    ulong  ticket1,ticket2;


    if( EA_NEGOCIAR_ATIVO_1 && estouSemPosicao1() ){
        
        // COMPRA PAR 1
      //if( podeEntrarComprando1() && velVolNETOrientaCompra1() && m_tick1.bid <= m_canal1.getPrecoRegiaoInferior() ){
        if( podeEntrarComprando1() && velVolNETOrientaCompra1()                                                     ){
            m_precoOrdem1 = m_tick1.bid;
            if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de compra1 ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_precoOrdem1, room1, vol1);
        }else{
            m_trade1.cancelarOrdens(ORDER_TYPE_BUY_LIMIT);
        }

        // VENDA PAR 1
      //if( podeEntrarVendendo1() && velVolNETOrientaVenda1() && m_tick1.ask >= m_canal1.getPrecoRegiaoSuperior() ){
        if( podeEntrarVendendo1() && velVolNETOrientaVenda1()                                                     ){
            m_precoOrdem1 = m_tick1.ask;
            if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de venda1 ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_precoOrdem1, room1, vol1);
        }else{
            m_trade1.cancelarOrdens(ORDER_TYPE_SELL_LIMIT);
        }
    }

    if( EA_NEGOCIAR_ATIVO_2 && estouSemPosicao2()){
        // COMPRA PAR 2
        if( podeEntrarComprando2() ){
        
            m_precoOrdem2 = m_canal2.getPrecoRegiaoInferior() - m_qtd_ticks_4_gain_ini_2*m_tick_size2;
            if( m_precoOrdem2 < m_canal2.getMinPrecoCanal() ) m_precoOrdem2 = m_canal2.getMinPrecoCanal();
            if(m_precoOrdem2==0){Print(__FUNCTION__,":Preco Ordem de compra2 ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket2 = m_trade2.manterOrdemLimitadaEntornoDe(m_symb_str2, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_precoOrdem2, room2, vol2);
        
        }else{
            m_trade2.cancelarOrdens(ORDER_TYPE_BUY_LIMIT);
        }

        // VENDA PAR 2
        if( podeEntrarVendendo2() ){
            m_precoOrdem2 = m_canal2.getPrecoRegiaoSuperior() + m_qtd_ticks_4_gain_ini_2*m_tick_size2;
            if( m_precoOrdem2 > m_canal2.getMaxPrecoCanal() ) m_precoOrdem2 = m_canal2.getMaxPrecoCanal();
            if(m_precoOrdem2==0){Print(__FUNCTION__,":Preco Ordem de venda2 ZERADO! VERIFIQUE!",
                                                    "\nm_canal2.getPrecoRegiaoSuperior():",m_canal2.getPrecoRegiaoSuperior(),
                                                    "\nm_canal2.getMaxPrecoCanal()      :",m_canal2.getMaxPrecoCanal(),
                                                    "\nm_qtd_ticks_4_gain_ini_2         :",m_qtd_ticks_4_gain_ini_2,
                                                    "\nm_tick_size2                     :",m_tick_size2
                                                     ); return;}
            sleepTeste(); ticket2 = m_trade2.manterOrdemLimitadaEntornoDe(m_symb_str2, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_precoOrdem2, room2, vol2);
        }else{
            m_trade2.cancelarOrdens(ORDER_TYPE_SELL_LIMIT);
        }
    }
}
//-----------------------------------------------------------------------------------------------------------------------------
*/
//------------------------------------------------------------------------------
//| HFT_FORMADOR_DE_MERCADO
//| Mantem pedidos de abetura de ordem segundo as regras abaixo:
//| 
//| ENTRADAS
//|         COMPRAR	imwf abaixo do bid e do ask
//|                 tlfv acima do bid e do ask
//|                 imbalance abaixo de -10
//|
//|         VENDER	imwf acima do bid e do ask
//|                 tlfv abaixo do bid e do ask
//|                 imbalance acima de +10
//|
//| SAIDAS
//|         mesmas condicoes das entradas.
//------------------------------------------------------------------------------
void abrirPosicaoHFTFormadorDeMercadoSinaisDoBook(){
    //double dist_min_entrada_book = m_dist_min_in_book_in_pos;
    double vol1    = m_vol_lote_ini1;
    double room1   = m_tick_size1*EA_TOLERANCIA_ENTRADA;
    double shift   = 0.0; //5.0; // soh pra teste. retire assim que acabar
    ulong  ticket1;

   int sinal1 = calcSinalBook1(EA_BOOK_DEEP1);
   // compre ou feche a posicao vendida
   if( sinal1>0 ){
        if(estouSemPosicao1() || estouVendido1() ){
            if(m_book1.getBid(2)==0){Print(__FUNCTION__,":Preco Ordem de compra ZERADO! VERIFIQUE!"); return;}
            if(estouVendido1()) Print(__FUNCTION__,":SAIDA: Mantendo ordem de COMPRA em torno de:", m_book1.getBid(2), "...");
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_book1.getBid(2), room1, vol1);
            //return;
        }
        return;
        // se cheou aqui, eh porque estou posicionado. Se estiver vendido, fecha a posicao;
        //if( estouVendido1() ){ m_trade1.fecharPosicao("SINALCMP"); return; }
   }
   
   // venda ou feche a posicao comprada
   if( sinal1<0 ){
        if(estouSemPosicao1() || estouComprado1()){
            if(m_book1.getAsk(2)==0){Print(__FUNCTION__,":Preco Ordem de venda ZERADO! VERIFIQUE!"); return;}
            if( estouComprado1()) Print(__FUNCTION__,":SAIDA: Mantendo ordem de VENDA em torno de:", m_book1.getAsk(2), "...");
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_book1.getAsk(2), room1, vol1);
            //return;
        }
        return;
        // se cheou aqui, eh porque estou posicionado. Se estiver comprado, fecha a posicao;
        //if( estouComprado1() ){ m_trade1.fecharPosicao("SINALVND"); return;}
   }
   
   // chegou aqui, eh porque nao tem sinal de compra ou venda e tambem nao tem posicao aberta. Entao cancela ordens de abertura de posicao, caso existam.
   if( estouSemPosicao1() ) m_trade1.cancelarOrdens("SEM_SINAL_ENTRADA");

}
//-----------------------------------------------------------------------------------------------------------------------------

// Calcula o sinal do book. Interprete assim:
//  1: entre comprando. se estiver vendido , feche a posicao.
// -1: entre vendendo . se estiver comprado, feche a posicao.
//  0: se estah posicionado, mantenha. Se nao estah, nao abra posicao.
int calcSinalBook1(int deep){
    if( m_book1.getIWFV(deep)      < m_book1.getBid(1) &&
        m_book1.getTLFV(deep)      > m_book1.getAsk(1) &&
        m_book1.getImbalance(deep) < -0.05                     ){
        return 1; // comprar
    }else{
        if( m_book1.getIWFV(deep)      > m_book1.getBid(1) &&
            m_book1.getTLFV(deep)      < m_book1.getAsk(1) &&
            m_book1.getImbalance(deep) > 0.05                  ){
            return -1; // vender
        }
    }
    
    return 0; // manter
}


//------------------------------------------------------------------------------
//| mantem pedidos de abertura de posicao abertos nas medias bid e ask do book.|
//------------------------------------------------------------------------------
double m_precoOrdem2;
void abrirPosicaoHFTFormadorDeMercadoSimplesNaMediaDoBook(){

    //if(m_acao_posicao == NAO_ABRIR_POSICAO      ){
    //    //Print("NAO_ABRIR_POSICAO Cancelando ordens APMB... ");
    //    m_trade1.cancelarOrdensComentadas(m_symb_str1,m_apmb); return;
    //};

    //if(m_acao_posicao != HFT_FORMADOR_DE_MERCADO) return;

    //double dist_min_entrada_book = m_dist_min_in_book_in_pos;
    double vol1    = m_vol_lote_ini1;
    double vol2    = m_vol_lote_ini1;
    double room1   = m_tick_size1*EA_TOLERANCIA_ENTRADA;
    double room2   = m_tick_size2*EA_TOLERANCIA_ENTRADA;
    double shift   = 0.0; //5.0; // soh pra teste. retire assim que acabar
    ulong  ticket1,ticket2;

   // mantem uma ordem de compra na media bid do book e uma ordem de venda na media ask do book.


   // estah acontecendo esta inconsistencia... ateh resolver, cancele todas as ordens e nao entre em posicao
   if( m_est.getPrecoMedBookAsk() <= m_est.getPrecoMedBookBid() && !(TESTE_OFFLINE) ){
       if(estouSemPosicao1()) m_trade1.cancelarOrdens("INCONSISTENCIA_MEDIA_BOOK");
       if(estouSemPosicao2()) m_trade2.cancelarOrdens("INCONSISTENCIA_MEDIA_BOOK");
       return;
   }

   // essa a eh a tendencia de cuto prazo (dentro da barra)
   int direcao = 0;
   if( m_est.getInclinacaoTrade() > 0                            ){ direcao = +1; }//if(TESTE_OFFLINE) direcao = +3;}
   if( m_est.getInclinacaoTrade() < 0                            ){ direcao = -1; }//if(TESTE_OFFLINE) direcao = -3;}
 //if( m_est.getInclinacaoTrade() > 0 && m_est.regLinGetB1() > 0 ){ direcao = +1;}
 //if( m_est.getInclinacaoTrade() < 0 && m_est.regLinGetB1() < 0 ){ direcao = -1;}

   // essa eh a tendendencia de prazo maior
   int direcaoPairTrading = 0;
   m_par.regLinFit();
   if( m_par.regLinSlope() > 0 ){ direcaoPairTrading = +1;}
   if( m_par.regLinSlope() < 0 ){ direcaoPairTrading = -1;}

   // comprando barato e vendendo caro, ou seja, entre vendendo acima do canal e comprando abaixo do canal
   int direcaoCanal = 0;
   if( m_canal1.compraEstahBarata(m_bid) ) direcaoCanal = +1;
   if( m_canal1.vendaEstahCara   (m_ask) ) direcaoCanal = -1;

   int dir = direcao+direcaoPairTrading;
   if( dir > -3 && dir < +3  ){
       if(estouSemPosicao1()) m_trade1.cancelarOrdensComentadas(m_symb_str1, m_apmb);
       if(estouSemPosicao2()) m_trade2.cancelarOrdensComentadas(m_symb_str2, m_apmb);
       return;
   }

   // mantendo uma ordem de venda na media ask do book...
   if( dir < 0 ){

     //cancelarOrdens(ORDER_TYPE_BUY_LIMIT);
       if(estouSemPosicao1()) m_trade1.cancelarOrdens(ORDER_TYPE_BUY_LIMIT ,m_apmb);
       if(estouSemPosicao2()) m_trade2.cancelarOrdens(ORDER_TYPE_SELL_LIMIT,m_apmb);

        m_precoOrdem1 = normalizar1( m_est.getPrecoMedBookAsk() + shift*m_tick_size1 );
        if(m_precoOrdem1<m_ask       ) m_precoOrdem1 = m_ask     ;
      //if(m_precoOrdem1<m_ask_stplev) m_precoOrdem1 = m_ask_stplev;

        if(TESTE_OFFLINE) m_precoOrdem1 = m_ask;

        // mantendo a distancia em ticks desde o preco atual ateh a ordem igual para os dois ativos...
        double distPrecoOrdem1Ask = (m_precoOrdem1-m_ask)/m_tick_size1;
        m_precoOrdem2 = normalizar2(m_tick2.bid-distPrecoOrdem1Ask*m_tick_size2);
        if(estouPosicionado1()) m_precoOrdem2 = m_tick2.bid;

        if( estouSemPosicao1() ){
            if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de venda ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_precoOrdem1, room1, vol1);
        }

        if(estouSemPosicao2()){
            sleepTeste(); ticket2 = m_trade2.manterOrdemLimitadaEntornoDe(EA_TICKER_REF, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_precoOrdem2, room2, vol2);
        }
        return;
   }

   if( dir > 0 ){
      //cancelarOrdens(ORDER_TYPE_SELL_LIMIT);
        if(estouSemPosicao1()) m_trade1.cancelarOrdens(ORDER_TYPE_SELL_LIMIT ,m_apmb);
        if(estouSemPosicao2()) m_trade2.cancelarOrdens(ORDER_TYPE_BUY_LIMIT  ,m_apmb);

        // mantendo uma ordem de compra na media bid do book...
        m_precoOrdem1 = normalizar1( m_est.getPrecoMedBookBid() - shift*m_tick_size1);
        if(m_precoOrdem1>m_bid       ) m_precoOrdem1 = m_bid       ;
      //if(m_precoOrdem1>m_bid_stplev) m_precoOrdem1 = m_bid_stplev;

        if(TESTE_OFFLINE) m_precoOrdem1 = m_bid;

        // mantendo a distancia em ticks desde o preco atual ateh a ordem igual para os dois ativos...
        double distPrecoOrdem1Bid = (m_bid-m_precoOrdem1)/m_tick_size1;
        m_precoOrdem2 = normalizar2(m_tick2.ask+distPrecoOrdem1Bid);
        if(estouPosicionado1()) m_precoOrdem2 = m_tick2.ask;

        if(estouSemPosicao1()){
            if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de compra ZERADO! VERIFIQUE!"); return;}
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_precoOrdem1, room1, vol1);
        }
        if(estouSemPosicao2()){
            sleepTeste(); ticket2 = m_trade2.manterOrdemLimitadaEntornoDe(EA_TICKER_REF, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_precoOrdem2, room2, vol2);
        }
   }
}
//---------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------
//| mantem pedidos de abertura de posicao abertos nas medias das agressoes.    |
//------------------------------------------------------------------------------
void abrirPosicaoHFTFormadorDeMercadoSimplesNaMediaDoTrade(){

    //double dist_min_entrada_book = m_dist_min_in_book_in_pos;
    double vol     = m_vol_lote_ini1;
    double room1   = m_tick_size1*EA_TOLERANCIA_ENTRADA;
    double shift   = 0.0; //5.0; // soh pra teste. retire assim que acabar
    ulong  ticket1;

   // mantem uma ordem de compra na media bid do book e uma ordem de venda na media ask do book.


   // estah acontecendo esta inconsistencia... ateh resolver, cancele todas as ordens e nao entre em posicao
//   if( m_est.getPrecoMedBookAsk() <= m_est.getPrecoMedBookBid() ){
//       cancelarOrdens("INCONSISTENCIA_MEDIA_BOOK");
//       return;
//   }

   int direcao = 0;
   if( m_est.getInclinacaoTrade() > 0                            ){ direcao = +1;}
   if( m_est.getInclinacaoTrade() < 0                            ){ direcao = -1;}
 //if( m_est.getInclinacaoTrade() > 0 && m_est.regLinGetB1() > 0 ){ direcao = +1;}
 //if( m_est.getInclinacaoTrade() < 0 && m_est.regLinGetB1() < 0 ){ direcao = -1;}

   if( direcao==0 ){ cancelarOrdens("SEM_DIRECAO_DEFINIDA"); return; }


   // mantendo uma ordem de venda na media ask do book...
   if( direcao < 0 ){

        cancelarOrdens(ORDER_TYPE_BUY_LIMIT);

        m_precoOrdem1 = normalizar1( m_est.getPrecoMedTradeBuy() + shift*m_tick_size1 );
      //m_precoOrdem1 = normalizar1( m_est.getPrecoMedBook()    + shift*m_tick_size1 );
        if(m_precoOrdem1<m_ask       ) m_precoOrdem1 = m_ask     ;
      //if(m_precoOrdem1<m_ask_stplev) m_precoOrdem1 = m_ask_stplev;

        if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de venda ZERADO! VERIFIQUE!"); return;}
        sleepTeste();
        ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_precoOrdem1, room1, vol);

        return;
   }


   if( direcao > 0 ){
        cancelarOrdens(ORDER_TYPE_SELL_LIMIT);

        // mantendo uma ordem de compra na media bid do book...
        m_precoOrdem1 = normalizar1( m_est.getPrecoMedTradeSel() - shift*m_tick_size1);
      //m_precoOrdem1 = normalizar1( m_est.getPrecoMedBook()    - shift*m_tick_size1);
        if(m_precoOrdem1>m_bid       ) m_precoOrdem1 = m_bid       ;
      //if(m_precoOrdem1>m_bid_stplev) m_precoOrdem1 = m_bid_stplev;

        if(m_precoOrdem1==0){Print(__FUNCTION__,":Preco Ordem de compra ZERADO! VERIFIQUE!"); return;}
        sleepTeste();
        ticket1 = m_trade1.manterOrdemLimitadaEntornoDe(m_symb_str1, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_precoOrdem1, room1, vol);
   }
}
//---------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------
// Inicia ordem de abertura a pelo menos XX desvios padrao na correlacao entre paraes de ativos.
// HFT_ARBITRAGEM_PAR
//---------------------------------------------------------------------------------------------------------
void abrirPosicaoHFTarbitragemPar(){

    if( m_ask      ==0 || m_bid      ==0 ||
        m_tick2.ask==0 || m_tick2.bid==0    ){
        Print(__FUNCTION__," Erro abertura posicao :m_ask=",m_ask,
                                                  " m_bid=",m_bid,
                                                  " ref_ask=", m_tick2.ask,
                                                  " ref_bid=", m_tick2.bid );

        // se tinha ordem pendente, cancela
        m_trade1.cancelarOrdensComentadas(m_symb_str1   ,m_apmb );
        m_trade2.cancelarOrdensComentadas(m_symb2.Name(),m_apmb );

        //m_aguardar_para_abrir_posicao = EA_EST_QTD_SEGUNDOS*1000; // aguarda ateh poder abrir nova posicao
        return;
    }

    // ativo estah barato em ralacao ao seu par...
    if( m_par.getSpreadStd() <= m_par.getSpreadStd(-EA_QTD_DP_FIRE_ORDEM) ){

        // providenciando a ordem de entrada na posicao...
        m_precoOrdem1 = m_bid;

        if( !m_trade1.tenhoOrdemLimitadaDeCompra( m_precoOrdem1, m_symb_str1, m_apmb, m_vol_lote_ini1 , true, m_shift_in_points, m_apmb_buy+getStrComment() ) ){
            if(m_precoOrdem1!=0) m_trade1.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_apmb_buy+getStrComment() );
        }

        // cancelando ordens de venda porventura colocadas...
        if( ! m_trade1.cancelarOrdensComentadasDeVenda(m_symb_str1 ,m_apmb     ) ) return; // se teve algum problema cancelando ordens, nao segue criando outras
        if( ! m_trade1.cancelarOrdensComentadasDeVenda(m_symb_str1 ,m_strRajada) ) return; // se teve algum problema cancelando ordens, nao segue criando outras
        return;
    }else{

        // ativo estah caro em relacao ao seu par...
        if( m_par.getSpreadStd() >= m_par.getSpreadStd(EA_QTD_DP_FIRE_ORDEM) ){

            // providenciando a ordem de entrada na posicao...
            m_precoOrdem1 = m_ask;
            double m_precoOrdem1Pair = m_symb2.Bid();

            if( !m_trade1.tenhoOrdemLimitadaDeVenda( m_precoOrdem1, m_symb_str1, m_apmb, m_vol_lote_ini1 , true, m_shift_in_points, m_apmb_sel+getStrComment() ) ){
                if(m_precoOrdem1!=0) m_trade1.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_apmb_sel+getStrComment() );
            }
       //   if( !m_trade1.tenhoOrdemLimitadaDeVenda( m_precoOrdem1Pair, EA_TICKER_REF, m_apmb, m_vol_lote_ini1 , true, m_shift_in_points, m_apmb_buy+getStrComment() ){
       //       if(m_precoOrdem1!=0) m_trade1.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_apmb_sel+getStrComment() );
       //   }


            // cancelando ordens de compra porventura colocadas...
            if( ! m_trade1.cancelarOrdensComentadasDeCompra(m_symb_str1, m_apmb     ) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras
            if( ! m_trade1.cancelarOrdensComentadasDeCompra(m_symb_str1, m_strRajada) ) return ; // se teve algum problema cancelando ordens, nao segue criando outras
            return;
        }
    }
    // se chegou aqui eh porque nao ha condicao para abrir posicao. Entao cancela pedidos de entrada pendentes.
    m_trade1.cancelarOrdensComentadas(m_symb_str1,m_apmb     );
    m_trade1.cancelarOrdensComentadas(m_symb_str1,m_strRajada);
}



//---------------------------------------------------------------------------------------------------------
// Inicia ordem de abertura a pelo menos XX ticks do preco atual. Visa ter prioridade na fila do book.
// HFT_FORMADOR_DE_MERCADO_SEM_CUSUM
//---------------------------------------------------------------------------------------------------------
int getTicksAddPorSelecaoAdversa1(){
    if(m_posicaoLotsPend<=m_vol_lote_ini1) return 0;
    if((EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_1+EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_2)==0) return 0;

    //double ticks_add = EA_AUMENTO_LAG_POR_LOTE_PENDENTE;
    double ticks_add = m_qtd_ticks_4_gain_ini_1;
    for ( int i=1; i<=m_posicaoLotsPend; i++ ){
        //ticks_add = (int)ceil( ticks_add + (ticks_add * EA_AUMENTO_LAG_POR_LOTE_PENDENTE) );
        if(i<=EA_AUMENTO_LAG_QTD_FASE1)
            ticks_add = (int)ceil( ticks_add + (ticks_add * EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_1) );
        else{
            ticks_add = (int)ceil( ticks_add + (ticks_add * EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_2) );
        }
    }
    //return (int)ceil(m_posicaoLotsPend*EA_AUMENTO_LAG_POR_LOTE_PENDENTE);

    ticks_add = ticks_add-m_qtd_ticks_4_gain_ini_1;
    if(ticks_add<0) ticks_add=0;
    return (int)ceil(ticks_add);
}// truncando pra cima



double getTicksAddPorSelecaoAdversa2(){

    if((EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_1+EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_2)==0) return 0;

    //if( estouSemPosicao2() ) return 0;
    double posicaoLotsPend2 =  calcVolPosicao2();

    if(m_posicaoLotsPend2<=m_vol_lote_ini1) return 0;

  //double ticks_add = EA_AUMENTO_LAG_POR_LOTE_PENDENTE;
    double ticks_add = m_qtd_ticks_4_gain_ini_1;
    for ( int i=1; i<=posicaoLotsPend2; i++ ){
        if(i<=EA_AUMENTO_LAG_QTD_FASE1)
            ticks_add = ceil( ticks_add + (ticks_add * EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_1) );
        else{
            ticks_add = ceil( ticks_add + (ticks_add * EA_AUMENTO_LAG_POR_LOTE_PENDENTE_FASE_2) );
        }
    }
    //return (int)ceil(m_posicaoLotsPend*EA_AUMENTO_LAG_POR_LOTE_PENDENTE);
    ticks_add = ticks_add-m_qtd_ticks_4_gain_ini_1;
    if(ticks_add<0) ticks_add=0;
    return ceil(ticks_add);
}// truncando pra cima

//int getQtdTicksProxOrdem(){
//
//}

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
    int copiados = CopyRates(m_symb_str1,_Period,1,1,m_rates1_tmp);
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
    //int copiados = CopyRates(m_symb_str1,_Period,1,1,m_rates1_tmp);
    //Print(":-| Copiados: ", copiados );
    //ArrayPrint(m_rates1_tmp);

  //double precoOrdem = 0;
    double distancia  = (EA_DISTAN_DEMAIS_ORDENS_RAJ*m_tick_size1);
    double shift      = 0;
    // Posicao vendido : Coloca ordem limitada de venda  no preco maximo do periodo anterior ou no preco atual (o maior)
    if( estouVendido1() ){

    //  // uma ordem no preco atual...
    //  m_precoOrdem1 = normalizar1( m_ask + distancia );
    ////if( m_precoOrdem1 < m_ask ){ m_precoOrdem1 = m_ask; }
    //  if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );

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
        m_precoOrdem1 = normalizar1( phigh );
        if( m_precoOrdem1 < m_ask ){ m_precoOrdem1 = m_ask; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem1, m_vol_lote_ini1*EA_INCREM_VOL_RAJ, m_strRajada+getStrComment() );
        m_time_analisado = m_rates1_tmp[0].time;
        return;
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////

        // outra ordem na maxima da barra anterior...
      //m_precoOrdem1 = normalizar1( m_rates1_tmp[0].high + distancia );
        m_precoOrdem1 = normalizar1( phigh );
        if( m_precoOrdem1 < m_ask ){ m_precoOrdem1 = m_ask; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );

        ////////////////////////////////////////////////////////////////////////
        // NOVOS EM TESTE (saiu o preco atual)
        ////////////////////////////////////////////////////////////////////////
        // outra ordem na minima da barra anterior...
      //m_precoOrdem1 = normalizar1( m_rates1_tmp[0].low + distancia );
        m_precoOrdem1 = normalizar1( plow );
        if( m_precoOrdem1 < m_ask ){ m_precoOrdem1 = m_ask; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );

        // outra ordem na abertura da barra anterior...
      //m_precoOrdem1 = normalizar1( m_rates1_tmp[0].open + distancia );
        m_precoOrdem1 = normalizar1( popen );
        if( m_precoOrdem1 < m_ask ){ m_precoOrdem1 = m_ask; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );

        // outra ordem no fechamento da barra anterior...
      //m_precoOrdem1 = normalizar1( m_rates1_tmp[0].close + distancia );
        m_precoOrdem1 = normalizar1( pclose );
        if( m_precoOrdem1 < m_ask ){ m_precoOrdem1 = m_ask; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_SELL_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );
        ////////////////////////////////////////////////////////////////////////

        m_time_analisado = m_rates1_tmp[0].time;
    }

    // Posicao comprado: Coloca ordem limitada de compra no preco minimo do periodo anterior ou no preco atual (o menor)
    if( estouComprado1() ){

   //   // uma ordem no preco atual...
   //   m_precoOrdem1 = normalizar1( m_bid - distancia );
   // //if( m_precoOrdem1 > m_bid ){ m_precoOrdem1 = m_bid; }
   //   if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );

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
        m_precoOrdem1 = normalizar1( plow );
        if( m_precoOrdem1 > m_bid ){ m_precoOrdem1 = m_bid; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem1, m_vol_lote_ini1*EA_INCREM_VOL_RAJ, m_strRajada+getStrComment() );
        m_time_analisado = m_rates1_tmp[0].time;
        return;
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////


        // outra ordem no minimo da barra anterior...
      //m_precoOrdem1 = normalizar1( m_rates1_tmp[0].low - distancia );
        m_precoOrdem1 = normalizar1( plow );
        if( m_precoOrdem1 > m_bid ){ m_precoOrdem1 = m_bid; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );


        ////////////////////////////////////////////////////////////////////////
        // NOVOS EM TESTE
        ////////////////////////////////////////////////////////////////////////
        // outra ordem na maxima da barra anterior...
      //m_precoOrdem1 = normalizar1( m_rates1_tmp[0].high - distancia );
        m_precoOrdem1 = normalizar1( phigh );
        if( m_precoOrdem1 > m_bid ){ m_precoOrdem1 = m_bid; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );

        // outra ordem na abertura da barra anterior...
      //m_precoOrdem1 = normalizar1( m_rates1_tmp[0].open - distancia );
        m_precoOrdem1 = normalizar1( popen );
        if( m_precoOrdem1 > m_bid ){ m_precoOrdem1 = m_bid; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );

        // outra ordem no fechamento da barra anterior...
      //m_precoOrdem1 = normalizar1( m_rates1_tmp[0].close - distancia );
        m_precoOrdem1 = normalizar1( pclose );
        if( m_precoOrdem1 > m_bid ){ m_precoOrdem1 = m_bid; }
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendente( ORDER_TYPE_BUY_LIMIT , m_precoOrdem1, m_vol_lote_ini1, m_strRajada+getStrComment() );


        m_time_analisado = m_rates1_tmp[0].time;
    }


    //doCloseRajada(m_passo_rajada, m_vol_lote_raj, m_qtd_ticks_4_gain_ini_1);

    //m_trade1.alterarValorDeOrdensNumericasPara(m_symb_str1,m_precoSaidaPosicao,m_precoPosicao);

}

void preencherFilaOrdensFixa(){

    //m_qtd_exec_filaordens++;

    //double precoOrdem         = 0;
    double passoRajada          = (m_raj_unica_distancia_demais_ordens*m_tick_size1);
    double passoRajadaPrimOrdem = (m_raj_unica_distancia_prim_ordem   *m_tick_size1);
    double shift                = 0;
    // Posicao vendido : Coloca rajada de ordens limitadas de venda
    if( estouVendido1() ){

        m_precoOrdem1 = normalizar1( m_precoPosicao+passoRajadaPrimOrdem );
        if( m_precoOrdem1 < m_ask ){ m_precoOrdem1 = m_ask; }
        m_trade1.setAsync(true);
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendenteRajada( ORDER_TYPE_SELL_LIMIT           , // tipo de ordens
                                                                  m_precoOrdem1                     , // preco da primeira ordem
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
                                                                 //,m_tick_size1
                                                                  );//
        m_trade1.setAsync(false);
        //m_time_analisado = m_rates1_tmp[0].time;
        return;
    }

    // Posicao comprado: Coloca rajadas de ordens limitadas de compra
    if( estouComprado1() ){

        m_precoOrdem1 = normalizar1( m_precoPosicao-passoRajadaPrimOrdem );
        if( m_precoOrdem1 > m_bid ){ m_precoOrdem1 = m_bid; }
        m_trade1.setAsync(true);
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendenteRajada( ORDER_TYPE_BUY_LIMIT              , // tipo de ordens
                                                                  m_precoOrdem1                      , // preco da primeira ordem
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
                                                                 //,m_tick_size1
                                                                  );//
        m_trade1.setAsync(false);
        //m_time_analisado = m_rates1_tmp[0].time;
        return;
    }
}

bool estouVendido1 (ENUM_DEAL_TYPE toCloseTypeDeal){ return toCloseTypeDeal==DEAL_TYPE_SELL; }
bool estouComprado1(ENUM_DEAL_TYPE toCloseTypeDeal){ return toCloseTypeDeal==DEAL_TYPE_BUY ; }
void preencherFilaOrdensFixaAssincrona(ENUM_DEAL_TYPE toCloseTypeDeal, double toClosePriceIn){

    //double precoOrdem         = 0;
    double passoRajada          = (m_raj_unica_distancia_demais_ordens*m_tick_size1);
    double passoRajadaPrimOrdem = (m_raj_unica_distancia_prim_ordem   *m_tick_size1);
    double shift                = 0;
    // Posicao vendido : Coloca rajada de ordens limitadas de venda
    if( estouVendido1(toCloseTypeDeal) ){

        m_precoOrdem1 = normalizar1( toClosePriceIn+passoRajadaPrimOrdem );
        if( m_precoOrdem1 < m_ask ){ m_precoOrdem1 = m_ask; }
        m_trade1.setAsync(true);
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendenteRajada( ORDER_TYPE_SELL_LIMIT             , // tipo de ordens
                                                                  m_precoOrdem1                      , // preco da primeira ordem
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
                                                                 //,m_tick_size1
                                                                  );//
        m_trade1.setAsync(false);
        //m_time_analisado = m_rates1_tmp[0].time;
        return;
    }

    // Posicao comprado: Coloca rajadas de ordens limitadas de compra
    if( estouComprado1(toCloseTypeDeal) ){

        m_precoOrdem1 = normalizar1( toClosePriceIn-passoRajadaPrimOrdem );
        if( m_precoOrdem1 > m_bid ){ m_precoOrdem1 = m_bid; }
        m_trade1.setAsync(true);
        if( m_precoOrdem1 != 0 )m_trade1.enviarOrdemPendenteRajada( ORDER_TYPE_BUY_LIMIT              , // tipo de ordens
                                                                  m_precoOrdem1                      , // preco da primeira ordem
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
                                                                 //,m_tick_size1
                                                                  );//
        m_trade1.setAsync(false);
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

double normalizar1(double preco){ return m_symb1.NormalizePrice(preco); }
double normalizar2(double preco){ return m_symb2.NormalizePrice(preco); }

//void fecharPosicao (string comentario){ m_trade1.fecharQualquerPosicao (comentario); setSemPosicao(); }
void cancelarOrdens(string comentario){ m_trade1.cancelarOrdens(comentario); setSemPosicao(); }

void setCompradoSoft(){ m_comprado = true ; m_vendido = false; }
void setVendidoSoft() { m_comprado = false; m_vendido = true ; }
void setComprado()    { m_comprado = true ; m_vendido = false; m_tstop = 0;}
void setVendido()     { m_comprado = false; m_vendido = true ; m_tstop = 0;}
void setSemPosicao()  { m_comprado = false; m_vendido = false; m_tstop = 0;}

bool podeEntrarComprando1(){ return m_tipo_entrada_permitida1==ENTRADA_BUY  || m_tipo_entrada_permitida1==ENTRADA_TODAS; }
bool podeEntrarVendendo1 (){ return m_tipo_entrada_permitida1==ENTRADA_SELL || m_tipo_entrada_permitida1==ENTRADA_TODAS; }
bool podeEntrarComprando2(){ return m_tipo_entrada_permitida2==ENTRADA_BUY  || m_tipo_entrada_permitida2==ENTRADA_TODAS; }
bool podeEntrarVendendo2 (){ return m_tipo_entrada_permitida2==ENTRADA_SELL || m_tipo_entrada_permitida2==ENTRADA_TODAS; }

bool estouComprado1   (){ return m_comprado; }
bool estouVendido1    (){ return m_vendido ; }
bool estouSemPosicao1 (){ return !estouComprado1() && !estouVendido1() ; }
bool estouPosicionado1(){ return  estouComprado1() ||  estouVendido1() ; }

bool estouPosicionado2(){ return PositionSelect(m_symb_str2); }
bool estouSemPosicao2 (){ return !estouPosicionado2(); }
bool estouVendido2    (){ return ( estouPosicionado2() && (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) );}
bool estouComprado2   (){ return ( estouPosicionado2() && (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ) );}

//bool estouVendido2 (){
//    double retorno = ( estouPosicionado2() && (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) ) 
//    return ;
//}
//bool estouComprado2(){ 
//    return ( estouPosicionado2() && (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ) );
//}



string status(){
   string obs =
         //" preco="       + m_tick1.ask                         +
         //" bid="         + m_tick1.bid                         +
         //" spread="      + (m_tick1.ask-m_tick1.bid)           +
           " last="        + DoubleToString( m_tick1.last )
         //" time="        + m_tick1.time
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
    delete(m_par);                        Print(__FUNCTION__,":-| m_par deletado:", GetLastError() );

  //MarketBookRelease(m_symb_str1);        Print(m_name," :-| Expert ", m_name, " Manipulador do Book liberado." );
    //IndicatorRelease( m_icci.Handle()  ); Print(m_name," :-| Expert ", m_name, " Manipulador do indicador cci   liberado." );
    //IndicatorRelease( m_ibb.Handle()    );

    if( EA_SHOW_CONTROL_PANEL ) { m_cp.Destroy(reason); Print(m_name,":-| Expert ", m_name, " Painel de controle destruido." ); }

    Comment("");                          Print(m_name," :-| Expert ", m_name, " Comentarios na tela apagados." );
                                          Print(m_name," :-) Expert ", m_name, " OnDeinit finalizado!" );
    
                                          
    m_db.close();
    
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

void gerenciarRebaixamentoDeSaldoDoDia(){
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
bool        m_eh_hora_de_fechar_posicao        = false;
datetime    m_time_in_seconds_atu              = TimeCurrent();
datetime    m_time_in_seconds_ant              = m_time_in_seconds_atu;
MqlDateTime m_date_atu;
MqlDateTime m_date_ant;
//----------------------------------------------------------------------------------------------------
void OnTimer(){
    //Print(__FUNCTION__, " Executando Ontimer()...");

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
  
    //acumularNET();
    //if( acumularRDF() ) compilarRDFnova();
  
  //calcularDirecaoVelocidadeDoVolume(); <TODO>: verificar se este metodo pode ser melhor que o uso estatistica2
    calcularOffset();
    calcLenBarraMedia();
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
    //Print(__FUNCTION__, " Fim Ontimer()...");

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


// colunas da matriz RDF
#define VEL_VOL_TRADE_BUY 0 // variavel independente
#define VEL_VOL_TRADE_SEL 1 // variavel independente
#define VEL_VOL_TRADE_LIQ 2 // variavel independente
#define ACE_VOL_TRADE_BUY 3 // variavel independente
#define ACE_VOL_TRADE_SEL 4 // variavel independente
#define CLASSE            5

#define NVARS             5  // quantidade de variaveis independentes

// colunas da matriz de RDF precos
#define BIDD              0
#define ASKK              1

// classes da matriz RDF
/*
#define ASK_BID            0  // Ask e bid nao mudaram
#define ASK_BID_UP         1  // ask e bid subiram
#define ASK_BID_DW         2  // ask e bid desceram
#define ASK_DW             3  // ask desceu e bid manteve
#define BID_UP             4  // bid subiu e ask manteve
#define ASK_UP             5  // ask subiu e bid manteve
#define BID_DW             6  // bid desceu e ask manteve
#define SPREAD_UP          7  // bid desceu e ask subiu
#define QTD_CLASSES        7  // quantidade de classes
*/

#define ASK_BID_DW_PLUSP   00  // ask e bid desceram         -- descida maxima menor que spread x2
#define ASK_BID_DW_PLUS    10  // ask e bid desceram         -- descida maxima menor que spread
#define ASK_BID_DW         20  // ask e bid desceram         -- descida maxima
#define ASK_DW             30  // ask desceu e bid manteve   -- descida media

#define BID_DW             40  // bid desceu e ask manteve   -- descida abaixo da media
#define ASK_BID            50  // Ask e bid nao mudaram      -- neutro
#define SPREAD_UP          50  // bid desceu e ask subiu     -- neutro -- aumentou spread 
#define ASK_UP             60  // ask subiu e bid manteve    -- subida abaixo da media

#define BID_UP             70  // bid subiu e ask manteve    -- subida media
#define ASK_BID_UP         80  // ask e bid subiram          -- subida maxima
#define ASK_BID_UP_PLUS    90  // ask e bid subiram          -- subida maxima maior que spread
#define ASK_BID_UP_PLUSP   100 // ask e bid subiram          -- subida maxima maior que spread x2

#define EA_MAT_RDF_NOVA_COLS    21

double m_matriz_RDF_nova  [][EA_MAT_RDF_NOVA_COLS]; // ultima coluna eh a classe com a previsao.
double m_matriz_RDF       [][NVARS+1];
double m_matriz_RDF_precos[][2];
int    m_pos_mat_RDF = 0;                                //linha da matriz RDF
int    m_pos_mat_RDF_nova = 0;                           //linha da matriz RDF nova
int    m_pos_mat_RDF_max      = EA_MAT_RDF_TAMANHO     -1;
int    m_pos_mat_RDF_max_nova = EA_MAT_RDF_TAMANHO_NOVA-1;
long   m_matriz_RDF_qtd_voltas = 0;
long   m_matriz_RDF_qtd_voltas_nova = 0;



// acumula uma linha na matriz RDF nova...
// o total de colunas da RDF nova eh igual a quantidade de linhas da antiga + 1.
void acumularRDFNova(int colRDF, double classe){
    // caminhe por toda a matriz RDF antiga...
    // cada linha da RDF nova terah a quantidade de linhas da RDF original

    // controlando o tamanho maximo da matriz...
    if( m_pos_mat_RDF_nova > m_pos_mat_RDF_max_nova ){ 
        m_pos_mat_RDF_nova = 0;
        m_matriz_RDF_qtd_voltas_nova++;
    }else{
        ArrayResize( m_matriz_RDF_nova ,EA_MAT_RDF_TAMANHO_NOVA );
    }
    
    //Print("m_pos_mat_RDF:",m_pos_mat_RDF, " m_pos_mat_RDF_nova:",m_pos_mat_RDF_nova);
    
    // adicionando na matriz RDF nova desde m_pos_mat_RDF (mais antigo) ateh o final da matriz m_pos_mat_RDF...
    int i = 0;
    for( ; i<EA_MAT_RDF_TAMANHO-m_pos_mat_RDF; i++){
        
        // pegue a coluna indicada e adicione na matriz RDF nova...
        m_matriz_RDF_nova[m_pos_mat_RDF_nova][i] = m_matriz_RDF[m_pos_mat_RDF+i][colRDF];
    }
    
    // adicionando na matriz RDF nova desde o inicio da matriz antiga ateh o elemento mais novo inserido na matriz antiga (m_pos_mat_RDF-1)...
    for( int iRDF=0; iRDF<m_pos_mat_RDF; iRDF++){
    
        // pegue a coluna indicada e adicione na matriz RDF nova...
        m_matriz_RDF_nova[m_pos_mat_RDF_nova][i++] = m_matriz_RDF[iRDF][colRDF];
    
    }
    
    // colocando a classe na ultima coluna da linha anterior da matriz nova...
    m_matriz_RDF_nova[m_pos_mat_RDF_nova][i] = classe;
    if(m_pos_mat_RDF_nova==0){ 
        m_matriz_RDF_nova[m_pos_mat_RDF_max_nova][i] = classe;
    }else{
        m_matriz_RDF_nova[m_pos_mat_RDF_nova - 1][i] = classe;
    }

    // avancando uma linha na matriz nova...
    m_pos_mat_RDF_nova++;
}


bool acumularNET(){
    // acumulando a cada 10 segundos...
    if(!m_mudou_segundo || m_date_atu.sec % 20 == 1) return false;
    
    //Print(__FUNCTION__, m_net1.toString() );
    m_net1.acumularFeature(false);
    m_predict_NET1 = m_net1.getPrevisao();
    return true;
}


bool acumularRDF(){

    if( !EA_CALC_REGRESSAO_RDF ) return false;
    //if( !m_mudou_segundo ) {return false;}

    // controlando o tamanho maximo da matriz...
    if( m_pos_mat_RDF > m_pos_mat_RDF_max ){ 
        m_pos_mat_RDF = 0;
        m_matriz_RDF_qtd_voltas++;
    }else{
        ArrayResize( m_matriz_RDF       ,EA_MAT_RDF_TAMANHO );
        ArrayResize( m_matriz_RDF_precos,EA_MAT_RDF_TAMANHO );
    }

    double askAnt = 0;
    double bidAnt = 0;
    if( m_pos_mat_RDF > 0 ){
        askAnt = m_matriz_RDF_precos[m_pos_mat_RDF-1][ASKK];
        bidAnt = m_matriz_RDF_precos[m_pos_mat_RDF-1][BIDD];
    }else{
        // aqui sabemos que m_pos_mat_RDF eh zero, entao atualizamos a ultima linha da matriz...
        askAnt = m_matriz_RDF_precos[m_pos_mat_RDF_max][ASKK];
        bidAnt = m_matriz_RDF_precos[m_pos_mat_RDF_max][BIDD];
    }
    double spread  = m_tick1.ask-m_tick1.bid;
    if( spread==0 ) spread = m_tick_size1;

    if( !(m_tick1.ask != askAnt || m_tick1.bid != bidAnt) ) return false;

    //if(m_matriz_RDF_qtd_voltas>0) ArrayPrint(m_matriz_RDF);
    
    // controlando o tamanho maximo da matriz...
    //if( m_pos_mat_RDF > m_pos_mat_RDF_max ){ 
    //    m_pos_mat_RDF = 0;
    //    m_matriz_RDF_qtd_voltas++;
    //}else{
    //    ArrayResize( m_matriz_RDF       ,EA_MAT_RDF_TAMANHO );
    //    ArrayResize( m_matriz_RDF_precos,EA_MAT_RDF_TAMANHO );
    //}
    
    m_matriz_RDF       [m_pos_mat_RDF][VEL_VOL_TRADE_BUY] = m_est.getVolTradeBuyPorSeg();
    m_matriz_RDF       [m_pos_mat_RDF][VEL_VOL_TRADE_SEL] = m_est.getVolTradeSelPorSeg();
    m_matriz_RDF       [m_pos_mat_RDF][VEL_VOL_TRADE_LIQ] = m_est.getVolTradeLiqPorSeg();

    m_matriz_RDF       [m_pos_mat_RDF][ACE_VOL_TRADE_BUY] = m_est.getAceVolBuy();
    m_matriz_RDF       [m_pos_mat_RDF][ACE_VOL_TRADE_SEL] = m_est.getAceVolSel();

    m_matriz_RDF_precos[m_pos_mat_RDF][BIDD             ] = m_tick1.bid;
    m_matriz_RDF_precos[m_pos_mat_RDF][ASKK             ] = m_tick1.ask;
    
    //double askAnt = 0;
    //double bidAnt = 0;
    //if( m_pos_mat_RDF > 0 ){
    //    askAnt = m_matriz_RDF_precos[m_pos_mat_RDF-1][ASKK];
    //    bidAnt = m_matriz_RDF_precos[m_pos_mat_RDF-1][BIDD];
    //}else{
    //    // aqui sabemos que m_pos_mat_RDF eh zero, entao atualizamos a ultima linha da matriz...
    //    askAnt = m_matriz_RDF_precos[m_pos_mat_RDF_max][ASKK];
    //    bidAnt = m_matriz_RDF_precos[m_pos_mat_RDF_max][BIDD];
    //}
    
    //double spread  = m_tick1.ask-m_tick1.bid;
    //if( spread==0 ) spread = m_tick_size1;
    
    // calculando o resultado em ticks e atribuindo à arvore (linha) anterior...
    double result = ( (m_tick1.ask+m_tick1.bid) - (bidAnt+askAnt) )/m_tick_size1;
    
    if(m_pos_mat_RDF==0){ 
        m_matriz_RDF[m_pos_mat_RDF_max][CLASSE] = result;
    }else{
        m_matriz_RDF[m_pos_mat_RDF - 1][CLASSE] = result;
    }
    //m_matriz_RDF[m_pos_mat_RDF][CLASSE] = result; 
    
    m_pos_mat_RDF++; 
    //ArrayPrint(m_matriz_RDF);
    
    acumularRDFNova(VEL_VOL_TRADE_LIQ,result);
    //ArrayPrint(m_matriz_RDF_nova);
    
    return true;
    
    /*
    double spread2 = spread*2;
    if( m_tick1.bid == bidAnt         && m_tick1.ask == askAnt        ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = ASK_BID        ; m_pos_mat_RDF++; return true;}
    
    if( m_tick1.bid  > bidAnt+spread2 && m_tick1.ask  > askAnt+spread2 ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = ASK_BID_UP_PLUSP; m_pos_mat_RDF++; return true;}
    if( m_tick1.bid  > bidAnt+spread  && m_tick1.ask  > askAnt+spread  ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = ASK_BID_UP_PLUS ; m_pos_mat_RDF++; return true;}
    if( m_tick1.bid  > bidAnt         && m_tick1.ask  > askAnt         ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = ASK_BID_UP      ; m_pos_mat_RDF++; return true;}
    
    if( m_tick1.bid  < bidAnt-spread2 && m_tick1.ask  < askAnt-spread2 ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = ASK_BID_DW_PLUSP; m_pos_mat_RDF++; return true;}
    if( m_tick1.bid  < bidAnt-spread  && m_tick1.ask  < askAnt-spread  ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = ASK_BID_DW_PLUS ; m_pos_mat_RDF++; return true;}
    if( m_tick1.bid  < bidAnt         && m_tick1.ask  < askAnt         ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = ASK_BID_DW      ; m_pos_mat_RDF++; return true;}
    
    if( m_tick1.bid == bidAnt        && m_tick1.ask  < askAnt        ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = ASK_DW    ; m_pos_mat_RDF++; return true;}
    if( m_tick1.bid  > bidAnt        && m_tick1.ask == askAnt        ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = BID_UP    ; m_pos_mat_RDF++; return true;}
    if( m_tick1.bid == bidAnt        && m_tick1.ask  > askAnt        ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = ASK_UP    ; m_pos_mat_RDF++; return true;}
    if( m_tick1.bid  < bidAnt        && m_tick1.ask == askAnt        ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = BID_DW    ; m_pos_mat_RDF++; return true;}
    if( m_tick1.bid  < bidAnt        && m_tick1.ask  > askAnt        ){ m_matriz_RDF[m_pos_mat_RDF][CLASSE] = SPREAD_UP ; m_pos_mat_RDF++; return true;}
    Print(__FUNCTION__, ":-( ERRO!!! SITUACAO NAO PREVISTA AO DEFINIR DIRECAO DO PRECO. m_pos_mat_RDF:",m_pos_mat_RDF);
    ArrayPrint(m_matriz_RDF_precos);
    return false;
    */
}

double m_predict_RDF1 = 0;
void compilarRDF(){
    if( !EA_CALC_REGRESSAO_RDF ) return;
    if(m_matriz_RDF_qtd_voltas == 0) return;
    
  //if( m_rdf.compile(m_matriz_RDF,EA_MAT_RDF_TAMANHO  ,NVARS,QTD_CLASSES,EA_MAT_RDF_TAMANHO,0.5  ) ){
  //if( m_rdf.compile(m_matriz_RDF,EA_MAT_RDF_TAMANHO  ,NVARS,1          ,EA_MAT_RDF_TAMANHO,0.5  ) ){
    if( m_rdf.compile(m_matriz_RDF,EA_MAT_RDF_TAMANHO-1,NVARS,1                             ,0.632) ){ // nova versao que resolve automaticamente a quantidade de arvores a usar...
        double x[NVARS];   
        x[0] = m_est.getVolTradeBuyPorSeg();
        x[1] = m_est.getVolTradeSelPorSeg();
        x[2] = m_est.getVolTradeLiqPorSeg();
        x[3] = m_est.getAceVolBuy();
        x[4] = m_est.getAceVolSel();
        
        double y[];
        m_rdf.processar(x,y);
        m_predict_RDF1 = y[0];
        //ArrayPrint(x);
        //ArrayPrint(y);
    }else{
        ArrayPrint(m_matriz_RDF);
    }
}

void compilarRDFnova(){
    if( !EA_CALC_REGRESSAO_RDF ) return;
    if(m_matriz_RDF_qtd_voltas == 0) return;
    
  //if( m_rdf.compile(m_matriz_RDF,EA_MAT_RDF_TAMANHO,NVARS,QTD_CLASSES,EA_MAT_RDF_TAMANHO,0.5  ) ){
  //if( m_rdf.compile(m_matriz_RDF,EA_MAT_RDF_TAMANHO,NVARS,1          ,EA_MAT_RDF_TAMANHO,0.5  ) ){
    if( m_rdf.compile(m_matriz_RDF_nova,EA_MAT_RDF_TAMANHO_NOVA,EA_MAT_RDF_NOVA_COLS-1, 1, 0.632) ){ // nova versao que resolve automaticamente a quantidade de arvores a usar...
        
        // fazendo a previsao sobre os dados da ultima linha da matriz RDF nova
        double x[EA_MAT_RDF_NOVA_COLS-1];
        int ind = m_pos_mat_RDF_nova-1;
        if(ind<0) ind = m_pos_mat_RDF_max_nova;
        for(int i=0; i<EA_MAT_RDF_NOVA_COLS-1; i++){ x[i] = m_matriz_RDF_nova[ind][i]; }
        
        double y[];
        m_rdf.processar(x,y);
        m_predict_RDF1 = y[0];
        //ArrayPrint(x);
        //ArrayPrint(y);
    }else{
        ArrayPrint(m_matriz_RDF);
    }

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
// 1. Calculo do offset bid/ask em funcao da volatilidade.
//----------------------------------------------------------------------------------------------------
double m_price_ant       = 0;
double m_offset          = 0;
double m_offset_em_ticks = 0;
osc_media m_volat_media;
//----------------------------------------------------------------------------------------------------
void calcularOffset(){
    if( !m_mudou_segundo ) return;
    if(m_price_ant == 0) { m_price_ant = m_tick1.last; return;}
    if(m_price_ant == 0) {printDouble("Erro: Last sem valor.", m_price_ant ); return; }

    //m_offset = m_volat_media.add( pow(m_tick1.last-m_price_ant,2) );
    //m_offset_em_ticks =           log(m_offset);//(m_offset/m_tick_size1)/EA_DIVISOR_OFFSET;

    // testando calculo do offset desde o tamanho da barra media;
    calcLenBarraMedia();
    m_offset          = m_lenBarraMediaEmTicks*EA_DIVISOR_OFFSET;
    m_offset_em_ticks = m_offset;

    m_price_ant = m_tick1.last;

    setOffSetFormadorDeMercado(m_offset_em_ticks);
}
//----------------------------------------------------------------------------------------------------

bool estatistica_estah_integra(){
    // aguardando estatistica acumular pelo menos 80% da sua capacidade
    if(m_est.getLenVetAcumTrade() < double(EA_EST_QTD_SEGUNDOS)*0.8 ){ Print("3:", m_est.getLenVetAcumTrade()," < ",double(EA_EST_QTD_SEGUNDOS)*0.8); return false;}
    return true;
}

//----------------------------------------------------------------------------------------------------
bool estah_no_intervalo_de_negociacao(){

    //if( m_date_atu.hour == 16 && m_date_atu.min == 1){
    //   Print("Break Point!!!!");
    //}

    // informando a mudanca do dia (usada no controle do rebaixamento de saldo maximo da sessao).
    if( m_date_ant.day != m_date_atu.day ){ m_mudou_dia = true; m_time_in_seconds_ini_day = StringToTime( TimeToString( TimeCurrent(), TIME_DATE )); }

    // restricao para nao operar no inicio nem no final do dia...
    if(m_date_atu.hour <   EA_HR_INI_OPERACAO     ) { return false; /*Print("1:", m_date_atu.hour," < " ,EA_HR_INI_OPERACAO);*/ } // operacao antes de 9:00 distorce os testes.
    if(m_date_atu.hour >=  EA_HR_FIM_OPERACAO + 1 ) { return false; /*Print("2:", m_date_atu.hour," >= ",EA_HR_FIM_OPERACAO);*/ } // operacao apos    18:00 distorce os testes.

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
        Print(__FUNCTION__, " m_aguardar_para_abrir_posicao:", m_aguardar_para_abrir_posicao, " milissegundos...");
    }
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

#define KEY_SHIFT  16 //
#define KEY_CTRL   17 //
#define KEY_C      67 // atalho para compra
#define KEY_F      70 // atalho para fechamento de posicao
#define KEY_R      82 // atalho para reversao
#define KEY_V      86 // atalho para venda
void processarAcionamentoDeTecla(int tecla){
    //if( m_acao_posicao == NAO_OPERAR ) return;
    switch( tecla ){
        case KEY_SHIFT: break;
        case KEY_CTRL : break;
        case KEY_C:
           if( TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0 ){
               Print("SHIFT+C foi pressionada. Comprando ativo 2:",m_symb_str2,"...");
               comprarLimitadoManual2();
           }else{
               Print(      "C foi pressionada. Comprando ativo 1:",m_symb_str1,"...");
               comprarLimitadoManual1();
           }
           break;
        case KEY_R:
           if( TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0 ){
               Print("SHIFT+R foi pressionada. Revertendo posicao 2:",m_symb_str2,"...");
               reverterPosicao2();
           }else{
               Print(      "R foi pressionada. Revertendo posicao 1:",m_symb_str1,"...");
               reverterPosicao1();
           }
           break;
        case KEY_V:
           if( TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0 ){
               Print("SHIFT+V foi pressionada. Vendendo ativo 2:",m_symb_str2,"...");
               venderLimitadoManual2();
           }else{
               Print(      "V foi pressionada. Vendendo ativo 1:",m_symb_str1,"...");
               venderLimitadoManual1();
           }
           break;

        case KEY_F:
           if( TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0 ){
                Print("SHIFT+F foi pressionada. Retornando ao modo de operacao anterior:",EnumToString(m_acao_posicao_ant),"...");
                m_acao_posicao = m_acao_posicao_ant; // retornando ao modo de operacao anterior ao fechamento
           }else{
                Print(      "F foi pressionada. Fechando todas as posicoes...");
                if(m_acao_posicao==FECHAR_POSICAO) break;
                m_acao_posicao_ant = m_acao_posicao; // salvando o anterior
                m_acao_posicao = FECHAR_POSICAO; // isso fecha todas as posicoes abertas e cancela todas as ordens pendentes
           }
           break;

        default:
           Print("TECLA nao listada:" ,tecla,":",TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0?"shift":"nao" );
    }
    ChartRedraw();
}

void comprarLimitado1(){ m_trade1.comprarLimit(m_tick1.bid,m_apmb_buy); }
void comprarLimitado2(){ m_trade2.comprarLimit(m_tick2.bid,m_apmb_buy); }
void venderLimitado1 (){ m_trade1.venderLimit (m_tick1.ask,m_apmb_sel); }
void venderLimitado2 (){ m_trade2.venderLimit (m_tick2.ask,m_apmb_sel); }

void comprarLimitadoManual1(){ m_trade1.comprarLimit(m_tick1.bid,m_apmb_man); }
void comprarLimitadoManual2(){ m_trade2.comprarLimit(m_tick2.bid,m_apmb_man); }
void venderLimitadoManual1 (){ m_trade1.venderLimit (m_tick1.ask,m_apmb_man); }
void venderLimitadoManual2 (){ m_trade2.venderLimit (m_tick2.ask,m_apmb_man); }

void reverterPosicao1(){ m_gerentePos1.reverterPosicao(); }
void reverterPosicao2(){ m_gerentePos2.reverterPosicao(); }

//+-----------------------------------------------------------+
//|                                                           |
//+-----------------------------------------------------------+
void OnTradeTransaction( const MqlTradeTransaction& tran,    // transacao
                         const MqlTradeRequest&     req ,    // request
                         const MqlTradeResult&      res   ){ // result
                         
    //Print(__FUNCTION__, " Executando OnTradeTransaction()...");

    //bool           closer          = false;  // true: trade eh um fechamento de posicao
    //bool           toClose         = false;  // true: trade deve ser fechado
    //ulong          toCloseidDeal   = 0    ;  // se toClose=true este serah o ticket  do trade a ser fechado
    //double         toCloseVol      = 0    ;  // se toClose=true este serah o volume  do trade a ser fechado
    //ENUM_DEAL_TYPE toCloseTypeDeal        ;  // se toClose=true este serah o sentido do trade a ser fechado, conforme ENUM_DEAL_TYPE
    //double         toClosePriceIn         ;  // se toClose=true este serah o preco   do trade a ser fechado
    //bool           toCloseOpenPos  = false;  // se toClose=true esta indicarah se a posicao foi aberta agora (primeiraOrdem)


  //if(tran.symbol != m_symb_str1) return; //20210305: correcao BUG estava abrindo posicao com papel diferente do que estah sendo processado.

  //m_pos.onTradeTransaction(tran,req,res,closer,toClose,toCloseidDeal,toCloseVol,toCloseTypeDeal,toClosePriceIn, toCloseOpenPos);

    if( EA_LOGAR_TRADETRANSACTION ) m_pos.logarInCSV(tran,req,res);

    if( m_acao_posicao == NAO_OPERAR     ) return;
    if( m_acao_posicao == FECHAR_POSICAO ) return;

    //if( toClose && tran.symbol != m_symb_str1){
    //    // contando volume total da posicao e...
    //    if( tran.deal_type == DEAL_TYPE_BUY ){
    //        m_volComprasNaPosicao += (tran.volume/m_lots_step1);
    //        //if( estouSemPosicao1() ) setCompradoSoft();
    //    }else{
    //        if( tran.deal_type == DEAL_TYPE_SELL ){
    //            m_volVendasNaPosicao += (tran.volume/m_lots_step1);
    //            //if( estouSemPosicao1() ) setVendidoSoft();
    //        }
    //    }
    //}


  //if( (toClose || closer) && toClosePriceIn > 0 ){
    if( tran.type == TRADE_TRANSACTION_DEAL_ADD && tran.price > 0 ){
        // acionando o fechamento das ordens da posicao...
        //doCloseRajada4(toCloseidDeal,toCloseVol,toCloseTypeDeal,toClosePriceIn,toCloseOpenPos);
        //doCloseRajada4Simples(toClosePriceIn,toCloseVol, tran.symbol);
        //doCloseOposite(toClosePriceIn,toCloseVol, tran.symbol,toCloseTypeDeal);
        doCloseOposite(tran.price,tran.volume, tran.symbol,tran.deal_type); // suspeita de erro em toClosePriceIn,
                                                                            // toCloseTypeDeal e toCloseVol
    }

    /*
    if( toClose==true ){

        // contando volume total da posicao e...
        if( toCloseTypeDeal == DEAL_TYPE_BUY ){
            m_volComprasNaPosicao += (toCloseVol/m_lots_step1);
            //if( estouSemPosicao1() ) setCompradoSoft();
        }else{
            if( toCloseTypeDeal == DEAL_TYPE_SELL ){
                m_volVendasNaPosicao += (toCloseVol/m_lots_step1);
                //if( estouSemPosicao1() ) setVendidoSoft();
            }
        }

        // acionando o fechamento das ordens da posicao...
        doCloseRajada4(toCloseidDeal,toCloseVol,toCloseTypeDeal,toClosePriceIn,toCloseOpenPos);

    }else{

        // Aqui eh fechamento de posicao.
        if(closer){

          //if( m_acao_posicao == HFT_FORMADOR_DE_MERCADO ){
            // Se a posicao estah sendo fechada por uma ordem INX, cancele a ordem de fechamento original(comentario numerico) com preco
            // mais afastado (maior pra posicoes compradas e menor pra posicoes vendidas).
                string comment;
                if( m_pos.getComment(tran.order,comment) ){
                    if( StringFind(comment,m_apmb) > -1 ){
                        // eh uma ordem INX, entao cancele uma ordem numerica mais afastada
                        if( estouComprado1() ){
                            m_trade1.cancelarMaiorOrdemDeVendaComComentarioNumerico();
                        }else{
                            if( estouVendido1() ){
                                m_trade1.cancelarMenorOrdemDeCompraComComentarioNumerico();
                            }
                        }
                    }
                }
          //}
        }
    }
    */
    //if( m_acao_posicao == HFT_FORMADOR_DE_MERCADO ) abrirPosicaoHFTFormadorDeMercado();
    
    //Print(__FUNCTION__, "        Fim OnTradeTransaction()...");
    
}


//-----------------------------------------------------
// Print a cada 10 solicitacoes
//-----------------------------------------------------
int m_qtd_print_intervalo = 10;
int m_qtd_print = m_qtd_print_intervalo;
void print      (string msg,long   val=-1){ if(++m_qtd_print>m_qtd_print_intervalo){Print(msg,":",val);m_qtd_print=0;} }
void printDouble(string msg,double val=-1){ if(++m_qtd_print>m_qtd_print_intervalo){Print(msg,":",val);m_qtd_print=0;} }
//#define LOG(var1,var2) Print(__FUNCTION__,":linha ",__LINE__,":"," :-| ",(var1),":",(var2));
//-----------------------------------------------------

int m_tamanhoBook = 0;
MqlBookInfo m_book[];
//void OnBookEvent(const string &symbol){
void onBookEvent(const string &symbol){
    //Print(__FUNCTION__, " Executando OnBookEvent()...");

   if( !EA_PROCESSAR_BOOK ) return;
   if( !MarketBookGet(symbol, m_book) ) { Print(":-( Falha MarketBookGet. Motivo: ", GetLastError()); return; }

   if(EA_NEGOCIAR_ATIVO_1 && symbol == m_symb_str1){ m_book1.setBook(m_book); } 
   if(EA_NEGOCIAR_ATIVO_2 && symbol == m_symb_str2)  m_book2.setBook();

   if(!EA_NEGOCIAR_ATIVO_1 || symbol != m_symb_str1 ) return;
   if( m_tamanhoBook==0) m_tamanhoBook = ArraySize(m_book);
   if( m_tamanhoBook==0) { Print(":-( Falha book vazio. Motivo: ", GetLastError()); return; }

   //m_est.addBook( TimeCurrent(), m_book, m_tamanhoBook,0.5, m_symb1.TickSize() );
   //Print(__FUNCTION__, " Fim OnBookEvent()...");
}


// calcula o tamanho da barra media nos ultimos xx minutos
double m_lenBarraMediaEmTicks = 0;
void calcLenBarraMedia(){

    if(!m_mudou_segundo) return;
    double   maxMin      = 0 ;
    int      starPos     = 1 ; // desde o periodo anterior
    int      qtdPeriodos = 60; // ateh 60 periodos pra tras
    MqlRates ratesLenBarraMedia[];

    int qtd = CopyRates(m_symb_str1,_Period,starPos,qtdPeriodos,ratesLenBarraMedia);

    for(int i=0; i<qtd; i++){
        maxMin += (ratesLenBarraMedia[i].high - ratesLenBarraMedia[i].low);
    }
    m_lenBarraMediaEmTicks =  (maxMin/m_tick_size1)/(double)qtd;

}

// transforma o tick informativo em tick de trade. Usamos em mercados que nao informam volume ou last nos ticks.
void normalizar2trade(MqlTick& tick){
   if(EA_EST_NORMALIZAR_TICK_2_TRADE){
      m_tick_util1.normalizar2trade(tick);
   }
}

void normalizar2trade1(MqlTick& tick){
   if(EA_EST_NORMALIZAR_TICK_2_TRADE){
      m_tick_util1.normalizar2trade(tick);
   }
}

void normalizar2trade2(MqlTick& tick){
   if(EA_EST_NORMALIZAR_TICK_2_TRADE){
      m_tick_util2.normalizar2trade(tick);
   }
}

void normalizar2trade1(){
   if(EA_EST_NORMALIZAR_TICK_2_TRADE){
      m_tick_util1.normalizar2trade(m_tick1);
   }
}

void normalizar2trade2(){
   if(EA_EST_NORMALIZAR_TICK_2_TRADE){
      m_tick_util2.normalizar2trade(m_tick2);
   }
}
