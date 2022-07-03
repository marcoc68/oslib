//+------------------------------------------------------------------+
//|                                         ose-p7-004-003-06-ns.mq5 |
//|                                          Copyright 2022, OS Corp |
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
//|    - Retira todas as classes nao usadas, tais como:              |
//|      canal, pairtradin, estatistica, etc.                        |
//|                                                                  |
//+------------------------------------------------------------------+

#define COMPILE_PRODUCAO

#property copyright "Copyright 2022, OS Corp."
#property link      "http://www.os.org"
#property version   "4.003"

#include <Trade/SymbolInfo.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <oslib/osc-tick-util.mqh>
#include <oslib/osc/osc-minion-trade-03.mqh>                 // executa ordens de neociacao
#include <oslib/osc/osc-minion-trade-estatistica.mqh>        // resumo das transacoes no dia
#include <oslib/osc/trade/osc_position.mqh>                  // 
#include <oslib/osc/exp/C0004GerentePosicao.mqh>             // 
#include <oslib/osc/cp/osc-pc-p7-004-003-06-book-signal.mqh> // painel de controle
#include <oslib/osc/data/osc-book.mqh>                       // implemantacao do algoritmo de gerenciamento do book.
//#include <oslib/osc/data/osc-vetor-fila-item-volume.mqh>
#include <oslib/osc/data/osc-vet-circular-volume.mqh>
#include <oslib/os-lib.mq5>

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
     HFT_FORMADOR_DE_MERCADO_BOOK         , //HFT_FORMADOR_DE_MERCADO_BOOK
     HFT_FORMADOR_DE_MERCADO_VOL            //HFT_FORMADOR_DE_MERCADO_VOL
};

//---------------------------------------------------------------------------------------------
  input group "Gerais";
  input ENUM_TIPO_OPERACAO         EA_ACAO_POSICAO            = HFT_FORMADOR_DE_MERCADO_VOL ; //*EA_ACAO_POSICAO:Forma de operacao do EA.
  input ENUM_TIPO_ENTRADA_PERMITDA EA_TIPO_ENTRADA_PERMITIDA  = ENTRADA_TODAS               ; //*TIPO_ENTRADA_PERMITIDA Tipos de entrada permitidas (sel,buy,ambas e nenhuma)
  input double                     EA_MAX_VOL_POSICAO         =  30                         ; //*MAX_VOL_POSICAO. reduz volume para nao passar desse numero.
  input double                     EA_SPREAD_MAXIMO_EM_TICKS  =  20                         ; //*SPREAD_MAXIMO_EM_TICKS. Se for maior que o maximo, nao abre novas posicoes.
  input int                        SLEEP_TESTE                =  0                          ; //*ERROOOOOOOOOOOOO SLEEP_TESTE nao pode em producao

  input group "=== Estratégias book/volume ===";
  input int    EA_LEVEL_ENTRADA    = 1 ; //*ERROOOOOOOOOOOOO LEVEL_ENTRADA    use 1 em producao
//input int    EA_LEVEL_FECHAMENTO = 0 ; //*ERROOOOOOOOOOOOO LEVEL_FECHAMENTO use 0 em producao
  input int    EA_BOOK_DEEP1       = 16; //*BOOK_DEEP1 profundidade do book
  #define      EA_BOOK_IMBALANCE1   0.1  // BOOK_IMBALANCE1 limiar para definir direcao do movimento
  input int    EA_QTD_SEG_VOL_IMBALANCE = 180  ; //QTD_SEG_VOL_IMBALANCE qtd seg calc vol imbalance.
  input int    EA_QTD_TIK_VOL_IMBALANCE = 1000 ; //QTD_TIK_VOL_IMBALANCE qtd ticks calc vol imbalance.
  input int    EA_TIMER_VOL_IMBALANCE   = 15   ; //TIMER_VOL_IMBALANCE qtd seg entre calculos vol imbalance.
  input double EA_VOL_IMBALANCE         = 0.15 ; //VOL_IMBALANCE % para considerar o vol desbalanceado.
  input bool   EA_PROCESSAR_BOOK        = true ; //PROCESSAR_BOOK
  
  //input group "=== RAJADA e Formador de Mercado ==="
  #define      EA_TAMANHO_RAJADA                            3     //TAMANHO_RAJADA;
  #define      EA_LAG_RAJADA1                               4     //LAG_RAJADA1
  #define      EA_FECHA_POSICAO_NO_BREAK_EVEN               false //FECHA_POSICAO_NO_BREAK_EVEN

  input group "=== Entrada na posicao ===";
  input int    EA_TOLERANCIA_ENTRADA       = 2 ; //*TOLERANCIA_ENTRADA em ticks: algumas estrategias permitem uma tolerancia do preco em ticks para entrada na posicao.
                                                 // em producao, use o EA_LEVEL_ENTRADA + 1
  input int    EA_VOL_LOTE_INI_1           = 1 ; //*VOL_LOTE_INI_1 Vol do lote na abertura de posicao.
  input double EA_QTD_TICKS_4_GAIN_INI_1   = 1 ; //*TICKS_4_GAIN_INI_1 Qtd ticks para o gain;
  input int    EA_QTD_TICKS_4_GAIN_MIN_1   = 1 ; //*QTD_TICKS_4_GAIN_MIN_1 menor alvo inicial possivel;
  input int    EA_TARIFA_TESTE             = 0 ; //*TARIFA_TESTE:tarifa de teste. cobra seu valor por volume de trade vencedor. use quando t4g=2 e tarifa=1;
  input int    EA_DESLOC_T4G_TESTE         = 0 ; //*DESLOC_T4G_TESTE:deslocamento do T4G. Use zero em producao e 1 em teste;

  input group "=== Database ===";
  input string EA_DBNAME        = "oslib7"; //DBNAME nome do banco de dados que guardarah o historico coletados dos books
  input bool   EA_REGISTRA_BOOK =  false  ; //*REGISTRA_BOOK se grava book em banco de dados

  #define      EA_LOGAR_TRADETRANSACTION            false  //LOGAR_TRADETRANSACTION

