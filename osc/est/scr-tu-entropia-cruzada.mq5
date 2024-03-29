﻿//+------------------------------------------------------------------+
//|                                       teste-entropia-cruzada.mq5 |
//+------------------------------------------------------------------+

#include <oslib\osc\est\CStat.mqh>

void OnStart(){
    
    string descricao;
    bool   result;
    
    test0001(descricao,result); Print(descricao,":", result);

}


void test0001(string &descricao, bool &result){

    descricao = __FUNCTION__ + " :-| teste_basico_0001|esperado 0.479650006297541|";

    // distribuicao de fato:
    double a=0;
    double b=1;
    double c=0;
    
    // distribuicao prevista:
    double pa=0.228;
    double pb=0.619;
    double pc=0.153;
    
    // entropia cruzada calculada membro a membro...
    // resultado deve ser 0.479650006297541
    double h = -(a*log(pa)+
                 b*log(pb)+
                 c*log(pc));

  //Print("entropia cruzada = ", h );            

  // entropia cruada calculada por CStat...
  // resultado deve ser 0.479650006297541
  double vetFato    [3] = {0     ,1    , 0    };
  double vetPrevisao[3] = {0.228, 0.619, 0.153};
  
  CStat stat;
  double hnovo = stat.calcEntropiaCruzada(vetFato,vetPrevisao);
  //Print("entropia cruzada calculada em CStat= ", hnovo );
  
  // comparando resultados
  result = (hnovo == h               ) &&
           // 
          //hnovo == MathSignif( 0.479650006297541, 15 ) ;

           (hnovo >= 0.479650006297541 -
                     0.000000000000001 
                     && 
            hnovo <= 0.479650006297541 +
                     0.000000000000001   );
  
}
