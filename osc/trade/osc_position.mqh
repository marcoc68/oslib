//+------------------------------------------------------------------+
//|                                                 osc_position.mqh |
//|                                          Copyright 2019, OS Corp |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao 0.001 Mantem banco de dados de ordens e posicoes.         |
//| 1.                                                               |
//|                                                                  |
//| 2.                                                               |
//|                                                                  |
//+------------------------------------------------------------------+
//
// Uma posicao tem:
//   - um identificador
//   - ordens de entrada
//   - ordens de saida
//   Uma ordem tem:
//     - identificador
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.0"

#include <Object.mqh>
#include <Arrays\ArrayObj.mqh>
#include <Generic\HashMap.mqh>
#include <oslib\osc\trade\osc_ontradetransactionexport.mqh> // log para ontradetransaction

class OsOrdem : public CObject{
public:
    int   inOut   ; // 1(in); -1(out) ; 0(desconhecida)
    
    ulong idOrd    ; // ticket da ordem
    ulong idDea    ; // ticket da negociacao;
    ulong idPos    ; // ticket da posicao a qual pertence a ordem;
    ulong idToClose; // id deal da ordem que esta ordem estah fechando.
    
    ulong mag       ; // numero magico desta ordem;
    ulong magMeClose; // numero magico da ordem de fechamento dessa ordem;
    ulong magToClose; // numero magico da ordem que esta ordem estah fechando;
    
    string symbol ; // ticker
    double price  ; // preco
    double vol    ; // volume
    
    ENUM_TRADE_TRANSACTION_TYPE typTra; // ultimo tipo de transacao (evento) informado para a ordem
    ENUM_DEAL_TYPE              typDea; 
    ENUM_ORDER_TYPE             typOrd;
    ENUM_ORDER_STATE            status;

    ENUM_TRADE_REQUEST_ACTIONS reqAction; // acao solicitada na ultima requisicao
    double                     reqPrice ; // preco da ultima requisicao
    double                     reqVol   ; // volume da ultima requisicao
    ENUM_ORDER_TYPE            reqTypOrd; // tipo de ordem feito na ultima requisicao
    string                     reqComent; // comentario
    
    uint                       retCode ; // codigo de retorno da ultima requisicao
    ulong                      retOrder; // numero de ordem gerada, caso tenha sido colocada.    
    double                     retVol  ; // volume da ultima gerada, confirmado pela corretora.
    uint                       reqId   ; // requist_id eh o identificador da requisicao. Eh definido pelo terminal durante a despacho da solicitacao. 
    
    //------------------------------------
    //             req.action          , // ENUM_TRADE_REQUEST_ACTIONS    // Tipo de operação de negociação 
    //             req.magic           , // ulong                         // Expert Advisor -conselheiro- ID (número mágico) 
    //             req.order           , // ulong                         // Bilhetagem da ordem 
    //             req.symbol          , // string                        // Símbolo de negociação 
    //             req.volume          , // double                        // Volume solicitado para uma encomenda em lotes 
    //             req.price           , // double                        // Preço 
    //             req.stoplimit       , // double                        // Nível StopLimit da ordem 
    //             req.sl              , // double                        // Nível Stop Loss da ordem 
    //             req.tp              , // double                        // Nível Take Profit da ordem 
    //             req.deviation       , // ulong                         // Máximo desvio possível a partir do preço requisitado 
    //             req.type            , // ENUM_ORDER_TYPE               // Tipo de ordem 
    //             req.type_filling    , // ENUM_ORDER_TYPE_FILLING       // Tipo de execução da ordem 
    //             req.type_time       , // ENUM_ORDER_TYPE_TIME          // Tipo de expiração da ordem 
    //             req.expiration      , // datetime                      // Hora de expiração da ordem (para ordens do tipo ORDER_TIME_SPECIFIED)) 
    //             req.comment         , // string                        // Comentário sobre a ordem 
    //             req.position        , // ulong                         // Bilhete da posição 
    //             req.position_by     , // ulong                         // Bilhete para uma posição oposta 
    //------------------------------------


    virtual int Compare( const CObject*  node,   // Node to compare with 
                         const int       mode=0){// Compare mode 
       if( this.mag > ((OsOrdem*)node).mag ) return  1;
       if( this.mag < ((OsOrdem*)node).mag ) return -1;
                                             return  0;
    }
    
