//+--------------------------------------------------------+
//|                           C0701StrategyPairsTrading.mqh|
//|                     Copyright 2026,oficina de software.|
//|                      https://www.metaquotes.net/marcoc.|
//|                                                        |
//| CLASSE PARA CLASSES QUE IMPLEMENTAM EXPERT ADVISORS.   |
//|                                                        |
//|                                                        |
//+--------------------------------------------------------+
#property copyright "2026, Oficina de Software."
#property link      "marcoc68@gmail.com"

#include <oslib/osc/exp/C0700Strategy.mqh>

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <oslib/osc/est/C00021Pairs.mqh>
#include <oslib/osc/osc-media2.mqh>
#include <oslib/osc-trade-util.mqh>

//--- estado do par (direcao da operacao sobre o spread)
#define PAR_FLAT          0  // sem posicao
#define PAR_LONG_SPREAD   1  // comprado no spread : COMPRA ativo1 / VENDE  ativo2
#define PAR_SHORT_SPREAD -1  // vendido  no spread : VENDE  ativo1 / COMPRA ativo2
#define TERMINAL         "TERMINAL"  // nome especial para indicar o simbolo do terminal.
#define BUSCAR_PAR       "BUSCAR_PAR"  // nome especial para indicar que o EA deve buscar um par adequado.


struct ParametrosC0701StrategyPairsTrading{

    //input group "=== Par de ativos ===";
    string         ea_symbol_1           ; //  = TERMINAL  ; //SYMBOL_1 primeiro ativo do par (p1 do spread)
    string         ea_symbol_2           ; //  = BUSCAR_PAR; //SYMBOL_2 segundo  ativo do par (p2 do spread)
    double         ea_coef_correlacao_min; //  = 0.80      ; //COEF_CORRELACAO_MIN coeficiente de correlacao minimo entre os dois ativos para operar
    string         ea_symbols_candidates ; //  = "AUDCAD, AUDCHF, AUDJPY, AUDNZD, AUDSGD, AUDUSD, CADCHF, CADJPY, CHFJPY, CHFSGD, EURAUD, EURCAD, EURCHF, EURDKK, EURGBP, EURJPY, EURNOK, EURNZD, EURPLN, EURSEK, EURSGD, EURUSD, EURZAR, GBPAUD, GBPCAD, GBPCHF, GBPDKK, GBPJPY, GBPNOK, GBPNZD, GBPSEK, GBPSGD, GBPTRY, GBPUSD, NOKJPY, NOKSEK, NZDCAD, NZDCHF, NZDJPY, NZDUSD, SEKJPY, SGDJPY, USDCAD, USDCHF, USDCNH, USDCZK, USDDKK, USDHKD, USDHUF, USDJPY, USDMXN, USDNOK, USDPLN, USDSEK"; //SYMBOLS_CANDIDATES lista de simbolos candidatos a formar par com SYMBOL_1

    //input group "=== Spread do PAR ===";
    int             ea_qtd_periodos       ; // = 60         ; //QTD_PERIODOS qtd de barras usadas na media e no desvio do spread
    ENUM_TIMEFRAMES ea_timeframe          ; // = PERIOD_M3  ; //TIMEFRAME timeframe das barras da janela do spread
    double          ea_desvios_entrada    ; // = 3.0        ; //DESVIOS_ENTRADA afastamento em desvios padrao para disparar a operacao
    double          ea_desvios_saida      ; // = 0.0        ; //DESVIOS_SAIDA distancia da media, em desvios, onde a posicao eh fechada. 0=fecha na media

    //input group "=== Volume ===";
    double         ea_volume_1                   ; //= 0.01 ; //VOLUME lote aplicado na primeira perna
    double         ea_volume_2                   ; //= 0.01 ; //VOLUME lote aplicado na segunda perna
    bool           ea_aplicar_sugestao_de_volume ; //= true ; //APLICAR_SUGESTAO_DE_VOLUME aplica a sugestao de volume de lotes
    double         ea_tolerancia_equil           ; //= 0.10 ; //TOLERANCIA_EQUIL desequilibrio aceito entre as pernas no calculo da sugestao. 0.01=1%

    //input group "=== Stop ===";
    double         ea_stop_financeiro     ; //= 0.0     ; //STOP_FINANCEIRO perda maxima somada das duas pernas, na moeda da conta. 0=desligado
    bool           ea_stop_media_abertura ; //= false   ; //STOP_MEDIA_ABERTURA fecha qd a media alcanca o spread de abertura +- desvios de abertura

    //input group "=== Operacao ===";
    int            ea_spread_pips_max_para_abrir_posicao ; //= 5    ; // Spread em pips maior que este valor. Não abre posição.
    bool           ea_operacao_automatica                ; //= true ; //OPERACAO_AUTOMATICA false=nao abre nem fecha sozinho, apenas loga o que faria
    bool           ea_teclas_habilitadas                 ; //= true ; //TECLAS_HABILITADAS abre/fecha o par por combinacao de teclas (grafico precisa ter o foco)
    bool           ea_tecla_ctrl                         ; //= true ; //TECLA_CTRL exige CTRL na combinacao de teclas
    bool           ea_tecla_alt                          ; //= false; //TECLA_ALT exige ALT na combinacao de teclas
    bool           ea_tecla_shift                        ; //= true ; //TECLA_SHIFT exige SHIFT na combinacao de teclas
    int            ea_tecla_abrir                        ; //= 65   ; //TECLA_ABRIR codigo da tecla que abre o par. 65='A'
    int            ea_tecla_fechar                       ; //= 70   ; //TECLA_FECHAR codigo da tecla que fecha o par. 70='F'

