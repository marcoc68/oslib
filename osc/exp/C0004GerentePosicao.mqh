//+------------------------------------------------------------------+
//|                                           C0004GerentePosicao.mqh|
//|                               Copyright 2020,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//|                                                                  |
//| FAZ GERENCIAMENTO DE POSICOES                                    |
//| - inicializar()                                                  |
//| - abrir()                                                        |
//| - reverter()                                                     |
//| - processarTransacao()                                           |
//| - fecharPosicao()                                                |
//|                                                                  |
//|                                                                  --------------------------------------------|
//| REGRAS                                                                                                       |
//| - C01 - if mercado estah comprador e compra estah acelerando e volVenda estah freiando   then riscoCompra-01 |
//| - C02 - if mercado estah comprador e compra estah acelerando e volVenda estah acelerando then riscoCompra-02 |
//| - C03 - if mercado estah comprador e compra estah freiando   e volVenda estah freiando   then riscoCompra-02 |
//| - C04 - if mercado estah comprador e compra estah freiando   e volVenda estah acelerando then riscoCompra-03 |
//|                                                                                                              |
//+--------------------------------------------------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

#include <oslib\osc-util.mqh>
#include <oslib\osc\osc-minion-trade-03.mqh>


#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
//#include <Trade\AccountInfo.mqh>

#define SENTIDO_POSICAO_COMPRA  1
#define SENTIDO_POSICAO_VENDA  -1

class C004GerentePosicao{

private:
    int         m_codUltErro;
    string      m_msgUltErro;
    
    string           m_in   ;
    string           m_inb  ;
    string           m_ins  ;
    string           m_inr  ;
    CSymbolInfo      m_symb ;
    osc_minion_trade m_trade; // operacao com ordens
    CPositionInfo    m_position;
    
    double m_vol            ;// volume padrao quando nao eh informado
    
    double m_spread;
    int    m_digits;
    int    m_t4gMin;
    double m_tick_size;
    int    m_signal; // sinal da posicao. (-1) venda, (+1) compra, (0) nao posicionado

    int    m_lagEmTicks;
    int    m_tamanhoRajada;
    int    m_reduz_t4g_a_cada_x_seg;
    
protected:
public:
    
    bool inicializar(string strSymb, ulong magic, int lagEmTicks=1, int tamanhoRajada=3, int reduz_t4g_a_cada_x_seg=0);
    bool abrir();
    bool abrirRajada(ENUM_ORDER_TYPE orderType, double preco, int lag, int lenRajada, string comentario);
    bool temPosicaoAberta();
    int  getSignal(){ return   m_signal     ; } // positioned() deve ter sido chamado antes de executar esta funcao
    bool isBuyer  (){ return (getSignal()>0); } // positioned() deve ter sido chamado antes de executar esta funcao
    bool isSeller (){ return (getSignal()<0); } // positioned() deve ter sido chamado antes de executar esta funcao
    string getAnimal(){
        if( isBuyer () ) return "BULL";
        if( isSeller() ) return "BEAR";
                         return "FANTHON";
    }
    
    bool doCloseOposite ( double precoOrdemExecutada, double t4g, double vol, MqlTick& ultTick, int sleep, ENUM_DEAL_TYPE typeDeal, long ticket=0 );
    bool doCloseOposite2( double precoOrdemExecutada, double t4g, double vol, MqlTick& ultTick, int sleep, ENUM_DEAL_TYPE typeDeal, long ticket=0 );
    
    // recebe uma ordem executada e abre uma ordem se entrada e outra de saida a xx ticks da ordem recebida. 
    bool fireNorteSul(double precoOrdemExecutada,             int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0);
    bool fireNorteSul(double precoOrdemExecutada, double vol, int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0);

    bool fireNorteSulRajada(double precoOrdemExecutada,             int t4g, int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0);
    bool fireNorteSulRajada(double precoOrdemExecutada, double vol, int t4g, int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0);

    void preencherOrdensLimitadasDeCompraAbaixoComLag2(double valIni, int qtdOrdens, string comment, int lagEmTicks);
    void preencherOrdensLimitadasDeVendaAcimaComLag2  (double valIni, int qtdOrdens, string comment, int lagEmTicks);