    string toString(){
        string str;
        StringConcatenate(str
                             ,"|ttr ",EnumToString(typTra)
                             ,"|ord ",idOrd
                             ,"|dea ",idDea
                             ,"|pos ",idPos
                             ,"|mag ",mag
                             ,"|mml ",magMeClose
                             ,"|mtc ",magToClose
                             ,"|sym ",symbol
                             ,"|io " ,inOut
                             ,"|prc ",price
                             ,"|vol ",vol
                             ,"|tor ",EnumToString(typOrd)
                             ,"|tde ",EnumToString(typDea)
                             ,"|stt ",EnumToString(status) 
                          );
        return str;
    }
};

/*
class CArrayOsOrdem : public CArrayObj{
public:
    string toString(){
        string str;
        for(int i=0; i<Total(); i++){
            StringConcatenate(str, str, ((OsOrdem*)At(i)).toString(),"\n" );
        }
        return str;
    };    
};
*/
class CHashOsOrdem : public CHashMap<ulong,OsOrdem*>{
public:
    string toString(){
    
        ulong chave[]; OsOrdem* valor[];
        int   qtd = CopyTo(chave,valor);
        
        string str;
        for(int i=0; i<qtd; i++){
            StringConcatenate(str, str, valor[i].toString(),"\n" );
        }
        return str;
    };    
};


class osc_position{

private:

    ulong                        m_idPos     ; // id da posicao atual
    double                       m_volIn     ; // volume de contratos em trades IN.
    double                       m_volOut    ; // volume de contratos em trades OUT.
    ENUM_DEAL_TYPE               m_type      ; // compra, venda ou desconhecida, conforme definidos em ENUM_TIPO_POSICAO.
    string                       m_logPosicao; // string com os eventos ao longo da vida da posicao.
    
    CHashOsOrdem                 m_ordens ;  // hash com as ordens da posicao.
    osc_ontradetransactionexport m_logTran;  // loga transacoes da posicao em arqui csv.

    void processarOrderAdd(const MqlTradeTransaction& tran,   
                           const MqlTradeRequest&     req ,   
                           const MqlTradeResult&      res );
    
    void processarOrderUpdate(const MqlTradeTransaction& tran,   
                              const MqlTradeRequest&     req ,   
                              const MqlTradeResult&      res );

    void processarOrderDelete(const MqlTradeTransaction& tran);

    void processarTransactionRequest(const MqlTradeTransaction& tran,   
                                     const MqlTradeRequest&     req ,   
                                     const MqlTradeResult&      res );

    void processarDealAdd(const MqlTradeTransaction& tran            ,   
                          const MqlTradeRequest&     req             ,   
                          const MqlTradeResult&      res             ,
                                bool&                closer          , // true: trade eh um fechamento de posicao
                                bool&                toClose         , // true: trade deve ser fechado
                                ulong&               toCloseidDeal   , // se toClose=true este serah o ticket  do trade a ser fechado
                                double&              toCloseVol      , // se toClose=true este serah o volume  do trade a ser fechado
                                ENUM_DEAL_TYPE&      toCloseTypeDeal , // se toClose=true este serah o sentido do trade a ser fechado, conforme ENUM_DEAL_TYPE
                                double&              toClosePriceIn  , // se toClose=true este serah o preco   do trade a ser fechado
                                bool&                toCloseOpenPos  );// se toClose=true esta indicarah se a posicao foi aberta agora (primeiraOrdem)


    //------------------------- qtd microsegundos entre chamadas
    ulong m_microsec_ant;
    ulong m_microsec    ;
    ulong getMicrosec(){
        m_microsec     = GetMicrosecondCount()-m_microsec_ant;
        m_microsec_ant += m_microsec;
        return m_microsec;
    }
    //------------------------- auxiliar pra saber se comentario eh numerico (ordem de fechamento de posicao)
    bool strEhNumero(string str, ulong &num){
         num = StringToInteger(str);
         return ( MathIsValidNumber(num) && num != 0 );
    }
    //-------------------------

public:

         ~osc_position(){ Print(m_logPosicao); }

    void initialize();

    bool initLogCSV  (){ return m_logTran.initialize(); }
    void deInitLogCSV(){        m_logTran.closeCSV  (); }

    uint logarInCSV( const MqlTradeTransaction& tran,   
                     const MqlTradeRequest&     req ,   
                     const MqlTradeResult&      res ){ return m_logTran.printDetCSV(tran,req,res); }

