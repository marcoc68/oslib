﻿//+------------------------------------------------------------------+
//|                                             ex-HistorySelect.mq5 |
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
   color BuyColor =clrBlue; 
   color SellColor=clrRed; 
//--- história do negócio pedido 
   HistorySelect(0,TimeCurrent()); 
//--- cria objetos 
   string   name; 
   uint     total=HistoryDealsTotal(); 
   ulong    ticket=0; 
   double   price; 
   double   profit; 
   datetime time; 
   string   symbol; 
   long     type; 
   long     entry; 
//--- para todos os negócios 
   for(uint i=0;i<total;i++) 
     { 
      //--- tentar obter ticket negócios 
      if((ticket=HistoryDealGetTicket(i))>0) 
        { 
         //--- obter as propriedades negócios 
         price =HistoryDealGetDouble(ticket,DEAL_PRICE); 
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME); 
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL); 
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE); 
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY); 
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT); 
         //--- apenas para o símbolo atual 
         if(price && time && symbol==Symbol()) 
           { 
            //--- cria o preço do objeto 
            name="TradeHistory_Deal_"+string(ticket); 
            if(entry) ObjectCreate(0,name,OBJ_ARROW_RIGHT_PRICE,0,time,price,0,0); 
            else      ObjectCreate(0,name,OBJ_ARROW_LEFT_PRICE,0,time,price,0,0); 
            //--- definir propriedades do objeto 
            ObjectSetInteger(0,name,OBJPROP_SELECTABLE,0); 
            ObjectSetInteger(0,name,OBJPROP_BACK,0); 
            ObjectSetInteger(0,name,OBJPROP_COLOR,type?BuyColor:SellColor); 
            if(profit!=0) ObjectSetString(0,name,OBJPROP_TEXT,"Profit: "+string(profit)); 
           } 
        } 
     } 
//--- aplicar no gráfico 
   ChartRedraw(); 
  }//+------------------------------------------------------------------+
