﻿//+------------------------------------------------------------------+
//|                                                 C0005Strategy.mqh|
//|                               Copyright 2021,oficina de software.|
//|                                https://www.metaquotes.net/marcoc.|
//|                                                                  |
//| CLASSE BASE PARA CLASSES QUE IMPLEMENTAM ESTRATEGIAS DE TRADE.   |
//|                                                                  |
//|                                                                  |
//|                                                                  --------------------------------------------|
//|                                                                                                              |
//+--------------------------------------------------------------------------------------------------------------+
#property copyright "2021, Oficina de Software."
#property link      "httpS://www.os.net"

#include <Trade\SymbolInfo.mqh>
//#include <Trade\PositionInfo.mqh>
//#include <Trade\AccountInfo.mqh>


class C0005Strategy{

private:
    int         m_codUltErro;
    string      m_msgUltErro;
    
    string           m_in   ;
    string           m_inb  ;
    string           m_ins  ;
    CSymbolInfo      m_symb ;
    osc_minion_trade m_trade; // operacao com ordens
    
    double m_vol            ;// volume padrao quando nao eh informado
    
    double m_spread;
    int    m_digits;
    
protected:
public:
    
    bool inicializar(string strSymb, ulong magic);
    bool abrir();
    bool abrirRajada(ENUM_ORDER_TYPE orderType, double preco, int lag, int lenRajada, string comentario);
    bool temPosicaoAberta();
    bool fireNorteSul(double precoOrdemExecutada, int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0); // recebe uma ordem executada e abre uma ordem se entrada e outra de saida a xx ticks da ordem recebida. 
    
    void setSpread(double spread){ m_spread = spread; m_digits=m_symb.Digits(); }
    double getSpread(){ return m_spread; }
    
    string getMsgUltErro(){ return m_msgUltErro;}
    int    getCodUltErro(){ return m_codUltErro;}
    
    double normalizar(const double price);
};


//-----------------------------------------------------------------------------
// // recebe preco de ordem executada e abre uma ordem de entrada e outra de saida
// // a xx ticks da ordem recebida. 
//-----------------------------------------------------------------------------
//
// precoOrdemExecutada: in preco da ordem executada que disparou o pedido de colocacao de ordens acima e abaixo.
// lagEmTicks         : distancia entre o preco da ordem executada e as ordens que serão colocadas por esta funcao. 
//-----------------------------------------------------------------------------
#define SENTIDO_POSICAO_COMPRA  1
#define SENTIDO_POSICAO_VENDA  -1
bool C0005Strategy::fireNorteSul(double precoOrdemExecutada, int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0){

    if(precoOrdemExecutada==0){
        // tratar erro
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," ERRO: precoOrdemExecutada ZERADO. VERIFIQUE!!!!");
        return false;
    }
    
    if( lagEmTicks == 0 ){
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," ERRO: lagEmTicks ZERADO. VERIFIQUE!!!!");
        return false;
    }
    
    //double precoCompra = m_symb.NormalizePrice( precoOrdemExecutada-lagEmTicks*m_symb.TickSize() );
    //double precoVenda  = m_symb.NormalizePrice( precoOrdemExecutada+lagEmTicks*m_symb.TickSize() );
    
    // aparentemente algumas ordens entram com slip, fazendo com que o mapa de saida fique descalibrado
    // e colocando ordens de saida proximas umas das outras.
    double precoCompra = normalizar( precoOrdemExecutada-lagEmTicks*m_symb.TickSize() );
    double precoVenda  = normalizar( precoOrdemExecutada+lagEmTicks*m_symb.TickSize() );

    if( precoCompra > ultTick.bid ) precoCompra = ultTick.bid;
    if( precoVenda  < ultTick.ask ) precoVenda  = ultTick.ask;


    Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," precoCompra:",precoCompra," precoVenda:",precoVenda);
    //m_symb.RefreshRates();
    //if( precoCompra > m_symb.Ask() ) precoCompra = m_symb.Ask();
    //if( precoVenda  < m_symb.Bid() ) precoVenda  = m_symb.Bid();

    //if( m_trade.tenhoOrdemPendente(preco) ){ return false; }
    
    //if( temPosicaoAberta() ){ return false; }

    if(sleep>0) Sleep(sleep);
    
    if( !m_trade.tenhoOrdemPendente(precoCompra) ){
        m_trade.setAsync(true);
        m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoCompra, m_vol, m_inb);
        if( sentidoPosicao == SENTIDO_POSICAO_COMPRA ){ m_trade.cancelarOrdensComentadasDeCompraMenoresQue(m_symb.Name(),m_inb,precoCompra); }
        m_trade.setAsync(false);
    }else{
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") precoCompra:",precoCompra," jah tem uma ordem na posicao. Ordem de compra nao colocada.");
    }
    if( !m_trade.tenhoOrdemPendente(precoVenda ) ){
        m_trade.setAsync(true);
        m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoVenda , m_vol, m_ins);
        if( sentidoPosicao == SENTIDO_POSICAO_VENDA ){ m_trade.cancelarOrdensComentadasDeVendaMaioresQue(m_symb.Name(),m_ins,precoVenda); }
        m_trade.setAsync(false);
    }else{
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") precoVenda:",precoVenda," jah tem uma ordem na posicao. Ordem de compra nao colocada.");
    }
    
    return true;
}
//-----------------------------------------------------------------------------