    //input group "=== Diversos ===";
    ulong          ea_magic             ; //= 260908001000; //MAGIC numero magico do EA. yy-mm-vv-vvv-vvv-vv
    ulong          ea_desvio_pontos     ; //= 20          ; //DESVIO_PONTOS desvio maximo aceito do preco nas ordens a mercado
    bool           ea_show_tela         ; //= true        ; //SHOW_TELA mostra o estado do EA no grafico
    int            ea_qtd_miliseg_timer ; //= 250       ; //QTD_MILISEG_TIMER tempo de acionamento do timer
    string         ea_name              ;
};

class C0701StrategyPairsTrading: public C0700Strategy{

public:
    ParametrosC0701StrategyPairsTrading m_param;
    C00021Pairs   m_pairs                ; // calculo do spread, da media e do desvio padrao
    CTrade        m_trade                ; // execucao das ordens
    CSymbolInfo   m_symb1                ; // propriedades do ativo 1
    CSymbolInfo   m_symb2                ; // propriedades do ativo 2
    osc_media     m_media_spread_symb1   ; // media do spread na janela
    osc_media     m_media_spread_symb2   ; // media do spread na janela
    string        m_nm_symb1             ; // nome do ativo 1
    string        m_nm_symb2             ; // nome do ativo 2

    double        m_volume1              ; // volume normalizado para o ativo 1
    double        m_volume2              ; // volume normalizado para o ativo 2
    double        m_volume_sugerido1     ; // volume sugerido normalizado para o ativo 1
    double        m_volume_sugerido2     ; // volume sugerido normalizado para o ativo 2

    datetime      m_dt_ult_barra         ; // data da ultima barra ja contabilizada na janela
    int           m_qtd_amostras         ; // qtd de spreads ja adicionados a janela

    double        m_spread_atu           ; // spread instantaneo
    double        m_spread_med           ; // media do spread na janela
    double        m_spread_std           ; // desvio padrao do spread na janela
    double        m_zscore               ; // (spread - media)/desvio

    double        m_coef_correlacao      ; // coeficiente de correlacao entre os dois ativos
    bool          m_par_eh_cointegrado   ; // indica se o par eh cointegrado (teste de Engle-Granger)
    datetime      m_dt_ult_calc_coef_corr; // data da ultima vez que calculamos o coeficiente de correlacao e cointegracao

    double        m_banda_sup            ; // media + k*desvio
    double        m_banda_inf            ; // media - k*desvio

    int           m_estado               ; // situacao atual do par
    double        m_lucro_par            ; // resultado somado das duas pernas

    //--- referencia registrada na abertura da posicao (usada pelo stop da media)
    bool          m_abertura_reg         ; // jah temos a referencia da abertura?
    double        m_spread_abert         ; // spread no momento da abertura
    double        m_med_abert            ; // media  do spread no momento da abertura
    double        m_std_abert            ; // desvio do spread no momento da abertura
    datetime      m_dt_abert             ; // data da abertura

    string        m_ult_simulado         ; // ultima acao simulada logada (evita repetir no log)
    bool          m_pos_invalida         ; // pernas abertas que nao formam um spread e nao foram desmontadas

    bool          m_inicializado         ;
    ulong         m_magic                ;

    C0701StrategyPairsTrading(ParametrosC0701StrategyPairsTrading &param){
        C0701StrategyPairsTrading();
        m_param = param;
    }

    C0701StrategyPairsTrading(){
        m_volume1          = 0       ; // volume normalizado para o ativo 1
        m_volume2          = 0       ; // volume normalizado para o ativo 2
        m_volume_sugerido1 = 0       ; // volume sugerido normalizado para o ativo 1
        m_volume_sugerido2 = 0       ; // volume sugerido normalizado para o ativo 2

        m_dt_ult_barra     = 0       ; // data da ultima barra ja contabilizada na janela
        m_qtd_amostras     = 0       ; // qtd de spreads ja adicionados a janela

        m_spread_atu       = 0       ; // spread instantaneo
        m_spread_med       = 0       ; // media do spread na janela
        m_spread_std       = 0       ; // desvio padrao do spread na janela
        m_zscore           = 0       ; // (spread - media)/desvio
        m_coef_correlacao  = 0       ; // coeficiente de correlacao entre os dois ativos
        m_par_eh_cointegrado = false   ; // indica se o par eh cointegrado (teste de Engle-Granger)
        m_banda_sup        = 0       ; // media + k*desvio
        m_banda_inf        = 0       ; // media - k*desvio

        m_estado           = PAR_FLAT; // situacao atual do par
        m_lucro_par        = 0       ; // resultado somado das duas pernas

        m_abertura_reg     = false    ; // jah temos a referencia da abertura?
        m_spread_abert     = 0        ; // spread no momento da abertura
        m_med_abert        = 0        ; // media  do spread no momento da abertura
        m_std_abert        = 0        ; // desvio do spread no momento da abertura
        m_dt_abert         = 0        ; // data da abertura

        m_ult_simulado     = ""       ; // ultima acao simulada logada (evita repetir no log)
        m_pos_invalida     = false    ; // pernas abertas que nao formam um spread e nao foram desmontadas

        m_inicializado     = false    ;
        m_magic            = 0        ;
    }

