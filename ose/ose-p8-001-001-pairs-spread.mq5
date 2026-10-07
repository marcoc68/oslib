//+------------------------------------------------------------------+
//|                                  ose-p8-001-001-pairs-spread.mq5 |
//|                                          Copyright 2026, OS Corp |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao p8-001-001                                                |
//|    Pairs trading por reversao a media do spread logaritmico.     |
//|    Eh o mesmo EA da versao 000, otimizado para negociar          |
//|                                                                  |
//|    vários pares ao mesmo tempo conforme parametro.               |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, OS Corp."
#property link      "http://www.os.org"
#property version   "8.002"

#include <oslib/osc/exp/C0701StrategyPairsTrading.mqh>
#include <Trade\AccountInfo.mqh>

//---------------------------------------------------------------------------------------------
input group "=== Par de ativos ===";
input int            EA_QTD_PARES_A_OPERAR  = 8         ; //QTD_PARES_A_OPERAR quantidade de pares a operar
input string         EA_SYMBOL_1            = TERMINAL  ; //SYMBOL_1 primeiro ativo do par (p1 do spread)
input string         EA_SYMBOL_2            = BUSCAR_PAR; //SYMBOL_2 segundo  ativo do par (p2 do spread)
input double         EA_COEF_CORRELACAO_MIN = 0.95      ; //COEF_CORRELACAO_MIN coeficiente de correlacao minimo entre os dois ativos para operar
input string         EA_SYMBOLS_CANDIDATES1  = "EURUSD,GBPUSD,USDCHF,USDJPY,USDCAD,AUDUSD"; //SYMBOLS_CANDIDATES1 lista de ativos candidatos a formar par com SYMBOL_1. separados por ','
input string         EA_SYMBOLS_CANDIDATES2  = "AUDNZD,AUDCAD,AUDCHF,AUDJPY,CHFJPY,EURGBP,EURAUD,EURJPY,EURCHF,EURNZD,EURCAD,GBPCHF,GBPJPY,GBPAUD,GBPCAD,GBPNZD,NZDCAD,NZDCHF,NZDJPY,NZDUSD,USDSGD"; //SYMBOLS_CANDIDATES2 lista de ativos candidatos a formar par com SYMBOL_1. separados por ','

//input string         EA_SYMBOLS_CANDIDATES1   = "AUDCAD,AUDCHF,AUDJPY,AUDNZD,AUDSGD,AUDUSD,CADCHF,CADJPY,CHFJPY,CHFSGD,EURAUD,EURCAD,EURCHF,EURDKK,EURGBP,EURHKD,EURJPY,EURNOK,EURNZD,EURPLN,EURSEK,EURSGD,EURTRY,EURUSD,EURZAR,GBPAUD,GBPCAD,GBPCHF,GBPDKK,GBPJPY"; //SYMBOLS_CANDIDATES1 lista de ativos candidatos a formar par com SYMBOL_1. separados por ','
//input string         EA_SYMBOLS_CANDIDATES2   = "GBPNOK,GBPNZD,GBPSEK,GBPSGD,GBPTRY,GBPUSD,NOKJPY,NOKSEK";//,NZDCAD";//,NZDCHF,NZDJPY,NZDUSD,SEKJPY,SGDJPY,USDCAD,USDCHF,USDCNH,USDCZK,USDDKK,USDHKD,USDHUF,USDJPY,USDMXN,USDNOK,USDPLN,USDSEK,USDSGD,USDTHB,USDTRY,USDZAR"; //SYMBOLS_CANDIDATES2 lista de ativos candidatos a formar par com SYMBOL_1. separados por ','
input group "=== Spread do PAR ===";
input int             EA_QTD_PERIODOS    = 120        ; //QTD_PERIODOS qtd de barras usadas na media e no desvio do spread
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
input double         EA_MARGIN_LEVEL_MINIMO = 150     ; //MARGIN_LEVEL_MINIMO nivel de margem minimo para abrir posicao.
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

string        m_name = "OSE-P8-001-001-PAIRS-SPREAD";

struct Par{
    string symbol1;
    string symbol2;
    double coef_correlacao;
    bool   cointegrados;
    double spread_medio;
    C0701StrategyPairsTrading strategy;
};

ParametrosC0701StrategyPairsTrading m_param;
Par                                 m_vet_pares[];    // vetor de pares de ativos.
CAccountInfo                        m_conta;
uint                                m_qtd_pares = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
    inicializarParametrosC0701StrategyPairsTrading();
    montarVetorDePares();
    int result = onInit();
    criarTimer(EA_QTD_MILISEG_TIMER);
    return result;
}

