//+--------------------------------------------------------+
//|                                       C0700Strategy.mqh|
//|                     Copyright 2026,oficina de software.|
//|                      https://www.metaquotes.net/marcoc.|
//|                                                        |
//| CLASSE PARA CLASSES QUE IMPLEMENTAM EXPERT ADVISORS.   |
//|                                                        |
//|                                                        |
//+--------------------------------------------------------+
#property copyright "2026, Oficina de Software."
#property link      "marcoc68@gmail.com"

#include <oslib/osc/exp/I0700Strategy.mqh>

class C0700Strategy: public I0700Strategy{

public:
    virtual int onInit()  ;
    virtual void onDeinit();
    virtual void onTick()  ;
};
