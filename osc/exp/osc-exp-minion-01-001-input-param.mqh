﻿//+-----------------------------------------            -------------+
//|                                       osc-exp-minion-01-001.mqh  |
//|                                         Copyright 2019, OS Corp. |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao 01.001                                                    |
//| 1. Arquivo de include de parametros a serem obtidos para usar a  |
//|    classe osc_minion_expert.                                     |
//|                                                                  |
//+------------------------------------------------------------------+

//#define SLEEP_PADRAO  50
//#define COMPILE_PRODUCAO

// declarando uma instancia da classe osc_minion_expert (m_exp)...
#include <oslib\osc\exp\osc-exp-minion-01-001.mqh>
osc_minion_expert m_exp;




//defnindo o metodo que passa os parametros recebidos pelo EA pra dentro da classe osc_minion_expert (m_exp)...
void atualizarParametros(){
  //input group "Gerais"
    m_exp.setAcaoPosicao        (EA_ACAO_POSICAO            );
    m_exp.setSpreadMaximoEmTicks(EA_SPREAD_MAXIMO_EM_TICKS  );

  //input group "Volume por Segundo"
    m_exp.setVolSegMaxEntradaPos(EA_VOLSEG_MAX_ENTRADA_POSIC);

  //input group "Volume Aporte"
    m_exp.setVolLoteIni    (EA_VOL_LOTE_INI  ); //VOL_LOTE_INI Vol do lote a ser usado na abertura de posicao qd vol/seg eh L1.
    m_exp.setVolLoteRaj    (EA_VOL_LOTE_RAJ  ); //VOL_LOTE_RAJ Vol do lote a ser usado qd vol/seg eh L1.
    m_exp.setVolMartingale (EA_VOL_MARTINGALE); //VOL_MARTINGALE dobra a quantidade de ticks a cada passo.
    
  //input group "Rajada"
    m_exp.setTamanhoRajada      (EA_TAMANHO_RAJADA          );
    
  //input group "Passo Fixo"
    m_exp.setPassoRajada        (EA_PASSO_RAJ               );// 3 PASSO_RAJ_L1:Incremento de preco, em tick, na direcao contraria a posicao;
    m_exp.setQtdTicks4GainIni   (EA_QTD_TICKS_4_GAIN_INI    );// 3 QTD_TICKS_4_GAIN_INI_L1:Qtd ticks para o gain qd vol/seg eh level 1;
    m_exp.setQtdTicks4GainRaj   (EA_QTD_TICKS_4_GAIN_RAJ    );// 3 QTD_TICKS_4_GAIN_RAJ_L1:Qtd ticks para o gain qd vol/seg eh level 1;

  //input group "Passo dinamico"
    m_exp.setPassoDinamico                  (EA_PASSO_DINAMICO                     );// true PASSO_DINAMICO:tamanho do passo muda em funcao da volatilidade
    m_exp.setPassoDinamicoPorcT4G           (EA_PASSO_DINAMICO_PORC_T4G            );// 1    PASSO_DINAMICO_PORC_TFG: % do TFG para definir o passo.
    m_exp.setPassoDinamicoMin               (EA_PASSO_DINAMICO_MIN                 );// 1    PASSO_DINAMICO_MIN:menor passo possivel.
    m_exp.setPassoDinamicoMax               (EA_PASSO_DINAMICO_MAX                 );// 15   PASSO_DINAMICO_MAX:maior passo possivel.
    m_exp.setPassoDinamicoPorcCanalEntrelaca(EA_PASSO_DINAMICO_PORC_CANAL_ENTRELACA);// 0.02 PASSO_DINAMICO_PORC_CANAL_ENTRELACA
    m_exp.setPassoDinamicoStopQtdContrat    (EA_PASSO_DINAMICO_STOP_QTD_CONTRAT    );// 3    PASSO_DINAMICO_STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
    m_exp.setPassoDinamicoStopChunk         (EA_PASSO_DINAMICO_STOP_CHUNK          );// 2    PASSO_DINAMICO_STOP_CHUNK:tamanho do chunk.
    m_exp.setPassoDinamicoStopPorcCanal     (EA_PASSO_DINAMICO_STOP_PORC_CANAL     );// 1    PASSO_DINAMICO_STOP_PORC_CANAL:porcentagem do canal, usada para calcular o stop_loss dinamico.
    m_exp.setPassoDinamicoStopRedutorRisco  (EA_PASSO_DINAMICO_STOP_REDUTOR_RISCO  );// 1    PASSO_DINAMICO_STOP_REDUTOR_RISCO:porcentagem sobre o tamanho do passo para iniciar saida da posicao.

  //input group "Stops"
    m_exp.setStopTipoControleRisco (EA_STOP_TIPO_CONTROLE_RISCO); // 1    STOP_TIPO_CONTROLE_RISCO, se 1, controle normal. Se 2, controle por proximidade do breakeven.
    m_exp.setStopTicksStopLoss     (EA_STOP_TICKS_STOP_LOSS    ); // 15   STOP_TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
    m_exp.setStopTicksTkProf       (EA_STOP_TICKS_TKPROF       ); // 30   STOP_TICKS_TKPROF:Quantidade de ticks usados no take profit;
    m_exp.setStopRebaixamentoMaxDia(EA_STOP_REBAIXAMENTO_MAX   ); // 300  STOP_REBAIXAMENTO_MAX:preencha com positivo.
    m_exp.setStopObjetivoDia       (EA_STOP_OBJETIVO_DIA       ); // 250  STOP_OBJETIVO_DIA:para se saldo alcancar objetivo do dia.
    m_exp.setStopLoss              (EA_STOP_LOSS               ); //-1200 STOP_LOSS:Valor maximo de perda aceitavel;
    m_exp.setStopQtdContrat        (EA_STOP_QTD_CONTRAT        ); // 10   STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
    m_exp.setStopPorcL1            (EA_STOP_PORC_L1            ); // 1    STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
    m_exp.setStopMinutos           (EA_STOP_10MINUTOS          ); // 0    STOP_10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
    m_exp.setStopTicksTolerSaida   (EA_STOP_TICKS_TOLER_SAIDA  ); // 1    STOP_TICKS_TOLER_SAIDA: qtd de ticks a aguardar nas saidas stop;

  //m_exp.set input group "Entrelacamento"
    m_exp.setEntrelacaPeriodoCoef(EA_ENTRELACA_PERIODO_COEF);// 6    ENTRELACA_PERIODO_COEF: periodo p/calc coef entrelacamento.
    m_exp.setEntrelacaCoefMin    (EA_ENTRELACA_COEF_MIN    );// 0.40 ENTRELACA_COEF_MIN em porcentagem.
    m_exp.setEntrelacaCanalMax   (EA_ENTRELACA_CANAL_MAX   );// 30   ENTRELACA_CANAL_MAX: tamanho maximo em ticks do canal de entrelacamento.
    m_exp.setEntrelacaCanalStop  (EA_ENTRELACA_CANAL_STOP  );// 35   ENTRELACA_CANAL_STOP:StopLoss se canal maior que este parametro.
  
  //input group "Regiao de compra e venda"
    m_exp.setRegiaoBuySell           (EA_REGIAO_BUY_SELL     );// 0.3   REGIAO_BUY_SELL regiao de compra e venda nas extremidades do canal de entrelacamento.
    m_exp.setRegiaoBuySellUsaCanalDia(EA_USA_REGIAO_CANAL_DIA);// false USA_REGIAO_CANAL_DIA usa a regiao do canal diario (true) ou canal de entrelacamento(false) para calcular regiao de compra venda.

  //input group "volatilidade e inclinacoes"
	m_exp.setVolatAlta            (EA_VOLAT_ALTA              );// 1.5 VOLAT_ALTA Volatilidade a considerar alta(%). Calculada a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
	m_exp.setVolat4sAltaPorc      (EA_VOLAT4S_ALTA_PORC       );// 1.0 VOLAT4S_ALTA_PORC Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media abrir posicao.
	m_exp.setVolat4sStopPorc      (EA_VOLAT4S_STOP_PORC       );// 1.5 VOLAT4S_STOP_PORC Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media para stopar.
	m_exp.setVolat4sMin           (EA_VOLAT4S_MIN             );// 1.5 VOLAT4S_MIN Acima deste valor, nao abre posicao.
	m_exp.setInclAlta             (EA_INCL_ALTA               );// 0.9 INCL_ALTA Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
	m_exp.setInclMin              (EA_INCL_MIN                );// 0.1 INCL_MIN Inclinacao minima para entrar no trade.
	m_exp.setMinDeltaVol          (EA_MIN_DELTA_VOL           );// 10  MIN_DELTA_VOL %delta vol minimo para entrar na posicao
	m_exp.setMinDeltaVolAceleracao(EA_MIN_DELTA_VOL_ACELERACAO);// 1   MIN_DELTA_VOL_ACELERACAO Aceleracao minima da %delta vol para entrar na posicao

  //input group "entrada na posicao"
    m_exp.setToleranciaEntrada(EA_TOLERANCIA_ENTRADA);// 1 TOLERANCIA_ENTRADA algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao 

  //input group "show_tela"
    m_exp.setShowTela           (EA_SHOW_TELA                       );// false SHOW_TELA:mostra valor de variaveis na tela;
    m_exp.setShowTelaLinhasAcima(EA_SHOW_TELA_LINHAS_ACIMA          );// 0     SHOW_TELA_LINHAS_ACIMA:permite impressao na parte inferior da tela;
    m_exp.setShowTelaPermOpenPos(EA_SHOW_STR_PERMISSAO_ABRIR_POSICAO);// false SHOW_STR_PERMISSAO_ABRIR_POSICAO:condicoes p/abrir posicao;
    m_exp.setShowCanalPrecos    (EA_SHOW_CANAL_PRECOS               );// false SHOW_CANAL_PRECOS:mostra o canal de precos na tela;
  
  //input group "diversos"
	m_exp.setDebug(EA_DEBUG);// false          DEBUG se true, grava informacoes de debug no log do EA.
	m_exp.setMagic(EA_MAGIC);// 20200507001001 MAGIC Numero magico desse EA. yyyymm-pvv-vvvv-vvv.

  //input group "tarifa b3-minidolar"
    m_exp.setDolarTarifa(EA_DOLAR_TARIFA);// 5.0 DOLAR_TARIFA usado para calcular a tarifa do dolar.

  //input group "risco"
    m_exp.setMaxVolEmRisco  (EA_MAX_VOL_EM_RISCO );// 200 MAX_VOL_EM_RISCO Qtd max de contratos em risco; Sao os contratos pendentes da posicao.
    m_exp.setDxTraillingStop(EA_DX_TRAILLING_STOP);// 1.0 DX_TRAILLING_STOP % do DX1 para fazer o trailling stop
    
  //input group "horario de operacao"
    m_exp.setHrIniOperacao(EA_HR_INI_OPERACAO);// 09 Hora ini operacao;
    m_exp.setMiIniOperacao(EA_MI_INI_OPERACAO);// 30 Min  ini operacao;
    m_exp.setHrFimOperacao(EA_HR_FIM_OPERACAO);// 18 Hora fim operacao;
    m_exp.setMiFimOperacao(EA_MI_FIM_OPERACAO);// 50 Min  fim operacao;
    
  //input group "sleep e timer"
    m_exp.setSleepIniOper   (EA_SLEEP_INI_OPER   );// 60  SLEEP_INI_OPER Aguarda estes segundos para iniciar abertura de posicoes.
    m_exp.setSleepAtraso    (EA_SLEEP_ATRASO     );// 0   SLEEP_TESTE_ONLINE atraso em milisegundos antes de enviar ordens.
    m_exp.setQtdMiliSegTimer(EA_QTD_MILISEG_TIMER);// 250 QTD_MILISEG_TIMER Tempo de acionamento do timer.

}

