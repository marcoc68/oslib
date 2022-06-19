//+------------------------------------------------------------------+
//|                                                 osc_minion_trade.|
//|                               Copyright 2010,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
#property copyright "2010, Oficina de Software."
#property link      "http://www.os.net"
//---
//#include <Expert\ExpertTrade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>
#include <Generic\HashMap.mqh>
#include <Object.mqh>

#define M_TIME_SLEEP_MANY_REQUESTS 50
//#define MAX_TENTATIVAS_CORRECAO_INVALID_PRICE 10
  #define MAX_TENTATIVAS_CORRECAO_INVALID_PRICE 1

// estrutura usada para guardar ordens enviadas pro mercado bem como seu ultimo status.
class TradeOrder : public CObject{
public:
  MqlTradeRequest req;
  MqlTradeResult  res;
};

//class osc_minion_trade : public CExpertTrade{
class osc_minion_trade : public CTrade{
private:
   CHashMap<ulong,TradeOrder*> m_ordens;
   
   MqlTradeRequest m_treq                           ;  // To be used for sending our trade requests
   MqlTradeResult  m_tres                           ;  // To be used to get our trade results
 //bool            enviarOrdemPendenteStop(ENUM_ORDER_TYPE tipo, int offset, string obs);
   double          m_stp                            ;
   double          m_tkp                            ;
   double          m_stpV                           ;
   double          m_tkpV                           ;
   int             m_digits                         ;
   ulong           m_mmagic                         ; // transforme em parametro
   int             m_desvio                         ; // transforme em parametro
   int             m_digitos                        ;
   double          m_point                          ;
   double          m_volume                         ;
   COrderInfo      m_order                          ;
   CPositionInfo   m_position                       ;
   bool            m_async                          ;
   bool            m_async_salvo                    ;
   CSymbolInfo     m_symb                           ;
   string          m_symb_str                       ;
   double          m_stops_level_in_price           ;
   
   //---------------------------------------------------------------
   // Administracao de ordens e seus resultados de processamento
   //---------------------------------------------------------------
   void        addOrdem(MqlTradeRequest& req, MqlTradeResult &res, ulong ordem=0);// adiciona requisicao e resultado de uma ordem
   TradeOrder* getOrdem(ulong ordem);                              // recupera ultima requisicao e resultado de uma ordem
   bool        permiteAlterarOrdem(ulong ordem, double newPrice, double newVol, string newComment); // valida se pode enviar pedido de alteracao de ordem
   bool        permiteCancelarOrdem(ulong ordem); // valida se pode enviar pedido de cancelamento de ordem
   //---------------------------------------------------------------

   bool   orderStatePendente     (const ENUM_ORDER_STATE order_state); // retorna true se o estado da ordem informado for pendente
   bool   orderTypeCompra        (const ENUM_ORDER_TYPE  order_type ); // retorna true se o tipo da ordem for compra
   bool   orderTypeCompraLimitada(const ENUM_ORDER_TYPE  order_type ); // retorna true se o tipo da ordem for compra limitada
   bool   orderTypeVendaLimitada (const ENUM_ORDER_TYPE  order_type ); // retorna true se o tipo da ordem for venda limitada

   double orderPrice (){ return OrderGetDouble(ORDER_PRICE_OPEN); } // retorna o preco de entrada da ordem atualmente posicionada
protected:

public:
   void osc_minion_trade();
   void setStopLoss( double stp ){ m_symb.NormalizePrice(stp)   ; m_stp = stp; m_stpV = -stp; }
   void setTakeProf( double tkp ){ m_tkp    = tkp; m_tkpV = -tkp; }
   void setMagic   ( ulong  mag ){ m_mmagic = mag               ; }
   void setVolLote ( double vol ){ m_volume = vol               ; } // tamanho do lote que serah usado nas operacoes;
   
   bool vender    (MqlTick &tick             ){ return enviarOrdemAMercado(tick.bid, ORDER_TYPE_SELL      ); }
   bool vender    (MqlTick &tick , string obs){ return enviarOrdemAMercado(tick.bid, ORDER_TYPE_SELL, obs ); }
   bool comprar   (MqlTick &tick             ){ return enviarOrdemAMercado(tick.ask, ORDER_TYPE_BUY       ); }
   bool comprar   (MqlTick &tick , string obs){ return enviarOrdemAMercado(tick.ask, ORDER_TYPE_BUY , obs ); }

   bool venderStop  (double val, string obs){ return enviarOrdemPendente (ORDER_TYPE_SELL_STOP , val, obs ); }
   bool comprarStop (double val, string obs){ return enviarOrdemPendente (ORDER_TYPE_BUY_STOP  , val, obs ); }
   bool venderLimit (double val, string obs){ return enviarOrdemPendente (ORDER_TYPE_SELL_LIMIT, val, obs ); }
   bool comprarLimit(double val, string obs){ return enviarOrdemPendente (ORDER_TYPE_BUY_LIMIT , val, obs ); }

// bool venderStop (int offset, string obs){ return enviarOrdemPendenteStop(ORDER_TYPE_SELL_STOP, offset, obs ); }
// bool comprarStop(int offset, string obs){ return enviarOrdemPendenteStop(ORDER_TYPE_BUY_STOP , offset, obs ); }
   void  fecharPosicao (string); // fecha posicoes abertas com o magic
   ulong fecharPosicaoCtaNetting (string symbol, string comentario); // fecha a posico aberta para o simbolo informado.
   void  fecharPosicaoVendida(string symbol, string comentario); //fecha posicoes vendidas abertas com o magic.
   void  fecharPosicaoComprada(string symbol, string comentario);//fecha posicoes compradas abertas com o magic.
   void  fecharQualquerPosicao (string); // fecha posicoes abertas ateh de magic diferentes
   void  trazerOrdensComComentarioNumerico2valorPresente(string symbol, int qtdTicksDeslocamento=0); // tras as ordens de fechamento a valor presente, visando fechar a posicao.
   bool  trazerOrdensFechamentoPosicaoPara(double novoValor);
   bool  alterarValorDeOrdensNumericasPara(string symbol,double novoValor, double valorPosicao);
    int  remanejarOrdensPendentes( int order_signal, double valNear, double valFar, double lag_);
  double findPrice(double price_, double lag_, int signal_);
   
   ulong manterOrdemLimitadaEntornoDe(string symbol, ENUM_ORDER_TYPE order_type, string comment, double value, double room, double vol); // Mantem uma ordem limitada em torno do valor informado, cancelando outras ordens em niveis de preco diferentes.
   ulong manterOrdemLimitadaNoRoom(ENUM_ORDER_TYPE order_type, string comment, double value, double room, double vol); // Mantem uma ordem limitada em torno do valor informado, e em direcao ao melhor bid/ask.
   
   bool cancelarOrdem                             (ulong  ticket                   );//cancela a ordem que tem o ticket informado no parametro.
   void cancelarOrdensDuplicadas                  (            ENUM_ORDER_TYPE tipo);//cancela ordens pendentes do tipo informado
   void cancelarOrdens                            (            ENUM_ORDER_TYPE tipo);//cancela ordens pendentes do tipo informado
   void cancelarOrdens                            (ulong ticketExcept=0            );//cancela ordens pendentes, exceto a do ticket informado.
   void cancelarOrdens                            (            ENUM_ORDER_TYPE tipo, string comment);
   void cancelarOrdens                            (               string comentario);//cancela ordens pendentes
   void cancelarOrdensComentadas                  (string symbol, string comentario);//cancela as ordens que tenham o comentario informado
   bool cancelarOrdensComentadasDeVenda           (string symbol, string comentario);//cancela as ordens que tenham o comentario informado e sejam de venda
   bool cancelarOrdensComentadasDeVenda           (string symbol, string comentario, double valor);//cancela as ordens de venda que tenham o comentario e valor informado;
   bool cancelarOrdensComentadasDeVendaMaioresQue (string symbol, string comentario, double valor);//cancela as ordens de venda que tenham o comentario e valor informado;
   bool cancelarOrdensComentadasDeCompra          (string symbol, string comentario              );//cancela as ordens que tenham o comentario informado e sejam de compra
   bool cancelarOrdensComentadasDeCompra          (string symbol, string comentario, double valor);//cancela as ordens de compra que tenham o comentario e valor informado;
   bool cancelarOrdensComentadasDeCompraMenoresQue(string symbol, string comentario, double valor);//cancela as ordens de compra que tenham o comentario e valor informado;
   void cancelarOrdensComComentarioNumerico       (string symbol                   );//cancela ordens cujo comentario eh um numero;
   void cancelarOrdensComComentarioNumerico       (string symbol, ENUM_ORDER_TYPE tipo );//cancela ordens cujo comentario eh um numero e o tipo eh igual ao especificado;
   void cancelarOrdensComVolumeAcimaDe            (ENUM_ORDER_TYPE order_type, double volume); // cancela ordens com volume maior que o informado   
   void cancelarOrdensExcetoComTxt                (string txtNaoCancelar, string comentario);
   void cancelarOrdensDeCompraMenoresQue          (double valor);
   void cancelarOrdensDeVendaMaioresQue           (double valor);
   
   void cancelarOrdensMaioresQue( ENUM_ORDER_TYPE type, double valor, bool igual_tambem=true);
   void cancelarOrdensMenoresQue( ENUM_ORDER_TYPE type, double valor, bool igual_tambem=true);
   
   void cancelarOrdens                            (string symbol, ENUM_ORDER_TYPE tipo, string comentario, ulong ticketExcept=0);//cancela ordens pendentes que atendem aos parametros, exceto o ticket informado em ticketExcept. 

   void cancelarOrdensDoTipo       (ENUM_ORDER_TYPE tipo              ); // cancela todas as ordens do tipo informado
   void cancelarOrdensPorTipoEvalor(ENUM_ORDER_TYPE tipo, double valor); // cancela todas as ordens do tipo informado

    void cancelarMenorOrdemDoTipo(ENUM_ORDER_TYPE order_type);
    void cancelarMaiorOrdemDoTipo(ENUM_ORDER_TYPE order_type);

   ulong  cancelarMaiorOrdemDeVendaComComentarioNumerico ();
   ulong  cancelarMenorOrdemDeCompraComComentarioNumerico();
   

   int contarOrdensLimitadasDeCompra(string symbol, string comment);
   int contarOrdensLimitadasDeVenda (string symbol, string comment);


   bool enviarOrdemAMercado(double val, ENUM_ORDER_TYPE tipo);
   bool enviarOrdemAMercado(double val, ENUM_ORDER_TYPE tipo, string obs);

   bool enviarOrdemPendente      (ENUM_ORDER_TYPE tipo, double  val, string  obs);
   bool enviarOrdemPendente      (ENUM_ORDER_TYPE tipo, double  val, double  volume, string obs, int tentativas=1);
   bool enviarOrdemPendente      (ENUM_ORDER_TYPE tipo, double  val, double  volume, string obs, ulong &tkt); // devolve o ticket da ordem   
   bool enviarOrdemPendenteRajada(ENUM_ORDER_TYPE tipo, double _val, double _volume, string obs, double passoVal, double incremVolume, double incremVal, double qtdOrdens, bool stop=false, double porcStop=0, double valSaidaPosicao=0, double passoValAtehSaidaPosicao=0 );

   void preencherOrdensLimitadasDeCompraAbaixo(double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize);
   void preencherOrdensLimitadasDeVendaAcima  (double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize);

   // a versao 2 destas funcoes inicia o controle mais longe preco atual.
   void preencherOrdensLimitadasDeCompraAbaixoComLag(double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize, int lag);
   void preencherOrdensLimitadasDeVendaAcimaComLag  (double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize, int lag);

   // a versao 2 destas funcoes inicia o controle mais proximo preco atual.
   void preencherOrdensLimitadasDeCompraAbaixoComLag2(double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize, int lag);
   void preencherOrdensLimitadasDeVendaAcimaComLag2  (double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize, int lag);

   
   bool alterarOrdem(ENUM_ORDER_TYPE tipo, double price);
   bool alterarOrdem(                      double price, double volume);
   bool alterarOrdem(ENUM_ORDER_TYPE tipo, double price, double volume, ulong order_ticket=0, string newComment="", int tentativas=1);
   bool alterarPrecoOrdem(double price);
   void colocarStopEmTodasAsOrdens(double stp);
   bool colocarStopNaOrdem(ulong ticket, double stp);


   double getPositionVolume(){ return m_position.Volume();} //Volume da posicao. estouComprado ou estouVendido devem ter sido chamados antes.
   
   double getPrice(){ return m_treq.price; } // valor do preco da ultima ordem ou da ultima posicao.
   
   bool   estouVendido(string symbol);
   bool   estouVendido(){return estouVendido(m_symb_str);}
   
   bool   estouComprado(string symbol)                 ;
   bool   estouComprado(){return estouComprado(m_symb_str);}
   
   bool   tenhoOrdemLimitada(double value, ENUM_ORDER_TYPE type);
   bool   tenhoOrdemLimitadaDeCompra(double value, string symbol, string comment);
   bool   tenhoOrdemLimitadaDeCompra(double value, string symbol, string comment, double volume, bool cancelar, double tolerancia, string newComment="");
   bool   tenhoOrdemLimitadaDeCompra(double value, string comment){ return tenhoOrdemLimitadaDeCompra(value, m_symb_str, comment); }
   
   bool   tenhoOrdemLimitadaDeVenda (double value, string symbol, string comment                              );
   bool   tenhoOrdemLimitadaDeVenda (double value, string symbol, string comment, double volume, bool cancelar, double tolerancia, string newComment="");
   bool   tenhoOrdemLimitadaDeVenda (double value, string comment){return tenhoOrdemLimitadaDeVenda (value, m_symb_str, comment);}

   double tenhoOrdemLimitadaDeCompraMaiorQue(double value, string symbol, string comment, double volume, ulong& ticket, bool aceitarIgual=false);
   double tenhoOrdemLimitadaDeVendaMenorQue (double value, string symbol, string comment, double volume, ulong& ticket, bool aceitarIgual=false);

   double tenhoOrdemLimitadaDeCompraMaiorOuIgual(double value);
   double tenhoOrdemLimitadaDeVendaMenorOuIgual(double value);

   bool   tenhoOrdenComComentarioNumerico(double price, ENUM_ORDER_TYPE tipo);

   double buscarMaiorOrdemLimitadaDeVendaAcimaDe  (double value, string symbol, string comment, double volume, ulong& ticket);
   double buscarMenorOrdemLimitadaDeCompraAbaixoDe(double value, string symbol, string comment, double volume, ulong& ticket);

   double buscarMenorOrdemLimitadaDeVenda         (              string symbol, string comment, double volume, ulong& ticket);
   double buscarMaiorOrdemLimitadaDeCompra        (              string symbol, string comment, double volume, ulong& ticket);

   double buscarMenorOrdemLimitadaDeVenda         (             ulong& ticket);
   double buscarMaiorOrdemLimitadaDeCompra        (             ulong& ticket);

   double buscarMaiorOrdemLimitadaDeVendaComComentarioNumerico (ulong& ticket);
   double buscarMenorOrdemLimitadaDeCompraComComentarioNumerico(ulong& ticket);

   bool   alterarOrdemLimitadaComValorDiferenteDe(double value, string symbol, double volume, string comment, string newComment="");
   
   double getVolUltOrdemVerificada(){ return m_order.VolumeCurrent(); }
   double getValUltOrdemVerificada(){ return m_order.PriceOpen();     }
   

   bool   tenhoOrdemPendente(double price);
   ulong  tenhoOrdemPendente(double price, ENUM_ORDER_TYPE tipo, ulong ticketOut);// busca ordem com o mesmo preco, tipo e ticket diferente.
   bool   tenhoOrdemPendenteComComentario( string symbol, string comment);// verifica se tem ordem pendente de execucao para o simbolo informado com o comentario informado

   double getVolOrdensPendentesDeVenda (string symbol);   
   double getVolOrdensPendentesDeVenda ();   
   double getVolOrdensPendentesDeCompra(string symbol);   
   double getVolOrdensPendentesDeCompra();   
   
   int    contarOrdensPendentes(ENUM_ORDER_TYPE order_type  );
   int    contarOrdensPendentes(int             order_signal);
   
   void   setAsync(bool newMode){ m_async = newMode;}
   bool   getAsync()            { return m_async;}
   
   void   saveAsync()           { m_async_salvo = m_async;}
   void   restoreAsync()        { m_async = m_async_salvo;}

   void osc_minion_trade::setSymbol(string symb_str);
   string stateOrderToString(){ return EnumToString( (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) ); }
};

void osc_minion_trade::osc_minion_trade(){
   
   setStopLoss(40)  ;
   setTakeProf(15)  ;
   m_mmagic  = 20191004; // transforme em parametro
   m_desvio  = 0.0     ; // transforme em parametro
   
   setSymbol(_Symbol);
   //m_digitos = _Digits ;
   //m_point   = _Point  ;
   //m_symb.Name(_Symbol);
       
   Print(":-| osc_minion_trade:" , __FUNCTION__,": DIGITOS:",m_digitos," POINTS: ",m_point ); 
}

void osc_minion_trade::setSymbol(string symb_str){
    m_symb_str = symb_str;
    m_symb.Name(symb_str);
    m_point   = m_symb.Point();
    m_digitos = m_symb.Digits();
    m_stops_level_in_price = m_symb.StopsLevel()*m_symb.Point();
}

bool osc_minion_trade::enviarOrdemAMercado(double val, ENUM_ORDER_TYPE tipo            ){ return enviarOrdemAMercado(val,tipo,""); }
bool osc_minion_trade::enviarOrdemAMercado(double val, ENUM_ORDER_TYPE tipo, string obs){
   ZeroMemory(m_treq);
   ZeroMemory(m_tres);
   
   m_symb.RefreshRates();
   double price   = val;
   //double point   = _Point;
   double stp     = 0; 
   double tkp     = 0;
   m_treq.comment = obs;

   if(tipo == ORDER_TYPE_SELL) { price=m_symb.Bid(); stp = m_stpV; tkp = m_tkpV; }
   if(tipo == ORDER_TYPE_BUY ) { price=m_symb.Ask(); stp = m_stp ; tkp = m_tkp ; }

   m_treq.action       = TRADE_ACTION_DEAL;                          // immediate order execution
   m_treq.price                   = m_symb.NormalizePrice(price);                // latest ask price
   if( m_stp != 0.0 ){ m_treq.sl  = m_symb.NormalizePrice(price - stp); }      // Stop Loss
   if( m_tkp != 0.0 ){ m_treq.tp  = m_symb.NormalizePrice(price + tkp); }      // Take Profit
   m_treq.symbol       = m_symb_str;                                    // currency pair
   m_treq.volume       = m_volume;                                   // number of lots to trade
   m_treq.magic        = m_mmagic;                                   // Order Magic Number
   m_treq.type         = tipo;                                       // Compra, venda, etc
 //m_treq.type_filling = ORDER_FILLING_FOK;                          // Order execution type
   m_treq.type_filling = ORDER_FILLING_RETURN;                       // Order execution type
   m_treq.deviation    = m_desvio;                                   // Deviation from current price in points

   if( m_async ){
       if ( OrderSendAsync(m_treq,m_tres) ){ return true; }
   }else{
       if ( OrderSend     (m_treq,m_tres) ){ return true; }
   }
   
   Alert(":-( ",__FUNCTION__,"(",val, ",",tipo, ",",obs, ") ERRO SOLIC ORD ",GetLastError(),":",m_tres.retcode,":",m_tres.comment);
   Print(":-( ",__FUNCTION__,"(",val, ",",tipo, ",",obs, ") retcode=",m_tres.retcode," deal=",m_tres.deal," order=",m_tres.order," comment=",m_tres.comment," EA=", obs);

   //if( m_tres.retcode == TRADE_RETCODE_TOO_MANY_REQUESTS ){
       Print(":-( ",__FUNCTION__,"(",val,",",tipo,",", obs,") Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms..."  );
       Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
   //}
   return false;
}