//-------------------------------------------------------------------------------------------
input group "Passo dinamico"
input bool   EA_PASSO_DINAMICO                  = true ; //PASSO_DINAMICO:tamanho do passo muda em funcao da volatilidade
input double EA_PASSO_DINAMICO_PORC_BARRA_MEDIA = 0.20 ; //PASSO_DINAMICO_PORC_BARRA_MEDIA: % da barra media para definir o T4G.
input double EA_PASSO_DINAMICO_PORC_T4G         = 0.0  ; //PASSO_DINAMICO_PORC_TFG: % do TFG por volume na posicao para definir o passo.
//-------------------------------------------------------------------------------------------
//
  //input group "STOP PARCIAL"
  #define EA_STOP_PARCIAL_ATIVAR                   false //*STOP_PARCIAL_ATIVAR
  #define EA_STOP_PARCIAL_FIRE_VOLUME_TOT          6     //*STOP_PARCIAL_FIRE_VOLUME_TOT
  #define EA_STOP_PARCIAL_FIRE_PORC_LUCRO_POSICAO  0.8   //*STOP_PARCIAL_FIRE_PORC_LUCRO_POSICAO

  input group "=== STOP LOSS ===";
  input int    EA_STOP_TICKS_STOP_LOSS   =  0    ; // STOP_TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
  input int    EA_STOP_TICKS_TKPROF      =  0    ; // STOP_TICKS_TKPROF:Quantidade de ticks usados no take profit;
  input double EA_STOP_REBAIXAMENTO_MAX  =  0    ; // STOP_REBAIXAMENTO_MAX:preencha com positivo.
  input double EA_STOP_OBJETIVO_DIA      =  0    ; // STOP_OBJETIVO_DIA:para se saldo alcancar objetivo do dia.
  input double EA_STOP_LOSS              =  0    ; //*STOP_LOSS:Valor maximo de perda aceitavel;
  input int    EA_STOP_TICKS_TOLER_SAIDA =  1    ; // STOP_TICKS_TOLER_SAIDA: qtd de ticks a aguardar nas saidas stop;
  input int    EA_MAX_TMP_FECHAM_POSICAO =  2    ; // MAX_TMP_FECHAM_POSICAO depois desse tempo, forca o fechamento da posicao

  #define      EA_STOP_CHUNK                10     //STOP_CHUNK:A partir dessa qtd contratos totais na posicao, comeca a controlar seu fechamento.
  #define      EA_STOP_PORC_L1              1      //STOP_PORC_L1:Porc qtd contratos totais da posicao em reais para a saida;
  #define      EA_STOP_10MINUTOS            0      //STOP_10MINUTOS:fecha a posicao aberta a mais de XX segundos, se xx eh dif de zero.
  #define      EA_STOP_QTD_CONTRATOS_PENDENTES 0   //STOP_QTD_CONTRATOS_PENDENTES fecha posic se qtd contrat maior que este
//
  input group "=== Show_tela ===";
  input bool   EA_SHOW_CONTROL_PANEL               = false  ;//*SHOW_CONTROL_PANEL mostra painel de controle;
  input bool   EA_SHOW_TELA                        = false  ;//*SHOW_TELA:mostra valor de variaveis na tela;

//input group "diversos"
#define      EA_MAGIC         22050700400306  //MAGIC: Numero magico desse EA. yy-mm-vv-vvv-vvv-vv.
#define      EA_DOLAR_TARIFA  6.0             //double DOLAR_TARIFA:usado para calcular a tarifa do dolar.
//---------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
input group "=== Horario de operacao ===";
input int    EA_HR_INI_OPERACAO   = 09; // *Hora   de inicio da operacao;
input int    EA_MI_INI_OPERACAO   = 05; // *Minuto de inicio da operacao;
input int    EA_HR_FIM_OPERACAO   = 17; // *Hora   de fim    da operacao;
input int    EA_MI_FIM_OPERACAO   = 40; // *Minuto de fim    da operacao;
input int    EA_HR_FECHAR_POSICAO = 17; // *HR_FECHAR_POSICAO fecha todas as posicoes;
input int    EA_MI_FECHAR_POSICAO = 45; // *MI_FECHAR_POSICAO fecha todas as posicoes;
//---------------------------------------------------------------------------------------------
//
input group "=== Sleep e timer ===";
input int    EA_SLEEP_INI_OPER     =  05  ;//*SLEEP_INI_OPER:Aguarda estes segundos para iniciar abertura de posicoes.
input int    EA_QTD_MILISEG_TIMER  =  250 ;//*QTD_MILISEG_TIMER:Tempo de acionamento do timer.
//---------------------------------------------------------------------------------------------

ENUM_TIPO_OPERACAO         m_acao_posicao     = NAO_OPERAR;
ENUM_TIPO_OPERACAO         m_acao_posicao_ant = NAO_OPERAR;
MqlDateTime                m_date;
string                     m_name = "OSE-P7-004-003-06-ns"; // operacao manual assistida por robo
osc_db                     m_db                      ;
CSymbolInfo                m_symb1                   ;
CPositionInfo              m_posicao1                ;
CAccountInfo               m_cta                     ;
C004GerentePosicao         m_gerentePos1             ;
osc_vet_circular_volume    m_vet_vol                 ; // vetor circular para acumulacao de volumes

double        m_tick_size1                    ;// alteracao minima do preco em pontos para o simbolo 1.
double        m_tick_value1                   ;// valor do tick na moeda do ativo 1.
double        m_lots_min                      ;// tamaho do menor lote aceitavel pelo simbolo.
double        m_lots_step1                    ;// alteracao minima de volume para o ativo 1.
double        m_spread                        ;// spread.
double        m_point1                        ;// um ponto do ativo 1.
double        m_point_value1                  ;// valor de um ponto na moeda do ativo 1.
double        m_stopLossOrdens                ;// stop loss;
double        m_tkprof                        ;// take profit;
double        m_distMediasBook                ;// Distancia entre as medias Ask e Bid do book.

osc_minion_trade                m_trade1           ; // operacao com ordens
osc_minion_trade_estatistica    m_trade_estatistica; // estatistica de trades
osc_control_panel_p7_004_003_06 m_cp               ; // painel de controle
osc_position                    m_pos              ; // processamento do OnTradeTransaction
osc_tick_util                   m_tick_util1       ; // para simular ticks de trade em bolsas que nao informam last/volume.
osc_book                        m_book1            ;

bool   m_comprado              =  false;
bool   m_vendido               =  false;

double m_breakeven            = 0; // breakeven sem normalizar
double m_precoPosicao         = 0; // valor medio de entrada da posicao (breakeven normalizado)
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
double m_posicaoProfit = 0;
double m_ask           = 0;
double m_bid           = 0;
double m_ask_stplev    = 0; // ask - stop level
double m_bid_stplev    = 0; // bid + stop level
double m_val_order_4_gain = 0;

string   m_apmb_man   = "INM"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb       = "IN" ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_sel   = "INS"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_apmb_buy   = "INB"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string   m_strRajada  = "RJ" ; //string que identifica rajadas de abertura de novas posicoes.
string   m_comment_fixo;

double m_maior_sld_do_dia = 0;
double m_sld_sessao_atu   = 0;
double m_rebaixamento_atu = 0;
bool   m_mudou_dia        = false;
bool   m_acionou_stop_rebaixamento_saldo = false;
int    m_spread_maximo_in_points = 0;
double m_stop_level_in_price = 0;

long   m_tempo_posicao_atu   = 0;
long   m_tempo_posicao_ini   = 0;

double m_qtd_ticks_4_gain_new  = 0;
double m_qtd_ticks_4_gain_ini_1  = 0;
double m_vol_lote_ini1       = 0;

// controles de apresentacao das variaveis de debug na tela...
string m_str_linhas_acima   = "";
string m_release = "[RELEASE TESTE]";

// string com o simbolo sendo operado
string m_symb_str1;

// milisegundos que devem ser aguardados antes de iniciar a operacao
int m_aguardar_para_abrir_posicao = 0;

// algumas estrategias permitem uma tolerancia do preco para entrada na posicao...
double m_room1 = 0;

datetime m_time_in_seconds_ini_day = TimeCurrent();