// inicializa os objetos de estrategia de cada par de ativos. Retorna INIT_SUCCEEDED se todos os pares foram inicializados com sucesso, ou INIT_FAILED se algum par falhou na inicializacao.
int onInit(){
    int retorno = 0;
    for(uint i = 0; i < m_qtd_pares; i++){
        retorno = m_vet_pares[i].strategy.onInit();
        if(retorno != INIT_SUCCEEDED){
            Print(":-| ", __FUNCTION__, " erro ao inicializar o par ", m_vet_pares[i].symbol1, "-", m_vet_pares[i].symbol2, " retorno=", retorno);
            return INIT_FAILED;
        }
    }
    showTela();
    return INIT_SUCCEEDED;
}

void criarTimer(int milisegundos_timer=0){
    if( milisegundos_timer > 0 ){
        EventSetMillisecondTimer( milisegundos_timer );
        Print(":-| ", __FUNCTION__, " Criado Timer de ", milisegundos_timer, " milisegundos." );
        Print(":-) ", __FUNCTION__, " inicializado !! " );
    }
}

void montarVetorDePares(){

    // 1. Separar a lista de ativos por vírgula dentro de um array de simbolos
    string symbols[];
    montarVetorDeSimbolosCandidatos(EA_SYMBOLS_CANDIDATES1 + "," + EA_SYMBOLS_CANDIDATES2, symbols);

    // 2. Dimensionar o vetor de pares de ativos
    int qtdSymbols = ArraySize(symbols);
    m_qtd_pares = ArrayResize(m_vet_pares, qtdSymbols * (qtdSymbols - 1) / 2); // combinações de pares

    // 3. Montar o vetor de pares de ativos e estrategias de negociacao
    int index = 0;
    ParametrosC0701StrategyPairsTrading param;
    for(int i = 0; i < qtdSymbols; i++){
        for(int j = i + 1; j < qtdSymbols; j++){
            m_vet_pares[index].symbol1 = symbols[i];
            m_vet_pares[index].symbol2 = symbols[j];

            param = m_param;
            param.ea_symbol_1 = m_vet_pares[index].symbol1;
            param.ea_symbol_2 = m_vet_pares[index].symbol2;
            m_vet_pares[index].strategy = C0701StrategyPairsTrading(param);
            index++;
        }
    }
    ArrayPrint(m_vet_pares);
    return;
}

void montarVetorDeSimbolosCandidatos(string inStrSymbols, string &outVetSymbols[]){
    int qtdSymbols;

    // 1. Separar a lista de ativos por vírgula
    ushort u_sep = StringGetCharacter(",", 0);
    qtdSymbols = StringSplit(inStrSymbols, u_sep, outVetSymbols);

    // Limpar espaços em branco dos nomes dos ativos
    for(int i = 0; i < qtdSymbols; i++)
    {
        StringTrimLeft(outVetSymbols[i]);
        StringTrimRight(outVetSymbols[i]);
    }
    return;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason){
    for(uint i = 0; i < m_qtd_pares; i++){
        m_vet_pares[i].strategy.onDeinit(reason);
    }
    EventKillTimer();
    Comment("");
    Print(":-| ", __FUNCTION__, " finalizado. reason=", reason );
}



//+------------------------------------------------------------------+
//void OnTick (){ processar(); }
void OnTimer(){ processar(); } // o grafico pode ser de um terceiro ativo, ou o ativo 2
                                          // pode negociar quando o ativo 1 estah parado.
void processar(){
    for(uint i = 0; i < m_qtd_pares; i++){
        m_vet_pares[i].strategy.processar();
    }
    showTela();
}

//+------------------------------------------------------------------+
//| Teclas de atalho                                                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam){

    if( id != CHARTEVENT_KEYDOWN   ) return;
    if( !EA_TECLAS_HABILITADAS     ) return;
    //if( !m_strategy.m_inicializado ) return;

    int tecla = (int)lparam;
    if( tecla != EA_TECLA_ABRIR && tecla != EA_TECLA_FECHAR ) return;

    // a tecla eh uma das nossas, mas os modificadores nao conferem. Logamos o que foi
    // detectado: ajuda a ajustar a combinacao quando o terminal captura o ALT antes do
    // grafico, ou quando o keystate do ALT nao responde como esperado no ambiente.
    if( !osc_trade_util::modificadoresPressionados( EA_TECLA_CTRL, EA_TECLA_ALT, EA_TECLA_SHIFT ) ){
        Print(":-| ", __FUNCTION__, " tecla ", tecla, " ignorada: modificadores nao conferem.",
                      " esperado  ctrl:", EA_TECLA_CTRL,
                      " alt:"           , EA_TECLA_ALT,
                      " shift:"         , EA_TECLA_SHIFT,
                      " | detectado ctrl:", osc_trade_util::teclaCtrl (),
                      " alt:"             , osc_trade_util::teclaAlt  (),
                      " shift:"           , osc_trade_util::teclaShift() );
        return;
    }

    if( tecla == EA_TECLA_FECHAR ){ fecharPorTecla(); return; }
}


