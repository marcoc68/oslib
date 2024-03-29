﻿//+------------------------------------------------------------------+
//|                                       ex-HistorySelectOrders.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() 
  { 
   datetime from=0; 
   datetime to=TimeCurrent(); 
//--- solicitar todo o histórico 
   HistorySelect(from,to); 
//--- variáveis ??para retornar valores das propriedades de ordem 
   ulong    ticket; 
   double   open_price; 
   double   initial_volume; 
   datetime time_setup; 
   datetime time_done; 
   string   symbol; 
   string   type; 
   long     order_magic; 
   long     positionID; 
//--- Numero de ordens atuais pendentes 
   uint     total=HistoryOrdersTotal(); 
//--- passar por ordens em um loop 
   for(uint i=0;i<total;i++) 
     { 
      //--- voltar ticket ordem por sua posição na lista 
      if((ticket=HistoryOrderGetTicket(i))>0) 
        { 
         //--- retorna propriedades de uma Ordem 
         open_price=       HistoryOrderGetDouble(ticket,ORDER_PRICE_OPEN); 
         time_setup=       (datetime)HistoryOrderGetInteger(ticket,ORDER_TIME_SETUP); 
         time_done=        (datetime)HistoryOrderGetInteger(ticket,ORDER_TIME_DONE); 
         symbol=           HistoryOrderGetString(ticket,ORDER_SYMBOL); 
         order_magic=      HistoryOrderGetInteger(ticket,ORDER_MAGIC); 
         positionID =      HistoryOrderGetInteger(ticket,ORDER_POSITION_ID); 
         initial_volume=   HistoryOrderGetDouble(ticket,ORDER_VOLUME_INITIAL); 
         type=GetOrderType(HistoryOrderGetInteger(ticket,ORDER_TYPE)); 
         //--- preparar e apresentar informações sobre a ordem 
         printf("#ticket %d %s %G %s at %G foi criado em %s => feito em %s, pos ID=%d", 
                ticket,                  // ticket de ordem 
                type,                    // tipo 
                initial_volume,          // volume colocado 
                symbol,                  // simbolo 
                open_price,              // preço de abertura especificado 
                TimeToString(time_setup),// tempo de colocar ordem 
                TimeToString(time_done), // tempo de deletar ou executar a ordem 
                positionID               // ID de uma posição, ao qual a quantidade de ordem de negócio está incluído 
                ); 
        } 
     } 
//--- 
  } 
//+------------------------------------------------------------------+ 
//| Retorna o nome string do tipo de ordem                           | 
//+------------------------------------------------------------------+ 
string GetOrderType(long type) 
  { 
   string str_type="unknown operation"; 
   switch(type) 
     { 
      case (ORDER_TYPE_BUY):            return("compra"); 
      case (ORDER_TYPE_SELL):           return("vender"); 
      case (ORDER_TYPE_BUY_LIMIT):      return("buy limit"); 
      case (ORDER_TYPE_SELL_LIMIT):     return("sell limit"); 
      case (ORDER_TYPE_BUY_STOP):       return("buy stop"); 
      case (ORDER_TYPE_SELL_STOP):      return("sell stop"); 
      case (ORDER_TYPE_BUY_STOP_LIMIT): return("buy stop limit"); 
      case (ORDER_TYPE_SELL_STOP_LIMIT):return("sell stop limit"); 
     } 
   return(str_type); 
  }//+------------------------------------------------------------------+