    void cancelarOrdensMaioresOuIguaisA( ENUM_ORDER_TYPE order_type, double price);
    void cancelarOrdensMenoresOuIguaisA( ENUM_ORDER_TYPE order_type, double price);

    double encontrarPrecoCompra(double preco);
    double encontrarPrecoVenda (double preco);
    
    void setSpread(double spread){ m_spread = spread; m_digits=m_symb.Digits(); }
    double getSpread(){ return m_spread; }
    
    string getMsgUltErro(){ return m_msgUltErro; }
    int    getCodUltErro(){ return m_codUltErro; }
    
    double normalizar(const double price);
    int trazerOrdensAfastadasParaProximoDoBreakEven( double t4g=1 );

    int reverterPosicao();
    int fecharPosicao();

    
    void setT4gMin(int t4gMin){ m_t4gMin = t4gMin;}
    
    double getLotsMin(){return m_vol;}
    
    bool positioned(){
        m_signal = calcSignalPosition();
        if( m_signal == 0 ) return false;
        return true;
    }

    int calcSignalPosition(){ 
        if( m_position.Select(m_symb.Name()) ){
            int retorno = -1;
            if( m_position.PositionType() == POSITION_TYPE_BUY ) { retorno = +1; }
            return retorno;
        }
        return 0;
    }
};

// ticket: se informado, serah colocado como comentario na ordem que estah sendo criada.
bool C004GerentePosicao::doCloseOposite( double precoOrdemExecutada, double t4g, double vol, MqlTick& ultTick, int sleep, ENUM_DEAL_TYPE typeDeal, long ticket=0 ){

    if( t4g < m_t4gMin ){ 
        Print(__FUNCTION__," :-( ERRO GRAVE: T4G menor que o minimo permitido. Recebido:",t4g, " minimo permitido:", m_t4gMin);  
        t4g = m_t4gMin;
    }
    
    // aparentemente algumas ordens entram com slip, fazendo com que o mapa de saida fique descalibrado
    // e colocando ordens de saida proximas umas das outras.
    double precoCompra = normalizar( precoOrdemExecutada-t4g*m_symb.TickSize() );
    double precoVenda  = normalizar( precoOrdemExecutada+t4g*m_symb.TickSize() );

    if( precoCompra > ultTick.bid ) precoCompra = ultTick.bid;
    if( precoVenda  < ultTick.ask ) precoVenda  = ultTick.ask;

    if(sleep>0) Sleep(sleep);

    m_trade.saveAsync();
    m_trade.setAsync(false);

    if( typeDeal == DEAL_TYPE_BUY ){
        Print(__FUNCTION__," Vendendo a:", precoVenda, " ...");
    	if(m_trade.tenhoOrdemLimitadaDeVendaMenorOuIgual(precoVenda)==0 ){
        	if(ticket>0){
                    m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoVenda, vol, IntegerToString(ticket) ); // fechamento de posicao
        	}else{
                    m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoVenda, vol, m_ins); // abertura de posicao
        	}
    	}
    }
    
    if( typeDeal == DEAL_TYPE_SELL ){
        Print(__FUNCTION__," Comprando a:", precoCompra, " ...");

    	if(!m_trade.tenhoOrdemLimitadaDeCompraMaiorOuIgual(precoCompra) ){
        	if(ticket>0){
        		m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoCompra, vol, IntegerToString(ticket)); // fechamento de posicao
        	}else{
        		m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoCompra, vol, m_inb); // abertura de posicao
        	}
        }
    }

    m_trade.restoreAsync();
    return true;
}