    void onTradeTransaction( const MqlTradeTransaction& tran,   
                             const MqlTradeRequest&     req ,   
                             const MqlTradeResult&      res ,
                                   bool&                closer          , // true: trade eh um fechamento de posicao
                                   bool&                toClose         , // true: trade deve ser fechado
                                   ulong&               toCloseidDeal   , // se toClose=true este serah o ticket  do trade a ser fechado
                                   double&              toCloseVol      , // se toClose=true este serah o volume  do trade a ser fechado
                                   ENUM_DEAL_TYPE&      toCloseTypeDeal , // se toClose=true este serah o sentido do trade a ser fechado, conforme ENUM_DEAL_TYPE
                                   double&              toClosePriceIn  , // se toClose=true este serah o preco   do trade a ser fechado
                                   bool&                toCloseOpenPos ); // se toClose=true esta indicarah se a posicao foi aberta agora (primeiraOrdem)

    bool getComment( const ulong ticket, string& comment  ); //busca e retorna o comentario de uma ordem
};

void osc_position::initialize(void){     
    m_idPos      = 0                   ; // id da posicao atual
    m_volIn      = 0                   ; // qtd trades IN  multiplicada pelo volume.
    m_volOut     = 0                   ; // qtd trades OUT multiplicada pelo volume.
    m_type       = DEAL_TYPE_COMMISSION; // na inicializacao nao usamos um tipo diferente de DEAL_TYPE_BUY ou DEAL_TYPE_SELL,
                                         // pois ainda nao sabemos se eh posicao vendida ou comprada (as unicas que tratamos).
    m_logPosicao = ""                  ; // string com os eventos ao longo da vida da posicao.
    m_ordens.Clear();                  ; // colecao com as ordens da posicao
}

void osc_position::processarOrderAdd(const MqlTradeTransaction& tran,   
                                     const MqlTradeRequest&     req ,   
                                     const MqlTradeResult&      res ){

    OsOrdem* ord = new OsOrdem   ;
    
    ord.idOrd  = tran.order      ;
  //ord.idDea  = tran.deal       ;
  //ord.idPos  = tran.position   ;
    
    ord.typTra = tran.type       ;
    ord.typOrd = tran.order_type ;
  //ord.typDea = tran.deal_type  ;
    
    ord.status = tran.order_state;
    ord.symbol = tran.symbol     ;
    
    ord.price  = tran.price ;
    ord.vol    = tran.volume;
    
    m_ordens.Add(ord.idOrd, ord);
    return;
}

void osc_position::processarOrderUpdate(const MqlTradeTransaction& tran,   
                                        const MqlTradeRequest&     req ,   
                                        const MqlTradeResult&      res ){
    // posicao vazia, adicione a ordem 
    OsOrdem* ord;
    if( m_ordens.TryGetValue(tran.order, ord) ){
        
      //ord.idOrd  = tran.order      ;
      //ord.idDea  = tran.deal       ;
      //ord.idPos  = tran.position   ;
        
        ord.typTra = tran.type       ;
        ord.typOrd = tran.order_type ;
      //ord.typDea = tran.deal_type  ;
        
        ord.status = tran.order_state;
        ord.symbol = tran.symbol     ;
        
        ord.price  = tran.price ;
        ord.vol    = tran.volume;
        
        return;
    }

    // update de uma ordem nao registrada, incluimos agora...
    processarOrderAdd(tran,req,res); //<TODO> ver como se comportarah se chegar apos a retirada de uma ordem da colecao.
}

// este evento ocorre quando uma ordem sai da lista de ordens pendentes
void osc_position::processarOrderDelete(const MqlTradeTransaction& tran){

    // ordem que estah saindo da lista estah cancelada, entao retiramos do nosso banco de dados...
    if( tran.order_state == ORDER_STATE_CANCELED ){ m_ordens.Remove(tran.order); }
}

