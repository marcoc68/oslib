﻿//+------------------------------------------------------------------+
//|                                                info-operacao.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
    Print("---------------------- TIPOS DE ORDENS ----------------------");
    Check_SYMBOL_ORDER_MODE(Symbol());
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+ 
//| A função imprime tipos de ordens permitidas para um símbolo      | 
//+------------------------------------------------------------------+ 
void Check_SYMBOL_ORDER_MODE(string symbol) { 
//--- receber o valor da propriedade descrevendo os tipos de ordens permitidas 
   int symbol_order_mode=(int)SymbolInfoInteger(symbol,SYMBOL_ORDER_MODE); 
//--- verificar se há ordens de mercado (Execução de Mercado) 
   if((SYMBOL_ORDER_MARKET&symbol_order_mode)==SYMBOL_ORDER_MARKET) 
      Print(symbol+": Ordens de mercado são permitidas (Buy e Sell)"); 
//--- verificar se há ordens de Limite 
   if((SYMBOL_ORDER_LIMIT&symbol_order_mode)==SYMBOL_ORDER_LIMIT) 
      Print(symbol+": Ordens Buy Limit e Sell Limit são permitidas"); 
//--- verificar se há ordens de Parada 
   if((SYMBOL_ORDER_STOP&symbol_order_mode)==SYMBOL_ORDER_STOP) 
      Print(symbol+": Ordens Buy Stop e Sell Stop são permitidas"); 
//--- verificar se há ordens Stop Limit 
   if((SYMBOL_ORDER_STOP_LIMIT&symbol_order_mode)==SYMBOL_ORDER_STOP_LIMIT) 
      Print(symbol+": Ordens Buy Stop Limit e Sell Stop Limit são permitidas"); 
//--- verificar se a colocação de uma ordem Stop Loss é permitida 
   if((SYMBOL_ORDER_SL&symbol_order_mode)==SYMBOL_ORDER_SL) 
      Print(symbol+": Ordens de Stop Loss são permitidas"); 
//--- Verificar se a colocação de uma ordem Take Profit é permitida 
   if((SYMBOL_ORDER_TP&symbol_order_mode)==SYMBOL_ORDER_TP) 
      Print(symbol+": Ordens de Take Profit são permitidas"); 
//--- 
}
  
//+------------------------------------------------------------------+ 
//| Verifica se um modo de preenchimento específico é permitido      | 
//+------------------------------------------------------------------+ 
bool IsFillingTypeAllowed(string symbol,int fill_type) { 
//--- Obtém o valor da propriedade que descreve os modos de preenchimento permitidos 
   int filling=(int)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE); 
//--- Retorna true, se o modo fill_type é permitido 
   return((filling & fill_type)==fill_type); 
}  