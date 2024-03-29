﻿//+------------------------------------------------------------------------------------------------------------------+
//|                                                osc-exp-canal.mqh                                                 |
//|                                          Copyright 2019, OS Corp.                                                |
//|                                                http://www.os.org                                                 |
//|                                                                                                                  |
//| Versao 01.001                                                                                                    |
//| 1. Implementa controle de canais                                                                                 |
//|                                                                                                                  |
//|    01-001 Primeira versão                                 .                                                      |
//|    Para usar: 1. inclua    : #include <oslib\osc\osc-canal.mqh>                                                  |
//|               2. declare   : osc_canal m_canal;                                                                  |
//|               3. inicialize: m_canal.inicializar(m_tick_size,EA_TAMANHO_CANAL, EA_PORC_REGIAO_OPERACIONAL_CANAL);|
//|               4. refresh   : m_canal.refresh(m_ask,m_bid);                                                       |
//|               5. use       : m_canal.getLenCanalOperacionalEmTicks()                                             |
//|                              m_canal.regiaoSuperior()                                                            |
//|                              m_canal.regiaoInferior()                                                            |
//|                              m_canal.getPrecoRegiaoSuperior()                                                    |
//|                              m_canal.getPrecoRegiaoInferior()                                                    |
//|                                                                                                                  |
//+------------------------------------------------------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Trade\SymbolInfo.mqh>
#include <oslib\os-lib.mq5>

class osc_canal{

private:
    MqlRates m_rates[], m_ratesDia[1];
    
    // string com o simbolo sendo operado
    string m_symb_str        ;
    double m_bid, m_ask, m_tick_size,m_direcaoDia;
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
    double m_regiaoInferior                  ;
    double m_regiaoSuperior                  ;
    double m_porcRegiaoOperacao              ; //0.20;
    double m_maxDistanciaEntrelacaParaOperar ; //1000;
    double m_precoRegiaoInferior             ;
    double m_precoRegiaoSuperior             ;
    int    m_regiao_ult_extremo_tocado       ;
    double m_coef_linear                     ;

    //----------------------------------------------------------------------------------------------------

    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas no metodo calcCoefEntrelacamentoMedio();
    //|-------------------------------------------------------------------------------------
    double   m_coefEntrelaca                  ;
    double   m_coefEntrelacaInv               ;
    int      m_qtdPeriodo                     ;
    MqlRates m_ratesEntrelaca[]               ;
    double   m_maxPrecoCanal                  ;
    double   m_minPrecoCanal                  ;
    double   m_len_canal_operacional_em_ticks ;
    datetime m_time_desde_entrelaca           ;
    double   m_direcao_entre                  ; // indica se a barra total do entrelacamento eh de alta ou baixa...
    //----------------------------------------------------------------------------------------------------

    bool MEA_SHOW_CANAL_PRECOS               ;
    

    // variaveis usadas para controlar o coficiente de "Entrelacamento"
    int    MEA_ENTRELACA_PERIODO_COEF; // 6   //ENTRELACA_PERIODO_COEF: periodo p/calc coef entrelacamento.
    double MEA_ENTRELACA_COEF_MIN    ; // 0.40//ENTRELACA_COEF_MIN em porcentagem.
    int    MEA_ENTRELACA_CANAL_MAX   ; // 30  //ENTRELACA_CANAL_MAX: tamanho maximo em ticks do canal de entrelacamento.
    int    MEA_ENTRELACA_CANAL_STOP  ; // 35  //ENTRELACA_CANAL_STOP:StopLoss se canal maior que este parametro.

    // variaveis usadas para controlar a "Regiao de compra e venda"
    double MEA_REGIAO_BUY_SELL     ; //  0.3   //REGIAO_BUY_SELL: regiao de compra e venda nas extremidades do canal de entrelacamento.
    bool   MEA_USA_REGIAO_CANAL_DIA; //  false //USA_REGIAO_CANAL_DIA: usa a regiao do canal diario (true) ou canal de entrelacamento(false) para calcular regiao de compra venda.