void osc_position::processarTransactionRequest(const MqlTradeTransaction& tran,   
                                               const MqlTradeRequest&     req ,   
                                               const MqlTradeResult&      res ){
    
    // nao processmos requisicoes de delecao de ordens.
    // as ordens deletedas sao retiradas do nosso banco de dados (m_ordens) durante o 
    // processamento da transacao TRADE_TRANSACTION_ORDER_DELETE.
    if(req.action == TRADE_ACTION_REMOVE) return;
    
    // posicao vazia, adicione a ordem 
    OsOrdem* ord;
    
    // Descobrindo qual a ordem da requisicao. 
    // Na primeira requisicao de uma ordem, seu numero fica no resultado, nas demais, fica na requisicao.
    ulong order = req.order>0?req.order:res.order;
    
    // se a ordem jah estiver neste controle, atualizamos suas informacoes de requisicao e resultado senao, a incluimos.
    if( m_ordens.TryGetValue(order,ord) ){
        
        // Como a ordem jah estava neste controle, soh atualizamos o tipo de transacao, caso esteja nulo. 
        if (ord.typTra == NULL ) ord.typTra = tran.type;

        ord.reqAction = req.action          ; // ENUM_TRADE_REQUEST_ACTIONS    // Tipo de operação de negociação 
        ord.mag       = req.magic           ; // ulong                         // Expert Advisor -conselheiro- ID (número mágico) 
        //              req.order           ; // ulong                         // Bilhetagem da ordem 
      //ord.symbol    = req.symbol          ; // string                        // Símbolo de negociação 
        ord.reqVol    = req.volume          ; // double                        // Volume solicitado para uma encomenda em lotes 
        ord.reqPrice  = req.price           ; // double                        // Preço 
        //              req.stoplimit       ; // double                        // Nível StopLimit da ordem 
        //              req.sl              ; // double                        // Nível Stop Loss da ordem 
        //              req.tp              ; // double                        // Nível Take Profit da ordem 
        //              req.deviation       ; // ulong                         // Máximo desvio possível a partir do preço requisitado 
      //ord.reqTypOrd = req.type            ; // ENUM_ORDER_TYPE               // Tipo de ordem 
        //              req.type_filling    ; // ENUM_ORDER_TYPE_FILLING       // Tipo de execução da ordem 
        //              req.type_time       ; // ENUM_ORDER_TYPE_TIME          // Tipo de expiração da ordem 
        //              req.expiration      ; // datetime                      // Hora de expiração da ordem (para ordens do tipo ORDER_TIME_SPECIFIED)) 
        ord.reqComent = req.comment         ; // string                        // Comentário sobre a ordem 
        //              req.position        ; // ulong                         // Bilhete da posição 
        //              req.position_by     ; // ulong                         // Bilhete para uma posição oposta 
        ord.retCode   = res.retcode         ;
        ord.retOrder  = res.order           ;
        ord.retVol    = res.volume          ;
        ord.reqId     = res.request_id      ;
  
        // eh um fechamento de posicao, gravamos no log pra checar a perfomance...
        if( req.action==TRADE_ACTION_PENDING && strEhNumero(req.comment, ord.idToClose) ){
            ord.inOut = -1;            
            StringConcatenate( m_logPosicao,m_logPosicao,"CLOSE_BY:",ord.idOrd,":",ord.inOut,":",EnumToString(ord.typOrd),":",ord.vol,":",ord.reqPrice,":",ord.idToClose,":",getMicrosec(),":"); // string com os eventos ao longo da vida da posicao.
        }
        return;
    }

    // ordem ainda nao estah no controle. Colocamos agora...
    ord = new OsOrdem;
    ord.typTra    = tran.type     ;
    ord.idOrd     = order         ;
    ord.reqAction = req.action    ; // ENUM_TRADE_REQUEST_ACTIONS    // Tipo de operação de negociacao 
    ord.mag       = req.magic     ; // ulong                         // Expert Advisor -conselheiro- ID (número magico) 
    ord.symbol    = req.symbol    ; // string                        // Símbolo de negociacao 
    ord.reqVol    = req.volume    ; // double                        // Volume solicitado para uma encomenda em lotes 
    ord.reqPrice  = req.price     ; // double                        // Preco 
    ord.reqTypOrd = req.type      ; // ENUM_ORDER_TYPE               // Tipo de ordem 
    ord.reqComent = req.comment   ; // string                        // Comentario sobre a ordem 
    ord.retCode   = res.retcode   ;
    ord.retOrder  = res.order     ;
    ord.retVol    = res.volume    ;
    ord.reqId     = res.request_id;
    
    m_ordens.Add(ord.idOrd, ord);
    return;
}