ENUM_TIPO_ENTRADA_PERMITDA m_tipo_entrada_permitida = EA_TIPO_ENTRADA_PERMITIDA;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//testando a classe osc_canal...
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
    m_gerentePos1.inicializar(m_symb_str1,EA_MAGIC,EA_LAG_RAJADA1,EA_TAMANHO_RAJADA);
    m_gerentePos1.setSpread(             m_tick_size1);
    m_gerentePos1.setT4gMin((int)(EA_QTD_TICKS_4_GAIN_INI_1+EA_DESLOC_T4G_TESTE) );

    // estatistica de trade...
    m_time_in_seconds_ini_day = StringToTime( TimeToString( TimeCurrent(), TIME_DATE ) );
    m_trade_estatistica.initialize();
    m_trade_estatistica.setCotacaoMoedaTarifaWDO(EA_DOLAR_TARIFA);

    m_spread_maximo_in_points = (int)( (EA_SPREAD_MAXIMO_EM_TICKS*m_tick_size1)/m_point1 );
    m_stop_level_in_price     = normalizar1( m_symb1.StopsLevel()*m_point1               );

    m_room1         = normalizar1( (EA_TOLERANCIA_ENTRADA*m_tick_size1)/m_point1 ); // tolerancia permitida para entrada em algumas estrategias

    m_maior_sld_do_dia = (m_maior_sld_do_dia==0)?m_cta.Balance():m_maior_sld_do_dia; // saldo da conta no inicio da sessao;
    m_sld_sessao_atu   = (m_sld_sessao_atu  ==0)?m_cta.Balance():m_sld_sessao_atu  ;
    m_capitalInicial   = (m_capitalInicial  ==0)?m_cta.Balance():m_capitalInicial  ;
    
    m_vet_vol.initialize(EA_QTD_TIK_VOL_IMBALANCE); // tamanho da janela de calculo do desbalanceamento do volume (em ticks);

    m_comment_fixo = "LOGIN:"         + DoubleToString(m_cta.Login(),0) +
                     "  TRADEMODE:"   + m_cta.TradeModeDescription()    +
                     "  MARGINMODE:"  + m_cta.MarginModeDescription()   +
                     " "              + m_release;

    Comment(m_comment_fixo);

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

    m_tick_util1.setTickSize(m_symb1.TickSize(), m_symb1.Digits() );

    // carregando a ultima hora de ticks...
    datetime from = (TimeCurrent()-(60*60) ) ; // minutos atras
    MqlTick ticks1[];
    int qtdTicks1 = 0;
    datetime to   = TimeCurrent()             ; // agora
    qtdTicks1 = CopyTicksRange( m_symb_str1   , //const string     symbol_name,          // nome do símbolo
                                ticks1        , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                COPY_TICKS_ALL, //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                from*1000     , //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                to*1000         //ulong            to_msc=0              // data ate a qual são solicitados os ticks
                              );
    Print( __FUNCTION__,": Ticks copiados do ativo ",m_symb_str1,":",qtdTicks1);
    if(qtdTicks1>0){
        Print(__FUNCTION__,":-| Procesando ", qtdTicks1, " historicos... Mais antigo eh:", ticks1[0].time );
        for(int i=0; i<qtdTicks1; i++){
            //normalizar2trade(ticks1[i]);
            if( osc_padrao::isTkVol(ticks1[i]) ){
                m_vet_vol.add(ticks1[i]);// adicionando o tick ao vetor de volumes
                //if( m_vet_vol.count() > (EA_QTD_TIK_VOL_IMBALANCE/2) ){
                    m_vol_imb = m_vet_vol.get_desbalanceamento(); // obtendo o desbalancemento do volume;
                  //m_vol_imb = m_vet_vol.calc_desbalanceamento(); // obtendo o desbalancemento do volume;
                  //m_vol_imb = m_vet_vol.calc_desbalanceamento_com_peso(); // obtendo o desbalancemento do volume;
                //}
            }
        }
        Print(__FUNCTION__,":-| ",qtdTicks1, " historicos ",m_symb_str1  ," processados... Mais novo eh:", ticks1[qtdTicks1-1].time );
    }

    calcLenBarraMedia();
    return(INIT_SUCCEEDED);
}

void configurar_db(){ m_db.create_or_open_mydb(EA_DBNAME); }

MqlTick   m_tick1; // tick do ativo do grafico (se for pairs trading eh o ativo 1)

double m_r2         = 0;
void refreshMe(){

    // adicionando o tick ao componente estatistico...
    SymbolInfoTick(m_symb_str1,m_tick1);

    if( osc_padrao::isTkVol(m_tick1) ){
        m_vet_vol.add(m_tick1);// adicionando o tick ao vetor de volumes
        //if( m_vet_vol.count() > (EA_QTD_TIK_VOL_IMBALANCE/2) ){
            m_vol_imb = m_vet_vol.get_desbalanceamento(); // obtendo o desbalancemento do volume;
          //m_vol_imb = m_vet_vol.calc_desbalanceamento(); // obtendo o desbalancemento do volume;
          //m_vol_imb = m_vet_vol.calc_desbalanceamento_com_peso(); // obtendo o desbalancemento do volume;
        //}
    }

    m_ask     = m_tick1.ask;
    m_bid     = m_tick1.bid;
    m_spread  = m_tick1.ask-m_tick1.bid;
    

    m_trade1.setStopLoss( m_stopLossOrdens );
    m_trade1.setTakeProf( m_tkprof         );
    m_trade1.setVolLote ( m_lots_min       );

    //m_ask_stplev = m_bid + m_stop_level_in_price; if( m_ask_stplev < m_ask ) m_ask_stplev = m_ask;
    //m_bid_stplev = m_ask - m_stop_level_in_price; if( m_bid_stplev > m_bid ) m_bid_stplev = m_bid;
    m_ask_stplev = m_ask + m_stop_level_in_price;
    m_bid_stplev = m_bid - m_stop_level_in_price;

    m_sld_sessao_atu = m_cta.Balance (); // saldo da conta exceto as ordens em aberto nas posicoes...
    m_qtdOrdens      = OrdersTotal   ();
    m_qtdPosicoest   = PositionsTotal();
    m_qtdPosicoes1   = 0;

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
            m_lucroPosicao =   m_lucroPosicaoRealizado 
                             + m_lucroPosicaoParcial   // 22/10/2020 testando calculo de lucro da posicao...
                             - m_posicaoVolumeTot*(m_trade_estatistica.getUmaTarifaDiaWIN() + EA_TARIFA_TESTE );

            m_lucroPosicao4Gain = (m_posicaoVolumeTot *m_qtd_ticks_4_gain_ini_1)*(m_lots_step1); // 16/02/21 correcao valor do lote
          //m_lucroPosicao4Gain = (m_posicaoVolumeTot *m_qtd_ticks_4_gain_ini_1 ); // passou a usar em 05/06/2020
          //m_lucroPosicao4Gain = (m_posicaoVolumePend*m_qtd_ticks_4_gain_ini_1 ); // passou a usar em 05/06/2020

    }else{
        // aqui neste bloco, estah garantido que nao ha posicao aberta...
        m_qtdPosicoes1         = 0;
        m_volVendasNaPosicao   = 0;
        m_volComprasNaPosicao  = 0;

        m_capitalInicial       = m_cta.Balance(); // se nao estah na posicao, atualizamos o capital inicial da proxima posicao.
        //m_qtd_ticks_4_gain_ini_1 = EA_QTD_TICKS_4_GAIN_INI_1+EA_DESLOC_T4G_TESTE;
        m_comprado          = false;
        m_vendido           = false;
        m_stop              = false;
        m_fechar_posicao    = false;
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

void showAcao2(string acao){

   if( !EA_SHOW_TELA ){ return; }

   Comment(
         " \n BOOK ===" +
         "\n m_book1.IWFV/TLFV/IMB/SINAL    : ", astIfNeg(m_book1.getIWFV       (EA_BOOK_DEEP1)    ,0)+ " / " + 
                                                 astIfNeg(m_book1.getTLFV       (EA_BOOK_DEEP1)    ,0)+ " / " + 
                                                 astIfNeg(m_book1.getImbalance  (EA_BOOK_DEEP1)*100,0)+ " / " +  
                                                 astIfNeg(        calcSinalBook1(             )    ,0)        +
         " \n VOLUME ===" +
         "\n LEN/DESDE/DESB/VBUY/VSEL/VBUY-SEL: ",
		 	 	 	 	 	   astIfNeg(m_vet_vol.get_tamanho()                   ,0)+ " / " +
		                   TimeToString(m_vet_vol.dt_tick_mais_antigo(),TIME_SECONDS)+ " / " +
		                       astIfNeg(m_vet_vol.get_desbalanceamento()          ,2)+ " / " +
		                       astIfNeg(m_vet_vol.get_totbuy()                    ,0)+ " / " +
                               astIfNeg(m_vet_vol.get_totsel()                    ,0)+ " / " +
		                       astIfNeg(m_vet_vol.get_totbuy() -     
                                        m_vet_vol.get_totsel()                    ,0) +
       //  " \n ENTRADA  E SAIDA ==="+
           "\n DIVERSOS ==="+
           "\n lenBarraMediaEmTicks="     +astIfNeg(m_lenBarraMediaEmTicks,_Digits)+ "  REDUZIR_VOLUME=" + toString(m_reduzir_volume) +
           "\n TICKS_4_GAIN_INI---MIN="   +astIfNeg(m_qtd_ticks_4_gain_ini_1, 2) + " --- " +
                                            astIfNeg(EA_QTD_TICKS_4_GAIN_MIN_1,2) 
           );
}

string toString(bool b){ return b?"true":"false"; }


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

  m_cp.setTarWIN       ( m_trade_estatistica.getUmaTarifaDiaWIN() + EA_TARIFA_TESTE);
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

  m_cp.setIWFV      ( m_book1.getIWFV     (EA_BOOK_DEEP1), m_book1.getBid(1) );
  m_cp.setTLFV      ( m_book1.getTLFV     (EA_BOOK_DEEP1), m_book1.getAsk(1) );
  m_cp.setImbb      ( m_book1.getImbalance(EA_BOOK_DEEP1)                    );
  m_cp.setSinalBook ( calcSinalEntrada1   ()                                 );
  m_cp.setImbv      ( m_vol_imb,0 );  

  //m_cp.setVTDir2( m_direcaoVelVolTradeMed,0);
  //m_cp.setLEN0  ( m_canal1.getLenCanalOperacionalEmTicks(),0);
  //m_cp.setLEN1  ( m_canal1.getCoefLinear(),0);
}