bool osc_minion_trade::enviarOrdemPendente(ENUM_ORDER_TYPE tipo, double val,                string obs){return enviarOrdemPendente(tipo,val,m_volume,obs);}

bool osc_minion_trade::enviarOrdemPendente(ENUM_ORDER_TYPE tipo, double val, double volume, string obs, ulong &tkt){
     if( enviarOrdemPendente(tipo,val,volume,obs) ){ tkt = m_tres.order; return true; }
     return false;
}

bool osc_minion_trade::enviarOrdemPendente(ENUM_ORDER_TYPE tipo, double val, double volume, string obs, int tentativas=1){

   ZeroMemory(m_treq);
   ZeroMemory(m_tres);
   m_symb.RefreshRates();
   
   val = m_symb.NormalizePrice(val);
   double price   = val;
   double stp     = 0; 
   double tkp     = 0;

   if( tipo==ORDER_TYPE_BUY_LIMIT ){
       if( val > m_symb.Ask() ){
           price = m_symb.Bid();
         //price = m_symb.Ask() - m_symb.TickSize(); // comentado em 25/03/2021 para tentar corrigir ao negociar CFDs americanas
        // Alert(":-( ",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ") BUY_LIM PRECO(",val,") > QUE ASK(",price,"). CORRIGIDO PARA ASK. VERIFIQUE!");
        // Print(":-( ",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ") COMPRA LIMITADA A PRECO(",val,") MAIOR QUE O ASK(",price,"). CORRIGIDO PARA ASK. VERIFIQUE!");
       }
       if(m_stops_level_in_price > 0 && price > (m_symb.Ask() - m_stops_level_in_price) ){
            price = m_symb.Ask() - m_stops_level_in_price; 
       }
   }
   if( tipo==ORDER_TYPE_SELL_LIMIT ){
       if( val < m_symb.Bid() ){
           price = m_symb.Ask();
        // price = m_symb.Bid() + m_symb.TickSize();
        // Alert(":-( ",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ") SEL_LIM PRECO(",val,") < QUE BID(",price,"). CORRIGIDO PARA BID. VERIFIQUE!");           
        // Print(":-( ",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ") VENDA LIMITADA A PRECO(",val,") MENOR QUE O BID(",price,"). CORRIGIDO PARA BID. VERIFIQUE!");           
       }
       if(m_stops_level_in_price > 0 && price < (m_symb.Bid() + m_stops_level_in_price) ){ 
            price = m_symb.Bid() + m_stops_level_in_price; 
       }
   }

   if      (tipo==ORDER_TYPE_BUY_STOP  || tipo==ORDER_TYPE_BUY_LIMIT  ){
   
      //if( tipo==ORDER_TYPE_BUY_LIMIT ){
      //    //price    = SymbolInfoDouble(_Symbol,SYMBOL_ASK)+offset*point; // preço de abertura da ordem 
      //    double bid = SymbolInfoDouble(_Symbol,SYMBOL_ASK)-m_stops_level_in_price;
      //    if( price > bid){
      //        price = bid;
      //        Print(":-| ",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ") preco maior que stopLevel! Alterado para ",price);
      //    }
      //}
      stp          = m_stp ; 
      tkp          = m_tkp ;
   }else if(tipo==ORDER_TYPE_SELL_STOP || tipo==ORDER_TYPE_SELL_LIMIT ){
      //if( tipo==ORDER_TYPE_SELL_LIMIT ){
      //    //price    = SymbolInfoDouble(_Symbol,SYMBOL_BID)-offset*point; // preço para abertura 
      //    double ask = SymbolInfoDouble(_Symbol,SYMBOL_BID)+m_stops_level_in_price;
      //    if( price < ask){
      //        price = ask;
      //        Print(":-| ",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ") preco menor que stopLevel! Alterado para ",price);
      //    }
      //}
      stp          = m_stpV; 
      tkp          = m_tkpV;
   }

   m_treq.action       = TRADE_ACTION_PENDING;                       // execucao pendente
   m_treq.price                  = m_symb.NormalizePrice(price      );       // preco futuro recebido no pedido de negociacao
   if( m_stp != 0.0 ){ m_treq.sl = m_symb.NormalizePrice(price - stp); }     // Stop Loss
   if( m_tkp != 0.0 ){ m_treq.tp = m_symb.NormalizePrice(price + tkp); }     // Take Profit
   m_treq.symbol       = m_symb_str;                                    // currency pair
   m_treq.volume       = volume;                                     // number of lots to trade
   m_treq.magic        = m_mmagic;                                   // Order Magic Number
   m_treq.type         = tipo;                                       // Compra, venda, etc
 //m_treq.type_filling = ORDER_FILLING_FOK;                          // Order execution type
   m_treq.type_filling = ORDER_FILLING_RETURN;                       // Order execution type
   m_treq.deviation    = m_desvio;                                   // Deviation from current price in points
   m_treq.comment      = obs;
   m_treq.type_time    = ORDER_TIME_DAY;
 //m_treq.expiration   = TimeLocal();

   if( tipo==ORDER_TYPE_BUY_STOP_LIMIT || tipo==ORDER_TYPE_SELL_STOP_LIMIT ){
       m_treq.stoplimit = m_treq.price;
       if(tipo==ORDER_TYPE_BUY_STOP_LIMIT){
           m_treq.price = m_treq.stoplimit + m_symb.TickSize();
       }else{
           m_treq.price = m_treq.stoplimit - m_symb.TickSize();
       }       
   }

   //Print(":-| osc_minion_trade: Enviando ordem:", m_treq.price);   
   if( m_async ){
      if ( OrderSendAsync(m_treq,m_tres) ){ return true;  }
   }else{
      if ( OrderSend     (m_treq,m_tres) ){ 
         if( OrderSelect(m_tres.order) ){
             Print(":-| ",m_symb_str,":",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ",", tentativas,") retcode=",m_tres.retcode," deal=",m_tres.deal," order=",m_tres.order," msgerro=",m_tres.comment," commentOrder=", obs, " STATE:", EnumToString( (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) ) );
         }
         return true;  
      }
   }
   
   if( m_tres.retcode == TRADE_RETCODE_INVALID_PRICE && tentativas < MAX_TENTATIVAS_CORRECAO_INVALID_PRICE ){
        Print(":-( ",m_symb_str,":",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ",", tentativas,") retcode=",m_tres.retcode," deal=",m_tres.deal," order=",m_tres.order," msgerro=",m_tres.comment," commentOrder=", obs);
        return enviarOrdemPendente(tipo, m_treq.price, m_treq.volume, m_treq.comment, ++tentativas);
   }
   Alert(":-( ",m_symb_str,":",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ",", tentativas,") ERRO SOLIC ORD ",GetLastError(),":",m_tres.retcode,":",m_tres.comment);
   Print(":-( ",m_symb_str,":",__FUNCTION__,"(",EnumToString(tipo), ",",val,",",volume, ",",obs, ",", tentativas,") retcode=",m_tres.retcode," deal=",m_tres.deal," order=",m_tres.order," msgerro=",m_tres.comment," commentOrder=", obs);

   //if( m_tres.retcode == TRADE_RETCODE_TOO_MANY_REQUESTS ){
       // duas linhas abaixo comentadas em 25/03/2021.
       //Print(":-( ",m_symb_str,":",__FUNCTION__,"(",EnumToString(tipo),",",val,",", volume,",", obs,")"," :-( Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms..."  );
       //Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
   //}
   return false;
}

//------------------------------------------------------------------------------------------------------------
// Monta rajada de ordens usando o valor, volume, passo do valor, passo do volume e quantidade informados.
// ENUM_ORDER_TYPE tipo,
// double _val       , valor da primeira ordem
// double _volume    , volume da primeira ordem
// string obs        , comentario a ser usado em todas as ordens da rajada 
// double passoVal   , valor a ser acrescentado ao preco inicial a cada iteracao para definir os niveis de preco
//                     da rajada. Se quiser incrementar o preco pra baixo, passe um numero negativo neste parametro. 
// double incremVolume, incremento do volume a cada passo. Ex: se quiser dobrar a quantidade de ordens a cada
//                      nivel de preco, informe 2 no passo.  
// double tamanhoRajada, quantidade de ordens na rajada.
// bool   stop         , se true cria uma ordem de saida contraria as ordens de entrada apos a ultima ordem da rajada.
// double porcStop     , porcentagem aplicada ao passo da ultima rajada para obter o valor a decrementar ao passo do preco stop. 
//                       Se quiser incrementar o passo neste ponto coloque um valor negativo.
//------------------------------------------------------------------------------------------------------------
bool osc_minion_trade::enviarOrdemPendenteRajada(ENUM_ORDER_TYPE tipo         , 
                                                 double         _val          ,// valor primeira ordem
                                                 double         _volume       ,// volume da primeira ordem
                                                 string          obs          ,// cometario das ordens
                                                 double          passoVal     ,// distancia entre as ordens
                                                 double          incremVolume ,// multiplica pelo volume a cada ordem
                                                 double          incremVal    ,// multiplica pela distancia a cada ordem
                                                 double          tamanhoRajada,// qtd ordens
                                                 bool            stop=false   ,// se true, a ultima ordem serah o stop loss
                                                 double          porcStop=0   , //
                                                 double          valSaidaPosicao         =0,//
                                                 double          passoValAtehSaidaPosicao=0 
                                                 ){

    double volume   = _volume;
    double val      = _val;
    double volLocal = volume;
    double volTot   = 1;
   
    val = m_symb.NormalizePrice(val);

    while( tamanhoRajada > 0 ){
        volTot += volume;
        if( !enviarOrdemPendente(tipo, val, volume, obs) ){ return false; }
      
        // volume da ordem
        volLocal = volLocal * incremVolume;
        volume   = round(volLocal);        

        // valor da ordem
        passoVal  = passoVal*incremVal;
        val       = m_symb.NormalizePrice(val + passoVal);
      
        // controle do laco
        tamanhoRajada--;
    }
   
    // testando a colocacao do stoploss...
    if( stop ){
        if( tipo == ORDER_TYPE_BUY_LIMIT ){
            if( !enviarOrdemPendente(ORDER_TYPE_SELL_STOP_LIMIT, val-passoVal*porcStop, volTot, obs) ){ return false; }        
        }else{
            if( !enviarOrdemPendente(ORDER_TYPE_BUY_STOP_LIMIT , val-passoVal*porcStop, volTot, obs) ){ return false; }
        }
    }
    
    // testando colocacao de ordens a favor da posicao...
    if(valSaidaPosicao > 0 && passoValAtehSaidaPosicao != 0){
    
        val = _val;
    
        if( tipo == ORDER_TYPE_BUY_LIMIT ){
        
            while(val < (valSaidaPosicao-passoValAtehSaidaPosicao*2) ){
                
                val = val+passoValAtehSaidaPosicao;
                
                if( val < valSaidaPosicao ){ 
                    enviarOrdemPendente(ORDER_TYPE_BUY_STOP_LIMIT , val, _volume, obs);
                }
            }
        }else{

            while(val > (valSaidaPosicao+passoValAtehSaidaPosicao*2) ){

                val = val-passoValAtehSaidaPosicao;
                
                if( val > valSaidaPosicao ){ 
                    enviarOrdemPendente(ORDER_TYPE_SELL_STOP_LIMIT, val, _volume, obs);
                }
            }
        }
    }
    
    return true;
}


//bool osc_minion_trade::alterarPrecoOrdem(int ticket, double price){ 
//   return alterarOrdem( int ticket, price); 
//}


// altera preco da ordem pendente...
bool osc_minion_trade::alterarPrecoOrdem(double price){ return alterarOrdem(m_treq.type, price); }


// altera ordem pendente...
bool osc_minion_trade::alterarOrdem(                      double price, double volume ){return alterarOrdem(m_treq.type, price,   volume);}
bool osc_minion_trade::alterarOrdem(ENUM_ORDER_TYPE tipo, double price                ){return alterarOrdem(tipo       , price, m_volume);}
bool osc_minion_trade::alterarOrdem(ENUM_ORDER_TYPE tipo, double price, double volume, ulong order_ticket=0,string newComment="", int tentativas=1 ){

   ZeroMemory(m_treq);
   ZeroMemory(m_tres);

   m_symb.RefreshRates();
   
   //----------------------------------------------------------------------------------------------------------
   // 25/03/2021 trazemos a mesma validacao feita em cadastrarOrdem para minimizar a ocorrencia de invalidPrice
   //----------------------------------------------------------------------------------------------------------
   if( tipo==ORDER_TYPE_BUY_LIMIT ){
       if( price > m_symb.Ask() ){
           price = m_symb.Bid();
       }
       if(m_stops_level_in_price > 0 && price > (m_symb.Ask() - m_stops_level_in_price) ){
            price = m_symb.Ask() - m_stops_level_in_price; 
       }
   }
   if( tipo==ORDER_TYPE_SELL_LIMIT ){
       if( price < m_symb.Bid() ){
           price = m_symb.Ask();
       }
       if(m_stops_level_in_price > 0 && price < (m_symb.Bid() + m_stops_level_in_price) ){ 
            price = m_symb.Bid() + m_stops_level_in_price; 
       }
   }
   //----------------------------------------------------------------------------------------------------------

   price = m_symb.NormalizePrice(price);
   if(order_ticket==0) order_ticket=OrderGetTicket(0);
   
   m_treq.action  = TRADE_ACTION_MODIFY; // alterar ordem 
   m_treq.type    = tipo;
   m_treq.volume  = volume;              // number of lots to trade
   m_treq.order   = order_ticket;        // 
   m_treq.price   = price;               // preco futuro recebido no pedido de negociacao
   
   // valida se pode enviar pedido de alteracao de ordem
   if( !permiteAlterarOrdem(m_treq.order,price,volume,newComment) ) return false;

   // configurando stops...
   double stp = 0; 
   double tkp = 0;
   if      ( m_treq.type==ORDER_TYPE_BUY_STOP  || m_treq.type==ORDER_TYPE_BUY_LIMIT  ){
      stp  = m_stp ; 
      tkp  = m_tkp ;
   }else if( m_treq.type==ORDER_TYPE_SELL_STOP || m_treq.type==ORDER_TYPE_SELL_LIMIT ){
      stp  = m_stpV; 
      tkp  = m_tkpV;
   }
   if( m_stp != 0.0 ){ m_treq.sl           = m_symb.NormalizePrice(price - stp); }      // Stop Loss
   if( m_tkp != 0.0 ){ m_treq.tp           = m_symb.NormalizePrice(price + tkp); }      // Take Profit


   m_treq.symbol       = m_symb_str;                                    // currency pair
   m_treq.magic        = m_mmagic;                                   // Order Magic Number
 //m_treq.type_filling = ORDER_FILLING_FOK;                          // Order execution type
   m_treq.type_filling = ORDER_FILLING_RETURN;                       // Order execution type
   m_treq.deviation    = m_desvio;                                   // Deviation from current price in points
   m_treq.type_time    = ORDER_TIME_DAY;
//   m_treq.comment      = obs;
   if( newComment != "" ) m_treq.comment = newComment;
   


   // enviando a ordem de alteracao do preco...
   
   // 27/12/2019: alteracao de ordem passa a ser assincrona.
   //if( m_async ){   
       if ( OrderSendAsync(m_treq,m_tres) ){ 
          addOrdem(m_treq,m_tres);
          return true; 
       }
       addOrdem(m_treq,m_tres);
   //}else{
   //    if ( OrderSend     (m_treq,m_tres) ){ return true; }
   //}
   
   //Print(":-( ",__FUNCTION__,"(",tipo, ",",price,",",volume, ",",order_ticket,",",newComment,") retcode=",m_tres.retcode," lastError=",GetLastError()," order=",m_treq.order," comment=",m_tres.comment);

   if( m_tres.retcode == TRADE_RETCODE_INVALID_PRICE && tentativas < MAX_TENTATIVAS_CORRECAO_INVALID_PRICE ){
        Print(":-( ",m_symb_str,":",__FUNCTION__,"(",EnumToString(tipo), ",",price,",",volume, ",",order_ticket, ",", newComment,",",tentativas,") retcode=",m_tres.retcode," deal=",m_tres.deal," order=",m_tres.order," msgerro=",m_tres.comment," commentOrder=", newComment);
        return alterarOrdem(tipo, price, volume, order_ticket,newComment="", ++tentativas );
   }
   Alert(":-( ",m_symb_str,":",__FUNCTION__,"(",EnumToString(tipo), ",",price,",",volume, ",",order_ticket, ",", newComment,",",tentativas,") retcode=",m_tres.retcode," deal=",m_tres.deal," order=",m_tres.order," msgerro=",m_tres.comment," commentOrder=", newComment);
   Print(":-( ",m_symb_str,":",__FUNCTION__,"(",EnumToString(tipo), ",",price,",",volume, ",",order_ticket, ",", newComment,",",tentativas,") retcode=",m_tres.retcode," deal=",m_tres.deal," order=",m_tres.order," msgerro=",m_tres.comment," commentOrder=", newComment);
   
   return false;
}

//+-----------------------------------------------------------+
//| Cancela a ordem do ticket informado                       |
//+-----------------------------------------------------------+
bool osc_minion_trade::cancelarOrdem(ulong ticket){

    if( !permiteCancelarOrdem(ticket) ) return false;

    if( OrderSelect(ticket) ){
        MqlTradeResult  result ={}; 
        MqlTradeRequest request={}; 
    
        request.order   = ticket; 
        request.action  = TRADE_ACTION_REMOVE;
        
        if(!OrderSendAsync(request,result)){
            addOrdem(request,result,ticket);
            Print(":-( ",__FUNCTION__,"(",ticket,") REMOCAO ERRO OrderSendAsync ",GetLastError(),":",result.retcode,":",result.comment);
            return false;
        }
        
        addOrdem(request,result,ticket);
        return true;
    }
    
    Print(":-| ", __FUNCTION__,"(",ticket,") ORDEM NAO ENCONTRADA PELO MT5:GetLastError():", GetLastError() ); 
    return false;
}


/*
//+-----------------------------------------------------------+
//| Cancela a ordem do ticket informado                       |
//+-----------------------------------------------------------+
bool osc_minion_trade::cancelarOrdem(ulong ticket) {

   if( OrderSelect(ticket) ){
    
          MqlTradeResult  result ={}; 
          MqlTradeRequest request={}; 
          
          request.order   = ticket; 
          request.action  = TRADE_ACTION_REMOVE; 

          //PrintFormat("ENVIANDO REMOCAO DA ORDEM COM TICKET #%I64d :",ticket);
          // 27/12/2019: cancelamento de ordens passa a ser assincrono.
          //if( m_async ){   
              Print(":-| ",__FUNCTION__ ,"(#",ticket,") :-| Canc #",ticket," asyn");   
              if(!OrderSendAsync(request,result)){
                 Print(__FUNCTION__,"(#", ticket,") :-( REMOCAO ERRO OrderSendAsync=",GetLastError(), ":", result.retcode,":",result.comment, " order=", ticket);  // se não for possível enviar o pedido, exibir um código de erro
                 
                 //if( result.retcode == TRADE_RETCODE_TOO_MANY_REQUESTS ){
                     Print(__FUNCTION__,"(",ticket,")"," :-( Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms..."  );
                     Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
                 //}
                 return false;
              }
          //}else{
          //    if(!OrderSend(request,result)){
          //       PrintFormat(":-( osc_minion_trade: REMOCAO ERRO OrderSend %d :",GetLastError());  // se não for possível enviar o pedido, exibir um código de erro
          //       PrintFormat(":-( osc_minion_trade: REMOCAO ERRO retcode=%u  deal=%I64u  order=%I64u :", result.retcode,result.deal,result.order);
          //       return false;
          //    }
          //}   
          return true;
   }
   Print(__FUNCTION__,"(",ticket,") :-( ERRO REMOCAO ORDEM: NAO ENCONTRADA :GetLastError():", GetLastError() ); return false;
}
*/