//enum ENUM_TIPO_ENTRADA_PERMITDA{
//     ENTRADA_NULA              , //ENTRADA_NULA  Nao permite abrir posicoes.
//     ENTRADA_BUY               , //ENTRADA_BUY   Soh abre posicoes de compra.
//     ENTRADA_SELL              , //ENTRADA_SELL  Soh abre posicoes de venda.
//     ENTRADA_TODAS               //ENTRADA_TODAS Abre qualquer tipo de posicao.
//};

//---------------------------------------------------------------------------------------------
input group "Gerais"
input ENUM_TIPO_OPERACAO EA_ACAO_POSICAO            = FECHAR_POSICAO; //ACAO_POSICAO Forma de operacao do EA.
input int                EA_SPREAD_MAXIMO_EM_TICKS  = 4;              //SPREAD_MAXIMO_EM_TICKS Se for maior que o maximo, nao abre novas posicoes.
//
input group "Volume por Segundo"
input int EA_VOLSEG_MAX_ENTRADA_POSIC = 150; //VOLSEG_MAX_ENTRADA_POSIC: vol/seg maximo para entrar na posicao.

input group "Volume Aporte"
input int  EA_VOL_LOTE_INI   =     1; //VOL_LOTE_INI Vol do lote a ser usado na abertura de posicao qd vol/seg eh L1.
input int  EA_VOL_LOTE_RAJ   =     1; //VOL_LOTE_RAJ Vol do lote a ser usado qd vol/seg eh L1.
input bool EA_VOL_MARTINGALE = false; //VOL_MARTINGALE dobra a quantidade de ticks a cada passo.

