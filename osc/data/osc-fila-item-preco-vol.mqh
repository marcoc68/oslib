//+------------------------------------------------------------------+
//|                                      osc_fila_item_preco_vol.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Fila de itens preco e volume.                                       |
//+---------------------------------------------------------------------+
#property description "Fila de itens preco/volume."

#include <Object.mqh>
#include <Generic\Queue.mqh>

class Item : public CObject{

public:
    double price;
    double vol  ;
    long   time ;

    virtual int Compare( const CObject*  node,   // Node to compare with 
                         const int       mode=0){// Compare mode 
       if( this.time > ((Item*)node).time ) return  1;
       if( this.time < ((Item*)node).time ) return -1;
                                            return  0;
    }
    
    string toString(){
        string str;
        StringConcatenate(str
                             ,"|p " , price
                             ,"|v " , vol
                             ,"|t " , time
                          );
        return str;
    }
};

class osc_fila_item_preco_vol : public CQueue<Item*> {
private:
protected:    
public:
    void deleteItens(){
        Item* item[];
        int   qtd = CopyTo(item);
        
        Print(__FUNCTION__, " Deletando ", qtd, " itens..." );
        for(int i=0; i<qtd; i++){
            delete(item[i]);
        }
    }

    string toString(){
    
        Item* item[];
        int   qtd = CopyTo(item);
        
        string str;
        for(int i=qtd-1; i>-1; i--){
            StringConcatenate( str, str, item[i].toString(), "\n" );
        }
        return str;
    };
};

/*
int osc_vetor_fila_item_veloc_vol::copyPriceTo(double &price[]){ 

    ArrayResize( price,Count() );
    Item* vet[];
    CopyTo(vet);
    for(int i=0; i<Count(); i++) price[i] = vet[i].val;        
    return Count(); 
}

int osc_vetor_fila_item_veloc_vol::copyPriceTo(double &price[], double &ind[]){ 

    ArrayResize( price,Count() );
    ArrayResize( ind  ,Count() );
    Item* vet[];
    CopyTo(vet);
    for(int i=0; i<Count(); i++){
        price[i] = vet[i].val;
        ind  [i] = i+1       ;
    }        
    return Count(); 
}
*/