    int onInit(){
        Print(":-| ", __FUNCTION__, " ************************************************");
        Print(":-| ", __FUNCTION__, " Iniciando : ", TimeCurrent() );
        Print(":-| ", __FUNCTION__, " BUILDER   : ", __MQLBUILD__  );
        Print(":-| ", __FUNCTION__, " ************************************************");

        if( !inicializarSimbolos()  ) return INIT_PARAMETERS_INCORRECT;
        if( !inicializarParametros()) return INIT_PARAMETERS_INCORRECT;

        m_media_spread_symb1.initialize( m_param.ea_qtd_periodos, 1 ); // media do spread operacional coletado a cada 5 segundos.
        m_media_spread_symb2.initialize( m_param.ea_qtd_periodos, 1 ); // media do spread operacional coletado a cada 5 segundos.

        m_magic = criar_magic(m_nm_symb1 + m_nm_symb2); // magic unico para cada par de ativos

        m_trade.SetExpertMagicNumber( m_magic          );
        m_trade.SetDeviationInPoints( m_param.ea_desvio_pontos );
        m_trade.LogLevel            ( LOG_LEVEL_ERRORS );

        // janela de EA_QTD_PERIODOS amostras. A classe filtra adicoes com menos de 1 segundo
        // de intervalo, o que nao nos afeta pois adicionamos no maximo uma amostra por barra.
        m_pairs.initialize( m_param.ea_qtd_periodos, m_param.ea_timeframe );

        logarModoOperacao();
        sugerirVolumeEquilibrio();

        carregarHistorico();
        reconhecerPosicoes(); // o EA pode estar sendo iniciado no meio de uma operacao

        EventSetMillisecondTimer( m_param.ea_qtd_miliseg_timer );
        Print(":-| ", __FUNCTION__, " Criado Timer de ", m_param.ea_qtd_miliseg_timer, " milisegundos." );
        Print(":-) ", __FUNCTION__, " inicializado !! " );

        m_inicializado = true;
        processar();
        return(INIT_SUCCEEDED);
    }

    void onDeinit(const int reason) {
        EventKillTimer();
        Comment("");
        Print(":-| ", __FUNCTION__, " finalizado. reason=", reason );
    }
    
    void onTick(){ processar(); }
    void onTimer(){ processar(); }

    //+------------------------------------------------------------------+
    //| Inicializacao dos dois ativos do par                             |
    //+------------------------------------------------------------------+
    bool inicializarSimbolos(){

        m_nm_symb1 = m_param.ea_symbol_1;
        m_nm_symb2 = m_param.ea_symbol_2;

        if( m_nm_symb1 == TERMINAL ) m_nm_symb1 = _Symbol;
        if( m_nm_symb2 == TERMINAL ) m_nm_symb2 = _Symbol;

        if( m_nm_symb1 == BUSCAR_PAR ) m_nm_symb1 = buscarParAdequado( m_nm_symb2 );
        if( m_nm_symb2 == BUSCAR_PAR ) m_nm_symb2 = buscarParAdequado( m_nm_symb1 );

        if( m_nm_symb1 == m_nm_symb2 ){
            Print(":-( ", __FUNCTION__, " SYMBOL_1 e SYMBOL_2 devem ser ativos diferentes." );
            return false;
        }

        if( !osc_trade_util::selecionarSimbolo(m_nm_symb1) ) return false;
        if( !osc_trade_util::selecionarSimbolo(m_nm_symb2) ) return false;

        m_symb1.Name( m_nm_symb1 );
        m_symb2.Name( m_nm_symb2 );
        m_symb1.Refresh(); m_symb1.RefreshRates();
        m_symb2.Refresh(); m_symb2.RefreshRates();

        Print(":-| ", __FUNCTION__, " ativo1:", m_nm_symb1,
                      " digits:"   , m_symb1.Digits(),
                      " lots min/step/max:", m_symb1.LotsMin(), "/", m_symb1.LotsStep(), "/", m_symb1.LotsMax() );
        Print(":-| ", __FUNCTION__, " ativo2:", m_symb2.Name(),
                      " digits:"   , m_symb2.Digits(),
                      " lots min/step/max:", m_symb2.LotsMin(), "/", m_symb2.LotsStep(), "/", m_symb2.LotsMax() );
        return true;
    }

    string buscarParAdequado(string symbol){
        return C00021Pairs::buscarParAdequado(symbol, m_param.ea_symbols_candidates, m_param.ea_qtd_periodos, m_param.ea_timeframe,
                                              m_param.ea_coef_correlacao_min, true, m_param.ea_spread_pips_max_para_abrir_posicao);
    }

    //+------------------------------------------------------------------+
    //| Validacao e normalizacao dos parametros de entrada               |
    //+------------------------------------------------------------------+
    bool inicializarParametros(){

        if( m_param.ea_qtd_periodos < 2 ){
            Print(":-( ", __FUNCTION__, " QTD_PERIODOS deve ser no minimo 2. informado:", m_param.ea_qtd_periodos );
            return false;
        }

        if( m_param.ea_desvios_entrada <= 0 ){
            Print(":-( ", __FUNCTION__, " DESVIOS_ENTRADA deve ser maior que zero. informado:", m_param.ea_desvios_entrada );
            return false;
        }

        if( m_param.ea_desvios_saida < 0 ){
            Print(":-( ", __FUNCTION__, " DESVIOS_SAIDA nao pode ser negativo. informado:", m_param.ea_desvios_saida );
            return false;
        }

        if( m_param.ea_desvios_saida >= m_param.ea_desvios_entrada ){
            Print(":-( ", __FUNCTION__, " DESVIOS_SAIDA (", m_param.ea_desvios_saida, ") deve ser menor que ",
                          "DESVIOS_ENTRADA (", m_param.ea_desvios_entrada, "), senao a posicao fecharia na propria abertura." );
            return false;
        }

        if( m_param.ea_volume_1 <= 0 || m_param.ea_volume_2 <= 0 ){
            Print(":-( ", __FUNCTION__, " VOLUME_1 e VOLUME_2 devem ser maiores que zero. informados:", m_param.ea_volume_1, " e ", m_param.ea_volume_2 );
            return false;
        }

        m_volume1 = osc_trade_util::normalizarVolume( m_symb1, m_param.ea_volume_1 );
        m_volume2 = osc_trade_util::normalizarVolume( m_symb2, m_param.ea_volume_2 );

        Print(":-| ", __FUNCTION__, " volume ", m_nm_symb1, ":", m_volume1,
                                    " volume ", m_nm_symb2, ":", m_volume2 );

        if( m_volume1 != m_param.ea_volume_1 || m_volume2 != m_param.ea_volume_2 ){
            Print(":-| ", __FUNCTION__, " VOLUMES de ", m_nm_symb1,":" ,m_param.ea_volume_1, " e de", m_nm_symb2, ":", m_param.ea_volume_2, " foram ajustados aos limites dos ativos." );
        }
        return true;
    }