//+---------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada de compra no valor especificado|
//+---------------------------------------------------------------------+
bool osc_minion_trade::tenhoOrdemLimitadaDeCompra(double value, string symbol,string comment){
   
   ulong order_ticket; 
   //ENUM_ORDER_STATE order_state;

//--- passando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          //m_order.SelectByIndex(i); // selecionando a ordem para posterior alteracao se necessario...

          //order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
          if(  OrderGetString (ORDER_SYMBOL    ) == symbol                &&
               OrderGetDouble (ORDER_PRICE_OPEN) == value                 && 
               OrderGetInteger(ORDER_TYPE      ) == ORDER_TYPE_BUY_LIMIT  &&
               orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
               //order_state                       != ORDER_STATE_FILLED    && // buscamos ordens pendentes
               //order_state                       != ORDER_STATE_REJECTED  &&
               //order_state                       != ORDER_STATE_CANCELED  &&
               //order_state                       != ORDER_STATE_EXPIRED     
               ){
               return true;
          }
      }
   }
   return false;
}

//+--------------------------------------------------------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada no valor e tipo especificados, e simbolo configurado previamente na instancia.|
//+--------------------------------------------------------------------------------------------------------------------+
bool osc_minion_trade::tenhoOrdemLimitada(double value, ENUM_ORDER_TYPE type){
   
    ulong order_ticket;
    string texto = __FUNCTION__;
    StringConcatenate(texto, " Buscando ordem ", m_symb_str," ", EnumToString(type), " valor ", value, " ...");
    //Print(texto,":");

//--- passando por todas as ordens pendentes
    for(int i=OrdersTotal()-1; i>=0; i--){

        if( (order_ticket = OrderGetTicket(i) )>0 ){

            StringConcatenate(texto,
              "\nAnalisando ", OrderGetString (ORDER_SYMBOL), 
              " preco:", OrderGetDouble (ORDER_PRICE_OPEN),
              " type:", EnumToString( (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) ),
              " state:", EnumToString( (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) ),
              " pend:", orderStatePendente( (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) ) );
            
            if(  OrderGetString (ORDER_SYMBOL    ) == m_symb_str            &&
                 OrderGetDouble (ORDER_PRICE_OPEN) == value                 &&
(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE      ) == type                  &&
                 orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))   ){
                 Print(texto, "\nAchei.");
                 return true;
            }
        }
    }
    Print(texto, "\nNao encontrei.");
    return false;
}

bool osc_minion_trade::orderStatePendente(const ENUM_ORDER_STATE order_state){
    return (    order_state == ORDER_STATE_PLACED 
             || order_state == ORDER_STATE_STARTED
             || order_state == ORDER_STATE_REQUEST_ADD
             || order_state == ORDER_STATE_REQUEST_MODIFY
             || order_state == ORDER_STATE_REQUEST_CANCEL
             || order_state == ORDER_STATE_PARTIAL       
             );
}

// retorna true se o tipo da ordem for compra
bool osc_minion_trade::orderTypeCompra(const ENUM_ORDER_TYPE order_type){
	return (   order_type==ORDER_TYPE_BUY_LIMIT
			|| order_type==ORDER_TYPE_BUY
			|| order_type==ORDER_TYPE_BUY_STOP
			|| order_type==ORDER_TYPE_BUY_STOP_LIMIT
			);
}

bool osc_minion_trade::orderTypeCompraLimitada(const ENUM_ORDER_TYPE order_type){ return order_type==ORDER_TYPE_BUY_LIMIT ; }
bool osc_minion_trade::orderTypeVendaLimitada (const ENUM_ORDER_TYPE order_type){ return order_type==ORDER_TYPE_SELL_LIMIT; }

//+---------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada de venda no valor especificado |
//+---------------------------------------------------------------------+
bool osc_minion_trade::tenhoOrdemLimitadaDeVenda(double value, string symbol, string comment){
   
   ulong order_ticket;

//--- passaANDO por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 
          //m_order.SelectByIndex(i); // selecionando a ordem para posterior alteracao se necessario...
          if(  OrderGetString (ORDER_SYMBOL    ) == symbol                &&
               OrderGetDouble (ORDER_PRICE_OPEN) == value                 && 
               OrderGetInteger(ORDER_TYPE      ) == ORDER_TYPE_SELL_LIMIT &&
          orderStatePendente( (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) )
               //order_state                       != ORDER_STATE_FILLED    && // buscamos ordens pendentes
               //order_state                       != ORDER_STATE_REJECTED  &&
               //order_state                       != ORDER_STATE_CANCELED  &&
               //order_state                       != ORDER_STATE_EXPIRED    
               ){

               return true;
          }
      }
      // nao deveria chegar aqui se todas as ordens sao do comentario...
      //m_order.SelectByIndex(i);
      //Print( ":-( osc_minion_trade: "    ,m_order.Comment()         ,
      //       " Ticket:"        ,m_order.Ticket()          ,
      //       ":"               ,m_order.Symbol()          ,
      //       " Tipo:"          ,m_order.TypeDescription() , 
      //       " State:"         ,m_order.StateDescription(),
      //       " PriceOpen:"     ,m_order.PriceOpen()," value:",value, " igual?=",(m_order.PriceOpen()==value),OrderGetDouble (ORDER_PRICE_OPEN) == value, 
      //       " PriceCurrent:"  ,m_order.PriceCurrent(),
      //       " PriceStopLimit:",m_order.PriceStopLimit() );      
   }
   return false;
}

//+----------------------------------------------------------------------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada de venda no valor e volume especificados. Altera para o valor e volume especificados        |
//| caso encontre a ordem com outro valor/volume, mesmo comentario (comentario fazendo parte da ordem encontrada).                   |
//+----------------------------------------------------------------------------------------------------------------------------------+
bool osc_minion_trade::tenhoOrdemLimitadaDeVenda(double value, string symbol, string comment, double volume, bool alterar, double tolerancia, string newComment=""){
   
   ulong order_ticket = 0    ;
   double price_open;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      //m_order.SelectByIndex(i);
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL  ) == symbol                &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1            &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_SELL_LIMIT &&
          orderStatePendente( (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) )
               //order_state                     == ORDER_STATE_PLACED     
                                                                         ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN);
               if( price_open                           >= value-tolerancia && 
                   price_open                           <= value+tolerancia &&
                   OrderGetDouble(ORDER_VOLUME_CURRENT) == volume            ){
                   return true; // colcoado aqui em 04/02/2020 para que nao siga verificando todas as ordens pendentes.
               }else{
                   //<TODO:> se tiver mais de uma ordem, pode ser que altere todas nas chamadas subsequentes.
                   // como estah sendo usado para uma ordem, vem funcionando.
                   // corrija assim que possivel.
                   if( alterar ){
                       Print(":-| ",__FUNCTION__ ,"(",value,",",symbol,",",comment,",",volume,",",alterar,",",tolerancia,") :-| Alt #",order_ticket,
                                                                                                                               " OldP=",price_open,
                                                                                                                               " NewP=",value," asyn");   
                       //if( !cancelarOrdem(order_ticket) ) tenhoOrdem=true;
                       alterarOrdem( (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE), value, volume, order_ticket, newComment);
                       return true; // colcoado aqui em 04/02/2020 para que nao siga verificando todas as ordens pendentes.
                   }
               }
          }
      }
   }
   return false;
}


//+--------------------------------------------------------------------------------------------+
//| Mantem uma sequencia de ordens limitadas de venda acima do valor informado.                |
//+--------------------------------------------------------------------------------------------+
void osc_minion_trade::preencherOrdensLimitadasDeVendaAcima(double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize){

    double valOrdem = valIni;

    for( int i=0; i<qtdOrdens; i++ ){
        if( !tenhoOrdemLimitadaDeVenda(valOrdem,symbol,comment ) ){
            enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, valOrdem, volume, comment);
        }
        valOrdem = m_symb.NormalizePrice(valOrdem+tickSize);
    }
}

//+--------------------------------------------------------------------------------------------+
//| Mantem uma sequencia de ordens limitadas de compra abaixo do valor informado.              |
//+--------------------------------------------------------------------------------------------+
void osc_minion_trade::preencherOrdensLimitadasDeCompraAbaixo(double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize){
   
    double valOrdem = valIni;

    for( int i=0; i<qtdOrdens; i++ ){
        if( !tenhoOrdemLimitadaDeCompra(valOrdem,symbol,comment ) ){
            enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, valOrdem, volume, comment);
        }
        valOrdem = m_symb.NormalizePrice(valOrdem-tickSize);
    }
}

//+--------------------------------------------------------------------------------------------+
//| Mantem uma sequencia de ordens limitadas de venda acima do valor informado.                |
//+--------------------------------------------------------------------------------------------+
void osc_minion_trade::preencherOrdensLimitadasDeVendaAcimaComLag(double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize, int lag){

    //
    // Determinando o valor inicial   
    //
    //    1.2 Busca maior ordem maior que a inicial.
    //        1.2.1 Se encontrar retorna um lag por vez ateh encontrar o menor valor
    //              maior ou igual ao inicial. Este serah o valor inicial.
    //
    //        1.2.2 Se nao encontrar, entao valIni eh o valor inicial valido. 
    //

    // 1.2 Busca maior ordem maior que a inicial.
    ulong ticket;
    double newValIni = buscarMaiorOrdemLimitadaDeVendaAcimaDe(valIni, symbol, comment, volume, ticket);
    
    // 1.2.1 Se encontrar retorna um lag por vez ateh encontrar o menor valor maior ou igual ao inicial.
    //       Este serah o valor inicial.
    if( newValIni > 0 ){
        while(newValIni > valIni){
            newValIni -= (tickSize*lag);
            newValIni  = m_symb.NormalizePrice(newValIni);
        }
    }else{
        // 1.2.2 Se nao encontrar, entao valIni eh o valor inicial valido. 
        newValIni = valIni;
    }
   
  //double valOrdem = m_symb.NormalizePrice(newValIni+(tickSize*lag) );
    double valOrdem = newValIni;

    //m_symb.RefreshRates();
    //double ask = m_symb.Ask(); 

    for( int i=0; i<qtdOrdens; i++ ){

        // incluindo as ordens no lag...
        if( !tenhoOrdemLimitadaDeVenda(valOrdem,symbol,comment ) ){
            if(valOrdem >= valIni) enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, valOrdem, volume, comment);
        }        

        // eliminando as ordens desalinhadas com o lag...
        for(int j=1; j<lag;j++){
            valOrdem = m_symb.NormalizePrice( valOrdem + tickSize );
            if( tenhoOrdemLimitadaDeVenda(valOrdem,symbol,comment ) ){
                //Print("Cancelando ordem de venda desalinhadas com o lag. Valor:",valOrdem);
                cancelarOrdensComentadasDeVenda(symbol,comment,valOrdem);
            }
        }
        valOrdem = m_symb.NormalizePrice( valOrdem + tickSize );
    }
    
    int qtd = contarOrdensLimitadasDeVenda(symbol,comment);
    //Print("Cancelando ordens de venda maiores que:",valOrdem);    
    // Eliminando ordens acima da faixa ordens permitida...
    if(qtd>qtdOrdens) cancelarOrdensComentadasDeVendaMaioresQue(symbol,comment,valOrdem);
    
}

//+--------------------------------------------------------------------------------------------+
//| Mantem uma sequencia de ordens limitadas de compra abaixo do valor informado.              |
//+--------------------------------------------------------------------------------------------+
void osc_minion_trade::preencherOrdensLimitadasDeCompraAbaixoComLag(double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize, int lag){
   
    //
    // Determinando o valor inicial   
    //
    //    1.2 Busca menor ordem menor que a inicial.
    //        1.2.1 Se encontrar aumenta um lag por vez ateh encontrar o maior valor maior ou igual ao inicial.
    //              Este serah o valor inicial.
    //
    //        1.2.2 Se nao encontrar, entao valIni eh o valor inicial valido. 
    //
    ulong ticket;
    double newValIni = buscarMenorOrdemLimitadaDeCompraAbaixoDe(valIni, symbol, comment, volume, ticket);
    
    // 1.2.1 Se encontrar retorna um lag por vez ateh encontrar o menor valor maior que o inicial.
    //       Este serah o valor inicial.
    if( newValIni > 0 ){
        while(newValIni < valIni){
            newValIni += (tickSize*lag);
            newValIni  = m_symb.NormalizePrice(newValIni);
        }
    }else{
        // 1.2.2 Se nao encontrar, entao valIni eh o valor inicial valido. 
        newValIni = valIni;
    }

  //double valOrdem = m_symb.NormalizePrice( newValIni-(tickSize*lag) );
    double valOrdem =                        newValIni                 ;

  //for( int i=0; i<qtdOrdens; i++ ){
  //    valOrdem = m_symb.NormalizePrice( valOrdem -(tickSize*lag) );
  //    if( !tenhoOrdemLimitadaDeCompra(valOrdem,symbol,comment ) ){
  //        enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, valOrdem, volume, comment);
  //    }
  //  //valOrdem = m_symb.NormalizePrice( valOrdem -(tickSize*lag) );
  //}

    //m_symb.RefreshRates();
    //double bid = m_symb.Bid(); 
    for( int i=0; i<qtdOrdens; i++ ){

        // incluindo as ordens no lag...
        if( !tenhoOrdemLimitadaDeCompra(valOrdem,symbol,comment ) ){
            if( valOrdem <= valIni ) enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, valOrdem, volume, comment);
        }

        // eliminando as ordens desalinhadas com o lag...
        for(int j=1;j<lag;j++){
            valOrdem = m_symb.NormalizePrice( valOrdem - tickSize );
            if( tenhoOrdemLimitadaDeCompra(valOrdem,symbol,comment ) ){
                //Print("Cancelando ordem de compra desalinhadas com o lag. Valor:",valOrdem);
                cancelarOrdensComentadasDeCompra(symbol,comment,valOrdem);
            }
        }
        valOrdem = m_symb.NormalizePrice( valOrdem - tickSize );       
    }

    int qtd = contarOrdensLimitadasDeCompra(symbol,comment);
    // Eliminando ordens abaixo da faixa ordens permitida...
    if( qtd > qtdOrdens ) cancelarOrdensComentadasDeCompraMenoresQue(symbol,comment,valOrdem);
}

//+--------------------------------------------------------------------------------------------+
//| Mantem uma sequencia de ordens limitadas de venda acima do valor informado. Versao 2       |
//+--------------------------------------------------------------------------------------------+
void osc_minion_trade::preencherOrdensLimitadasDeVendaAcimaComLag2(double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize, int lag){
    //Print(__FUNCTION__, " LAG:",lag);

    //
    // Determinando o valor inicial   
    //
    //    1.2 Busca menor ordem de venda.
    //        1.2.1 Se     encontrar, entao este   eh o valor inicial.
    //        1.2.2 Se nao encontrar, entao valIni eh o valor inicial valido. 
    //

    // 1.2 Busca menor ordem de venda.
    ulong ticket;
    double newValIni = buscarMenorOrdemLimitadaDeVenda(symbol, comment, volume, ticket);
    
    // 1.2.1 Se encontrar, entao este eh o valor inicial.
    // 1.2.2 Se nao encontrar, entao valIni eh o valor inicial valido. 
    
    //Print( __FUNCTION__, " :-| valIni:",valIni, " newValIni:",newValIni);
    if( newValIni == 0 || newValIni > valIni ){ newValIni = valIni; }
   
    double valOrdem = newValIni;

    //m_symb.RefreshRates();
    //double ask = m_symb.Ask(); 

    for( int i=0; i<qtdOrdens; i++ ){

        // incluindo as ordens no lag...
        if( !tenhoOrdemLimitadaDeVenda(valOrdem,symbol,comment ) ){
            if(valOrdem >= valIni) enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, valOrdem, volume, comment);
        }        

        // eliminando as ordens desalinhadas com o lag...
        for(int j=1; j<lag;j++){
            valOrdem = m_symb.NormalizePrice( valOrdem + tickSize );
            if( tenhoOrdemLimitadaDeVenda(valOrdem,symbol,comment ) ){
                //Print("Cancelando ordem de venda desalinhadas com o lag. Valor:",valOrdem);
                //cancelarOrdensComentadasDeVenda(symbol,comment,valOrdem);
                cancelarOrdensPorTipoEvalor(ORDER_TYPE_SELL_LIMIT,valOrdem);
            }
        }
        valOrdem = m_symb.NormalizePrice( valOrdem + tickSize );
    }
    
    int qtd = contarOrdensLimitadasDeVenda(symbol,comment);
    //Print("Cancelando ordens de venda maiores que:",valOrdem);    
    // Eliminando ordens acima da faixa ordens permitida...
    if(qtd>qtdOrdens) cancelarOrdensComentadasDeVendaMaioresQue(symbol,comment,valOrdem);
    
}


//+--------------------------------------------------------------------------------------------+
//| Mantem uma sequencia de ordens limitadas de compra abaixo do valor informado. Versao 2.    |
//+--------------------------------------------------------------------------------------------+
void osc_minion_trade::preencherOrdensLimitadasDeCompraAbaixoComLag2(double valIni, int qtdOrdens, string symbol, string comment, double volume, double tickSize, int lag){
    //Print(__FUNCTION__, " LAG:",lag);
    //
    // Determinando o valor inicial   
    //
    //    1.2 Busca maior ordem de compra.
    //        1.2.1 Se     encontrar, entao este   eh o valor inicial.
    //        1.2.2 Se nao encontrar, entao valIni eh o valor inicial valido. 
    //
    ulong ticket;
    double newValIni = buscarMaiorOrdemLimitadaDeCompra(symbol, comment, volume, ticket);
    
    //        1.2.1 Se     encontrar, entao este   eh o valor inicial.
    //        1.2.2 Se nao encontrar, entao valIni eh o valor inicial valido. 
    //Print( __FUNCTION__, " :-| valIni:",valIni, " newValIni:",newValIni);
    if( newValIni == 0 || newValIni < valIni ){ newValIni = valIni; }

    double valOrdem = newValIni;

    for( int i=0; i<qtdOrdens; i++ ){

        // incluindo as ordens no lag...
        if( !tenhoOrdemLimitadaDeCompra(valOrdem,symbol,comment ) ){
            if( valOrdem <= valIni ) enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, valOrdem, volume, comment);
        }

        // eliminando as ordens desalinhadas com o lag...
        for(int j=1;j<lag;j++){
            valOrdem = m_symb.NormalizePrice( valOrdem - tickSize );
            if( tenhoOrdemLimitadaDeCompra(valOrdem,symbol,comment ) ){
                //Print("Cancelando ordem de compra desalinhadas com o lag. Valor:",valOrdem);
                //cancelarOrdensComentadasDeCompra(symbol,comment,valOrdem);
                cancelarOrdensPorTipoEvalor(ORDER_TYPE_BUY_LIMIT,valOrdem);
            }
        }
        valOrdem = m_symb.NormalizePrice( valOrdem - tickSize );       
    }

    int qtd = contarOrdensLimitadasDeCompra(symbol,comment);
    // Eliminando ordens abaixo da faixa ordens permitida...
    if( qtd > qtdOrdens ) cancelarOrdensComentadasDeCompraMenoresQue(symbol,comment,valOrdem);
}

//+--------------------------------------------------------------------------------------------+
//| elimina ordens cujo volume seja acima do informado.                                        |
//+--------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensComVolumeAcimaDe(ENUM_ORDER_TYPE order_type, double volume){
   ulong order_ticket = 0    ;
//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL        ) == m_symb_str      &&
               OrderGetDouble (ORDER_VOLUME_CURRENT) >  volume          &&
               OrderGetInteger(ORDER_TYPE          ) == order_type      &&
               OrderGetInteger(ORDER_STATE)          == ORDER_STATE_PLACED ){
               cancelarOrdem(order_ticket);
          }
      }
   }
}