    int  porcentagem( double parte, double tot, int seTotZero);
    void inicializarVariaveisRecebidasPorParametro();
    //|-------------------------------------------------------------------------------------
    //| O coeficiente de entrelacamento eh a porcentagem de intersecao do preco da barra
    //| atual em relacao a barra anterior.
    //| Esta funcao retorna o coeficiente de entrelacacamento medio dos ultimos x periodos 
    //|-------------------------------------------------------------------------------------
    void   calcCoefEntrelacamentoMedio();
    void   calcOpenMaxMinDia();
    double calcCoefEntrelacamento(double minAnt, double maxAnt, double minAtu, double maxAtu);

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


public:
    void inicializar(CSymbolInfo& symb, int qtdPeriodo, double porcRegiaoOperacao);
  //void inicializar(double tick_size, int qtdPeriodo, double porcRegiaoOperacao);
    bool refresh    (double ask, double bid);
    double getPrecoRegiaoInferior(){return m_precoRegiaoInferior;}
    double getPrecoRegiaoSuperior(){return m_precoRegiaoSuperior;}

    // variaveis usadas para controlar a "Regiao de compra e venda"
    void setRegiaoBuySell           (double v){MEA_REGIAO_BUY_SELL         =v;} //  0.3   //REGIAO_BUY_SELL: regiao de compra e venda nas extremidades do canal de entrelacamento.
    void setRegiaoBuySellUsaCanalDia(bool   v){MEA_USA_REGIAO_CANAL_DIA    =v;} //  false //USA_REGIAO_CANAL_DIA: usa a regiao do canal diario (true) ou canal de entrelacamento(false) para calcular regiao de compra venda.
    

    void calcDistPrecoMaxMin                ();
    void calcMaiorPrecoDeCompraVenda        ();
    bool regiaoInferior                     (){return m_regiaoInferior                 <= m_porcRegiaoOperacao              || m_porcRegiaoOperacao             ==0;}
    bool regiaoSuperior                     (){return m_regiaoSuperior                 <= m_porcRegiaoOperacao              || m_porcRegiaoOperacao             ==0;}
    bool distaciaEntrelacamentoPermiteOperar(){return m_len_canal_operacional_em_ticks <= m_maxDistanciaEntrelacaParaOperar || m_maxDistanciaEntrelacaParaOperar==0;}
    bool entrelacamentoDeBaixa              (){return m_direcao_entre < 0;}
    bool entrelacamentoDeAlta               (){return m_direcao_entre > 0;}
    void setShowCanalPrecos(bool               v){ MEA_SHOW_CANAL_PRECOS               =v;} bool   getShowCanalPrecos     (){return MEA_SHOW_CANAL_PRECOS               ;}

    //|------------------------------------------------------------------------------------------------------------
    //| retorna true se a compra estah barata, ou seja, abaixo da regiao de media ou se a venda estah cara, 
    //| ou seja, acima da regiao de media
    //|------------------------------------------------------------------------------------------------------------
    bool compraEstahBarata(double price){ return price < m_precoRegiaoInferior; } 
    bool vendaEstahCara   (double price){ return price > m_precoRegiaoSuperior; } 

    
    // variaveis usadas para controlar o coficiente de "Entrelacamento"
    void setEntrelacaPeriodoCoef    (int    v){MEA_ENTRELACA_PERIODO_COEF  =v;} // 6   //ENTRELACA_PERIODO_COEF: periodo p/calc coef entrelacamento.
    void setEntrelacaCoefMin        (double v){MEA_ENTRELACA_COEF_MIN      =v;} // 0.40//ENTRELACA_COEF_MIN em porcentagem.
    void setEntrelacaCanalMax       (int    v){MEA_ENTRELACA_CANAL_MAX     =v;} // 30  //ENTRELACA_CANAL_MAX: tamanho maximo em ticks do canal de entrelacamento.
    void setEntrelacaCanalStop      (int    v){MEA_ENTRELACA_CANAL_STOP    =v;} // 35  //ENTRELACA_CANAL_STOP:StopLoss se canal maior que este parametro.
 
    double getMaxPrecoCanal             (){return m_maxPrecoCanal                 ;}
    double getMinPrecoCanal             (){return m_minPrecoCanal                 ;}
    double getLenCanalOperacionalEmTicks(){return m_len_canal_operacional_em_ticks;}
    double getCoefEntrelaca             (){return m_coefEntrelaca                 ;}
    int    getRegiaoUltExtremoTocado    (){return m_regiao_ult_extremo_tocado     ;} // 1 (ultimo toque foi na regiao superior); -1(ultimo toque foi na regiao inferior)
    double getCoefLinear                (){return m_coef_linear                   ;}
       
};