    //+------------------------------------------------------------------+
    //| Modo de operacao e teclas de atalho (log do OnInit)              |
    //+------------------------------------------------------------------+
    void logarModoOperacao(){

        if( m_param.ea_operacao_automatica ){
            Print(":-| ", __FUNCTION__, " OPERACAO AUTOMATICA LIGADA: o EA abre e fecha as posicoes." );
        }else{
            Print(":-| ", __FUNCTION__, " OPERACAO AUTOMATICA DESLIGADA: o EA nao abre nem fecha posicao ",
                          "sozinho. Apenas loga [SIMULADO] o que faria. As teclas continuam valendo." );
        }

        if( !m_param.ea_teclas_habilitadas ){
            Print(":-| ", __FUNCTION__, " teclas de atalho desabilitadas." );
            return;
        }

        Print(":-| ", __FUNCTION__, " tecla para ABRIR : ", strTeclaAbrir () );
        Print(":-| ", __FUNCTION__, " tecla para FECHAR: ", strTeclaFechar() );
        Print(":-| ", __FUNCTION__, " as teclas so chegam ao EA com o grafico em foco. Se o ALT for ",
                      "capturado pelo menu do terminal, troque a combinacao nos parametros." );
    }

    string strTeclaAbrir (){
        return osc_trade_util::descreverTecla( m_param.ea_tecla_ctrl, m_param.ea_tecla_alt, m_param.ea_tecla_shift, m_param.ea_tecla_abrir  );
    }

    string strTeclaFechar(){
        return osc_trade_util::descreverTecla( m_param.ea_tecla_ctrl, m_param.ea_tecla_alt, m_param.ea_tecla_shift, m_param.ea_tecla_fechar );
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

        // quanto vale, em dinheiro, 1% de variacao do preco, para o volume configurado...
        double val1_atu = osc_trade_util::valorPorPercentual( m_nm_symb1, m_volume1, 0.01 );
        double val2_atu = osc_trade_util::valorPorPercentual( m_nm_symb2, m_volume2, 0.01 );

        Print(":-| ", __FUNCTION__, " --- equilibrio financeiro das pernas (1% de variacao) ---" );
        Print(":-| ", __FUNCTION__, " ", m_nm_symb1, " vol:", m_volume1,
                      " preco:", osc_trade_util::precoReferencia(m_nm_symb1),
                      " valor de 1%:", DoubleToString(val1_atu,2), " ", AccountInfoString(ACCOUNT_CURRENCY) );
        Print(":-| ", __FUNCTION__, " ", m_nm_symb2, " vol:", m_volume2,
                      " preco:", osc_trade_util::precoReferencia(m_nm_symb2),
                      " valor de 1%:", DoubleToString(val2_atu,2), " ", AccountInfoString(ACCOUNT_CURRENCY) );

        if( val1_atu > 0 && val2_atu > 0 ){
            double desequil = MathAbs(val1_atu-val2_atu)/MathMax(val1_atu,val2_atu);
            Print(":-| ", __FUNCTION__, " desequilibrio do volume configurado: ",
                          DoubleToString(desequil*100,2), "%" );
        }

        double erro=0;
        if( !osc_trade_util::calcVolumesEquilibrio( m_nm_symb1, m_nm_symb2, m_volume_sugerido1, m_volume_sugerido2, erro,
                                                    m_param.ea_tolerancia_equil ) ){
            Print(":-( ", __FUNCTION__, " nao foi possivel calcular o volume de equilibrio. ",
                          "Verifique cotacao e tick value dos ativos." );
            return;
        }

        double val1_sug = osc_trade_util::valorPorPercentual( m_nm_symb1, m_volume_sugerido1, 0.01 );
        double val2_sug = osc_trade_util::valorPorPercentual( m_nm_symb2, m_volume_sugerido2, 0.01 );

        Print(":-) ", __FUNCTION__, " SUGESTAO de volume minimo para equilibrio: ",
                      m_nm_symb1, ":", m_volume_sugerido1, " (1% = ", DoubleToString(val1_sug,2), ") ",
                      m_nm_symb2, ":", m_volume_sugerido2, " (1% = ", DoubleToString(val2_sug,2), ") ",
                      " desequilibrio residual:", DoubleToString(erro*100,2), "%" );

        if( erro > m_param.ea_tolerancia_equil ){
            Print(":-| ", __FUNCTION__, " o melhor par encontrado ainda ficou acima da tolerancia de ",
                          DoubleToString(m_param.ea_tolerancia_equil*100,2), "%. Os lotes minimos dos dois ativos ",
                          "nao permitem um casamento melhor nesta faixa de volume." );
        }

        if( m_param.ea_aplicar_sugestao_de_volume  && erro <= m_param.ea_tolerancia_equil ){
            m_volume1 = m_volume_sugerido1;
            m_volume2 = m_volume_sugerido2;
            Print(":-) ", __FUNCTION__, " aplicada sugestao de volume de lotes: VOLUME1=", m_volume1, " e VOLUME2=", m_volume2, "." );
        }else{
            Print(":-| ", __FUNCTION__, " a sugestao nao altera o EA: ele continua operando com VOLUME1=", m_param.ea_volume_1, " e VOLUME2=", m_param.ea_volume_2, "." );
        }
    }

