//+------------------------------------------------------------------+
//|                                   osc-vol-profile-fila-itens.mqh |
//|                               Copyright 2022,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
#property copyright "2022, Oficina de Software."
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Fila de volume_profile_itens.                                       |
//+---------------------------------------------------------------------+

#include <Object.mqh>
#include <Generic\Queue.mqh>
#include <oslib/osc/data/osc-vol-profile-item.mqh>
#include <oslib/osc/data/osc-vol-profile-vprof.mqh>



class volume_profile_fila_itens : public CQueue<volume_profile_item*>{
public:
    ~volume_profile_fila_itens(){ deleteItens(); }
    
    void deleteItens(){
        volume_profile_item* item[];
        int qtd = CopyTo(item);
        
        Print(__FUNCTION__, " Deletando ", qtd, " itens..." );
        for(int i=0; i<qtd; i++){
            delete(item[i]);
        }
    }

    string toString(Vprof &_vprof){
    
        volume_profile_item* item[];
        int qtd = CopyTo(item);
        
        string str;
        for(int i=qtd-1; i>-1; i--){
            StringConcatenate( str, str, item[i].toString(),_vprof.str_tip(item[i].price), "\n" );
        }
        return str;
    }
};