//+------------------------------------------------------------------+
//|                                 osc_vetor_fila_item_desb_vol.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Vetor circular baseado em filas visando rapido calculo de medias.   |
//+---------------------------------------------------------------------+

#include <Object.mqh>
#include <Generic\Queue.mqh>
#include <oslib/osc-padrao.mqh>
//#include <oslib/osc-util.mqh>


class ItemVol : public CObject{

public:
    ulong    id      ;
    double   volsel  ; // volume de agressoes de vendas
    double   volbuy  ; // volume de agressoes de compras

    ItemVol():id(0),volsel(0),volbuy(0){}
    ItemVol(MqlTick &tick){
    	id     = tick.time_msc; // usando o horario em milissegundos como id do item da fila.
    	volsel = osc_padrao::isTkSel(tick)?tick.volume_real:0;
    	volbuy = osc_padrao::isTkBuy(tick)?tick.volume_real:0;
    }

    bool tem_volume(){ return (volsel>0 || volbuy>0); }

    virtual int Compare( const CObject*  node,   // Node to compare with 
                         const int       mode=0){// Compare mode 
       if( this.id > ((ItemVol*)node).id ) return  1;
       if( this.id < ((ItemVol*)node).id ) return -1;
                                           return  0;
    }
    
    string toString(){
        string str;
        StringConcatenate(str
                             ,"|id "     ,id
                             ,"|volsel " ,volsel
                             ,"|volbuy " ,volbuy
                          );
        return str;
    }
};

class osc_vetor_fila_item_volume : public CQueue<ItemVol*> {
private:
	int    m_tamanho_max ;  // tamanho maximo da fila;
	double m_vbuy, m_vsel;  // volume de compras e vendas;

    void deleteItens(){
        ItemVol* itens[];
        int qtd = CopyTo(itens);
        
        Print(__FUNCTION__, " Deletando ", qtd, " itens..." );
        for(int i=0; i<qtd; i++){
            delete(itens[i]);
        }
    }

protected:
public:
	 osc_vetor_fila_item_volume(): m_tamanho_max(10000){}

    ~osc_vetor_fila_item_volume(){ deleteItens(); }
    
    // adiciona ticks a fila de volumes...
    bool add(MqlTick &tick){

    	// criando um item a patir do tick;
    	ItemVol *item = new ItemVol(tick);

    	// nao tem volume. voltamos daqui e nao tocamos na fila;
    	if( !item.tem_volume() ){
    		delete(item);
    		return false;
    	}

    	// Adicionando o item a fila e atualizando os acumuladores de volume...
    	Enqueue(item);
    	m_vbuy += item.volbuy;
    	m_vsel += item.volsel;
    	
    	//Caso passe do tamanho, descarta os primeiros;
        while( Count() > m_tamanho_max ){
        	item = Dequeue();
        	m_vbuy -= item.volbuy;
        	m_vsel -= item.volsel;
        	delete(item);
        }

    	return true;
    }
    
    // calcula e retorna o desbalanceamento do volume sem "pesar" as ocorrencias mais recentes...
    double calc_desbalanceamento(){
        if( (m_vbuy+m_vsel) == 0 ) return 0;
        return (m_vbuy-m_vsel)/(m_vbuy+m_vsel);
    }
    
    // retorna data do tick mais antigo na fila.
    datetime dt_tick_mais_antigo(){
        ItemVol item = Peek();
        return (datetime)(item.id/1000);
    }
    
    // define o tamaho maximo da fila
    void set_tamanho_fila(const int tamanho_max){
        m_tamanho_max = tamanho_max;
    }
};

/*
int osc_vetor_fila_item_volume::copyPriceTo(double &price[]){

    ArrayResize( price,Count() );
    Item* vet[];
    CopyTo(vet);
    for(int i=0; i<Count(); i++) price[i] = vet[i].val;        
    return Count(); 
}

int osc_vetor_fila_item_volume::copyPriceTo(double &price[], double &ind[]){

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
