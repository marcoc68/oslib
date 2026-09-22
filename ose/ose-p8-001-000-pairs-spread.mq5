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

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <oslib/osc/est/C00021Pairs.mqh>
#include <oslib/osc-trade-util.mqh>

//--- estado do par (direcao da operacao sobre o spread)
#define PAR_FLAT          0  // sem posicao
#define PAR_LONG_SPREAD   1  // comprado no spread : COMPRA ativo1 / VENDE  ativo2
#define PAR_SHORT_SPREAD -1  // vendido  no spread : VENDE  ativo1 / COMPRA ativo2

//---------------------------------------------------------------------------------------------
input group "=== Par de ativos ===";
input string         EA_SYMBOL_1        = "EURUSD"    ; //SYMBOL_1 primeiro ativo do par (p1 do spread)
input string         EA_SYMBOL_2        = "GBPUSD"    ; //SYMBOL_2 segundo  ativo do par (p2 do spread)

input group "=== Spread ===";
input int            EA_QTD_PERIODOS    = 60          ; //QTD_PERIODOS qtd de barras usadas na media e no desvio do spread
input ENUM_TIMEFRAMES EA_TIMEFRAME      = PERIOD_M1   ; //TIMEFRAME timeframe das barras da janela do spread
input double         EA_DESVIOS_ENTRADA = 2.0         ; //DESVIOS_ENTRADA afastamento em desvios padrao para disparar a operacao
input double         EA_DESVIOS_SAIDA   = 0.0         ; //DESVIOS_SAIDA distancia da media, em desvios, onde a posicao eh fechada. 0=fecha na media

input group "=== Volume ===";
input double         EA_VOLUME          = 0.10        ; //VOLUME lote aplicado igualmente nas duas pernas
input bool           EA_SUGERIR_VOLUME  = true        ; //SUGERIR_VOLUME loga, no OnInit, o menor volume de equilibrio financeiro de cada perna
input double         EA_TOLERANCIA_EQUIL= 0.01        ; //TOLERANCIA_EQUIL desequilibrio aceito entre as pernas no calculo da sugestao. 0.01=1%

input group "=== Stop ===";
input double         EA_STOP_FINANCEIRO = 0.0         ; //STOP_FINANCEIRO perda maxima somada das duas pernas, na moeda da conta. 0=desligado
input bool           EA_STOP_MEDIA_ABERTURA = false   ; //STOP_MEDIA_ABERTURA fecha qd a media alcanca o spread de abertura +- desvios de abertura
input double         EA_STOP_DESVIOS_MEDIA  = 1.0     ; //STOP_DESVIOS_MEDIA qtos desvios da abertura sao somados ao spread de abertura no stop acima

input group "=== Operacao ===";
input bool           EA_OPERACAO_AUTOMATICA = true    ; //OPERACAO_AUTOMATICA false=nao abre nem fecha sozinho, apenas loga o que faria
input bool           EA_TECLAS_HABILITADAS  = true    ; //TECLAS_HABILITADAS abre/fecha o par por combinacao de teclas (grafico precisa ter o foco)
input bool           EA_TECLA_CTRL      = true        ; //TECLA_CTRL exige CTRL na combinacao de teclas
input bool           EA_TECLA_ALT       = true        ; //TECLA_ALT exige ALT na combinacao de teclas
input bool           EA_TECLA_SHIFT     = false       ; //TECLA_SHIFT exige SHIFT na combinacao de teclas
input int            EA_TECLA_ABRIR     = 65          ; //TECLA_ABRIR codigo da tecla que abre o par. 65='A'
input int            EA_TECLA_FECHAR    = 70          ; //TECLA_FECHAR codigo da tecla que fecha o par. 70='F'

input group "=== Diversos ===";
input ulong          EA_MAGIC           = 26090800100000; //MAGIC numero magico do EA. yy-mm-vv-vvv-vvv-vv
input ulong          EA_DESVIO_PONTOS   = 20          ; //DESVIO_PONTOS desvio maximo aceito do preco nas ordens a mercado
input bool           EA_SHOW_TELA       = true        ; //SHOW_TELA mostra o estado do EA no grafico
input int            EA_QTD_MILISEG_TIMER = 250       ; //QTD_MILISEG_TIMER tempo de acionamento do timer
//---------------------------------------------------------------------------------------------

string        m_name = "OSE-P8-001-000-PAIRS-SPREAD";

C00021Pairs   m_pairs                 ; // calculo do spread, da media e do desvio padrao
CTrade        m_trade                 ; // execucao das ordens
CSymbolInfo   m_symb1                 ; // propriedades do ativo 1
CSymbolInfo   m_symb2                 ; // propriedades do ativo 2

double        m_volume1        = 0    ; // volume normalizado para o ativo 1
double        m_volume2        = 0    ; // volume normalizado para o ativo 2

datetime      m_dt_ult_barra   = 0    ; // data da ultima barra ja contabilizada na janela
int           m_qtd_amostras   = 0    ; // qtd de spreads ja adicionados a janela

double        m_spread_atu     = 0    ; // spread instantaneo
double        m_spread_med     = 0    ; // media do spread na janela
double        m_spread_std     = 0    ; // desvio padrao do spread na janela
double        m_zscore         = 0    ; // (spread - media)/desvio
double        m_banda_sup      = 0    ; // media + k*desvio
double        m_banda_inf      = 0    ; // media - k*desvio

int           m_estado         = PAR_FLAT; // situacao atual do par
double        m_lucro_par      = 0    ; // resultado somado das duas pernas