//+---------------------------------------------------------------------------+
//| Busca a menor ordem limitada de venda com valor MENOR que o especificado. |
//+---------------------------------------------------------------------------+
double osc_minion_trade::buscarMenorOrdemLimitadaDeCompraAbaixoDe(double value, string symbol, string comment, double volume, ulong& ticket){
   
   ulong order_ticket = 0    ;
   double price_open;
   double valMin = value;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL        ) == symbol          &&
               OrderGetDouble (ORDER_VOLUME_CURRENT) == volume          &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1            &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_BUY_LIMIT  &&
               OrderGetInteger(ORDER_STATE)    == ORDER_STATE_PLACED     ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN);
               if( price_open < valMin ){
                   valMin = price_open;
                   ticket = order_ticket;
               }
          }
      }
   }
   return valMin==value?0.0:valMin;
}


//+---------------------------------------------------------------------------+
//| Busca a maior ordem limitada de compra com valor MAIOR que o especificado.|
//+---------------------------------------------------------------------------+
double osc_minion_trade::buscarMaiorOrdemLimitadaDeVendaAcimaDe(double value, string symbol, string comment, double volume, ulong& ticket){
   
   ulong            order_ticket = 0    ;
   double           price_open          ;
   double           valMax       = value;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      //m_order.SelectByIndex(i);
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL        ) == symbol          &&
               OrderGetDouble (ORDER_VOLUME_CURRENT) == volume          &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1            &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_SELL_LIMIT &&
               OrderGetInteger(ORDER_STATE   ) == ORDER_STATE_PLACED     ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN);
               if( price_open >  valMax ){
                   valMax = price_open;
                   ticket = order_ticket;
               }
          }
      }
   }
   return valMax==value?0.0:valMax;
}


//+---------------------------------------------------------------------------------+
//| Busca a menor ordem limitada de venda para simbolo,volume e comentario informados
//+---------------------------------------------------------------------------------+
double osc_minion_trade::buscarMenorOrdemLimitadaDeVenda(string symbol, string comment, double volume, ulong& ticket){
   
   ulong  order_ticket = 0;
   double price_open      ;
   double valMin       = DBL_MAX;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      //m_order.SelectByIndex(i);
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL        ) == symbol          &&
               OrderGetDouble (ORDER_VOLUME_CURRENT) == volume          &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1            &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_SELL_LIMIT &&
               OrderGetInteger(ORDER_STATE   ) == ORDER_STATE_PLACED     ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN);
               if( price_open <  valMin ){
                   valMin = price_open;
                   ticket = order_ticket;
               }
          }
      }
   }
   return valMin==DBL_MAX?0.0:valMin;
}

//+---------------------------------------------------------------------------------+
//| Busca a menor ordem limitada de venda. retorna o valor e seta o numero do ticket|
//+---------------------------------------------------------------------------------+
double osc_minion_trade::buscarMenorOrdemLimitadaDeVenda(ulong& ticket){
   
   ulong  order_ticket = 0;
   double price_open      ;
   double valMin       = DBL_MAX;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      //m_order.SelectByIndex(i);
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL  ) == m_symb_str            &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_SELL_LIMIT &&
               OrderGetInteger(ORDER_STATE   ) == ORDER_STATE_PLACED     ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN);
               if( price_open <  valMin ){
                   valMin = price_open;
                   ticket = order_ticket;
               }
          }
      }
   }
   return valMin==DBL_MAX?0.0:valMin;
}



//+------------------------------------------------------------------------------------+
//| Busca a maior ordem limitada de compra para o simbolo,volume e comentario informados
//+------------------------------------------------------------------------------------+
double osc_minion_trade::buscarMaiorOrdemLimitadaDeCompra(string symbol, string comment, double volume, ulong& ticket){
   
   ulong  order_ticket = 0;
   double price_open      ;
   double valMax       = 0;

//--- passando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      //m_order.SelectByIndex(i);
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL        ) == symbol         &&
               OrderGetDouble (ORDER_VOLUME_CURRENT) == volume         &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1           &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_BUY_LIMIT &&
               OrderGetInteger(ORDER_STATE   ) == ORDER_STATE_PLACED     ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN);
               if( price_open >  valMax ){
                   valMax = price_open;
                   ticket = order_ticket;
               }
          }
      }
   }
   return valMax;
}

//+------------------------------------------------------------------------------------+
//| Busca a maior ordem limitada de compra. Retorna o preco e seta o ticket.           |
//+------------------------------------------------------------------------------------+
double osc_minion_trade::buscarMaiorOrdemLimitadaDeCompra(ulong& ticket){
   
   ulong  order_ticket = 0;
   double price_open      ;
   double valMax       = 0;

//--- passando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      //m_order.SelectByIndex(i);
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL  ) == m_symb_str           &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_BUY_LIMIT &&
               OrderGetInteger(ORDER_STATE   ) == ORDER_STATE_PLACED     ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN);
               if( price_open >  valMax ){
                   valMax = price_open;
                   ticket = order_ticket;
               }
          }
      }
   }
   return valMax;
}


//+---------------------------------------------------------------------------+
//| Busca a MENOR ordem limitada de COMPRA com o comentario informado.        |
//| Se encontrar, retorna o valor da ordem e seta o ticket.                   |
//| Se nao encontrar retorna zero.                                            |
//+---------------------------------------------------------------------------+
double osc_minion_trade::buscarMenorOrdemLimitadaDeCompraComComentarioNumerico( ulong& ticket){
   
   ulong  order_ticket = 0;
   double price_open   = 0;
   double valMin       = 0;
   string strComentarioNumerico;
   long      comentarioNumerico;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL  ) == m_symb.Name()         &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_BUY_LIMIT  &&
               OrderGetInteger(ORDER_STATE)    == ORDER_STATE_PLACED     ){

               strComentarioNumerico = OrderGetString(ORDER_COMMENT);
               comentarioNumerico    = StringToInteger(strComentarioNumerico);          
              
               // se o comentario da ordem eh um numero, entao a cancelamos...
               if( MathIsValidNumber(comentarioNumerico) && comentarioNumerico != 0 ){ 

                   price_open = OrderGetDouble(ORDER_PRICE_OPEN);
                   if( price_open < valMin || valMin == 0){
                       valMin = price_open;
                       ticket = order_ticket;
                   }
               }
          }
      }
   }
   return valMin;
}
//+---------------------------------------------------------------------------+
//| Busca a MAIOR ordem limitada de VENDA com o comentario informado.         |
//| Se encontrar, retorna o valor da ordem e seta o ticket.                   |
//| Se nao encontrar retorna zero.                                            |
//+---------------------------------------------------------------------------+
double osc_minion_trade::buscarMaiorOrdemLimitadaDeVendaComComentarioNumerico(ulong& ticket){
   
   ticket              = 0;
   ulong  order_ticket = 0;
   double price_open   = 0;
   double valMax       = 0;
   string strComentarioNumerico;
   long      comentarioNumerico;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL  ) == m_symb.Name()          &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_SELL_LIMIT  &&
               OrderGetInteger(ORDER_STATE)    == ORDER_STATE_PLACED     ){

               strComentarioNumerico = OrderGetString(ORDER_COMMENT);
               comentarioNumerico    = StringToInteger(strComentarioNumerico);          
              
               // se o comentario da ordem eh um numero, entao a cancelamos...
               if( MathIsValidNumber(comentarioNumerico) && comentarioNumerico != 0 ){ 

                   price_open = OrderGetDouble(ORDER_PRICE_OPEN);
                   if( price_open > valMax || valMax == 0){
                       valMax = price_open;
                       ticket = order_ticket;
                   }
               }
          }
      }
   }
   return valMax;
}

// Cancela a MAIOR ordem de VENDA com o comentario numerico.
ulong osc_minion_trade::cancelarMaiorOrdemDeVendaComComentarioNumerico(){
    ulong ticket;
    if( buscarMaiorOrdemLimitadaDeVendaComComentarioNumerico(ticket) > 0 ){
        //Print(__FUNCTION__, " Cancelando ordem com coment numerico #",ticket, "...");
        cancelarOrdem(ticket);
    }
    return ticket;    
}

// Cancela a MENOR ordem de COMPRA com o comentario numerico.
ulong osc_minion_trade::cancelarMenorOrdemDeCompraComComentarioNumerico(){
    ulong ticket;
    if( buscarMenorOrdemLimitadaDeCompraComComentarioNumerico(ticket) > 0 ){
        //Print(__FUNCTION__, " Cancelando ordem com coment numerico #",ticket, "...");
        cancelarOrdem(ticket);
    }
    return ticket;    
}

//+---------------------------------------------------------------------------+
//| Conta as ordens limitadas de venda do ticker e simbolos informados        |
//+---------------------------------------------------------------------------+
int osc_minion_trade::contarOrdensLimitadasDeVenda(string symbol, string comment){
   int qtd = 0;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL        ) == symbol          &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1            &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_SELL_LIMIT &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
               //OrderGetInteger(ORDER_STATE   ) == ORDER_STATE_PLACED     
               ){
               qtd++;
          }
      }
   }
   return qtd;
}

//+---------------------------------------------------------------------------+
//| Conta as ordens limitadas de compra do ticker e simbolos informados       |
//+---------------------------------------------------------------------------+
int osc_minion_trade::contarOrdensLimitadasDeCompra(string symbol, string comment){
   int qtd = 0;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL        ) == symbol          &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1            &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_BUY_LIMIT  &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
               //OrderGetInteger(ORDER_STATE   ) == ORDER_STATE_PLACED     
               ){
               qtd++;
          }
      }
   }
   return qtd;
}




//+--------------------------------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada de venda MENOR que o valor e volume especificados.    |
//| Altera ordens com o valor maior e mesmo comentario.                                        |
//+--------------------------------------------------------------------------------------------+
double osc_minion_trade::tenhoOrdemLimitadaDeVendaMenorQue(double value, string symbol, string comment, double volume, ulong& ticket, bool aceitarIgual=false){
   
   if( OrdersTotal() == 0 ) return 0;
   
   ulong order_ticket = 0;
   double price_open;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL  ) == symbol                &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1            &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_SELL_LIMIT &&
               orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
               ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN    );
               if( price_open                           <  value  &&
                   OrderGetDouble(ORDER_VOLUME_CURRENT) == volume   ){
                   ticket = order_ticket;
                   return price_open; // foi encontrada a ordem e nao precisou ser modificada
               
               }else if( aceitarIgual                                  && 
                         price_open                           == value &&
                         OrderGetDouble(ORDER_VOLUME_CURRENT) == volume  ){
                   ticket = order_ticket;
                   return price_open; // foi encontrada a ordem e nao precisou ser modificada
               
               }else{
                   Print(":-| ",__FUNCTION__ ,"(",value,",",symbol,",",comment,",",volume,",",ticket,",",aceitarIgual,
                                              ") Alt #",order_ticket,
                                              " OldP=",price_open,
                                              " NewP=",value,
                                              " #state ", stateOrderToString()," asyn");   
                   alterarOrdem( (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE), value, volume, order_ticket, "");
                   ticket = order_ticket;
                   return value; // foi encontrada ordem e modificada
               }
          }
      }
   }
   return 0; // nao foi encontrada sequer ordem ordem modificavel
}

//+---------------------------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada de venda MENOR ou IGUAL ao valor especificado.   |
//+---------------------------------------------------------------------------------------+
double osc_minion_trade::tenhoOrdemLimitadaDeVendaMenorOuIgual(double value){
   
   if( OrdersTotal() == 0 ) return 0;
   
   ulong order_ticket = 0;
   double price_open;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL  ) == m_symb_str            &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_SELL_LIMIT &&
               orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
               ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN );
               if( price_open <= value ){
                   return price_open; // foi encontrada uma ordem
               }
          }
      }
   }
   return 0; // nao foi encontrada sequer uma ordem
}

//+---------------------------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada de compra MAIOR ou IGUAL ao valor especificado.  |
//+---------------------------------------------------------------------------------------+
double osc_minion_trade::tenhoOrdemLimitadaDeCompraMaiorOuIgual(double value){
   
   if( OrdersTotal() == 0 ) return 0;
   
   ulong order_ticket = 0;
   double price_open;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL  ) == m_symb_str           &&
               OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_BUY_LIMIT &&
               orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
               ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN);
               if( price_open >= value ){
                   return price_open; // foi encontrada a ordem
               }
          }
      }
   }
   return 0; // nao foi encontrada sequer uma ordem
}

//+---------------------------------------------------------------------------------------------------------------+
//| Mantem uma ordem limitada entre o valor informado e o melhor bid/ask, cancelando outras ordens em niveis      |
//| de preco diferentes.                                                                                          |
//| - se encontrar ordem com mesmo valor, volume e comentario:                                                    |
//|   - se nao tem ordem no room informado, altera para o valor informado.                                        |
//|   - se jah tem ordem no romm informado, cancela.                                                              |
//| - room aqui eh o espaco entre o preco informado e a direcao do melhor bid/ask.                                |
//|   -  EX:                                                                                                      |
//|   -                                                                                                           |
//|   -  ask 80                                                                                                   |
//|   -  ask 70                                                                                                   |
//|   -  ask 60  x                                                                                                |
//|   -  bid 50  x                                                                                                |
//|   -  bid 40  x                                                                                                |
//|   -  bid 30                                                                                                   |
//|   -                                                                                                           |
//|   -  se a funcao receber um pedido para manter a ordem de compra no 40, e o room igual a 3:                   |
//|      - manterah a maior ordem limitada de compra acima de 30 e menor que 70 e cancelarah as demais.           |
//|   -                                                                                                           |
//| - IN                                                                                                          |
//|   - symbol                                                                                                    |
//|   - order_type                                                                                                |
//|   - comment                                                                                                   |
//|   - value                                                                                                     |
//|   - room                                                                                                      |
//|   - vol                                                                                                       |
//| - OUT                                                                                                         |
//|   - <=  zero: erro                                                                                            |
//|   - >   zero: ordem mantida                                                                                   |
//|---------------------------------------------------------------------------------------------------------------+
ulong osc_minion_trade:: manterOrdemLimitadaNoRoom(ENUM_ORDER_TYPE order_type, string comment, double value, double room, double vol){

    // nao tem ordem, cadastramos uma agora...
    if( OrdersTotal() == 0 ){
        if( enviarOrdemPendente(order_type, value , vol, comment) ){return m_tres.order;}else{return -1;}
    }

    ulong order_ticket    = 0;
    ulong order_found     = 0;
    ulong order_candidate = 0;

//--- passando por todas as ordens pendentes com o mesmo comentario, volume e faixa de valor...
   for(int i=OrdersTotal()-1; i>=0; i--){
      if( ( order_ticket = OrderGetTicket(i) )>0 ){

          if(     OrderGetString (ORDER_SYMBOL        )          == m_symb_str &&
     //StringFind(OrderGetString (ORDER_COMMENT       ),comment) > -1          &&
 (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE          )          == order_type &&
                  OrderGetDouble (ORDER_VOLUME_INITIAL)          == vol        &&
              orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
                                                                                   ){
              order_candidate = order_ticket;

              // compras...
              if( orderTypeCompraLimitada(order_type) &&
            	  orderPrice() >= (value     )        &&
            	  orderPrice() <= (value+room)          ){

            	  // encontrou a ordem. seu numero estah em order_ticket
                  order_found = order_ticket; break;
              }

              // vendas...
              if( orderTypeVendaLimitada(order_type) &&
            	  orderPrice() <= (value     )       &&
            	  orderPrice() >= (value-room)         ){

            	  // encontrou a ordem. seu numero estah em order_ticket
                  order_found = order_ticket; break;
              }
          }
      }
   }//for

   // ordem encontrada... cancelamos as demais do mesmo tipo e terminamos
   if( order_found > 0 ){
       // cancelamos as demais ordens, exceto a encontrada ou a modificada...
     //cancelarOrdens(symbol, order_type, comment, order_found);
       cancelarOrdens(order_found);
       return order_found;
   }

   //Print("order_candidate=",order_candidate," order_found=",order_found, " ...");

   // nao encontrou ordem nenhuma, entao cadastramos uma agora...
   if( order_candidate == 0 ){
       if( enviarOrdemPendente(order_type, value , vol, comment) ){return m_tres.order;}else{return -1;}
   }else{
       // encontrou pelo menos uma ordem, mas nao no valor informado...
       // - alteramos a ordem para o parametro informado
       if( order_candidate > 0 ){
           alterarOrdem(order_type, value, vol, order_candidate, comment);
           order_found = order_candidate;
       }
   }

   // cancelamos as demais ordens, exceto a encontrada ou a modificada...
 //cancelarOrdens(symbol, order_type, comment, order_found);
   if( !PositionSelect(m_symb_str) ){
       cancelarOrdens(order_found);
   }

   return order_found;
}

//+---------------------------------------------------------------------------------------------------------------+
//| Mantem uma ordem limitada em torno do valor informado, cancelando outras ordens em niveis de preco diferentes.|
//| - se encontrar ordem com mesmo valor, volume e comentario:                                                    |
//|   - se nao tem ordem no valor informado,altera para o valor informado.                                        |
//|   - se jah tem ordem no valor informado, cancela.                                                             |
//| - IN                                                                                                          |
//|   - symbol                                                                                                    |
//|   - order_type                                                                                                |
//|   - comment                                                                                                   |
//|   - value                                                                                                     |
//|   - room                                                                                                      |
//|   - vol                                                                                                       |
//| - OUT                                                                                                         |
//|   - <=  zero: erro                                                                                            |
//|   - >   zero: ordem mantida                                                                                   |
//|---------------------------------------------------------------------------------------------------------------+
ulong osc_minion_trade:: manterOrdemLimitadaEntornoDe(string symbol, ENUM_ORDER_TYPE order_type, string comment, double value, double room, double vol){

    // nao tem ordem, cadastramos uma agora...
    if( OrdersTotal() == 0 ){
        if( enviarOrdemPendente(order_type, value , vol, comment) ){return m_tres.order;}else{return -1;}
    }
   
    ulong order_ticket    = 0;
    ulong order_found     = 0;
    ulong order_candidate = 0;

//--- passando por todas as ordens pendentes com o mesmo comentario, volume e faixa de valor...
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( ( order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL        )          == symbol     &&
    StringFind(OrderGetString (ORDER_COMMENT       ),comment) > -1          &&
               OrderGetInteger(ORDER_TYPE          )          == order_type &&
               OrderGetDouble (ORDER_VOLUME_INITIAL)          == vol        &&
               orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
                                                                                   ){
              order_candidate = order_ticket;

              if( OrderGetDouble(ORDER_PRICE_OPEN) >= (value-room) &&
                  OrderGetDouble(ORDER_PRICE_OPEN) <= (value+room)  ){
                  
                  // encontrou a ordem. seu numero estah em order_ticket
                  order_found = order_ticket; break;
              }              
          }
      }
   }//for
   
   // ordem encontrada... cancelamos as demais do mesmo tipo e terminamos
   if( order_found > 0 ){
       // cancelamos as demais ordens, exceto a encontrada ou a modificada...
       cancelarOrdens(symbol, order_type, comment, order_found);
       return order_found; 
   }
   
   //Print("order_candidate=",order_candidate," order_found=",order_found, " ...");

   // nao encontrou ordem nenhuma, entao cadastramos uma agora...
   if( order_candidate == 0 ){
       if( enviarOrdemPendente(order_type, value , vol, comment) ){return m_tres.order;}else{return -1;}
   }else{
       // encontrou pelo menos uma ordem, mas nao no valor informado...
       // - alteramos a ordem para o parametro informado
       if( order_candidate > 0 ){
           alterarOrdem(order_type, value, vol, order_candidate, comment);
           order_found = order_candidate;
       }
   }
   
   // cancelamos as demais ordens, exceto a encontrada ou a modificada...
   cancelarOrdens(symbol, order_type, comment, order_found);

   return order_found; 
}


