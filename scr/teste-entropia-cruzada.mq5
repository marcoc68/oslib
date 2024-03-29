﻿//+------------------------------------------------------------------+
//|                                       teste-entropia-cruzada.mq5 |
//+------------------------------------------------------------------+

#include <oslib\osc\est\CStat.mqh>

void OnStart(){
    
    // distribuicao de fato:
    double a=0;
    double b=1;
    double c=0;
    
    // distribuicao prevista:
    double pa=0.228;
    double pb=0.619;
    double pc=0.153;
    
    double h = -(a*log(pa)+
                 b*log(pb)+
                 c*log(pc));

  Print("entropia cruzada = ", h );            

  double vetFato    [3] = {0     ,1    , 0    };
  double vetPrevisao[3] = {0.228, 0.619, 0.153};
  
  CStat stat;
  double hnovo = stat.calcEntropiaCruzada(vetFato,vetPrevisao);
  Print("entropia cruzada calculada em CStat= ", hnovo );        

}