//--- referencia registrada na abertura da posicao (usada pelo stop da media)
bool          m_abertura_reg   = false; // jah temos a referencia da abertura?
double        m_spread_abert   = 0    ; // spread no momento da abertura
double        m_med_abert      = 0    ; // media  do spread no momento da abertura
double        m_std_abert      = 0    ; // desvio do spread no momento da abertura
double        m_nivel_stop_med = 0    ; // nivel da media que aciona o stop
datetime      m_dt_abert       = 0    ; // data da abertura

string        m_ult_simulado   = ""   ; // ultima acao simulada logada (evita repetir no log)
bool          m_pos_invalida   = false; // pernas abertas que nao formam um spread e nao foram desmontadas

bool          m_inicializado   = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){

    Print(":-| ", __FUNCTION__, " ************************************************");
    Print(":-| ", __FUNCTION__, " Iniciando : ", TimeCurrent() );
    Print(":-| ", __FUNCTION__, " EA        : ", m_name        );
    Print(":-| ", __FUNCTION__, " MAGIC     : ", EA_MAGIC      );
    Print(":-| ", __FUNCTION__, " BUILDER   : ", __MQLBUILD__  );
    Print(":-| ", __FUNCTION__, " ************************************************");

    if( !inicializarSimbolos()  ) return INIT_PARAMETERS_INCORRECT;
    if( !inicializarParametros()) return INIT_PARAMETERS_INCORRECT;

    m_trade.SetExpertMagicNumber( EA_MAGIC         );
    m_trade.SetDeviationInPoints( EA_DESVIO_PONTOS );
    m_trade.LogLevel            ( LOG_LEVEL_ERRORS );

    // janela de EA_QTD_PERIODOS amostras. A classe filtra adicoes com menos de 1 segundo
    // de intervalo, o que nao nos afeta pois adicionamos no maximo uma amostra por barra.
    m_pairs.initialize( EA_QTD_PERIODOS );

    logarModoOperacao();
    sugerirVolumeEquilibrio();

    carregarHistorico();
    reconhecerPosicoes(); // o EA pode estar sendo iniciado no meio de uma operacao

    EventSetMillisecondTimer( EA_QTD_MILISEG_TIMER );
    Print(":-| ", __FUNCTION__, " Criado Timer de ", EA_QTD_MILISEG_TIMER, " milisegundos." );
    Print(":-) ", __FUNCTION__, " inicializado !! " );

    m_inicializado = true;
    processar();
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason){
    EventKillTimer();
    Comment("");
    Print(":-| ", __FUNCTION__, " finalizado. reason=", reason );
}

//+------------------------------------------------------------------+
void OnTick (){ processar(); }
void OnTimer(){ processar(); } // o grafico pode ser de um terceiro ativo, ou o ativo 2
                               // pode negociar quando o ativo 1 estah parado.

//+------------------------------------------------------------------+
//| Inicializacao dos dois ativos do par                             |
//+------------------------------------------------------------------+
bool inicializarSimbolos(){

    if( EA_SYMBOL_1 == EA_SYMBOL_2 ){
        Print(":-( ", __FUNCTION__, " SYMBOL_1 e SYMBOL_2 devem ser ativos diferentes." );
        return false;
    }

    if( !osc_trade_util::selecionarSimbolo(EA_SYMBOL_1) ) return false;
    if( !osc_trade_util::selecionarSimbolo(EA_SYMBOL_2) ) return false;

    m_symb1.Name( EA_SYMBOL_1 );
    m_symb2.Name( EA_SYMBOL_2 );
    m_symb1.Refresh(); m_symb1.RefreshRates();
    m_symb2.Refresh(); m_symb2.RefreshRates();

    Print(":-| ", __FUNCTION__, " ativo1:", EA_SYMBOL_1,
                  " digits:"   , m_symb1.Digits(),
                  " lots min/step/max:", m_symb1.LotsMin(), "/", m_symb1.LotsStep(), "/", m_symb1.LotsMax() );
    Print(":-| ", __FUNCTION__, " ativo2:", EA_SYMBOL_2,
                  " digits:"   , m_symb2.Digits(),
                  " lots min/step/max:", m_symb2.LotsMin(), "/", m_symb2.LotsStep(), "/", m_symb2.LotsMax() );
    return true;
}

//+------------------------------------------------------------------+
//| Validacao e normalizacao dos parametros de entrada               |
//+------------------------------------------------------------------+
bool inicializarParametros(){

    if( EA_QTD_PERIODOS < 2 ){
        Print(":-( ", __FUNCTION__, " QTD_PERIODOS deve ser no minimo 2. informado:", EA_QTD_PERIODOS );
        return false;
    }

    if( EA_DESVIOS_ENTRADA <= 0 ){
        Print(":-( ", __FUNCTION__, " DESVIOS_ENTRADA deve ser maior que zero. informado:", EA_DESVIOS_ENTRADA );
        return false;
    }

    if( EA_DESVIOS_SAIDA < 0 ){
        Print(":-( ", __FUNCTION__, " DESVIOS_SAIDA nao pode ser negativo. informado:", EA_DESVIOS_SAIDA );
        return false;
    }

    if( EA_DESVIOS_SAIDA >= EA_DESVIOS_ENTRADA ){
        Print(":-( ", __FUNCTION__, " DESVIOS_SAIDA (", EA_DESVIOS_SAIDA, ") deve ser menor que ",
                      "DESVIOS_ENTRADA (", EA_DESVIOS_ENTRADA, "), senao a posicao fecharia na propria abertura." );
        return false;
    }

    if( EA_STOP_MEDIA_ABERTURA && EA_STOP_DESVIOS_MEDIA < 0 ){
        Print(":-( ", __FUNCTION__, " STOP_DESVIOS_MEDIA nao pode ser negativo. informado:", EA_STOP_DESVIOS_MEDIA );
        return false;
    }

    if( EA_VOLUME <= 0 ){
        Print(":-( ", __FUNCTION__, " VOLUME deve ser maior que zero. informado:", EA_VOLUME );
        return false;
    }

    m_volume1 = osc_trade_util::normalizarVolume( m_symb1, EA_VOLUME );
    m_volume2 = osc_trade_util::normalizarVolume( m_symb2, EA_VOLUME );

    Print(":-| ", __FUNCTION__, " volume ", EA_SYMBOL_1, ":", m_volume1,
                                " volume ", EA_SYMBOL_2, ":", m_volume2 );

    if( m_volume1 != EA_VOLUME || m_volume2 != EA_VOLUME ){
        Print(":-| ", __FUNCTION__, " VOLUME ", EA_VOLUME, " foi ajustado aos limites dos ativos." );
    }
    return true;
}

