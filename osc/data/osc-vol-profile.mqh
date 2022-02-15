//+------------------------------------------------------------------+
//|                                              osc-vol-profile.mqh |
//|                               Copyright 2022,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
//#property copyright "2022, Oficina de Software."
//#property link      "https://www.mql5.com/pt/users/marcoc"
//#property version   "1.00"
//+---------------------------------------------------------------------+
//| Volume profile.                                                     |
//| Estrutura para acumulacao de volume profile em uma janela de tempo  |
//| ou de volume.                                                       |
//+---------------------------------------------------------------------+

#include <Object.mqh>
#include <Generic\SortedMap.mqh>
#include <Generic\Queue.mqh>
#include <oslib/osc/data/osc-vol-profile-item.mqh>
#include <oslib/osc/data/osc-vol-profile-map-itens.mqh>
#include <oslib/osc/data/osc-vol-profile-fila-itens.mqh>
#include <oslib/osc/data/osc-vol-profile-vprof.mqh>

#define  QTD_SEG_ACUM_VPROF_DEFAULT 120
#define  PORC_VALUE_AREA_DEFAULT    68

struct Param{
    int    qtd_seg_acum_vprof;
    double porc_value_area;
    
    Param():qtd_seg_acum_vprof(QTD_SEG_ACUM_VPROF_DEFAULT),
            porc_value_area   (PORC_VALUE_AREA_DEFAULT   ) {}
};

class osc_vol_profile: public CObject{
private:
    
    void inicializa_volume_vprof(){
        double upre = m_vprof.upre;
        m_vprof.initialize();
        m_vprof.upre = upre;
    }

    volume_profile_map_itens  m_map_itens ; // HashMap com itens de precos e volumes
    volume_profile_fila_itens m_fila_itens; // Fila    com itens de precos e volume

public:

    Vprof m_vprof             ;
    Param m_param             ; 
    
    osc_vol_profile(){}

    // adicionando volume a um preco. Se o preco existir, adiciona o volume, senao cria novo Item.
    void add(MqlTick &tick){ add(tick.last,tick.volume_real,tick.time);}
    void add(double price, double vol, long time=0){
        // atualizando o ultimo preco...
        m_vprof.upre = price;
        
        // adicionando a fila de itens...
        volume_profile_item* item = new volume_profile_item;
        item.price = price;
        item.vol   = vol  ;
        item.time  = time ;
        m_fila_itens.Add(item);

        // adicionando ao sortedmap de itens...
        m_map_itens.add(price, vol, time);

        // verificando se deve retirar itens...
        retirar_itens_se_necessario(item);
    }

    // subtraindo volume de um preco. Se o volume do preco zerar, adiciona o volume, senao cria novo Item.
    void sub(double price, double vol  ){ m_map_itens.sub(     price,      vol); }
    void sub(volume_profile_item* item ){ sub            (item.price, item.vol); }
    
    void retirar_itens_se_necessario(volume_profile_item* ult_item){
    	// checando se tem itens na fila para retirar...
    	volume_profile_item* primeiro_item = m_fila_itens.Peek();
    	
    	// tempo demais na fila, entao eliminamos...
    	while( (primeiro_item != NULL) && (ult_item.time - primeiro_item.time > m_param.qtd_seg_acum_vprof) ){
    	    
    	    // subtraindo o volume do item antigo no sortedmap...
    	    sub(primeiro_item);

    	    // retirando o item antigo da fila e da memória...
    	    m_fila_itens.Dequeue();
    	    delete(primeiro_item);
    	    primeiro_item = m_fila_itens.Peek();
    	}
    }


    // passa vprof pra que toString consiga identificar VAH, VAL, VA e PRE
    string toString(){ return m_map_itens.toString(m_vprof); }
    
