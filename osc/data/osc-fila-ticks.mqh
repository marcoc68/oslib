//+------------------------------------------------------------------+
//|                                               osc-fila-ticks.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+-------------------------------------------------------------------------+
//| Vetor circular baseado em filas visando montaem de uma janela de ticks. |
//+-------------------------------------------------------------------------+
#property description "Vetor circular baseado em filas visando acumulo de dados para uso em redes neurais."

#include <Object.mqh>
#include <Generic\Queue.mqh>
#include <oslib/osc-tick-util.mqh>

class Tick : public CObject{

public:
    MqlTick tick;

    virtual int Compare( const CObject*  node,   // Node to compare with 
                         const int       mode=0){// Compare mode 
        if( this.tick.time_msc > ((Tick*)node).tick.time_msc ) return  1;
        if( this.tick.time_msc < ((Tick*)node).tick.time_msc ) return -1;
                                                               return  0;
    }
    
    string toString(int dig=0){ return osc_tick_util::toString(tick, dig);  }
};

class osc_fila_ticks : public CQueue<Tick*> {
private:
   int m_len; // tamanho da fila em segundos;
   int m_vol; // volume total na fila;
protected:
    
public:

    // in len: tamnho da fila em segundos.
    osc_fila_ticks(int len=15){
        m_len = len;
    }

    ~osc_fila_ticks(){ deleteItens(); }
    
    void deleteItens(){
        Tick* ticks[];
        int qtd = CopyTo(ticks);
        
        Print(__FUNCTION__, " Deletando ", qtd, " ticks..." );
        for(int i=0; i<qtd; i++){
            delete(ticks[i]);
        }
    }

    bool add(MqlTick &mqlTick){
        // criando o Tick a partir do MqlTick recebido...
        Tick *tick = new Tick();
        tick.tick = mqlTick;
        
        // adicionando o Tick criado a esta fila...
        Add(tick);
        
        // verificando o tamanho apos a insercao. Se passar, retira os primeiros elementos ateh que fique menor ou igual ao tamanho previsto na inicializacao. 
        
        
        return true;
    }

    void retirar_itens_se_necessario(Tick* ult_tick){
    	// checando se tem itens na fila para retirar...
    	Tick* primeiro_tick = Peek();
    	
    	// tempo demais na fila, entao eliminamos...
    	while( (primeiro_tick != NULL) && (ult_tick.time - primeiro_tick.time > m_len) ){
    	    
    	    // subtraindo o volume do item antigo...
    	    m_vol -= primeiro_tick.tick.volume_real;

    	    // retirando o item antigo da fila e da memória...
    	    m_fila_itens.Dequeue();
    	    delete(primeiro_item);
    	    primeiro_item = m_fila_itens.Peek();
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