//+------------------------------------------------------------------+
//| Modo de operacao e teclas de atalho (log do OnInit)              |
//+------------------------------------------------------------------+
void logarModoOperacao(){

    if( EA_OPERACAO_AUTOMATICA ){
        Print(":-| ", __FUNCTION__, " OPERACAO AUTOMATICA LIGADA: o EA abre e fecha as posicoes." );
    }else{
        Print(":-| ", __FUNCTION__, " OPERACAO AUTOMATICA DESLIGADA: o EA nao abre nem fecha posicao ",
                      "sozinho. Apenas loga [SIMULADO] o que faria. As teclas continuam valendo." );
    }

    if( !EA_TECLAS_HABILITADAS ){
        Print(":-| ", __FUNCTION__, " teclas de atalho desabilitadas." );
        return;
    }

    Print(":-| ", __FUNCTION__, " tecla para ABRIR : ", strTeclaAbrir () );
    Print(":-| ", __FUNCTION__, " tecla para FECHAR: ", strTeclaFechar() );
    Print(":-| ", __FUNCTION__, " as teclas so chegam ao EA com o grafico em foco. Se o ALT for ",
                  "capturado pelo menu do terminal, troque a combinacao nos parametros." );
}

string strTeclaAbrir (){
    return osc_trade_util::descreverTecla( EA_TECLA_CTRL, EA_TECLA_ALT, EA_TECLA_SHIFT, EA_TECLA_ABRIR  );
}

string strTeclaFechar(){
    return osc_trade_util::descreverTecla( EA_TECLA_CTRL, EA_TECLA_ALT, EA_TECLA_SHIFT, EA_TECLA_FECHAR );
}

//+------------------------------------------------------------------+
//| Sugestao de volume para o equilibrio financeiro das duas pernas  |
//|                                                                  |
//| O par soh eh neutro se uma mesma variacao percentual valer o     |
//| mesmo dinheiro nas duas pontas. Como cada ativo tem seu lote     |
//| minimo, seu passo e seu valor de tick, o volume igual nas duas   |
//| pernas quase nunca equilibra. Aqui procuramos o MENOR par de     |
//| volumes negociaveis que aproxima esse equilibrio.                |
//|                                                                  |
//| A sugestao nao altera nada: o EA continua operando com VOLUME.   |
//+------------------------------------------------------------------+
void sugerirVolumeEquilibrio(){

    if( !EA_SUGERIR_VOLUME ) return;

    // quanto vale, em dinheiro, 1% de variacao do preco, para o volume configurado...
    double val1_atu = osc_trade_util::valorPorPercentual( EA_SYMBOL_1, m_volume1, 0.01 );
    double val2_atu = osc_trade_util::valorPorPercentual( EA_SYMBOL_2, m_volume2, 0.01 );

    Print(":-| ", __FUNCTION__, " --- equilibrio financeiro das pernas (1% de variacao) ---" );
    Print(":-| ", __FUNCTION__, " ", EA_SYMBOL_1, " vol:", m_volume1,
                  " preco:", osc_trade_util::precoReferencia(EA_SYMBOL_1),
                  " valor de 1%:", DoubleToString(val1_atu,2), " ", AccountInfoString(ACCOUNT_CURRENCY) );
    Print(":-| ", __FUNCTION__, " ", EA_SYMBOL_2, " vol:", m_volume2,
                  " preco:", osc_trade_util::precoReferencia(EA_SYMBOL_2),
                  " valor de 1%:", DoubleToString(val2_atu,2), " ", AccountInfoString(ACCOUNT_CURRENCY) );

    if( val1_atu > 0 && val2_atu > 0 ){
        double desequil = MathAbs(val1_atu-val2_atu)/MathMax(val1_atu,val2_atu);
        Print(":-| ", __FUNCTION__, " desequilibrio do volume configurado: ",
                      DoubleToString(desequil*100,2), "%" );
    }

    double vol1=0, vol2=0, erro=0;
    if( !osc_trade_util::calcVolumesEquilibrio( EA_SYMBOL_1, EA_SYMBOL_2, vol1, vol2, erro,
                                                EA_TOLERANCIA_EQUIL ) ){
        Print(":-( ", __FUNCTION__, " nao foi possivel calcular o volume de equilibrio. ",
                      "Verifique cotacao e tick value dos ativos." );
        return;
    }

    double val1_sug = osc_trade_util::valorPorPercentual( EA_SYMBOL_1, vol1, 0.01 );
    double val2_sug = osc_trade_util::valorPorPercentual( EA_SYMBOL_2, vol2, 0.01 );

    Print(":-) ", __FUNCTION__, " SUGESTAO de volume minimo para equilibrio: ",
                  EA_SYMBOL_1, ":", vol1, " (1% = ", DoubleToString(val1_sug,2), ") ",
                  EA_SYMBOL_2, ":", vol2, " (1% = ", DoubleToString(val2_sug,2), ") ",
                  " desequilibrio residual:", DoubleToString(erro*100,2), "%" );

    if( erro > EA_TOLERANCIA_EQUIL ){
        Print(":-| ", __FUNCTION__, " o melhor par encontrado ainda ficou acima da tolerancia de ",
                      DoubleToString(EA_TOLERANCIA_EQUIL*100,2), "%. Os lotes minimos dos dois ativos ",
                      "nao permitem um casamento melhor nesta faixa de volume." );
    }

    Print(":-| ", __FUNCTION__, " a sugestao nao altera o EA: ele continua operando com VOLUME=", EA_VOLUME, "." );
}