void osc_canal::inicializar(CSymbolInfo& symb, int qtdPeriodo, double porcRegiaoOperacao){
    
    m_symb_str  = symb.Name();
    m_tick_size = symb.TickSize();
    setShowCanalPrecos(true);
    

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
    m_regiaoInferior                  = 0;
    m_regiaoSuperior                  = 0;
    m_porcRegiaoOperacao              = porcRegiaoOperacao; //0.20;
    m_maxDistanciaEntrelacaParaOperar = 0; //1000;
    m_precoRegiaoInferior             = 0;
    m_precoRegiaoSuperior             = 0;
    m_regiao_ult_extremo_tocado       = 0;
    m_coef_linear                     = 0;
    //----------------------------------------------------------------------------------------------------

    //|-------------------------------------------------------------------------------------
    //| 0. variaveis usadas no metodo calcCoefEntrelacamentoMedio();
    //|-------------------------------------------------------------------------------------
    m_coefEntrelaca                  = 0;
    m_coefEntrelacaInv               = 0;
    m_qtdPeriodo                     = qtdPeriodo;
    m_maxPrecoCanal                  = 0;
    m_minPrecoCanal                  = 0;
    m_len_canal_operacional_em_ticks = 0;
    m_time_desde_entrelaca           = 0;
    m_direcao_entre                  = 0; // indica se a barra total do entrelacamento eh de alta ou baixa...
    //----------------------------------------------------------------------------------------------------
    
    
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
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

bool osc_canal::refresh(double ask, double bid){

    m_bid = bid;
    m_ask = ask;
    
    if( MEA_USA_REGIAO_CANAL_DIA ){ 
        calcOpenMaxMinDia();
    }else{
        calcCoefEntrelacamentoMedio();
    }
    //calcOpenMaxMinDia();
      calcDistPrecoMaxMin();
      return true;
}   


void osc_canal::inicializarVariaveisRecebidasPorParametro(){

    // quantidade de periodos usados para calcular o coeficiente de entrelacamento.
    m_qtdPeriodo = MEA_ENTRELACA_PERIODO_COEF;
    
    // regiao nas extremidades do canal de entrelacamento.
    // definida em % do canal. ex: 0.2 significa:
    //                             ateh 20% abaixo do topo do canal  
    //                             ateh 20% acima  do topo do canal  
    m_porcRegiaoOperacao = MEA_REGIAO_BUY_SELL;
    
    // tamanho maximo em ticks do canal de entrelacamento. Se for maior, fica pintado de vermelho.
    m_maxDistanciaEntrelacaParaOperar = MEA_ENTRELACA_CANAL_MAX; 
}

// retorna a porcentagem como um numero inteiro.
int osc_canal::porcentagem( double parte, double tot, int seTotZero){
    if( tot==0 ){ return seTotZero ; }
                  return (int)( (parte/tot)*100.0);
}

//+-------------------------------------------+
//| destrutor                                 |
//+-------------------------------------------+
/*
osc_canal::~osc_canal(){
                                          Print(__FUNCTION__,":-| Iniciando metodo OnDeinit..." );
    delLineMinPreco();                    Print(__FUNCTION__,":-| Linha de preco minimo elimnada." );
    delLineMaxPreco();                    Print(__FUNCTION__,":-| Linha de preco maximo elimnada." );
    delLineTimeDesdeEntrelaca();          Print(__FUNCTION__,":-| Linha horizontal entrelacamento eliminada." );
    delLineMaiorPrecoCompra();            Print(__FUNCTION__,":-| Linha horizontal regiao de compra." );
    delLineMenorPrecoVenda();             Print(__FUNCTION__,":-| Linha horizontal regiao de venda."  );
    return;
}
*/

//string m_str_line_max_price             = "line_max_price";
//string m_str_line_min_price             = "line_min_price";
//string m_str_line_maior_preco_compra    = "str_line_maior_preco_compra";
//string m_str_line_menor_preco_venda     = "str_line_menor_preco_venda";
//string m_str_line_time_desde_entrelaca  = "line_time_desde_entrelaca";
//bool m_line_min_preco_criada            = false;
//bool m_line_max_preco_criada            = false;
//bool m_line_maior_preco_compra_criada   = false;
//bool m_line_menor_preco_venda_criada    = false;
//bool m_line_time_desde_entrelaca_criada = false;

void osc_canal::drawLineMaxPreco(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_max_preco_criada ){ 
            HLineMove(0,m_str_line_max_price,m_maxPrecoCanal);
        }else{
            HLineCreate(0,m_str_line_max_price,0,m_maxPrecoCanal,clrMediumBlue,STYLE_SOLID);
            m_line_max_preco_criada = true;
        }
        //Print(__FUNCTION__);
        ChartRedraw(0);
    }
    //Print("MEA_SHOW_CANAL_PRECOS=",MEA_SHOW_CANAL_PRECOS);
}