input group "Rajada"
input int EA_TAMANHO_RAJADA  = 3;    //TAMANHO_RAJADA;

input group "Passo Fixo"
input int EA_PASSO_RAJ            = 3; //PASSO_RAJ Incremento de preco, em tick, na direcao contraria a posicao;
input int EA_QTD_TICKS_4_GAIN_INI = 3; //QTD_TICKS_4_GAIN_INI Qtd ticks para o gain qd vol/seg eh level 1;
input int EA_QTD_TICKS_4_GAIN_RAJ = 3; //QTD_TICKS_4_GAIN_RAJ Qtd ticks para o gain qd vol/seg eh level 1;

//-------------------------------------------------------------------------------------------
input group "Passo dinamico"
input bool   EA_PASSO_DINAMICO                      = true; //PASSO_DINAMICO:tamanho do passo muda em funcao da volatilidade
input double EA_PASSO_DINAMICO_PORC_T4G             = 1   ; //PASSO_DINAMICO_PORC_TFG: % do TFG para definir o passo.
input int    EA_PASSO_DINAMICO_MIN                  = 1   ; //PASSO_DINAMICO_MIN:menor passo possivel.
input int    EA_PASSO_DINAMICO_MAX                  = 15  ; //PASSO_DINAMICO_MAX:maior passo possivel.
input double EA_PASSO_DINAMICO_PORC_CANAL_ENTRELACA = 0.02; //PASSO_DINAMICO_PORC_CANAL_ENTRELACA
input int    EA_PASSO_DINAMICO_STOP_QTD_CONTRAT     = 3   ; //PASSO_DINAMICO_STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
input int    EA_PASSO_DINAMICO_STOP_CHUNK           = 2   ; //PASSO_DINAMICO_STOP_CHUNK:tamanho do chunk.
input double EA_PASSO_DINAMICO_STOP_PORC_CANAL      = 1   ; //PASSO_DINAMICO_STOP_PORC_CANAL:porcentagem do canal, usada para calcular o stop_loss dinamico.
input double EA_PASSO_DINAMICO_STOP_REDUTOR_RISCO   = 1   ; //PASSO_DINAMICO_STOP_REDUTOR_RISCO:porcentagem sobre o tamanho do passo para iniciar saida da posicao.