// ticket: se informado, serah colocado como comentario na ordem que estah sendo criada.
// a diferenca deste para doCloseOposite eh que este mantem apenas uma ordem em cada lado da transacao executada
bool C004GerentePosicao::doCloseOposite2( double precoOrdemExecutada, double t4g, double vol, MqlTick& ultTick, int sleep, ENUM_DEAL_TYPE typeDeal, long ticket=0 ){

    //if( t4g < m_t4gMin ){ 
    //    Print(__FUNCTION__," :-( ERRO GRAVE: T4G menor que o minimo permitido. Recebido:",t4g, " minimo permitido:", m_t4gMin);  
    //    t4g = m_t4gMin;
    //}
    
    
    // aparentemente algumas ordens entram com slip, fazendo com que o mapa de saida fique descalibrado
    // e colocando ordens de saida proximas umas das outras.
    double precoCompra = normalizar( precoOrdemExecutada-t4g*m_symb.TickSize() );
    double precoVenda  = normalizar( precoOrdemExecutada+t4g*m_symb.TickSize() );

  //if( precoCompra > ultTick.bid ) precoCompra = ultTick.bid;
  //if( precoVenda  < ultTick.ask ) precoVenda  = ultTick.ask;
    m_symb.RefreshRates();
    if( precoCompra > m_symb.Bid() ) precoCompra = m_symb.Bid();
    if( precoVenda  < m_symb.Ask() ) precoVenda  = m_symb.Ask();

    if(sleep>0) Sleep(sleep);

    m_trade.saveAsync();
    m_trade.setAsync(false);

    if( typeDeal == DEAL_TYPE_BUY ){
        Print(__FUNCTION__," Vendendo a:", precoVenda, " ...");
    	if(m_trade.tenhoOrdemLimitadaDeVendaMenorOuIgual(precoVenda)==0 ){
        	if(ticket>0){
                  //m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoVenda, vol, IntegerToString(ticket) ); // fechamento de posicao
                    m_trade.manterOrdemLimitadaNoRoom(ORDER_TYPE_SELL_LIMIT, IntegerToString(ticket), precoVenda, t4g, vol);
        	}else{
                  //m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoVenda, vol, m_ins); // abertura de posicao
                    m_trade.manterOrdemLimitadaNoRoom(ORDER_TYPE_SELL_LIMIT, m_ins                  , precoVenda, t4g, vol);
        	}
    	}
    }
    
    if( typeDeal == DEAL_TYPE_SELL ){
        Print(__FUNCTION__," Comprando a:", precoCompra, " ...");

    	if(!m_trade.tenhoOrdemLimitadaDeCompraMaiorOuIgual(precoCompra) ){
        	if(ticket>0){
              //m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoCompra, vol, IntegerToString(ticket)); // fechamento de posicao
                m_trade.manterOrdemLimitadaNoRoom(ORDER_TYPE_BUY_LIMIT, IntegerToString(ticket), precoCompra, t4g, vol);
        	}else{
              //m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoCompra, vol, m_inb); // abertura de posicao
                m_trade.manterOrdemLimitadaNoRoom(ORDER_TYPE_BUY_LIMIT, m_ins, precoCompra, t4g, vol);
        	}
        }
    }

    m_trade.restoreAsync();
    return true;
}

//-----------------------------------------------------------------------------
// // recebe preco de ordem executada e abre uma ordem de entrada e outra de saida
// // a xx ticks da ordem recebida. 
//-----------------------------------------------------------------------------
//
// precoOrdemExecutada: in preco da ordem executada que disparou o pedido de colocacao de ordens acima e abaixo.
// lagEmTicks         : distancia entre o preco da ordem executada e as ordens que serão colocadas por esta funcao. 
//-----------------------------------------------------------------------------
bool C004GerentePosicao::fireNorteSul(double precoOrdemExecutada,             int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0){
    return fireNorteSul(precoOrdemExecutada, m_vol, lagEmTicks, ultTick, sleep, sentidoPosicao);
}

