//+------------------------------------------------------------------+
//|                                  ose-p8-001-000-pairs-spread.mq5 |
//|                                          Copyright 2026, OS Corp |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao p8-001-000                                                |
//|    Pairs trading por reversao a media do spread logaritmico.     |
//|                                                                  |
//|    ESTRATEGIA                                                    |
//|    - spread = log(p1) - log(p2), calculado pela classe           |
//|      C00021Pairs (oslib/osc/est/C00021Pairs.mqh).                |
//|                                                                  |
//|    - A media e o desvio padrao do spread sao calculados sobre    |
//|      uma janela de EA_QTD_PERIODOS barras fechadas do timeframe  |
//|      EA_TIMEFRAME. A janela eh alimentada com uma amostra por    |
//|      barra fechada (fechamento contra fechamento).               |
//|                                                                  |
//|    - O sinal eh avaliado a cada tick, usando o spread            |
//|      instantaneo contra as bandas da ultima barra fechada:       |
//|                                                                  |
//|      spread > media + k*desvio -> ativo1 caro em relacao ao 2:   |
//|                                   VENDE ativo1 / COMPRA ativo2   |
//|      spread < media - k*desvio -> ativo1 barato em relacao ao 2: |
//|                                   COMPRA ativo1 / VENDE ativo2   |
//|                                                                  |
//|    - Saida: quando o spread retorna a media (ou para dentro de   |
//|      DESVIOS_SAIDA desvios da media), fecha as duas pernas.      |
//|      Opcionalmente, stop financeiro sobre o resultado somado     |
//|      das duas pernas e stop pelo deslocamento da media.          |
//|                                                                  |
//|    - Uma operacao por vez. Volume igual nas duas pernas.         |
//|                                                                  |
//|    SAIDAS ADICIONAIS                                             |
//|    - STOP_MEDIA_ABERTURA: fecha quando a media do spread se      |
//|      desloca ateh o nivel (spread de abertura +- STOP_DESVIOS_   |
//|      MEDIA * desvio de abertura), no sentido contrario ao da     |
//|      operacao. Eh a media perseguindo o preco: a premissa de     |
//|      reversao foi quebrada.                                      |
//|                                                                  |
//|    - DESVIOS_SAIDA: fecha antes do spread alcancar a media.      |
//|      Ex: entrada a 2.0 desvios e saida a 0.5 desvios.            |
//|                                                                  |
//|    OPERACAO MANUAL                                               |
//|    - OPERACAO_AUTOMATICA=false: o EA nao abre nem fecha posicao  |
//|      sozinho; apenas registra no log o que faria. As teclas      |
//|      continuam funcionando.                                      |
//|                                                                  |
//|    - TECLAS_HABILITADAS: abre/fecha o par por combinacao de      |
//|      teclas (padrao CTRL+ALT+A abre / CTRL+ALT+F fecha). O       |
//|      grafico precisa estar com o foco.                           |
//|                                                                  |
//|    - SUGERIR_VOLUME: no OnInit, calcula e loga o menor par de    |
//|      volumes que deixa as duas pernas equilibradas em dinheiro.  |
//|      Eh apenas uma sugestao: o EA opera com VOLUME.              |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, OS Corp."
#property link      "http://www.os.org"
#property version   "8.002"

//#include <Trade/Trade.mqh>
//#include <Trade/SymbolInfo.mqh>
//#include <oslib/osc/est/C00021Pairs.mqh>
//#include <oslib/osc/osc-media2.mqh>
//#include <oslib/osc-trade-util.mqh>
#include <oslib/osc/exp/C0701StrategyPairsTrading.mqh>


//--- estado do par (direcao da operacao sobre o spread)
//#define PAR_FLAT          0  // sem posicao
//#define PAR_LONG_SPREAD   1  // comprado no spread : COMPRA ativo1 / VENDE  ativo2
//#define PAR_SHORT_SPREAD -1  // vendido  no spread : VENDE  ativo1 / COMPRA ativo2
//#define TERMINAL         "TERMINAL"  // nome especial para indicar o simbolo do terminal.
//#define BUSCAR_PAR       "BUSCAR_PAR"  // nome especial para indicar que o EA deve buscar um par adequado.