void osc_canal::drawLineMinPreco(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_min_preco_criada ){ 
            HLineMove(0,m_str_line_min_price,m_minPrecoCanal);
        }else{
            HLineCreate(0,m_str_line_min_price,0,m_minPrecoCanal,clrRed,STYLE_SOLID);
            m_line_min_preco_criada = true;
        }
        //Print(__FUNCTION__);
        ChartRedraw(0);
    }
}

void osc_canal::drawLineMaiorPrecoCompra(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_maior_preco_compra_criada ){ 
            HLineMove(0,m_str_line_maior_preco_compra,m_precoRegiaoInferior);
        }else{
            HLineCreate(0,m_str_line_maior_preco_compra,0,m_precoRegiaoInferior,clrDarkGray,STYLE_DOT);
            m_line_maior_preco_compra_criada = true;
        }
        //Print(__FUNCTION__);
        ChartRedraw(0);
    }
}

void osc_canal::drawLineMenorPrecoVenda(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_menor_preco_venda_criada ){ 
            HLineMove(0,m_str_line_menor_preco_venda,m_precoRegiaoSuperior);
        }else{
            HLineCreate(0,m_str_line_menor_preco_venda,0,m_precoRegiaoSuperior,clrDarkGray,STYLE_DOT);
            m_line_menor_preco_venda_criada = true;
        }
        //Print(__FUNCTION__);
        ChartRedraw(0);
    }
}

void osc_canal::drawLineTimeDesdeEntrelaca(){
    if( MEA_SHOW_CANAL_PRECOS ){
        if( m_line_time_desde_entrelaca_criada ){ 
            VLineMove(0,m_str_line_time_desde_entrelaca,m_time_desde_entrelaca); 
        }else{
            VLineCreate(0,m_str_line_time_desde_entrelaca,0,m_time_desde_entrelaca,clrSteelBlue,STYLE_SOLID);
            m_line_time_desde_entrelaca_criada = true;
        }
        //Print(__FUNCTION__);
        ChartRedraw(0);
    }
}

void osc_canal::delLineMinPreco          (){HLineDelete(0,m_str_line_min_price           ); m_line_min_preco_criada            = false;}
void osc_canal::delLineMaxPreco          (){HLineDelete(0,m_str_line_max_price           ); m_line_max_preco_criada            = false;}
void osc_canal::delLineTimeDesdeEntrelaca(){VLineDelete(0,m_str_line_time_desde_entrelaca); m_line_time_desde_entrelaca_criada = false;}
void osc_canal::delLineMaiorPrecoCompra  (){HLineDelete(0,m_str_line_maior_preco_compra  ); m_line_maior_preco_compra_criada   = false;}
void osc_canal::delLineMenorPrecoVenda   (){HLineDelete(0,m_str_line_menor_preco_venda   ); m_line_menor_preco_venda_criada    = false;}


void osc_canal::calcDistPrecoMaxMin(){
    if(MEA_USA_REGIAO_CANAL_DIA){
        m_dxPrecoMaxEmTicks = (m_maxPrecoCanal - m_bid     )/m_tick_size;
        m_dxPrecoMinEmTicks = (m_bid      - m_minPrecoCanal)/m_tick_size;
    }else{
        m_dxPrecoMaxEmTicks = (m_maxPrecoCanal - m_bid     )/m_tick_size;
        m_dxPrecoMinEmTicks = (m_bid      - m_minPrecoCanal)/m_tick_size;
    }

    //if( m_len_canal_operacional_em_ticks == 0 ){
    //}

    calcMaiorPrecoDeCompraVenda();
    m_regiaoInferior = (m_dxPrecoMinEmTicks / m_len_canal_operacional_em_ticks);
    m_regiaoSuperior  = 1-m_regiaoInferior                        ;
}

void osc_canal::calcMaiorPrecoDeCompraVenda(){
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
        
    if( newMaiorPrecoDeCompra != m_precoRegiaoInferior ){
        m_precoRegiaoInferior = newMaiorPrecoDeCompra; 
        drawLineMaiorPrecoCompra();
    }
        
    if( newMenorPrecoDeVenda != m_precoRegiaoSuperior   ){
        m_precoRegiaoSuperior  = newMenorPrecoDeVenda;
        drawLineMenorPrecoVenda();
    }
}