//+----------------------------------------------------------------------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada de compra no valor e volume especificados. Altera para o valor e volume especificados       |
//| caso encontre a ordem com outro valor/volume, mesmo comentario (comentario fazendo parte da ordem encontrada).                   |
//+----------------------------------------------------------------------------------------------------------------------------------+
bool osc_minion_trade::tenhoOrdemLimitadaDeCompra(double value, string symbol, string comment, double volume, bool cancelar, double tolerancia, string newComment=""){
   
   ulong order_ticket = 0    ;
   //ENUM_ORDER_STATE order_state;
   double           price_open;
//--- passando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          //order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
          if(  OrderGetString (ORDER_SYMBOL ) == symbol                &&
    StringFind(OrderGetString(ORDER_COMMENT),comment) > -1             &&
               OrderGetInteger(ORDER_TYPE   ) == ORDER_TYPE_BUY_LIMIT  &&
               orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
               //order_state                    == ORDER_STATE_PLACED     
               ){

               price_open = OrderGetDouble (ORDER_PRICE_OPEN);
               if( price_open                           >= value-tolerancia && 
                   price_open                           <= value+tolerancia &&
                   OrderGetDouble(ORDER_VOLUME_CURRENT) == volume            ){
                   return true; // colcoado aqui em 04/02/2020 para que nao siga verificando todas as ordens pendentes.
               }else{
                   if( cancelar ){ 
                       Print(":-| ",__FUNCTION__ ,"(",value,",",symbol,",",comment,",",volume,",",cancelar,",",tolerancia,") Alt #",order_ticket,
                                                                                                                           " OldP=",price_open,
                                                                                                                           " NewP=",value,
                                                                                                                           " #state ", stateOrderToString()," asyn");   
                       alterarOrdem( (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE), value, volume, order_ticket, newComment);
                       return true; // colcoado aqui em 04/02/2020 para que nao siga verificando todas as ordens pendentes.
                   }
               }
          }
      }
   }
   return false;
}

//+--------------------------------------------------------------------------------------------------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada de compra com valor MAIOR e volume igual aos especificados. Altera ordem com o valor menor e mesmo comentario e volume. |
//+--------------------------------------------------------------------------------------------------------------------------------------------------------------+
double osc_minion_trade::tenhoOrdemLimitadaDeCompraMaiorQue(double value, string symbol, string comment, double volume, ulong& ticket, bool aceitarIgual=false){
   
   if( OrdersTotal() == 0 ) return 0;
   ulong order_ticket = 0    ;
   double           price_open;

//--- passaANDO por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          if(  OrderGetString (ORDER_SYMBOL ) == symbol                &&
    StringFind(OrderGetString(ORDER_COMMENT),comment) > -1             &&
               OrderGetInteger(ORDER_TYPE   ) == ORDER_TYPE_BUY_LIMIT  &&
               orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
               ){

               price_open = OrderGetDouble (ORDER_PRICE_OPEN);
               if( price_open                           >  value && 
                   OrderGetDouble(ORDER_VOLUME_CURRENT) == volume  ){
                   ticket = order_ticket;
                   return price_open; // foi encontrada a ordem e nao precisou ser modificada
               }else if( aceitarIgual                                  && 
                         price_open                           == value &&
                         OrderGetDouble(ORDER_VOLUME_CURRENT) == volume  ){
                   ticket = order_ticket;
                   return price_open; // foi encontrada a ordem e nao precisou ser modificada
               }else{
                   Print(":-| ",__FUNCTION__ ,"(",value,",",symbol,",",comment,",",volume,",",ticket,",",aceitarIgual,
                                              ") :-| Alt #",order_ticket,
                                              " OldP=",price_open,
                                              " NewP=",value,
                                              " #state ", stateOrderToString()," asyn");   
                   alterarOrdem( (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE), value, volume, order_ticket, "");
                   ticket = order_ticket;
                   return value; // foi encontrada a ordem e precisou ser modificada
               }
          }
      }
   }
   return 0;
}

//+-----------------------------------------------------------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada com volume e comentario iguais aos informados e valor diferente do informado.    |
//| Se encontrar, altera o valor da ordem para o informardo em "valor".                                                   |
//+-----------------------------------------------------------------------------------------------------------------------+
bool osc_minion_trade::alterarOrdemLimitadaComValorDiferenteDe(double value, string symbol, double volume, string comment, string newComment=""){
   
   ulong order_ticket = 0    ;
   ENUM_ORDER_STATE order_state;
   double price_open;

//--- passaando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
          if(  OrderGetString (ORDER_SYMBOL  ) == symbol                &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1            &&
             //OrderGetInteger(ORDER_TYPE    ) == ORDER_TYPE_SELL_LIMIT &&
               order_state                     != ORDER_STATE_REJECTED  &&
               order_state                     != ORDER_STATE_CANCELED  &&
               order_state                     != ORDER_STATE_EXPIRED    ){

               price_open = OrderGetDouble(ORDER_PRICE_OPEN);
               
               if( price_open != value && OrderGetDouble(ORDER_VOLUME_CURRENT) == volume ){
                   Print(":-| ",__FUNCTION__ ,"(",value,",",symbol,",",volume,",",comment,",",newComment,") :-| Alt #",order_ticket,
                                                                                                              " OldP=",price_open,
                                                                                                              " NewP=",value,
                                                                                                              " #state ", stateOrderToString()," asyn");   
                   alterarOrdem( (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE), value, volume, order_ticket, newComment);
                   return true;
               }
          }
      }
   }
   return false;
}


//+---------------------------------------------------------------------+
//| Verifica se tenho uma ordem limitada com o comentario especificado  |
//+---------------------------------------------------------------------+
bool osc_minion_trade::tenhoOrdemPendenteComComentario( const string symbol, const string comment){
   
   //ulong order_ticket; 
   ENUM_ORDER_STATE order_state;

//--- passando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      
    //if( (order_ticket = OrderGetTicket(i) )>0 ){ 
      if(                 OrderGetTicket(i)  >0 ){ 

        //m_order.SelectByIndex(i); // selecionando a ordem para posterior alteracao se necessario...
          
          order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
          if(//m_order.Symbol()              == symbol                 &&
             //m_order.Comment()             == comment                &&
               OrderGetString (ORDER_SYMBOL ) == symbol                &&
               OrderGetString (ORDER_COMMENT) == comment               &&
               order_state                    != ORDER_STATE_REJECTED  &&
               order_state                    != ORDER_STATE_CANCELED  &&
               order_state                    != ORDER_STATE_EXPIRED    ){
               return true;
          }
      }
   }
   return false;
}


//+---------------------------------------------------------------------+
//| Conta e retorna o volume das ordens de venda pendentes.          |
//+---------------------------------------------------------------------+
double osc_minion_trade::getVolOrdensPendentesDeVenda(){ return getVolOrdensPendentesDeVenda(m_symb_str); }
double osc_minion_trade::getVolOrdensPendentesDeVenda(string symbol){
   
   ulong  order_ticket;
   double volOrdensPendentes = 0;
   ENUM_ORDER_STATE order_state;
   ENUM_ORDER_TYPE  order_type;

//--- passando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          //m_order.SelectByIndex(i); // selecionando a ordem para posterior alteracao se necessario...

          order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
          order_type  = (ENUM_ORDER_TYPE )OrderGetInteger(ORDER_TYPE );
          if(   OrderGetString (ORDER_SYMBOL) == symbol    &&
              ( order_type  == ORDER_TYPE_SELL_LIMIT || 
                order_type  == ORDER_TYPE_SELL_STOP  || 
                order_type  == ORDER_TYPE_SELL_STOP_LIMIT )&&
                order_state != ORDER_STATE_REJECTED  &&
                order_state != ORDER_STATE_CANCELED  &&
                order_state != ORDER_STATE_EXPIRED    ){

                volOrdensPendentes += OrderGetDouble(ORDER_VOLUME_CURRENT); 
          }
      }
   }
   return volOrdensPendentes;
}

//+---------------------------------------------------------------------+
//| Conta e retorna o volume das ordens de compra pendentes.          |
//+---------------------------------------------------------------------+
double osc_minion_trade::getVolOrdensPendentesDeCompra(){ return getVolOrdensPendentesDeCompra(m_symb_str); }
double osc_minion_trade::getVolOrdensPendentesDeCompra(string symbol){
   
   ulong  order_ticket;
   double volOrdensPendentes = 0;
   ENUM_ORDER_STATE order_state;
   ENUM_ORDER_TYPE  order_type;

//--- passando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      
      if( (order_ticket = OrderGetTicket(i) )>0 ){ 

          //m_order.SelectByIndex(i); // selecionando a ordem para posterior alteracao se necessario...

          order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
          order_type  = (ENUM_ORDER_TYPE )OrderGetInteger(ORDER_TYPE );
          if(   OrderGetString (ORDER_SYMBOL)  == symbol   &&
              ( order_type  == ORDER_TYPE_BUY_LIMIT || 
                order_type  == ORDER_TYPE_BUY_STOP  || 
                order_type  == ORDER_TYPE_BUY_STOP_LIMIT ) &&
                order_state != ORDER_STATE_REJECTED        &&
                order_state != ORDER_STATE_CANCELED        &&
                order_state != ORDER_STATE_EXPIRED          ){

                volOrdensPendentes += OrderGetDouble(ORDER_VOLUME_CURRENT); 
          }
      }
   }
   return volOrdensPendentes;
}

//+---------------------------------------------------------------------+
//| Conta e retorna o volume das ordens de compra pendentes.          |
//+---------------------------------------------------------------------+
int osc_minion_trade::contarOrdensPendentes(ENUM_ORDER_TYPE order_type){
   
   ulong  order_ticket;
   int qtdOrdensPendentes = 0;

//--- passando por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      
      if( (order_ticket = OrderGetTicket(i) )              > 0          &&
           OrderGetString (ORDER_SYMBOL)                  == m_symb_str &&
           (ENUM_ORDER_TYPE )OrderGetInteger(ORDER_TYPE ) == order_type &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)) 
        ){ 
           qtdOrdensPendentes++; 
      }
   }
   return qtdOrdensPendentes;
}
//+---------------------------------------------------------------------+

//+----------------------------------------------------------------------------------+
//| Conta e retorna o volume das ordens pendentes.                                   |
//| order_signal = +1 -> retorna a contagem das ordens pendentes de compra limitadas |
//|              = -1 -> retorna a contagem das ordens pendentes de venda  limitadas |
//+----------------------------------------------------------------------------------+
int osc_minion_trade::contarOrdensPendentes(int order_signal){
   
   ulong  order_ticket;
   int qtdOrdensPendentes = 0;

//--- passando por todas as ordens pendentes 
   for( int i=OrdersTotal()-1; i>=0; i-- ){ 
      
      if( (order_ticket = OrderGetTicket(i) )  > 0          &&
           OrderGetString (ORDER_SYMBOL)      == m_symb_str &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)) 
        ){ 
        
           if( order_signal == 1 && 
             (ENUM_ORDER_TYPE )OrderGetInteger(ORDER_TYPE ) == ORDER_TYPE_BUY_LIMIT ){
               qtdOrdensPendentes++; 
           }else{
               if( order_signal == -1 && 
                   (ENUM_ORDER_TYPE )OrderGetInteger(ORDER_TYPE ) == ORDER_TYPE_SELL_LIMIT ){
                   qtdOrdensPendentes++; 
               }           
           }
      }
   }
   return qtdOrdensPendentes;
}
//+---------------------------------------------------------------------+

//+----------------------------------------------------------------------------------+
//| Com relacao as ordens de saida de uma posicao conceituamos:                      |
//| Regiao de aproximacao: eh aquela mais próxima ao breakeven, onde se consideram   |
//|                        boas as chances de execucao das ordens de saida.          |
//| Regiao de afastamento: eh aquela mais afastada do breakeven, onde se consideram  |
//|                        poucas as chances de execucao das ordens de saida.        |
//| Esta função traz ordens da regiao de afastamento para a regiao de aproximacao.   |
//|                                                                                  |
//| PARAMETROS                                                                       |
//| order_signal = +1 -> ordens de saida sao as        pendentes de compra limitadas |
//|              = -1 -> ordens de saida sao as        pendentes de venda  limitadas |
//|                                                                                  |
//| valNear      = valor, na regiao de aproximacao, mais proximo  ao breakeven.      |
//|                                                                                  |
//| valFar       = valor, na regiao de aproximacao, mais afastado do breakeven.      |
//|                                                                                  |
//| lag          = ao remanejar as ordens para dentro da regiao de aproximacao,      |
//|                a distancia entre cada ordem eh chamada de lag. Esta funcao nao   |
//|                corrigirah ordens dentro da regiao de aproximacao, que estejam    |
//|                menos afastadas umas das outras que o lag informado. O lag serah  |
//|                usado para as novas ordens remanejadas para dentro da regiao de   |
//|                aproximacao.                                                      |
//| retorna        quantidade de ordens remanejadas                                  |
//|                                                                                  |
//+----------------------------------------------------------------------------------+
int osc_minion_trade::remanejarOrdensPendentes( int order_signal, double valNear, double valFar, double lag_){
//                                                            +1         5541.5          5539.0         1   
//                                                            -1         5531.5          5532.0
//                                                            +1         5535.6          5534.1         1
   ulong  order_ticket;
   int qtdOrdensAlteradas = 0;
   double order_value, new_price;
   ENUM_ORDER_TYPE order_type;
   double lag = lag_*m_symb.TickSize();

//--- passando por todas as ordens pendentes 
   for( int i=OrdersTotal()-1; i>=0; i-- ){ 
      
      if( (order_ticket = OrderGetTicket(i) )  > 0          &&
           OrderGetString (ORDER_SYMBOL)      == m_symb_str &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)) 
        ){ 
           order_value = OrderGetDouble(ORDER_PRICE_OPEN);
           order_type  = (ENUM_ORDER_TYPE )OrderGetInteger(ORDER_TYPE );
           //Print(__FUNCTION__," Processando ", EnumToString(order_type), ", valor:",order_value,"...");
           
           if( order_signal == -1     && 
               order_value   > valFar &&
               order_type   == ORDER_TYPE_SELL_LIMIT ){
             
               new_price = findPrice(valNear,lag,order_signal*-1);
               if(new_price < order_value) alterarOrdem( order_type, new_price, OrderGetDouble(ORDER_VOLUME_CURRENT), order_ticket);
               qtdOrdensAlteradas++;
               //Print(__FUNCTION__," :-| :",m_symb_str,": ordem saida em:",order_value," alterada para ", new_price," !");
           }else{
               if( order_signal == +1     && 
                   order_value   < valFar &&
                   order_type   == ORDER_TYPE_BUY_LIMIT ){
                 
                   new_price = findPrice(valNear,lag,order_signal*-1);
                   if(new_price > order_value) alterarOrdem( order_type, new_price, OrderGetDouble(ORDER_VOLUME_CURRENT), order_ticket);
                   qtdOrdensAlteradas++; 
                   //Print(__FUNCTION__," :-| :",m_symb_str,": ordem saida em:",order_value," alterada para ", new_price," !");
               }
           }
      }
   }
   return qtdOrdensAlteradas;
}
//+---------------------------------------------------------------------+

// encontra um preco maior ou igual ao informado, no qual nao exista ordem pendente.
double osc_minion_trade::findPrice(double price_, double lag_, int signal_){
    
    double price = m_symb.NormalizePrice(price_+(lag_*signal_)); 
    
    while( tenhoOrdemPendente(price) ){
        //Print(__FUNCTION__,": Tenho ordem pendente no preco ", price,". Tentando proximo..." );
        price = m_symb.NormalizePrice(price + (lag_*signal_));
    }
    
    //Print(__FUNCTION__,": Encontrei preco sem ordem pendente ", price,"! Retornando..." );
    return price;
}

//+--------------------------------------------------------------------------------+
//| Se tiver ordem pendente sem stop no ativo que estamos operando, coloca o stop. |
//+--------------------------------------------------------------------------------+
void osc_minion_trade::colocarStopEmTodasAsOrdens(double stp){
   
   ulong order_ticket = 0    ;

//--- passaANDO por todas as ordens pendentes 
   for(int i=OrdersTotal()-1; i>=0; i--){ 
      m_order.SelectByIndex(i);
      if( (order_ticket = OrderGetTicket(i) )>0 && m_order.Symbol() == m_symb_str ){
          //Print(":-| osc_minion_trade: 1Colocando stop na ordem ", order_ticket, "...");
          colocarStopNaOrdem(order_ticket,stp);
      }
   }
}


//+------------------------------------------------------------------------------+
//| Coloca stop na ordem do ticket informado, se necessario. Sempre assincrono.  |
//+------------------------------------------------------------------------------+
bool osc_minion_trade::colocarStopNaOrdem(ulong ticket, double stp) {

   if( OrderSelect(ticket) && m_order.Select(ticket) ){
   
          if( m_order.StopLoss() != 0       ) return true  ;//{Print("ordem jah tem stop."     ); return true  ;} // ordem jah tem stop.
        //if( m_stp              == 0       ) return false ;//{Print("nao tenho stop definido."); return false ;} // nao tenho stop definido.
          
          // tem acontecido tentativas de colocar stop em ordens com valor zero. Acho que sao ordens nao limitadas. Verifique.
          if( m_order.PriceOpen() == 0      ){ 
              Print (__FUNCTION__," :-( Tentativa de colocar stop em ordem com PriceOpen zero. VERIFIQUE! Nao executarei!" );
              return false;
          }
   
          double priceStop = m_symb.NormalizePrice(m_order.PriceOpen()-stp);
          
          //if( m_order.Type()==ORDER_TYPE_SELL_STOP || m_order.Type()==ORDER_TYPE_SELL_LIMIT ){
          if( OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP || OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_LIMIT ){
             priceStop = m_symb.NormalizePrice(m_order.PriceOpen()+stp);
          }
          
          // Stop Loss
          //double priceStop = m_symbol.NormalizePrice(m_order.PriceOpen()-stp);
          //double priceStop =         NormalizeDouble(m_order.PriceOpen()-stp, _Digits);
   
          //string strtipo;
          //m_order.FormatType( strtipo,OrderGetInteger(ORDER_TYPE) );
          //Print("2Colocando stop na ordem ", ticket             , 
          //      " param stp:"              , stp                , 
          //      " open:"                   , m_order.PriceOpen(), 
          //      " stop:"                   , priceStop          , 
          //      " tipoordem:"              , strtipo            , 
          //      "..."                                           );
          bool sincro = m_async;
          m_async     = true;
          bool retorno = OrderModify(ticket                  ,
                                     m_order.PriceOpen()     ,
                                     priceStop               ,
                                     m_order.TakeProfit()    ,
                                     m_order.TypeTime()      ,
                                     m_order.TimeExpiration(),
                                     m_order.PriceStopLimit());
         m_async = sincro;
         return retorno;            
   }
   Print(__FUNCTION__,":-( ERRO colocarStopNaOrdem ticket=",ticket," ORDEM NAO ENCONTRADA!"); return false;   
   return false;
}

//+-------------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes, do simbolo informado cujo comentario eh um numero.     |
//+-------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensComComentarioNumerico(string symbol) {
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( OrderGetString(ORDER_SYMBOL ) == symbol && 
               OrderGetString(ORDER_COMMENT) != NULL   &&
              OrderGetInteger(ORDER_STATE  ) == ORDER_STATE_PLACED   ){                     
          
               string strComentarioNumerico = OrderGetString(ORDER_COMMENT);
               long      comentarioNumerico = StringToInteger(strComentarioNumerico);          
              
               // se o comentario da ordem eh um numero, entao a cancelamos...
               if( MathIsValidNumber(comentarioNumerico) && comentarioNumerico != 0 ){ 
                   Print(":-| ",__FUNCTION__ ,"(",symbol,") :-| Canc #",order_ticket," #state ", stateOrderToString()," coment=(", strComentarioNumerico, ") asyn");   
                   cancelarOrdem(order_ticket); 
               }
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}