void osc_position::processarDealAdd(const MqlTradeTransaction& tran   ,   
                                    const MqlTradeRequest&     req    ,   
                                    const MqlTradeResult&      res    ,
                                          bool&                closer         ,  // true: trade eh um fechamento de posicao
                                          bool&                toClose        ,  // true: trade deve ser fechado
                                          ulong&               toCloseidDeal  ,  // se toClose=true este serah o ticket  do trade a ser fechado
                                          double&              toCloseVol     ,  // se toClose=true este serah o volume  do trade a ser fechado
                                          ENUM_DEAL_TYPE&      toCloseTypeDeal,  // se toClose=true este serah o sentido do trade a ser fechado, conforme ENUM_DEAL_TYPE
                                          double&              toClosePriceIn ,  // se toClose=true este serah o preco   do trade a ser fechado
                                          bool&                toCloseOpenPos ){ // se toClose=true esta indicarah se a posicao foi aberta agora (primeiraOrdem)

    //Print(__FUNCTION__, ":-| Processandi ORDEM:",tran.order, " DEAL:", tran.deal, " POS ",tran.position, " deal_type:", EnumToString(tran.deal_type) );
    
    closer = true;
    OsOrdem* ord;
    if( m_ordens.TryGetValue(tran.order, ord) ){
        //Print(__FUNCTION__, ":-| ORDEM:",tran.order, " encontrada!" );
      //ord.idOrd   = tran.order      ; // ok
        ord.idDea   = tran.deal       ; // ok
        ord.idPos   = tran.position   ; // ok
        
        ord.typTra  = tran.type       ; // ok
      //ord.typOrd  = tran.order_type ; // ok
        ord.typDea  = tran.deal_type  ; // ok
        
      //ord.status  = tran.order_state; // ok
      //ord.symbol  = tran.symbol     ; // ok
        
        ord.price   = tran.price      ; // ok
        ord.vol     = tran.volume     ; // ok
    }else{
      //deal de uma ordem nao registrada, incluimos agora...
        //Print(__FUNCTION__, ":-| ORDEM:",tran.order, " NAO encontrada! Criando uma agora..." );
        ord = new OsOrdem;
        ord.idOrd  = tran.order      ; // ok
        ord.idDea  = tran.deal       ; // ok
        ord.idPos  = tran.position   ; // ok
        
        ord.typTra = tran.type       ; // ok
      //ord.typOrd = tran.order_type ; // ok
        ord.typDea = tran.deal_type  ; // ok
        
      //    ord.status = tran.order_state; // ok
        ord.symbol = tran.symbol     ; // ok
        
        ord.price  = tran.price      ; // ok
        ord.vol    = tran.volume     ; // ok
        
        m_ordens.Add(ord.idOrd,ord);
    } 

    // atualisando resumo da posicao e definindo se a ordem eh IN ou OUT...
    if( m_idPos==0 || m_idPos!=ord.idPos ){ // ordem de abertura da posicao
      //Print(__FUNCTION__, ":-| ORDEM:",tran.order," POSICAO estava zerada. Incluindo ordem na posicao:",ord.idPos );
      //Print(__FUNCTION__, ":-| NOVA POS:",ord.idPos," idDeal:",ord.idDea," ord:",tran.order," tranDealTyp:",EnumToString(tran.deal_type)," posAnt:",m_idPos );
        m_idPos   = ord.idPos ; // id da posicao atual
        m_type    = ord.typDea; // o mesmo tipo do primeiro trade da posicao (compra ou venda).
        m_volIn   = ord.vol   ; // volume de trades IN.
        ord.inOut = 1;
        
        //---------- trade deve ser fechado        
        toClose         = true      ; closer=false;
        toCloseVol      = ord.vol   ;
        toCloseidDeal   = ord.idDea ;
        toCloseTypeDeal = ord.typDea;
        toClosePriceIn  = ord.price ;
        toCloseOpenPos  = true      ; // esta eh a transacao de abertura da posicao
        //----------
    }else{
      //<TODO> colocar o codigo para tratar a chegada de um deal de outra posicao
      //m_idPos   = tran.position ; // id da posicao atual
      //Print(__FUNCTION__, ":-| ORDEM:",tran.order," Checando se eh a mesma direcao da posicao:", EnumToString(m_type) );
      
        // transacao com o mesmo tipo da posicao, eh IN, senao eh OUT.
        if( m_type == ord.typDea ){ //&& m_volIn>m_volOut
          //Print(__FUNCTION__, ":-| direcao da posicao e da transacao sao iguais..." );
            m_volIn  += ord.vol;
            ord.inOut = 1;

            //---------- trade deve ser fechado        
            toClose         = true; closer=false;
            toCloseVol      = ord.vol;
            toCloseidDeal   = ord.idDea;
            toCloseTypeDeal = ord.typDea;
            toClosePriceIn  = ord.price ;
            //----------
        }else{
          //Print(__FUNCTION__, ":-| direcao da posicao e da transacao sao diferentes...");
            m_volOut += ord.vol;
            ord.inOut = -1;
        }
        toCloseOpenPos = false; // esta NAO eh a transacao de abertura da posicao
      //Print(__FUNCTION__, ":-| MESM POS:",ord.idPos," idDeal:",ord.idDea," ord:",tran.order," tranDealTyp:",EnumToString(tran.deal_type));
    }
    
    //StringConcatenate( m_logPosicao,m_logPosicao,"\n:",tran.position,":",ord.idDea,":",ord.idOrd,":",ord.inOut,":",EnumToString(ord.typDea),":",ord.vol,":",ord.price,":",getMicrosec(),":::"); // string com os eventos ao longo da vida da posicao.
    //Print(__FUNCTION__, ":-| gravando no log da posicao...", m_logPosicao);
    
    // verificando se chegou o final da posicao...
    if( m_volIn <= m_volOut ){
          //StringConcatenate( m_logPosicao,m_logPosicao,"FINAL:"); // string com os eventos ao longo da vida da posicao.
          Print(m_logPosicao);
        
        //Print(__FUNCTION__, ":-| gravando FINAL no log da posicao...");
        initialize();
    }
    
    toClosePriceIn  = ord.price; // testando envio do preco da transacao mesmo que nao seja uma transacao a ser fechada (10/11/2020)
    return;
}

