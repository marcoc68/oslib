//+------------------------------------------------------------------+
//|                                osc_vetor_fila_item_veloc_vol.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Vetor circular baseado em filas visando rapido calculo de medias.   |
//+---------------------------------------------------------------------+
#property description "Vetor circular baseado em filas visando acumulo de dados para uso em redes neurais."

#include <Object.mqh>
#include <Generic\Queue.mqh>
#include <oslib/osc-padrao.mqh>

class ItemVelVol : public CObject{

public:
    ulong    id       ;
    double   vvolsel  ; // velocidade do volume de agressoes de vendas
    double   vvolbuy  ; // velocidade do volume de agressoes de compras
    double   vvolliq  ; // velocidade do volume de compras menos a de vendas
    double   retPrice ; // retorno do preco medido no periodo seguinte a esta velocidade do preco

    virtual int Compare( const CObject*  node,   // Node to compare with 
                         const int       mode=0){// Compare mode 
       if( this.id > ((ItemVelVol*)node).id ) return  1;
       if( this.id < ((ItemVelVol*)node).id ) return -1;
                                              return  0;
    }
    
    string toString(){
        string str;
        StringConcatenate(str
                             ,"|id "      ,id
                             ,"|vvolsel " ,vvolsel
                             ,"|vvolbuy " ,vvolbuy
                             ,"|vvolliq " ,vvolliq
                             ,"|retPrice ",retPrice
                          );
        return str;
    }
};

class osc_vetor_fila_item_veloc_vol : public CQueue<ItemVelVol*> {
private:
protected:
    
public:
    ~osc_vetor_fila_item_veloc_vol(){ deleteItens(); }
    
    void deleteItens(){
        ItemVelVol* item[];
        int qtd = CopyTo(item);
        
        Print(__FUNCTION__, " Deletando ", qtd, " itens..." );
        for(int i=0; i<qtd; i++){
            delete(item[i]);
        }
    }

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