input group "Stops"
input int    EA_STOP_TIPO_CONTROLE_RISCO =  1    ; //STOP_TIPO_CONTROLE_RISCO, se 1, controle normal. Se 2, controle por proximidade do breakeven.
input int    EA_STOP_TICKS_STOP_LOSS     =  15   ; //STOP_TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
input int    EA_STOP_TICKS_TKPROF        =  30   ; //STOP_TICKS_TKPROF:Quantidade de ticks usados no take profit;
input int    EA_STOP_REBAIXAMENTO_MAX    =  300  ; //STOP_REBAIXAMENTO_MAX:preencha com positivo.
input int    EA_STOP_OBJETIVO_DIA        =  250  ; //STOP_OBJETIVO_DIA:para se saldo alcancar objetivo do dia.
input int    EA_STOP_LOSS                = -1200 ; //STOP_LOSS:Valor maximo de perda aceitavel;
input int    EA_STOP_QTD_CONTRAT         =  10   ; //STOP_QTD_CONTRAT:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
input double EA_STOP_PORC_L1             =  1    ; //STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
input int    EA_STOP_10MINUTOS           =  0    ; //STOP_10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
input int    EA_STOP_TICKS_TOLER_SAIDA   =  1    ; //STOP_TICKS_TOLER_SAIDA: qtd de ticks a aguardar nas saidas stop;

