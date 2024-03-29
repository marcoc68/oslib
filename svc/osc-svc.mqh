﻿//+------------------------------------------------------------------+
//|                                                      osc-svc.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "1.00"


enum ENUM_ID_SVC{
     SVC_RUN     = 1,
     SVC_PROXIMO 
};

class OscSvc{

public:

    //+------------------------------------------------------------------+ 
    //| Enviar evento de transmissão para todos os gráficos abertos      | 
    //+------------------------------------------------------------------+ 
    void broadcastEvent(ENUM_ID_SVC pEventID, long lparam,double dparam,string sparam){ 
        //int  eventID=broadcastEventID-CHARTEVENT_CUSTOM; 
        long currChart=ChartFirst(); 
        int  i=0; 
        while(i<CHARTS_MAX){               // Temos, certamente, nao mais do que CHARTS_MAX abrindo graficos 
           EventChartCustom(currChart,(ushort)pEventID,lparam,dparam,sparam); 
           currChart=ChartNext(currChart); // Recebemos um novo grafico do anterior 
           if(currChart==-1) break;        // Alcancado o final da lista de graficos 
           i++;                            // Aumentando o contador 
        } 
    } 
};

//+------------------------------------------------------------------+
  