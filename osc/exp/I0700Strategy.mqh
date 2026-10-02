//+-----------------------------------------------------------+
//|                                          I0700Strategy.mqh|
//|                        Copyright 2026,oficina de software.|
//|                         https://www.metaquotes.net/marcoc.|
//|                                                           |
//| INTERFACE PARA CLASSES QUE IMPLEMENTAM EXPERT ADVISORS.   |
//|                                                           |
//|                                                           |
//+-----------------------------------------------------------+
#property copyright "2026, Oficina de Software."
#property link      "marcoc68@gmail.com"

interface I0700Strategy{
    int onInit();
    void onDeinit();
    void onTick();
};