input group "Entrelacamento"
input int    EA_ENTRELACA_PERIODO_COEF = 6   ;//ENTRELACA_PERIODO_COEF: periodo p/calc coef entrelacamento.
input double EA_ENTRELACA_COEF_MIN     = 0.40;//ENTRELACA_COEF_MIN em porcentagem.
input int    EA_ENTRELACA_CANAL_MAX    = 30  ;//ENTRELACA_CANAL_MAX: tamanho maximo em ticks do canal de entrelacamento.
input int    EA_ENTRELACA_CANAL_STOP   = 35  ;//ENTRELACA_CANAL_STOP:StopLoss se canal maior que este parametro.

input group "Regiao de compra e venda"
input double EA_REGIAO_BUY_SELL       = 0.3  ; //REGIAO_BUY_SELL regiao de compra e venda nas extremidades do canal de entrelacamento.
input bool   EA_USA_REGIAO_CANAL_DIA  = false; //USA_REGIAO_CANAL_DIA usa a regiao do canal diario (true) ou canal de entrelacamento(false) para calcular regiao de compra venda.

input group "volatilidade e inclinacoes"
input double EA_VOLAT_ALTA                = 1.5; //VOLAT_ALTA Volatilidade a considerar alta(%). Calculada a volatilidade como a porcentagem da tamanho da barra atual em relacao ao canal de ofertas;
input double EA_VOLAT4S_ALTA_PORC         = 1.0; //VOLAT4S_ALTA_PORC Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media abrir posicao.
input double EA_VOLAT4S_STOP_PORC         = 1.5; //VOLAT4S_STOP_PORC Porcentagem que a volatilidade por segundo pode ser maior que a volatilidade por segundo media para stopar.
input double EA_VOLAT4S_MIN               = 1.5; //VOLAT4S_MIN Acima deste valor, nao abre posicao.
input double EA_INCL_ALTA                 = 0.9; //INCL_ALTA Verifique o tipo de entrada pra saber se eh permitido acima dessa inclinacao.
input double EA_INCL_MIN                  = 0.1; //INCL_MIN Inclinacao minima para entrar no trade.
input int    EA_MIN_DELTA_VOL             = 10 ; //MIN_DELTA_VOL %delta vol minimo para entrar na posicao
input int    EA_MIN_DELTA_VOL_ACELERACAO  = 1  ; //MIN_DELTA_VOL_ACELERACAO Aceleracao minima da %delta vol para entrar na posicao

input group "entrada na posicao"
input int EA_TOLERANCIA_ENTRADA = 1;   //TOLERANCIA_ENTRADA algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao 

input group "show_tela"
input bool EA_SHOW_TELA                        = false; //SHOW_TELA:mostra valor de variaveis na tela;
input int  EA_SHOW_TELA_LINHAS_ACIMA           = 0    ; //SHOW_TELA_LINHAS_ACIMA:permite impressao na parte inferior da tela;
input bool EA_SHOW_STR_PERMISSAO_ABRIR_POSICAO = false; //SHOW_STR_PERMISSAO_ABRIR_POSICAO:condicoes p/abrir posicao;
input bool EA_SHOW_CANAL_PRECOS                = false; //SHOW_CANAL_PRECOS:canal de precos;


input group "diversos"
input bool EA_DEBUG = false         ; //DEBUG se true, grava informacoes de debug no log do EA.
input long EA_MAGIC = 20200507001001; //MAGIC Numero magico desse EA. yyyymm-pvv-vvvv-vvv.

////input group "estrategia distancia do preco"
////#define EA_TICKS_ENTRADA_DIST_PRECO 1 //TICKS_ENTRADA_DIST_PRECO:Usado na entrada tipo HFT_DISTANCIA_PRECO. Distancia do preco para entrar na proxima posicao; .
////
////input group "estrategia distancia da media"
////#define EA_TICKS_ENTRADA_DIST_MEDIA 2 //TICKS_ENTRADA_DIST_MEDIA:Usado na entrada tipo HFT_DISTANCIA_DA_MEDIA. Distancia da media para entrar na proxima posicao; .
////
////input group "estrategia HFT_FLUXO_ORDENS"
////#define EA_PROB_UPDW                0.8 //PROB_UPDW:probabilidade do preco subir ou descer em funcao do fluxo de ordens;

