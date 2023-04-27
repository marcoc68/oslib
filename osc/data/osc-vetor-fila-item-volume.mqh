﻿//+------------------------------------------------------------------+
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

#define VETVOL_TAMANHO_PADRAO 1000

class ItemVol : public CObject{

public:
    ulong    id      ;
    double   volsel  ; // volume de agressoes de vendas
    double   volbuy  ; // volume de agressoes de compras

    ItemVol():id(0),volsel(0),volbuy(0){}
    ItemVol(MqlTick &tick){
    	id     = tick.time_msc; // usando o horario em milissegundos como id do item da fila.
    	volsel = (osc_padrao::isTkVol(tick) && osc_padrao::isTkSel(tick))?tick.volume_real:0;
    	volbuy = (osc_padrao::isTkVol(tick) && osc_padrao::isTkBuy(tick))?tick.volume_real:0;
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
                             ,"|id "     ,(datetime)id/1000, ",",id%1000
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
	 osc_vetor_fila_item_volume(): m_tamanho_max(VETVOL_TAMANHO_PADRAO){}

    ~osc_vetor_fila_item_volume(){ deleteItens(); }
    
    // adiciona ticks a fila de volumes...
    bool add(MqlTick &tick){
    
        if(m_tamanho_max==0) m_tamanho_max=VETVOL_TAMANHO_PADRAO;

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
    	//TrimExcess();
    	ItemVol *old_item;
        while( Count() > m_tamanho_max ){
            //Print(__FUNCTION__, " eliminando item da fila...", item.toString() );
        	old_item = Dequeue();
        	if( CheckPointer(old_item)== POINTER_INVALID ) break;
        	m_vbuy -= old_item.volbuy;
        	m_vsel -= old_item.volsel;
        	delete(old_item);
        }

    	return true;
    }
    
    // calcula e retorna o desbalanceamento do volume sem "pesar" as ocorrencias mais recentes...
    double calc_desbalanceamento(){
        if( (m_vbuy+m_vsel) == 0 ) return 0;
        return (m_vbuy-m_vsel)/(m_vbuy+m_vsel);
    }
    
    // calcula e retorna o desbalanceamento do volume "pesando" as ocorrencias mais recentes...
    double calc_desbalanceamento_com_peso(){
    
        if( (m_vbuy+m_vsel) == 0 ) return 0;

        ItemVol* vet[];
        CopyTo(vet);
        ArraySetAsSeries(vet,false);
        
        int size = ArraySize(vet);
        double vbuy = 0;
        double vsel = 0;
        
        for(int i=0; i<size; i++){
            if(CheckPointer(vet[i])==POINTER_INVALID) break;
            vbuy += ( vet[i].volbuy * (i+1) );
            vsel += ( vet[i].volsel * (i+1) );
            //Print(__FUNCTION__, " usando peso ",(i+1), " em ", vet[i].toString() );
        }
        double desb = (vbuy+vsel)==0?0:(vbuy-vsel)/(vbuy+vsel);
        //Print(__FUNCTION__, " size:", size, " vbuy:", vbuy, " vsel:", vsel, " desb:", desb );
        return desb;
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