//+------------------------------------------------------------------+
//| Carga inicial da janela com as ultimas barras fechadas           |
//+------------------------------------------------------------------+
void carregarHistorico(){

    MqlRates rates1[];
    ArraySetAsSeries(rates1,false); // ordem crescente de data

    int qtd = CopyRates( EA_SYMBOL_1, EA_TIMEFRAME, 1, EA_QTD_PERIODOS, rates1 );
    if( qtd <= 0 ){
        Print(":-| ", __FUNCTION__, " sem historico de ", EA_SYMBOL_1,
                      " ainda. A janela serah preenchida barra a barra. erro=", GetLastError() );
        return;
    }

    // forcando o carregamento do historico do ativo 2...
    MqlRates aux[];
    CopyRates( EA_SYMBOL_2, EA_TIMEFRAME, 1, EA_QTD_PERIODOS, aux );

    for(int i=0; i<qtd; i++){
        double preco2 = 0;
        if( !getFechamentoAtivo2( rates1[i].time, preco2 ) ) continue;
        adicionarAmostra( rates1[i].close, preco2, rates1[i].time );
    }

    m_dt_ult_barra = rates1[qtd-1].time;

    Print(":-| ", __FUNCTION__, " ", m_qtd_amostras, "/", EA_QTD_PERIODOS,
                  " amostras carregadas. ultima barra:", m_dt_ult_barra,
                  " media:", m_spread_med, " desvio:", m_spread_std );
}

// fechamento do ativo 2 na barra de data dt. Se o ativo 2 nao tiver barra nessa data
// exata (nao negociou no periodo), usa o fechamento da barra imediatamente anterior.
bool getFechamentoAtivo2(const datetime dt, double &preco){
    preco = 0;

    MqlRates rates2[];
    ArraySetAsSeries(rates2,false);
    if( CopyRates( EA_SYMBOL_2, EA_TIMEFRAME, dt, 1, rates2 ) == 1 ){
        preco = rates2[0].close;
        return (preco > 0);
    }

    int shift = iBarShift( EA_SYMBOL_2, EA_TIMEFRAME, dt, false );
    if( shift < 0 ) return false;

    preco = iClose( EA_SYMBOL_2, EA_TIMEFRAME, shift );
    return (preco > 0);
}

// adiciona uma amostra de spread a janela e atualiza media e desvio.
void adicionarAmostra(const double p1, const double p2, const datetime dt){
    if( p1 <= 0 || p2 <= 0 ) return;

    m_pairs.calcSpread( p1, p2, dt );
    if( m_qtd_amostras < EA_QTD_PERIODOS ) m_qtd_amostras++;

    m_spread_med = m_pairs.getSpreadMed();
    m_spread_std = m_pairs.getSpreadStd();
}

//+------------------------------------------------------------------+
//| Alimenta a janela quando uma nova barra fecha                    |
//+------------------------------------------------------------------+
void atualizarEstatistica(){

    MqlRates rates1[];
    ArraySetAsSeries(rates1,false);
    if( CopyRates( EA_SYMBOL_1, EA_TIMEFRAME, 1, 1, rates1 ) != 1 ) return;

    if( rates1[0].time <= m_dt_ult_barra ) return; // barra ja contabilizada

    double preco2 = 0;
    if( getFechamentoAtivo2( rates1[0].time, preco2 ) ){
        adicionarAmostra( rates1[0].close, preco2, rates1[0].time );
    }

    // marca a barra como processada mesmo sem o par, para nao travar a janela
    // caso o ativo 2 fique sem cotacao em algum periodo.
    m_dt_ult_barra = rates1[0].time;
}

//+------------------------------------------------------------------+
//| Ciclo principal                                                  |
//+------------------------------------------------------------------+
void processar(){

    if( !m_inicializado ) return;

    atualizarEstatistica();

    if( !atualizarPrecos() ) return;

    reconhecerPosicoes();

    // pernas abertas que nao formam um spread e que o EA nao pode desmontar (operacao
    // manual): nao dah para avaliar entrada nem saida enquanto isso nao for resolvido.
    if( m_pos_invalida    ){ showTela(); return; }

    if( !janelaCompleta() ){ showTela(); return; }

    if( m_estado == PAR_FLAT ){
        verificarEntrada();
    }else{
        verificarSaida();
    }

    showTela();
}

// atualiza o spread instantaneo e as bandas de operacao. Retorna falso se nao
// foi possivel obter cotacao dos dois ativos.
bool atualizarPrecos(){

    MqlTick t1, t2;
    if( !SymbolInfoTick(EA_SYMBOL_1,t1) ) return false;
    if( !SymbolInfoTick(EA_SYMBOL_2,t2) ) return false;

    double p1 = m_pairs.getLast(t1);
    double p2 = m_pairs.getLast(t2);
    if( p1 <= 0 || p2 <= 0 ) return false;

    m_spread_atu = log(p1) - log(p2);
    if( !MathIsValidNumber(m_spread_atu) ) return false;

    m_spread_med = m_pairs.getSpreadMed();
    m_spread_std = m_pairs.getSpreadStd();

    // bandas calculadas pela propria classe: media + shift*desvio
    m_banda_sup  = m_pairs.getSpreadStd(  EA_DESVIOS_ENTRADA );
    m_banda_inf  = m_pairs.getSpreadStd( -EA_DESVIOS_ENTRADA );
    m_zscore     = (m_spread_std > 0) ? (m_spread_atu-m_spread_med)/m_spread_std : 0;

    return true;
}