int m_lag_rajada1 = 0;//EA_LAG_RAJADA1
void definirPasso(){

   double vol1 = 0;
   if( m_posicao1.Select(m_symb_str1) ){
       vol1 = m_posicao1.Volume();
   }
   
   if( EA_PASSO_DINAMICO ){

       //m_qtd_ticks_4_gain_new = EA_QTD_TICKS_4_GAIN_INI_1;
       m_qtd_ticks_4_gain_new = m_lenBarraMediaEmTicks*EA_PASSO_DINAMICO_PORC_BARRA_MEDIA; 
       for( int i=1; i<vol1; i++ ){
          m_qtd_ticks_4_gain_new += EA_PASSO_DINAMICO_PORC_T4G*m_qtd_ticks_4_gain_new;
       }

       m_qtd_ticks_4_gain_ini_1 = m_qtd_ticks_4_gain_new + EA_DESLOC_T4G_TESTE;
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
     if(!EA_PROCESSAR_BOOK) return;
     inicializarBookEvent(m_symb_str1);
     m_book1.initialize(m_symb_str1,EA_BOOK_DEEP1,EA_BOOK_IMBALANCE1); 
     m_book1.set_db(m_db); 
     m_book1.set_registrar_db(EA_REGISTRA_BOOK);
}

void inicializarBookEvent(string symb_str){
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
}

double m_stopLossPosicao = 0;

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
    m_qtd_ticks_4_gain_ini_1 = EA_QTD_TICKS_4_GAIN_INI_1+EA_DESLOC_T4G_TESTE;
    m_vol_lote_ini1        = EA_VOL_LOTE_INI_1    !=0?EA_VOL_LOTE_INI_1    *m_lots_step1:m_symb1.LotsMin();

    Print(":-| ", __FUNCTION__," m_aguardar_para_abrir_posicao      :", m_aguardar_para_abrir_posicao         );
    Print(":-| ", __FUNCTION__," m_tipo_entrada_permitida           :", EnumToString(m_tipo_entrada_permitida));
    Print(":-| ", __FUNCTION__," m_stopLossPosicao                  :", m_stopLossPosicao                     );
    Print(":-| ", __FUNCTION__," m_qtd_ticks_4_gain_ini_1           :", m_qtd_ticks_4_gain_ini_1           );
    Print(":-| ", __FUNCTION__," m_vol_lote_ini1                    :", m_vol_lote_ini1                    );
    Print(":-| ", __FUNCTION__," SLEEP_TESTE                        :", SLEEP_TESTE        ," miliseg"     );
    Print(":-| ", __FUNCTION__," ******************************** Variaveis diversas inicializadas."       );
}

void inicializarPassoRajadaFixoHFT_FORMADOR_DE_MERCADO(){
    Print(":-| ", __FUNCTION__," ******************************** Inicializando variaveis HFT_FORMADOR_DE_MERCADO...");
    m_lag_rajada1                          = EA_LAG_RAJADA1;

    Print(":-| ", __FUNCTION__," m_lag_rajada1                         :", m_lag_rajada1                           );
    Print(":-| ", __FUNCTION__," ******************************** Variaveis HFT_FORMADOR_DE_MERCADO inicializadas.");
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

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick(){ onTick(); }

void onTick(){
    refreshMe();
    onBookEvent(m_symb_str1);

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
        case HFT_FORMADOR_DE_MERCADO_BOOK: abrirPosicaoHFTFormadorDeMercadoSinaisDoBook  (); break;
        case HFT_FORMADOR_DE_MERCADO_VOL : abrirPosicaoHFTFormadorDeMercadoSinaisDoVolume(); break;
        //case NAO_ABRIR_POSICAO           : naoAbrirPosicao                               (); break;
        default                          : return;
    }
}

//void naoAbrirPosicao(){ return; }
bool naoOperar(){ return m_acao_posicao==NAO_OPERAR; }

bool podeAbrirProsicao(){

  if( m_aguardar_para_abrir_posicao > 0 ){ print("m_aguardar_para_abrir_posicao",m_aguardar_para_abrir_posicao);return false;} // soh abre novas posicoes apos zerar a penalidade de tempo do dia...
  if( spreadMaiorQueMaximoPermitido()   ){ print("spreadMaiorQueMaximoPermitido"                              );return false;}

  return true; //<TODO> tirar pois eh soh pra teste
}

bool saldoRebaixouMaisQuePermitidoNoDia(){ return ( EA_STOP_REBAIXAMENTO_MAX != 0 && m_trade_estatistica.getRebaixamentoSld () > EA_STOP_REBAIXAMENTO_MAX ); }
bool saldoAtingiuObjetivoDoDia         (){ return ( EA_STOP_OBJETIVO_DIA     != 0 && m_trade_estatistica.getProfitDiaLiquido() > EA_STOP_OBJETIVO_DIA     ); }

