//+------------------------------------------------------------------+
//|                                    osc-vol-profile-map-itens.mqh |
//|                               Copyright 2022,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
#property copyright "2022, Oficina de Software."
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Sorted Map de volume_profile_itens.                                 |
//+---------------------------------------------------------------------+

#include <Object.mqh>
#include <Generic\SortedMap.mqh>
#include <oslib/osc/data/osc-vol-profile-item.mqh>
#include <oslib/osc/data/osc-vol-profile-vprof.mqh>


class volume_profile_map_itens : public CSortedMap<double,volume_profile_item*>{
public:
    ~volume_profile_map_itens(){ deleteItens(); }
    
    void deleteItens(){
        double chave[]; volume_profile_item* item[];
        int   qtd = CopyTo(chave,item);
        
        Print(__FUNCTION__, " Deletando ", qtd, " itens..." );
        for(int i=0; i<qtd; i++){
            delete(item[i]);
        }
    }

    string toString(Vprof &vprof){
    
        double chave[]; volume_profile_item* item[];
        int   qtd = CopyTo(chave,item);
        
        string str;
        for(int i=qtd-1; i>-1; i--){
            StringConcatenate( str, str, item[i].toString(),vprof.str_tip(chave[i]), "\n" );
        }
        return str;
    }

    // adicionando volume a um preco. Se o preco existir, adiciona o volume, senao cria novo Item.
    // se o volume zerar, elimina o preco deste hash...
    bool add(double price, double vol, long time = 0 ){ 
        
        if( time==0 ) time = TimeCurrent();
        
        // preco existe, entao adicionamos o volume e atualizamos a data.
        volume_profile_item* item;
        if( TryGetValue(price, item) ){
            item.vol += vol;
            if(time>item.time) item.time=time;
            return true;
        }
        
        // preco nao existe, entao criamos novo Item.
        item      = new volume_profile_item;
        item.vol  = vol     ;
        item.price= price   ;
        item.time = time    ;
        return Add(price, item);
    }
    
    // subtrai o volume de um preco. Se o volume zerar, elimina o preco deste hash...
    bool sub(double price, double vol){ 
        
        // preco existe, entao subtraimos o volume.
        volume_profile_item* item;
        if( TryGetValue(price, item) ){
            item.vol -= vol;
            
            // preco zerou, removemos do hash...
            if(item.vol <= 0){
                Remove(price);
                delete(item);
            }
            return true;
        }
        return false;
    }
};