// a janela precisa estar cheia e com dispersao valida para operar.
bool janelaCompleta(){
    return ( m_qtd_amostras >= EA_QTD_PERIODOS && m_spread_std > 0 );
}

//+------------------------------------------------------------------+
//| Entrada                                                          |
//+------------------------------------------------------------------+
void verificarEntrada(){

    if( m_spread_atu > m_banda_sup ){
        // ativo1 caro em relacao ao ativo2: vende o caro e compra o barato.
        string motivo = "spread " + DoubleToString(m_spread_atu,8) + " acima da banda " +
                        DoubleToString(m_banda_sup,8) + " (z=" + DoubleToString(m_zscore,2) + ")";
        solicitarAbertura( PAR_SHORT_SPREAD, motivo, false );
        return;
    }

    if( m_spread_atu < m_banda_inf ){
        // ativo1 barato em relacao ao ativo2: compra o barato e vende o caro.
        string motivo = "spread " + DoubleToString(m_spread_atu,8) + " abaixo da banda " +
                        DoubleToString(m_banda_inf,8) + " (z=" + DoubleToString(m_zscore,2) + ")";
        solicitarAbertura( PAR_LONG_SPREAD, motivo, false );
        return;
    }

    limparSimulado(); // spread dentro das bandas: nenhuma entrada pendente
}

// porta de entrada de toda abertura. Quando a operacao automatica estah desligada,
// as entradas do EA (manual=false) viram apenas log. As teclas (manual=true) passam.
bool solicitarAbertura(const int direcao, const string motivo, const bool manual){

    if( !manual && !EA_OPERACAO_AUTOMATICA ){
        logarSimulado( "ABRIR:"+IntegerToString(direcao),
                       "ABRIRIA " + descreverDirecao(direcao) + ". motivo: " + motivo );
        return false;
    }

    Print(":-| ", __FUNCTION__, (manual?" [TECLA] ":" "), "abrindo ", descreverDirecao(direcao),
                  ". motivo: ", motivo );
    return abrirPar( direcao );
}

// porta de entrada de todo fechamento. Mesma regra da abertura.
// chave: identifica a condicao que pediu o fechamento, para o controle do log simulado.
bool solicitarFechamento(const string chave, const string motivo, const bool manual){

    if( m_estado == PAR_FLAT ) return false;

    if( !manual && !EA_OPERACAO_AUTOMATICA ){
        logarSimulado( chave, "FECHARIA o par (" + estadoStr() + "). motivo: " + motivo );
        return false;
    }

    fecharPar( (manual ? "[TECLA] " : "") + motivo );
    return ( m_estado == PAR_FLAT );
}

// abre as duas pernas. Se a segunda perna falhar, desfaz a primeira para nao
// deixar posicao direcional em aberto.
bool abrirPar(const int direcao){

    ENUM_ORDER_TYPE tipo1 = (direcao==PAR_LONG_SPREAD) ? ORDER_TYPE_BUY  : ORDER_TYPE_SELL;
    ENUM_ORDER_TYPE tipo2 = (direcao==PAR_LONG_SPREAD) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY ;

    if( !enviarMercado( EA_SYMBOL_1, tipo1, m_volume1 ) ){
        Print(":-( ", __FUNCTION__, " falha na perna 1 (", EA_SYMBOL_1, "). operacao abortada." );
        return false;
    }

    if( !enviarMercado( EA_SYMBOL_2, tipo2, m_volume2 ) ){
        Print(":-( ", __FUNCTION__, " falha na perna 2 (", EA_SYMBOL_2,
                      "). desfazendo a perna 1 (", EA_SYMBOL_1, ")..." );
        fecharSimbolo( EA_SYMBOL_1 );
        return false;
    }

    m_estado = direcao;
    registrarAbertura( direcao, false );

    Print(":-) ", __FUNCTION__, " par aberto. estado=", estadoStr(), " spread=", m_spread_atu,
                  " media=", m_spread_med, " desvio=", m_spread_std );
    return true;
}

// guarda o spread, a media e o desvio do momento da abertura. Sao eles que definem o
// nivel do stop pelo deslocamento da media (STOP_MEDIA_ABERTURA).
void registrarAbertura(const int direcao, const bool herdada){

    m_abertura_reg = true;
    m_spread_abert = m_spread_atu;
    m_med_abert    = m_spread_med;
    m_std_abert    = m_spread_std;
    m_dt_abert     = TimeCurrent();
    m_ult_simulado = "";

    // o stop eh acionado quando a media se desloca ateh o spread de abertura, no sentido
    // contrario ao da operacao: para cima em quem estah vendido no spread, para baixo em
    // quem estah comprado.
    m_nivel_stop_med = (direcao==PAR_SHORT_SPREAD)
                     ? m_spread_abert + EA_STOP_DESVIOS_MEDIA*m_std_abert
                     : m_spread_abert - EA_STOP_DESVIOS_MEDIA*m_std_abert;

    Print(":-| ", __FUNCTION__, (herdada?" (posicao jah estava aberta - referencia adotada do mercado atual) ":" "),
                  "referencia da abertura. spread:", m_spread_abert,
                  " media:", m_med_abert, " desvio:", m_std_abert,
                  (EA_STOP_MEDIA_ABERTURA ? "  stop da media em:"+DoubleToString(m_nivel_stop_med,8)
                                          : "  (stop da media desligado)") );
}