input group "tarifa b3-minidolar"
input double EA_DOLAR_TARIFA = 5.0; //DOLAR_TARIFA usado para calcular a tarifa do dolar.

//input group "estrategia desbalanceamento"
//input double EA_DESBALAN_UP0 = 0.8 ; //DESBALAN_UP0:Desbalanceamento na primeira fila do book para comprar na estrategia de desbalanceamento.
//input double EA_DESBALAN_DW0 = 0.2 ; //DESBALAN_DW0:Desbalanceamento na primeira fila do book para vender  na estrategia de desbalanceamento.
//input double EA_DESBALAN_UP1 = 0.7 ; //DESBALAN_UP1:Desbalanceamento na segunda fila do book para comprar na estrategia de desbalanceamento.
//input double EA_DESBALAN_DW1 = 0.3 ; //DESBALAN_DW1:Desbalanceamento na segunda fila do book para vender  na estrategia de desbalanceamento.
//input double EA_DESBALAN_UP2 = 0.65; //DESBALAN_UP2:Desbalanceamento na terceira fila do book para comprar na estrategia de desbalanceamento.
//input double EA_DESBALAN_DW2 = 0.35; //DESBALAN_DW2:Desbalanceamento na terceira fila do book para vender  na estrategia de desbalanceamento.
//input double EA_DESBALAN_UP3 = 0.6 ; //DESBALAN_UP3:Desbalanceamento na quarta fila do book para comprar na estrategia de desbalanceamento.
//input double EA_DESBALAN_DW3 = 0.4 ; //DESBALAN_DW3:Desbalanceamento na quarta fila do book para vender  na estrategia de desbalanceamento.

//input group "estrategia HFT_PRIORIDADE_NO_BOOK"
//input int EA_TICKS_ENTRADA_BOOK = 4; //TICKS_ENTRADA_BOOK:fila do book onde iniciam as ordens.


input group "risco"
input int    EA_MAX_VOL_EM_RISCO  = 200;// MAX_VOL_EM_RISCO Qtd max de contratos em risco; Sao os contratos pendentes da posicao.
input double EA_DX_TRAILLING_STOP = 1.0;// DX_TRAILLING_STOP % do DX1 para fazer o trailling stop

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
//#define FEIRA07_GERAR_SQL_LOG     false  // Se true grava comandos sql no log para insert do book em tabela postgres.
//#define FEIRA01_DEBUG             false  // se true, grava informacoes de debug no log.
//#define FEIRA04_QTD_BAR_PROC_HIST 0      // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
//#define FEIRA05_BOOK_OUT          0      // Porcentagem das extremidades dos precos do book que serão desprezados.
//#define FEIRA99_ADD_IND_2_CHART   true   // Se true apresenta o idicador feira no grafico.

input group "classe estatistica"
input int  EA_EST_QTD_SEGUNDOS   = 21  ;   // EST_QTD_SEGUNDOS Quantidade de segundos que serao acumulads para calcular as medias.
input bool EA_EST_PROCESSAR_BOOK = true;   // EST_PROCESSAR_BOOK:se true, processa o book de ofertas.

//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
input group "horario de operacao"
input int EA_HR_INI_OPERACAO = 09; // HR_INI_OPERACAO Hora ini operacao;
input int EA_MI_INI_OPERACAO = 30; // MI_INI_OPERACAO Min ini operacao;
input int EA_HR_FIM_OPERACAO = 18; // HR_FIM_OPERACAO Hora fim operacao;
input int EA_MI_FIM_OPERACAO = 50; // MI_FIM_OPERACAO Min fim operacao;
//---------------------------------------------------------------------------------------------

input group "sleep e timer"
input int EA_SLEEP_INI_OPER    = 21 ; // SLEEP_INI_OPER Aguarda estes segundos para iniciar abertura de posicoes.
input int EA_SLEEP_ATRASO      = 0  ; // SLEEP_TESTE_ONLINE atraso em milisegundos antes de enviar ordens.
input int EA_QTD_MILISEG_TIMER = 250; // QTD_MILISEG_TIMER Tempo de acionamento do timer.
//---------------------------------------------------------------------------------------------

