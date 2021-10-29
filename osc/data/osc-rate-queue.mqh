//+------------------------------------------------------------------+
//|                                                osc-rate-queue.mqh|
//|                               Copyright 2020,oficina de software.|
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "2021, Oficina de Software."
#property link      "https://www.mql5.com/pt/users/marcoc"


//---
#include <oslib/osc/data/osc-rate.mqh>
#include <Generic\Queue.mqh>

//+------------------------------------------------------------------+
//| Janela de objetos osc_rate                                       |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
class osc_rate_queue : public CQueue<osc_rate*>{
    private:
    protected:
    public:
};