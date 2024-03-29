﻿//+------------------------------------------------------------------+
//|                                                  osc-svc-run.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property service
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <oslib\svc\osc-svc.mqh>
#include <oslib\svc\run\cls-run.mqh>
//#include "osc-svc.mqh"

//+------------------------------------------------------------------+
//| Script para testar estatisticas de mudanca de precos             |
//+------------------------------------------------------------------+
input int    QTD_MINUTOS   = 21;
input int    LEN_CHUNK_INI = 2;
input int    LEN_CHUNK_FIM = 8;
input string SIMBOLO       = "";
input int    SLEEP         = 60000;//MILISSEGUNDOS ENTRE CADA CALCULO DAS RUNS

void OnStart(){
    OscRun cRun;
    OscSvc cSvc;
  //cRun.onStart(QTD_MINUTOS,LEN_CHUNK_INI,LEN_CHUNK_FIM,SIMBOLO,SLEEP);
    datetime from = D'2020.02.10 13:58:00';
    datetime to   = D'2020.02.10 14:14:00'; //TimeCurrent();

    MqlTick ticks[]; //vetor de ticks que serao processados;
    int     run1 []; //vetor de runs positivas;
    int     run2 []; //vetor de runs negativas;
   
    double tickSize = SymbolInfoDouble(SIMBOLO,SYMBOL_TRADE_TICK_SIZE);
    int    qtdTicks = 0;
    int    lenChunk = LEN_CHUNK_INI; // chunk eh o tamanho da run medido em ticks...
    int    chunk    = 0;
    string strRun   = "";
    
    Print("SVCRUN PROCESSANDO ATIVO:",SIMBOLO," TICK_SIZE:",tickSize);
    while(true){
        qtdTicks = CopyTicksRange(SIMBOLO,ticks,COPY_TICKS_INFO,TimeCurrent()*1000 - (60000*QTD_MINUTOS), TimeCurrent()*1000 );
        strRun = "";
        for(lenChunk=LEN_CHUNK_INI; lenChunk<=LEN_CHUNK_FIM; lenChunk++){
            //svc.onStart(QTD_MINUTOS,LEN_CHUNK_INI,LEN_CHUNK_FIM,SIMBOLO,SLEEP);
            cRun.calcRuns(ticks,qtdTicks,lenChunk,tickSize,run1,run2);
            strRun += cRun.toString(run1,run2,lenChunk);
        }
        cSvc.broadcastEvent(SVC_RUN, 0, 0,strRun);
        Sleep(SLEEP);
    }
}