//+---------------------------------------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes, do simbolo informado cujo comentario eh um numero e seja do tipo informado.|
//+---------------------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensComComentarioNumerico(string symbol, ENUM_ORDER_TYPE tipo) {
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( OrderGetInteger(ORDER_TYPE   ) == tipo   &&
                OrderGetString(ORDER_SYMBOL ) == symbol && 
                OrderGetString(ORDER_COMMENT) != NULL   &&
               OrderGetInteger(ORDER_STATE  ) == ORDER_STATE_PLACED   ){                     
          
               string strComentarioNumerico = OrderGetString(ORDER_COMMENT);
               long      comentarioNumerico = StringToInteger(strComentarioNumerico);          
              
               // se o comentario da ordem eh um numero, entao a cancelamos...
               if( MathIsValidNumber(comentarioNumerico) && comentarioNumerico != 0 ){ 
                   //Print(":-| ",__FUNCTION__ ,"(",symbol,",",EnumToString(tipo),") :-| Canc #",order_ticket," #state ", stateOrderToString(), " coment=(", strComentarioNumerico, ") asyn");   
                   cancelarOrdem(order_ticket); 
               }
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}
//+------------------------------------------------------------------------------------------------+

//+------------------------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes, do tipo informado e com simbolo configurado nesta instancia.|
//| e que tenham uma ou mais ordens no mesmo preco                                                 |
//+------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensDuplicadas(ENUM_ORDER_TYPE tipo) {
   ulong order_ticket; 
   ulong ticket2; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( OrderGetInteger(ORDER_TYPE   ) == tipo       &&
                OrderGetString(ORDER_SYMBOL ) == m_symb_str && 
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))   ){                     
                   
                   ticket2 = tenhoOrdemPendente(OrderGetDouble(ORDER_PRICE_OPEN), tipo, order_ticket);
                   
                   if( ticket2 > order_ticket ){
                       Print(":-| ",__FUNCTION__ ,"(",EnumToString(tipo),") Canc #",ticket2, " #state ", stateOrderToString(), " asyn");   
                       cancelarOrdem(ticket2); 
                   }else{
                       if(ticket2 > 0 ){
                           Print(":-| ",__FUNCTION__ ,"(",EnumToString(tipo),") Canc #",order_ticket, " #state ", stateOrderToString(), " asyn");   
                           cancelarOrdem(order_ticket); 
                       }
                   }
           }
      }
   }
}
//+------------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes, do tipo informado e com simbolo configurado nesta instancia.|
//+------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdens(ENUM_ORDER_TYPE tipo) {
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( OrderGetInteger(ORDER_TYPE   ) == tipo        &&
                OrderGetString(ORDER_SYMBOL ) == m_symb_str  && 
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
                                                                                  ){                     
          
              
                   //Print(":-| ",__FUNCTION__ ,"(",EnumToString(tipo),") Canc #",order_ticket," #state ", stateOrderToString()," asyn");   
                   cancelarOrdem(order_ticket); 
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}
//+------------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes, do tipo informado, com simbolo configurado nesta instancia e|
//| iniciando com o comentario informado.                                                          |
//+------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdens(ENUM_ORDER_TYPE tipo, string comment) {
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( OrderGetInteger(ORDER_TYPE   ) == tipo        &&
                OrderGetString(ORDER_SYMBOL ) == m_symb_str  && 
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1 &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
                                                                                  ){                     
          
              
                   //Print(":-| ",__FUNCTION__ ,"(",EnumToString(tipo),") Canc #",order_ticket," #state ", stateOrderToString()," asyn");   
                   cancelarOrdem(order_ticket); 
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}
//+------------------------------------------------------------------------------------------------+

//+------------------------------------------------------------------------------------------------+
//| cancela ordens pendentes que atendem aos parametros, exceto o ticket informado em ticketExcept.|
//+------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdens(string symbol, ENUM_ORDER_TYPE tipo, string comment, ulong ticketExcept=0){
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if(  order_ticket                  != ticketExcept &&
               OrderGetInteger(ORDER_TYPE   ) == tipo         &&
                OrderGetString(ORDER_SYMBOL ) == symbol       &&
    StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1  &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
                                                                                  ){                     
                   //Print(":-| ",__FUNCTION__ ,"(",symbol,",",EnumToString(tipo),",",comment,",",ticketExcept,") Canc #",order_ticket," #state ", stateOrderToString()," asyn");   
                   cancelarOrdem(order_ticket); 
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}
//+------------------------------------------------------------------------------------------------+

//+--------------------------------------------------------------------------------------------------------------------+
//| cancela todas as ordens pendentes do simbolo informado nesta instanacia, exceto o ticket informado em ticketExcept.|
//+--------------------------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdens(ulong ticketExcept=0){
   ulong order_ticket;
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes
   for(int i=0; i<qtdOrdensPendentes; i++){

      if( (order_ticket = OrderGetTicket(i) ) > 0 ){

           if(  order_ticket                  != ticketExcept &&
//             OrderGetInteger(ORDER_TYPE   ) == tipo         &&
                OrderGetString(ORDER_SYMBOL ) == m_symb_str   &&
//  StringFind(OrderGetString (ORDER_COMMENT ),comment) > -1  &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
                                                                                  ){
                   //Print(":-| ",__FUNCTION__ ,"(",symbol,",",EnumToString(tipo),",",comment,",",ticketExcept,") Canc #",order_ticket," #state ", stateOrderToString()," asyn");
                   cancelarOrdem(order_ticket);
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}
//+------------------------------------------------------------------------------------------------+

//+----------------------------------------------------------------------------------------------------------------------+
//| Cancela todas as ordens de compra pendentes, menores que valor informado e com o simbolo configurado nesta instancia.|
//+----------------------------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensDeCompraMenoresQue(double valor){
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if(  OrderGetDouble(ORDER_PRICE_OPEN)  < valor                     && // valor
                OrderGetString(ORDER_SYMBOL    ) == m_symb_str                && 
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)) &&
               OrderGetInteger(ORDER_TYPE)       == ORDER_TYPE_BUY_LIMIT         ){    
               
               //Print(":-| ",__FUNCTION__ ,"(",valor,") Canc #",order_ticket, " #state ", stateOrderToString(), " asyn");   
               cancelarOrdem(order_ticket); 
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}
//+------------------------------------------------------------------------------------------------+

//+----------------------------------------------------------------------------------------------------------------------+
//| Cancela todas as ordens de venda pendentes, maiores que valor informado e com o simbolo configurado nesta instancia. |
//+----------------------------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensDeVendaMaioresQue(double valor){
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( OrderGetDouble (ORDER_PRICE_OPEN)  > valor                     &&
                OrderGetString(ORDER_SYMBOL    ) == m_symb_str                && 
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)) &&
               OrderGetInteger(ORDER_TYPE)       == ORDER_TYPE_SELL_LIMIT     ){
                                    
                   //Print(":-| ",__FUNCTION__ ,"(",valor,") Canc #",order_ticket, " #state ", stateOrderToString(), " asyn");   
                   cancelarOrdem(order_ticket); 
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}
//+------------------------------------------------------------------------------------------------+

//+-------------------------------------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes, menores que valor informado e com o simbolo configurado nesta instancia. |
//| in  ENUM_ORDER_TYPE type        : tipo de ordem
//| in  double          valor       : valor limite
//| in  bool            igual_tambem: true - cancela tambem as ordens com o valor limite.
//| out void
//+-------------------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensMenoresQue( ENUM_ORDER_TYPE type, double valor, bool igual_tambem=true){
   ulong order_ticket;
   int qtdOrdensPendentes = OrdersTotal();
   double preco_ord;

//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if(   OrderGetInteger(ORDER_TYPE)       == type          &&
                 OrderGetString (ORDER_SYMBOL    ) == m_symb_str    && 
             orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))   ){
                                    
                   preco_ord = OrderGetDouble (ORDER_PRICE_OPEN);

                   if( (preco_ord <= valor &&  igual_tambem) ||
                       (preco_ord <  valor && !igual_tambem)  ) cancelarOrdem(order_ticket); 
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}
//+------------------------------------------------------------------------------------------------+
//+-------------------------------------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes, maiores que valor informado e com o simbolo configurado nesta instancia. |
//| in  ENUM_ORDER_TYPE type        : tipo de ordem
//| in  double          valor       : valor limite
//| in  bool            igual_tambem: true - cancela tambem as ordens com o valor limite.
//| out void
//+-------------------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensMaioresQue( ENUM_ORDER_TYPE type, double valor, bool igual_tambem=true){
   ulong order_ticket;
   int qtdOrdensPendentes = OrdersTotal();
   double preco_ord;
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if(   OrderGetInteger(ORDER_TYPE)       == type          &&
                 OrderGetString (ORDER_SYMBOL    ) == m_symb_str    && 
             orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))   ){
                   
                   preco_ord = OrderGetDouble (ORDER_PRICE_OPEN);
                   
                   if( (preco_ord >= valor &&  igual_tambem) ||
                       (preco_ord >  valor && !igual_tambem)  ) cancelarOrdem(order_ticket); 
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO REMOCAO ORDEM ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
}
//+------------------------------------------------------------------------------------------------+

//+------------------------------------------------+
//| Cancela ordem de maior valor do tipo informado |
//+------------------------------------------------+
void osc_minion_trade::cancelarMaiorOrdemDoTipo(ENUM_ORDER_TYPE order_type){

   ulong order_ticket;
   double valor = 0;
   
   double maior_valor = 0;
   ulong  order_ticket_maior_valor = 0;
   
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( 
                OrderGetString (ORDER_SYMBOL    ) == m_symb_str && 
                OrderGetInteger(ORDER_TYPE      ) == order_type &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
                    ){
                   valor = OrderGetDouble(ORDER_PRICE_OPEN);
                   
                   if(valor > maior_valor) {
                       maior_valor=valor;
                       order_ticket_maior_valor=order_ticket;
                   }
           }
      }else{
           Print(":-( ", __FUNCTION__,"(",order_type,") :-( ERRO ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }   
   if( maior_valor > 0){ 
       //Print(":-( ", __FUNCTION__,"(",order_type,") Cancelando ordem:",order_ticket, " com valor:",maior_valor,"...");
       cancelarOrdem(order_ticket_maior_valor);
   }else{
       Print(":-( ", __FUNCTION__,"(",order_type,") Nao encontrei ordem para cancelar! Verifique!");
   }
}
//+------------------------------------------------------------------------------------------------+

//+------------------------------------------------+
//| Cancela ordem de menor valor do tipo informado |
//+------------------------------------------------+
void osc_minion_trade::cancelarMenorOrdemDoTipo(ENUM_ORDER_TYPE order_type){

   ulong order_ticket;
   double valor = 0;
   
   double menor_valor = 0;
   ulong  order_ticket_menor_valor=0;
   
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( 
                OrderGetString (ORDER_SYMBOL    ) == m_symb_str && 
                OrderGetInteger(ORDER_TYPE      ) == order_type &&
           orderStatePendente((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE))
                    ){
                   valor = OrderGetDouble(ORDER_PRICE_OPEN);
                   
                   if(valor < menor_valor || menor_valor==0){ 
                       menor_valor=valor;
                       order_ticket_menor_valor = order_ticket;
                   }
           }
      }else{
           Print(":-( ", __FUNCTION__,"(",order_type,") :-( ERRO ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }   
   if( menor_valor > 0){
       //Print(":-( ", __FUNCTION__,"(",order_type,") Cancelando ordem:",order_ticket, " com valor:",menor_valor,"...");
       cancelarOrdem(order_ticket_menor_valor);
   }else{
       Print(":-( ", __FUNCTION__,"(",order_type,") Nao encontrei ordem para cancelar! Verifique!");
   }
}
//+------------------------------------------------------------------------------------------------+


//+----------------------------------------------------------------------------------------------------+
//| Trata-se de uma forma de fechamento de posicao. Funciona no esquema de ordens pendentes            |
//| nas quais colocamos o ticket da ordem que estah sendo fechada no comentario da ordem de fechamento.|
//| A estrategia eh trazer estas ordens que tem comentario numerico a seu valor presente.              |
//| Se todas as ordens forem executadas a posicao serah fechada, senao, esperamos que fiquem           |
//| poucas ordens pendentes.                                                                           |
//+----------------------------------------------------------------------------------------------------+
void osc_minion_trade::trazerOrdensComComentarioNumerico2valorPresente(string symbol, int qtdTicksDeslocamento=0) {

   if( !PositionSelect(symbol) ){
       Print(__FUNCTION__,"(",symbol,",",qtdTicksDeslocamento, ") :-( Nao ha posicao aberta!");      
   }   
   
   ulong            order_ticket; 
   ENUM_ORDER_STATE order_state;
   int              qtdOrdensPendentes = OrdersTotal();
   double           valor_presente = 0;  
   //ENUM_ORDER_TYPE order_type;
   double tick_size = SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);

   // definindo o valor presente em funcao da posicao ser comprado ou vendido...
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
      valor_presente = SymbolInfoDouble(symbol,SYMBOL_BID)+(tick_size*qtdTicksDeslocamento);
   }else{
      valor_presente = SymbolInfoDouble(symbol,SYMBOL_ASK)-(tick_size*qtdTicksDeslocamento);
   }
   
   double precoAtual           ;
   long   comentarioNumerico   ;
   string strComentarioNumerico;

//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
           if( OrderGetString(ORDER_SYMBOL)  == symbol && 
               OrderGetString(ORDER_COMMENT) != NULL   &&
                    order_state              == ORDER_STATE_PLACED     ){ // 10/06/2020 evitando alterar ordens em estado de pendencia
          
               strComentarioNumerico = OrderGetString(ORDER_COMMENT);
               comentarioNumerico    = StringToInteger(strComentarioNumerico);
               precoAtual            = OrderGetDouble(ORDER_PRICE_OPEN);
              
               // se o comentario da ordem eh um numero, entao alteramos para o valor atual...
               if( MathIsValidNumber(comentarioNumerico) && comentarioNumerico != 0 ){ 
                   if( precoAtual != valor_presente ){
                       Print(":-| ",__FUNCTION__ ,"(",symbol,") :-| Alter #",order_ticket," #state ", stateOrderToString()," coment=(", strComentarioNumerico, ") asyn");
                       alterarOrdem( (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE), valor_presente, OrderGetDouble(ORDER_VOLUME_CURRENT), order_ticket, "STOP_VP");
                       //if( !alterarOrdem( (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE), valor_presente, OrderGetDouble(ORDER_VOLUME_CURRENT), order_ticket, "STOP_VP") ){
                       //    Print(":-( ", __FUNCTION__,"(",symbol,",",qtdTicksDeslocamento,",",deep,") ERRO ALTER ORDEM ticket=",order_ticket," IND=", i," PRECO_ATUAL=",precoAtual, " VAL_PRESENTE=", valor_presente);
                       //    if( deep==1 ){
                       //        trazerOrdensComComentarioNumerico2valorPresente(symbol, qtdTicksDeslocamento, 2);
                       //    }
                       //    return;
                       //}
                   }
               }
           }
      }else{
           Print(" :-( ",__FUNCTION__," ERRO ALTER ORDEM ticket=",order_ticket," IND=", i, " ORDEM NAO ENCONTRADA!");
           
           // Diminuindo a quantidade de erros quando tenta trazer muitas ordens a valor presente, mas as mesmas jah foram executadas.
           // Visa evitar erros "Too many trade requests" que acontecem apos muitos erros de ordem nao encontrada.
           // testar online dia 08/06/2020 na conta demo. 
           //if( deep==1 ){
           //    trazerOrdensComComentarioNumerico2valorPresente(symbol, qtdTicksDeslocamento, 2);
           //}
           return;
      }
   }
}

//+----------------------------------------------------------------------------------------------------+
//| Trata-se de uma forma de alteracao do preco de fechamento da posicao. Funciona no esquema de ordens|
//| pendentes nas quais colocamos o ticket da ordem que estah sendo fechada no comentario da ordem de  |
//| fechamento.                                                                                        |
//| Foi feita inicialmente para controlar risco, trazendo o valor de saida da posicao para proximo do  |
//| breakeven em funcao de criterios avaliados pela estrategia de controle de risco.                   |
//+----------------------------------------------------------------------------------------------------+
bool osc_minion_trade::alterarValorDeOrdensNumericasPara(string symbol,double novoValor, double valorPosicao) {

   if(!PositionSelect(symbol)){
       Print(__FUNCTION__,"(",symbol,",",novoValor,",",valorPosicao, ") :-( Nao ha posicao aberta!");      
       return false;
   }
   ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double tick_size = SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);

   string strComentarioNumerico = "";
   long      comentarioNumerico = 0 ;
   double valorAnt              = 0 ;
   novoValor                    = m_symb.NormalizePrice( novoValor );

   ulong            order_ticket; 
   ENUM_ORDER_STATE order_state ;
   ENUM_ORDER_TYPE  order_type  ;
   
//--- passar por todas as ordens pendentes 
   int qtdOrdensPendentes = OrdersTotal();
   for(int i=0; i<qtdOrdensPendentes; i++){
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
           if( OrderGetString(ORDER_SYMBOL)  == symbol && 
               OrderGetString(ORDER_COMMENT) != NULL   &&
               order_state                   == ORDER_STATE_PLACED     ){ // testando alteracao apenas de ordens aceitas
               //order_state                 != ORDER_STATE_FILLED   && // ordens executadas nao podem ser alteradass
          
               strComentarioNumerico = OrderGetString(ORDER_COMMENT);
               comentarioNumerico    = StringToInteger(strComentarioNumerico);          
              
               // se o comentario da ordem eh um numero, entao alteramos para o valor atual...
               if( MathIsValidNumber(comentarioNumerico) && comentarioNumerico != 0 ){ 

                   valorAnt = m_symb.NormalizePrice( OrderGetDouble(ORDER_PRICE_OPEN) );
                   if( valorAnt != novoValor ){
                   
                       order_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
                   
                     //if( position_type == POSITION_TYPE_BUY && novoValor < valorAnt && order_type==ORDER_TYPE_SELL_LIMIT ){
                       if( position_type == POSITION_TYPE_BUY                         && order_type==ORDER_TYPE_SELL_LIMIT ){
                           Print(":-| ",__FUNCTION__ ,"(",symbol,",",novoValor,") Alter #",order_ticket," #state ", stateOrderToString()," [coment=", strComentarioNumerico,",valorAnt=",valorAnt,"] asyn");
                           alterarOrdem( order_type, novoValor, OrderGetDouble(ORDER_VOLUME_CURRENT), order_ticket);
                       }else{
                         //if( position_type == POSITION_TYPE_SELL && novoValor > valorAnt && order_type==ORDER_TYPE_BUY_LIMIT ){
                           if( position_type == POSITION_TYPE_SELL                         && order_type==ORDER_TYPE_BUY_LIMIT ){
                               Print(":-| ",__FUNCTION__ ,"(",symbol,",",novoValor,") Alter #",order_ticket," #state ", stateOrderToString()," [coment=", strComentarioNumerico,",valorAnt=",valorAnt,"] asyn");
                               alterarOrdem( order_type, novoValor, OrderGetDouble(ORDER_VOLUME_CURRENT), order_ticket);
                           }
                       }
                   }
               }
           }
      }
   }//for
   
   return true;
}

