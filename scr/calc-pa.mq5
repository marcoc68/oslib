﻿//+------------------------------------------------------------------+
//|                                                      calc-pa.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#property script_show_inputs
input double  INI   = 0;  
input double  FATOR = 1;
input int     QTD   = 40;

//+------------------------------------------------------------------+
//| Calcula progressao aritimetica                                   |
//+------------------------------------------------------------------+

void OnStart(){
   
    double ini    = INI;
    double fator  = FATOR;
    int    qtd    = QTD;
    double atu    = ini;
    double sld    = ini;
    
    for( int i=0; i<qtd; i++){
        atu += fator;
        sld += atu;
    }
    
    Print("PROGRESSAO INI:",ini," FATOR:",fator, " QTD:",qtd, " ATU:",atu, " SLD:",sld);
      
}
//+------------------------------------------------------------------+