//-----------------------------------------------------------------------------
// inicializa para trabalhar com os parametros informados a saber:
//-----------------------------------------------------------------------------
//
// strSymb : in ticker do simbolo cujas posicoes serao gerenciadas.
// magic   : in numero magico das ordens que serao colocadas.
//-----------------------------------------------------------------------------
bool C0005Strategy::inicializar(string strSymb, ulong magic){
    m_symb.Name(strSymb);
    m_symb.Refresh();
    
    if( !m_symb.RefreshRates() ){
        m_codUltErro = GetLastError();
        m_msgUltErro = "Erro inicializacao simbolo ";
        StringConcatenate(m_msgUltErro, strSymb, " codErro:", m_codUltErro );
        return false;
    }
    m_vol = m_symb.LotsMin();
    
    m_trade.setSymbol  ( strSymb );
    m_trade.setMagic   ( magic   );
    m_trade.setStopLoss( 0       );
    m_trade.setTakeProf( 0       );
    m_trade.setVolLote ( m_vol   );
    
    m_in  = "IN";
    m_inb = "INB";
    m_ins = "INS";
    
    return true;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// abre ordens de posicao rajada com os parametros informados a saber:
//-----------------------------------------------------------------------------
//
// orderType : in tipo da ordem de abertura. Suporte para ordens limitadas.
// preco     : in preco da ordem de abertura. Se houver uma ordem pendente no preco, nao abre. 
// lag       : in tamanho do lag em ticks.
// lenRajada : in tamanho da rajada.
// comentario: in comentario a colocar nas ordens de abertura de posicao
//-----------------------------------------------------------------------------
bool C0005Strategy::abrirRajada(ENUM_ORDER_TYPE orderType, double preco, int lag, int lenRajada, string comentario){

    if(preco==0){
        // tratar erro
        return false;
    }

    if( m_trade.tenhoOrdemPendente(preco) ){ return false; }
    
    if( temPosicaoAberta() ){ return false; }

    switch(orderType){
        case ORDER_TYPE_SELL_LIMIT:
                
            m_trade.preencherOrdensLimitadasDeVendaAcimaComLag2(preco            ,
                                                                lenRajada        ,
                                                                m_symb.Name()    ,
                                                                comentario       ,
                                                                m_vol            ,
                                                                m_symb.TickSize(),
                                                                lag              );
    
            return true;

        case ORDER_TYPE_BUY_LIMIT:
            m_trade.preencherOrdensLimitadasDeCompraAbaixoComLag2(preco            ,
                                                                  lenRajada        ,
                                                                  m_symb.Name()    ,
                                                                  comentario       ,
                                                                  m_vol            ,
                                                                  m_symb.TickSize(),
                                                                  lag              );
            return true;
   }
    
   return false;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// abre ordens de posicao rajada com os parametros informados a saber:
//-----------------------------------------------------------------------------
//
// price  : in preco  
// retorna: out preco normalizado pelo spread e m_digits configurados na instancia.
//-----------------------------------------------------------------------------
double C0005Strategy::normalizar(const double price) {
   if(m_spread!=0) return(NormalizeDouble(MathRound(price/m_spread)*m_spread,m_digits));
   return(NormalizeDouble(price,m_digits));
}
//-----------------------------------------------------------------------------