//+----------------------------------------------------------------------------------------------------+
//| Trata-se de uma forma de alteracao do preco de fechamento da posicao. Funciona no esquema de ordens|
//| pendentes nas quais colocamos o ticket da ordem que estah sendo fechada no comentario da ordem de  |
//| fechamento.                                                                                        |
//| Foi feita inicialmente para controlar risco, trazendo o valor de saida da posicao para proximo do  |
//| breakeven em funcao de criterios avaliados pela estrategia de controle de risco.                   |
//+----------------------------------------------------------------------------------------------------+
bool osc_minion_trade::trazerOrdensFechamentoPosicaoPara(double novoValor) {

   if(!PositionSelect(m_symb_str)){
       Print(__FUNCTION__,"(",novoValor,") :-( Nao ha posicao aberta no ticker ", m_symb_str);      
       return false;
   }
   ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double tick_size = SymbolInfoDouble(m_symb_str,SYMBOL_TRADE_TICK_SIZE);

   string strComentarioNumerico = "";
   long      comentarioNumerico = 0 ;
   double valorAnt              = 0 ;
   novoValor                    = m_symb.NormalizePrice( novoValor );

   ulong            order_ticket; 
   ENUM_ORDER_STATE order_state ;
   ENUM_ORDER_TYPE  order_type  ;
   
//--- passar por todas as ordens pendentes 
   int qtdOrdensPendentes = OrdersTotal();
   for(int i=0; i<qtdOrdensPendentes; i++){
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
           if( OrderGetString(ORDER_SYMBOL)  == m_symb_str && 
               order_state                   == ORDER_STATE_PLACED     ){ // testando alteracao apenas de ordens aceitas
          
               valorAnt = m_symb.NormalizePrice( OrderGetDouble(ORDER_PRICE_OPEN) );
               if( valorAnt != novoValor ){
               
                   order_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
               
                   if( position_type == POSITION_TYPE_BUY  && order_type==ORDER_TYPE_SELL_LIMIT ){
                       Print(":-| ",__FUNCTION__ ,"(",novoValor,") Alter #",order_ticket," #state ", stateOrderToString()," [coment=", strComentarioNumerico,",valorAnt=",valorAnt,"] asyn");
                       alterarOrdem( order_type, novoValor, OrderGetDouble(ORDER_VOLUME_CURRENT), order_ticket);
                   }else{
                     //if( position_type == POSITION_TYPE_SELL && novoValor > valorAnt && order_type==ORDER_TYPE_BUY_LIMIT ){
                       if( position_type == POSITION_TYPE_SELL                         && order_type==ORDER_TYPE_BUY_LIMIT ){
                           Print(":-| ",__FUNCTION__ ,"(",novoValor,") Alter #",order_ticket," #state ", stateOrderToString()," [coment=", strComentarioNumerico,",valorAnt=",valorAnt,"] asyn");
                           alterarOrdem( order_type, novoValor, OrderGetDouble(ORDER_VOLUME_CURRENT), order_ticket);
                       }
                   }
               }
           }
      }
   }//for
   
   return true;
}


//+-----------------------------------------------------------+
//| Cancela todas as ordens pendentes do ticker configurado.  |
//+-----------------------------------------------------------+
void osc_minion_trade::cancelarOrdens(string comentario) {
   ulong order_ticket; 
   int totOrdens = OrdersTotal();

//--- passar por todas as ordens pendentes 
 //for(int i=OrdersTotal()-1; i>=0; i--){ 
   for(int i=0; i<totOrdens; i++){     // assim processa primeiro as mais antigas

      if( (order_ticket = OrderGetTicket(i) )>0 ){

          //order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
          if( OrderGetString(ORDER_SYMBOL) == m_symb.Name() && OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED ) {

              //Print(":-| ", __FUNCTION__, "(", comentario, ") Canc #", order_ticket, " #state ", stateOrderToString(), " asyn");
              cancelarOrdem(order_ticket);

              /*
              MqlTradeResult  result  = { 0 };
              MqlTradeRequest request = { 0 };

              request.order = order_ticket;
              request.action = TRADE_ACTION_REMOVE;

              //--- envio do pedido
              // 27/12/2019: cancelamento de ordens passa a ser assincrono.
              //if( m_async ){
              
              //------------------------------------------------------------
              // verificando se ordem de cancelamento jah foi enviada...
              //------------------------------------------------------------
              if( !permiteCancelarOrdem(order_ticket) ) continue;
              //------------------------------------------------------------
              
              Print(":-| ", __FUNCTION__, "(", comentario, ") :-| Canc #", order_ticket, " asyn");
              if (!OrderSendAsync(request, result)) {
                  addOrdem(request,result);
                  Print(":-( ", __FUNCTION__, "(", comentario, ",", deep, ") :-( REMOCAO ERRO OrderSendAsync ", GetLastError(), ":", result.retcode, ":", result.comment, " order=", order_ticket);

                  //if( result.retcode == TRADE_RETCODE_TOO_MANY_REQUESTS ){
                  //    Print(__FUNCTION__,"(",comentario,":",deep,")"," :-( Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms..."  );
                  //    Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
                  //}

                  if (deep == 1) {
                      Print(":-( ", __FUNCTION__, "(", comentario, ",", deep, ") :-( Aguardando ", M_TIME_SLEEP_MANY_REQUESTS, "ms e passando controle para execucao da segunda chamada...");
                      Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
                      cancelarOrdens(comentario, 2);
                  }
                  return;
              }

              // ordem de cancelamento foi submetida, entao guardamos para posterior verificacao
              addOrdem(request,result);
              */
              
          }
      }
   }
}

//+-----------------------------------------------------------+
//| Cancela todas as ordens pendentes do tipo informado       |
//+-----------------------------------------------------------+
void osc_minion_trade::cancelarOrdensDoTipo(ENUM_ORDER_TYPE tipo) {
   ulong            order_ticket; 
   int totOrdens = OrdersTotal();

//--- passar por todas as ordens pendentes 
 //for(int i=OrdersTotal()-1; i>=0; i--){ 
   for(int i=0; i<totOrdens; i++){     // assim processa primeiro as mais antigas
      
    //order_state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);

      if( (order_ticket = OrderGetTicket(i) )  > 0                  &&
           OrderGetString (ORDER_SYMBOL    )  == m_symb.Name()      &&
           OrderGetInteger(ORDER_TYPE)        == tipo               &&
           OrderGetInteger(ORDER_STATE)       == ORDER_STATE_PLACED    
                                                                      ){ 
          //Print(":-| ", __FUNCTION__, "(", tipo, ") Canc #", order_ticket," #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket);
      }
   }
}

//+-------------------------------------------------------------+
//| Cancela todas as ordens pendentes do tipo e valor informados|
//+-------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensPorTipoEvalor(ENUM_ORDER_TYPE tipo, double valor){
   ulong            order_ticket; 
   int totOrdens = OrdersTotal();

//--- passar por todas as ordens pendentes 
   for(int i=0; i<totOrdens; i++){     // assim processa primeiro as mais antigas
      
      if( (order_ticket = OrderGetTicket(i) )  > 0                  &&
           OrderGetString (ORDER_SYMBOL    )  == m_symb.Name()      &&
           OrderGetInteger(ORDER_TYPE      )  == tipo               &&
           OrderGetDouble (ORDER_PRICE_OPEN)  == valor              &&           
           OrderGetInteger(ORDER_STATE     )  == ORDER_STATE_PLACED    
                                                                      ){ 
          //Print(":-| ", __FUNCTION__, "(", tipo, ") Canc #", order_ticket, " #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket);
      }
   }
}


//+--------------------------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes que nao tenham o texto(parametro) como parte do seu comentario.|
//+--------------------------------------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensExcetoComTxt(string txtNaoCancelar, string comentario ) {
   ulong order_ticket;
   int totOrdens = OrdersTotal();

//--- passar por todas as ordens pendentes 
 //for(int i=OrdersTotal()-1; i>=0; i--){ 
   for(int i=0; i<totOrdens; i++){     // assim processa primeiro as mais antigas
      
      if( (order_ticket = OrderGetTicket(i) )>0  && 
           OrderGetString(ORDER_COMMENT) != NULL && // NAO CANCELA ORDENS SEM COMENTARIO (colocadas manualmente)
           OrderGetString(ORDER_COMMENT) != ""   && // NAO CANCELA ORDENS SEM COMENTARIO (colocadas manualmente)
           
          StringFind( OrderGetString(ORDER_COMMENT),txtNaoCancelar) < 0 ){ 
          //Print(":-| ", __FUNCTION__, "(",txtNaoCancelar,",",comentario,") Canc #", order_ticket, " #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket);
//        MqlTradeResult  result ={0}; 
//        MqlTradeRequest request={0}; 
//        
//        request.order   = order_ticket; 
//        request.action  = TRADE_ACTION_REMOVE; 
//       
//        //--- envio do pedido assincrono
//        // 27/12/2019: cancelamento de ordens passa a ser assincrono.
//        //Print(":-| ",__FUNCTION__ ,"(",txtNaoCancelar,",",comentario,") :-| Canc #", order_ticket, " asyn");   
//        if(!OrderSendAsync(request,result)){
//           Print(__FUNCTION__,"(",txtNaoCancelar,",",comentario,",",deep,") :-( REMOCAO ERRO OrderSendAsync ",GetLastError(),":",result.retcode,":",result.comment, " order=",order_ticket);  // se não for possível enviar o pedido, exibir um código de erro
//           //if( result.retcode == TRADE_RETCODE_TOO_MANY_REQUESTS ){
//           //    Print(__FUNCTION__,"(",txtNaoCancelar,",",comentario,",",deep,")"," :-( Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms..."  );
//           //    Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
//           //}
//
//           if( deep == 1 ){
//               Print(__FUNCTION__,"(",txtNaoCancelar,",",comentario,",",deep,") :-| Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms e passando controle para execucao da segunda chamada...");
//               Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
//               cancelarOrdensExcetoComTxt(txtNaoCancelar,comentario,2);
//           }
//           return;
//        }
      }
   }
}


//+---------------------------------------------------------------------+
//| Cancela todas as ordens pendentes que tenham o comentario informado.|
//| A partir de 20/12/2019 passa a cancelar ordens que contenham a      |
//| a string informada como parte do seu comentario.                    | 
//|                                                                     | 
//| A partir de 27/12/2019 cancelamento passa a ser assincrono.         |
//|                                                                     | 
//| A partir de 30/01/2020 passa a cancelar ordens que sejam do simbolo |
//| informado.                                                          | 
//|                                                                     | 
//| A partir de 20/09/2020:passa a verificar se jah foi enviado pedido  |
//|  - Passa a verificar se jah foi enviado pedido de cancelamento antes| 
//|    de enviar novo pedido.                                           | 
//|  - Passa a nao mais executar duas vezes em caso de erro na primeira | 
//|    execucao. Esperamos nao ser mais necessario devido a verificacao |
//|    de pedido acima.                                                 | 
//|  - Passa a enviar pedidos de cancelamento somente para ordens em    | 
//|    estado ORDER_STATE_PLACED, visando menos rejeicoes por tentativa |
//|    de cancelar ordens em status que nao permitem cancelamento.      | 
//+---------------------------------------------------------------------+
void osc_minion_trade::cancelarOrdensComentadas(string symbol, string comentario) {
   ulong order_ticket; 
   int totOrdens = OrdersTotal();

//--- passar por todas as ordens pendentes 
 //for(int i=OrdersTotal()-1; i>=0; i--){ 
   for(int i=0; i<totOrdens; i++){  // assim processa primeiro as mais antigas
      
      if( (order_ticket = OrderGetTicket(i) )                        > 0      &&
                          OrderGetString(ORDER_SYMBOL )             == symbol &&  // ADICIONADO EM 30/01/2020
              StringFind( OrderGetString(ORDER_COMMENT),comentario)  > -1     &&
                         OrderGetInteger(ORDER_STATE)               == ORDER_STATE_PLACED ){ // add em 20/09/2020 
      
          //Print(":-| ", __FUNCTION__, "(", comentario, ") Canc #", order_ticket, " #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket); // add em 21/09/2020 e comentado trecho abaixo
          /*
          MqlTradeResult  result ={0}; 
          MqlTradeRequest request={0}; 
          
          request.order   = order_ticket; 
          request.action  = TRADE_ACTION_REMOVE; 
         
          //--- envio do pedido
          // 27/12/2019: cancelamento de ordens passa a ser assincrono.
          if(!OrderSendAsync(request,result)){
             Print(__FUNCTION__,"(",symbol,",",comentario,",",deep,") :-( REMOCAO ERRO OrderSendAsync ",GetLastError(),":",result.retcode,":",result.comment, " order=", order_ticket);  // se não for possível enviar o pedido, exibir um código de erro

             if( deep == 1 ){
                 Print(__FUNCTION__,"(",symbol,",",comentario,",",deep,") :-| Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms e passando controle para segunda chamada...");
                 Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
                 cancelarOrdensComentadas(symbol,comentario,2);
             }
             return;
          }
          */
      }
   }
}

//+-------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes de compra, do simbolo informado,            |
//| que tenham o comentario informado.                                            |
//| A partir de 21/01/2020 passa a cancelar ordens que contenham a                |
//| a string informada como parte do seu comentario.                              | 
//+-------------------------------------------------------------------------------+
bool osc_minion_trade::cancelarOrdensComentadasDeCompra(string symbol, string comentario) {
   ulong order_ticket; 
   int totOrdens = OrdersTotal();

   //--- passar por todas as ordens pendentes 
   for(int i=0; i<totOrdens; i++){  // assim processa primeiro as mais antigas
      
      if( (order_ticket = OrderGetTicket(i) ) > 0                && 
             OrderGetString (ORDER_SYMBOL) == symbol             &&  // ADICIONADO EM 21/01/2020
             OrderGetInteger(ORDER_STATE)  == ORDER_STATE_PLACED &&
 StringFind( OrderGetString (ORDER_COMMENT),comentario) > -1     &&
           ( OrderGetInteger(ORDER_TYPE)   == ORDER_TYPE_BUY_LIMIT  )
         ){ 
          //Print(":-| ", __FUNCTION__, "(",symbol,",",comentario,") Canc #", order_ticket, " #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket); // add em 21/09/2020 e comentado trecho abaixo
      }
   }//for
   return true;
}

//+------------------------------------------------------------------------------+
//| Cancela todas as ordens pendentes de venda, do simbolo informado,            |
//| que tenham o comentario informado.                                           |
//| A partir de 20/12/2019 passa a cancelar ordens que contenham a               |
//| a string informada como parte do seu comentario.                             | 
//+------------------------------------------------------------------------------+
bool osc_minion_trade::cancelarOrdensComentadasDeVenda(string symbol, string comentario) {
   ulong order_ticket; 
   int totOrdens = OrdersTotal();

   //--- passar por todas as ordens pendentes 
   for(int i=0; i<totOrdens; i++){  // assim processa primeiro as mais antigas
      
      if( (order_ticket = OrderGetTicket(i) ) > 0          && 
             OrderGetString (ORDER_SYMBOL)   == symbol     &&  // ADICIONADO EM 21/01/2010
             OrderGetInteger(ORDER_STATE)    == ORDER_STATE_PLACED &&
 StringFind( OrderGetString (ORDER_COMMENT),comentario) > -1 &&
           ( OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_SELL_LIMIT  )
         ){ 
          //Print(":-| ", __FUNCTION__, "(",symbol,",",comentario,") Canc #", order_ticket, " #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket); // add em 21/09/2020 e comentado trecho abaixo
      }
   } // for sobre total de ordens...
   
   return true;
   
}