void limparAbertura(){
    m_abertura_reg   = false;
    m_spread_abert   = 0;
    m_med_abert      = 0;
    m_std_abert      = 0;
    m_nivel_stop_med = 0;
    m_dt_abert       = 0;
    m_ult_simulado   = "";
}

string descreverDirecao(const int direcao){
    if( direcao == PAR_LONG_SPREAD  ) return "LONG SPREAD (COMPRA "+EA_SYMBOL_1+" / VENDE "+EA_SYMBOL_2+")";
    if( direcao == PAR_SHORT_SPREAD ) return "SHORT SPREAD (VENDE "+EA_SYMBOL_1+" / COMPRA "+EA_SYMBOL_2+")";
    return "FLAT";
}

// loga a acao que o EA tomaria se estivesse operando automaticamente.
//
// A condicao eh reavaliada a cada tick e a mensagem carrega precos, que mudam sempre.
// Por isso a repeticao eh controlada pela chave (a condicao em si) e nao pelo texto:
// logamos uma vez quando a condicao aparece e so voltamos a logar se ela sumir e
// aparecer de novo (quem limpa a chave eh limparSimulado).
void logarSimulado(const string chave, const string acao){
    if( chave == m_ult_simulado ) return;
    m_ult_simulado = chave;
    Print(":-| [SIMULADO] ", acao, " (OPERACAO_AUTOMATICA=false)" );
}

// nenhuma condicao de acao ativa neste ciclo: a proxima que aparecer volta a ser logada.
void limparSimulado(){ m_ult_simulado = ""; }

//+------------------------------------------------------------------+
//| Saida                                                            |
//+------------------------------------------------------------------+
void verificarSaida(){

    // 1. stop financeiro sobre o resultado somado das duas pernas...
    if( EA_STOP_FINANCEIRO > 0 && m_lucro_par <= -EA_STOP_FINANCEIRO ){
        string motivo = "stop financeiro. resultado do par:" + DoubleToString(m_lucro_par,2) +
                        " limite:" + DoubleToString(-EA_STOP_FINANCEIRO,2);
        solicitarFechamento( "FECHAR_STOP_FIN", motivo, false );
        return;
    }

    // 2. stop pelo deslocamento da media...
    //    a media alcancou o spread registrado na abertura (mais os desvios daquele momento),
    //    no sentido contrario ao da operacao. Nao foi o spread que voltou para a media: foi a
    //    media que foi atras do spread. A premissa de reversao nao vale mais.
    if( atingiuStopDaMedia() ){
        string motivo = "stop da media. media:" + DoubleToString(m_spread_med,8) +
                        " alcancou o nivel de abertura:" + DoubleToString(m_nivel_stop_med,8) +
                        " (spread abertura:" + DoubleToString(m_spread_abert,8) +
                        " +- " + DoubleToString(EA_STOP_DESVIOS_MEDIA,2) +
                        " x desvio:" + DoubleToString(m_std_abert,8) + ")";
        solicitarFechamento( "FECHAR_STOP_MEDIA", motivo, false );
        return;
    }

    // 3. retorno do spread a media, ou ateh DESVIOS_SAIDA de distancia dela...
    //    entramos vendidos no spread acima da media: saimos quando ele cai ateh o alvo.
    //    entramos comprados no spread abaixo da media: saimos quando ele sobe ateh o alvo.
    double alvo = alvoDeSaida();

    if( ( m_estado == PAR_SHORT_SPREAD && m_spread_atu <= alvo ) ||
        ( m_estado == PAR_LONG_SPREAD  && m_spread_atu >= alvo ) ){
        string motivo = (EA_DESVIOS_SAIDA > 0)
                      ? "spread " + DoubleToString(m_spread_atu,8) + " alcancou o alvo " +
                        DoubleToString(alvo,8) + " (" + DoubleToString(EA_DESVIOS_SAIDA,2) +
                        " desvios da media " + DoubleToString(m_spread_med,8) + ")"
                      : "spread " + DoubleToString(m_spread_atu,8) + " retornou a media " +
                        DoubleToString(m_spread_med,8);
        solicitarFechamento( "FECHAR_ALVO", motivo, false );
        return;
    }

    limparSimulado(); // nenhuma condicao de saida ativa
}

// nivel de spread onde a posicao eh fechada. Com DESVIOS_SAIDA=0 eh a propria media.
// Com DESVIOS_SAIDA>0 o alvo fica antes da media, do lado de onde viemos:
// entrada a 2.0 desvios e saida a 0.5 desvios, por exemplo.
double alvoDeSaida(){ return alvoDeSaida( m_estado ); }

double alvoDeSaida(const int direcao){
    if( EA_DESVIOS_SAIDA <= 0 ) return m_spread_med;
    if( direcao == PAR_SHORT_SPREAD ) return m_spread_med + EA_DESVIOS_SAIDA*m_spread_std;
    if( direcao == PAR_LONG_SPREAD  ) return m_spread_med - EA_DESVIOS_SAIDA*m_spread_std;
    return m_spread_med;
}

// o spread jah estah no (ou alem do) alvo de saida da direcao informada?
bool jahNoAlvoDeSaida(const int direcao){
    double alvo = alvoDeSaida( direcao );
    if( direcao == PAR_SHORT_SPREAD ) return ( m_spread_atu <= alvo );
    if( direcao == PAR_LONG_SPREAD  ) return ( m_spread_atu >= alvo );
    return false;
}

