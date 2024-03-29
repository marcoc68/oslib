﻿//+------------------------------------------------------------------+
//|                                              teste-regressao.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Math\Alglib\dataanalysis.mqh>
#include <Math\Stat\Math.mqh>
#include <Graphics\Graphic.mqh>
#include <oslib\osc\est\CStat.mqh>

#property script_show_inputs
input int IN_LEN_VET     = 100;
input int IN_PILE        = 5;
input int IN_QTD_JOGADAS = 400;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

void OnStart(){

   CStat stat;
   double v[];
   
   stat.testeNormal(IN_LEN_VET,IN_PILE,IN_QTD_JOGADAS,v);
   GraphPlot(v,CURVE_HISTOGRAM);
 //GraphPlot( is, retacum , is, estimateArAcum, CURVE_LINES,"nome_teste");

}
//+------------------------------------------------------------------+

   
 //GraphPlot( is, estimate, is, rets, CURVE_POINTS,"nome_teste");
 //GraphPlot( is, estimate, is, rets, CURVE_POINTS,"nome_teste");
 //GraphPlot(     estimate, CURVE_POINTS,"nome_teste");
 //GraphPlot(     rets    , CURVE_LINES,"nome_teste");
 //GraphPlot(     retacum , CURVE_LINES,"nome_teste");
 //GraphPlot( is, retacum , CURVE_LINES,"nome_teste");
 //GraphPlot( is, retacum , is, estimate      , CURVE_LINES,"nome_teste");
 //GraphPlot( is, retacum , is, estimateAr    , CURVE_LINES,"nome_teste");
 //GraphPlot(                   estimateArAcum, CURVE_LINES,"nome_teste");
 //GraphPlot( is, estimateAr, is, estimateArAcum, CURVE_LINES,"nome_teste");