// fechamento manual das duas pernas.
void fecharPorTecla(){
    for(uint i = 0; i < m_qtd_pares; i++){
        m_vet_pares[i].strategy.fecharPorTecla();
    }
}

void inicializarParametrosC0701StrategyPairsTrading(){
    // inicializando os parametros que serao passados para os objetos de estrategia...
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
    m_param.ea_margin_level_minimo                = EA_MARGIN_LEVEL_MINIMO               ;
    m_param.ea_operacao_automatica                = EA_OPERACAO_AUTOMATICA               ;
    m_param.ea_teclas_habilitadas                 = EA_TECLAS_HABILITADAS                ;
    m_param.ea_tecla_ctrl                         = EA_TECLA_CTRL                        ;
    m_param.ea_tecla_alt                          = EA_TECLA_ALT                         ;
    m_param.ea_tecla_shift                        = EA_TECLA_SHIFT                       ;
    m_param.ea_tecla_abrir                        = EA_TECLA_ABRIR                       ;
    m_param.ea_tecla_fechar                       = EA_TECLA_FECHAR                      ;
    m_param.ea_magic                              = EA_MAGIC                             ;
    m_param.ea_desvio_pontos                      = EA_DESVIO_PONTOS                     ;
    m_param.ea_show_tela                          = false                                ;
    m_param.ea_qtd_miliseg_timer                  = 0                                    ; // timer desabilitado nas classes de operacao e geranciado aqui no EA.
    m_param.ea_name                               = m_name                               ;
}

void showTela(){
    string str_show_tela = linhaTelaComum() + "\n";
    uint qtd = 0;
    // primeiro mostra as posicoes abertas...
    for(uint i = 0; i < m_qtd_pares; i++){
        if( m_vet_pares[i].strategy.getEstado() != PAR_FLAT ){
            str_show_tela += linhaTela(m_vet_pares[i]) + "\n";
        }
    }

    // depois mostra os pares que estao aptos a operar, mas ainda nao abriram posicao.
    for(uint i = 0; i < m_qtd_pares; i++){
        if(  m_vet_pares[i].strategy.getEstado() == PAR_FLAT &&
             m_vet_pares[i].strategy.coef_correlacao_ok() &&
             m_vet_pares[i].strategy.parCointegrado() &&
             m_vet_pares[i].strategy.spread_operacional_ok()
          ){
            str_show_tela += linhaTela(m_vet_pares[i]) + "\n";
            if(++qtd > 30) break;
        }
    }
    Comment(str_show_tela);
}

string linhaTela(Par &par){
    return par.strategy.getNmSymbol1() + "_" + par.strategy.getNmSymbol2() +
           " Spread :" + DoubleToString(par.strategy.getSpreadOperacional1(), 2) + "_" +
                         DoubleToString(par.strategy.getSpreadOperacional2(), 2) +

           " Corr:"  + DoubleToString(par.strategy.getCoefCorrelacao(), 2) +

           " Coint " +               (par.strategy.parCointegrado()? "SIM" : "NAO") +

           " EST "   +                par.strategy.estadoStr() +

           " VOL "   + DoubleToString(par.strategy.getVolume1(), 2) + "_" +
                       DoubleToString(par.strategy.getVolume2(), 2) +
           " Zscor " + DoubleToString(par.strategy.getZscore(), 2) +

           " Result " + DoubleToString(par.strategy.getLucroPar(), 2);
}

string linhaTelaComum(){
    return m_name +"\n" +
           "Account: " + m_conta.Company() + "  MarginLevel:" + DoubleToString(m_conta.MarginLevel(), 2) + "%" + " Equity: " + DoubleToString(m_conta.Equity(),2) + "\n" +
           "QtdPares: " + IntegerToString(m_qtd_pares) + "  Janela: " + IntegerToString(m_param.ea_qtd_periodos) + " barras de " + EnumToString(m_param.ea_timeframe);
}
//+------------------------------------------------------------------+