//---------------------------------------------------------------------------------------------
input group "=== Par de ativos ===";
input string         EA_SYMBOL_1            = TERMINAL  ; //SYMBOL_1 primeiro ativo do par (p1 do spread)
input string         EA_SYMBOL_2            = BUSCAR_PAR; //SYMBOL_2 segundo  ativo do par (p2 do spread)
input double         EA_COEF_CORRELACAO_MIN = 0.80      ; //COEF_CORRELACAO_MIN coeficiente de correlacao minimo entre os dois ativos para operar
input string         EA_SYMBOLS_CANDIDATES1   = "AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDSGD,AUDUSD,CADCHF,CADJPY,CHFJPY,CHFSGD,EURAUD,EURCAD,EURCHF,EURDKK,EURGBP,EURHKD,EURJPY,EURNOK,EURNZD,EURPLN,EURSEK,EURSGD,EURTRY,EURUSD,EURZAR,GBPAUD,GBPCAD,GBPCHF,GBPDKK,GBPJPY"; //SYMBOLS_CANDIDATES1 lista de ativos candidatos a formar par com SYMBOL_1. separados por ','
input string         EA_SYMBOLS_CANDIDATES2   = "GBPNOK,GBPNZD,GBPSEK,GBPSGD,GBPTRY,GBPUSD,NOKJPY,NOKSEK,NZDCAD,NZDCHF,NZDJPY,NZDUSD,SEKJPY,SGDJPY,USDCAD,USDCHF,USDCNH,USDCZK,USDDKK,USDHKD,USDHUF,USDJPY,USDMXN,USDNOK,USDPLN,USDSEK,USDSGD,USDTHB,USDTRY,USDZAR"; //SYMBOLS_CANDIDATES2 lista de ativos candidatos a formar par com SYMBOL_1. separados por ','
// retirados:  EURHKD, EURTRY -> (spread alto)
input group "=== Spread do PAR ===";
input int             EA_QTD_PERIODOS    = 60         ; //QTD_PERIODOS qtd de barras usadas na media e no desvio do spread
input ENUM_TIMEFRAMES EA_TIMEFRAME       = PERIOD_M3  ; //TIMEFRAME timeframe das barras da janela do spread
input double          EA_DESVIOS_ENTRADA = 3.0        ; //DESVIOS_ENTRADA afastamento em desvios padrao para disparar a operacao
input double          EA_DESVIOS_SAIDA   = 0.0        ; //DESVIOS_SAIDA distancia da media, em desvios, onde a posicao eh fechada. 0=fecha na media

input group "=== Volume ===";
input double         EA_VOLUME_1        = 0.01        ; //VOLUME lote aplicado na primeira perna
input double         EA_VOLUME_2        = 0.01        ; //VOLUME lote aplicado na segunda perna
input bool           EA_APLICAR_SUGESTAO_DE_VOLUME = true ; //APLICAR_SUGESTAO_DE_VOLUME aplica a sugestao de volume de lotes
input double         EA_TOLERANCIA_EQUIL= 0.10        ; //TOLERANCIA_EQUIL desequilibrio aceito entre as pernas no calculo da sugestao. 0.01=1%

input group "=== Stop ===";
input double         EA_STOP_FINANCEIRO = 0.0         ; //STOP_FINANCEIRO perda maxima somada das duas pernas, na moeda da conta. 0=desligado
input bool           EA_STOP_MEDIA_ABERTURA = false   ; //STOP_MEDIA_ABERTURA fecha qd a media alcanca o spread de abertura +- desvios de abertura

input group "=== Operacao ===";
input int            EA_SPREAD_PIPS_MAX_PARA_ABRIR_POSICAO = 5    ; // Spread em pips maior que este valor. Não abre posição.
input bool           EA_OPERACAO_AUTOMATICA = true    ; //OPERACAO_AUTOMATICA false=nao abre nem fecha sozinho, apenas loga o que faria
input bool           EA_TECLAS_HABILITADAS  = true    ; //TECLAS_HABILITADAS abre/fecha o par por combinacao de teclas (grafico precisa ter o foco)
input bool           EA_TECLA_CTRL      = true        ; //TECLA_CTRL exige CTRL na combinacao de teclas
input bool           EA_TECLA_ALT       = false       ; //TECLA_ALT exige ALT na combinacao de teclas
input bool           EA_TECLA_SHIFT     = true        ; //TECLA_SHIFT exige SHIFT na combinacao de teclas
input int            EA_TECLA_ABRIR     = 65          ; //TECLA_ABRIR codigo da tecla que abre o par. 65='A'
input int            EA_TECLA_FECHAR    = 70          ; //TECLA_FECHAR codigo da tecla que fecha o par. 70='F'

input group "=== Diversos ===";
input ulong          EA_MAGIC           = 260908001000; //MAGIC numero magico do EA. yy-mm-vv-vvv-vvv-vv
input ulong          EA_DESVIO_PONTOS   = 20          ; //DESVIO_PONTOS desvio maximo aceito do preco nas ordens a mercado
input bool           EA_SHOW_TELA       = true        ; //SHOW_TELA mostra o estado do EA no grafico
input int            EA_QTD_MILISEG_TIMER = 250       ; //QTD_MILISEG_TIMER tempo de acionamento do timer
//---------------------------------------------------------------------------------------------

string        m_name = "OSE-P8-001-000-PAIRS-SPREAD";