void definirPrecoSaidaPosicao(void){
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

bool stopGainParcialSimples(){

    if( EA_STOP_PARCIAL_ATIVAR                                   &&
        //m_tempo_posicao_atu > EA_STOP_PARCIAL_FIRE_TEMPO_POSICAO &&
        m_posicaoVolumeTot >= EA_STOP_PARCIAL_FIRE_VOLUME_TOT    &&
        m_lucroPosicao >= m_lucroPosicao4Gain*(EA_STOP_PARCIAL_FIRE_PORC_LUCRO_POSICAO) ){
        return true;
    }

    return false;
}

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
     return false;
}

string strPosicao(){
   return " Contr="       + DoubleToString (m_posicaoLotsPend  ,0)+ "/"+
                            DoubleToString (m_posicaoVolumeTot ,0)+
          " SPRE= "       + DoubleToString (m_symb1.Spread()    ,2)+
          " LUCRP="       + DoubleToString (m_lucroPosicao     ,2)+
          " ASK/BID="   + DoubleToString (m_ask,_Digits)        + "/"+ DoubleToString (m_bid,_Digits)+
          " Leilao="    +                 strEmLeilao()        ;
}

bool   emLeilao   (){return (m_ask<=m_bid);}
string strEmLeilao(){ if(emLeilao()) return "SIM"; return "NAO";}

//------------------------------------------------------------------------------------------------------------
// Faz: recebe um valor de ordem executa e dispara uma ordem na direcao oposta a ordem executada. Ou seja, se 
//      a ordem executada (typeDeal) foi uma compra, dispara uma venda e vice-versa.
//------------------------------------------------------------------------------------------------------------
bool m_stop_comprado  = false;
bool m_stop_vendido   = false;
bool m_fechar_posicao = false;
bool m_reduzir_volume = false;
void doCloseOposite( double toClosePriceIn, double vol, string symbol, ENUM_DEAL_TYPE typeDeal, long ticket=0  ){
    //Print(__FUNCTION__,"(",toClosePriceIn,",",vol,",",symbol,",", EnumToString(typeDeal),")", ",tg4=",m_qtd_ticks_4_gain_ini_1 );
    
    if (naoOperar() ) return;
    //if(m_stop) return;
    
    definirPasso();
    
    double vol_posicao = 0;
    if( m_posicao1.Select(m_symb_str1) ){ 
        vol_posicao = m_posicao1.Volume();
    }
    
    // em caso de fechamento da posicao, as ordens de saida da posicao devem ser a 0 ticks de distancia, da ultima execucao
    m_stop_comprado = false;
    m_stop_vendido  = false;
    if( m_fechar_posicao || vol_posicao > EA_MAX_VOL_POSICAO || m_reduzir_volume || m_stop ){
        if( m_posicao1.Select(m_symb_str1) ){
            if ( m_posicao1.PositionType() == POSITION_TYPE_BUY  ) m_stop_comprado = true;
            if ( m_posicao1.PositionType() == POSITION_TYPE_SELL ) m_stop_vendido  = true;
        }
    }
    
    double t4g = m_qtd_ticks_4_gain_ini_1;
    if( symbol==m_symb_str1 ){
        // ordem de fechamento da posicao
        if( (m_stop_comprado && typeDeal==DEAL_TYPE_BUY) || (m_stop_vendido && typeDeal==DEAL_TYPE_SELL)  ){
          //m_gerentePos1.doCloseOposite2(toClosePriceIn, EA_LEVEL_ENTRADA-1, vol, m_tick1,SLEEP_TESTE, typeDeal, ticket);
            m_gerentePos1.doCloseOposite3Agressao(                                 m_tick1,SLEEP_TESTE, typeDeal, ticket); return;
        }else{
            m_gerentePos1.doCloseOposite2(toClosePriceIn, t4g               , vol, m_tick1,SLEEP_TESTE, typeDeal, ticket); 
        }
        // ordem de entrada mais afastada da posicao
        if( (m_stop_comprado && typeDealInverso(typeDeal)==DEAL_TYPE_BUY) || (m_stop_vendido && typeDealInverso(typeDeal)==DEAL_TYPE_SELL) ){
          //m_gerentePos1.doCloseOposite2(toClosePriceIn, EA_LEVEL_ENTRADA-1, vol, m_tick1,SLEEP_TESTE, typeDealInverso(typeDeal) );
            m_gerentePos1.doCloseOposite3Agressao(                                 m_tick1,SLEEP_TESTE, typeDealInverso(typeDeal) ); return;
        }else{
            m_gerentePos1.doCloseOposite2(toClosePriceIn, t4g               , vol, m_tick1,SLEEP_TESTE, typeDealInverso(typeDeal) ); 
        }
        
        return; 
    }
}

ENUM_DEAL_TYPE typeDealInverso( ENUM_DEAL_TYPE typeDeal ){
    if( typeDeal == DEAL_TYPE_BUY  ) return DEAL_TYPE_SELL;
                                     return DEAL_TYPE_BUY ;
}

bool ehCompra(ENUM_DEAL_TYPE typeDeal){ return typeDeal==DEAL_TYPE_BUY ;}
bool ehVenda (ENUM_DEAL_TYPE typeDeal){ return typeDeal==DEAL_TYPE_SELL;}

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

bool stopGainParcial                     (){ return stopGainParcialSimples               ();}

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
}

