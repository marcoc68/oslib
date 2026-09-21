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
//|    - Saida: quando o spread retorna a media, fecha as duas       |
//|      pernas. Opcionalmente, stop financeiro sobre o resultado    |
//|      somado das duas pernas.                                     |
//|                                                                  |
//|    - Uma operacao por vez. Volume igual nas duas pernas.         |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, OS Corp."
#property link      "http://www.os.org"
#property version   "8.001"

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <oslib/osc/est/C00021Pairs.mqh>

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

input group "=== Volume ===";
input double         EA_VOLUME          = 0.10        ; //VOLUME lote aplicado igualmente nas duas pernas

input group "=== Stop ===";
input double         EA_STOP_FINANCEIRO = 0.0         ; //STOP_FINANCEIRO perda maxima somada das duas pernas, na moeda da conta. 0=desligado

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

    if( !selecionarSimbolo(EA_SYMBOL_1) ) return false;
    if( !selecionarSimbolo(EA_SYMBOL_2) ) return false;

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

// coloca o ativo no Observacao de Mercado, se ainda nao estiver.
bool selecionarSimbolo(const string symb){
    if( !SymbolSelect(symb,true) ){
        Print(":-( ", __FUNCTION__, " nao foi possivel selecionar o ativo ", symb, ". erro=", GetLastError() );
        return false;
    }
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

    if( EA_VOLUME <= 0 ){
        Print(":-( ", __FUNCTION__, " VOLUME deve ser maior que zero. informado:", EA_VOLUME );
        return false;
    }

    m_volume1 = normalizarVolume( m_symb1, EA_VOLUME );
    m_volume2 = normalizarVolume( m_symb2, EA_VOLUME );

    Print(":-| ", __FUNCTION__, " volume ", EA_SYMBOL_1, ":", m_volume1,
                                " volume ", EA_SYMBOL_2, ":", m_volume2 );

    if( m_volume1 != EA_VOLUME || m_volume2 != EA_VOLUME ){
        Print(":-| ", __FUNCTION__, " VOLUME ", EA_VOLUME, " foi ajustado aos limites dos ativos." );
    }
    return true;
}

// ajusta o volume aos limites (minimo, maximo e passo) do ativo.
double normalizarVolume(CSymbolInfo &symb, const double vol){
    double step = symb.LotsStep(); if( step <= 0 ) step = 0.01;
    double v    = MathRound(vol/step)*step;
    if( v < symb.LotsMin() ) v = symb.LotsMin();
    if( v > symb.LotsMax() ) v = symb.LotsMax();
    return NormalizeDouble( v, digitosDoPasso(step) );
}

// quantidade de casas decimais correspondente ao passo de volume informado.
int digitosDoPasso(const double step){
    for(int d=0; d<8; d++){
        double escala = MathPow(10,d);
        if( MathAbs( step*escala - MathRound(step*escala) ) < 1e-9 ) return d;
    }
    return 8;
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
        Print(":-| ", __FUNCTION__, " spread ", m_spread_atu, " acima da banda ", m_banda_sup,
                      " (z=", m_zscore, "). VENDE ", EA_SYMBOL_1, " / COMPRA ", EA_SYMBOL_2 );
        abrirPar( PAR_SHORT_SPREAD );
        return;
    }

    if( m_spread_atu < m_banda_inf ){
        // ativo1 barato em relacao ao ativo2: compra o barato e vende o caro.
        Print(":-| ", __FUNCTION__, " spread ", m_spread_atu, " abaixo da banda ", m_banda_inf,
                      " (z=", m_zscore, "). COMPRA ", EA_SYMBOL_1, " / VENDE ", EA_SYMBOL_2 );
        abrirPar( PAR_LONG_SPREAD );
        return;
    }
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
    Print(":-) ", __FUNCTION__, " par aberto. estado=", estadoStr(), " spread=", m_spread_atu,
                  " media=", m_spread_med, " desvio=", m_spread_std );
    return true;
}

//+------------------------------------------------------------------+
//| Saida                                                            |
//+------------------------------------------------------------------+
void verificarSaida(){

    // 1. stop financeiro sobre o resultado somado das duas pernas...
    if( EA_STOP_FINANCEIRO > 0 && m_lucro_par <= -EA_STOP_FINANCEIRO ){
        Print(":-| ", __FUNCTION__, " STOP FINANCEIRO acionado. resultado do par:", m_lucro_par,
                      " limite:", -EA_STOP_FINANCEIRO );
        fecharPar("stop financeiro");
        return;
    }

    // 2. retorno do spread a media...
    //    entramos vendidos no spread acima da media: saimos quando ele cai ateh a media.
    //    entramos comprados no spread abaixo da media: saimos quando ele sobe ateh a media.
    if( m_estado == PAR_SHORT_SPREAD && m_spread_atu <= m_spread_med ){
        Print(":-| ", __FUNCTION__, " spread ", m_spread_atu, " retornou a media ", m_spread_med, "." );
        fecharPar("retorno a media");
        return;
    }

    if( m_estado == PAR_LONG_SPREAD && m_spread_atu >= m_spread_med ){
        Print(":-| ", __FUNCTION__, " spread ", m_spread_atu, " retornou a media ", m_spread_med, "." );
        fecharPar("retorno a media");
        return;
    }
}

