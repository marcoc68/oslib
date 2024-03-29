﻿//+------------------------------------------------------------------+
//|                                                  osc-svc-run.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property service
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include <oslib\svc\osc-svc-run.mqh>
//+------------------------------------------------------------------+
//| Script para testar estatisticas de mudanca de precos             |
//+------------------------------------------------------------------+
input int    QTD_MINUTOS   = 21;
input int    LEN_CHUNK_INI = 2;
input int    LEN_CHUNK_FIM = 8;
input string SIMBOLO       = "";
input int    SLEEP         = 60000;//MILISSEGUNDOS ENTRE CADA CALCULO DAS RUNS

void OnStart(){
   OscSvcRun svc;
   svc.onStart(QTD_MINUTOS,LEN_CHUNK_INI,LEN_CHUNK_FIM,SIMBOLO,SLEEP);
}