bool C004GerentePosicao::fireNorteSul(double precoOrdemExecutada, double vol, int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0){
    
    if(vol==0){
        vol = m_vol;
        //Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," VOLUME ZERADO. CORRIGIDO PARA ",m_vol," VERIFIQUE!!!!");
    }

    if(precoOrdemExecutada==0){
        // tratar erro
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," ERRO: precoOrdemExecutada ZERADO. VERIFIQUE!!!!");
        return false;
    }
    
    if( lagEmTicks == 0 ){
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," ERRO: lagEmTicks ZERADO. VERIFIQUE!!!!");
        lagEmTicks = m_lagEmTicks;
        return false;
    }
    
    if( lagEmTicks < m_t4gMin ){ lagEmTicks = m_t4gMin; }
    
    //double precoCompra = m_symb.NormalizePrice( precoOrdemExecutada-lagEmTicks*m_symb.TickSize() );
    //double precoVenda  = m_symb.NormalizePrice( precoOrdemExecutada+lagEmTicks*m_symb.TickSize() );
    
    // aparentemente algumas ordens entram com slip, fazendo com que o mapa de saida fique descalibrado
    // e colocando ordens de saida proximas umas das outras.
    double precoCompra = normalizar( precoOrdemExecutada-lagEmTicks*m_symb.TickSize() );
    double precoVenda  = normalizar( precoOrdemExecutada+lagEmTicks*m_symb.TickSize() );

    if( precoCompra > ultTick.bid ) precoCompra = ultTick.bid;
    if( precoVenda  < ultTick.ask ) precoVenda  = ultTick.ask;


    //Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," precoCompra:",precoCompra," precoVenda:",precoVenda);
    //m_symb.RefreshRates();
    //if( precoCompra > m_symb.Ask() ) precoCompra = m_symb.Ask();
    //if( precoVenda  < m_symb.Bid() ) precoVenda  = m_symb.Bid();

    //if( m_trade.tenhoOrdemPendente(preco) ){ return false; }
    
    //if( temPosicaoAberta() ){ return false; }

    if(sleep>0) Sleep(sleep);
    
    precoCompra = encontrarPrecoCompra(precoCompra);    
    if( !m_trade.tenhoOrdemPendente(precoCompra) ){
         m_trade.setAsync(true);
         m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoCompra, vol, m_inb);
         //if( sentidoPosicao == SENTIDO_POSICAO_COMPRA ){ m_trade.cancelarOrdensComentadasDeCompraMenoresQue(m_symb.Name(),m_inb,precoCompra); }
         m_trade.setAsync(false);
    }else{
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") precoCompra:",precoCompra," jah tem uma ordem na posicao. Ordem de compra nao colocada.");
    }
    
    precoVenda = encontrarPrecoVenda(precoVenda);
    if( !m_trade.tenhoOrdemPendente(precoVenda ) ){
         m_trade.setAsync(true);
         m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoVenda , vol, m_ins);
         //if( sentidoPosicao == SENTIDO_POSICAO_VENDA ){ m_trade.cancelarOrdensComentadasDeVendaMaioresQue(m_symb.Name(),m_ins,precoVenda); }
         m_trade.setAsync(false);
    }else{
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") precoVenda:",precoVenda," jah tem uma ordem na posicao. Ordem de compra nao colocada.");
    }
    
    m_lagEmTicks = lagEmTicks;
    return true;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// // recebe preco de ordem executada e abre uma ordem de entrada e outra de saida
// // a xx ticks da ordem recebida. 
//-----------------------------------------------------------------------------
//
// precoOrdemExecutada: in preco da ordem executada que disparou o pedido de colocacao de ordens acima e abaixo.
// lagEmTicks         : distancia entre o preco da ordem executada e as ordens que serão colocadas por esta funcao. 
//-----------------------------------------------------------------------------
bool C004GerentePosicao::fireNorteSulRajada(double precoOrdemExecutada,        int t4g,      int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0){
    return               fireNorteSulRajada(       precoOrdemExecutada, m_vol,     t4g,          lagEmTicks,          ultTick,     sleep,       sentidoPosicao);
       //     gerentePos.fireNorteSulRajada(            toClosePriceIn, vol  , (int)(t4g+ticksAdd),             tick, SLEEP_TESTE     ,pos_type )
}

