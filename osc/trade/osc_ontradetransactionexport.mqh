﻿//+------------------------------------------------------------------+
//|                                 osc_ontradetransactionexport.mqh |
//|                                          Copyright 2019, OS Corp |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao 0.001                                                     |
//| 1.                                                               |
//|                                                                  |
//| 2.                                                               |
//|                                                                  |
//+------------------------------------------------------------------+
//

class osc_ontradetransactionexport{

private:
    
    //---------------------------
    int  m_csvFile;
    //bool openCSV(datetime from, string sufix);           
    //uint printHeaderCSV(int csvFile);
    //int  printDetCSV(int csvFile, const MqlTradeTransaction &tran,  
    //                              const MqlTradeRequest     &req ,
    //                              const MqlTradeResult      &res );
    //---------------------------

    //-------------------------
    ulong  m_microsec_ant;
    ulong  m_microsec    ;
    ulong getMicrosec(){
        m_microsec     = GetMicrosecondCount()-m_microsec_ant;
        m_microsec_ant += m_microsec;
        return m_microsec;
    }
    //-------------------------

       
public:
    bool initialize(string sufixo_arq="ONTRAN");
    bool openCSV(datetime from, string sufix);           
    uint printHeaderCSV();
    uint printDetCSV(const MqlTradeTransaction &tran,  
                     const MqlTradeRequest     &req ,
                     const MqlTradeResult      &res );
    void closeCSV(){ FileClose(m_csvFile); } 

};

bool osc_ontradetransactionexport::initialize(string sufixo_arq="ONTRAN"){
    if( ! openCSV(TimeTradeServer(),sufixo_arq) ) return false;
    printHeaderCSV();
    return true;
}

uint osc_ontradetransactionexport::printHeaderCSV(){
    return FileWrite(m_csvFile,
                    "ms"             ,
                                       // struct MqlTradeTransaction 
                    "1deal"           , // ulong                       // Bilhetagem da operação (deal) 
                    "1order"          , // ulong                       // Bilhetagem da ordem 
                    "1symbol"         , // string                      // Nome do ativo da negociação 
                    "1type"           , // ENUM_TRADE_TRANSACTION_TYPE // Tipo de transação da negociação 
                    "1order_type"     , // ENUM_ORDER_TYPE             // Tipo de ordem 
                    "1order_state"    , // ENUM_ORDER_STATE            // Estado da ordem 
                    "1deal_type"      , // ENUM_DEAL_TYPE              // Tipo de operação (deal) 
                    "1time_type"      , // ENUM_ORDER_TYPE_TIME        // Tipo de ordem por período de ação 
                    "1time_expiration", // datetime                    // Hora de expiração da ordem 
                    "1price"          , // double                      // Preço 
                    "1price_trigger"  , // double                      // Preço de ativação de ordem tipo Stop limit 
                    "1price_sl"       , // double                      // Nível de Stop Loss 
                    "1price_tp"       , // double                      // Nível de Take Profit 
                    "1volume"         , // double                      // Volume em lotes
                    "1position"       , // ulong                       // Position ticket 
                    "1position_by"    , // ulong                       // Ticket of an opposite position 
  
                                       // struct MqlTradeRequest 
                   "2action"          , // ENUM_TRADE_REQUEST_ACTIONS    // Tipo de operação de negociação 
                   "2magic"           , // ulong                         // Expert Advisor -conselheiro- ID (número mágico) 
                   "2order"           , // ulong                         // Bilhetagem da ordem 
                   "2symbol"          , // string                        // Símbolo de negociação 
                   "2volume"          , // double                        // Volume solicitado para uma encomenda em lotes 
                   "2price"           , // double                        // Preço 
                   "2stoplimit"       , // double                        // Nível StopLimit da ordem 
                   "2sl"              , // double                        // Nível Stop Loss da ordem 
                   "2tp"              , // double                        // Nível Take Profit da ordem 
                   "2deviation"       , // ulong                         // Máximo desvio possível a partir do preço requisitado 
                   "2type"            , // ENUM_ORDER_TYPE               // Tipo de ordem 
                   "2type_filling"    , // ENUM_ORDER_TYPE_FILLING       // Tipo de execução da ordem 
                   "2type_time"       , // ENUM_ORDER_TYPE_TIME          // Tipo de expiração da ordem 
                   "2expiration"      , // datetime                      // Hora de expiração da ordem (para ordens do tipo ORDER_TIME_SPECIFIED)) 
                   "2comment"         , // string                        // Comentário sobre a ordem 
                   "2position"        , // ulong                         // Bilhete da posição 
                   "2position_by"     , // ulong                         // Bilhete para uma posição oposta 

                                       // struct MqlTradeResult 
                   "3retcode"         , // uint     // Código de retorno da operação 
                   "3deal"            , // ulong    // Bilhetagem (ticket) da operação (deal),se ela for realizada 
                   "3order"           , // ulong    // Bilhetagem (ticket) da ordem, se ela for colocada 
                   "3volume"          , // double   // Volume da operação (deal), confirmada pela corretora 
                   "3price"           , // double   // Preço da operação (deal), se confirmada pela corretora 
                   "3bid"             , // double   // Preço de Venda corrente 
                   "3ask"             , // double   // Preço de Compra corrente 
                   "3comment"         , // string   // Comentário da corretora para a operação (por default, ele é preenchido com a descrição código de retorno de um servidor de negociação) 
                   "3request_id"      , // uint     // Identificador da solicitação definida pelo terminal durante o despacho 
                   "3retcode_external"); // uint     // Código de resposta do sistema de negociação exterior 
}  