// a media do spread alcancou o nivel registrado na abertura da posicao?
bool atingiuStopDaMedia(){

    if( !EA_STOP_MEDIA_ABERTURA ) return false;
    if( !m_abertura_reg         ) return false;
    if( m_estado == PAR_FLAT    ) return false;

    if( m_estado == PAR_SHORT_SPREAD ) return ( m_spread_med >= m_nivel_stop_med );
    return ( m_spread_med <= m_nivel_stop_med );
}

// fecha as duas pernas do par.
void fecharPar(const string motivo){

    Print(":-| ", __FUNCTION__, "(", motivo, ") fechando ", EA_SYMBOL_1, " e ", EA_SYMBOL_2,
                  ". resultado do par:", m_lucro_par );

    bool ok1 = fecharSimbolo( EA_SYMBOL_1 );
    bool ok2 = fecharSimbolo( EA_SYMBOL_2 );

    if( ok1 && ok2 ){
        m_estado = PAR_FLAT;
        limparAbertura();
        Print(":-) ", __FUNCTION__, "(", motivo, ") par fechado." );
    }else{
        Print(":-( ", __FUNCTION__, "(", motivo, ") fechamento incompleto. ",
                      EA_SYMBOL_1, ":", ok1, " ", EA_SYMBOL_2, ":", ok2,
                      ". nova tentativa no proximo ciclo." );
    }
}

//+------------------------------------------------------------------+
//| Posicoes                                                         |
//+------------------------------------------------------------------+

// reconhece o estado do par a partir das posicoes realmente abertas. Permite que o
// EA seja reiniciado no meio de uma operacao e detecta pernas orfas.
void reconhecerPosicoes(){

    m_pos_invalida = false;

    int dir1 = direcaoPosicao( EA_SYMBOL_1 );
    int dir2 = direcaoPosicao( EA_SYMBOL_2 );

    m_lucro_par = lucroSimbolo( EA_SYMBOL_1 ) + lucroSimbolo( EA_SYMBOL_2 );

    if( dir1 == 0 && dir2 == 0 ){
        if( m_abertura_reg ) limparAbertura();
        m_estado = PAR_FLAT;
        return;
    }

    // perna orfa: uma das pontas ficou aberta sozinha. Nao eh operacao de spread,
    // eh exposicao direcional. Desmonta.
    if( dir1 == 0 || dir2 == 0 ){
        desmontarPosicaoInvalida( "perna orfa detectada. " + EA_SYMBOL_1 + ":" + IntegerToString(dir1) +
                                  " " + EA_SYMBOL_2 + ":" + IntegerToString(dir2) );
        return;
    }

    // as duas pernas no mesmo sentido tambem nao formam um spread.
    if( dir1 == dir2 ){
        desmontarPosicaoInvalida( "as duas pernas estao no mesmo sentido (" + IntegerToString(dir1) + ")" );
        return;
    }

    m_estado = dir1; // comprado no ativo1 = comprado no spread

    // o EA pode ter sido reiniciado (ou a posicao pode ter sido aberta na mao) com o par
    // jah montado. Nesse caso nao temos a referencia da abertura: adotamos a atual.
    if( !m_abertura_reg && m_spread_std > 0 ) registrarAbertura( m_estado, true );
}

// desfaz uma combinacao de pernas que nao forma um spread. Respeita OPERACAO_AUTOMATICA:
// sem ela, o EA nao desmonta nada, apenas avisa.
void desmontarPosicaoInvalida(const string motivo){

    if( !EA_OPERACAO_AUTOMATICA ){
        m_pos_invalida = true;
        logarSimulado( "DESMONTAR", "DESMONTARIA as posicoes: " + motivo );
        return;
    }

    Print(":-( ", __FUNCTION__, " ", motivo, ". desmontando..." );
    fecharSimbolo( EA_SYMBOL_1 );
    fecharSimbolo( EA_SYMBOL_2 );
    m_estado = PAR_FLAT;
    limparAbertura();
}

// +1 comprado, -1 vendido, 0 sem posicao do EA no ativo informado.
int direcaoPosicao(const string symb){
    return osc_trade_util::direcaoPosicao( symb, EA_MAGIC );
}

// resultado nao realizado (lucro + swap) das posicoes do EA no ativo informado.
double lucroSimbolo(const string symb){
    return osc_trade_util::lucroPosicao( symb, EA_MAGIC );
}

// fecha todas as posicoes do EA no ativo informado. Retorna true se nao restou posicao.
bool fecharSimbolo(const string symb){
    return osc_trade_util::fecharSimbolo( m_trade, symb, EA_MAGIC, EA_DESVIO_PONTOS );
}

// envia ordem a mercado para o ativo informado.
bool enviarMercado(const string symb, const ENUM_ORDER_TYPE tipo, const double volume){
    return osc_trade_util::enviarMercado( m_trade, symb, tipo, volume, m_name );
}

//+------------------------------------------------------------------+
//| Teclas de atalho                                                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam){

    if( id != CHARTEVENT_KEYDOWN  ) return;
    if( !EA_TECLAS_HABILITADAS    ) return;
    if( !m_inicializado           ) return;

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

    if( tecla == EA_TECLA_ABRIR  ){ abrirPorTecla (); return; }
    if( tecla == EA_TECLA_FECHAR ){ fecharPorTecla(); return; }
}