    //+------------------------------------------------------------------+
    //| Carga inicial da janela com as ultimas barras fechadas           |
    //+------------------------------------------------------------------+
    void carregarHistorico(){

        MqlRates rates1[];
        ArrayResize(rates1, m_param.ea_qtd_periodos);
        ArraySetAsSeries(rates1,false); // ordem crescente de data

        int qtd = CopyRates( m_nm_symb1, m_param.ea_timeframe, 0, m_param.ea_qtd_periodos, rates1 );
        if( qtd <= 0 ){
            Print(":-| ", __FUNCTION__, " sem historico de ", m_nm_symb1,
                          " ainda. A janela serah preenchida barra a barra. erro=", GetLastError() );
            return;
        }

        // forcando o carregamento do historico do ativo 2...
        for(int i=0; i<qtd; i++){
            double preco2 = 0, spread2 = 0;
            if( !getFechamentoAtivo2( rates1[i].time, preco2, spread2 ) ) continue;
            adicionarAmostra( rates1[i].close, preco2 , rates1[i].time );
            adicionarSpreadOperacional( rates1[i].spread, spread2, rates1[i].time );
        }
        calcularCoeficenteCorrelacao();

        m_dt_ult_barra = rates1[qtd-1].time;

        Print(":-| ", __FUNCTION__, " ", m_qtd_amostras, "/", m_param.ea_qtd_periodos,
                      " amostras carregadas. ultima barra:", m_dt_ult_barra,
                      " media:", m_spread_med, " desvio:", m_spread_std );
    }

    // fechamento do ativo 2 na barra de data dt. Se o ativo 2 nao tiver barra nessa data
    // exata (nao negociou no periodo), usa o fechamento da barra imediatamente anterior.
    bool getFechamentoAtivo2(const datetime dt, double &preco, double &spread){
        preco = 0;

        MqlRates rates2[];
        ArraySetAsSeries(rates2,false);
        if( CopyRates( m_nm_symb2, m_param.ea_timeframe, dt, 1, rates2 ) == 1 ){
            preco = rates2[0].close;
            spread = rates2[0].spread;
            return (preco > 0);
        }

        int shift = iBarShift( m_nm_symb2, m_param.ea_timeframe, dt, false );
        if( shift < 0 ) return false;

        preco  = iClose ( m_nm_symb2, m_param.ea_timeframe, shift );
        spread = iSpread( m_nm_symb2, m_param.ea_timeframe, shift );
        return (preco > 0);
    }

    // adiciona uma amostra de spread a janela e atualiza media e desvio.
    // usado no processamento do historico.
    void adicionarAmostra(const double p1, const double p2, const datetime dt){
        if( p1 <= 0 || p2 <= 0 ) return;

        m_pairs.calcSpread( p1, p2, dt );
        if( m_qtd_amostras < m_param.ea_qtd_periodos ) m_qtd_amostras++;

        m_spread_med = m_pairs.getSpreadMed();
        m_spread_std = m_pairs.getSpreadStd();
    }

    void calcularCoeficenteCorrelacao(){
        if( TimeCurrent() - m_dt_ult_calc_coef_corr < PeriodSeconds(m_param.ea_timeframe) ) return; // ja calculamos nesta barra
        m_dt_ult_calc_coef_corr = TimeCurrent();
        m_coef_correlacao = m_pairs.calcCoefCorr();
        m_par_eh_cointegrado = m_pairs.parEhCointegrado();
    }

    // spread medio usado pra saber se vale a pena negociar o ativo.
    void adicionarSpreadOperacional(const double s1, const double s2, const datetime dt){
        if( s1 <= 0 || s2 <= 0 ) return;
        m_media_spread_symb1.add( s1, dt );
        m_media_spread_symb2.add( s2, dt );
    }

    //+------------------------------------------------------------------+
    //| Alimenta a janela quando uma nova barra fecha                    |
    //+------------------------------------------------------------------+
    void atualizarEstatistica(){

        MqlRates rates1[];
        ArraySetAsSeries(rates1,false);
        if( CopyRates( m_nm_symb1, m_param.ea_timeframe, 1, 1, rates1 ) != 1 ) return;

        if( rates1[0].time <= m_dt_ult_barra ) return; // barra ja contabilizada

        double preco2 = 0, spread2 = 0;
        if( getFechamentoAtivo2( rates1[0].time, preco2, spread2 ) ){
            adicionarAmostra( rates1[0].close, preco2, rates1[0].time );
            adicionarSpreadOperacional ( rates1[0].spread, spread2, rates1[0].time );
        }

        // marca a barra como processada mesmo sem o par, para nao travar a janela
        // caso o ativo 2 fique sem cotacao em algum periodo.
        m_dt_ult_barra = rates1[0].time;
    }

    //+------------------------------------------------------------------+
    //| Ciclo principal                                                  |
    //+------------------------------------------------------------------+
    string processar(){

        if( !m_inicializado ) return status();

        atualizarEstatistica();

        if( !atualizarPrecos() ) return status();

        reconhecerPosicoes();

        // pernas abertas que nao formam um spread e que o EA nao pode desmontar (operacao
        // manual): nao dah para avaliar entrada nem saida enquanto isso nao for resolvido.
        if( m_pos_invalida    ){ return status(); }

        if( !janelaCompleta() ){ return status(); }

        if( m_estado == PAR_FLAT ){
            verificarEntrada();
        }else{
            verificarSaida();
        }

        return status();
    }
    
    string status(){ showTela(); return "Status em construcao...";}