uint osc_ontradetransactionexport::printDetCSV(const MqlTradeTransaction &tran,  
                                               const MqlTradeRequest     &req ,
                                               const MqlTradeResult      &res ){
    return FileWrite(m_csvFile,  
                    getMicrosec(),        
                                       // struct MqlTradeTransaction 
                    tran.deal           , // ulong                       // Bilhetagem da operação (deal) 
                    tran.order          , // ulong                       // Bilhetagem da ordem 
                    tran.symbol         , // string                      // Nome do ativo da negociação 
       EnumToString(tran.type)          , // ENUM_TRADE_TRANSACTION_TYPE // Tipo de transação da negociação 
       EnumToString(tran.order_type)    , // ENUM_ORDER_TYPE             // Tipo de ordem 
       EnumToString(tran.order_state)   , // ENUM_ORDER_STATE            // Estado da ordem 
       EnumToString(tran.deal_type)     , // ENUM_DEAL_TYPE              // Tipo de operação (deal) 
       EnumToString(tran.time_type)     , // ENUM_ORDER_TYPE_TIME        // Tipo de ordem por período de ação 
                    tran.time_expiration, // datetime                    // Hora de expiração da ordem 
                    tran.price          , // double                      // Preço 
                    tran.price_trigger  , // double                      // Preço de ativação de ordem tipo Stop limit 
                    tran.price_sl       , // double                      // Nível de Stop Loss 
                    tran.price_tp       , // double                      // Nível de Take Profit 
                    tran.volume         , // double                      // Volume em lotes
                    tran.position       , // ulong                       // Position ticket 
                    tran.position_by    , // ulong                       // Ticket of an opposite position 
  
                                       // struct MqlTradeRequest 
      EnumToString(req.action)         , // ENUM_TRADE_REQUEST_ACTIONS    // Tipo de operação de negociação 
                   req.magic           , // ulong                         // Expert Advisor -conselheiro- ID (número mágico) 
                   req.order           , // ulong                         // Bilhetagem da ordem 
                   req.symbol          , // string                        // Símbolo de negociação 
                   req.volume          , // double                        // Volume solicitado para uma encomenda em lotes 
                   req.price           , // double                        // Preço 
                   req.stoplimit       , // double                        // Nível StopLimit da ordem 
                   req.sl              , // double                        // Nível Stop Loss da ordem 
                   req.tp              , // double                        // Nível Take Profit da ordem 
                   req.deviation       , // ulong                         // Máximo desvio possível a partir do preço requisitado 
      EnumToString(req.type)           , // ENUM_ORDER_TYPE               // Tipo de ordem 
      EnumToString(req.type_filling)   , // ENUM_ORDER_TYPE_FILLING       // Tipo de execução da ordem 
      EnumToString(req.type_time)      , // ENUM_ORDER_TYPE_TIME          // Tipo de expiração da ordem 
                   req.expiration      , // datetime                      // Hora de expiração da ordem (para ordens do tipo ORDER_TIME_SPECIFIED)) 
                   req.comment         , // string                        // Comentário sobre a ordem 
                   req.position        , // ulong                         // Bilhete da posição 
                   req.position_by     , // ulong                         // Bilhete para uma posição oposta 

                                       // struct MqlTradeResult 
                   res.retcode         , // uint     // Código de retorno da operação 
                   res.deal            , // ulong    // Bilhetagem (ticket) da operação (deal),se ela for realizada 
                   res.order           , // ulong    // Bilhetagem (ticket) da ordem, se ela for colocada 
                   res.volume          , // double   // Volume da operação (deal), confirmada pela corretora 
                   res.price           , // double   // Preço da operação (deal), se confirmada pela corretora 
                   res.bid             , // double   // Preço de Venda corrente 
                   res.ask             , // double   // Preço de Compra corrente 
                   res.comment         , // string   // Comentário da corretora para a operação (por default, ele é preenchido com a descrição código de retorno de um servidor de negociação) 
                   res.request_id      , // uint     // Identificador da solicitação definida pelo terminal durante o despacho 
                   res.retcode_external);  // uint     // Código de resposta do sistema de negociação exterior 
}

//+-----------------------------------------------------------+
//|                                                           |
//+-----------------------------------------------------------+
bool osc_ontradetransactionexport::openCSV(datetime from, string sufix){
    
    // data inicial. farah parte do nome do arquivo...
    string strFrom = TimeToString(from,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    StringReplace(strFrom,".","" );
    StringReplace(strFrom," ","_");
    StringReplace(strFrom,":","_");

    string nameArqCSV =   strFrom                       + "_" + 
                          IntegerToString(getMicrosec())+ "_" + sufix + ".csv";

    Print(":-| ",__FUNCTION__,": Creating file ", nameArqCSV, " in common file dir...");
    
    m_csvFile = FileOpen(nameArqCSV, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ";");
    
    if( m_csvFile<0 ){
        Print(":-( ",__FUNCTION__,": Error creating file: ", nameArqCSV     );
        Print(":-( ",__FUNCTION__,": Erro code          : ", GetLastError() );
        return false;
    }
    return true;
}