//------------------------------------------------------------------------------
//| HFT_FORMADOR_DE_MERCADO_BOOK
//| Mantem pedidos de abetura de ordem segundo as regras abaixo:
//| 
//| ENTRADAS
//|         COMPRAR	imwf abaixo do bid e do ask
//|                 tlfv acima do bid e do ask
//|                 imbalance abaixo de -10%
//|
//|         VENDER	imwf acima do bid e do ask
//|                 tlfv abaixo do bid e do ask
//|                 imbalance acima de +10%
//| SAIDAS
//|         mesmas condicoes das entradas.
//------------------------------------------------------------------------------
void abrirPosicaoHFTFormadorDeMercadoSinaisDoBook(){
    ulong  ticket1;

    if(m_book1.getBid(EA_LEVEL_ENTRADA)==0 || m_book1.getAsk(EA_LEVEL_ENTRADA)==0 ){Print(__FUNCTION__,":Preco dos niveis de entrada no BOOK ZERADOS! VERIFIQUE!"); return;}

    if( estouSemPosicao1() ) cancelarOrdensComComentarioNumerico();   

   // obtendo o sinal do book de ofertas...
   //int sinal1 = calcSinalEntrada1();
     int sinal1 = calcSinalBook1();
   //int sinal1 = calcSinalVolume1();
   
   // comprando ou fechando a posicao vendida...
   if( sinal1>0 ){

        if(estouSemPosicao1() || estouVendido1() ){
            m_trade1.saveAsync();
            m_trade1.setAsync(false);
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaNoRoom(ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_book1.getBid(EA_LEVEL_ENTRADA), m_room1, m_vol_lote_ini1);
            m_trade1.restoreAsync();
            if(estouVendido1()) Print(__FUNCTION__,":SAIDA: Mantendo ordem de COMPRA em torno de:", m_book1.getBid(EA_LEVEL_ENTRADA),", ticket: #",ticket1, "...");
        }
        return;
   }
   
   // vendendo ou fechando a posicao comprada...
   if( sinal1<0 ){
        if(estouSemPosicao1() || estouComprado1()){
            m_trade1.saveAsync();
            m_trade1.setAsync(false);
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaNoRoom(ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_book1.getAsk(EA_LEVEL_ENTRADA), m_room1, m_vol_lote_ini1);
            m_trade1.restoreAsync();
            if( estouComprado1()) Print(__FUNCTION__,":SAIDA: Mantendo ordem de VENDA em torno de:", m_book1.getAsk(EA_LEVEL_ENTRADA),", ticket: #",ticket1, "...");
        }
        return;
   }
   /*
   // fechando posicao caso nao tenha sinal pra comprar ou vender...
   if( sinal1==0 ){
        if(estouVendido1() ){
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaNoRoom(m_symb_str1, ORDER_TYPE_BUY_LIMIT, m_apmb_buy, m_book1.getBid(EA_LEVEL_ENTRADA), m_room1, m_vol_lote_ini1);
            Print(__FUNCTION__,":SAIDA: Mantendo ordem de COMPRA em torno de:", m_book1.getBid(EA_LEVEL_ENTRADA),", ticket: #",ticket1, "...");
            Sleep(100);
            return;
        }

        if(estouComprado1()){
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaNoRoom(m_symb_str1, ORDER_TYPE_SELL_LIMIT, m_apmb_sel, m_book1.getAsk(EA_LEVEL_ENTRADA), m_room1, m_vol_lote_ini1);
            Print(__FUNCTION__,":SAIDA: Mantendo ordem de VENDA em torno de:", m_book1.getAsk(EA_LEVEL_ENTRADA),", ticket: #",ticket1, "...");
            Sleep(100);
            return;
        }
   }
   */
   // chegou aqui, eh porque nao tem sinal de compra ou venda e tambem nao tem posicao aberta. Entao cancela ordens de abertura de posicao, caso existam.
   if( estouSemPosicao1() ) m_trade1.cancelarOrdens("SEM_SINAL_ENTRADA");
}
//-----------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//| HFT_FORMADOR_DE_MERCADO_VOL
//| Mantem pedidos de abetura de ordem segundo as regras abaixo:
//| 
//| ENTRADAS
//|         COMPRAR	vol_imbalance acima de 0.15
//|
//|         VENDER	vol_imbalance abaixo -0.15
//| SAIDAS
//|         condicoes contrarias as entradas.
//------------------------------------------------------------------------------
void abrirPosicaoHFTFormadorDeMercadoSinaisDoVolume(){
    ulong  ticket1;
    m_reduzir_volume = false;

    if(m_ask==0 || m_bid==0 || m_bid>m_ask ){Print(__FUNCTION__,":Preco dos ticks inconsistentes! VERIFIQUE!"); return;}

    if( estouSemPosicao1() ){ cancelarOrdensComComentarioNumerico(); }

    // obtendo o sinal...
    int sinal1 = calcSinalVolume1();
   
    double bid_entrada = normalizar1( m_bid - m_symb1.TickSize()*(EA_LEVEL_ENTRADA-1) );
    double ask_entrada = normalizar1( m_ask + m_symb1.TickSize()*(EA_LEVEL_ENTRADA-1) );
   
   // comprando ou fechando a posicao vendida...
   if( sinal1>0 ){

      //if(estouSemPosicao1() || estouVendido1() ){
        if( estouSemPosicao1() && podeEntrarComprando() ){
            m_trade1.saveAsync();
            m_trade1.setAsync(false);
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaNoRoom(ORDER_TYPE_BUY_LIMIT, m_apmb_buy, bid_entrada, m_room1, m_vol_lote_ini1);
            m_trade1.restoreAsync();
            //if(estouVendido1()) Print(__FUNCTION__,":SAIDA: Mantendo ordem de COMPRA em torno de:", bid_entrada,", ticket: #",ticket1, "...");
            return;
        }
        
        if( estouVendido1() ){ m_reduzir_volume = true; }
        return;
   }
   
   // vendendo ou fechando a posicao comprada...
   if( sinal1<0 ){
      //if(estouSemPosicao1() || estouComprado1()){
        if( estouSemPosicao1() && podeEntrarVendendo() ){
            m_trade1.saveAsync();
            m_trade1.setAsync(false);
            sleepTeste(); ticket1 = m_trade1.manterOrdemLimitadaNoRoom(ORDER_TYPE_SELL_LIMIT, m_apmb_sel, ask_entrada, m_room1, m_vol_lote_ini1);
            m_trade1.restoreAsync();
            //if( estouComprado1()) Print(__FUNCTION__,":SAIDA: Mantendo ordem de VENDA em torno de:", ask_entrada,", ticket: #",ticket1, "...");
            return;
        }
        if( estouComprado1() ){ m_reduzir_volume = true; }
        return;        
   }
   
   //if( estouPosicionado1() ) m_reduzir_volume = true;
   
   // chegou aqui, eh porque nao tem sinal de compra ou venda e tambem nao tem posicao aberta. Entao cancela ordens de abertura de posicao, caso existam.
   if( estouSemPosicao1() ) m_trade1.cancelarOrdens("SEM_SINAL_ENTRADA");
}
//-----------------------------------------------------------------------------------------------------------------------------

// Calcula o sinal do book. Interprete assim:
//  1: entre comprando. se estiver vendido , feche a posicao.
// -1: entre vendendo . se estiver comprado, feche a posicao.
//  0: se estah posicionado, mantenha. Se nao estah, nao abra posicao.
int calcSinalBook1(){
    if(    m_book1.getIWFV(EA_BOOK_DEEP1)      < m_book1.getBid(1)
        && m_book1.getTLFV(EA_BOOK_DEEP1)      > m_book1.getAsk(1)
        && m_book1.getImbalance(EA_BOOK_DEEP1) < -0.05
      //&& m_maior_agressao           > 0                    // agressao de compras estah maior que as de venda         
                                                       ){
        return 1; // comprar
    }else{
        if(    m_book1.getIWFV(EA_BOOK_DEEP1)      > m_book1.getBid(1)
            && m_book1.getTLFV(EA_BOOK_DEEP1)      < m_book1.getAsk(1)
            && m_book1.getImbalance(EA_BOOK_DEEP1) > 0.05
          //&& m_maior_agressao           < 0                // agressao de vendas estah maior que as de compra   
                                                       ){
            return -1; // vender
        }
    }
    return 0; // manter 
}

int calcSinalVolume1(){
    if(m_vol_imb < -EA_VOL_IMBALANCE) return -1;// agressao de compras estah maior que as de venda.
    if(m_vol_imb >  EA_VOL_IMBALANCE) return +1;// agressao de vendas estah maior que as de compra.
                                      return  0;
}

int calcSinalEntrada1(){
    if(calcSinalBook1() > 0 && calcSinalVolume1() > 0 ) return  1;
    if(calcSinalBook1() < 0 && calcSinalVolume1() < 0 ) return -1;
                                                        return  0;
}