    // atualiza o spread instantaneo e as bandas de operacao. Retorna falso se nao
    // foi possivel obter cotacao dos dois ativos.
    MqlTick m_tick1, m_tick2;
    int m_spread_em_pips1, m_spread_em_pips2;
    bool atualizarPrecos(){

        // spread instantaneo em pips. Usado para saber se podemos operar...
        m_spread_em_pips1 = m_symb1.Spread();
        m_spread_em_pips2 = m_symb2.Spread();
        adicionarSpreadOperacional( m_spread_em_pips1, m_spread_em_pips2, TimeCurrent() );

        if( !SymbolInfoTick(m_nm_symb1,m_tick1) ) return false;
        if( !SymbolInfoTick(m_nm_symb2,m_tick2) ) return false;

       // spread instantaneo entre os ativos do par que queremos negociar.
        double p1 = m_pairs.getLast(m_tick1);
        double p2 = m_pairs.getLast(m_tick2);
        if( p1 <= 0 || p2 <= 0 ) return false;

        m_spread_atu = m_pairs.calcSpread( p1, p2, TimeCurrent() );
        if( !MathIsValidNumber(m_spread_atu) ) return false;

        m_spread_med = m_pairs.getSpreadMed();
        m_spread_std = m_pairs.getSpreadStd();

        // bandas calculadas pela propria classe: media + shift*desvio
        m_banda_sup  = m_pairs.getSpreadStd(  m_param.ea_desvios_entrada );
        m_banda_inf  = m_pairs.getSpreadStd( -m_param.ea_desvios_entrada );
        m_zscore     = (m_spread_std > 0) ? (m_spread_atu-m_spread_med)/m_spread_std : 0;

        return true;
    }

    // a janela precisa estar cheia e com dispersao valida para operar.
    bool janelaCompleta(){
        return ( m_qtd_amostras >= m_param.ea_qtd_periodos && m_spread_std > 0 );
    }

    //+------------------------------------------------------------------+
    //| Entrada                                                          |
    //+------------------------------------------------------------------+
    void verificarEntrada(){

        if( m_spread_atu > m_banda_sup && coef_correlacao_ok() && spread_operacional_ok() ){
            // ativo1 caro em relacao ao ativo2: vende o caro e compra o barato.
            string motivo = "spread " + DoubleToString(m_spread_atu,8) + " acima da banda " +
                            DoubleToString(m_banda_sup,8) + " (z=" + DoubleToString(m_zscore,2) + ")";
            solicitarAbertura( PAR_SHORT_SPREAD, motivo, false );
            return;
        }

        if( m_spread_atu < m_banda_inf && coef_correlacao_ok() && spread_operacional_ok() ){
            // ativo1 barato em relacao ao ativo2: compra o barato e vende o caro.
            string motivo = "spread " + DoubleToString(m_spread_atu,8) + " abaixo da banda " +
                            DoubleToString(m_banda_inf,8) + " (z=" + DoubleToString(m_zscore,2) + ")";
            solicitarAbertura( PAR_LONG_SPREAD, motivo, false );
            return;
        }

        limparSimulado(); // spread dentro das bandas: nenhuma entrada pendente
    }

    bool coef_correlacao_ok(){ return ( m_coef_correlacao >= m_param.ea_coef_correlacao_min ); }

    bool spread_operacional_ok(){
        return ( m_spread_em_pips1             >= 0 && m_spread_em_pips1             <= m_param.ea_spread_pips_max_para_abrir_posicao &&
                 m_spread_em_pips2             >= 0 && m_spread_em_pips2             <= m_param.ea_spread_pips_max_para_abrir_posicao &&
                 m_media_spread_symb1.getMed() >= 0 && m_media_spread_symb1.getMed() <= m_param.ea_spread_pips_max_para_abrir_posicao &&
                 m_media_spread_symb2.getMed() >= 0 && m_media_spread_symb2.getMed() <= m_param.ea_spread_pips_max_para_abrir_posicao
               );
    }