bool C004GerentePosicao::fireNorteSulRajada(double precoOrdemExecutada, double vol, int t4g, int lagEmTicks, MqlTick& ultTick, int sleep=0, int sentidoPosicao=0){

    if(vol==0){
        vol = m_vol;
        //Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," VOLUME ZERADO. CORRIGIDO PARA ",m_vol," VERIFIQUE!!!!");
    }
    vol = m_vol;

    if(precoOrdemExecutada==0){
        // tratar erro
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," ERRO: precoOrdemExecutada ZERADO. VERIFIQUE!!!!");
        return false;
    }
    
    if( lagEmTicks == 0 ){
        Print(__FUNCTION__,"(",precoOrdemExecutada,",",lagEmTicks,",",sleep,") "," ERRO: lagEmTicks ZERADO. VERIFIQUE!!!!");
        lagEmTicks = m_lagEmTicks;
        return false;
    }
    
    //if( lagEmTicks < m_t4gMin ){ lagEmTicks = m_t4gMin; }

  //double precoCompra = normalizar( precoOrdemExecutada-lagEmTicks*m_symb.TickSize()*2.0 );
  //double precoVenda  = normalizar( precoOrdemExecutada+lagEmTicks*m_symb.TickSize()*2.0 );
    double precoCompra = normalizar( precoOrdemExecutada-       t4g*m_symb.TickSize()     );
    double precoVenda  = normalizar( precoOrdemExecutada+       t4g*m_symb.TickSize()     );

    // aproximando as ordens de saida, 1 tick a cada 10 segundos no posicao...
    if( m_reduz_t4g_a_cada_x_seg > 0 ){
        int timePosition = (int)( TimeCurrent() - m_position.Time());
        int ticksPorTime = timePosition/m_reduz_t4g_a_cada_x_seg;
    
        if( ticksPorTime >= 1 && ticksPorTime < 50000 && getSignal() != 0 ){
            Print(__FUNCTION__,":", m_symb.Name(), ": Tempo na posicao ",getAnimal()," eh ",timePosition,"seg. Reduzindo a saida da posicao em ", ticksPorTime, " ticks...");
            if( isBuyer () ) precoVenda  = precoVenda  - ticksPorTime*m_symb.TickSize();
            if( isSeller() ) precoCompra = precoCompra + ticksPorTime*m_symb.TickSize();
        }
    }

    // Ops, algo deu errado no calculo dos precos, entao trazemos para os melhors bid e ask.
    if( precoCompra > ultTick.bid ) precoCompra = ultTick.bid;
    if( precoVenda  < ultTick.ask ) precoVenda  = ultTick.ask;

    if(sleep>0) Sleep(sleep);
    
    m_trade.preencherOrdensLimitadasDeCompraAbaixoComLag2(precoCompra, m_tamanhoRajada, m_symb.Name(), m_inb, vol, m_tick_size, lagEmTicks);
    m_trade.preencherOrdensLimitadasDeVendaAcimaComLag2  (precoVenda , m_tamanhoRajada, m_symb.Name(), m_ins, vol, m_tick_size, lagEmTicks);
    
    //m_lagEmTicks = lagEmTicks;
    return true;
}
//-----------------------------------------------------------------------------


void C004GerentePosicao::preencherOrdensLimitadasDeCompraAbaixoComLag2(double valIni, int qtdOrdens, string comment, int lagEmTicks){
    m_trade.preencherOrdensLimitadasDeCompraAbaixoComLag2(valIni, qtdOrdens, m_symb.Name(), comment, m_vol, m_tick_size, lagEmTicks);
}

void C004GerentePosicao::preencherOrdensLimitadasDeVendaAcimaComLag2(double valIni, int qtdOrdens, string comment, int lagEmTicks){
    m_trade.preencherOrdensLimitadasDeVendaAcimaComLag2(valIni, qtdOrdens, m_symb.Name(), comment, m_vol, m_tick_size, lagEmTicks);
}

// encontra um preco menor ou igual ao informado, no qual nao exista ordem pendente.
double C004GerentePosicao::encontrarPrecoCompra(double preco){
    while( m_trade.tenhoOrdemPendente(preco) ){
        preco = preco - m_symb.TickSize();
    }
    return normalizar(preco);
}

// encontra um preco maior ou igual ao informado, no qual nao exista ordem pendente.
double C004GerentePosicao::encontrarPrecoVenda(double preco){
    while( m_trade.tenhoOrdemPendente(preco) ){
        preco = preco + m_symb.TickSize();
    }
    return normalizar(preco);
}