// calcula velocidade do volume...
double m_vol_buy = 0;
double m_vol_sel = 0;
double m_vol_imb = 0;  // imbalance do volume
double m_vel_vol_buy = 0;
double m_vel_vol_sel = 0;
double m_maior_agressao = 0;
datetime m_now     = TimeCurrent();
datetime m_now_ant = m_now;
/*
void calcVelVolume(){
    
    
    
    // como a funcao CopyTicksRange nao atualiza ateh que mude o segundo, executamos apenas uma vez pr segundo.
    m_now = TimeCurrent();
    if( m_now > m_now_ant+EA_TIMER_VOL_IMBALANCE ){
        m_now_ant = m_now;
    }else{
        return;
    }
    
    datetime to   = m_now; // agora
    datetime from = (to-EA_QTD_SEG_VOL_IMBALANCE)  ; // EA_QTD_SEG_VOL_IMBALANCE segundos atras
    MqlTick ticks1[];
    int qtdTicks1 = 0;
    qtdTicks1 = CopyTicksRange( m_symb_str1     , //const string symbol_name,          // nome do símbolo
                                ticks1          , //MqlTick&     ticks_array[],        // matriz para recebimento de ticks
                                COPY_TICKS_TRADE, //uint         flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                from*1000       , //ulong        from_msc=0,           // data a partir da qual são solicitados os ticks
                                to*1000           //ulong        to_msc=0              // data ate a qual são solicitados os ticks
                              );
    //if(qtdTicks1>0) Print(__FUNCTION__,":-| ",qtdTicks1, " hist copiados... de:", TimeToString(ticks1[0].time,TIME_SECONDS),",", ticks1[0].time_msc%1000, " ateh:", TimeToString(ticks1[qtdTicks1-1].time, TIME_SECONDS),",", ticks1[qtdTicks1-1].time_msc%1000 );

    m_vol_buy = 0;
    m_vol_sel = 0;
    m_vel_vol_buy = 0;
    m_vel_vol_sel = 0;
    m_maior_agressao = 0;

    double soma_pesos_buy = 0;
    double soma_pesos_sel = 0;
    for(int i=0; i<qtdTicks1; i++){
    	if( m_tick_util1.isTkBuy(ticks1[i]) ){ m_vol_buy += ticks1[i].volume_real*(i+1); soma_pesos_buy+=(i+1);}
    	if( m_tick_util1.isTkSel(ticks1[i]) ){ m_vol_sel += ticks1[i].volume_real*(i+1); soma_pesos_sel+=(i+1);}
    }

    //m_vel_vol_buy   = m_vol_buy/(double)(EA_QTD_SEG_VOL_IMBALANCE-1);
    //m_vel_vol_sel   = m_vol_sel/(double)(EA_QTD_SEG_VOL_IMBALANCE-1);
    m_vel_vol_buy    = soma_pesos_buy>0 ? m_vol_buy/(double)(soma_pesos_buy):0;
    m_vel_vol_sel    = soma_pesos_sel>0 ? m_vol_sel/(double)(soma_pesos_sel):0;
    m_maior_agressao = m_vel_vol_buy-m_vel_vol_sel;
    
    double soma_vol = m_vol_buy+m_vol_sel;
    m_vol_imb       = (soma_vol!=0)?(m_vol_buy-m_vol_sel)/(soma_vol):0;
}
*/

bool estouVendido1 (ENUM_DEAL_TYPE toCloseTypeDeal){ return toCloseTypeDeal==DEAL_TYPE_SELL; }
bool estouComprado1(ENUM_DEAL_TYPE toCloseTypeDeal){ return toCloseTypeDeal==DEAL_TYPE_BUY ; }

bool spreadMaiorQueMaximoPermitido(){ return m_spread > m_spread_maximo_in_points && m_spread_maximo_in_points != 0; }

bool m_fastClose     = true;
bool m_traillingStop = false;
void setFastClose()    { m_fastClose=true ; m_traillingStop=false;}
void setTraillingStop(){ m_fastClose=false; m_traillingStop=true ;}

double normalizar1(double preco){ return m_symb1.NormalizePrice(preco); }

void cancelarOrdens(string comentario){ m_trade1.cancelarOrdens(comentario); setSemPosicao(); }

void setCompradoSoft(){ m_comprado = true ; m_vendido = false; }
void setVendidoSoft() { m_comprado = false; m_vendido = true ; }
void setComprado()    { m_comprado = true ; m_vendido = false; m_tstop = 0;}
void setVendido()     { m_comprado = false; m_vendido = true ; m_tstop = 0;}
void setSemPosicao()  { m_comprado = false; m_vendido = false; m_tstop = 0;}

bool estouComprado1   (){ return m_comprado; }
bool estouVendido1    (){ return m_vendido ; }
bool estouSemPosicao1 (){ return !estouComprado1() && !estouVendido1() ; }
bool estouPosicionado1(){ return  estouComprado1() ||  estouVendido1() ; }

bool podeEntrarComprando(){ return m_tipo_entrada_permitida==ENTRADA_BUY  || m_tipo_entrada_permitida==ENTRADA_TODAS; }
bool podeEntrarVendendo (){ return m_tipo_entrada_permitida==ENTRADA_SELL || m_tipo_entrada_permitida==ENTRADA_TODAS; }

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
   m_trade_estatistica.refresh(m_time_in_seconds_ini_day, m_time_in_seconds_atu, EA_TARIFA_TESTE);

                        Print(__FUNCTION__," :-| Expert ", m_name, " Iniciando metodo OnDeinit..." );
                        Print(__FUNCTION__," :-| PROFIT BRUTO  :",m_trade_estatistica.getProfitDia       () );
                        Print(__FUNCTION__," :-| TARIFAS       :",m_trade_estatistica.getTarifaDia       () );
                        Print(__FUNCTION__," :-| PROFIT LIQUIDO:",m_trade_estatistica.getProfitDiaLiquido() );
    EventKillTimer();   Print(__FUNCTION__," :-| Expert ", m_name, " Timer destruido." );


    if( EA_SHOW_CONTROL_PANEL ) { m_cp.Destroy(reason); Print(__FUNCTION__," :-| Expert ", m_name, " Painel de controle destruido." ); }
    Comment("");                                        Print(__FUNCTION__," :-| Expert ", m_name, " Comentarios na tela apagados." );
    m_db.close();                                       Print(__FUNCTION__," :-| Expert ", m_name, " m_db fechado!" );
    MarketBookRelease(m_symb_str1)                    ; Print(__FUNCTION__," :-| Expert ", m_name, " book descadastrado!" );
                                                        Print(__FUNCTION__," :-) Expert ", m_name, " OnDeinit finalizado!" );
    return;
}

double OnTester(){
    m_trade_estatistica.print_posicoes(0, m_time_in_seconds_atu);
    return m_trade_estatistica.getProfitDiaLiquido(); // profit do dia no relatorio de performance
}

void printHeartBit(){ if(m_date_ant.min != m_date_atu.min) Print(":-| HeartBit! m_stop:", m_stop           , 
                                                                    " m_fechar_posicao:", m_fechar_posicao ,
                                                                    " lenVetVolume:"    , m_vet_vol.count() ) ; }

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

    // 1. Atualizando as variaveis de tempo atual m_time_in_seconds e m_date...
    m_time_in_seconds_atu = TimeCurrent();
    TimeToStruct(m_time_in_seconds_atu,m_date_atu);

    // 2. executando funcoes que dependem das valiaveis m_time_in_seconds ou m_date atualizadas...
    m_estah_no_intervalo_de_negociacao = estah_no_intervalo_de_negociacao(); // verificando intervalo de negociacao...
    m_eh_hora_de_fechar_posicao        = eh_hora_de_fechar_posicao       (); // verificando se as posicoes devem ser fechadas...
    controlarTimerParaAbrirPosicao();
    verificarMudancaDeSegundo();
    calcLenBarraMedia();
    //calcularOffset(); // tem de ser apos o calculo do tamanho da barra media
    printHeartBit();

    // 3. atualizando variaveis de comparacao de data anterior e atual m_time_in_seconds_ant e m_date_ant.
    //    a partir deste ponto, as atuais e anteriores ficam iguais.
    m_time_in_seconds_ant = m_time_in_seconds_atu;
    m_date_ant            = m_date_atu;

    if (EA_SHOW_CONTROL_PANEL) {
        m_trade_estatistica.refresh(m_time_in_seconds_ini_day, m_time_in_seconds_atu, EA_TARIFA_TESTE);
        refreshControlPanel();
    }
    
    //onTick();
}
//----------------------------------------------------------------------------------------------------