    // porta de entrada de toda abertura. Quando a operacao automatica estah desligada,
    // as entradas do EA (manual=false) viram apenas log. As teclas (manual=true) passam.
    bool solicitarAbertura(const int direcao, const string motivo, const bool manual){

        if( !manual && !m_param.ea_operacao_automatica ){
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

        if( !manual && !m_param.ea_operacao_automatica ){
            logarSimulado( chave, "FECHARIA o par (" + estadoStr() + "). motivo: " + motivo );
            return false;
        }

        fecharPar( (manual ? "[TECLA] " : "") + motivo );
        return ( m_estado == PAR_FLAT );
    }

    // abre as duas pernas. Se a segunda perna falhar, desfaz a primeira para nao
    // deixar posicao direcional em aberto.
    bool abrirPar(const int direcao){

        ENUM_ORDER_TYPE tipo1, tipo2;

        if( m_coef_correlacao > 0 ){
            // correlacao positiva:
            // spread abaixo da media: compra ativo1 e vende ativo2
            // spread acima da media : vende ativo1 e compra ativo2
            tipo1 = (direcao==PAR_LONG_SPREAD) ? ORDER_TYPE_BUY  : ORDER_TYPE_SELL;
            tipo2 = (direcao==PAR_LONG_SPREAD) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY ;
        }else{
            // correlacao negativa:
            // spread abaixo da media: compra ambos os ativos
            // spread acima da media : vende ambos os ativos
            tipo1 = (direcao==PAR_LONG_SPREAD) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL ;
            tipo2 = (direcao==PAR_LONG_SPREAD) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        }

        if( !enviarMercado( m_nm_symb1, tipo1, m_volume1 ) ){
            Print(":-( ", __FUNCTION__, " falha na perna 1 (", m_nm_symb1, "). operacao abortada." );
            return false;
        }

        if( !enviarMercado( m_nm_symb2, tipo2, m_volume2 ) ){
            Print(":-( ", __FUNCTION__, " falha na perna 2 (", m_nm_symb2,
                          "). desfazendo a perna 1 (", m_nm_symb1, ")..." );
            fecharSimbolo( m_nm_symb1 );
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

        Print(":-| ", __FUNCTION__, (herdada?" (posicao jah estava aberta - referencia adotada do mercado atual) ":" "),
                      "referencia da abertura. spread:", m_spread_abert,
                      " media:", m_med_abert, " desvio:", m_std_abert,
                      // o stop eh acionado quando a media se desloca ateh o spread de abertura.
                      (m_param.ea_stop_media_abertura ? "  stop se spread medio atingir:"+DoubleToString(m_spread_abert,8)
                                              : "  (stop da media desligado)") );
    }

    void limparAbertura(){
        m_abertura_reg   = false;
        m_spread_abert   = 0;
        m_med_abert      = 0;
        m_std_abert      = 0;
        m_dt_abert       = 0;
        m_ult_simulado   = "";
    }

    string descreverDirecao(const int direcao){
        if( direcao == PAR_LONG_SPREAD  ) return "LONG SPREAD (COMPRA "+m_nm_symb1+" / VENDE "+m_nm_symb2+")";
        if( direcao == PAR_SHORT_SPREAD ) return "SHORT SPREAD (VENDE "+m_nm_symb1+" / COMPRA "+m_nm_symb2+")";
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
        if( m_param.ea_stop_financeiro > 0 && m_lucro_par <= -m_param.ea_stop_financeiro ){
            string motivo = "stop financeiro. resultado do par:" + DoubleToString(m_lucro_par,2) +
                            " limite:" + DoubleToString(-m_param.ea_stop_financeiro,2);
            solicitarFechamento( "FECHAR_STOP_FIN", motivo, false );
            return;
        }

        // 2. stop pelo deslocamento da media...
        //    a media alcancou o spread registrado na abertura da posicao. Nao foi o spread que voltou para a media: foi a
        //    media que foi atras do spread da abertura da posicao. A premissa de reversao nao vale mais.
        if( spreadMedioAtingiuSpreadDaAbertura() ){
            string motivo = "stop da media. media atual:" + DoubleToString(m_spread_med,8) +
                            " alcancou o spread da abertura da posicao:" + DoubleToString(m_spread_abert,8) + ")";
            solicitarFechamento( "FECHAR_STOP_MEDIA", motivo, false );
            return;
        }

        // 3. retorno do spread a media, ou ateh DESVIOS_SAIDA de distancia dela...
        //    entramos vendidos no spread acima da media: saimos quando ele cai ateh o alvo.
        //    entramos comprados no spread abaixo da media: saimos quando ele sobe ateh o alvo.
        double alvo = alvoDeSaida();

        if( ( m_estado == PAR_SHORT_SPREAD && m_spread_atu <= alvo ) ||
            ( m_estado == PAR_LONG_SPREAD  && m_spread_atu >= alvo ) ){
            string motivo = (m_param.ea_desvios_saida > 0)
                          ? "spread " + DoubleToString(m_spread_atu,8) + " alcancou o alvo " +
                            DoubleToString(alvo,8) + " (" + DoubleToString(m_param.ea_desvios_saida,2) +
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
        if( m_param.ea_desvios_saida <= 0 ) return m_spread_med;
        if( direcao == PAR_SHORT_SPREAD ) return m_spread_med + m_param.ea_desvios_saida*m_spread_std;
        if( direcao == PAR_LONG_SPREAD  ) return m_spread_med - m_param.ea_desvios_saida*m_spread_std;
        return m_spread_med;
    }

    // o spread jah estah no (ou alem do) alvo de saida da direcao informada?
    bool jahNoAlvoDeSaida(const int direcao){
        double alvo = alvoDeSaida( direcao );
        if( direcao == PAR_SHORT_SPREAD ) return ( m_spread_atu <= alvo );
        if( direcao == PAR_LONG_SPREAD  ) return ( m_spread_atu >= alvo );
        return false;
    }

    // spread medio alcancou o spread registrado na abertura da posicao?
    bool spreadMedioAtingiuSpreadDaAbertura(){

        if( !m_param.ea_stop_media_abertura ) return false;
        if( !m_abertura_reg                 ) return false;
        if( m_estado == PAR_FLAT            ) return false;

        if( m_estado == PAR_SHORT_SPREAD ) return ( m_spread_med >= m_spread_abert );
        return ( m_spread_med <= m_spread_abert );
    }

    // fecha as duas pernas do par.
    void fecharPar(const string motivo){

        Print(":-| ", __FUNCTION__, "(", motivo, ") fechando ", m_nm_symb1, " e ", m_nm_symb2,
                      ". resultado do par:", m_lucro_par );

        bool ok1 = fecharSimbolo( m_nm_symb1 );
        bool ok2 = fecharSimbolo( m_nm_symb2 );

        if( ok1 && ok2 ){
            m_estado = PAR_FLAT;
            limparAbertura();
            Print(":-) ", __FUNCTION__, "(", motivo, ") par fechado." );
        }else{
            Print(":-( ", __FUNCTION__, "(", motivo, ") fechamento incompleto. ",
                          m_nm_symb1, ":", ok1, " ", m_nm_symb2, ":", ok2,
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

        int dir1 = direcaoPosicao( m_nm_symb1 );
        int dir2 = direcaoPosicao( m_nm_symb2 );

        m_lucro_par = lucroSimbolo( m_nm_symb1 ) + lucroSimbolo( m_nm_symb2 );

        if( dir1 == 0 && dir2 == 0 ){
            if( m_abertura_reg ) limparAbertura();
            m_estado = PAR_FLAT;
            return;
        }

        // perna orfa: uma das pontas ficou aberta sozinha. Nao eh operacao de spread,
        // eh exposicao direcional. Desmonta.
        if( dir1 == 0 || dir2 == 0 ){
            desmontarPosicaoInvalida( "perna orfa detectada. " + m_nm_symb1 + ":" + IntegerToString(dir1) +
                                      " " + m_nm_symb2 + ":" + IntegerToString(dir2) );
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

        if( !m_param.ea_operacao_automatica ){
            m_pos_invalida = true;
            logarSimulado( "DESMONTAR", "DESMONTARIA as posicoes: " + motivo );
            return;
        }

        Print(":-( ", __FUNCTION__, " ", motivo, ". desmontando..." );
        fecharSimbolo( m_nm_symb1 );
        fecharSimbolo( m_nm_symb2 );
        m_estado = PAR_FLAT;
        limparAbertura();
    }

    // +1 comprado, -1 vendido, 0 sem posicao do EA no ativo informado.
    int direcaoPosicao(const string symb){
        return osc_trade_util::direcaoPosicao( symb, m_magic );
    }

    // resultado nao realizado (lucro + swap) das posicoes do EA no ativo informado.
    double lucroSimbolo(const string symb){
        return osc_trade_util::lucroPosicao( symb, m_magic );
    }

    // fecha todas as posicoes do EA no ativo informado. Retorna true se nao restou posicao.
    bool fecharSimbolo(const string symb){
        return osc_trade_util::fecharSimbolo( m_trade, symb, m_magic, m_param.ea_desvio_pontos );
    }

    // envia ordem a mercado para o ativo informado.
    bool enviarMercado(const string symb, const ENUM_ORDER_TYPE tipo, const double volume){
        return osc_trade_util::enviarMercado( m_trade, symb, tipo, volume, m_param.ea_name+"-"+IntegerToString(m_magic) );
    }

    ulong criar_magic(string symbols_concatenados){

      string symbols_cortado = "";
      int tamanho = StringLen(symbols_concatenados);
      for(int i = 0; i < tamanho; i++){
        symbols_cortado += StringSubstr(symbols_concatenados,i,1);
        i++;
      }
      return toAsciiText(symbols_cortado);
    }

    // Função para converter os caracteres de uma string em seus códigos numéricos concatenados
    ulong toAsciiText(string texto){
        string texto_numerico = "";
        int tamanho = StringLen(texto);

        for(int i = 0; i < tamanho; i++){
            // Obtém o código numérico (ushort) do caractere na posição 'i'
            ushort char_code = StringGetCharacter(texto, i);

            // Concatena o código convertido para string no resultado
            texto_numerico += IntegerToString(char_code);
        }

        return StringToInteger(texto_numerico);
    }

    string estadoStr(){
        if( m_estado == PAR_LONG_SPREAD  ) return "LONG SPREAD  (C " +m_nm_symb1+" / V "+m_nm_symb2+")";
        if( m_estado == PAR_SHORT_SPREAD ) return "SHORT SPREAD (V " +m_nm_symb1+" / C "+m_nm_symb2+")";
        return "FLAT";
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
    }

    void showTela(){

        Comment(
            "Par            : ", m_nm_symb1, " / ", m_nm_symb2, "  CoefCorr: ", DoubleToString(m_coef_correlacao, 2),"  [COINT ",m_par_eh_cointegrado?"SIM":"NAO","]  Magic: ", m_magic,"\n",

            "Vol: "         , DoubleToString(m_volume1         ,2), "/", DoubleToString(m_volume2         ,2),
            " Vol sugerido: ", DoubleToString(m_volume_sugerido1,2), "/", DoubleToString(m_volume_sugerido2,2), "\n",

            "Janela         : ", m_param.ea_qtd_periodos, " barras de ", EnumToString(m_param.ea_timeframe),
                                "   (", m_qtd_amostras, " amostras", (janelaCompleta()?"":" - AGUARDANDO"), ")\n",

            "Spread in PIPs : [instataneo  ", m_spread_em_pips1, " / ", m_spread_em_pips2,"  ]  [ ",
            "Medio  ", DoubleToString(m_media_spread_symb1.getMed(), 2), " / ", DoubleToString(m_media_spread_symb2.getMed(), 2),"  ]\n",

            "Z-score        : ", DoubleToString(m_zscore      , 2), "\n",
            "Alvo de saida  : ", DoubleToString(alvoDeSaida() , 8),
                                 (m_param.ea_desvios_saida>0 ? "  ("+DoubleToString(m_param.ea_desvios_saida,2)+" dp da media)"
                                                     : "  (na media)"), "\n",
            "Estado         : ", estadoStr(), (m_pos_invalida?"   *** PERNAS INVALIDAS - NAO DESMONTADAS ***":""), "\n",
            strTelaAbertura(),
            "Resultado par  : ", DoubleToString(m_lucro_par , 2),
                                 (m_param.ea_stop_financeiro>0 ? "   (stop em -"+DoubleToString(m_param.ea_stop_financeiro,2)+")" : m_param.ea_stop_media_abertura ? "   (stop na media)" : "   (sem stop)"), "\n",
            "Operacao       : ", (m_param.ea_operacao_automatica ? "AUTOMATICA" : "MANUAL (o EA so loga o que faria)"), "\n",
            "Teclas         : ", (m_param.ea_teclas_habilitadas
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

        if( m_param.ea_stop_media_abertura ){
            s += "Spread na abertura  : " + DoubleToString(m_spread_abert,8) +
                 "   (Spread medio " + DoubleToString(m_spread_med,8) + ")\n";
        }
        return s;
    }
};
