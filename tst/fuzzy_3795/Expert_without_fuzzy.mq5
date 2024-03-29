﻿//+------------------------------------------------------------------+
//|                                         Expert without fuzzy.mq5 |
//|                                Copyright 2017, Dmitrievskiy Max. |
//|                        https://www.mql5.com/ru/users/dmitrievsky |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Dmitrievskiy Max."
#property link      "https://www.mql5.com/ru/users/dmitrievsky"
#property version   "1.00"

#include <Trade\AccountInfo.mqh>
#include <MT4Orders.mqh>

int hnd1, hnd2, hnd3;
double arr1[], arr2[], arr3[];

input double   MaximumRisk=0.01;
input double   CustomLot=0;    
input int      OrderMagic=666;

double   lots;
static datetime last_time=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
   hnd1 = iRSI(_Symbol,0,9,PRICE_CLOSE);
   hnd2 = iRSI(_Symbol,0,14,PRICE_CLOSE);
   hnd3 = iRSI(_Symbol,0,21,PRICE_CLOSE);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(!isNewBar())
     {  
      return;
     }
     
   double TradeSignal=CalculateSignal(); 
   
   if(CountOrders(0)!=0 || CountOrders(1)!=0)
      {
       for(int b=OrdersTotal()-1; b>=0; b--)
         {
          if(OrderSelect(b,SELECT_BY_POS)==true)
           {
            if(OrderSymbol()==_Symbol && OrderMagicNumber()==OrderMagic)
             {
              if(OrderType()==OP_BUY && TradeSignal>=0.5)
               {
                if(OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Red))
                 {
                  if(TradeSignal==1.0)
                  {
                   lots = LotsOptimized(); 
                   if(OrderSend(Symbol(),OP_SELL,lots,SymbolInfoDouble(_Symbol,SYMBOL_BID),0,0,0,NULL,OrderMagic,Red)){
                     };
                  }
                 }
               }
               if(OrderType()==OP_SELL && TradeSignal<=0.5)
               {
                if(OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Red))
                 {
                  if(TradeSignal==0.0)
                  {
                   lots = LotsOptimized(); 
                   if(OrderSend(Symbol(),OP_BUY,lots,SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0,0,NULL,OrderMagic,Green)){
                    };
                  }
                 }
               }
             }
            }
          }
         return;
        }
        
   lots = LotsOptimized(); 
   if(TradeSignal==0.0 && CheckMoneyForTrade(_Symbol,lots,ORDER_TYPE_BUY))
     { 
      if(OrderSend(Symbol(),OP_BUY,lots,SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0,0,NULL,OrderMagic,Green)){
       };
     }
   else if(TradeSignal==1.0 && CheckMoneyForTrade(_Symbol,lots,ORDER_TYPE_SELL))
     {
      if(OrderSend(Symbol(),OP_SELL,lots,SymbolInfoDouble(_Symbol,SYMBOL_BID),0,0,0,NULL,OrderMagic,Red)){
       };
     }
   return;
     
  }
//+------------------------------------------------------------------+

double CalculateSignal()
{
 double res =0.5;
 CopyBuffer(hnd1,0,0,1,arr1);
 CopyBuffer(hnd2,0,0,1,arr2);
 CopyBuffer(hnd3,0,0,1,arr3);
 
 if(arr1[0]>70 && arr2[0]>70 && arr3[0]>70) res=1.0;
 if(arr1[0]<30 && arr2[0]<30 && arr3[0]<30) res=0.0;
 
 if(arr1[0]<30 && arr2[0]<30 && arr3[0]>70) res=0.5;
 if(arr1[0]<30 && arr2[0]>70 && arr3[0]<30) res=0.5;
 if(arr1[0]>70 && arr2[0]<30 && arr3[0]<30) res=0.5;
 
 if(arr1[0]>70 && arr2[0]>70 && arr3[0]<30) res=0.5;
 if(arr1[0]>70 && arr2[0]<30 && arr3[0]>70) res=0.5;
 if(arr1[0]<30 && arr2[0]>70 && arr3[0]>70) res=0.5;
 
 if(arr1[0]<30 && arr2[0]<30 && (arr3[0]>40 && arr3[0]<60)) res=0.0;
 if(arr1[0]<30 && (arr2[0]>40 && arr2[0]<60) && arr3[0]<30) res=0.0;
 if((arr1[0]>40 && arr1[0]<60) && arr2[0]<30 && arr3[0]<30) res=0.0;
 
 if(arr1[0]>70 && arr2[0]>70 && (arr3[0]>40 && arr3[0]<60)) res=1.0;
 if(arr1[0]>70 && (arr2[0]>40 && arr2[0]<60) && arr3[0]>70) res=1.0;
 if((arr1[0]>40 && arr1[0]<60) && arr2[0]>70 && arr3[0]>70) res=1.0;
 
 return(res);
}

int CountOrders(int a)
  {
   int result=0;
   for(int k=0; k<OrdersTotal(); k++)
     {
      if(OrderSelect(k,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderType()==a && OrderMagicNumber()==OrderMagic && OrderSymbol()==_Symbol)
           {result++;}
        }
     }
   return(result);
  }
  
double LotsOptimized()
  {
   CAccountInfo myaccount; SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   double lot;
   
   lot=NormalizeDouble(myaccount.FreeMargin()*MaximumRisk/1000.0,2);
   if(CustomLot!=0.0) lot=CustomLot;
   
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   int ratio=(int)MathRound(lot/volume_step);
   if(MathAbs(ratio*volume_step-lot)>0.0000001)
     {
      lot = ratio*volume_step;
     }
   if(lot<SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN)) lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(lot>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   return(lot);
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBar()
  {
   datetime lastbar_time=datetime(SeriesInfoInteger(Symbol(),_Period,SERIES_LASTBAR_DATE));
   if(last_time==0)
     {
      last_time=lastbar_time;
      return(false);
     }
   if(last_time!=lastbar_time)
     {
      last_time=lastbar_time;
      return(true);
     }
   return(false);
  
  }
//+------------------------------------------------------------------+

bool CheckMoneyForTrade(string symb,double lot,ENUM_ORDER_TYPE type)
  {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   //--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false
      Print("Error in ",__FUNCTION__," code=",GetLastError());
      return(false);
     }
   //--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
      return(false);
     }
//--- checking successful
   return(true);
  }