// abertura manual. O lado eh o mesmo que o EA escolheria: se o spread estah acima da
// media, vende o spread; se estah abaixo, compra. A distancia ateh a banda de entrada
// nao eh exigida, afinal a ordem partiu do operador.
void abrirPorTecla(){

    Print(":-| ", __FUNCTION__, " tecla ", strTeclaAbrir(), " pressionada." );

    if( !atualizarPrecos() ){
        Print(":-( ", __FUNCTION__, " sem cotacao dos dois ativos. abertura cancelada." );
        return;
    }

    reconhecerPosicoes();

    if( m_estado != PAR_FLAT ){
        Print(":-| ", __FUNCTION__, " jah existe posicao aberta (", estadoStr(), "). nada a fazer." );
        return;
    }

    if( m_qtd_amostras < 1 || m_spread_med == 0 ){
        Print(":-( ", __FUNCTION__, " a janela ainda nao tem media do spread: nao dah para escolher ",
                      "o lado da operacao. abertura cancelada." );
        return;
    }

    int direcao = ( m_spread_atu >= m_spread_med ) ? PAR_SHORT_SPREAD : PAR_LONG_SPREAD;

    // avisamos quando a posicao jah nasce dentro da regiao de saida: com a operacao
    // automatica ligada, o proprio EA a fecharia no ciclo seguinte.
    if( EA_OPERACAO_AUTOMATICA && jahNoAlvoDeSaida(direcao) ){
        Print(":-| ", __FUNCTION__, " ATENCAO: o spread ", m_spread_atu, " jah estah no alvo de saida ",
                      alvoDeSaida(direcao), ". Com OPERACAO_AUTOMATICA ligada o EA fecha esta posicao ",
                      "no proximo ciclo." );
    }

    string motivo  = "abertura manual por tecla. spread:" + DoubleToString(m_spread_atu,8) +
                     " media:" + DoubleToString(m_spread_med,8) +
                     " z:" + DoubleToString(m_zscore,2) +
                     ( janelaCompleta() ? "" : "  (ATENCAO: janela ainda incompleta)" );

    solicitarAbertura( direcao, motivo, true );
    showTela();
}

// fechamento manual das duas pernas.
void fecharPorTecla(){

    Print(":-| ", __FUNCTION__, " tecla ", strTeclaFechar(), " pressionada." );

    atualizarPrecos();
    reconhecerPosicoes();

    if( m_estado == PAR_FLAT ){
        Print(":-| ", __FUNCTION__, " nao ha posicao aberta. nada a fazer." );
        return;
    }

    solicitarFechamento( "FECHAR_TECLA",
                         "fechamento manual por tecla. resultado do par:" +
                         DoubleToString(m_lucro_par,2), true );
    showTela();
}

//+------------------------------------------------------------------+
//| Tela                                                             |
//+------------------------------------------------------------------+
string estadoStr(){
    if( m_estado == PAR_LONG_SPREAD  ) return "LONG SPREAD  (C " +EA_SYMBOL_1+" / V "+EA_SYMBOL_2+")";
    if( m_estado == PAR_SHORT_SPREAD ) return "SHORT SPREAD (V " +EA_SYMBOL_1+" / C "+EA_SYMBOL_2+")";
    return "FLAT";
}

void showTela(){

    if( !EA_SHOW_TELA ) return;

    Comment(
        m_name, "\n",
        "Par            : ", EA_SYMBOL_1, " / ", EA_SYMBOL_2, "\n",
        "Janela         : ", EA_QTD_PERIODOS, " barras de ", EnumToString(EA_TIMEFRAME),
                             "   (", m_qtd_amostras, " amostras", (janelaCompleta()?"":" - AGUARDANDO"), ")\n",
        "Spread atual   : ", DoubleToString(m_spread_atu, 8), "\n",
        "Spread medio   : ", DoubleToString(m_spread_med, 8), "\n",
        "Desvio padrao  : ", DoubleToString(m_spread_std, 8), "\n",
        "Banda superior : ", DoubleToString(m_banda_sup , 8), "  (+", DoubleToString(EA_DESVIOS_ENTRADA,2), " dp)\n",
        "Banda inferior : ", DoubleToString(m_banda_inf , 8), "  (-", DoubleToString(EA_DESVIOS_ENTRADA,2), " dp)\n",
        "Z-score        : ", DoubleToString(m_zscore    , 2), "\n",
        "Alvo de saida  : ", DoubleToString(alvoDeSaida(), 8),
                             (EA_DESVIOS_SAIDA>0 ? "  ("+DoubleToString(EA_DESVIOS_SAIDA,2)+" dp da media)"
                                                 : "  (na media)"), "\n",
        "Estado         : ", estadoStr(), (m_pos_invalida?"   *** PERNAS INVALIDAS - NAO DESMONTADAS ***":""), "\n",
        strTelaAbertura(),
        "Resultado par  : ", DoubleToString(m_lucro_par , 2),
                             (EA_STOP_FINANCEIRO>0 ? "   (stop em -"+DoubleToString(EA_STOP_FINANCEIRO,2)+")" : "   (sem stop)"), "\n",
        "Operacao       : ", (EA_OPERACAO_AUTOMATICA ? "AUTOMATICA" : "MANUAL (o EA so loga o que faria)"), "\n",
        "Teclas         : ", (EA_TECLAS_HABILITADAS
                              ? strTeclaAbrir()+" abre  /  "+strTeclaFechar()+" fecha"
                              : "desabilitadas"), "\n"
    );
}

// linha da tela com a referencia da abertura e o nivel do stop da media.
string strTelaAbertura(){

    if( m_estado == PAR_FLAT || !m_abertura_reg ) return "";

    string s = "Abertura       : " + TimeToString(m_dt_abert,TIME_DATE|TIME_SECONDS) +
               "   spread " + DoubleToString(m_spread_abert,8) +
               "   desvio " + DoubleToString(m_std_abert,8) + "\n";

    if( EA_STOP_MEDIA_ABERTURA ){
        s += "Stop da media  : " + DoubleToString(m_nivel_stop_med,8) +
             "   (media atual " + DoubleToString(m_spread_med,8) + ")\n";
    }
    return s;
}
//+------------------------------------------------------------------+