    // 
    void calcular_area_de_valor(){
    
        double chave[]; volume_profile_item* item[];
        int   qtd = m_map_itens.CopyTo(chave,item);
        int   imax = qtd-1;
        
        if(qtd<1) return;
        
        if(qtd==1){
            m_vprof.pmax = item[0].price;
            m_vprof.pmin = item[0].price;
            m_vprof.ppoc = item[0].price;
            m_vprof.pvah = item[0].price;
            m_vprof.pval = item[0].price;

            m_vprof.ipoc = 0;
            m_vprof.ivah = 0;
            m_vprof.ival = 0;
            return;            
        }
        
        //Print(__FUNCTION__, " Calculando VA (value area) em ", qtd, " itens..." );
        
        // determinando o preco com o maior volume...
        inicializa_volume_vprof();
        for(int i=0; i<qtd; i++){
            
            // maior volume e preco com maior volume ppoc
            if(item[i].vol > m_vprof.vpoc){ 
                m_vprof.vpoc=item[i].vol; 
                m_vprof.ppoc=item[i].price;
                m_vprof.ipoc=     i       ;
            }
            
            // volume total
            m_vprof.vtot += item[i].vol;
            
            // maior e menor precos...
            if(item[i].price > m_vprof.pmax)                       m_vprof.pmax = item[i].price;
            if(item[i].price < m_vprof.pmin || m_vprof.pmin == 0 ) m_vprof.pmin = item[i].price;
        }
        
        // 68% do volume total
        m_vprof.vtot = ( m_vprof.vtot * m_param.porc_value_area ) / 100.0;
        
        if( m_vprof.ipoc + 1  > imax ){
            m_vprof.pvah = item[ m_vprof.ipoc + 0 ].price;
            m_vprof.vvah = 0                             ;
            m_vprof.ivah =       m_vprof.ipoc + 0        ;
        }else if( m_vprof.ipoc + 2  > imax ){
            m_vprof.pvah = item[ m_vprof.ipoc + 1 ].price;
            m_vprof.vvah = item[ m_vprof.ipoc + 1 ].vol  ; 
            m_vprof.ivah =       m_vprof.ipoc + 1        ;
        }else{
            m_vprof.pvah = item[ m_vprof.ipoc + 2 ].price;
            m_vprof.vvah = item[ m_vprof.ipoc + 1 ].vol + item[ m_vprof.ipoc + 2 ].vol  ; 
            m_vprof.ivah =       m_vprof.ipoc + 2        ;
        }

        if( m_vprof.ipoc - 1  < 0 ){
            m_vprof.pval = item[ m_vprof.ipoc - 0 ].price;
            m_vprof.vval = 0                             ;
            m_vprof.ival =       m_vprof.ipoc - 0        ;
        }else if( m_vprof.ipoc - 2  < 0 ){
            m_vprof.pval = item[ m_vprof.ipoc - 1 ].price;
            m_vprof.vval = item[ m_vprof.ipoc - 1 ].vol  ;
            m_vprof.ival =       m_vprof.ipoc - 1        ;
        }else{
            m_vprof.pval = item[ m_vprof.ipoc - 2 ].price;
            m_vprof.vval = item[ m_vprof.ipoc - 1 ].vol + item[ m_vprof.ipoc - 2 ].vol  ; 
            m_vprof.ival =       m_vprof.ipoc - 2        ;
        }
        m_vprof.toString();
        
        double v = m_vprof.vpoc;
        while( v < m_vprof.vtot || (m_vprof.vvah==0 && m_vprof.vval==0) ){

            if( m_vprof.vvah > m_vprof.vval ){

                v += m_vprof.vvah;
                if( m_vprof.ivah + 1  > imax ){
                    m_vprof.pvah = item[ m_vprof.ivah + 0 ].price;
                    m_vprof.vvah = 0                             ;
                    m_vprof.ivah =       m_vprof.ivah + 0        ;
                }else if( m_vprof.ivah + 2  > imax ){
                    m_vprof.pvah = item[ m_vprof.ivah + 1 ].price;
                    m_vprof.vvah = item[ m_vprof.ivah + 1 ].vol  ; 
                    m_vprof.ivah =       m_vprof.ivah + 1        ;
                }else{
                    m_vprof.pvah = item[ m_vprof.ivah + 2 ].price;
                    m_vprof.vvah = item[ m_vprof.ivah + 1 ].vol + item[ m_vprof.ivah + 2 ].vol  ; 
                    m_vprof.ivah =       m_vprof.ivah + 2        ;
                }
            }else{
                v += m_vprof.vval;
                if( m_vprof.ival - 1  < 0 ){
                    m_vprof.pval = item[ m_vprof.ival - 0 ].price;
                    m_vprof.vval = 0                             ;
                    m_vprof.ival =       m_vprof.ival - 0        ;
                }else if( m_vprof.ival - 2  < 0 ){
                    m_vprof.pval = item[ m_vprof.ival - 1 ].price;
                    m_vprof.vval = item[ m_vprof.ival - 1 ].vol  ;
                    m_vprof.ival =       m_vprof.ival - 1        ;
                }else{
                    m_vprof.pval = item[ m_vprof.ival - 2 ].price;
                    m_vprof.vval = item[ m_vprof.ival - 1 ].vol + item[ m_vprof.ival - 2 ].vol  ; 
                    m_vprof.ival =       m_vprof.ival - 2        ;
                }
            }
            //Print( m_vprof.toString(), " V70%=",m_vprof.vtot, " VCALC=", v );
        }
    }
    
};