// demarcacao da mudanca de segundo.
bool m_mudou_segundo = false;
void verificarMudancaDeSegundo(){
   if(m_date_ant.sec != m_date_atu.sec){m_mudou_segundo=true; return;}
   m_mudou_segundo = false;
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
               Print("SHIFT+C foi pressionada. Compraria ativo 2: nao funciona");
           }else{
               Print(      "C foi pressionada. Comprando ativo 1:",m_symb_str1,"...");
               comprarLimitadoManual1();
           }
           break;
        case KEY_R:
           if( TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0 ){
               Print("SHIFT+R foi pressionada. Revertendo posicao 2: nao funciona");
           }else{
               Print(      "R foi pressionada. Revertendo posicao 1:",m_symb_str1,"...");
               reverterPosicao1();
           }
           break;
        case KEY_V:
           if( TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0 ){
               Print("SHIFT+V foi pressionada. Vendendo ativo 2: nao funciona");
           }else{
               Print(      "V foi pressionada. Vendendo ativo 1:",m_symb_str1,"...");
               venderLimitadoManual1();
           }
           break;

        case KEY_F:
           if( TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0 ){
                Print("SHIFT+F foi pressionada. Saindo do modo de fechar posicoes...");
                //m_acao_posicao = m_acao_posicao_ant; // retornando ao modo de operacao anterior ao fechamento
                m_fechar_posicao = false;
           }else{
                Print(      "F foi pressionada. Fechando todas as posicoes...");
                m_fechar_posicao = true;
                //if(m_acao_posicao==FECHAR_POSICAO) break;
                //m_acao_posicao_ant = m_acao_posicao; // salvando o anterior
                //m_acao_posicao = FECHAR_POSICAO; // isso fecha todas as posicoes abertas e cancela todas as ordens pendentes
           }
           break;

        default:
           Print("TECLA nao listada:" ,tecla,":",TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)<0?"shift":"nao" );
    }
    ChartRedraw();
}

void comprarLimitado1(){ m_trade1.comprarLimit(m_tick1.bid,m_apmb_buy); }
void venderLimitado1 (){ m_trade1.venderLimit (m_tick1.ask,m_apmb_sel); }

void comprarLimitadoManual1(){ m_trade1.comprarLimit(m_tick1.bid,m_apmb_man); }
void venderLimitadoManual1 (){ m_trade1.venderLimit (m_tick1.ask,m_apmb_man); }

void reverterPosicao1(){ m_gerentePos1.reverterPosicao(); }

//+-----------------------------------------------------------+
//|                                                           |
//+-----------------------------------------------------------+
void OnTradeTransaction( const MqlTradeTransaction& tran,    // transacao
                         const MqlTradeRequest&     req ,    // request
                         const MqlTradeResult&      res   ){ // result
                         
    //Print(__FUNCTION__, " Executando OnTradeTransaction()...");

  bool           closer          = false;  // true: trade eh um fechamento de posicao
  bool           toClose         = false;  // true: trade deve ser fechado
  ulong          toCloseidDeal   = 0    ;  // se toClose=true este serah o ticket  do trade a ser fechado
  double         toCloseVol      = 0    ;  // se toClose=true este serah o volume  do trade a ser fechado
  ENUM_DEAL_TYPE toCloseTypeDeal        ;  // se toClose=true este serah o sentido do trade a ser fechado, conforme ENUM_DEAL_TYPE
  double         toClosePriceIn         ;  // se toClose=true este serah o preco   do trade a ser fechado
  bool           toCloseOpenPos  = false;  // se toClose=true esta indicarah se a posicao foi aberta agora (primeiraOrdem)


  if(tran.symbol != m_symb_str1) return; //20210305: correcao BUG estava abrindo posicao com papel diferente do que estah sendo processado.

    m_pos.onTradeTransaction(tran,req,res,closer,toClose,toCloseidDeal,toCloseVol,toCloseTypeDeal,toClosePriceIn, toCloseOpenPos);

    //if( EA_LOGAR_TRADETRANSACTION ) m_pos.logarInCSV(tran,req,res);

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
  //if(  toClose && tran.type == TRADE_TRANSACTION_DEAL_ADD && tran.price > 0 ){
    if(             tran.type == TRADE_TRANSACTION_DEAL_ADD && tran.price > 0 ){

        // contando compras e vendas realizadas na posicao...
        if( tran.deal_type == DEAL_TYPE_BUY ){
            m_volComprasNaPosicao += (tran.volume/m_lots_step1);
        }else{
            if( tran.deal_type == DEAL_TYPE_SELL ){
                m_volVendasNaPosicao += (tran.volume/m_lots_step1);
            }
        }

       // a partir daqui haverah disparo de ordens, entao saimos caso nao seja possivel a operacao.
       if( m_acao_posicao == NAO_OPERAR     ) return;
       if( m_acao_posicao == FECHAR_POSICAO ) return;

        // acionando o fechamento das ordens da posicao...
        //Print(__FUNCTION__, ": tran.order:#", tran.order, ", tran.volume:", tran.volume );
      //doCloseOposite(tran.price,tran.volume, tran.symbol,tran.deal_type, tran.order); // suspeita de erro em toClosePriceIn, toCloseTypeDeal e toCloseVol
        doCloseOposite(tran.price,          1, tran.symbol,tran.deal_type, tran.order); // forcando 1 lote, independente da transacao que originou o fechamento 
    }
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
   if( !EA_PROCESSAR_BOOK ) return;
   
   if( symbol != m_symb_str1 || !m_tem_book) return;
   
   if( !MarketBookGet(symbol, m_book) ) { Print(":-( Falha MarketBookGet. Motivo: ", GetLastError()); return; }

   if(symbol == m_symb_str1){ m_book1.setBook(m_book); } 
   if( m_tamanhoBook==0) m_tamanhoBook = ArraySize(m_book);
   if( m_tamanhoBook==0) { Print(":-( Falha book vazio. Motivo: ", GetLastError()); return; }
}

// calcula o tamanho da barra media nos ultimos xx minutos
double m_lenBarraMediaEmTicks = 0;
void calcLenBarraMedia(){

    //if(!m_mudou_segundo) return;
    if(m_date_ant.min == m_date_atu.min) return; // recalcula 1x por minuto.
    double   maxMin      = 0 ;
    int      starPos     = 1 ; // desde o periodo anterior
    int      qtdPeriodos = 15; // ateh 15 periodos pra tras
    MqlRates ratesLenBarraMedia[];

    int qtd = CopyRates(m_symb_str1,_Period,starPos,qtdPeriodos,ratesLenBarraMedia);

    for(int i=0; i<qtd; i++){
        //Print("i:" + TimeToString(ratesLenBarraMedia[i].time) );
        maxMin += (ratesLenBarraMedia[i].high - ratesLenBarraMedia[i].low);
    }
    m_lenBarraMediaEmTicks =  (maxMin/m_tick_size1)/(double)qtd;
}
