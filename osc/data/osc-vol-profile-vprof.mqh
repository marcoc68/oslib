//+------------------------------------------------------------------+
//|                                        osc-vol-profile-vprof.mqh |
//|                               Copyright 2022,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
#property copyright "2022, Oficina de Software."
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Volume profile.                                                     |
//| Estrutura para acumulacao de volume profile em uma janela de tempo  |
//| ou de volume.                                                       |
//+---------------------------------------------------------------------+

#include <Object.mqh>

struct Vprof{
    double ppoc; // preco  da linha com maior volume total
    double pvah; // preco  da linha superior da area de valor
    double pval; // preco  da linha inferior da area de valor

    double vpoc; // volume da linha com maior volume total
    double vvah; // volume da linha superior da area de valor
    double vval; // volume da linha inferior da area de valor
    
    int    ipoc; // indice da linha com maior volume total
    int    ivah; // indice da linha superior da area de valor
    int    ival; // indice da linha inferior da area de valor
    
    double vtot; // volume total;
    double pmax; // maior preco;
    double pmin; // menor preco;
    double upre; // ultimo preco adicionado;
    
    void initialize(){
        ppoc = 0; vpoc = 0;
        pvah = 0; vvah = 0;
        pval = 0; vval = 0;
        vtot = 0; pmax = 0; pmin = 0; 
    }
    
    string toString(){
        string str;
        StringConcatenate(str
                             ,"|POC " , ppoc
                             ,"|VAH " , pvah
                             ,"|VAL " , pval
                             ,"|PRE " , upre
                          );
        return str;
    }

   string str_poc(double price){ return price==ppoc?":POC":"";}
   string str_vah(double price){ return price==pvah?":VAH":"";}
   string str_val(double price){ return price==pval?":VAL":"";}
   string str_upr(double price){ return price==upre?":PRE":"";}
   string str_tip(double price){ return str_poc(price)+
                                        str_vah(price)+
                                        str_val(price)+
                                        str_upr(price);}
};