//+-------------------------------------------------------------------------------+
//| Cancela ordens pendentes de venda, do simbolo, valor e comentario informados. |
//+-------------------------------------------------------------------------------+
bool osc_minion_trade::cancelarOrdensComentadasDeVenda(string symbol, string comentario, double valor) {
   ulong order_ticket; 
   int totOrdens = OrdersTotal();

//--- passar por todas as ordens pendentes 
 //for(int i=OrdersTotal()-1; i>=0; i--){ 
   for(int i=0; i<totOrdens; i++){  // assim processa primeiro as mais antigas
      
      if( ( order_ticket = OrderGetTicket(i) ) > 0         && 
             OrderGetString(ORDER_SYMBOL)     == symbol   && // simbolo
            OrderGetInteger(ORDER_STATE)      == ORDER_STATE_PLACED &&
             OrderGetDouble(ORDER_PRICE_OPEN) == valor    && // valor
 StringFind( OrderGetString (ORDER_COMMENT),comentario) > -1 &&  // comentario
           ( OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_SELL_LIMIT      || // venda
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_SELL            ||
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_SELL_STOP       ||
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_SELL_STOP_LIMIT  )
         ){ 
          Print(":-| ", __FUNCTION__, "(",symbol,",",comentario,",",valor,") Canc #", order_ticket, " #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket); // add em 21/09/2020 e comentado trecho abaixo

          /*
          MqlTradeResult  result ={0}; 
          MqlTradeRequest request={0}; 
          
          request.order   = order_ticket; 
          request.action  = TRADE_ACTION_REMOVE; 
         
          //--- envio do pedido assincrono
        //Print(":-| ",__FUNCTION__ ,"(",symbol,",",comentario,") :-| Canc #", order_ticket, " asyn");
          if(!OrderSendAsync(request,result)){
             Print(__FUNCTION__,"(",symbol,",",comentario,",",valor,",",deep,") :-( REMOCAO ERRO OrderSendAsync ",GetLastError(), ":", result.retcode,":",result.comment, " order=", order_ticket);  // se não for possível enviar o pedido, exibir um código de erro
             //if( result.retcode == TRADE_RETCODE_TOO_MANY_REQUESTS ){
             //    Print(__FUNCTION__,"(",symbol,",",comentario,",",valor,")"," :-( Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms..."  );
             //    Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
             //}
             if( deep == 1 ){
                 Print(__FUNCTION__,"(",symbol,",",comentario,",",valor,",",deep,")"," :-( Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms e passando controle para segunda chamada..."  );
                 Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
                 cancelarOrdensComentadasDeVenda(symbol, comentario, valor, 2);
             }
             return false; // se retornou aqui, eh porque encontrou ordens a cancelar e chegou a ter algum problema, mesmo que
                           // tenha conseguido cancelar as ordens.

          }else{
             Print(":-| ",__FUNCTION__ ,"(",symbol,",",comentario,",",valor,",",deep,") :-| Canc #", order_ticket, " asyn");
          }
          */
      }
   }// for
   return true;
}

//+-------------------------------------------------------------------------------+
//| Cancela ordens pendentes de compra, do simbolo, valor e comentario informados. |
//+-------------------------------------------------------------------------------+
bool osc_minion_trade::cancelarOrdensComentadasDeCompra(string symbol, string comentario, double valor) {
   ulong order_ticket; 
   int totOrdens = OrdersTotal();

//--- passar por todas as ordens pendentes 
 //for(int i=OrdersTotal()-1; i>=0; i--){ 
   for(int i=0; i<totOrdens; i++){  // assim processa primeiro as mais antigas
      
      if( (order_ticket = OrderGetTicket(i) ) > 0         && 
             OrderGetString(ORDER_SYMBOL)     == symbol   && // simbolo
             OrderGetDouble(ORDER_PRICE_OPEN) == valor    && // valor
             OrderGetInteger(ORDER_STATE)     == ORDER_STATE_PLACED &&
 StringFind( OrderGetString (ORDER_COMMENT),comentario) > -1 &&  // comentario
           ( OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_BUY_LIMIT      || // venda
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_BUY            ||
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_BUY_STOP       ||
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_BUY_STOP_LIMIT  )
         ){ 
          Print(":-| ", __FUNCTION__, "(",symbol,",",comentario,",",valor,") Canc #", order_ticket," #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket); // add em 21/09/2020 e comentado trecho abaixo

          /*
          MqlTradeResult  result ={0}; 
          MqlTradeRequest request={0}; 
          
          request.order   = order_ticket; 
          request.action  = TRADE_ACTION_REMOVE; 
         
          //--- envio do pedido assincrono
          
          if(!OrderSendAsync(request,result)){
             Print(__FUNCTION__,"(",symbol,",",comentario,",",valor,",",deep,") :-( REMOCAO ERRO OrderSendAsync ",GetLastError(), ":", result.retcode,":",result.comment, " order=", order_ticket);  // se não for possível enviar o pedido, exibir um código de erro
             //if( result.retcode == TRADE_RETCODE_TOO_MANY_REQUESTS ){
             //    Print(__FUNCTION__,"(",symbol,",",comentario,",",valor,")"," :-( Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms..."  );
             //    Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
             //}
             if( deep == 1 ){
                 Print(__FUNCTION__,"(",symbol,",",comentario,",",valor,",",deep,")"," :-( Aguardando ",M_TIME_SLEEP_MANY_REQUESTS,"ms e passando controle para segunda chamada..."  );
                 Sleep(M_TIME_SLEEP_MANY_REQUESTS); //<TODO> consertar e tentar tirar este sleep daqui
                 cancelarOrdensComentadasDeCompra(symbol, comentario, valor, 2);
             }
             return false; // se retornou aqui, eh porque encontrou ordens a cancelar e chegou a ter algum problema, mesmo que
                           // tenha conseguido cancelar as ordens.
          }else{
             Print(":-| ",__FUNCTION__ ,"(",symbol,",",comentario,",",valor,",", deep, ") :-| Canc #", order_ticket, " asyn");
          }
          */
      }
   }// for
   return true; 
}

//+-------------------------------------------------------------------------------+
//| Cancela ordens pendentes de compra, do simbolo, valor e comentario informados. |
//+-------------------------------------------------------------------------------+
bool osc_minion_trade::cancelarOrdensComentadasDeCompraMenoresQue(string symbol,string comentario,double valor){
   ulong order_ticket; 
   int totOrdens = OrdersTotal();

   //--- passar por todas as ordens pendentes 
   for(int i=0; i<totOrdens; i++){  // assim processa primeiro as mais antigas
      
      if( (order_ticket = OrderGetTicket(i) ) > 0         && 
             OrderGetString(ORDER_SYMBOL)     == symbol   && // simbolo
             OrderGetDouble(ORDER_PRICE_OPEN)  < valor    && // valor
             OrderGetInteger(ORDER_STATE)     == ORDER_STATE_PLACED &&
 StringFind( OrderGetString (ORDER_COMMENT),comentario) > -1 &&  // comentario
           ( OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_BUY_LIMIT      || // venda
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_BUY            ||
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_BUY_STOP       ||
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_BUY_STOP_LIMIT  )
         ){ 
          //Print(":-| ", __FUNCTION__, "(",symbol,",",comentario,",",valor,") Canc #", order_ticket," #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket); // add em 21/09/2020 e comentado trecho abaixo
      }
   }// for
   return true; 
}

//+-------------------------------------------------------------------------------+
//| Cancela ordens pendentes de venda, do simbolo, valor e comentario informados. |
//+-------------------------------------------------------------------------------+
bool osc_minion_trade::cancelarOrdensComentadasDeVendaMaioresQue(string symbol, string comentario, double valor) {
   ulong order_ticket; 
   int totOrdens = OrdersTotal();

   //--- passar por todas as ordens pendentes 
   for(int i=0; i<totOrdens; i++){  // assim processa primeiro as mais antigas
      
      if( ( order_ticket = OrderGetTicket(i) ) > 0           && 
             OrderGetString(ORDER_SYMBOL)     == symbol      &&  // simbolo
             OrderGetDouble(ORDER_PRICE_OPEN)  > valor       &&  // valor
             OrderGetInteger(ORDER_STATE)     == ORDER_STATE_PLACED &&
 StringFind( OrderGetString (ORDER_COMMENT),comentario) > -1 &&  // comentario
           ( OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_SELL_LIMIT      || // venda
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_SELL            ||
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_SELL_STOP       ||
             OrderGetInteger(ORDER_TYPE)     == ORDER_TYPE_SELL_STOP_LIMIT  )
         ){ 
          //Print(":-| ", __FUNCTION__, "(",symbol,",",comentario,",",valor,") Canc #", order_ticket," #state ", stateOrderToString(), " asyn");
          cancelarOrdem(order_ticket); // add em 21/09/2020 e comentado trecho abaixo
      }
   }// for
   return true;
}


//+-----------------------------------------------------------+
//| Fecha as posicoes compradas                               |
//| tem bug. Soh funciona em contas hedge                     |
//+-----------------------------------------------------------+
void osc_minion_trade::fecharPosicaoComprada(string symbol, string comentario) {
    if( estouComprado(symbol) ){ fecharPosicao(comentario); }
}

//+-----------------------------------------------------------+
//| Fecha as posicoes vendidas                                |
//| tem bug. Soh funciona em contas hedge                     |
//+-----------------------------------------------------------+
void osc_minion_trade::fecharPosicaoVendida(string symbol, string comentario) {
    if( estouVendido(symbol) ){ fecharPosicao(comentario); }
}

//+-----------------------------------------------------------------+
//| Fecha todas as posicoes abertas pelo EA. Usa o magic para saber.|
//+-----------------------------------------------------------------+
void osc_minion_trade::fecharPosicao(string comentario) {

   int total=PositionsTotal(); // qtd posicoes abertas   
   for(int i=total-1; i>=0; i--)
   {
      //--- parâmetros da ordem
      ulong  position_ticket=PositionGetTicket(i);                                      // bilhete da posição
      string position_symbol=PositionGetString(POSITION_SYMBOL);                        // simbolo 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // número de signos depois da coma
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber da posição
      double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume da posição
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // tipo de posição
      
      //--- saída de informação sobre a posição
      PrintFormat(":-| osc_minion_trade: Fechando posicao #%I64u %s  %s  %.2f  %s [%I64d] ...",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  magic);
      
      //--- se o MagicNumber coincidir
      if(magic==m_mmagic){
      
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(m_treq);
         ZeroMemory(m_tres);
         
         //--- configuração dos parâmetros da ordem
         m_treq.action   =TRADE_ACTION_DEAL;        // tipo de operação de negociação
       //m_treq.type     =ORDER_TYPE_CLOSE_BY;
         m_treq.position =position_ticket;          // bilhete da posição
         m_treq.symbol   =position_symbol;          // símbolo 
         m_treq.volume   =volume;                   // volume da posição
         m_treq.deviation=m_desvio;                 // desvio permitido do preço
         m_treq.magic    =m_mmagic;                 // MagicNumber da posição
         
         //--- envio do pedido
         if( m_async ){   
             if(!OrderSendAsync(m_treq,m_tres)){
                PrintFormat(":-( osc_minion_trade: CLOSE ERRO OrderSend %d :" + comentario,GetLastError());  // se não for possível enviar o pedido, exibir um código de erro
                PrintFormat(":-( osc_minion_trade: CLOSE ERRO retcode=%u  deal=%I64u  order=%I64u :" + comentario, m_tres.retcode,m_tres.deal,m_tres.order);
             }
         }else{
             if(!OrderSend(m_treq,m_tres)){
                PrintFormat(":-( osc_minion_trade: CLOSE ERRO OrderSend %d :" + comentario,GetLastError());  // se não for possível enviar o pedido, exibir um código de erro
                PrintFormat(":-( Ctrade: CLOSE ERRO retcode=%u  deal=%I64u  order=%I64u :" + comentario, m_tres.retcode,m_tres.deal,m_tres.order);
             }
         }

         // aguardando a posicao ser fechada por eteh 10 segundos ... 
         for(int a=0; a<100; a++){
             if( PositionSelectByTicket(position_ticket) ){
                 Print( ":-| Fechando posicao ticket=",position_ticket, " volume=",volume, " ordem=",m_tres.order,"..."  );
                 Sleep(1000);
             }else{
                 Print( ":-| Posicao fechada! ticket=",position_ticket, " volume=",volume, " ordem=",m_tres.order,"..."  );
                 break;
             }
         }
      }//end if
   }// end for
}// end fecharPosicao()

//+-----------------------------------------------------------+
//| Fecha todas as posicoes da conta                          |
//+-----------------------------------------------------------+
void osc_minion_trade::fecharQualquerPosicao(string comentario) {
   int total=PositionsTotal(); // qtd posicoes abertas   
   for(int i=total-1; i>=0; i--)
   {
      //--- parâmetros da ordem
      ulong  position_ticket=PositionGetTicket(i);                                      // bilhete da posição
      string position_symbol=PositionGetString(POSITION_SYMBOL);                        // simbolo 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // número de signos depois da coma
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber da posição
      double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume da posição
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // tipo de posição
      
      //--- saída de informação sobre a posição
      PrintFormat(":-| Ctrade::fecharQualquerPosicao #%I64u %s  %s  %.2f  %s [%I64d]",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  magic);
      
      //--- se o MagicNumber coincidir
      //if(magic==m_mmagic){
      
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(m_treq);
         ZeroMemory(m_tres);
         
         //--- configuração dos parâmetros da ordem
         m_treq.action   =TRADE_ACTION_DEAL;        // tipo de operação de negociação
       //m_treq.type     =ORDER_TYPE_CLOSE_BY;      // MagicNumber da posição
         m_treq.position =position_ticket;          // bilhete da posição
         m_treq.symbol   =position_symbol;          // símbolo 
         m_treq.volume   =volume;                   // volume da posição
         m_treq.deviation=m_desvio;                 // desvio permitido do preço
         m_treq.magic    =m_mmagic;                 // MagicNumber da posição
         m_treq.type_filling = ORDER_FILLING_RETURN;// Order execution type
         
         
         //--- colocação do preço e tipo de ordem dependendo do tipo de ordem
         if(type==POSITION_TYPE_BUY){
            //m_treq.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
            //m_treq.type =ORDER_TYPE_SELL;
            enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, SymbolInfoDouble(position_symbol,SYMBOL_BID), volume, comentario);
            return;
         }else{
            //m_treq.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            //m_treq.type =ORDER_TYPE_BUY;
            enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , SymbolInfoDouble(position_symbol,SYMBOL_ASK), volume, comentario);
            return;
         }
         
         
         //--- envio do pedido
         //if( m_async ){   
         //    if(!OrderSendAsync(m_treq,m_tres)){
         //       PrintFormat(":-( Ctrade: CLOSE ERRO OrderSend %d :" + comentario,GetLastError());  // se não for possível enviar o pedido, exibir um código de erro
         //       PrintFormat(":-( Ctrade: CLOSE ERRO retcode=%u  deal=%I64u  order=%I64u :" + comentario, m_tres.retcode,m_tres.deal,m_tres.order);
         //       return;
         //    }
         //}else{
         //    if(!OrderSend(m_treq,m_tres)){
         //       PrintFormat(":-( Ctrade: CLOSE ERRO OrderSend %d :" + comentario,GetLastError());  // se não for possível enviar o pedido, exibir um código de erro
         //       PrintFormat(":-( Ctrade: CLOSE ERRO retcode=%u  deal=%I64u  order=%I64u :" + comentario, m_tres.retcode,m_tres.deal,m_tres.order);
         //       return;
         //    }
         //}
         
         
         // aguardando a posicao ser fechada por eteh 10 segundos ... 
         //for(int a=0; a<100; a++){
         //    if( PositionSelectByTicket(position_ticket) ){
         //        Print( ":-| Fechando posicao ticket=",position_ticket, " volume=",volume, " ordem=",m_tres.order,"..."  );
         //        Sleep(1000);
         //    }else{
         //        Print( ":-| Posicao fechada! ticket=",position_ticket, " volume=",volume, " ordem=",m_tres.order,"..."  );
         //        break;
         //    }
         //}
         
         
      //}//end if
       
   } // end for
   
}// end fecharPosicao()

//+-------------------------------------------------------------------+
//| Fecha posico em conta Neting, para o simbolo informado.  Usa      |
//| ordem pendente para fechar a mesma.                               |
//| Retorna:                                                          |
//| -  ticket da ordem usada para fechar a posicao.                   |
//| -  zero se a posicao nao for encontrada ou                        |
//| -       se houver erro ao enviar a ordem de fechamento da posicao.|
//+-------------------------------------------------------------------+
ulong osc_minion_trade::fecharPosicaoCtaNetting(string symbol, string comentario="") {

   if (!PositionSelect(symbol)){
      Print( __FUNCTION__, ":-| Erro obtendo posicao a fechar para ", symbol, " VERIFIQUE!", GetLastError() );
      return -1;
   }
      
   //--- colocacao do preco e tipo de ordem dependendo do tipo de posicao que serah fechada
   if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
      if( enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, SymbolInfoDouble(symbol,SYMBOL_BID), PositionGetDouble(POSITION_VOLUME), comentario) ){
          return m_tres.order;
      }
      Print( __FUNCTION__, ":-( Erro fechando posicao!!", symbol, " VERIFIQUE!", GetLastError() );
      return -1;
   }else{
      if( enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , SymbolInfoDouble(symbol,SYMBOL_ASK), PositionGetDouble(POSITION_VOLUME), comentario) ){
          return m_tres.order;
      }
      Print( __FUNCTION__, ":-( Erro fechando posicao!!", symbol, " VERIFIQUE!", GetLastError() );
      return -1;
   }
      
     // aguardando a posicao ser fechada por eteh 10 segundos ... 
     //for(int a=0; a<100; a++){
     //    if( PositionSelectByTicket(position_ticket) ){
     //        Print( ":-| Fechando posicao ticket=",position_ticket, " volume=",volume, " ordem=",m_tres.order,"..."  );
     //        Sleep(1000);
     //    }else{
     //        Print( ":-| Posicao fechada! ticket=",position_ticket, " volume=",volume, " ordem=",m_tres.order,"..."  );
     //        break;
     //    }
     //}
   
}

//+-----------------------------------------------------------+
//| Verifica se tem uma posicao e se eh de compra             |
//+-----------------------------------------------------------+
bool osc_minion_trade::estouComprado(string symbol) {

   //<TODO> voltar aqui e melhorar a performance. Use positionselect diretamente sem perguntar por positiontotal. Ver uso em fecharPosicaoCtaNetting.
   if ( PositionsTotal() > 0 ){
      m_position.Select(symbol);
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // tipo de posicao
      if(type==POSITION_TYPE_BUY){ return true; }
   }
   return false;      
}

//+-----------------------------------------------------------+
//| Verifica se tem uma posicao e se eh de venda              |
//+-----------------------------------------------------------+
bool osc_minion_trade::estouVendido(string symbol) {

   //<TODO> voltar aqui e melhorar a performance. Use positionselect diretamente sem perguntar por positiontotal. Ver uso em fecharPosicaoCtaNetting.
   if ( PositionsTotal() > 0 ){
      m_position.Select(symbol);
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // tipo de posicao
      if(type==POSITION_TYPE_SELL){ return true; }
   }
   return false;      
}
//+------------------------------------------------------------------+


//---------------------------------------------------------------
// Administracao de ordens e seus resultados de processamento
//---------------------------------------------------------------

// adiciona requisicao e resultado de uma ordem
void osc_minion_trade::addOrdem(MqlTradeRequest& req, MqlTradeResult& res, ulong ordem=0){

    // montando o objeto que serah armazenado (requisicao e resposta)
    TradeOrder* ord = new TradeOrder;
    ord.req = req;
    ord.res = res; 

    // se estiver na colecao, atualiza e termina
    if(ordem==0) ordem = req.order; // se a ordem nao foi informada, usa a da requisicao
    if(ordem==0) ordem = res.order; // se a ordem da requisicao estah zerada, usa a do resultado
    if( m_ordens.TrySetValue(ordem,ord) ) return;
    
    // nao estah na colecao, entao incluimos
    m_ordens.Add(ordem,ord);
}

// recupera ultima requisicao e resultado de uma ordem. Se nao encontrar, retorna nulo
TradeOrder* osc_minion_trade::getOrdem(ulong ordem){
    TradeOrder* ord;
    if( m_ordens.TryGetValue(ordem,ord) ) return ord;
    return NULL;
}

// valida se pode enviar pedido de alteracao de ordem
bool osc_minion_trade::permiteAlterarOrdem(ulong ordem, double newPrice, double newVol, string newComment){
    TradeOrder* to = getOrdem(ordem);
    
    if(to==NULL) return true;
    
    // parametros a alterar sao iguais aos ultimos do pedido. Nao permita alterar com mesmos parametros, ainda que a ultima alteracao tenha falhado.
    if(     newPrice   == to.req.price
         && newVol     == to.req.volume
         && newComment == to.req.comment ){
        
        //Print(":-| ", __FUNCTION__,"(",ordem,",",newPrice,",",newVol,",",newComment,"): alteracao rejeitada antes do envio, pois ordem jah possui os parametros solicitados." );
        return false;
    }
         
    return true;
}      

// valida se pode enviar pedido de cancelamento de ordem
bool osc_minion_trade::permiteCancelarOrdem(ulong ordem){

    TradeOrder* to = getOrdem(ordem);

    if(to==NULL) return true;

    // Jah enviou um pedido de cancelamento. Nao permite enviar outro, ainda que o ultimo cancelamento tenha falhado.
    if( to.req.action == TRADE_ACTION_REMOVE ){
    //Print(":-| ", __FUNCTION__, "(", ordem, ") Canc rejeitado antes do envio pois jah possui um pedido de cancelamento.");
      return false;
    }
    
    return true;
}
//---------------------------------------------------------------

//+----------------------------------------------------------------------------------------------------------------------+
//| verifica se ah ordem com comentario numerico no preco informado para o simbolo configurado na instancia deste objeto.|
//+----------------------------------------------------------------------------------------------------------------------+
bool osc_minion_trade::tenhoOrdenComComentarioNumerico(double price, ENUM_ORDER_TYPE tipo){
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( OrderGetInteger(ORDER_TYPE      ) == tipo          &&
               OrderGetDouble (ORDER_PRICE_OPEN) == price         &&
                OrderGetString(ORDER_SYMBOL    ) == m_symb_str    && 
                OrderGetString(ORDER_COMMENT   ) != NULL          &&
          orderStatePendente( (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) )
               //(    OrderGetInteger(ORDER_STATE     ) == ORDER_STATE_PLACED 
               //  || OrderGetInteger(ORDER_STATE     ) == ORDER_STATE_STARTED
               //  || OrderGetInteger(ORDER_STATE     ) == ORDER_STATE_REQUEST_ADD
               //  || OrderGetInteger(ORDER_STATE     ) == ORDER_STATE_PARTIAL   )
             ){                     
          
               string strComentarioNumerico = OrderGetString(ORDER_COMMENT);
               long      comentarioNumerico = StringToInteger(strComentarioNumerico);          
              
               // se o comentario da ordem eh um numero, entao encontramos...
               if( MathIsValidNumber(comentarioNumerico) && comentarioNumerico != 0 ){ return true; }
           }
      }else{
           Print(":-( ", __FUNCTION__," :-( ERRO BUSCA_ORDEM_NUMERICA ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
   return false;
}

//+-------------------------------------------------------------------------------------------------------+
//| verifica se ah ordem pendente no preco informado para o simbolo configurado na instancia deste objeto.|
//+-------------------------------------------------------------------------------------------------------+
bool osc_minion_trade::tenhoOrdemPendente(double price){
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( OrderGetDouble (ORDER_PRICE_OPEN) == price      &&
                OrderGetString(ORDER_SYMBOL    ) == m_symb_str &&
          orderStatePendente( (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) )
             ){                     
               return true;
           }
      }else{
           Print(":-( ", __FUNCTION__,"(",price,") ERRO BUSCA_ORDEM_PENDENTE ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
   return false;
}


//+-------------------------------------------------------------------------------------------------------+
//| verifica se ah ordem pendente no preco informado para o simbolo configurado na instancia deste objeto.|
//+-------------------------------------------------------------------------------------------------------+
ulong osc_minion_trade::tenhoOrdemPendente(double price, ENUM_ORDER_TYPE tipo, ulong ticketOut){
   ulong order_ticket; 
   int qtdOrdensPendentes = OrdersTotal();
//--- passar por todas as ordens pendentes 
   for(int i=0; i<qtdOrdensPendentes; i++){ 
      
      if( (order_ticket = OrderGetTicket(i) ) > 0 ){ 
           
           if( order_ticket                      != ticketOut  &&
                OrderGetDouble(ORDER_PRICE_OPEN) == price      &&
               OrderGetInteger(ORDER_TYPE      ) == tipo       &&
                OrderGetString(ORDER_SYMBOL    ) == m_symb_str &&
          orderStatePendente( (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) )
             ){                     
               return order_ticket;
           }
      }else{
           Print(":-( ", __FUNCTION__,"(",price,") ERRO BUSCA_ORDEM_PENDENTE ticket=",order_ticket,"IND=", i, " ORDEM NAO ENCONTRADA!");
      }
   }
   return 0;
}
