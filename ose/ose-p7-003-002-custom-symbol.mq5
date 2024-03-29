﻿//+------------------------------------------------------------------+
//|                                 ose-p7-003-002-custom-symbol.mq5 |
//|                                          Copyright 2020, OS Corp |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao p7-003-002                                                |
//| 1.                                                               |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.0"

#include <Trade\AccountInfo.mqh>

enum ENUM_TYPE_LINE {
    TYPE_LINE_SQL, // generetes sql lines
    TYPE_LINE_CSV  // generetes csv lines
};
enum ENUM_TYPE_ARQ {
    TYPE_ARQ_TERMINAL_LOGFILE, // write lines in terminal logfile
    TYPE_ARQ_NEW_FILE          // write lines in new file
};
enum ENUM_TYPE_EXPORT {
    TYPE_EXPORT_TICK, // exportacao de ticks
    TYPE_EXPORT_BOOK, // exportacao do book de ofertas
    TYPE_EXPORT_ALL   // exportacao de ticks e do book
};

input ENUM_TYPE_EXPORT EA_TYPE_EXPORT    = TYPE_EXPORT_ALL  ; // TYPE_EXPORT
input ENUM_TYPE_LINE   EA_TYPE_LINE      = TYPE_LINE_SQL    ; // TYPE_LINE
input string           EA_CSV_SEPARATOR  = ";"              ; // CSV_SEPARATOR
input ENUM_TYPE_ARQ    EA_TYPE_ARQ       = TYPE_ARQ_NEW_FILE; // TYPE_ARQ

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

string m_symbol_dest;
string m_symbol_ori;
int OnInit(){

   m_symbol_dest = Symbol()+".SYN";
   m_symbol_ori  = Symbol();
//--- ativamos o livro de ofertas para o instrumento a partir do qual vamos tomas dados
   MarketBookAdd(Symbol());
   return(INIT_SUCCEEDED);
}
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
}

//+------------------------------------------------------------------+
//| Tick function                                                    |
//+------------------------------------------------------------------+
void OnTick(void){
    MqlTick ticks[];
    ArrayResize(ticks,1); 

    //--- copiamos os preços atuais a partir de um instrumento habitual para um instrumento personalizado
    if(SymbolInfoTick(m_symbol_ori,ticks[0])){
        CustomTicksAdd(m_symbol_dest,ticks);
    }
}

//+------------------------------------------------------------------+
//| Book function                                                    |
//+------------------------------------------------------------------+
void OnBookEvent(const string &book_symbol){ 
    //--- copiamos o estado atual do livro de ofertas a partir de um instrumento habitual para um instrumento personalizado
    if(book_symbol==Symbol()){
        MqlBookInfo book_array[];
        if(MarketBookGet(m_symbol_ori,book_array)){
            CustomBookAdd(m_symbol_dest,book_array);
        }
    }
}
//+------------------------------------------------------------------+