//-----------------------------------------------------------------------------
// inicializa para trabalhar com os parametros informados a saber:
//-----------------------------------------------------------------------------
//
// strSymb : in ticker do simbolo cujas posicoes serao gerenciadas.
// magic   : in numero magico das ordens que serao colocadas.
//-----------------------------------------------------------------------------
bool C004GerentePosicao::inicializar(string strSymb, ulong magic, int lagEmTicks=1, int tamanhoRajada=3, int reduz_t4g_a_cada_x_seg=0){
    m_symb.Name(strSymb);
    m_symb.Refresh();
    m_tick_size     = m_symb.TickSize(); 
    
    m_lagEmTicks             = lagEmTicks;
    m_tamanhoRajada          = tamanhoRajada;
    m_reduz_t4g_a_cada_x_seg = reduz_t4g_a_cada_x_seg;

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
    
    m_position.Select(strSymb);
    
    m_in  = "IN";
    m_inb = "INB";
    m_ins = "INS";
    m_inr = "INR";
    
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
bool C004GerentePosicao::abrirRajada(ENUM_ORDER_TYPE orderType, double preco, int lag, int lenRajada, string comentario){

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
double C004GerentePosicao::normalizar(const double price) {
   if(m_spread!=0) return(NormalizeDouble(MathRound(price/m_spread)*m_spread,m_digits));
   return(NormalizeDouble(price,m_digits));
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// Traz ordens de saida a mais de 2 TICKS_4_GAIN do breakeven, para TICKTS_4_GAIN+1 do breakeven.
// Se jah houver ordem de saida no novo psicionamento, vai afastando 1 ticket de forma que as ordens fiquem
// conforme a sequencia abaixo:
// 
// EXEMPLO BREAKEVEN DA VENDA NO 1000 COM 3 TICKS_4_GAIN E 4 ORDENS DE SAIDA. CADA TICKET VALENDO 05 UNIDADES.
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
//-----------------------------------------------------------------------------
// in t4g: distancia em tikets desde o breakeven ateh a primeira ordem de saida da posicao com ganho...
int C004GerentePosicao::trazerOrdensAfastadasParaProximoDoBreakEven( double t4g=1 ){
    // se nao estah posisionado volta daqui.
    if( !positioned() ) return 0;
    
    //1. obtenha o valor do breakeven
    double break_even = m_position.PriceOpen();
    
    //2. obtenha o valor de t4g e calcule qual deve ser a posicao da ordem de saida mais próxima do breakeven
    double order_out_1 = break_even + t4g*m_tick_size*(double)m_signal;
    
    //3. obtenha a quantidade de ordens de saida pendentes e calcule qual deve ser a posicao da ordem mais afastada do breakeven
    double qtd_ordens_pendentes = m_trade.contarOrdensPendentes(m_signal*-1);
    if( qtd_ordens_pendentes == 0 ) return 0; 
    
    double order_out_2 = order_out_1 + qtd_ordens_pendentes*m_tick_size*m_signal;
    //Print( __FUNCTION__ , " :-| ", "sigPos:"     , m_signal,
    //                               " brkeve:"    , break_even ,
    //                               " iniRegAprx:", order_out_1,
    //                               " fimRegAprx:", order_out_2,
    //                               " ordPends:"  , qtd_ordens_pendentes);
   
    
    //4. As duas posicoes acima delimitam a regiao de aproximacao. Depois dela, eh a regiao de afastamento.
    //5. faca um loop sobre as ordens de saida.
    //5.1 para cada ordem na regiao de afastamento, coloque-a em uma posicao livre na regiao de aproximacao.
    return m_trade.remanejarOrdensPendentes( m_signal*-1, order_out_1, order_out_2, 1 );
}

int C004GerentePosicao::reverterPosicao(){
    // se nao estah posisionado volta daqui.
    if( !positioned() ) return 0;
    
    // descobrir volume pendente
    //Print(__FUNCTION__,":",m_symb.Name(),":m_position.Volume():",m_position.Volume() );
    //Print(__FUNCTION__,":",m_symb.Name(),":m_symb.LotsMin   ():",m_symb.LotsMin   () );
    int vol = (int)( (m_position.Volume()/m_symb.LotsMin())*2.0 );
    //Print(__FUNCTION__,":",m_symb.Name(),":vol                :",vol                 );
    
    // atualizando as cotacoes...
    m_symb.RefreshRates();
    
    // estou comprado, entao vendo o dobro do volume ao menor preco limitado...
    if( m_position.PositionType() == POSITION_TYPE_BUY ){
        return m_trade.enviarOrdemPendente(ORDER_TYPE_SELL,m_symb.Ask(),m_position.Volume()*2,m_inr);
        //while(vol-- >= 0){
        //    
        //    //Print(__FUNCTION__,":",m_symb.Name(),":vendendo lote minimo: novo vol:",vol );
        //    m_trade.venderLimit( m_symb.Ask(),m_inr );
        //}
        //return 1;
    }
    
    // estou vendido, entao compro o dobro do volume ao menor preco limitado... 
    if( m_position.PositionType() == POSITION_TYPE_SELL ){
        return m_trade.enviarOrdemPendente(ORDER_TYPE_BUY,m_symb.Bid(),m_position.Volume()*2,m_inr);
        //while(vol-- >= 0){
        //    //Print(__FUNCTION__,":",m_symb.Name(),":vendendo lote minimo: novo vol:",vol );
        //   m_trade.comprarLimit( m_symb.Bid(), m_inr );
        //}
        //return 1;
    }
    
    return 0;
    
}
//-----------------------------------------------------------------------------

//|-----------------------------------------------------------------------------
//| Envia ordens de fechamento de posicao. Mantem ordens pendentes
//|-----------------------------------------------------------------------------
int C004GerentePosicao::fecharPosicao(){
    // se nao estah posisionado volta daqui.
    if( !positioned() ) return 0;
    
    // descobrir volume pendente
    //Print(__FUNCTION__,":",m_symb.Name(),":m_position.Volume():",m_position.Volume() );
    //Print(__FUNCTION__,":",m_symb.Name(),":m_symb.LotsMin   ():",m_symb.LotsMin   () );
    int vol = (int)( (m_position.Volume()/m_symb.LotsMin()) );
    //Print(__FUNCTION__,":",m_symb.Name(),":vol                :",vol                 );
    
    // atualizando as cotacoes...
    m_symb.RefreshRates();
    
    // estou comprado, entao vendo o dobro do volume ao menor preco limitado...
    if( m_position.PositionType() == POSITION_TYPE_BUY ){
        //return m_trade.enviarOrdemPendente(ORDER_TYPE_SELL,m_symb.Bid(),vol,m_ins);
        Print(__FUNCTION__,":",m_symb.Name(),": vendendo em ",m_symb.Bid()," para fechar posicao comprada..." );
        return m_trade.enviarOrdemAMercado(m_symb.Bid(),ORDER_TYPE_SELL,m_ins);
    }
    
    // estou vendido, entao compro o dobro do volume ao menor preco limitado... 
    if( m_position.PositionType() == POSITION_TYPE_SELL ){
        //return m_trade.enviarOrdemPendente(ORDER_TYPE_BUY,m_symb.Ask(),vol,m_inb);
        Print(__FUNCTION__,":",m_symb.Name(),": comprando em ",m_symb.Ask(), " para fechar posicao vendida..." );
        return m_trade.enviarOrdemAMercado(m_symb.Ask(),ORDER_TYPE_BUY,m_inb);
    }
    
    return 0;
    
}
//-----------------------------------------------------------------------------
//|-----------------------------------------------------------------------------------
//| cancela ordens pendentes, do tipo informado, com preco menor ou igual ao informado
//|-----------------------------------------------------------------------------------
void C004GerentePosicao::cancelarOrdensMenoresOuIguaisA( ENUM_ORDER_TYPE order_type, double price){
    m_trade.cancelarOrdensMenoresQue( order_type, price, true );
}
//------------------------------------------------------------------------------------
//|-----------------------------------------------------------------------------------
//| cancela ordens pendentes, do tipo informado, com preco maior ou igual ao informado
//|-----------------------------------------------------------------------------------
void C004GerentePosicao::cancelarOrdensMaioresOuIguaisA( ENUM_ORDER_TYPE order_type, double price){
    m_trade.cancelarOrdensMaioresQue( order_type, price, true );
}
//------------------------------------------------------------------------------------