// fecha as duas pernas do par.
void fecharPar(const string motivo){

    Print(":-| ", __FUNCTION__, "(", motivo, ") fechando ", EA_SYMBOL_1, " e ", EA_SYMBOL_2,
                  ". resultado do par:", m_lucro_par );

    bool ok1 = fecharSimbolo( EA_SYMBOL_1 );
    bool ok2 = fecharSimbolo( EA_SYMBOL_2 );

    if( ok1 && ok2 ){
        m_estado = PAR_FLAT;
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

    int dir1 = direcaoPosicao( EA_SYMBOL_1 );
    int dir2 = direcaoPosicao( EA_SYMBOL_2 );

    m_lucro_par = lucroSimbolo( EA_SYMBOL_1 ) + lucroSimbolo( EA_SYMBOL_2 );

    if( dir1 == 0 && dir2 == 0 ){ m_estado = PAR_FLAT; return; }

    // perna orfa: uma das pontas ficou aberta sozinha. Nao eh operacao de spread,
    // eh exposicao direcional. Desmonta.
    if( dir1 == 0 || dir2 == 0 ){
        Print(":-( ", __FUNCTION__, " perna orfa detectada. ", EA_SYMBOL_1, ":", dir1,
                      " ", EA_SYMBOL_2, ":", dir2, ". desmontando..." );
        fecharSimbolo( EA_SYMBOL_1 );
        fecharSimbolo( EA_SYMBOL_2 );
        m_estado = PAR_FLAT;
        return;
    }

    // as duas pernas no mesmo sentido tambem nao formam um spread.
    if( dir1 == dir2 ){
        Print(":-( ", __FUNCTION__, " as duas pernas estao no mesmo sentido (", dir1,
                      "). desmontando..." );
        fecharSimbolo( EA_SYMBOL_1 );
        fecharSimbolo( EA_SYMBOL_2 );
        m_estado = PAR_FLAT;
        return;
    }

    m_estado = dir1; // comprado no ativo1 = comprado no spread
}

// +1 comprado, -1 vendido, 0 sem posicao do EA no ativo informado.
int direcaoPosicao(const string symb){
    for(int i=PositionsTotal()-1; i>=0; i--){
        ulong ticket = PositionGetTicket(i);
        if( ticket == 0 ) continue;
        if( PositionGetInteger(POSITION_MAGIC ) != (long)EA_MAGIC ) continue;
        if( PositionGetString (POSITION_SYMBOL) != symb           ) continue;
        return ( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ) ? 1 : -1;
    }
    return 0;
}

// resultado nao realizado (lucro + swap) das posicoes do EA no ativo informado.
double lucroSimbolo(const string symb){
    double lucro = 0;
    for(int i=PositionsTotal()-1; i>=0; i--){
        ulong ticket = PositionGetTicket(i);
        if( ticket == 0 ) continue;
        if( PositionGetInteger(POSITION_MAGIC ) != (long)EA_MAGIC ) continue;
        if( PositionGetString (POSITION_SYMBOL) != symb           ) continue;
        lucro += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
    }
    return lucro;
}

// fecha todas as posicoes do EA no ativo informado. Retorna true se nao restou posicao.
bool fecharSimbolo(const string symb){
    bool ok = true;
    for(int i=PositionsTotal()-1; i>=0; i--){
        ulong ticket = PositionGetTicket(i);
        if( ticket == 0 ) continue;
        if( PositionGetInteger(POSITION_MAGIC ) != (long)EA_MAGIC ) continue;
        if( PositionGetString (POSITION_SYMBOL) != symb           ) continue;

        m_trade.SetTypeFillingBySymbol( symb );
        if( !m_trade.PositionClose( ticket, EA_DESVIO_PONTOS ) ){
            Print(":-( ", __FUNCTION__, " falha ao fechar ", symb, " ticket:", ticket,
                          " retcode:", m_trade.ResultRetcode(), " ", m_trade.ResultRetcodeDescription() );
            ok = false;
        }
    }
    return ok;
}

// envia ordem a mercado para o ativo informado.
bool enviarMercado(const string symb, const ENUM_ORDER_TYPE tipo, const double volume){

    m_trade.SetTypeFillingBySymbol( symb );

    bool ok = false;
    if( tipo == ORDER_TYPE_BUY ){
        ok = m_trade.Buy ( volume, symb, 0.0, 0.0, 0.0, m_name );
    }else{
        ok = m_trade.Sell( volume, symb, 0.0, 0.0, 0.0, m_name );
    }

    if( !ok ){
        Print(":-( ", __FUNCTION__, " ", symb, " ", EnumToString(tipo), " vol:", volume,
                      " retcode:", m_trade.ResultRetcode(), " ", m_trade.ResultRetcodeDescription() );
        return false;
    }

    Print(":-) ", __FUNCTION__, " ", symb, " ", EnumToString(tipo), " vol:", volume,
                  " preco:", m_trade.ResultPrice() );
    return true;
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
        "Estado         : ", estadoStr(), "\n",
        "Resultado par  : ", DoubleToString(m_lucro_par , 2),
                             (EA_STOP_FINANCEIRO>0 ? "   (stop em -"+DoubleToString(EA_STOP_FINANCEIRO,2)+")" : "   (sem stop)"), "\n"
    );
}
//+------------------------------------------------------------------+