//----------------------------------------------------------------------------
// Busca e retorna o comentario de uma ordem.
// Se encontrar a ordem, retorna true grava o comentario na variavel comment
// Se nao encontrar a ordem, retorna false.
//----------------------------------------------------------------------------
bool osc_position::getComment( const ulong ticket, string& comment  ){
    OsOrdem* ord;
    if( m_ordens.TryGetValue(ticket, ord) ){
        comment = ord.reqComent;
        return true;
    }
    return false;
}
//----------------------------------------------------------------------------


//+-----------------------------------------------------------+
//|                                                           |
//+-----------------------------------------------------------+
void osc_position::onTradeTransaction( const MqlTradeTransaction& tran           ,  // transacao
                                       const MqlTradeRequest&     req            ,  // request
                                       const MqlTradeResult&      res            ,  // result
                                             bool&                closer         ,  // true: trade eh um fechamento de posicao
                                             bool&                toClose        ,  // true: trade deve ser fechado
                                             ulong&               toCloseidDeal  ,  // se toClose=true este serah o ticket  do trade a ser fechado
                                             double&              toCloseVol     ,  // se toClose=true este serah o volume  do trade a ser fechado
                                             ENUM_DEAL_TYPE&      toCloseTypeDeal,  // se toClose=true este serah o sentido do trade a ser fechado, conforme ENUM_DEAL_TYPE
                                             double&              toClosePriceIn ,  // se toClose=true este serah o preco   do trade a ser fechado
                                             bool&                toCloseOpenPos ){ // se toClose=true esta indicarah se a posicao foi aberta agora (primeiraOrdem)

    toClose = false;
    switch(tran.type){
        case TRADE_TRANSACTION_ORDER_ADD:    // adicao de nova ordem aberta...
             //processarOrderAdd          (tran,req,res); 
             break;
        case TRADE_TRANSACTION_ORDER_UPDATE: // modificacao de uma ordem em aberto
             //processarOrderUpdate       (tran,req,res); 
             break;
        case TRADE_TRANSACTION_REQUEST:      // foi feito um pedido
             processarTransactionRequest(tran,req,res); break;
        case TRADE_TRANSACTION_DEAL_ADD:     // adicao de novo negocio para o historico...
             processarDealAdd(tran,req,res,closer,toClose,toCloseidDeal,toCloseVol,toCloseTypeDeal, toClosePriceIn, toCloseOpenPos); break;
        case TRADE_TRANSACTION_ORDER_DELETE: // remocao de uma ordem da lista de ordens em aberto
             processarOrderDelete(tran); 
             //Print(__FUNCTION__, ":", strTransaction  (tran,req,res) ); 
             break;
        case TRADE_TRANSACTION_HISTORY_ADD:  // adicao de uma nova ordem para o historico...
             //Print(__FUNCTION__, ":", strTransaction  (tran,req,res) ); 
             break;
        //default:
        //     Print(__FUNCTION__, ":", strTransaction(tran,req,res) );
    }
    
  //Print( m_ordens.toString() );
}