// obtendo a barras de preco do dia
void osc_canal::calcOpenMaxMinDia(){ 
    CopyRates(m_symb_str,PERIOD_D1,0,1,m_ratesDia);
    //ArraySetAsSeries(m_ratesDia,true); // array tem tamanho igual a 1. Nao necessita este metodo.
    if( m_ratesDia[0].high != m_maxPrecoCanal ){ 
        m_maxPrecoCanal = m_ratesDia[0].high;
        m_regiao_ult_extremo_tocado=1;
        drawLineMaxPreco(); 

        //m_len_canal_operacional_em_ticks = (m_maxPrecoCanal - m_minPrecoCanal)/m_tick_size;
        calcMaiorPrecoDeCompraVenda(); 
      //m_direcaoDia   = m_ratesDia[0].close - m_ratesDia[0].open; // se for negativo eh dia de baixa.
    }
    
    if( m_ratesDia[0].low  != m_minPrecoCanal ){ 
        m_minPrecoCanal = m_ratesDia[0].low ; 
        m_regiao_ult_extremo_tocado=-1;
        drawLineMinPreco(); 
        //m_len_canal_operacional_em_ticks = (m_maxPrecoCanal - m_minPrecoCanal)/m_tick_size;
        calcMaiorPrecoDeCompraVenda(); 
      //m_direcaoDia   = m_ratesDia[0].close - m_ratesDia[0].open; // se for negativo eh dia de baixa.
    }

    m_direcaoDia  = m_ratesDia[0].close - m_ratesDia[0].open; // se for negativo eh dia de baixa.
    m_coef_linear = m_direcaoDia/24;
    
}

//|-------------------------------------------------------------------------------------
//| O coeficiente de entrelacamento eh a porcentagem de intersecao do preco da barra
//| atual em relacao a barra anterior.
//|
//| Esta funcao retorna o coeficiente de entrelacacamento medio dos ultimos x periodos 
//|-------------------------------------------------------------------------------------
void osc_canal::calcCoefEntrelacamentoMedio(){
 
    // calculando a cada segundo impar...
    //if( m_date_ant.sec   == m_date_atu.sec ||   // espera mudar o segundo para calcular
    //    m_date_atu.sec%2 == 0                ){ // calcula sempre no segundo impar
    //    return; 
    //}
    
    //Print("MEA_USA_REGIAO_CANAL_DIA=",MEA_USA_REGIAO_CANAL_DIA);
    if( MEA_USA_REGIAO_CANAL_DIA ) return;
    
    double totCoef    = 0;
    int    peso       = m_qtdPeriodo;
    int    totPeso    = 0;
    int    starPos    = 0;
   
    // obtendo as ultimas barras de preco
    //Print("m_symb_str=",m_symb_str,
    //      " _Period=",_Period,
    //      " starPos=",starPos,
    //      " m_qtdPeriodo=",m_qtdPeriodo);
    
    //if( m_qtdPeriodo == 0 ){ Print(":-( ", __FUNCTION__,": m_qtdPeriodo estah zerado. Nao eh possivel calcular o coeficiente de entrelacamento medio!! VERIFIQUE!!!" ); return;}
    
    CopyRates(m_symb_str,_Period,starPos,m_qtdPeriodo,m_ratesEntrelaca);
    ArraySetAsSeries(m_ratesEntrelaca,true);

    double   maxPreco             = m_ratesEntrelaca[0].high;
    double   minPreco             = m_ratesEntrelaca[0].low ;
    datetime time_desde_entrelaca = m_ratesEntrelaca[m_qtdPeriodo-1].time;

    // calculando direcao nas barras de entrelacamento. resultado positivo eh alta, negativo eh baixa.
    m_direcao_entre = m_ratesEntrelaca[0].close - m_ratesEntrelaca[m_qtdPeriodo-1].open;
    m_coef_linear   = m_direcao_entre/m_qtdPeriodo;
    
    for( int i=0; i<m_qtdPeriodo-1; i++){
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
    
    if( maxPreco != m_maxPrecoCanal ){ m_maxPrecoCanal = maxPreco; m_regiao_ult_extremo_tocado= 1; drawLineMaxPreco(); calcMaiorPrecoDeCompraVenda(); }
    if( minPreco != m_minPrecoCanal ){ m_minPrecoCanal = minPreco; m_regiao_ult_extremo_tocado=-1; drawLineMinPreco(); calcMaiorPrecoDeCompraVenda(); }

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
double osc_canal::calcCoefEntrelacamento(double minAnt, double maxAnt, double minAtu, double maxAtu){
   
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