C0701StrategyPairsTrading           m_strategy;
ParametrosC0701StrategyPairsTrading m_param;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
    m_param.ea_symbol_1                           = EA_SYMBOL_1                          ;
    m_param.ea_symbol_2                           = EA_SYMBOL_2                          ;
    m_param.ea_coef_correlacao_min                = EA_COEF_CORRELACAO_MIN               ;
    m_param.ea_symbols_candidates                 = EA_SYMBOLS_CANDIDATES1 + "," + EA_SYMBOLS_CANDIDATES2 ;
    m_param.ea_qtd_periodos                       = EA_QTD_PERIODOS                      ;
    m_param.ea_timeframe                          = EA_TIMEFRAME                         ;
    m_param.ea_desvios_entrada                    = EA_DESVIOS_ENTRADA                   ;
    m_param.ea_desvios_saida                      = EA_DESVIOS_SAIDA                     ;
    m_param.ea_volume_1                           = EA_VOLUME_1                          ;
    m_param.ea_volume_2                           = EA_VOLUME_2                          ;
    m_param.ea_aplicar_sugestao_de_volume         = EA_APLICAR_SUGESTAO_DE_VOLUME        ;
    m_param.ea_tolerancia_equil                   = EA_TOLERANCIA_EQUIL                  ;
    m_param.ea_stop_financeiro                    = EA_STOP_FINANCEIRO                   ;
    m_param.ea_stop_media_abertura                = EA_STOP_MEDIA_ABERTURA               ;
    m_param.ea_spread_pips_max_para_abrir_posicao = EA_SPREAD_PIPS_MAX_PARA_ABRIR_POSICAO;
    m_param.ea_operacao_automatica                = EA_OPERACAO_AUTOMATICA               ;
    m_param.ea_teclas_habilitadas                 = EA_TECLAS_HABILITADAS                ;
    m_param.ea_tecla_ctrl                         = EA_TECLA_CTRL                        ;
    m_param.ea_tecla_alt                          = EA_TECLA_ALT                         ;
    m_param.ea_tecla_shift                        = EA_TECLA_SHIFT                       ;
    m_param.ea_tecla_abrir                        = EA_TECLA_ABRIR                       ;
    m_param.ea_tecla_fechar                       = EA_TECLA_FECHAR                      ;
    m_param.ea_magic                              = EA_MAGIC                             ;
    m_param.ea_desvio_pontos                      = EA_DESVIO_PONTOS                     ;
    m_param.ea_show_tela                          = EA_SHOW_TELA                         ;
    m_param.ea_qtd_miliseg_timer                  = EA_QTD_MILISEG_TIMER                 ;
    m_param.ea_name                               = m_name                               ;

    m_strategy = new C0701StrategyPairsTrading(m_param);
    return m_strategy.onInit();
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason){
    m_strategy.onDeinit(reason);
    
    EventKillTimer();
    Comment("");
    Print(":-| ", __FUNCTION__, " finalizado. reason=", reason );
}

//+------------------------------------------------------------------+
void OnTick (){ m_strategy.processar(); }
void OnTimer(){ m_strategy.processar(); } // o grafico pode ser de um terceiro ativo, ou o ativo 2
                                          // pode negociar quando o ativo 1 estah parado.

//+------------------------------------------------------------------+
//| Teclas de atalho                                                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam){

    if( id != CHARTEVENT_KEYDOWN   ) return;
    if( !EA_TECLAS_HABILITADAS     ) return;
    if( !m_strategy.m_inicializado ) return;

    int tecla = (int)lparam;
    if( tecla != EA_TECLA_ABRIR && tecla != EA_TECLA_FECHAR ) return;

    // a tecla eh uma das nossas, mas os modificadores nao conferem. Logamos o que foi
    // detectado: ajuda a ajustar a combinacao quando o terminal captura o ALT antes do
    // grafico, ou quando o keystate do ALT nao responde como esperado no ambiente.
    if( !osc_trade_util::modificadoresPressionados( EA_TECLA_CTRL, EA_TECLA_ALT, EA_TECLA_SHIFT ) ){
        Print(":-| ", __FUNCTION__, " tecla ", tecla, " ignorada: modificadores nao conferem.",
                      " esperado  ctrl:", EA_TECLA_CTRL,
                      " alt:"          , EA_TECLA_ALT,
                      " shift:"        , EA_TECLA_SHIFT,
                      " | detectado ctrl:", osc_trade_util::teclaCtrl (),
                      " alt:"             , osc_trade_util::teclaAlt  (),
                      " shift:"           , osc_trade_util::teclaShift() );
        return;
    }

    if( tecla == EA_TECLA_FECHAR ){ fecharPorTecla(); return; }
}


// fechamento manual das duas pernas.
void fecharPorTecla(){
    m_strategy.fecharPorTecla();
    m_strategy.showTela();
}

//+------------------------------------------------------------------+
